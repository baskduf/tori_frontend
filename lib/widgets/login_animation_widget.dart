import 'package:flutter/material.dart';

class LoginAnimationWidget extends StatefulWidget {
  const LoginAnimationWidget({Key? key}) : super(key: key);

  @override
  _LoginAnimationWidgetState createState() => _LoginAnimationWidgetState();
}

class _LoginAnimationWidgetState extends State<LoginAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _jumpController;
  late Animation<double> _jumpAnimation;
  bool _jumpForward = true;

  @override
  void initState() {
    super.initState();

    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _jumpAnimation =
        CurvedAnimation(parent: _jumpController, curve: Curves.easeInOut);

    _jumpController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _jumpForward = !_jumpForward;
        _jumpController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _jumpController.forward();
      }
    });

    _jumpController.forward();
  }

  @override
  void dispose() {
    _jumpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // 점프 아이콘 (고양이, 흰색)
        AnimatedBuilder(
          animation: _jumpAnimation,
          builder: (context, child) {
            double startX = _jumpForward ? -50 : screenWidth + 50;
            double endX = screenWidth / 2 - 24; // 아이콘 중앙 조정
            double xPos = startX + (endX - startX) * _jumpAnimation.value;

            double yOffset = -50 *
                (_jumpAnimation.value < 0.5
                    ? _jumpAnimation.value * 2
                    : (1 - _jumpAnimation.value) * 2); // 점프 곡선

            return Positioned(
              left: xPos,
              top: MediaQuery.of(context).size.height / 2 - 24 + yOffset,
              child: child!,
            );
          },
          child: const Icon(Icons.pets, size: 48, color: Colors.white),
        ),

        // 텍스트 안내 (아이콘 아래쪽)
        Positioned(
          top: MediaQuery.of(context).size.height / 2 + 40, // 아이콘 바로 아래
          left: 0,
          right: 0,
          child: const Center(
            child: Text(
              '로그인 진행중입니다. 잠시만 기다려주세요 😄',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
