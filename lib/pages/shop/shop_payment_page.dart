import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ShopPaymentPage extends StatefulWidget {
  final String htmlUrl;
  ShopPaymentPage({Key? key, required this.htmlUrl}) : super(key: key);

  @override
  _ShopPaymentPageState createState() => _ShopPaymentPageState();
}

class _ShopPaymentPageState extends State<ShopPaymentPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('付款頁面'),
      ),
      body: WebView(
        initialUrl: widget.htmlUrl,
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
