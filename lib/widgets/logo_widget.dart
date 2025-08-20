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
          // 로고 이미지
          Opacity(
            opacity: 0.8, // 불투명도 조절 (0.0~1.0)
            child: Image.asset(
              'assets/icon/tori_logo.png',
              width: 80, // 적당한 가로 크기
              height: 80, // 적당한 세로 크기
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          // 기존 텍스트 + 아이콘
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 10),
              Text(
                'TORI',
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
              Icon(Icons.phone, size: 40, color: Colors.white.withOpacity(0.85)),
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
