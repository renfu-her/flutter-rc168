import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<Country> _countries = [];
  List<Zone> _zones = [];
  String _selectedCountryId = '206';
  String _selectedZoneId = '3139';
  String _countryId = '206';
  String _zoneId = '3139';

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();

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
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _onCountrySelected("206");
  }

  @override
  void dispose() {
    // 記得釋放控制器資源
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _telephoneController.dispose();
    _address1Controller.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    try {
      final response = await dio.get('${appUri}/gws_country&api_key=${apiKey}');
      if (response.statusCode == 200) {
        setState(() {
          _countries = List<Country>.from(response.data['country']
              .map((country) => Country.fromJson(country)));
        });
      }
    } catch (e) {
      // 錯誤處理
    }
  }

  Future<void> _loadZones(String countryId) async {
    try {
      final response = await dio
          .get('${appUri}/gws_zone&country_id=$countryId&api_key=${apiKey}');
      if (response.statusCode == 200) {
        setState(() {
          _zones = List<Zone>.from(
              response.data['zones'].map((zone) => Zone.fromJson(zone)));

          if (_zones.isNotEmpty) {
            // 選擇列表中的第一個地區作為預設選擇
            _selectedZoneId = _zones.first.id;
          }
        });
      }
    } catch (e) {
      // 錯誤處理
    }
  }

  // 更新選定國家並加載對應的地區
  void _onCountrySelected(String value) {
    setState(() {
      _selectedCountryId = value;
      _selectedZoneId = '0'; // 將 _selectedZoneId 設為 null
      _zones = []; // 清空地區列表
    });
    _loadZones(value);
  }

  // 函數：提交註冊資訊
  Future<void> submitRegistration() async {
    final formData = FormData.fromMap({
      'firstname': _firstNameController.text,
      'lastname': _lastNameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'confirm': _confirmController.text,
      'telephone': _telephoneController.text,
      'address_1': _address1Controller.text,
      'city': _cityController.text,
      'country_id': _selectedCountryId.toString(),
      'zone_id': _selectedZoneId.toString(),
      'postcode': _postcodeController.text,
      'fax': '',
      'company': '',
      'address_2': '',
      'newsletter': 0,
      'custom_field': {
        'account': '{1: 711}',
        'address': '{1: 711}',
      }
    });

    try {
      final response = await dio.post(
        '${appUri}/gws_customer/add&api_key=${apiKey}',
        data: formData,
      );

      if (response.data['message'][0]['msg_status'] == true) {
        // _showDialog('更新', '已經更新');
        Navigator.pop(context);
      } else {
        // Handle the error
        _showDialog('註冊失敗', '請確認 E-mail 是否已經註冊。');
        print('Failed to register');
      }
    } catch (e) {
      // Handle any exceptions
      print('Error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('註冊頁面'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: '名 *',
                  hintText: '請輸入您的名',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入名';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: '姓 *',
                  hintText: '請輸入您的姓',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入姓氏';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail *',
                  hintText: '請輸入 E-mail',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入 E-mai;';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '密碼 *',
                  hintText: '請輸入密碼',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入密碼';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _confirmController,
                decoration: const InputDecoration(
                  labelText: '確認密碼 *',
                  hintText: '請輸入確認密碼',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入確認密碼';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(
                  labelText: '電話 *',
                  hintText: '請輸入電話',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入電話';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _address1Controller,
                decoration: const InputDecoration(
                  labelText: '地址 *',
                  hintText: '請輸入地址',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入地址';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: '城市 *',
                  hintText: '請輸入城市',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入城市';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _postcodeController,
                decoration: const InputDecoration(
                  labelText: '郵遞區號 *',
                  hintText: '請輸入郵遞區號',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入郵遞區號';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCountryId,
                items: _countries.map((Country country) {
                  return DropdownMenuItem<String>(
                    value: country.id,
                    child: Text(country.name),
                  );
                }).toList(),
                onChanged: (value) => _onCountrySelected(value!),
              ),
              DropdownButtonFormField<String>(
                value: _selectedZoneId,
                items: _zones.map((Zone zone) {
                  return DropdownMenuItem<String>(
                    value: zone.id,
                    child: Text(zone.name),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedZoneId = value!),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        width: double.infinity, // 容器宽度占满整个屏幕宽度
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: ElevatedButton(
            onPressed: () {
              if (_validateAndSaveForm()) {
                submitRegistration();
              } else {
                _showDialog('錯誤', '請填寫必填欄位。');
              }
            },
            child: Text(
              '註冊',
              style: const TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // 按钮背景颜色为蓝色
              foregroundColor: Colors.white, // 文本颜色为白色
              minimumSize: const Size(double.infinity, 36), // 按钮最小尺寸，宽度占满
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6), // 圆角矩形按钮
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Country {
  String id;
  String name;

  Country({required this.id, required this.name});

  // 從 JSON 數據中解析 Country 對象
  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['country_id'].toString(),
      name: json['name'],
    );
  }
}

class Zone {
  String id;
  String name;

  Zone({required this.id, required this.name});

  // 從 JSON 數據中解析 Zone 對象
  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['zone_id'].toString(),
      name: json['name'],
    );
  }
}
