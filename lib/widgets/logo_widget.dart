import 'package:flutter/material.dart';

class Logo extends StatefulWidget {
  const Logo({Key? key}) : super(key: key);

  @override
  _LogoState createState() => _LogoState();
}

class _LogoState extends State<Logo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3), // 한 사이클 시간
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 반복하면서 뒤집기
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 로고 이미지 (모서리 둥글게, 화질 최적화)
          ClipRRect(
            borderRadius: BorderRadius.circular(16), // 모서리 둥글게
            child: Image.asset(
              'assets/icon/tori_font_logo.png',
              width: 120,
              height: 120,
              fit: BoxFit.cover, // cover로 영역 채우기
              filterQuality: FilterQuality.high, // 고품질 리샘플링
            ),
          ),
          const SizedBox(height: 12),
          // 텍스트 + 아이콘
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 10),
              Text(
                'TORI VOICE',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.85),
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '새로운 인연과의 만남',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.65),
              fontWeight: FontWeight.w400,
              shadows: const [
                Shadow(
                  color: Colors.black38,
                  offset: Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
