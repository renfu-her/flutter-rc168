import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class FingerprintPage extends StatefulWidget {
  @override
  _FingerprintPageState createState() => _FingerprintPageState();
}

class _FingerprintPageState extends State<FingerprintPage> {
  /// 本地认证框架
  final LocalAuthentication auth = LocalAuthentication();

  /// 是否有可用的生物识别技术
  bool? _canCheckBiometrics;

  /// 生物识别技术列表
  List<BiometricType>? _availableBiometrics;

  /// 识别结果
  String _authorized = '验证失败';

  /// 检查是否有可用的生物识别技术
  Future<void> _checkBiometrics() async {
    bool? canCheckBiometrics;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print(e);
    }
    if (!mounted) return;

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
    });
  }

  /// 获取生物识别技术列表
  Future<void> _getAvailableBiometrics() async {
    List<BiometricType>? availableBiometrics;
    try {
      availableBiometrics = await auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print(e);
    }
    if (!mounted) return;

    setState(() {
      _availableBiometrics = availableBiometrics;
    });
  }

  /// 生物识别
  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: '掃描指紋進行身份驗證',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: false,
        ),
      );
    } on PlatformException catch (e) {
      print(e);
    }
    if (!mounted) return;

    setState(() {
      _authorized = authenticated ? '驗證通過' : '驗證失敗';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: Text('指紋辨識'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Text('是否有可用的生物识别技术: $_canCheckBiometrics\n'),
                ElevatedButton(
                  child: const Text('检查生物识别技术'),
                  onPressed: _checkBiometrics,
                ),
                Text('可用的生物识别技术: $_availableBiometrics\n'),
                ElevatedButton(
                  child: const Text('获取可用的生物识别技术'),
                  onPressed: _getAvailableBiometrics,
                ),
                Text('状态: $_authorized\n'),
                ElevatedButton(
                  child: const Text('验证'),
                  onPressed: _authenticate,
                )
              ])),
    ));
  }
}
