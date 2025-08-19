import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/match_service.dart';

class MatchSettingsScreen extends StatefulWidget {
  const MatchSettingsScreen({super.key});

  @override
  State<MatchSettingsScreen> createState() => _MatchSettingsScreenState();
}

class _MatchSettingsScreenState extends State<MatchSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final MatchService _matchService;
  final _formKey = GlobalKey<FormState>();

  String _preferredGender = 'any';
  RangeValues _ageRange = const RangeValues(20, 30);
  int _radiusKm = 10;

  bool _isSaving = false;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();

    _matchService = Provider.of<MatchService>(context, listen: false);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }
  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

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

  Widget _glassContainer({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _glassButton({
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.blueAccent,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.75),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 8,
        shadowColor: Colors.black87,
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          shadows: [
            Shadow(
              color: Colors.white70,
              offset: Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
      ),
      child: Text(label),
    );
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
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        prefixIcon: const Icon(Icons.person_search_outlined, color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dropdownColor: Colors.grey[900],
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white70,
        shadows: [
          Shadow(
            color: Colors.black54,
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      iconEnabledColor: Colors.white70,
      elevation: 4,
    );
  }

  Widget _buildAgeRangeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.blueAccent.shade200,
            inactiveTrackColor: Colors.blueAccent.shade200.withOpacity(0.3),
            thumbColor: Colors.blueAccent.shade200,
            overlayColor: Colors.blueAccent.shade200.withOpacity(0.2),
            valueIndicatorColor: Colors.blueAccent.shade200,
            trackHeight: 4,
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
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(0, 1),
                  blurRadius: 1,
                ),
              ],
            ),
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
            activeTrackColor: Colors.blueAccent.shade200,
            inactiveTrackColor: Colors.blueAccent.shade200.withOpacity(0.3),
            thumbColor: Colors.blueAccent.shade200,
            overlayColor: Colors.blueAccent.shade200.withOpacity(0.2),
            valueIndicatorColor: Colors.blueAccent.shade200,
            trackHeight: 4,
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
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(0, 1),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('매칭 설정'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white70.withOpacity(0.8)),
        titleTextStyle: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          shadows: [
            Shadow(
              color: Colors.black54,
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      backgroundColor: null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF121212),
              Color(0xFF1E1E1E),
              Color(0xFF2B2B2B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          child: _isSaving
              ? Center(
            child: _glassContainer(
              padding: const EdgeInsets.all(32),
              child: const CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation(Colors.white70),
              ),
            ),
          )
              : Form(
            key: _formKey,
            child: ListView(
              key: ValueKey('form'),
              children: [
                const Text(
                  '선호 성별',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _glassContainer(child: _buildPreferredGenderDropdown()),
                const SizedBox(height: 32),
                const Text(
                  '선호 나이대',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _glassContainer(child: _buildAgeRangeSlider()),
                const SizedBox(height: 32),
                const Text(
                  '반경 (킬로미터)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _glassContainer(child: _buildRadiusSlider()),
                const SizedBox(height: 40),
                _glassButton(label: '저장', onPressed: _saveSettings),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
