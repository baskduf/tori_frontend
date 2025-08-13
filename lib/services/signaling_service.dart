// lib/signaling_service.dart
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef RemoteStreamCallback = void Function(MediaStream stream);
typedef StatusCallback = void Function(String status);  // 상태 변경 콜백

class SignalingService {
  final String roomName;
  final String wsUrl;

  late WebSocketChannel _channel;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
  };

  final RemoteStreamCallback onAddRemoteStream;
  final StatusCallback? onStatusChanged;

  SignalingService({
    required this.roomName,
    required this.wsUrl,
    required this.onAddRemoteStream,
    this.onStatusChanged,
  });

  Future<void> connect() async {
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel.stream.listen((message) async {
      final data = jsonDecode(message);
      await _handleMessage(data);
    });

    await _openUserMedia();
    await _createPeerConnection();
  }

  Future<void> _openUserMedia() async {
    _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceServers);

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    _peerConnection?.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        onAddRemoteStream(event.streams[0]);
      }
    };

    _peerConnection?.onIceCandidate = (candidate) {
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
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(data['answer']['sdp'], data['answer']['type']),
        );
        break;

      case 'ice-candidate':
        final c = data['candidate'];
        await _peerConnection?.addCandidate(
          RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']),
        );
        break;

      case 'match_cancelled':
        if (onStatusChanged != null) {
          onStatusChanged!('cancelled');
        }
        break;

      case 'match_success':
        if (onStatusChanged != null) {
          onStatusChanged!('success');
        }
        break;

    // 필요한 다른 상태들도 여기에 추가

      default:
      // 무시
        break;
    }
  }

  void makeCall() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection?.setLocalDescription(offer);
    _sendMessage({'type': 'offer', 'offer': {'sdp': offer.sdp, 'type': offer.type}});
  }

  void _sendMessage(Map<String, dynamic> message) {
    _channel.sink.add(jsonEncode(message));
  }

  MediaStream? get localStream => _localStream;

  void dispose() {
    _localStream?.dispose();
    _peerConnection?.close();
    _channel.sink.close();
  }
}
