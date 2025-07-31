import 'package:flutter/material.dart';

final darkGrayColor = Color(0xFF2E2E2E);

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: darkGrayColor,
  scaffoldBackgroundColor: darkGrayColor,
  appBarTheme: AppBarTheme(
    backgroundColor: darkGrayColor,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey[800]?.withOpacity(0.7),  // 반투명 느낌
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    labelStyle: TextStyle(color: Colors.white70),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.grey[700],
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.grey[300],
    ),
  ),
  textTheme: TextTheme(
    bodyMedium: TextStyle(color: Colors.white70),
  ),
);
