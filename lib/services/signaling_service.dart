import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef RemoteStreamCallback = void Function(MediaStream stream);
typedef StatusCallback = void Function(String status);

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
      print('Received signaling message: $data');  // 디버깅용
      await _handleMessage(data);
    });

    await _openUserMedia();
    await _createPeerConnection();
  }

  Future<void> _openUserMedia() async {
    _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    print('Local media stream opened');
    print('Local audio tracks count: ${_localStream?.getAudioTracks().length}');
    print('Local video tracks count: ${_localStream?.getVideoTracks().length}');
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceServers);

    final localAudioTracks = _localStream?.getAudioTracks() ?? [];
    print('Adding ${localAudioTracks.length} audio tracks to peer connection');

    localAudioTracks.forEach((track) {
      print('Adding audio track id: ${track.id}');
      _peerConnection?.addTrack(track, _localStream!);
    });

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        print('Remote stream added: ${event.streams[0].id}');
        print('Remote stream audio tracks count: ${event.streams[0].getAudioTracks().length}');
        print('Remote stream video tracks count: ${event.streams[0].getVideoTracks().length}');
        onAddRemoteStream(event.streams[0]);
      } else {
        print('onTrack event but no streams');
      }
    };

    _peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate != null) {
        print('Sending ICE candidate: ${candidate.candidate}');
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

    print('Peer connection created');
  }

  Future<void> _handleMessage(Map<String, dynamic> data) async {
    switch (data['type']) {
      case 'offer':
        print('Received offer');
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(data['offer']['sdp'], data['offer']['type']),
        );
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection?.setLocalDescription(answer);
        _sendMessage({'type': 'answer', 'answer': {'sdp': answer.sdp, 'type': answer.type}});
        break;

      case 'answer':
        print('Received answer');
        final remoteDesc = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
        final currentSignalingState = _peerConnection?.signalingState;
        print('Current signaling state before setting answer: $currentSignalingState');

        if (currentSignalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
          await _peerConnection?.setRemoteDescription(remoteDesc);
          print('Remote description (answer) set successfully');
        } else {
          print('Warning: Ignored answer SDP because signaling state is $currentSignalingState');
        }
        break;

      case 'ice-candidate':
        print('Received ICE candidate');
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

      default:
        print('Unknown signaling message type: ${data['type']}');
        break;
    }
  }

  void makeCall() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection?.setLocalDescription(offer);
    print('Local description set with offer, SDP length: ${offer.sdp!.length}');
    _sendMessage({'type': 'offer', 'offer': {'sdp': offer.sdp, 'type': offer.type}});
    print('Sent offer');
  }

  void _sendMessage(Map<String, dynamic> message) {
    final msgJson = jsonEncode(message);
    print('Sending message: $msgJson');
    _channel.sink.add(msgJson);
  }

  MediaStream? get localStream => _localStream;

  void dispose() {
    _localStream?.dispose();
    _peerConnection?.close();
    _channel.sink.close();
    print('Signaling disposed');
  }
}

// --- UI 샘플 코드: 로컬 오디오, 원격 오디오 재생 ---

class VoiceChatPage extends StatefulWidget {
  final String roomName;
  final String wsUrl;

  const VoiceChatPage({Key? key, required this.roomName, required this.wsUrl}) : super(key: key);

  @override
  State<VoiceChatPage> createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage> {
  late SignalingService signaling;

  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  String _status = "대기중";

  @override
  void initState() {
    super.initState();
    initRenderers();

    signaling = SignalingService(
      roomName: widget.roomName,
      wsUrl: widget.wsUrl,
      onAddRemoteStream: (stream) {
        print('UI: Remote stream received, updating renderer');
        _remoteRenderer.srcObject = stream;
        setState(() {});
      },
      onStatusChanged: (status) {
        print('UI: Status changed: $status');
        setState(() {
          _status = status;
        });
      },
    );

    signaling.connect().then((_) {
      if (signaling.localStream != null) {
        _localRenderer.srcObject = signaling.localStream;
        setState(() {});
        print('UI: Local stream set to renderer');
      }

      signaling.makeCall();
    });
  }

  Future<void> initRenderers() async {
    await _remoteRenderer.initialize();
    await _localRenderer.initialize();
    print('Renderers initialized');
  }

  @override
  void dispose() {
    signaling.dispose();
    _remoteRenderer.dispose();
    _localRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('음성 채팅 ($_status)'),
      ),
      body: Column(
        children: [
          Expanded(
            child: RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 100,
            child: RTCVideoView(
              _localRenderer,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: () {
              signaling.makeCall();
            },
            child: const Text('Call 시작'),
          ),
        ],
      ),
    );
  }
}

