import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const baseUrl = 'http://localhost:8000/api/auth'; // 실제 IP로 변경
  final FlutterSecureStorage storage = FlutterSecureStorage();

  Future<bool> signup({
    required String username,
    required String password,
    required int age,
    required String gender,
    required String profileImagePath,
  }) async {
    try {
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
      final respStr = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        print('Signup failed: ${response.statusCode}, $respStr');
        return false;
      }
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/login/');
      var response = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['access'] != null && data['refresh'] != null) {
          await storage.write(key: 'access', value: data['access']);
          await storage.write(key: 'refresh', value: data['refresh']);
          return true;
        }
        print('Login failed: Tokens missing in response');
        return false;
      } else {
        print('Login failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      String? access = await storage.read(key: 'access');
      String? refresh = await storage.read(key: 'refresh');

      if (access == null || refresh == null) {
        print('Logout failed: Missing tokens');
        return false;
      }

      var uri = Uri.parse('$baseUrl/logout/');

      var response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $access',
        },
        body: jsonEncode({'refresh': refresh}),
      );

      if (response.statusCode == 200 || response.statusCode == 205) {
        await storage.delete(key: 'access');
        await storage.delete(key: 'refresh');
        return true;
      } else {
        print('Logout failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }

  Future<String?> getAccessToken() async {
    return await storage.read(key: 'access');
  }
}
