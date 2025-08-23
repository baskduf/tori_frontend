import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'voice_chat_screen.dart';

import '../widgets/searching_widget.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

import '../layouts/responsive_scaffold.dart';
import '../api/api_constants.dart';
import 'package:flutter/scheduler.dart';

enum MatchStatus {
  searching,          // 큐 대기 중
  matched,            // 상대 발견
  waiting_response,   // 상대 응답 대기
  success,            // 매칭 완료
  rejected,           // 상대 거절
  cancelled,          // 상대 이탈
  gemError,           // 보석 부족 / 지갑 오류
  noSetting,          // 매칭 설정 없음
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
  String? _matchedUserImageUrl = '';
  int _matchedUserAge = 0;
  String _matchedUserGender = '';
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 1. 토큰 존재 확인
    String? token = authProvider.accessToken;
    if (token == null) {
      print('❌ No token found in AuthProvider');
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    // 2. 토큰 만료 시 갱신
    if (JwtDecoder.isExpired(token)) {
      final refreshed = await authProvider.refreshTokenIfNeeded();
      if (!refreshed) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
      token = authProvider.accessToken; // 갱신된 토큰 사용
    }

    // 3. WebSocket 연결
    final uri = Uri.parse(ApiConstants.matchWs(token!));
    _channel = WebSocketChannel.connect(uri);

    _channel.stream.listen(
          (message) {
        final data = json.decode(message);
        switch (data['type']) {
          case 'match_found':
            final partnerData = {
              'name': data['partner'],
              'image_url': data['partner_image_url'] ?? '',
              'age': data['partner_age'],
              'gender': data['partner_gender'],
            };
            _onMatchFound(partnerData);
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
          case 'gem_error':
            _setStatus(MatchStatus.gemError);  // enum에 gemError가 정의되어 있어야 함
            break;
          case 'no_setting':
            _setStatus(MatchStatus.noSetting); // enum에 noSetting이 정의되어 있어야 함
            break;
        }
        // 기존 메시지 핸들러 그대로
      },
      onError: (error) {
        print('WebSocket error: $error');
        _handleUnauthorized();
      },
      onDone: () {
        print('WebSocket closed');
        _handleUnauthorized();
      },
    );

    _channel.sink.add(json.encode({'action': 'join_queue'}));

    setState(() {
      _channelInitialized = true;
    });
  }

  void _handleUnauthorized() {
    _showMessage('세션이 만료되었거나 로그인 필요', isError: true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout(); // 토큰 제거
    Navigator.of(context).pushReplacementNamed('/login');
  }


  void _onMatchFound(Map<String, dynamic> partner) {
    setState(() {
      _matchedUserName = partner['name'];
      _matchedUserImageUrl = partner['image_url'] ?? '';
      _matchedUserAge = partner['age'];       // 새로 추가
      _matchedUserGender = partner['gender']; // 새로 추가
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken ?? '';

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VoiceChatScreen(
          roomName: roomName,
          signalingUrl: ApiConstants.voiceChatWs(roomName, token),
          userName: _matchedUserName,
          userAge: _matchedUserAge,
          userGender: _matchedUserGender,
          profileUrl: _matchedUserImageUrl ?? '',
        )
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

  Widget _glassContainer({required Widget child, double? width, double? height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.transparent,  // 완전 투명
            borderRadius: BorderRadius.circular(28),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSearchingContent() {
    return SearchingWidget(
      glassContainerBuilder: _glassContainer,
      rotationAnimation: _animationController,
    );
  }

  Widget _buildMatchedContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _glassContainer(
          width: 110,
          height: 110,

          child: (_matchedUserImageUrl != null && _matchedUserImageUrl!.isNotEmpty)
              ? CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(_matchedUserImageUrl!),
            backgroundColor: Colors.transparent,
          )
              : Icon(
            Icons.people_alt,
            size: 70,
            color: Colors.white70,
            shadows: const [
              Shadow(
                color: Colors.black45,
                offset: Offset(0, 2),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          '매칭 상대 발견: $_matchedUserName',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black87,
                offset: Offset(1, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _glassButton(
              icon: Icons.check,
              label: '수락',
              color: Colors.greenAccent.shade400,
              onPressed: _acceptMatch,
            ),
            const SizedBox(width: 26),
            _glassButton(
              icon: Icons.close,
              label: '거절',
              color: Colors.redAccent.shade400,
              onPressed: _rejectMatch,
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          '6초 내 응답하지 않으면 자동으로 거절됩니다.',
          style: TextStyle(
            color: Colors.white60,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _glassButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, shadows: const [
        Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2)
      ]),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2)
          ],
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.75),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 10,
        shadowColor: Colors.black87,
      ),
    );
  }

  Widget _buildWaitingResponseContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _glassContainer(
          width: 140,
          height: 140,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation(Colors.white70),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          '상대방의 응답을 기다리는 중...',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            shadows: [
              Shadow(
                color: Colors.black54,
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isGemErrorSnackbarVisible = false;

  Widget _buildSearchingContentWithGemError(BuildContext context) {
    final previousScreen = _buildSearchingContent();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_isGemErrorSnackbarVisible) return; // 이미 표시 중이면 무시
      _isGemErrorSnackbarVisible = true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: _glassContainer(
            width: double.infinity,
            child: Row(
              children: const [
                SizedBox(width: 12),
                Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "앗 매칭 기회를 놓쳤어요! 젬이 조금 부족하네요 😢 광고로 무료로 충전할 수 있어요!",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                SizedBox(width: 12),
              ],
            ),
          ),
          duration: Duration(seconds: 4),
        ),
      ).closed.then((_) => _isGemErrorSnackbarVisible = false); // 종료 시 플래그 초기화
    });

    return previousScreen;
  }



  Widget _buildNoSettingContent() {
    return Center(
      child: _glassContainer(
        width: 200,
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.settings, size: 50, color: Colors.orangeAccent),
            SizedBox(height: 12),
            Text(
              '매칭 설정이 없습니다.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSuccessContent() {
    return Center(
      child: _glassContainer(
        width: 220,
        height: 220,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.greenAccent.shade400,
              shadows: const [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(0, 2),
                  blurRadius: 3,
                ),
              ],
            ),
            const SizedBox(height: 26),
            const Text(
              '매칭이 완료되었습니다!\n대화를 시작하세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black87,
                    offset: Offset(1, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_channelInitialized) {
      return Scaffold(
        backgroundColor: _backgroundGradientStart,
        body: Center(
          child: _glassContainer(
            width: 140,
            height: 140,
            child: const CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation(Colors.white70),
            ),
          ),
        ),
      );
    }

    Widget? content;

    switch (_status) {
      case MatchStatus.gemError:
        content = _buildSearchingContentWithGemError(context);
        _setStatus(MatchStatus.searching);
        _channel.sink.add(json.encode({'action': 'join_queue'}));
        break;
      case MatchStatus.noSetting:
        content = _buildNoSettingContent();
        break;
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white70),
        titleTextStyle: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          shadows: [
            Shadow(
              color: Colors.black54,
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      backgroundColor: null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF121212),
              Color(0xFF1E1E1E),
              Color(0xFF2B2B2B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: content,
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
          ),
        ),
      ),
    );
  }
}

const _backgroundGradientStart = Color(0xFF121212);
