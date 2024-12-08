import 'dart:html' as html; // Required for iframe
import 'dart:ui_web' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  late html.IFrameElement _iframeElement;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      // Initialize the iframe
      _iframeElement = html.IFrameElement()
        ..src = widget.gameUrl
        ..style.border = "none"
        ..style.width = "100%"
        ..style.height = "100%";

      // Add a listener for receiving messages from Unity
      html.window.addEventListener("message", _onMessageFromUnity);

      // Add the iframe to the Flutter view registry
      ui.platformViewRegistry.registerViewFactory(
        'unity-webgl',
        (int viewId) => _iframeElement,
      );
    }
  }

  // Handle messages from Unity
  void _onMessageFromUnity(html.Event event) {
    if (event is html.MessageEvent) {
      final data = event.data;
      // Check if the message is from Unity
      if (data != null &&
          data is Map<dynamic, dynamic> &&
          data['type'] == 'gameLoaded') {
        print("Game loaded. Sending ssid to Unity...");

        // Send the ssid back to Unity
        _iframeElement.contentWindow?.postMessage(
          {
            'type': 'setSsid',
            'ssid': widget.ssId,
          },
          '*', // Allow communication from any origin
        );
      }
    }
  }

  @override
  void dispose() {
    // Remove the message listener when the widget is disposed
    html.window.removeEventListener("message", _onMessageFromUnity);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HtmlElementView(viewType: 'unity-webgl'), // Embed the iframe
    );
  }
}
