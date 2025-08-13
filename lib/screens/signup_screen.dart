import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;

import '../layouts/main_layout.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/primary_button.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String gender = 'male';
  io.File? _profileImage;
  Uint8List? _webImageBytes;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _profileImage = null; // 혹시 몰라 초기화
          });
        } else {
          setState(() {
            _profileImage = io.File(pickedFile.path);
            _webImageBytes = null; // 혹시 몰라 초기화
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 오류: $e')),
      );
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() ||
        (!kIsWeb && _profileImage == null) ||
        (kIsWeb && _webImageBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 채우고 프로필 사진을 선택하세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool success = await _apiService.signup(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      age: int.tryParse(_ageController.text) ?? 18,
      gender: gender,
      profileImageBytes: kIsWeb ? _webImageBytes : null,
      profileImageFile: kIsWeb ? null : _profileImage,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 성공! 로그인하세요')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 실패')),
      );
    }
  }

  Widget _buildProfileImagePreview() {
    if (_profileImage == null && _webImageBytes == null) {
      return const Text(
        '프로필 사진을 선택하세요',
        style: TextStyle(color: Colors.grey),
      );
    } else if (kIsWeb && _webImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(80),
        child: Image.memory(_webImageBytes!, height: 160, width: 160, fit: BoxFit.cover),
      );
    } else if (_profileImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(80),
        child: Image.file(_profileImage!, height: 160, width: 160, fit: BoxFit.cover),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: '회원가입',
      appBarActions: [],
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  hint: '아이디',
                  controller: _usernameController,
                  validator: (val) => val == null || val.isEmpty ? '필수 입력' : null,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  hint: '비밀번호',
                  controller: _passwordController,
                  obscure: true,
                  validator: (val) => val == null || val.length < 6 ? '6자 이상 입력' : null,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  hint: '나이',
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    final n = int.tryParse(val ?? '');
                    if (n == null || n < 1) return '유효한 나이 입력';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: gender,
                  items: const [
                    DropdownMenuItem(child: Text('남성'), value: 'male'),
                    DropdownMenuItem(child: Text('여성'), value: 'female'),
                  ],
                  onChanged: (val) => setState(() => gender = val ?? 'male'),
                  decoration: const InputDecoration(
                    labelText: '성별',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
                _buildProfileImagePreview(),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('사진 선택'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(140, 45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator()
                    : PrimaryButton(
                  text: '회원가입',
                  onPressed: _submit,
                  width: double.infinity,
                  height: 50,
                  borderRadius: 12,
                  color: Colors.blueAccent,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
