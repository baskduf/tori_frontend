import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api/auth'; // 실제 IP로 변경 필요
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  /// 회원가입
  Future<bool> signup({
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

    return response.statusCode >= 200 && response.statusCode < 300;
  }


  /// 로그인 (토큰 저장)
  Future<bool> login({
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access'] != null && data['refresh'] != null) {
          await storage.write(key: 'access_token', value: data['access']);
          await storage.write(key: 'refresh_token', value: data['refresh']);
          print('Login success, tokens saved');
          return true;
        } else {
          print('Login failed: Tokens missing in response');
          return false;
        }
      } else {
        print('Login failed: ${response.statusCode}, ${response.body}');
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      return false;
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
