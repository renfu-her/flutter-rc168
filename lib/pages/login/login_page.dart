import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';

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

  @override
  void dispose() {
    // 確保在widget被移除時釋放控制器資源
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
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
        '${appUrl}/index.php?route=extension/module/api/gws_customer/login&api_key=${apiKey}', // 替换为您的API端点
        data: formData,
      );

      print(response.data['login'][0]['status']);

      if (response.data['login'][0]['status'] == true) {
        email = _emailController.text;
        isLogin = true;
        widget.onLoginSuccess();
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
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('確定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('登入'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white, // 根據您的截圖，AppBar是紅色的
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
                _isLoading ? '登录中...' : '登录', // 当加载时显示登录中...
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _login,
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
