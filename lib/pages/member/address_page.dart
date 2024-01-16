import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';

class AddressPage extends StatefulWidget {
  @override
  _AddressPageState createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  Future<List<CustomerAddress>>? addresses;

  @override
  void initState() {
    super.initState();
    addresses = fetchAddresses();
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

  Future<List<CustomerAddress>> fetchAddresses() async {
    final response = await dio.get(
        '${app_url}/index.php?route=extension/module/api/gws_customer_address&customer_id=${customerId}&api_key=${api_key}');

    if (response.statusCode == 200) {
      var responseData = response.data;
      List<CustomerAddress> addresses =
          (responseData['customer_address'] as List)
              .map((addressJson) => CustomerAddress.fromJson(addressJson))
              .toList();

      // 异步填充额外的详细信息
      for (var address in addresses) {
        await address.fillAdditionalDetails();
      }

      return addresses;
    } else {
      throw Exception('Failed to load addresses');
    }
  }

  Future<String> fetchZoneName(String zoneId) async {
    final response = await dio.get('${app_url}/zones/$zoneId');
    if (response.statusCode == 200) {
      // 解析響應，獲取zone名稱
      return response.data['name'];
    } else {
      throw Exception('Failed to load zone name');
    }
  }

  Future<String> fetchCountryName(String countryId) async {
    final response = await dio.get(
        '${app_url}/index.php?route=extension/module/api/gws_country&country_id=${countryId}&api_key=${api_key}');
    if (response.statusCode == 200) {
      // 解析響應，獲取country名稱
      return response.data['country'][0]['name'];
    } else {
      throw Exception('Failed to load country name');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('地址'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<List<CustomerAddress>>(
          future: addresses,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              }
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var address = snapshot.data![index];
                  return Column(
                    children: <Widget>[
                      ListTile(
                        title: Text(
                          '${address.firstname} ${address.lastname}',
                          style: TextStyle(fontSize: 16),
                        ),
                        subtitle: Text(
                          '${address.address1} \n${address.address2} \n${address.city}, ${address.zoneName}, ${address.countryName}, ${address.postcode}',
                          style: TextStyle(fontSize: 16),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize
                              .min, // Row should be as big as the sum of its children.
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                // 在这里处理编辑按钮的点击事件
                                // 例如，打开一个编辑表单或导航到另一个页面
                                // Navigator.of(context).push(...);
                                _showDialog('刪除', '地址已經刪除。');
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                // 在这里处理删除按钮的点击事件
                                // 可以显示确认对话框或直接删除条目
                                // 然后可能需要调用setState来更新列表视图
                              },
                            ),
                          ],
                        ),
                      ),
                      Divider(), // 添加横线
                    ],
                  );
                },
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: ElevatedButton(
          onPressed: () {
            // // TODO: 處理密碼保存
            // if (_validateAndSaveForm()) {
            //   _changePassword();
            // } else {
            //   _showDialog('提示', '請填寫必填的密碼欄位。');
            // }
          },
          child: Text('增加新的地址'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
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

class CustomerAddress {
  String addressId;
  String customerId;
  String firstname;
  String lastname;
  String company;
  String address1;
  String address2;
  String city;
  String postcode;
  String countryId;
  String zoneId;
  String customField;
  String zoneName;
  String countryName;

  CustomerAddress({
    required this.addressId,
    required this.customerId,
    required this.firstname,
    required this.lastname,
    required this.company,
    required this.address1,
    required this.address2,
    required this.city,
    required this.postcode,
    required this.countryId,
    required this.zoneId,
    required this.customField,
    required this.zoneName,
    required this.countryName,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      addressId: json['address_id'],
      customerId: json['customer_id'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      company: json['company'],
      address1: json['address_1'],
      address2: json['address_2'],
      city: json['city'],
      postcode: json['postcode'],
      countryId: json['country_id'],
      zoneId: json['zone_id'],
      customField: json['custom_field'],
      countryName: '',
      zoneName: '',
    );
  }

  Future<void> fillAdditionalDetails() async {
    // 从 API 获取 zone 和 country 名称
    this.zoneName = await fetchZoneName(this.countryId, this.zoneId);
    this.countryName = await fetchCountryName(this.countryId);
  }
}

Future<String> fetchZoneName(String countryId, String zoneId) async {
  final dio = Dio(); // 创建 Dio 实例
  try {
    final response = await dio.get(
        '${app_url}/index.php?route=extension/module/api/gws_zone&country_id=${countryId}&api_key=${api_key}'); // 使用 Dio 发送 GET 请求
    if (response.statusCode == 200) {
      List zones = response.data['zones'];

      var matchingZone = zones.firstWhere(
        (z) => z['zone_id'] == zoneId && z['country_id'] == countryId,
        orElse: () => null,
      );
      if (matchingZone != null) {
        // 返回匹配的区域名称
        return matchingZone['name'];
      } else {
        throw Exception('Matching zone not found');
      }
    } else {
      throw Exception('Failed to load zone name');
    }
  } catch (e) {
    // 处理异常
    throw Exception('Failed to fetch zone name: $e');
  }
}

Future<String> fetchCountryName(String countryId) async {
  final dio = Dio(); // 创建 Dio 实例
  try {
    final response = await dio.get(
        '${app_url}/index.php?route=extension/module/api/gws_country&country_id=${countryId}&api_key=${api_key}'); // 使用 Dio 发送 GET 请求
    if (response.statusCode == 200) {
      // 解析响应并返回国家名称
      return response.data['country'][0]['name'];
    } else {
      throw Exception('Failed to load country name');
    }
  } catch (e) {
    // 处理异常
    throw Exception('Failed to fetch country name: $e');
  }
}
