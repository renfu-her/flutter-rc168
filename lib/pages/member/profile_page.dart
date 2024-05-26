import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';
import 'package:flutter_responsive_framework/flutter_responsive_framework.dart';
import 'package:rc168/responsive_text.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _passwordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // 添加表单键

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  bool _validateAndSaveForm() {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save(); // Save the form if it's valid
      return true;
    }
    return false;
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: ResponsiveText(
            title,
            baseFontSize: 36,
          ),
          content: ResponsiveText(
            message,
            baseFontSize: 30,
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

  void _loadUserInfo() {
    // 获取保存的用户信息
    String lastNameName = UserPreferences.getLastName() ?? '';
    String firstNameName = UserPreferences.getFirstName() ?? '';
    String email = UserPreferences.getEmail() ?? '';

    // 设置控制器的初始值
    _lastNameController.text = lastNameName;
    _firstNameController.text = firstNameName;
    _emailController.text = email;
  }

  Future<void> _changePassword() async {
    final String apiUrl =
        "${appUri}/gws_customer/change_password&api_key=${apiKey}";

    dio.options.headers['content-Type'] = 'application/x-www-form-urlencoded';
    dio.options.headers["accept"] = "application/json";

    try {
      final response = await Dio().post(apiUrl,
          data: FormData.fromMap({
            'email': _emailController.text,
            'current_password': _currentPasswordController.text,
            'new_password': _newPasswordController.text,
            'confirm': _confirmPasswordController.text,
          }));

      if (response.data['message'][0]['msg_status']) {
        // 如果 msg_status 为 true
        _showDialog('修改密碼成功', '已經更換密碼。');
        // 可以在这里显示成功的提示或执行其他操作
      } else {
        // 如果 msg_status 为 false
        _showDialog('修改密碼失敗', '更新失敗。');
        // 显示失败的原因
      }
    } catch (e) {
      print("请求错误: $e");
      // 处理请求错误
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('會員資料'),
        backgroundColor: Colors.blue,
        foregroundColor: Color(0xFF4F4E4C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey, // 关联 GlobalKey
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: '姓*',
                hintText: '請輸入您的姓',
              ),
            ),
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: '名*',
                hintText: '請輸入您的名稱',
              ),
            ),
            TextFormField(
              controller: _emailController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: '請輸入您的電子郵件',
              ),
            ),
            TextFormField(
              controller: _currentPasswordController,
              obscureText: !_passwordVisible,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '密碼為必填項。';
                }
                return null; // 如果数据有效，则返回 null
              },
              decoration: InputDecoration(
                labelText: '目前密碼',
                hintText: '請輸入目前密碼',
                suffixIcon: IconButton(
                  icon: Icon(
                    // 根据_passwordVisible状态切换图标
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    // 更新状态并切换密码可见性
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
              ),
            ),
            TextFormField(
              controller: _newPasswordController,
              obscureText: !_newPasswordVisible,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '新密碼為必填項。';
                }
                return null; // 如果数据有效，则返回 null
              },
              decoration: InputDecoration(
                labelText: '新密碼',
                hintText: '請輸入新的密碼',
                suffixIcon: IconButton(
                  icon: Icon(
                    // 根据_passwordVisible状态切换图标
                    _newPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    // 更新状态并切换密码可见性
                    setState(() {
                      _newPasswordVisible = !_newPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_confirmPasswordVisible,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '重複密碼為必填項。';
                }
                return null; // 如果数据有效，则返回 null
              },
              decoration: InputDecoration(
                labelText: '重複新的密碼',
                hintText: '請輸入重複新的密碼',
                suffixIcon: IconButton(
                  icon: Icon(
                    // 根据_passwordVisible状态切换图标
                    _confirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    // 更新状态并切换密码可见性
                    setState(() {
                      _confirmPasswordVisible = !_confirmPasswordVisible;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: ElevatedButton(
          onPressed: () {
            // TODO: 處理密碼保存
            if (_validateAndSaveForm()) {
              _changePassword();
            } else {
              _showDialog('提示', '請填寫必填的密碼欄位。');
            }
          },
          child:
              ResponsiveText('儲存', baseFontSize: 36, color: Color(0xFF4F4E4C)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Color(0xFF4F4E4C),
            minimumSize: Size(double.infinity, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}
