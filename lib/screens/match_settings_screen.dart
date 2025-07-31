import 'package:flutter/material.dart';
import '../services/match_service.dart';

class MatchSettingsScreen extends StatefulWidget {
  const MatchSettingsScreen({super.key});

  @override
  State<MatchSettingsScreen> createState() => _MatchSettingsScreenState();
}

class _MatchSettingsScreenState extends State<MatchSettingsScreen> {
  final MatchService _matchService = MatchService();

  final _formKey = GlobalKey<FormState>();

  String _preferredGender = 'all';
  RangeValues _ageRange = const RangeValues(20, 30);
  int _radiusKm = 10;

  bool _isSaving = false;

  void _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
    });

    try {
      bool success = await _matchService.saveMatchSettings(
        preferredGender: _preferredGender,
        ageRange: [_ageRange.start.toInt(), _ageRange.end.toInt()],
        radiusKm: _radiusKm,
      );

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('매칭 조건이 저장되었습니다.')),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장 실패')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매칭 설정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('선호 성별', style: TextStyle(fontSize: 18)),
              DropdownButtonFormField<String>(
                value: _preferredGender,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('상관없음')),
                  DropdownMenuItem(value: 'male', child: Text('남성')),
                  DropdownMenuItem(value: 'female', child: Text('여성')),
                ],
                onChanged: (value) {
                  setState(() {
                    _preferredGender = value ?? 'all';
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 20),
              const Text('선호 나이대', style: TextStyle(fontSize: 18)),
              RangeSlider(
                values: _ageRange,
                min: 18,
                max: 60,
                divisions: 42,
                labels: RangeLabels(
                  _ageRange.start.round().toString(),
                  _ageRange.end.round().toString(),
                ),
                onChanged: (RangeValues values) {
                  setState(() {
                    _ageRange = values;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text('반경 (킬로미터)', style: TextStyle(fontSize: 18)),
              Slider(
                value: _radiusKm.toDouble(),
                min: 1,
                max: 50,
                divisions: 49,
                label: '$_radiusKm km',
                onChanged: (double value) {
                  setState(() {
                    _radiusKm = value.round();
                  });
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('저장'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
