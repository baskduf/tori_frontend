import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';

class ApiClient {
  final AuthProvider authProvider;
  final GlobalKey<NavigatorState> navigatorKey;

  ApiClient({required this.authProvider, required this.navigatorKey});

  /// GET
  Future<http.Response> get(String url) async {
    final token = await _getValidToken();
    if (token == null) return Future.error('Unauthorized');

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    return _handleResponse(response);
  }

  /// POST
  Future<http.Response> post(String url, {Map<String, dynamic>? body}) async {
    final token = await _getValidToken();
    if (token == null) return Future.error('Unauthorized');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    return _handleResponse(response);
  }

  /// 토큰 체크/갱신
  Future<String?> _getValidToken() async {
    String? token = authProvider.accessToken;

    if (token == null || token.isEmpty) {
      return null;
    }

    return token;
  }

  /// 토큰 체크/갱신 (Public)
  Future<String?> getValidToken() async {
    String? token = authProvider.accessToken;

    // 토큰 없거나 만료시 refresh 처리
    if (token == null || token.isEmpty) {
      final refreshed = await authProvider.refreshTokenIfNeeded();
      if (!refreshed) {
        _handleUnauthorized();
        return null;
      }
      token = authProvider.accessToken;
    }

    return token;
  }

  /// 401 처리
  http.Response _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      _handleUnauthorized();
    }
    return response;
  }

  void _handleUnauthorized() {
    authProvider.logout();
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  }
}
