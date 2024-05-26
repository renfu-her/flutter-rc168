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
  String htmlData = '';
  String htmlDateTitle = '';

  @override
  void initState() {
    super.initState();
    fetchInformation();
  }

  Future<void> fetchInformation() async {
    try {
      var response = await dio.get(
        '${appUri}/gws_information&information_id=${widget.informationId}&api_key=${apiKey}',
      );
      var data = response.data['informations'][0]; // 假设我们只关心第一个信息
      setState(() {
        htmlData = data['description'];
        htmlDateTitle = data['title'];
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('相關說明 - ${htmlDateTitle}'),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF4F4E4C),
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
