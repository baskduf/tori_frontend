import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../api/api_client.dart';
import '../main.dart';
import '../services/signaling_service.dart';
import '../screens/match_screen.dart';
import '../widgets/sound_bar_widget.dart';

class VoiceChatScreen extends StatefulWidget {
  final String roomName;
  final String signalingUrl;

  const VoiceChatScreen({
    Key? key,
    required this.roomName,
    required this.signalingUrl,
  }) : super(key: key);

  @override
  _VoiceChatScreenState createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen>
    with TickerProviderStateMixin {
  SignalingService? _signaling;
  MediaStream? _remoteStream;

  late AnimationController _animationController;
  late AnimationController _volumeController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _volumeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    final apiClient = ApiClient(authProvider: authProvider, navigatorKey: navigatorKey);

    _signaling = SignalingService(
      roomName: widget.roomName,
      wsUrl: widget.signalingUrl,
      onAddRemoteStream: (stream) {
        setState(() {
          _remoteStream = stream;
        });
      },
      onStatusChanged: (status) {
        if (status == 'cancelled' && mounted) {
          Navigator.of(context).pop();
        } else if (status == 'success') {
          _goToMatchScreen();
        }
      },
      apiClient: apiClient, // <-- 만약 생성자가 apiClient를 요구하면 추가
    );


    _signaling!.connect().then((_) {
      _signaling?.makeCall();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _volumeController.dispose();
    _signaling?.dispose();
    super.dispose();
  }

  void _goToMatchScreen() {
    _signaling?.dispose();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MatchScreen(initialStatus: MatchStatus.searching),
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String label, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 28, color: color.withOpacity(0.85), shadows: const [
          Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 3),
        ]),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: color.withOpacity(0.9),
            shadows: const [
              Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 3),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localAudioActive = _signaling?.localStream != null;
    final remoteAudioActive = _remoteStream != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.white.withOpacity(0.7),
          shadows: const [
            Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4),
          ],
        ),
        title: Text(
          'Voice Chat - Room: ${widget.roomName}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            shadows: const [
              Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            tooltip: '매칭 찾기',
            onPressed: _goToMatchScreen,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF2E2E2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
              _goToMatchScreen();
            }
          },
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
                  margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '음성 채팅 상태',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.9),
                          shadows: const [
                            Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildStatusRow(
                        Icons.mic,
                        localAudioActive ? '로컬 오디오 활성화됨' : '로컬 오디오 대기 중...',
                        localAudioActive ? Colors.lightGreenAccent.shade400 : Colors.white70,
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _volumeController,
                        builder: (_, __) {
                          double level = localAudioActive ? _volumeController.value : 0.0;
                          return SoundLevelBar(level: level);
                        },
                      ),
                      const SizedBox(height: 30),
                      FadeTransition(
                        opacity: _animationController.drive(
                          Tween(begin: 0.5, end: 1.0).chain(
                            CurveTween(curve: Curves.easeInOut),
                          ),
                        ),
                        child: _buildStatusRow(
                          Icons.headset,
                          remoteAudioActive ? '상대방 오디오 수신 중' : '상대방 오디오 대기 중...',
                          remoteAudioActive ? Colors.lightGreenAccent.shade400 : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _volumeController,
                        builder: (_, __) {
                          double level = remoteAudioActive ? 1 - _volumeController.value : 0.0;
                          return SoundLevelBar(level: level);
                        },
                      ),
                      const SizedBox(height: 50),
                      ElevatedButton.icon(
                        onPressed: () {
                          _signaling?.dispose();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.call_end, color: Colors.white),
                        label: const Text(
                          '통화 종료',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 6),
                            ],
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.85),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 10,
                          shadowColor: Colors.redAccent.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
