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

  String _preferredGender = 'any';
  RangeValues _ageRange = const RangeValues(20, 30);
  int _radiusKm = 10;

  bool _isSaving = false;

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    try {
      final success = await _matchService.saveMatchSettings(
        preferredGender: _preferredGender,
        ageRange: [_ageRange.start.toInt(), _ageRange.end.toInt()],
        radiusKm: _radiusKm,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '매칭 조건이 저장되었습니다.' : '저장 실패'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  Widget _buildPreferredGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _preferredGender,
      items: const [
        DropdownMenuItem(value: 'any', child: Text('상관없음')),
        DropdownMenuItem(value: 'male', child: Text('남성')),
        DropdownMenuItem(value: 'female', child: Text('여성')),
      ],
      onChanged: (value) => setState(() => _preferredGender = value ?? 'any'),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: const Icon(Icons.person_search_outlined),
      ),
      style: const TextStyle(fontSize: 16),
      dropdownColor: Colors.white,
      elevation: 4,
    );
  }

  Widget _buildAgeRangeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.blueAccent.withOpacity(0.3),
            thumbColor: Colors.blueAccent,
            overlayColor: Colors.blueAccent.withOpacity(0.2),
            valueIndicatorColor: Colors.blueAccent,
          ),
          child: RangeSlider(
            values: _ageRange,
            min: 18,
            max: 60,
            divisions: 42,
            labels: RangeLabels(
              _ageRange.start.round().toString(),
              _ageRange.end.round().toString(),
            ),
            onChanged: (values) => setState(() => _ageRange = values),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            '나이: ${_ageRange.start.round()} - ${_ageRange.end.round()} 세',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _buildRadiusSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.blueAccent.withOpacity(0.3),
            thumbColor: Colors.blueAccent,
            overlayColor: Colors.blueAccent.withOpacity(0.2),
            valueIndicatorColor: Colors.blueAccent,
          ),
          child: Slider(
            value: _radiusKm.toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            label: '$_radiusKm km',
            onChanged: (value) => setState(() => _radiusKm = value.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            '반경: $_radiusKm km',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매칭 설정'),
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('선호 성별', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _buildPreferredGenderDropdown(),
              const SizedBox(height: 32),

              const Text('선호 나이대', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _buildAgeRangeSlider(),
              const SizedBox(height: 32),

              const Text('반경 (킬로미터)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _buildRadiusSlider(),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                child: const Text(
                  '저장',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
