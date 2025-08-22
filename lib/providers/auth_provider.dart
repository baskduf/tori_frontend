import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../api/api_constants.dart';

class AuthProvider with ChangeNotifier {
  // -------------------------
  // 상태 변수 / 객체 정의
  // -------------------------
  String _status = ''; // 로그인 상태 표시
  bool _isLoading = false; // 로딩 표시
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
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

    if (_accessToken != null) scheduleTokenRefresh();
  }

  /// ===== 토큰 저장 =====
  Future<void> _saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
    notifyListeners();
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
        final access = data['access'];
        final refresh = data['refresh'];
        if (access != null && refresh != null) {
          await _saveTokens(access, refresh);
          scheduleTokenRefresh();
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

  // 모바일용 social login (idToken 기반)
  Future<Map<String, dynamic>> socialLoginMobile({
    required String provider,
    required String idToken,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.googleMobileLogin),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );

    if (response.statusCode >= 200 && response.statusCode < 500) {
      return jsonDecode(response.body);
    } else {
      throw Exception('서버 로그인 실패: ${response.body}');
    }
  }

  Future<String> loginWithGoogleMobile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return '사용자가 취소함';

      final auth = await account.authentication;
      print('##################################################');
      print('Google 계정 선택됨: ${account.email}');

      print('accessToken: ${auth.accessToken}');
      print('idToken: ${auth.idToken}');


      final idToken = auth.idToken;
      if (idToken == null) return 'ID 토큰 획득 실패';

      final data = await socialLoginMobile(provider: 'google', idToken: idToken);
      final status = data['statusCode'];

      if (status == 200 || status == 201) {
        final access = data['access'];
        final refresh = data['refresh'];
        if (access != null && refresh != null) {
          await _saveTokens(access, refresh);
          scheduleTokenRefresh();
        }
        return 'success';
      } else if (status == 202) {
        return 'signup_required:${json.encode(data['user_data'])}';
      } else {
        return data['message'] ?? data['error'] ?? '알 수 없는 오류';
      }
    } catch (e, stacktrace) {
      print('OAuth 처리 오류: $e');
      print(stacktrace);
      return 'OAuth 처리 오류: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }



  /// ===== 토큰 갱신 =====
  Future<bool> _refreshTokenIfNeeded() async {
    if (_isRefreshing || _refreshToken == null) return false;
    if (_accessToken != null && !JwtDecoder.isExpired(_accessToken!)) return true;

    _isRefreshing = true;

    try {
      // 기존 AuthService refreshAccessToken 사용
      final success = await apiService.refreshAccessToken();

      _isRefreshing = false;

      if (success) {
        _accessToken = await apiService.getAccessToken();
        notifyListeners();
        scheduleTokenRefresh();
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      _isRefreshing = false;
      await logout();
      return false;
    }
  }

  // public wrapper 추가
  Future<bool> refreshTokenIfNeeded() async {
    return await _refreshTokenIfNeeded();
  }

  /// ===== 인증 요청 래퍼 =====
  Future<http.Response?> authenticatedRequest(
      Future<http.Response> Function(String accessToken) requestFn) async {
    if (_accessToken == null) {
      _accessToken = await _storage.read(key: 'access_token');
      if (_accessToken == null) return null;
    }

    if (JwtDecoder.isExpired(_accessToken!)) {
      final refreshed = await _refreshTokenIfNeeded();
      if (!refreshed) return null;
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
      debugPrint('Authenticated request error: $e');
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
    scheduleTokenRefresh();
  }

  /// ===== 백그라운드 자동 갱신 스케줄 =====
  void scheduleTokenRefresh() {
    if (_accessToken == null) return;

    final expirationDate = JwtDecoder.getExpirationDate(_accessToken!);
    final now = DateTime.now();
    final refreshBefore = expirationDate.subtract(const Duration(minutes: 1));

    final duration = refreshBefore.difference(now);
    if (duration.isNegative) return;

    Future.delayed(duration, () async {
      await _refreshTokenIfNeeded();
      scheduleTokenRefresh(); // 재귀 예약
    });
  }
}
