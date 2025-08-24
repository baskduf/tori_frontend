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

  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _disposed = false;

  // 개선된 ICE 서버 설정 (더 안정적인 STUN/TURN 서버)
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
      // Google STUN 서버 (가장 안정적)
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
    if (_disposed) return;

    await _remoteRenderer.initialize();
    await _openUserMedia();
    await _createPeerConnection();
    _connectWebSocket();
  }

  Future<void> _openUserMedia() async {
    if (_disposed) return;

    await _localStream?.dispose();
    _localStream = null;

    // 개선된 오디오 제약 조건 (노이즈 제거에 최적화)
    final Map<String, dynamic> mediaConstraints = {
      'audio': {
        // 노이즈 제거 설정 강화
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': false,  // 자동 볼륨 조절 활성화 (노이즈 감소에 도움)

        // 샘플링 및 채널 설정 최적화
        'channelCount': 1,       // 모노 (더 안정적)
        'sampleRate': 16000,     // 16kHz로 낮춰서 안정성 향상 (음성용으로 충분)
        'sampleSize': 16,

        // 볼륨 관련 설정
        'volume': 0.8,           // 볼륨을 약간 낮춰서 클리핑 방지
        'latency': 0.02,         // 20ms 레이턴시 (너무 낮으면 버퍼 언더런 발생)

        // 추가 노이즈 제거 옵션 (브라우저별로 지원 여부 다름)
        'googEchoCancellation': true,
        'googAutoGainControl': true,
        'googNoiseSuppression': true,
        'googHighpassFilter': true,
        'googTypingNoiseDetection': true,
        'googAudioMirroring': false,
      },
      'video': false
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      print('Local audio tracks: ${_localStream?.getAudioTracks().length}');

      // 오디오 트랙 추가 설정
      if (_localStream != null) {
        for (var track in _localStream!.getAudioTracks()) {
          // 오디오 트랙별 세부 설정
          await track.applyConstraints({
            'echoCancellation': true,
            'noiseSuppression': true,
            'autoGainControl': true,
            'sampleRate': 16000,
          });
        }
      }
    } catch (e) {
      print('Error accessing user media: $e');
      // 실패시 더 기본적인 설정으로 재시도
      try {
        final basicConstraints = {
          'audio': {
            'echoCancellation': true,
            'noiseSuppression': true,
            'sampleRate': 16000,
          },
          'video': false
        };
        _localStream = await navigator.mediaDevices.getUserMedia(basicConstraints);
      } catch (e2) {
        print('Fallback media access also failed: $e2');
      }
    }
  }

  Future<void> _createPeerConnection() async {
    if (_disposed) return;

    await _peerConnection?.close();

    // PeerConnection 설정 최적화
    final config = Map<String, dynamic>.from(_iceServers);
    config['sdpSemantics'] = 'unified-plan';  // 최신 SDP 형식 사용

    _peerConnection = await createPeerConnection(config);

    // 로컬 오디오 트랙 추가 + 최적화된 인코딩 설정
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        final sender = await _peerConnection?.addTrack(track, _localStream!);
        if (sender != null) {
          final params = sender.parameters;
          params.encodings = [
            RTCRtpEncoding(
              maxBitrate: 32000,    // 32kbps로 낮춰서 안정성 향상
              maxFramerate: null,   // 오디오는 프레임레이트 제한 없음
              scaleResolutionDownBy: null,
            )
          ];

          // 추가 코덱 설정 (Opus 코덱 최적화)
          try {
            await sender.setParameters(params);
          } catch (e) {
            print('Failed to set sender parameters: $e');
          }
        }
      }
    }

    // 원격 트랙 이벤트 처리 개선
    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (_disposed) return;
      if (event.streams.isNotEmpty) {
        final remoteStream = event.streams[0];

        // 중복 스트림 설정 방지
        if (_remoteRenderer.srcObject != remoteStream) {
          // 1. 기존 트랙 정리
          _remoteRenderer.srcObject?.getAudioTracks().forEach((track) {
            track.stop();        // 트랙 정지
          });
          _remoteRenderer.srcObject = null;

          // 2. 새 스트림 바인딩
          _remoteRenderer.srcObject = remoteStream;

          // 3. 새 트랙 활성화 및 볼륨 조절
          for (var track in remoteStream.getAudioTracks()) {
            track.enabled = true;

            // 필요시 Web Audio API 또는 gainNode 활용 볼륨 조절 가능
            // track.applyConstraints({'volume': 0.5});  // Flutter WebRTC에서 지원 여부 확인 필요
          }

          // 4. 콜백 호출
          onAddRemoteStream(remoteStream);
        }

      }
    };

    // ICE 연결 상태 모니터링
    _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      print('ICE Connection State: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        onStatusChanged?.call('connection_unstable');
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

    await _channel?.sink.close();
    _channel = null;

    final token = await apiClient.getValidToken();
    if (token == null) {
      print('WebSocket connection aborted: token expired');
      onStatusChanged?.call('token_expired');
      return;
    }

    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
          (message) async {
        if (_disposed) return;
        await _handleMessage(jsonDecode(message));
      },
      onDone: () {
        print('WebSocket connection closed');
        if (!_disposed) onStatusChanged?.call('connection_closed');
      },
      onError: (error) {
        print('WebSocket error: $error');
        if (!_disposed) onStatusChanged?.call('connection_error');
      },
    );
  }

  Future<void> _handleMessage(Map<String, dynamic> data) async {
    if (_disposed || _peerConnection == null) return;

    switch (data['type']) {
      case 'role_assignment':
        final role = data['role'];
        if (role == 'offer') {
          await makeCall();
        } else if (role == 'answer') {
          onStatusChanged?.call('waiting_for_offer');
        }
        break;

      case 'offer':
        final offer = RTCSessionDescription(data['offer']['sdp'], data['offer']['type']);
        await _peerConnection?.setRemoteDescription(offer);

        // Answer 생성시 오디오 최적화 옵션 추가
        final answerConstraints = <String, dynamic>{
          'offerToReceiveAudio': true,
          'offerToReceiveVideo': false,
        };

        final answer = await _peerConnection!.createAnswer(answerConstraints);
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

    // Offer 생성시 오디오 최적화 옵션
    final offerConstraints = <String, dynamic>{
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    };

    final offer = await _peerConnection!.createOffer(offerConstraints);
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
      _channel!.sink.add(jsonEncode(message));
    }
  }

  // 런타임에 오디오 품질 조절하는 메서드 추가
  Future<void> adjustAudioQuality(bool highQuality) async {
    if (_peerConnection == null || _localStream == null) return;

    final senders = await _peerConnection!.getSenders();
    for (var sender in senders) {
      if (sender.track?.kind == 'audio') {
        final params = sender.parameters;
        params.encodings = [
          RTCRtpEncoding(
            maxBitrate: highQuality ? 64000 : 24000,
          )
        ];
        await sender.setParameters(params);
      }
    }
  }

  MediaStream? get localStream => _localStream;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    print('Disposing SignalingService...');

    await _channel?.sink.close();
    _channel = null;

    await _peerConnection?.close();
    _peerConnection = null;

    await _localStream?.dispose();
    _localStream = null;

    await _remoteRenderer.dispose();
  }
}