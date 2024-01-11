import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';
import 'package:rc168/pages/member/information_page.dart';
import 'package:rc168/pages/login/login_page.dart';

class MemberPage extends StatefulWidget {
  @override
  _MemberPageState createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage> {
  List<dynamic> informations = [];

  @override
  void initState() {
    super.initState();
    fetchInfo();
    if (isLogin) {
      fetchCustomer();
    }
  }

  void _updateAfterLogin() {
    fetchInfo();
    fetchCustomer();
  }

  void fetchInfo() async {
    try {
      var response = await Dio().get(
        '${app_url}/index.php?route=extension/module/api/gws_information&api_key=${api_key}',
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
        '${app_url}/index.php?route=extension/module/api/gws_customer&email=${email}&api_key=${api_key}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: isLogin ? _buildUserInformation() : _buildLoginInterface(),
      ),
    );
  }

  Widget _buildLoginInterface() {
    // 返回未登錄狀態下的介面
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 16),
        const Text(
          '請登入會員帳號',
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text('註冊'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                          builder: (context) => LoginPage(
                              onLoginSuccess:
                                  _updateAfterLogin)), // 假设您有一个新页面叫做NewPage
                    )
                        .then((_) {
                      setState(() {
                        fetchCustomer();
                      });
                    });
                    ;
                  },
                  child: Text('登入'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
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
        Expanded(
          child: ListView.builder(
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
        ),
      ],
    );
  }

  Widget _buildUserInformation() {
    // 返回登錄後的用戶信息介面
    return Column(
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2),
        Text(
          email,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 18),
        // 我的会员资料
        _buildOptionItem(Icons.account_circle, '我的會員資料', () {
          // 添加导航到我的会员资料页面的逻辑
        }),
        // 我的订单
        _buildOptionItem(Icons.list_alt, '我的訂單', () {
          // 添加导航到我的订单页面的逻辑
        }),
        // 我的地址
        _buildOptionItem(Icons.location_on, '我的地址', () {
          // 添加导航到我的地址页面的逻辑
        }),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
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
        Expanded(
          child: ListView.builder(
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
        ),
      ],
    );
  }

  Widget _buildOptionItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
