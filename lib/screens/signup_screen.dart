import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _apiService = ApiService();

  final _formKey = GlobalKey<FormState>();
  String username = '';
  String password = '';
  int age = 18;
  String gender = 'male';
  File? _profileImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 필드를 채우고 프로필 사진을 선택하세요')),
      );
      return;
    }
    _formKey.currentState!.save();

    bool success = await _apiService.signup(
      username: username,
      password: password,
      age: age,
      gender: gender,
      profileImagePath: _profileImage!.path,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원가입 성공! 로그인하세요')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원가입 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('회원가입')),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: '아이디'),
                  onSaved: (val) => username = val ?? '',
                  validator: (val) => val == null || val.isEmpty ? '필수 입력' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: '비밀번호'),
                  obscureText: true,
                  onSaved: (val) => password = val ?? '',
                  validator: (val) => val == null || val.length < 6 ? '6자 이상' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: '나이'),
                  keyboardType: TextInputType.number,
                  onSaved: (val) => age = int.tryParse(val ?? '0') ?? 18,
                  validator: (val) {
                    int? n = int.tryParse(val ?? '');
                    if (n == null || n < 1) return '유효한 나이 입력';
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: gender,
                  items: [
                    DropdownMenuItem(child: Text('남성'), value: 'male'),
                    DropdownMenuItem(child: Text('여성'), value: 'female'),
                  ],
                  onChanged: (val) => setState(() => gender = val ?? 'male'),
                  decoration: InputDecoration(labelText: '성별'),
                ),
                SizedBox(height: 10),
                _profileImage == null
                    ? Text('프로필 사진을 선택하세요')
                    : Image.file(_profileImage!, height: 150),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('사진 선택'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text('회원가입'),
                )
              ],
            ),
          ),
        ));
  }
}
