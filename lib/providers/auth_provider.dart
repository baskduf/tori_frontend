import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthProvider with ChangeNotifier {
  final ApiService apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _accessToken;
  String? _refreshToken;
  bool _isRefreshing = false;

  AuthProvider({required this.apiService});

  String? get accessToken => _accessToken;
  bool get isLoggedIn => _accessToken != null;

  /// ===== 초기화 =====
  Future<void> init() async {
    _accessToken = await _storage.read(key: 'access_token');
    _refreshToken = await _storage.read(key: 'refresh_token');
    notifyListeners();
  }

  /// ===== 토큰 저장 =====
  Future<void> _saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
    notifyListeners();
  }

  /// ===== 일반 로그인 =====
  Future<String> login(String username, String password) async {
    final result = await apiService.login(username: username, password: password);
    if (result == 'success') {
      _accessToken = await apiService.getAccessToken();
      _refreshToken = await apiService.getRefreshToken();
      notifyListeners();
    }
    return result;
  }

  /// ===== 소셜 로그인 =====
  Future<String> socialLogin(
      String provider,
      String code, {
        String? username,
        int? age,
        String? gender,
        File? profileImageFile,
      }) async {
    try {
      final data = await apiService.socialLogin(
        provider: provider,
        code: code,
        username: username,
        age: age,
        gender: gender,
        profileImageFile: profileImageFile,
      );

      final status = data['statusCode'];
      if (status == 200 || status == 201) {
        // access/refresh 저장
        final access = data['access'];
        final refresh = data['refresh'];
        if (access != null && refresh != null) {
          await _saveTokens(access, refresh);
        }
        return status == 200 ? 'success' : 'signup_success';
      } else if (status == 202) {
        return 'signup_required:${json.encode(data['user_data'])}';
      } else {
        return '실패: ${data['message'] ?? data['error'] ?? '알 수 없는 오류'}';
      }
    } catch (e) {
      return 'OAuth 오류: $e';
    }
  }

  /// ===== 토큰 갱신 =====
  Future<bool> _refreshTokenIfNeeded() async {
    if (_isRefreshing) return false;
    if (_refreshToken == null) return false;

    _isRefreshing = true;
    final success = await apiService.refreshAccessToken();
    _isRefreshing = false;

    if (success) {
      _accessToken = await apiService.getAccessToken();
      notifyListeners();
    } else {
      _accessToken = null;
      _refreshToken = null;
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      notifyListeners();
    }

    return success;
  }

  /// ===== 인증 요청 래퍼 =====
  Future<http.Response?> authenticatedRequest(
      Future<http.Response> Function(String accessToken) requestFn) async {
    if (_accessToken == null) {
      _accessToken = await _storage.read(key: 'access_token');
      if (_accessToken == null) return null;
    }

    try {
      var response = await requestFn(_accessToken!);
      if (response.statusCode == 401) {
        final refreshed = await _refreshTokenIfNeeded();
        if (!refreshed) return null;
        response = await requestFn(_accessToken!);
      }
      return response;
    } catch (e) {
      print('Authenticated request error: $e');
      return null;
    }
  }

  /// ===== 로그아웃 =====
  Future<void> logout() async {
    await apiService.logout();
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    notifyListeners();
  }

  /// ===== 외부에서 토큰 강제 세팅 =====
  Future<void> setToken(String access, String refresh) async {
    await _saveTokens(access, refresh);
  }
}
