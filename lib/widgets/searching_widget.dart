// lib/screens/widgets/searching_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';

class SearchingWidget extends StatefulWidget {
  final Widget Function({required Widget child, double? width, double? height}) glassContainerBuilder;
  final Animation<double> rotationAnimation;

  const SearchingWidget({
    super.key,
    required this.glassContainerBuilder,
    required this.rotationAnimation,
  });

  @override
  State<SearchingWidget> createState() => _SearchingWidgetState();
}

class _SearchingWidgetState extends State<SearchingWidget> {
  int _dotCount = 1;
  late Timer _dotTimer;

  @override
  void initState() {
    super.initState();
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() {
        _dotCount = _dotCount % 4 + 1; // 1 → 2 → 3 → 4 → 1
      });
    });
  }

  @override
  void dispose() {
    _dotTimer.cancel();
    super.dispose();
  }

  String get _dots => '.' * _dotCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        widget.glassContainerBuilder(
          width: 140,
          height: 140,
          child: RotationTransition(
            turns: widget.rotationAnimation,
            child: const Icon(
              Icons.public, // 지구 아이콘
              size: 80,
              color: Colors.white70,
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          '매칭 상대를 찾는 중$_dots',
          style: const TextStyle(
            fontSize: 22,
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
}
