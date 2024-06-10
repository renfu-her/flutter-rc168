import 'package:flutter/material.dart';
import 'package:rc168/main.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ShopPaymentBankTransferPage extends StatefulWidget {
  final String htmlUrl;
  ShopPaymentBankTransferPage({Key? key, required this.htmlUrl})
      : super(key: key);

  @override
  _ShopPaymentBankTransferPageState createState() =>
      _ShopPaymentBankTransferPageState();
}

class _ShopPaymentBankTransferPageState
    extends State<ShopPaymentBankTransferPage> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize any necessary settings or listeners here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('付款頁面-銀行轉帳'),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF4F4E4C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MyApp()),
          ),
        ),
      ),
      body: Stack(
        children: [
          WebView(
            initialUrl: widget.htmlUrl,
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _controller = webViewController;
            },
            onPageFinished: (String url) async {
              // 获取页面HTML
              final String htmlContent = await _controller.evaluateJavascript(
                  "document.documentElement.outerHTML.toString()");
              // print(url);
              // 根据HTML内容进行逻辑处理，例如触发本地通知
              // 此处添加判断逻辑，根据实际情况触发通知
              if (url.contains("success")) {
                final Uri uri = Uri.parse(url);
                final String orderId = uri.queryParameters['orderId'] ?? '';
                await showOrderPlacedNotification(orderId);
              }
              if (url.contains("fail")) {
                await showOrderCancelledNotification();
              }
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => MyApp()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF4F4E4C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.black),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('返回首頁'),
            ),
          ),
        ],
      ),
    );
  }
}
