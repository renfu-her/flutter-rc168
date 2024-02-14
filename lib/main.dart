import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'package:rc168/pages/category/category_page.dart';
import 'package:rc168/pages/home_page.dart';
import 'package:rc168/pages/member/member_page.dart';
import 'package:rc168/pages/search_page.dart';
import 'package:rc168/pages/shop/shop_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rc168/firebase_options.dart';

// 创建一个全局的通知插件实例
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

var dio = Dio();
String appUrl = 'https://ocapi.remember1688.com';
String appUri = '${appUrl}/index.php?route=extension/module/api';
String imgUrl = '${appUrl}/image/';
String apiKey =
    'CNQ4eX5WcbgFQVkBXFKmP9AE2AYUpU2HySz2wFhwCZ3qExG6Tep7ZCSZygwzYfsF';
String demoUrl = 'https://demo.dev-laravel.co';
String logoImg = '';
String categoryId = '';
String email = '';
String lastName = '';
String firstName = '';
bool isLogin = false;
int customerId = 0;
String fullName = '';
int selectedIndex = 0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserPreferences.init();

  // 初始化设置
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // 使用应用图标
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp());
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

// 通知類
Future<void> showOrderPlacedNotification() async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'order_channel', // 频道ID
    'Order Notifications', // 频道名称
    channelDescription: 'Notification channel for order updates', // 频道描述
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'Order Placed',
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(
    0, // 通知ID
    '訂單通知', // 通知标题
    '訂單通知 - 已經訂購完成.', // 通知内容
    platformChannelSpecifics,
  );
}

Future<void> showOrderCompletedNotification() async {
  // 类似于 showOrderPlacedNotification，修改为订单完成的相关信息
}

Future<void> showOrderCancelledNotification() async {
  // 类似于 showOrderPlacedNotification，修改为订单取消的相关信息
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 底部導航項目列表
  static List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    CategoryPage(),
    SearchPage(),
    ShopPage(),
    MemberPage(),
  ];

  @override
  void initState() {
    super.initState();
    // showOrderPlacedNotification();
    getSetting().then((img) {
      if (mounted) {
        setState(() {
          logoImg = '${imgUrl}' + img;
        });
      }
    }).catchError((error) {
      // 處理錯誤，例如顯示錯誤消息
      print(error);
    });

    setUserPreferences();
  }

  void setUserPreferences() async {
    if (UserPreferences.isLoggedIn()) {
      isLogin = UserPreferences.isLoggedIn();
      email = UserPreferences.getEmail() ?? '預設電子郵件';
      fullName = UserPreferences.getFullName() ?? '預設姓名';
      customerId = UserPreferences.getCustomerId() ?? 0;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Future<String> getSetting() async {
    try {
      var response =
          await Dio().get('${appUri}/gws_store_settings&api_key=${apiKey}');
      return response.data['settings']['config_logo'];
    } catch (e) {
      print(e);
      throw (e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: logoImg != null
            ? Image.network(
                logoImg,
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator());
                },
                errorBuilder: (BuildContext context, Object exception,
                    StackTrace? stackTrace) {
                  return SizedBox();
                },
              )
            : SizedBox(),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(FontAwesomeIcons.heart), onPressed: () {}),
          IconButton(icon: Icon(FontAwesomeIcons.comments), onPressed: () {}),
        ],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Align(
                alignment: Alignment.center,
                child: Text('您好',
                    style: TextStyle(fontSize: 24, color: Colors.white)),
              ),
            ),
            ListTile(
              leading: const Icon(FontAwesomeIcons.circleUser),
              title: const Text('會員中心'),
              onTap: () {},
            ),
            // ListTile(
            //   title: Text('項目2'),
            //   onTap: () {},
            // ),
          ],
        ),
      ),
      body: Center(
        child: _widgetOptions.elementAt(selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.house),
            label: '首頁',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.tags),
            label: '商品分類',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.magnifyingGlass),
            label: '搜尋',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.cartShopping),
            label: '購物車',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.user),
            label: '會員中心',
          ),
        ],
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class UserPreferences {
  static SharedPreferences? _preferences;

  static const _keyLoggedIn = 'loggedIn';
  static const _keyEmail = 'email';
  static const _keyFullName = 'fullName';
  static const _keyLastName = 'lastName';
  static const _keyFirstName = 'firstName';
  static const _keyCustomerId = '';

  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();

  static Future setLoggedIn(bool loggedIn) async =>
      await _preferences?.setBool(_keyLoggedIn, loggedIn);

  static bool isLoggedIn() => _preferences?.getBool(_keyLoggedIn) ?? false;

  static Future setEmail(String email) async =>
      await _preferences?.setString(_keyEmail, email);

  static String? getEmail() => _preferences?.getString(_keyEmail);

  static Future setFullName(String fullName) async =>
      await _preferences?.setString(_keyFullName, fullName);

  static String? getFullName() => _preferences?.getString(_keyFullName);

  static Future setLastName(String lastName) async =>
      await _preferences?.setString(_keyLastName, lastName);

  static String? getLastName() => _preferences?.getString(_keyLastName);

  static Future setFirstName(String firstName) async =>
      await _preferences?.setString(_keyFirstName, firstName);

  static String? getFirstName() => _preferences?.getString(_keyFirstName);

  static Future setCustomerId(int customerId) async =>
      await _preferences?.setInt(_keyCustomerId, customerId);

  static int? getCustomerId() => _preferences?.getInt(_keyCustomerId);

  static Future logout() async {
    await _preferences?.setBool(_keyLoggedIn, false);
    await _preferences?.remove(_keyEmail);
    email = '';
    isLogin = false;
    fullName = '';
  }
}
