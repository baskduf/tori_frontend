import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../api/api_client.dart';

typedef RemoteStreamCallback = void Function(MediaStream stream);
typedef StatusCallback = void Function(String status);

class SignalingService {
  final String roomName;
  final String wsUrl;
  final RemoteStreamCallback onAddRemoteStream;
  final StatusCallback? onStatusChanged;
  final ApiClient apiClient;

  WebSocketChannel? _channel;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  final _remoteRenderer = RTCVideoRenderer();
  bool _disposed = false;

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {
        'urls': [
          'turn:34.46.53.163:3478?transport=udp',
          'turn:34.46.53.163:3478?transport=tcp',
        ],
        'username': 'baskduf',
        'credential': '23s25fgh'
      },
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},
    ],
  };


  SignalingService({
    required this.roomName,
    required this.wsUrl,
    required this.onAddRemoteStream,
    this.onStatusChanged,
    required this.apiClient,
  });

  Future<void> connect() async {
    if (_disposed) return;

    await _openUserMedia();
    await _createPeerConnection();
    await _remoteRenderer.initialize();
    _connectWebSocket();
  }

  Future<void> _openUserMedia() async {
    if (_disposed) return;

    // 기존 스트림 정리
    await _localStream?.dispose();

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    print('Local audio tracks: ${_localStream?.getAudioTracks().length}');
  }

  Future<void> _createPeerConnection() async {
    if (_disposed) return;

    // 기존 연결 정리
    await _peerConnection?.close();

    _peerConnection = await createPeerConnection(_iceServers);

    // 로컬 오디오 트랙 추가
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        await _peerConnection?.addTrack(track, _localStream!);
      }
    }

    // 원격 트랙 이벤트
    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (_disposed) return;

      if (event.streams.isNotEmpty) {
        final remoteStream = event.streams[0];
        _remoteRenderer.srcObject = remoteStream;
        onAddRemoteStream(remoteStream);
      }
    };

    _peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) {
      if (_disposed || candidate == null) return;

      _sendMessage({
        'type': 'ice-candidate',
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        }
      });
    };
  }

  void _connectWebSocket() async {
    if (_disposed) return;

    // 기존 채널 닫기
    await _channel?.sink.close();
    _channel = null;

    final token = await apiClient.getValidToken();

    if (token == null) {
      print('WebSocket connection aborted: token expired');
      onStatusChanged?.call('token_expired');
      return; // 토큰 없으면 연결 시도하지 않음
    }

    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
          (message) async {
        if (_disposed) return;
        await _handleMessage(jsonDecode(message));
      },
      onDone: () {
        print('WebSocket connection closed');
        if (!_disposed) {
          onStatusChanged?.call('connection_closed');
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
        if (!_disposed) {
          onStatusChanged?.call('connection_error');
        }
      },
    );
  }


  Future<void> _handleMessage(Map<String, dynamic> data) async {
    if (_disposed || _peerConnection == null) return;

    switch (data['type']) {
      case 'role_assignment':
        final role = data['role'];
        if (role == 'offer') {
          // 역할이 offer이면 makeCall 수행
          await makeCall();
        } else if (role == 'answer') {
          // 역할이 answer이면 offer 수신 대기
          onStatusChanged?.call('waiting_for_offer');
        }
        break;

      case 'offer':
        final offer = RTCSessionDescription(data['offer']['sdp'], data['offer']['type']);
        await _peerConnection?.setRemoteDescription(offer);

        // answer 역할이면 답 생성
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection?.setLocalDescription(answer);

        _sendMessage({
          'type': 'answer',
          'answer': {'sdp': answer.sdp, 'type': answer.type}
        });
        break;

      case 'answer':
        final remoteDesc = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
        if (_peerConnection?.signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
          await _peerConnection?.setRemoteDescription(remoteDesc);
        }
        break;

      case 'ice-candidate':
        final c = data['candidate'];
        final candidate = RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']);
        await _peerConnection?.addCandidate(candidate);
        break;

      case 'match_cancelled':
        onStatusChanged?.call('cancelled');
        break;
    }
  }


  Future<void> makeCall() async {
    if (_disposed || _peerConnection == null) return;

    final offer = await _peerConnection!.createOffer();
    await _peerConnection?.setLocalDescription(offer);

    _sendMessage({
      'type': 'offer',
      'offer': {'sdp': offer.sdp, 'type': offer.type}
    });
  }

  void _sendMessage(Map<String, dynamic> message) async {
    if (_disposed || _channel == null) return;

    final token = await apiClient.getValidToken();
    if (token != null) {
      final msgJson = jsonEncode(message);
      _channel!.sink.add(msgJson);
    }
  }

  MediaStream? get localStream => _localStream;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    print('Disposing SignalingService...');

    // 순차적으로 리소스 정리
    await _channel?.sink.close();
    _channel = null;

    await _peerConnection?.close();
    _peerConnection = null;

    await _localStream?.dispose();
    _localStream = null;

    await _remoteRenderer.dispose();
  }
}