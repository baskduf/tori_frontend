import 'package:flutter/material.dart';

class MainLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showBack;
  final List<Widget>? appBarActions;
  final Color? appBarBackgroundColor;
  final Color? appBarIconColor;

  const MainLayout({
    super.key,
    required this.title,
    required this.child,
    this.showBack = false,
    this.appBarActions,
    this.appBarBackgroundColor,
    this.appBarIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarBackgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: IconThemeData(
          color: appBarIconColor ?? Theme.of(context).iconTheme.color,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: appBarIconColor ?? Theme.of(context).appBarTheme.titleTextStyle?.color,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 1),
                blurRadius: 2,
              )
            ],
          ),
        ),
        leading: showBack ? const BackButton() : null,
        actions: appBarActions,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}
