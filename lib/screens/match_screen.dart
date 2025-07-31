import 'dart:async';
import 'package:flutter/material.dart';
import '../services/match_service.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with WidgetsBindingObserver {
  final MatchService _matchService = MatchService();

  Map<String, dynamic>? matchedUser;
  int? matchId;
  int showTimeSec = 3;
  Timer? _countdownTimer;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (matchedUser == null) {
        _requestMatch();
      } else {
        timer.cancel();
      }
    });

    _requestMatch();
  }

  Future<void> _requestMatch() async {
    try {
      final data = await _matchService.requestRandomMatch();
      if (data != null) {
        setState(() {
          matchedUser = data['matched_user'];
          matchId = data['match_id'];
          showTimeSec = data['show_time_sec'];
        });
        _startCountdown();
      }
    } catch (e) {
      debugPrint('매칭 요청 실패: $e');

      if (e.toString().contains('400')) {
        if (!mounted) return;
        bool success = await _matchService.cancelMatching();
        if (success) {
          print('매칭 상태 해제 완료');
        }
        Navigator.pushReplacementNamed(context, '/match_settings');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('매칭 조건을 먼저 설정하세요')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('매칭 요청 실패: $e')),
        );
      }
    }
  }

  void _startCountdown() {
    int sec = showTimeSec;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (sec <= 1) {
        timer.cancel();
        setState(() {
          matchedUser = null;
          matchId = null;
        });
        _startPolling();
      } else {
        setState(() {
          showTimeSec = --sec;
        });
      }
    });
  }

  Future<void> _onDecision(String decision) async {
    if (matchId == null) return;
    try {
      final status = await _matchService.sendMatchDecision(matchId!, decision);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('결과: $status')),
      );
      setState(() {
        matchedUser = null;
        matchId = null;
      });
      _startPolling();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결정 전송 실패')),
      );
    }
  }

  Future<void> _cancelMatching() async {
    bool success = await _matchService.cancelMatching();
    if (success) {
      debugPrint('매칭 상태 해제 성공');
    } else {
      debugPrint('매칭 상태 해제 실패');
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _cancelMatching();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _cancelMatching();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (matchedUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('랜덤 매칭')),
        body: const Center(child: Text('매칭 가능한 상대를 찾는 중...')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('랜덤 매칭')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(matchedUser!['profile_image']),
            ),
            const SizedBox(height: 16),
            Text(
              '${matchedUser!['username']} (${matchedUser!['age']}세, ${matchedUser!['gender']})',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('평점: ${matchedUser!['rating'].toStringAsFixed(1)}'),
            const SizedBox(height: 16),
            Text('남은 시간: $showTimeSec 초'),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _onDecision('accept'),
                  child: const Text('수락'),
                ),
                ElevatedButton(
                  onPressed: () => _onDecision('reject'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('거절'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
