import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TelegramAuthWidget extends StatelessWidget {
  final String botUsername; // Telegram Bot Username

  TelegramAuthWidget({Key? key, required this.botUsername}) : super(key: key) {
    // Register the view for the Telegram widget
    if(kIsWeb){
    final widgetId = 'telegram-widget';

    // Remove any previously existing widget to prevent duplication
    html.document.getElementById(widgetId)?.remove();

    // Create a container for the Telegram widget
    final container = html.DivElement()
      ..id = widgetId
      ..style.width = '100%'
      ..style.height = '50px';

    // Add the Telegram widget as a script
    final script = html.ScriptElement()
      ..async = true
      ..src = 'https://telegram.org/js/telegram-widget.js?15'
      ..dataset.addAll({
        'telegram-login': botUsername, // Replace with your bot username
        'size': 'large',
        'radius': '5',
        'auth-url': 'javascript:void(0);', // No backend required
        'request-access': 'write',
      });

    container.append(script);

      // Register the widget
      ui.platformViewRegistry
          .registerViewFactory(widgetId, (int viewId) => container);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 100,
      child: HtmlElementView(viewType: 'telegram-widget'),
    );
  }
}
