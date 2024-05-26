import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';
import 'package:rc168/responsive_text.dart';

class AddressEditPage extends StatefulWidget {
  final String? addressId;
  const AddressEditPage({super.key, required this.addressId});

  @override
  _AddressEditPageState createState() => _AddressEditPageState();
}

class _AddressEditPageState extends State<AddressEditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _customFieldController = TextEditingController();
  final TextEditingController _zoneIdController = TextEditingController();
  final TextEditingController _cellphone = TextEditingController();
  final TextEditingController _pickupstore = TextEditingController();

  String _countryId = '206'; // 应该从一个下拉菜单中选择
  String _zoneId = '3139'; // 应该从一个下拉菜单中选择
  bool _isDefault = false; // 根据用户的选择设置
  List<Country> _countries = [];
  List<Zone> _zones = [];
  String _selectedCountryId = '206'; // 預設值
  String _selectedZoneId = '3139'; // 預設值

  bool _validateAndSaveForm() {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: ResponsiveText(
          title,
          baseFontSize: 38,
        ),
        content: ResponsiveText(
          message,
          baseFontSize: 36,
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: ResponsiveText('確定', baseFontSize: 36),
          ),
        ],
      ),
    );
  }

  Future<void> editAddress(String addressId) async {
    if (_validateAndSaveForm()) {
      var formData = FormData.fromMap({
        'customer_id': customerId,
        'api_key': apiKey,
        'address_id': addressId,
        'firstname': _firstNameController.text,
        'lastname': _lastNameController.text,
        'company': _pickupstore.text,
        'address_1': _address1Controller.text,
        'address_2': _address2Controller.text,
        'postcode': _postcodeController.text,
        'city': _cityController.text,
        'country_id': _selectedCountryId,
        'zone_id': _selectedZoneId,
        'custom_field': '{1: 711}',
        'cellphone': _cellphone.text,
        'pickupstore': _pickupstore.text,
        'default': _isDefault ? '1' : '0',
      });

      try {
        final response = await dio.post(
          '$appUri/gws_appcustomer_address/edit&customer_id=${customerId}&address_id=${addressId}&api_key=${apiKey}',
          data: formData,
        );

        // print{response.data);
        if (response.statusCode == 200) {
          _showDialog('編輯地址', '編輯地址完成');
        } else {
          _showDialog('Error', 'Failed to edit address');
        }
      } catch (e) {
        _showDialog('Error', e.toString());
      }
    }
  }

  Future<void> showAddress(String addressId) async {
    try {
      final response = await dio.post(
          '$appUri/gws_appcustomer_address&customer_id=${customerId}&address_id=${addressId}&api_key=${apiKey}');

      // print{response.statusCode);
      if (response.statusCode == 200) {
        var addressData = response.data['customer_address'];
        // // 現在更新所有的控制器和變量
        _firstNameController.text = addressData[0]['firstname'] ?? '';
        _lastNameController.text = addressData[0]['lastname'] ?? '';
        _companyController.text = addressData[0]['company'] ?? '';
        _postcodeController.text = addressData[0]['postcode'] ?? '';
        _address1Controller.text = addressData[0]['address_1'] ?? '';
        _address2Controller.text = addressData[0]['address_2'] ?? '';
        _cityController.text = addressData[0]['city'] ?? '';
        _selectedCountryId = addressData[0]['country_id'] ?? '206';
        _selectedZoneId = addressData[0]['zone_id'] ?? '3139';
        _cellphone.text = addressData[0]['cellphone'] ?? '';
        _pickupstore.text = addressData[0]['pickupstore'] ?? '';
        // 記得更新國家和地區選項
        _loadZones(_selectedCountryId);
      } else {
        _showDialog('Error', 'Failed to load address');
      }
    } catch (e) {
      _showDialog('Error', e.toString());
    }
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is removed
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyController.dispose();
    _postcodeController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _customFieldController.dispose();
    _cellphone.dispose();
    _pickupstore.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCountries();
    if (widget.addressId != null) {
      showAddress(widget.addressId!); // 確保有有效的地址ID
    }
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

  @override
  Widget build(BuildContext context) {
    // Build your form widget here using TextFormFields and a submit button
    return Scaffold(
      appBar: AppBar(
        title: Text('編輯地址'),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF4F4E4C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: '名字 *',
                  labelStyle: TextStyle(
                    fontSize: 14, // 这里可以更改标签字体大小
                  ),
                  // 如果你还想更改用户输入的文本大小，那么添加下面这行
                  hintStyle: TextStyle(
                    fontSize: 14, // 更改提示文字大小
                  ),
                  hintText: '請输入您的名字',
                ),
                style: const TextStyle(
                  fontSize: 14, // 更改用户输入的文本大小
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請输入名字';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: '姓式 *',
                  labelStyle: TextStyle(
                    fontSize: 14, // 这里可以更改标签字体大小
                  ),
                  // 如果你还想更改用户输入的文本大小，那么添加下面这行
                  hintStyle: TextStyle(
                    fontSize: 14, // 更改提示文字大小
                  ),
                  hintText: '請输入您的姓氏',
                ),
                style: const TextStyle(
                  fontSize: 14, // 更改用户输入的文本大小
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入姓氏';
                  }
                  return null;
                },
              ),
              // TextFormField(
              //   controller: _companyController,
              //   decoration: const InputDecoration(
              //       labelText: '超商店到店物流',
              //       labelStyle: TextStyle(
              //         fontSize: 14, // 这里可以更改标签字体大小
              //       ),
              //       // 如果你还想更改用户输入的文本大小，那么添加下面这行
              //       hintStyle: TextStyle(
              //         fontSize: 14, // 更改提示文字大小
              //       ),
              //       hintText: '請输入 7-11 門市或者全家門市'),
              //   style: const TextStyle(
              //     fontSize: 14, // 更改用户输入的文本大小
              //   ),
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return '請輸入 7-11 門市或者全家門市';
              //     }
              //     return null;
              //   },
              // ),
              TextFormField(
                controller: _cellphone,
                decoration: const InputDecoration(
                    labelText: '手機號碼',
                    labelStyle: TextStyle(
                      fontSize: 14, // 这里可以更改标签字体大小
                    ),
                    // 如果你还想更改用户输入的文本大小，那么添加下面这行
                    hintStyle: TextStyle(
                      fontSize: 14, // 更改提示文字大小
                    ),
                    hintText: '請输入手機號碼'),
                style: const TextStyle(
                  fontSize: 14, // 更改用户输入的文本大小
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入手機號碼';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _pickupstore,
                decoration: const InputDecoration(
                    labelText: '超商店到店物流',
                    labelStyle: TextStyle(
                      fontSize: 14, // 这里可以更改标签字体大小
                    ),
                    // 如果你还想更改用户输入的文本大小，那么添加下面这行
                    hintStyle: TextStyle(
                      fontSize: 14, // 更改提示文字大小
                    ),
                    hintText: '請输入 7-11 門市或者全家門市'),
                style: const TextStyle(
                  fontSize: 14, // 更改用户输入的文本大小
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入 7-11 門市或者全家門市';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _address1Controller,
                decoration: const InputDecoration(
                  labelText: '地址1 *',
                  labelStyle: TextStyle(
                    fontSize: 14, // 这里可以更改标签字体大小
                  ),
                  // 如果你还想更改用户输入的文本大小，那么添加下面这行
                  hintStyle: TextStyle(
                    fontSize: 14, // 更改提示文字大小
                  ),
                  hintText: '請输入地址1',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入地址1';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _address2Controller,
                decoration: const InputDecoration(
                  labelText: '地址2 ',
                  labelStyle: TextStyle(
                    fontSize: 14, // 这里可以更改标签字体大小
                  ),
                  // 如果你还想更改用户输入的文本大小，那么添加下面这行
                  hintStyle: TextStyle(
                    fontSize: 14, // 更改提示文字大小
                  ),
                  hintText: '請输入地址2',
                ),
              ),
              TextFormField(
                controller: _postcodeController,
                decoration: const InputDecoration(
                  labelText: '郵遞區號 *',
                  labelStyle: TextStyle(
                    fontSize: 14, // 这里可以更改标签字体大小
                  ),
                  // 如果你还想更改用户输入的文本大小，那么添加下面这行
                  hintStyle: TextStyle(
                    fontSize: 14, // 更改提示文字大小
                  ),
                  hintText: '請输入郵遞區號',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入郵遞區號';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: '區/鄉/鎮 *',
                  labelStyle: TextStyle(
                    fontSize: 14, // 这里可以更改标签字体大小
                  ),
                  // 如果你还想更改用户输入的文本大小，那么添加下面这行
                  hintStyle: TextStyle(
                    fontSize: 14, // 更改提示文字大小
                  ),
                  hintText: '請输入區/鄉/鎮',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入區/鄉/鎮';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCountryId,
                items: _countries.map((Country country) {
                  return DropdownMenuItem<String>(
                    value: country.id,
                    child: Text(
                      country.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) => _onCountrySelected(value!),
              ),
              DropdownButtonFormField<String>(
                value: _selectedZoneId,
                items: _zones.map((Zone zone) {
                  return DropdownMenuItem<String>(
                    value: zone.id,
                    child: Text(
                      zone.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedZoneId = value!),
              ),
              SizedBox(height: 80),
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
                editAddress(widget.addressId!);
              } else {
                _showDialog('錯誤', '請填寫必填欄位。');
              }
            },
            child: Text(
              '編輯地址',
              style: const TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, // 按钮背景颜色为蓝色
              foregroundColor: Color(0xFF4F4E4C), // 文本颜色为白色
              minimumSize: Size(double.infinity, 36), // 按钮最小尺寸，宽度占满
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: Colors.black),
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
