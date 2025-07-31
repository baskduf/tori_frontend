import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/primary_button.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiService = ApiService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    bool success = await _apiService.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: '로그인',
      showBack: false,
      appBarActions: [],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              hint: '아이디',
              controller: _usernameController,
              validator: (val) => val == null || val.isEmpty ? '필수 입력' : null, keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              hint: '비밀번호',
              controller: _passwordController,
              obscure: true,
              validator: (val) => val == null || val.isEmpty ? '필수 입력' : null, keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : PrimaryButton(
              text: '로그인',
              onPressed: _submit,
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: const Text('회원가입 하러 가기'),
            ),
          ],
        ),
      ),
    );
  }
}
