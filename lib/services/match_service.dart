import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class MatchService {
  static const baseUrl = 'http://localhost:8000/api/match';
  final ApiService _apiService = ApiService();

  Future<bool> saveMatchSettings({
    required String preferredGender,
    required List<int> ageRange,
    required int radiusKm,
  }) async {
    final token = await _apiService.getAccessToken();
    final response = await http.post(
      Uri.parse('$baseUrl/settings/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'preferred_gender': preferredGender,
        'age_range': ageRange,
        'radius_km': radiusKm,
      }),
    );
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>?> requestRandomMatch() async {
    final token = await _apiService.getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/random/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Random match request failed: ${response.statusCode}');
    }
  }

  Future<bool> cancelMatching() async {
    final token = await _apiService.getAccessToken();
    final response = await http.post(
      Uri.parse('$baseUrl/cancel/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Cancel matching failed: ${response.statusCode} ${response.body}');
      return false;
    }
  }


  Future<String?> sendMatchDecision(int matchId, String decision) async {
    final token = await _apiService.getAccessToken();
    final response = await http.post(
      Uri.parse('$baseUrl/decision/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'match_id': matchId, 'decision': decision}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'];
    } else {
      throw Exception('Match decision failed');
    }
  }
}
