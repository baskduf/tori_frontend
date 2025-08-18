import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api/auth';
  static const String tokenUrl = 'http://localhost:8000/token';

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  /// ===== 비밀번호 검증 =====
  String? passwordValidator(String? val) {
    if (val == null || val.isEmpty) return '비밀번호를 입력하세요';
    if (val.length < 8) return '비밀번호는 최소 8자 이상이어야 합니다';
    if (!RegExp(r'[A-Z]').hasMatch(val)) return '대문자를 최소 1개 포함해야 합니다';
    if (!RegExp(r'[a-z]').hasMatch(val)) return '소문자를 최소 1개 포함해야 합니다';
    if (!RegExp(r'\d').hasMatch(val)) return '숫자를 최소 1개 포함해야 합니다';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(val)) return '특수문자를 최소 1개 포함해야 합니다';
    return null;
  }

  /// ===== 회원가입 =====
  Future<String> signup({
    required String username,
    required int age,
    required String gender,
    required String tempToken,
    String? recaptchaToken,
    io.File? profileImageFile,
    Uint8List? profileImageBytes,
  }) async {
    final uri = Uri.parse('$baseUrl/signup/');
    final request = http.MultipartRequest('POST', uri);

    request.fields.addAll({
      'username': username,
      'age': age.toString(),
      'gender': gender,
      'temp_token' : tempToken
    });

    if (recaptchaToken != null) {
      request.fields['recaptcha_token'] = recaptchaToken;
    }

    // 프로필 이미지 업로드
    if (kIsWeb && profileImageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'profile_image',
        profileImageBytes,
        filename: 'web_image.png',
        contentType: MediaType('image', 'png'),
      ));
    } else if (profileImageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profile_image',
        profileImageFile.path,
      ));
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    print('Signup response: ${response.statusCode}, body: $respStr');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return "회원가입 성공!";
    }

    try {
      final jsonBody = jsonDecode(respStr);
      return jsonBody.values.first[0].toString();
    } catch (_) {
      return "회원가입 실패";
    }
  }

  /// ===== 토큰 갱신 =====
  Future<bool> refreshAccessToken() async {
    final refresh = await storage.read(key: 'refresh_token');
    if (refresh == null) return false;

    try {
      final uri = Uri.parse('$tokenUrl/refresh/');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access'] != null) {
          await storage.write(key: 'access_token', value: data['access']);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Refresh error: $e');
      return false;
    }
  }

  /// ===== 로그인 =====
  Future<String> login({
    required String username,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/login/');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final respStr = utf8.decode(response.bodyBytes);
      print('Login response: $respStr');

      if (response.statusCode == 200) {
        final data = jsonDecode(respStr);
        if (data['access'] != null && data['refresh'] != null) {
          await _saveTokens(data['access'], data['refresh']);
          return 'success';
        }
      }

      final data = jsonDecode(respStr);
      return data['detail'] ?? "로그인 실패";
    } catch (e) {
      return '로그인 오류: $e';
    }
  }

  /// ===== 로그아웃 =====
  Future<bool> logout() async {
    final access = await storage.read(key: 'access_token');
    final refresh = await storage.read(key: 'refresh_token');
    if (access == null || refresh == null) return false;

    try {
      final uri = Uri.parse('$baseUrl/logout/');
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $access',
        },
        body: jsonEncode({'refresh': refresh}),
      );
    } catch (_) {}

    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    return true;
  }

  /// ===== 소셜 로그인 =====
  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String code,
    String? username,
    int? age,
    String? gender,
    io.File? profileImageFile,
  }) async {
    final uri = Uri.parse('$baseUrl/oauth/$provider/code');
    final request = http.MultipartRequest('POST', uri);
    request.fields['provider'] = provider;
    request.fields['code'] = code;
    request.fields['redirect_uri'] = 'http://localhost:51577/api/auth/oauth/$provider/code';

    if (username != null) request.fields['username'] = username;
    if (age != null) request.fields['age'] = age.toString();
    if (gender != null) request.fields['gender'] = gender;
    if (profileImageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profile_image',
        profileImageFile.path,
      ));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return jsonDecode(response.body)..['statusCode'] = response.statusCode;
  }

  /// ===== 토큰 관련 =====
  Future<void> _saveTokens(String access, String refresh) async {
    await storage.write(key: 'access_token', value: access);
    await storage.write(key: 'refresh_token', value: refresh);
  }

  Future<String?> getAccessToken() => storage.read(key: 'access_token');
  Future<String?> getRefreshToken() => storage.read(key: 'refresh_token');
}
