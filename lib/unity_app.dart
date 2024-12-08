import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter/webview_flutter.dart';

class UnityWidget extends StatefulWidget {
  String ssId, gameUrl;

  UnityWidget({
    super.key,
    required this.ssId,
    required this.gameUrl,
  });

  @override
  State<UnityWidget> createState() => _UnityWidgetState();
}

class _UnityWidgetState extends State<UnityWidget> {
  late WebViewController _controller;

  Future<void> onPageLoaded() async {
    await _controller.runJavaScript('''
          window.addEventListener('message', (event) => {
            if (event.data.type === 'gameLoaded') {
              console.log('Game is loaded. Sending ssid...');
              window.postMessage({ type: 'setSsid', ssid: "${widget.ssId}" }, "*");
            }
          });
        ''');
  }

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (_) => onPageLoaded(),
          onHttpError: (HttpResponseError error) {
            Fluttertoast.showToast(
              msg: error.response!.statusCode.toString(),
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0,
            );
            debugPrint(
                'HttpResponseError error: ${error.response?.statusCode}');
          },
          onWebResourceError: (WebResourceError error) {
            Fluttertoast.showToast(
              msg: error.description,
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0,
            );
            debugPrint('Web error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.gameUrl));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: WebViewWidget(
            controller: _controller,
          ),
        ),
      ),
    );
  }
}
