import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const baseUrl = 'http://localhost:8000/api/auth';
  final FlutterSecureStorage storage = FlutterSecureStorage();

  // 회원가입 (multipart/form-data)
  Future<bool> signup({
    required String username,
    required String password,
    required int age,
    required String gender,
    required String profileImagePath,
  }) async {
    var uri = Uri.parse('$baseUrl/signup/');
    var request = http.MultipartRequest('POST', uri);

    request.fields['username'] = username;
    request.fields['password'] = password;
    request.fields['age'] = age.toString();
    request.fields['gender'] = gender;

    request.files.add(await http.MultipartFile.fromPath(
      'profile_image',
      profileImagePath,
    ));

    var response = await request.send();
    if (response.statusCode == 200) {
      return true;
    } else {
      print('Signup failed: ${response.statusCode}');
      return false;
    }
  }

  // 로그인
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    var uri = Uri.parse('$baseUrl/login/');
    var response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      await storage.write(key: 'access', value: data['access']);
      await storage.write(key: 'refresh', value: data['refresh']);
      return true;
    } else {
      print('Login failed: ${response.body}');
      return false;
    }
  }

  // 로그아웃
  Future<bool> logout() async {
    String? refresh = await storage.read(key: 'refresh');
    if (refresh == null) return false;

    var uri = Uri.parse('$baseUrl/logout/');
    var response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}));

    if (response.statusCode == 200) {
      await storage.delete(key: 'access');
      await storage.delete(key: 'refresh');
      return true;
    } else {
      print('Logout failed: ${response.body}');
      return false;
    }
  }

  // 토큰 가져오기 (필요시)
  Future<String?> getAccessToken() async {
    return await storage.read(key: 'access');
  }
}
