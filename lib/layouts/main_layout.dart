import 'package:flutter/material.dart';

class MainLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showBack;
  final List<Widget>? appBarActions;  // nullable로 변경 (옵션)

  const MainLayout({
    super.key,
    required this.title,
    required this.child,
    this.showBack = false,
    this.appBarActions,  // 중복 제거하고 nullable로 변경
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: showBack ? const BackButton() : null,
        actions: appBarActions,  // 여기에 넘겨줘야 합니다!
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}
