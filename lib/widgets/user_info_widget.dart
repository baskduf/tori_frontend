import 'package:flutter/material.dart';

class UserInfoWidget extends StatelessWidget {
  final String name;
  final int age;
  final IconData genderIcon;

  const UserInfoWidget({
    Key? key,
    required this.name,
    required this.age,
    required this.genderIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$name, $age',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          genderIcon,
          color: Colors.white70,
          size: 20,
        ),
      ],
    );
  }
}
