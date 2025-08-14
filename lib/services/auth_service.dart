import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api/auth'; // 실제 IP로 변경 필요
  static const String tokenUrl = 'http://localhost:8000/token'; // 실제 IP로 변경 필요
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  String? passwordValidator(String? val) {
    if (val == null || val.isEmpty) return '비밀번호를 입력하세요';
    if (val.length < 8) return '비밀번호는 최소 8자 이상이어야 합니다';
    if (!RegExp(r'[A-Z]').hasMatch(val)) return '대문자를 최소 1개 포함해야 합니다';
    if (!RegExp(r'[a-z]').hasMatch(val)) return '소문자를 최소 1개 포함해야 합니다';
    if (!RegExp(r'\d').hasMatch(val)) return '숫자를 최소 1개 포함해야 합니다';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(val)) return '특수문자를 최소 1개 포함해야 합니다';
    return null;
  }

  /// 회원가입
  Future<String> signup({
    required String username,
    required String password,
    required int age,
    required String gender,
    String? recaptchaToken, // 추가
    io.File? profileImageFile,
    Uint8List? profileImageBytes,
  }) async {
    final uri = Uri.parse('$baseUrl/signup/');
    var request = http.MultipartRequest('POST', uri);

    request.fields['username'] = username;
    request.fields['password'] = password;
    request.fields['age'] = age.toString();
    request.fields['gender'] = gender;

    if (recaptchaToken != null) {
      request.fields['recaptcha_token'] = recaptchaToken;
    }

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
    print('Signup response status: ${response.statusCode}, body: $respStr');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return "회원가입 성공!";
    } else {
      try {
        final jsonBody = jsonDecode(respStr);
        // 첫 번째 필드의 첫 번째 메시지 반환
        final firstKey = jsonBody.keys.first;
        final firstMessage = jsonBody[firstKey][0];
        return firstMessage.toString();
      } catch (e) {
        return "회원가입 실패";
      }
    }
  }

  /// 토큰 갱신 API 호출
  Future<bool> refreshAccessToken() async {
    try {
      final refresh = await storage.read(key: 'refresh_token');
      if (refresh == null) {
        print('Refresh failed: No refresh token');
        return false;
      }

      final uri = Uri.parse('$tokenUrl/refresh/');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['access'] != null) {
          await storage.write(key: 'access_token', value: data['access']);
          print('Access token refreshed successfully');
          return true;
        } else {
          print('Refresh failed: No access token in response');
          return false;
        }
      } else {
        print('Refresh failed: ${response.statusCode}, ${response.body}');
        return false;
      }
    } catch (e) {
      print('Refresh token error: $e');
      return false;
    }
  }

  /// 로그인 (토큰 저장 + 서버 메시지 반환, UTF-8 안전)
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

      // UTF-8로 정확히 디코딩
      final respStr = utf8.decode(response.bodyBytes);
      print('서버 응답 JSON: $respStr');

      if (response.statusCode == 200) {
        final data = jsonDecode(respStr);
        if (data['access'] != null && data['refresh'] != null) {
          await storage.write(key: 'access_token', value: data['access']);
          await storage.write(key: 'refresh_token', value: data['refresh']);
          return 'success';
        } else {
          return '로그인 실패: 토큰 누락';
        }
      } else {
        try {
          final data = jsonDecode(respStr);
          // detail이나 username, password 필드 메시지 우선 반환
          if (data['detail'] != null) return data['detail'].toString();
          if (data['username'] != null) return data['username'][0].toString();
          if (data['password'] != null) return data['password'][0].toString();
        } catch (_) {}
        return '로그인 실패';
      }
    } catch (e) {
      return '로그인 오류: $e';
    }
  }

  /// 로그아웃 (토큰 삭제 및 서버에 리프레시 토큰 전달)
  Future<bool> logout() async {
    try {
      final access = await storage.read(key: 'access_token');
      final refresh = await storage.read(key: 'refresh_token');

      if (access == null || refresh == null) {
        print('Logout failed: Missing tokens');
        return false;
      }

      final uri = Uri.parse('$baseUrl/logout/');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $access',
        },
        body: jsonEncode({'refresh': refresh}),
      );

      if (response.statusCode == 200 || response.statusCode == 205) {
        await storage.delete(key: 'access_token');
        await storage.delete(key: 'refresh_token');
        print('Logout success, tokens deleted');
        return true;
      } else {
        print('Logout failed: ${response.statusCode}, ${response.body}');
        return false;
      }
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }

  /// 저장된 Access Token 읽기
  Future<String?> getAccessToken() async {
    try {
      final token = await storage.read(key: 'access_token');
      print('Access token read: $token');
      return token;
    } catch (e) {
      print('Error reading access token: $e');
      return null;
    }
  }
}
