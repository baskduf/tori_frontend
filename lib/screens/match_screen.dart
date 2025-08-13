import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'voice_chat_screen.dart';

enum MatchStatus {
  searching,
  matched,
  waiting_response,
  success,
  rejected,
  cancelled,
}

class MatchScreen extends StatefulWidget {
  final MatchStatus initialStatus;

  const MatchScreen({super.key, required this.initialStatus});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with SingleTickerProviderStateMixin {
  late MatchStatus _status;
  String _matchedUserName = '';
  Timer? _responseTimer;
  final int _responseTimeoutSeconds = 6;

  late WebSocketChannel _channel;
  bool _channelInitialized = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _status = widget.initialStatus;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initWebSocket();
  }

  @override
  void dispose() {
    _responseTimer?.cancel();
    if (_channelInitialized) _channel.sink.close();
    _animationController.dispose();
    super.dispose();
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
        case 'match_cancelled':
          _onMatchCancelled(data['from']);
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

    _channel.sink.add(json.encode({'action': 'join_queue'}));

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

  void _onMatchCancelled(String fromUser) {
    if (_status == MatchStatus.matched ||
        _status == MatchStatus.waiting_response ||
        _status == MatchStatus.success) {
      _showMessage('상대가 매칭을 이탈했습니다.', isError: true);
      _setStatus(MatchStatus.searching);
      _channel.sink.add(json.encode({'action': 'join_queue'}));
      _matchedUserName = '';
    }
  }

  void _onMatchResponse(String result, String fromUser) {
    if (result == 'reject') {
      _showMessage('상대가 매칭을 거절했습니다.', isError: true);
      _setStatus(MatchStatus.searching);
      _channel.sink.add(json.encode({'action': 'join_queue'}));
    }
  }

  void _onMatchSuccess(String roomName) async {
    _setStatus(MatchStatus.success);

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token') ?? '';

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VoiceChatScreen(
          roomName: roomName,
          signalingUrl: 'ws://localhost:8000/ws/voicechat/$roomName/?token=$token',
        ),
      ),
    );

    _rejectMatch();

    setState(() {
      _status = MatchStatus.searching;
      _matchedUserName = '';
    });
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

    _setStatus(MatchStatus.searching);
    _matchedUserName = '';

    _channel.sink.add(json.encode({'action': 'join_queue'}));
  }

  void _showMessage(String message, {bool isError = false}) {
    final color = isError ? Colors.red.shade600 : Colors.green.shade600;
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay?.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  Widget _buildSearchingContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(strokeWidth: 6),
        ),
        const SizedBox(height: 24),
        const Text(
          '매칭 상대를 찾는 중...',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.blueAccent),
        ),
      ],
    );
  }

  Widget _buildMatchedContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.people_alt, size: 70, color: Colors.blue.shade700),
        const SizedBox(height: 18),
        Text(
          '매칭 상대 발견: $_matchedUserName',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _acceptMatch,
              icon: const Icon(Icons.check),
              label: const Text('수락'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                textStyle: const TextStyle(fontSize: 18),
                elevation: 5,
              ),
            ),
            const SizedBox(width: 25),
            ElevatedButton.icon(
              onPressed: _rejectMatch,
              icon: const Icon(Icons.close),
              label: const Text('거절'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                textStyle: const TextStyle(fontSize: 18),
                elevation: 5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          '6초 내 응답하지 않으면 자동으로 거절됩니다.',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildWaitingResponseContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(strokeWidth: 6),
        ),
        const SizedBox(height: 20),
        const Text(
          '상대방의 응답을 기다리는 중...',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.blueGrey),
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade600),
          const SizedBox(height: 24),
          const Text(
            '매칭이 완료되었습니다!\n대화를 시작하세요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
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
      case MatchStatus.searching:
        content = _buildSearchingContent();
        break;
      case MatchStatus.matched:
        content = _buildMatchedContent();
        break;
      case MatchStatus.waiting_response:
        content = _buildWaitingResponseContent();
        break;
      case MatchStatus.success:
        content = _buildSuccessContent();
        break;
      case MatchStatus.rejected:
      // rejected 상태는 실제 UI는 searching 화면에 메시지만 띄우고 있으므로
      // _showMessage() 함수로 메시지 띄운 뒤 searching UI 출력
        _showMessage('상대가 매칭을 거절했습니다.', isError: true);
        _setStatus(MatchStatus.searching);
        _channel.sink.add(json.encode({'action': 'join_queue'}));
        content = _buildSearchingContent();
        break;
      case MatchStatus.cancelled:
        _showMessage('상대가 매칭을 이탈했습니다.', isError: true);
        _setStatus(MatchStatus.searching);
        _channel.sink.add(json.encode({'action': 'join_queue'}));
        content = _buildSearchingContent();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('매칭 화면'),
        centerTitle: true,
        elevation: 3,
      ),
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: content,
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
        ),
      ),
    );
  }
}
