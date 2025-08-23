import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/match_service.dart';
import '../layouts/responsive_scaffold.dart';

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
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  success ? Icons.check_circle_outline : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  success ? '매칭 조건이 저장되었습니다 😄' : '저장 실패 😢',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          duration: const Duration(seconds: 3),
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
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.2),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _glassButton({
    required String label,
    required VoidCallback onPressed,
    Color color = const Color(0xFF424242),
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.75),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 8,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPreferredGenderDropdown() {
    final Map<String, Map<String, dynamic>> options = {
      'any': {'label': '상관없음', 'gem': 0},
      'male': {'label': '남성', 'gem': 5},
      'female': {'label': '여성', 'gem': 20},
    };

    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          _preferredGender = value;
        });
      },
      color: Colors.grey[900]?.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      itemBuilder: (context) {
        return options.entries.map((entry) {
          final key = entry.key;
          final label = entry.value['label'];
          final gem = entry.value['gem'];
          return PopupMenuItem(
            value: key,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(color: Colors.white)),
                if (gem > 0)
                  Row(
                    children: [
                      Text('$gem', style: const TextStyle(color: Colors.amber)),
                      const SizedBox(width: 4),
                      const Icon(Icons.diamond, color: Colors.amber, size: 16),
                    ],
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            options[_preferredGender]!['label'],
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const Icon(Icons.arrow_drop_down, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildAgeRangeSlider() {
    return RangeSlider(
      values: _ageRange,
      min: 18,
      max: 60,
      divisions: 42,
      labels: RangeLabels(
        _ageRange.start.round().toString(),
        _ageRange.end.round().toString(),
      ),
      onChanged: (values) => setState(() => _ageRange = values),
    );
  }

  Widget _buildRadiusSlider() {
    return Slider(
      value: _radiusKm.toDouble(),
      min: 1,
      max: 50,
      divisions: 49,
      label: '$_radiusKm km',
      onChanged: (value) => setState(() => _radiusKm = value.round()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _isSaving
              ? const Center(
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          )
              : Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text(
                  '선호 성별',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 12),
                _glassContainer(child: _buildPreferredGenderDropdown()),
                const SizedBox(height: 32),
                const Text(
                  '선호 나이',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 12),
                _glassContainer(child: _buildAgeRangeSlider()),
                const SizedBox(height: 32),
                Row(
                  mainAxisSize: MainAxisSize.min, // 텍스트 길이만큼만 차지
                  children: [
                    const Text(
                      '거리',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 8), // 텍스트 간격
                    Row(
                      children: const [
                        Text(
                          '(준비중)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey, // 회색으로 표시
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.build, // 수리 망치 아이콘
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ],
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
