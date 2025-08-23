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

  // 원격 오디오용 renderer (필요 시)
  final _remoteRenderer = RTCVideoRenderer();

  Timer? _reconnectTimer;
  bool _isConnecting = false;

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
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
    if (_isConnecting) return;
    _isConnecting = true;

    await _initializeLocalMedia();
    await _createPeerConnection();
    await _remoteRenderer.initialize(); // renderer 초기화
    _connectWebSocket();

    _isConnecting = false;
  }

  Future<void> _initializeLocalMedia() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    print('Local audio tracks: ${_localStream?.getAudioTracks().length}');
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceServers);

    // 로컬 오디오 트랙 추가
    _localStream?.getAudioTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    // 원격 트랙 이벤트
    _peerConnection?.onTrack = (RTCTrackEvent event) async {
      if (event.streams.isNotEmpty) {
        final remoteStream = event.streams[0];
        _remoteRenderer.srcObject = remoteStream;
        onAddRemoteStream(remoteStream);
      }
    };

    _peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate != null) {
        _sendMessage({
          'type': 'ice-candidate',
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          }
        });
      }
    };
  }

  void _connectWebSocket() {
    if (_channel != null) return; // 이미 연결 중이면 무시

    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
          (message) async => await _handleMessage(jsonDecode(message)),
      onDone: _scheduleReconnect,
      onError: (_) => _scheduleReconnect(),
    );
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;

    _reconnectTimer = Timer(const Duration(seconds: 3), () async {
      _reconnectTimer = null;

      // 기존 연결 종료 후 새로 연결
      await disposePeerConnection();
      await connect();
    });
  }

  Future<void> _handleMessage(Map<String, dynamic> data) async {
    switch (data['type']) {
      case 'offer':
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(data['offer']['sdp'], data['offer']['type']),
        );
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection?.setLocalDescription(answer);
        _sendMessage({'type': 'answer', 'answer': {'sdp': answer.sdp, 'type': answer.type}});
        break;

      case 'answer':
        final remoteDesc = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
        if (_peerConnection?.signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
          await _peerConnection?.setRemoteDescription(remoteDesc);
        }
        break;

      case 'ice-candidate':
        final c = data['candidate'];
        await _peerConnection?.addCandidate(
          RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']),
        );
        break;

      case 'match_cancelled':
        onStatusChanged?.call('cancelled');
        break;

      case 'match_success':
        onStatusChanged?.call('success');
        break;
    }
  }

  void makeCall() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection?.setLocalDescription(offer);
    _sendMessage({'type': 'offer', 'offer': {'sdp': offer.sdp, 'type': offer.type}});
  }

  void _sendMessage(Map<String, dynamic> message) async {
    final token = await apiClient.getValidToken();
    if (_channel != null && token != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  // PeerConnection과 Track 완전 해제
  Future<void> disposePeerConnection() async {
    _reconnectTimer?.cancel();

    if (_peerConnection != null) {
      for (var sender in await _peerConnection!.getSenders()) {
        await _peerConnection!.removeTrack(sender);
      }
    }


    // PeerConnection 종료
    await _peerConnection?.close();
    _peerConnection = null;

    // LocalStream Track stop
    _localStream?.getTracks().forEach((track) => track.stop());
    await _localStream?.dispose();
    _localStream = null;

    // Renderer 종료
    await _remoteRenderer.dispose();

    // WebSocket 종료
    await _channel?.sink.close();
    _channel = null;
  }

  MediaStream? get localStream => _localStream;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  void dispose() async {
    await disposePeerConnection();
  }
}
