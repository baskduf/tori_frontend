import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/signaling_service.dart';
import '../screens/match_screen.dart';

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

class _VoiceChatScreenState extends State<VoiceChatScreen> with SingleTickerProviderStateMixin {
  SignalingService? _signaling;
  MediaStream? _remoteStream;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

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
          Navigator.of(context).pop(); // 음성채팅 종료
        }
      },
    );

    _signaling!.connect().then((_) {
      _signaling?.makeCall();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _signaling?.dispose();
    super.dispose();
  }

  void _goToMatchScreen() {
    _signaling?.dispose();

    Navigator.push(
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
        Icon(icon, size: 28, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localAudioActive = _signaling?.localStream != null;
    final remoteAudioActive = _remoteStream != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Chat - Room: ${widget.roomName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            tooltip: '매칭 찾기',
            onPressed: _goToMatchScreen,
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
            _goToMatchScreen();
          }
        },
        child: Center(
          child: Card(
            elevation: 12,
            margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 타이틀
                  Text(
                    '음성 채팅 상태',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 40),

                  // 로컬 오디오 상태
                  _buildStatusRow(
                    Icons.mic,
                    localAudioActive ? '로컬 오디오 활성화됨' : '로컬 오디오 대기 중...',
                    localAudioActive ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 30),

                  // 원활한 상태 표현 애니메이션 (예: 점멸하는 원)
                  FadeTransition(
                    opacity: _animationController.drive(
                      Tween(begin: 0.5, end: 1.0),
                    ),
                    child: _buildStatusRow(
                      Icons.headset,
                      remoteAudioActive ? '상대방 오디오 수신 중' : '상대방 오디오 대기 중...',
                      remoteAudioActive ? Colors.green : Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // 종료 버튼 (직관적 UI)
                  ElevatedButton.icon(
                    onPressed: () {
                      _signaling?.dispose();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.call_end, color: Colors.white),
                    label: const Text('통화 종료', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
