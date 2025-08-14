import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;

class AuthProvider with ChangeNotifier {
  final ApiService apiService;

  String? _accessToken;
  bool _isRefreshing = false;

  AuthProvider({required this.apiService});

  String? get accessToken => _accessToken;

  /// 초기화: 저장된 access token 읽기
  Future<void> init() async {
    _accessToken = await apiService.getAccessToken();
    notifyListeners();
  }

  Future<String> login(String username, String password) async {
    final result = await apiService.login(username: username, password: password);
    if (result == 'success') {
      _accessToken = await apiService.getAccessToken();
      notifyListeners();
    }
    return result; // 항상 String 반환
  }


  /// 토큰이 만료되었을 때 자동 갱신
  Future<bool> _refreshTokenIfNeeded() async {
    if (_isRefreshing) return false; // 중복 호출 방지
    _isRefreshing = true;

    final success = await apiService.refreshAccessToken();
    if (success) {
      _accessToken = await apiService.getAccessToken();
      _isRefreshing = false;
      notifyListeners();
      return true;
    } else {
      _accessToken = null;
      _isRefreshing = false;
      notifyListeners();
      return false;
    }
  }

  /// API 요청을 래핑: 토큰 만료 시 자동 갱신 후 재시도
  Future<http.Response?> authenticatedRequest(
      Future<http.Response> Function(String accessToken) requestFn) async {
    if (_accessToken == null) {
      final initToken = await apiService.getAccessToken();
      if (initToken == null) return null;
      _accessToken = initToken;
    }

    http.Response response;
    try {
      response = await requestFn(_accessToken!);
      if (response.statusCode == 401) {
        // 토큰 만료: refresh 후 재시도
        final refreshed = await _refreshTokenIfNeeded();
        if (!refreshed) return null; // 갱신 실패
        response = await requestFn(_accessToken!);
      }
      return response;
    } catch (e) {
      print('Authenticated request error: $e');
      return null;
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    await apiService.logout();
    _accessToken = null;
    notifyListeners();
  }
}
