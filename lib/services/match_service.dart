import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MatchSetting {
  final int id;
  final String preferredGender;
  final int ageRangeMin;
  final int ageRangeMax;
  final int radiusKm;

  MatchSetting({
    required this.id,
    required this.preferredGender,
    required this.ageRangeMin,
    required this.ageRangeMax,
    required this.radiusKm,
  });



  factory MatchSetting.fromJson(Map<String, dynamic> json) {
    return MatchSetting(
      id: json['id'],
      preferredGender: json['preferred_gender'],
      ageRangeMin: json['age_min'],
      ageRangeMax: json['age_max'],
      radiusKm: json['radius_km'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "preferred_gender": preferredGender,
      "age_range_min": ageRangeMin,
      "age_range_max": ageRangeMax,
      "radius_km": radiusKm,
    };
  }
}

class MatchService {
  static const String baseUrl = 'http://localhost:8000/api/match/settings/';
  final FlutterSecureStorage storage = FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await storage.read(key: 'access_token');
  }

  Future<bool> saveMatchSettings({
    required String preferredGender,
    required List<int> ageRange,
    required int radiusKm,
  }) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'preferred_gender': preferredGender,
        'age_min': ageRange[0],
        'age_max': ageRange[1],
        'radius_km': radiusKm,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }


  Future<MatchSetting?> fetchMatchSetting() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return MatchSetting.fromJson(jsonData);
    } else {
      throw Exception('Failed to load match settings');
    }
  }

  Future<MatchSetting?> updateMatchSetting(MatchSetting setting) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(setting.toJson()),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return MatchSetting.fromJson(jsonData);
    } else {
      throw Exception('Failed to update match settings');
    }
  }
}
