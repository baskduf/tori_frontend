import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';
import '../services/auth_service.dart';
import '../widgets/logo_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;

  FocusNode _usernameFocus = FocusNode();
  FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );

    _buttonScaleAnimation = _buttonController.drive(
      Tween<double>(begin: 1.0, end: 0.95),
    );

    // 포커스에 따라 애니메이션 효과 주기 위해 setState 호출
    _usernameFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _buttonController.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    _buttonController.forward();
  }

  void _onTapCancel() {
    _buttonController.forward();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    bool success = await _apiService.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

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

  BoxDecoration _neumorphicDecoration({bool isFocused = false}) {
    final baseColor = const Color(0xFF2E2E2E); // 다크 그레이 배경과 유사
    final shadowColorDark = Colors.black.withOpacity(0.8);
    final shadowColorLight = Colors.grey.shade800;

    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: isFocused
          ? [
        BoxShadow(
          color: Colors.blueAccent.withOpacity(0.7),
          offset: const Offset(-5, -5),
          blurRadius: 15,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: shadowColorDark,
          offset: const Offset(5, 5),
          blurRadius: 15,
          spreadRadius: 1,
        ),
      ]
          : [
        BoxShadow(
          color: shadowColorLight,
          offset: const Offset(-5, -5),
          blurRadius: 10,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: shadowColorDark,
          offset: const Offset(5, 5),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFF1E1E1E); // 다크 그레이 배경

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Logo(),  // 여기 추가
                const SizedBox(height: 40),

                // Text(
                //   '로그인',
                //   style: TextStyle(
                //     fontSize: 32,
                //     fontWeight: FontWeight.bold,
                //     color: Colors.blueAccent.shade200,
                //     shadows: const [
                //       Shadow(
                //         blurRadius: 5,
                //         color: Colors.blueAccent,
                //         offset: Offset(0, 0),
                //       )
                //     ],
                //   ),
                // ),
                const SizedBox(height: 32),

                // 아이디 입력 필드 - focus시 애니메이션 그림자
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: _neumorphicDecoration(isFocused: _usernameFocus.hasFocus),
                  child: TextFormField(
                    focusNode: _usernameFocus,
                    controller: _usernameController,
                    validator: (val) =>
                    val == null || val.isEmpty ? '필수 입력' : null,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '아이디',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 비밀번호 입력 필드 - focus시 애니메이션 그림자
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: _neumorphicDecoration(isFocused: _passwordFocus.hasFocus),
                  child: TextFormField(
                    focusNode: _passwordFocus,
                    controller: _passwordController,
                    obscureText: true,
                    validator: (val) =>
                    val == null || val.isEmpty ? '필수 입력' : null,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      hintText: '비밀번호',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                _isLoading
                    ? const CircularProgressIndicator(color: Colors.blueAccent)
                    : ScaleTransition(
                  scale: _buttonScaleAnimation,
                  child: GestureDetector(
                    onTapDown: _onTapDown,
                    onTapUp: _onTapUp,
                    onTapCancel: _onTapCancel,
                    onTap: _submit,
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.shade700,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF003c8f),
                            offset: const Offset(4, 4),
                            blurRadius: 6,
                          ),
                          BoxShadow(
                            color: Colors.blueAccent.shade400,
                            offset: const Offset(-4, -4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '로그인',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                    color: Colors.black26,
                                    offset: Offset(1, 1),
                                    blurRadius: 2)
                              ]),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: Text(
                    '회원가입 하러 가기',
                    style: TextStyle(
                      color: Colors.blueAccent.shade400,
                      fontWeight: FontWeight.w600,
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
