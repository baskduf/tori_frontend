import 'package:flutter/material.dart';

class SoundLevelBar extends StatelessWidget {
  final double level; // 0.0 ~ 1.0

  const SoundLevelBar({Key? key, required this.level}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final barCount = 20; // 막대 개수
    final activeBars = (level * barCount).round();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(barCount, (index) {
        bool active = index < activeBars;
        return Container(
          width: 4,
          height: 20 + index * 3, // 위로 갈수록 길게
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: active ? Colors.lightGreenAccent.shade400 : Colors.white24,
            borderRadius: BorderRadius.circular(2),
            boxShadow: active
                ? [
              BoxShadow(
                color: Colors.lightGreenAccent.shade400.withOpacity(0.7),
                blurRadius: 4,
                spreadRadius: 1,
              )
            ]
                : [],
          ),
        );
      }),
    );
  }
}
