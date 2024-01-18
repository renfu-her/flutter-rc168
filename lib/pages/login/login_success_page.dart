import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';
import 'package:rc168/pages/login/login_page.dart';
import 'package:rc168/pages/member/information_page.dart';

class LoginSuccessPage extends StatefulWidget {
  @override
  _LoginSuccessPageState createState() => _LoginSuccessPageState();
}

class _LoginSuccessPageState extends State<LoginSuccessPage> {
  List<dynamic> informations = [];

  @override
  void initState() {
    super.initState();
    fetchInfo();
    fetchCustomer();
    getSetting().then((img) {
      if (mounted) {
        setState(() {
          logo_img = '${imgUrl}' + img; // 假设 imgUrl 是已定义的图片基础 URL
        });
      }
    }).catchError((error) {
      print(error);
    });
  }

  void fetchInfo() async {
    try {
      var response = await Dio().get(
        '${appUrl}/index.php?route=extension/module/api/gws_information&api_key=${apiKey}',
      );
      setState(() {
        informations = response.data['informations'];
      });
    } catch (e) {
      print(e);
    }
  }

  void fetchCustomer() async {
    try {
      var response = await Dio().get(
        '${appUrl}/index.php?route=extension/module/api/gws_customer&email=${email}&api_key=${apiKey}',
      );

      var customerData = response.data['customer'][0];
      setState(() {
        lastName = customerData['lastname'];
        firstName = customerData['firstname'];
        customerId = customerData['customer_id'];
      });
    } catch (e) {
      print(e);
    }
  }

  Future<String> getSetting() async {
    try {
      var response = await Dio().get(
        '${appUrl}/index.php?route=extension/module/api/gws_store_settings&api_key=${apiKey}',
      );
      return response.data['settings']['config_logo'];
    } catch (e) {
      print(e);
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('會員'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 20),
              logo_img.isNotEmpty
                  ? Image.network(
                      logo_img,
                      width: 160,
                    )
                  : SizedBox(height: 160), // 如果 logo_img 为空，则显示一个占位符
              const SizedBox(height: 16),
              Text(
                '${lastName}${firstName}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2),
              Text(
                email,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '相關說明',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ListView.builder(
                physics: NeverScrollableScrollPhysics(), // 禁用 ListView 滚动
                shrinkWrap: true, // 使 ListView 自适应大小
                itemCount: informations.length,
                itemBuilder: (BuildContext context, int index) {
                  var info = informations[index];
                  return ListTile(
                    title: Text(info['title'] ?? '無標題'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InformationPage(
                            informationId: info['information_id'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
