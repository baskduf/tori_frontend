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

  Timer? _reconnectTimer;

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
    await _openUserMedia();
    await _createPeerConnection();
    _connectWebSocket();
  }

  Future<void> _openUserMedia() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceServers);

    _localStream?.getAudioTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        onAddRemoteStream(event.streams[0]);
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
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
          (message) async => await _handleMessage(jsonDecode(message)),
      onDone: _scheduleReconnect,
      onError: (_) => _scheduleReconnect(),
    );
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      _reconnectTimer = null;
      _connectWebSocket();
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
      final msgJson = jsonEncode(message);
      _channel!.sink.add(msgJson);
    }
  }

  MediaStream? get localStream => _localStream;

  void dispose() {
    _reconnectTimer?.cancel();
    _localStream?.dispose();
    _peerConnection?.close();
    _channel?.sink.close();
  }
}
