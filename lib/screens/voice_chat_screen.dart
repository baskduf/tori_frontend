import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../api/api_client.dart';
import '../main.dart';
import '../services/signaling_service.dart';
import '../screens/match_screen.dart';
import '../layouts/responsive_scaffold.dart';

class VoiceChatScreen extends StatefulWidget {
  final String roomName;
  final String signalingUrl;
  final String userName;
  final int userAge;
  final String userGender; // 'M' or 'F'
  final String profileUrl; // 프로필 이미지 URL

  const VoiceChatScreen({
    Key? key,
    required this.roomName,
    required this.signalingUrl,
    required this.userName,
    required this.userAge,
    required this.userGender,
    required this.profileUrl,
  }) : super(key: key);

  @override
  _VoiceChatScreenState createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen>
    with TickerProviderStateMixin {
  SignalingService? _signaling;
  MediaStream? _remoteStream;
  bool _isConnecting = true;
  bool _disposed = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initializeVoiceChat();
  }

  void _initializeVoiceChat() async {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.7,
      upperBound: 1.0,
    )..repeat(reverse: true);

    final apiClient = ApiClient(authProvider: authProvider, navigatorKey: navigatorKey);

    _signaling = SignalingService(
      roomName: widget.roomName,
      wsUrl: widget.signalingUrl,
      onAddRemoteStream: (stream) {
        if (!_disposed && mounted) {
          setState(() {
            _remoteStream = stream;
            _isConnecting = false; // 연결 완료
          });
        }
      },
      onStatusChanged: (status) {
        if (_disposed || !mounted) return;

        if (status == 'cancelled') {
          _endCall();
        }
        // 필요시 다른 상태 처리 가능
      },
      apiClient: apiClient,
    );

    try {
      await _signaling!.connect();

      // 기존에 즉시 makeCall() 호출 삭제
      // 서버에서 role_assignment 메시지를 받으면 Service가 알아서 makeCall 수행

      // 30초 후에도 연결 안되면 종료
      Future.delayed(const Duration(seconds: 4), () {
        if (_disposed || !mounted) return;
        if (_isConnecting && _remoteStream == null) {
          _endCall();
        }
      });
    } catch (e) {
      print('Error initializing voice chat: $e');
      if (!_disposed && mounted) {
        _endCall();
      }
    }
  }


  void _endCall() async {
    if (_disposed) return;
    _disposed = true;

    _pulseController.stop();
    _pulseController.dispose();

    await _signaling?.dispose();
    _signaling = null;

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    if (!_disposed) {
      _endCall();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localAudioActive = _signaling?.localStream != null;
    final remoteAudioActive = _remoteStream != null;

    return WillPopScope(
      onWillPop: () async {
        _endCall();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white70),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _endCall,
          ),
          title: Text(
            _isConnecting
                ? '🎧 연결 중...'
                : '🎧 ${widget.userName}님과 통화중',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 연결 중 표시
              if (_isConnecting)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Colors.greenAccent),
                      SizedBox(height: 10),
                      Text(
                        '연결 중입니다...',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),

              // 프로필 사진 + 활성화 불빛
              Stack(
                alignment: Alignment.center,
                children: [
                  ScaleTransition(
                    scale: _pulseController,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (localAudioActive || remoteAudioActive) && !_isConnecting
                            ? Colors.green.withOpacity(0.4)
                            : Colors.transparent,
                        boxShadow: (localAudioActive || remoteAudioActive) && !_isConnecting
                            ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ]
                            : [],
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(widget.profileUrl),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 이름, 나이, 성별
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.userName}, ${widget.userAge}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    widget.userGender == 'M' ? Icons.male : Icons.female,
                    color: Colors.white70,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 오디오 상태 아이콘
              if (!_isConnecting)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAudioIcon(Icons.mic, localAudioActive, '내 오디오'),
                    const SizedBox(width: 40),
                    _buildAudioIcon(Icons.headset, remoteAudioActive, '상대 오디오'),
                  ],
                ),
              const SizedBox(height: 50),

              // 통화 종료 버튼
              ElevatedButton.icon(
                onPressed: _endCall,
                icon: const Icon(Icons.call_end, color: Colors.white),
                label: Text(
                  _isConnecting ? '연결 취소' : '통화 종료',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.85),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioIcon(IconData icon, bool active, String tooltip) {
    return Column(
      children: [
        Icon(
          icon,
          size: 48,
          color: active ? Colors.greenAccent : Colors.white54,
          shadows: active
              ? [
            Shadow(
              color: Colors.greenAccent.withOpacity(0.6),
              blurRadius: 12,
              offset: const Offset(0, 0),
            )
          ]
              : [],
        ),
        const SizedBox(height: 6),
        Text(
          tooltip,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}