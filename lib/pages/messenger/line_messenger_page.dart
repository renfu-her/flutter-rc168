import 'package:flutter/material.dart';
import 'package:rc168/main.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LineMessengerPage extends StatefulWidget {
  final String htmlUrl;
  LineMessengerPage({Key? key, required this.htmlUrl}) : super(key: key);

  @override
  _LineMessengerPageState createState() => _LineMessengerPageState();
}

class _LineMessengerPageState extends State<LineMessengerPage> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LINE Messenger'),
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
      body: WebView(
        initialUrl: widget.htmlUrl,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller = webViewController;
        },
        onPageFinished: (String url) async {
          // 获取页面HTML
          //
        },
      ),
    );
  }
}
