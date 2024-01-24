import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';
import 'package:rc168/pages/member/information_page.dart';
import 'package:rc168/pages/login/login_page.dart';
import 'package:rc168/pages/member/profile_page.dart';
import 'package:rc168/pages/member/order_page.dart';
import 'package:rc168/pages/member/address/address_page.dart';
import 'package:rc168/pages/member/register_page.dart';

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
        '${appUri}/gws_information&api_key=${apiKey}',
      );
      setState(() {
        informations = response.data['informations'];
      });
    } catch (e) {
      print(e);
    }
  }

  // 登入
  void fetchCustomer() async {
    try {
      var response = await Dio().get(
        '${appUri}/gws_customer&email=${email}&api_key=${apiKey}',
      );

      var customerData = response.data['customer'][0];
      await UserPreferences.setLoggedIn(true);
      await UserPreferences.setEmail(customerData['email']);
      await UserPreferences.setLastName(customerData['lastname']);
      await UserPreferences.setFirstName(customerData['firstname']);
      await UserPreferences.setFullName(
          customerData['lastname'] + customerData['firstname']);
      await UserPreferences.setCustomerId(
          int.parse(customerData['customer_id']));
      isLogin = UserPreferences.isLoggedIn();
      email = UserPreferences.getEmail()!;
      fullName = UserPreferences.getFullName()!;
      customerId = UserPreferences.getCustomerId()!;
      setState(() {
        fullName = fullName;
        lastName = customerData['lastname'];
        firstName = customerData['firstname'];
        customerId = customerId;
      });
    } catch (e) {
      print(e);
    }
  }

  Widget _listView() {
    return ListView.builder(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    isLogin = UserPreferences.isLoggedIn();
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
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => RegisterPage()));
                  },
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
        Expanded(
          child: _listView(),
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
        logoImg.isNotEmpty
            ? Image.network(
                logoImg,
                width: 160,
              )
            : SizedBox(height: 160), // 如果 logoImg 为空，则显示一个占位符
        const SizedBox(height: 16),
        Text(
          '${fullName}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          email,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 18),
        // 我的会员资料
        _buildOptionItem(Icons.account_circle, '會員資料', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfilePage()),
          );
        }),
        // 我的订单
        _buildOptionItem(Icons.list_alt, '訂單', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OrderPage()),
          );
        }),
        // 我的地址
        _buildOptionItem(Icons.location_on, '地址', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddressPage()),
          );
        }),
        _buildOptionItem(Icons.logout, '登出', () async {
          await UserPreferences.logout();
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (_) => (MyApp())));
        }),
        const SizedBox(height: 22),
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
        Expanded(
          child: _listView(),
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
