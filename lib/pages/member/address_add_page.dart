import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';

class AddressAddPage extends StatefulWidget {
  @override
  _AddressAddPageState createState() => _AddressAddPageState();
}

class _AddressAddPageState extends State<AddressAddPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _customFieldController = TextEditingController();
  final TextEditingController _zoneIdController = TextEditingController();

  bool _firstNameVisible = false;
  bool _lastNameVisible = false;
  bool _postcodeVisible = false;
  bool _address1Visible = false;
  bool _cityVisible = false;

  String _countryId = '206'; // 应该从一个下拉菜单中选择
  String _zoneId = '3139'; // 应该从一个下拉菜单中选择
  bool _isDefault = false; // 根据用户的选择设置

  Future<void> addAddress() async {
    // Build the FormData
    final formData = FormData.fromMap({
      'firstname': _firstNameController.text,
      'lastname': _lastNameController.text,
      'company': _companyController.text,
      'address_1': _address1Controller.text,
      'address_2': _address2Controller.text,
      'postcode': _postcodeController.text,
      'country_id': _countryId,
      'zone_id': _zoneId,
      'city': _cityController.text,
      'custom_field': {1: _customFieldController.text},
      'default': _isDefault
          ? '1'
          : '0', // Assuming the API expects '1' for true and '0' for false
    });

    // Send the POST request
    try {
      final response = await dio.post(
        '${app_url}/index.php?route=extension/module/api/gws_customer_address/add&customer_id=180&api_key=${api_key}',
        data: formData,
      );

      if (response.statusCode == 200) {
        // Handle the successful response
        print('Address added successfully');
      } else {
        // Handle the error
        print('Failed to add address');
      }
    } catch (e) {
      // Handle any exceptions
      print('Error occurred: $e');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build your form widget here using TextFormFields and a submit button
    return Scaffold(
      appBar: AppBar(
        title: Text('增加新的地址'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _lastNameController,
              obscureText: !_lastNameVisible,
              decoration: InputDecoration(
                labelText: '姓名*',
              ),
            ),
            TextFormField(
              controller: _firstNameController,
              obscureText: !_firstNameVisible,
              decoration: InputDecoration(
                labelText: '姓氏 *',
              ),
            ),
            TextField(
              controller: _companyController,
              decoration: InputDecoration(
                labelText: '公司/服務單位',
              ),
            ),
            TextField(
              controller: _address1Controller,
              obscureText: !_address1Visible,
              decoration: InputDecoration(
                labelText: '地址1 *',
              ),
            ),
            TextField(
              controller: _address2Controller,
              decoration: InputDecoration(
                labelText: '地址2',
              ),
            ),
            TextField(
              controller: _postcodeController,
              obscureText: !_postcodeVisible,
              decoration: InputDecoration(
                labelText: '郵遞區號 *',
              ),
            ),
            TextField(
              controller: _cityController,
              obscureText: !_cityVisible,
              decoration: InputDecoration(
                labelText: '區/鄉/鎮 *',
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        width: double.infinity, // 容器宽度占满整个屏幕宽度
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: ElevatedButton(
            onPressed: addAddress,
            child: Text('增加新的地址'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // 按钮背景颜色为蓝色
              foregroundColor: Colors.white, // 文本颜色为白色
              minimumSize: Size(double.infinity, 36), // 按钮最小尺寸，宽度占满
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
