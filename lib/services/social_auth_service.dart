// lib/services/social_auth_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SocialAuthService {
  static const String baseUrl = 'http://localhost:8000'; // Django 서버 URL

  // 소셜 로그인 유저 존재 여부 확인
  static Future<bool> checkUserExists(String provider, String accessToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/oauth/$provider/check/'),
      body: {
        'access_token': accessToken,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['exists'] ?? false;
    } else {
      throw Exception('회원 존재 여부 확인 실패: ${response.body}');
    }
  }

  // 소셜 회원가입
  static Future<String> registerSocialUser({
    required String provider,
    required String accessToken,
    required String username,
    required int age,
    required String gender,
    File? profileImageFile,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/oauth/$provider/register/'),
    );

    request.fields['access_token'] = accessToken;
    request.fields['username'] = username;
    request.fields['age'] = age.toString();
    request.fields['gender'] = gender;

    if (profileImageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profile_image',
        profileImageFile.path,
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return 'success';
    } else {
      return '회원가입 실패: ${response.body}';
    }
  }

  // 로그인 (JWT 발급)
  static Future<String> loginSocialUser(String provider, String accessToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/oauth/$provider/jwt/'),
      body: {
        'access_token': accessToken,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access']; // JWT 토큰
    } else {
      throw Exception('로그인 실패: ${response.body}');
    }
  }
}
