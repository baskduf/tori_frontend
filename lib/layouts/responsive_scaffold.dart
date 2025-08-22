import 'package:flutter/material.dart';


//todo refactoring
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFF121212),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: child,
          ),
        ),
      ),
    );
  }
}

// 사용 예시
class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      child: Column(
        children: [
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () => _showError(context, '오류가 발생했습니다!'),
            child: const Text('오류 발생시키기'),
          ),
        ],
      ),
    );
  }
}
