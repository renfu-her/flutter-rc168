import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

var dio = Dio();

var api_key =
    'CNQ4eX5WcbgFQVkBXFKmP9AE2AYUpU2HySz2wFhwCZ3qExG6Tep7ZCSZygwzYfsF';

void main() {
  runApp(MyApp());
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
  int _selectedIndex = 0;

  // 底部導航項目列表
  static const List<Widget> _widgetOptions = <Widget>[
    Text('首頁'),
    Text('商品分類'),
    Text('搜尋'),
    Text('購物車'),
    Text('會員中心'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter App'),
        backgroundColor: Colors.blue,
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
        child: _widgetOptions.elementAt(_selectedIndex),
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
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
