import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum MatchStatus {
  idle,
  searching,
  matched,
  waiting_response,
  success,
  rejected,
}

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  MatchStatus _status = MatchStatus.idle;
  String _matchedUserName = '';
  Timer? _responseTimer;
  final int _responseTimeoutSeconds = 6;

  late WebSocketChannel _channel;
  bool _channelInitialized = false;

  @override
  void initState() {
    super.initState();
    _initWebSocket();
  }

  Future<void> _initWebSocket() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token') ?? '';

    final uri = Uri.parse('ws://localhost:8000/ws/match/?token=$token');
    _channel = WebSocketChannel.connect(uri);

    _channel.stream.listen((message) {
      final data = json.decode(message);
      switch (data['type']) {
        case 'match_found':
          _onMatchFound(data['partner']);
          break;
        case 'match_response':
          _onMatchResponse(data['result'], data['from']);
          break;
        case 'match_success':
          _onMatchSuccess(data['room']);
          break;
      }
    }, onError: (error) {
      print('WebSocket error: $error');
      setState(() {
        _channelInitialized = false;
      });
    }, onDone: () {
      print('WebSocket closed');
    });

    setState(() {
      _channelInitialized = true;
    });
  }

  void _onMatchFound(String partnerName) {
    setState(() {
      _matchedUserName = partnerName;
      _setStatus(MatchStatus.matched);
    });
  }

  void _onMatchResponse(String result, String fromUser) {
    if (result == 'reject') {
      _setStatus(MatchStatus.rejected);
    }
  }

  void _onMatchSuccess(String roomName) {
    _setStatus(MatchStatus.success);
  }

  void _startResponseTimer() {
    _responseTimer?.cancel();
    _responseTimer = Timer(Duration(seconds: _responseTimeoutSeconds), () {
      if (_status == MatchStatus.matched) {
        _rejectMatch();
      }
    });
  }

  void _setStatus(MatchStatus status) {
    setState(() {
      _status = status;
      if (status == MatchStatus.matched) {
        _startResponseTimer();
      } else {
        _responseTimer?.cancel();
      }
    });
  }

  void _startMatching() {
    _channel.sink.add(json.encode({'action': 'join_queue'}));
    setState(() {
      _status = MatchStatus.searching;
      _matchedUserName = '';
    });
  }

  void _acceptMatch() {
    _responseTimer?.cancel();
    _channel.sink.add(json.encode({
      'action': 'respond',
      'partner': _matchedUserName,
      'response': 'accept',
    }));
    _setStatus(MatchStatus.waiting_response);
  }

  void _rejectMatch() {
    _responseTimer?.cancel();
    _channel.sink.add(json.encode({
      'action': 'respond',
      'partner': _matchedUserName,
      'response': 'reject',
    }));
    _setStatus(MatchStatus.idle);
    _matchedUserName = '';
  }

  @override
  void dispose() {
    _responseTimer?.cancel();
    if (_channelInitialized) _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_channelInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Widget content;

    switch (_status) {
      case MatchStatus.idle:
        content = ElevatedButton(
          onPressed: _startMatching,
          child: const Text('매칭 시작'),
        );
        break;

      case MatchStatus.searching:
        content = const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('매칭 상대를 찾는 중...'),
          ],
        );
        break;

      case MatchStatus.matched:
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('매칭 상대 발견: $_matchedUserName'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _acceptMatch,
              child: const Text('수락'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _rejectMatch,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('거절'),
            ),
            const SizedBox(height: 20),
            const Text('6초 내 응답하지 않으면 자동 거절 처리됩니다.'),
          ],
        );
        break;

      case MatchStatus.waiting_response:
        content = const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('상대방의 응답을 기다리는 중...'),
          ],
        );
        break;

      case MatchStatus.success:
        content = const Center(
          child: Text(
            '매칭이 완료되었습니다! 대화를 시작하세요.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        );
        break;

      case MatchStatus.rejected:
        content = const Center(
          child: Text(
            '상대가 매칭을 거절했습니다.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          if (_status == MatchStatus.rejected) {
            _startMatching();
          }
        });
        break;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('매칭 화면')),
      body: Center(child: content),
    );
  }
}
