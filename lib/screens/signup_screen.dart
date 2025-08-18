import 'dart:ui';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recaptcha_v3/recaptcha_v3.dart';  // 변경된 import

import '../layouts/main_layout.dart';
import '../widgets/custom_textfield_widget.dart';
import '../widgets/primary_button_widget.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});


  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String gender = 'male';
  io.File? _profileImage;
  Uint8List? _webImageBytes;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animController;

  String name = '';
  String profileUrl = '';
  String tempToken = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      name = args['name'] ?? '';
      profileUrl = args['profileUrl'] ?? '';
      tempToken = args['tempToken'] ?? '';
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    // recaptcha_v3에서는 main.dart에서 이미 초기화되므로 여기서 추가 설정 불필요
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _profileImage = null;
          });
        } else {
          setState(() {
            _profileImage = io.File(pickedFile.path);
            _webImageBytes = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 오류: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        (!kIsWeb && _profileImage == null) ||
        (kIsWeb && _webImageBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 채우고 프로필 사진을 선택하세요')),
      );
      return;
    }

    setState(() => _isLoading = true);
    _animController.repeat(reverse: true);

    try {
      // recaptcha_v3 패키지 사용법
      String? recaptchaToken = await Recaptcha.execute('signup');

      if (recaptchaToken == null || recaptchaToken == 'null returned') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('캡차 인증 실패')),
        );
        setState(() => _isLoading = false);
        _animController.stop();
        return;
      }

      // 기존 signup 호출 + tempToken 추가
      String respStr = await _apiService.signup(
        username: _usernameController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 18,
        gender: gender,
        profileImageBytes: kIsWeb ? _webImageBytes : null,
        profileImageFile: kIsWeb ? null : _profileImage,
        recaptchaToken: recaptchaToken,
        tempToken: tempToken,
      );

      _animController.stop();
      setState(() => _isLoading = false);

      if (!mounted) return;

      // 서버 응답을 팝업으로 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('회원가입 결과'),
          content: Text(respStr),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (respStr.contains('성공')) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      _animController.stop();
      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    }
  }


  Widget _glassContainer({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _glassButton({required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.15),
        elevation: 6,
        shadowColor: Colors.black54,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProfileImagePreview() {
    if (_profileImage == null && _webImageBytes == null) {
      return const Text(
        '프로필 사진을 선택하세요',
        style: TextStyle(color: Colors.white54),
      );
    } else if (kIsWeb && _webImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(80),
        child: Image.memory(
          _webImageBytes!,
          height: 160,
          width: 160,
          fit: BoxFit.cover,
        ),
      );
    } else if (_profileImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(80),
        child: Image.file(
          _profileImage!,
          height: 160,
          width: 160,
          fit: BoxFit.cover,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: '회원가입',
      appBarActions: [],
      appBarBackgroundColor: Colors.transparent,
      appBarIconColor: Colors.white70,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF121212),
              Color(0xFF1B1B1B),
              Color(0xFF272727),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _glassContainer(
                    child: CustomTextField(
                      hint: '아이디',
                      controller: _usernameController,
                      validator: (val) => val == null || val.isEmpty ? '필수 입력' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _glassContainer(
                    child: CustomTextField(
                      hint: '나이',
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        final n = int.tryParse(val ?? '');
                        if (n == null || n < 1) return '유효한 나이 입력';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _glassContainer(
                    child: DropdownButtonFormField<String>(
                      value: gender,
                      items: const [
                        DropdownMenuItem(child: Text('남성'), value: 'male'),
                        DropdownMenuItem(child: Text('여성'), value: 'female'),
                      ],
                      onChanged: (val) => setState(() => gender = val ?? 'male'),
                      decoration: const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _glassContainer(
                    child: Column(
                      children: [
                        _buildProfileImagePreview(),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('사진 선택'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // reCAPTCHA 브랜딩 추가 (Google 정책상 필수)
                  const RecaptchaBrand(),
                  const SizedBox(height: 20),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _isLoading
                        ? FadeTransition(
                      opacity: _animController.drive(
                        Tween(begin: 0.4, end: 1.0).chain(
                          CurveTween(curve: Curves.easeInOut),
                        ),
                      ),
                      child: const CircularProgressIndicator(color: Colors.white),
                    )
                        : _glassButton(text: '회원가입', onPressed: _submit),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}