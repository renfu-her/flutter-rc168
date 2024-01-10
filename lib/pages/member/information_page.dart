import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';
import 'package:flutter_html/flutter_html.dart';

var dio = Dio();

class InformationPage extends StatefulWidget {
  final String informationId;
  const InformationPage({super.key, required this.informationId});

  @override
  _InformationPageState createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  String htmlData = ''; // 初始化一个变量来存储HTML数据

  @override
  void initState() {
    super.initState();
    fetchInformation();
  }

  Future<void> fetchInformation() async {
    try {
      var response = await dio.get(
        '${app_url}/index.php?route=extension/module/api/gws_information&information_id=${widget.informationId}&api_key=${api_key}',
      );
      var data = response.data['informations'][0]; // 假设我们只关心第一个信息
      setState(() {
        htmlData = data['description']; // 将HTML数据设置到状态变量中
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('相關說明'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: htmlData.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Html(data: htmlData, style: {
                'img': Style(backgroundColor: Colors.grey, width: Width(395))
              }),
            ),
    );
  }
}
