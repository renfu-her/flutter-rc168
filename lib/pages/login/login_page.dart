import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:rc168/responsive_text.dart';

class LoginPage extends StatefulWidget {
  final Function onLoginSuccess;

  LoginPage({super.key, required this.onLoginSuccess});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final dio = Dio();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final LocalAuthentication auth = LocalAuthentication();
  bool? _canCheckBiometrics;
  List<BiometricType>? _availableBiometrics;
  String _authorized = 'Not Authorized';
  bool _isAuthenticating = false;

  @override
  void dispose() {
    // 確保在widget被移除時釋放控制器資源
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final formData = FormData.fromMap({
      'email': _emailController.text,
      'password': _passwordController.text,
    });

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showDialog('錯誤', '請填寫帳號密碼');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var response = await dio.post(
        '${appUri}/gws_customer/login&api_key=${apiKey}', // 替换为您的API端点
        data: formData,
      );

      // print{response.data['login'][0]['status']);

      if (response.data['login'][0]['status'] == true) {
        email = _emailController.text;
        isLogin = true;
        widget.onLoginSuccess();
        saveLoginState(isLogin);

        await prefs.setString('email', _emailController.text);
        // print{email);

        Navigator.pop(context);
      } else {
        _showDialog('登入失敗', '帳號密碼輸入錯誤。');
      }
    } catch (e) {
      _showDialog('登入失敗', '登入發生錯誤。');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: ResponsiveText(
            title,
            baseFontSize: 38,
          ),
          content: ResponsiveText(
            message,
            baseFontSize: 36,
            maxLines: 5,
          ),
          actions: <Widget>[
            TextButton(
              child: ResponsiveText(
                '確定',
                baseFontSize: 36,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      setState(() {
        _isAuthenticating = true; // 更新狀態為正在認證
        _authorized = '正在進行身份認證';
      });

      // 調用local_auth的authenticate方法
      authenticated = await auth.authenticate(
        localizedReason: '請掃描您的指紋進行認證', // 在彈窗中顯示的提示信息
        options: const AuthenticationOptions(
          useErrorDialogs: true, // 出錯時是否顯示錯誤對話框
          stickyAuth: true,
          biometricOnly: true, // 背景持久化認證會話
        ),
      );

      setState(() {
        _authorized = authenticated ? '認證成功' : '認證失敗';
        if (authenticated) {
          email = prefs.getString('email').toString();
          isLogin = true;
          widget.onLoginSuccess();
          saveLoginState(isLogin);

          Navigator.pop(context);
        }
      });
    } on PlatformException catch (e) {
      setState(() {
        _authorized = "錯誤 - ${e.message}";
        _isAuthenticating = false; // 更新狀態為非認證狀態
      });
      print(e);
    }
    if (!mounted) return;
    final String message = authenticated ? '認證成功' : '認證失敗';
    setState(() {
      _isAuthenticating = false;
      _authorized = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('登入'),
        backgroundColor: Colors.blue,
        foregroundColor: Color(0xFF4F4E4C), // 根據您的截圖，AppBar是紅色的
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: '請輸入您的電子郵件',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16.0), // 添加間隔
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '密碼',
                hintText: '請輸入您的密碼',
              ),
              obscureText: true, // 隱藏密碼輸入
            ),
            SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _isLoading ? null : _login, // 当加载时禁用按钮
              child: Text(
                _isLoading ? '登入中...' : '登入', // 当加载时显示登录中...
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Color(0xFF4F4E4C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigator.of(context).push(MaterialPageRoute(
                //     builder: (context) => const FingerprintPage()));
                _authenticate();
              },
              child: Text(
                '使用指紋登入',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> saveLoginState(bool isLoggedIn) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', isLoggedIn);
}

Future<void> saveFingerprintOption(bool useFingerprint) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('useFingerprint', useFingerprint);
}
