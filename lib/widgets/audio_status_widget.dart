import 'package:flutter/material.dart';

class AudioStatusWidget extends StatelessWidget {
  final bool isActive;
  final IconData icon;

  const AudioStatusWidget({
    Key? key,
    required this.isActive,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: 32,
      color: isActive ? Colors.greenAccent : Colors.white38,
      shadows: isActive
          ? [
        const Shadow(
          color: Colors.greenAccent,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ]
          : null,
    );
  }
}