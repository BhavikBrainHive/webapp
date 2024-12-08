import 'dart:html' as html; // Required for iframe
import 'dart:ui_web' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:peer2play_plugin/peer2play_plugin.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PluginTest extends StatelessWidget {
  const PluginTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConnectP2PButton(
          onSuccess: (onSuccess) {
            final gameUrl = onSuccess['gameUrl'];
            late String ssid;
            if (onSuccess['displayName'] != null) {
              ssid = onSuccess['displayName'];
            } else if (onSuccess['wallet'] != null) {
              ssid = onSuccess['wallet'];
            }
            print(onSuccess);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(onSuccess.toString()),
              duration: Duration(seconds: 7),
            ));
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => GameHome(
                          ssId: ssid,
                          gameUrl: gameUrl,
                        )));
          },
          onError: (onError) {
            print(onError);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(onError), duration: Duration(seconds: 7)));
          },
        ),
      ),
    );
  }
}

class GameHome extends StatefulWidget {
  String ssId, gameUrl;

  GameHome({
    super.key,
    required this.ssId,
    required this.gameUrl,
  });

  @override
  State<GameHome> createState() => _GameHomeState();
}

class _GameHomeState extends State<GameHome> {
  late WebViewController _controller;
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

  Future<void> onPageLoaded() async {
    await _controller.runJavaScript('''
          window.addEventListener('message', (event) => {
            if (event.data.type === 'gameLoaded') {
              console.log('Game is loaded. Sending ssid...');
              window.postMessage({ type: 'setSsid', ssid: "Bhavik" }, "*");
            }
          });
        ''');
  }
}

class BottomSheetContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.of(context).size.height * 0.65);
    final bgHeight = 150.toDouble();
    return Stack(
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: bgHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1E1E1E),
                      Colors.yellow.withOpacity(0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Container(
                height: height - (bgHeight / 1.7),
                color: Colors.transparent,
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: [
                                Color.fromRGBO(255, 255, 255, 0.06),
                                Color.fromRGBO(78, 73, 73, 0.2),
                              ],
                              end: Alignment.bottomCenter,
                              begin: Alignment.topCenter,
                            ),
                          ),
                          child: SizedBox(
                            height: 16,
                            width: 16,
                            child: SvgPicture.asset(
                              'assets/svg/pig.svg',
                              semanticsLabel: 'Dart Logo',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 5.w,
                        ),
                        Text(
                          'Bhavik M.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white,
                            // fontFamily: 'Play',
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(255, 255, 255, 0.06),
                            Color.fromRGBO(78, 73, 73, 0.2),
                          ],
                          end: Alignment.bottomCenter,
                          begin: Alignment.topCenter,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 5.h,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            height: 16,
                            width: 16,
                            child: SvgPicture.asset(
                              'assets/svg/sei.svg',
                              semanticsLabel: 'Dart Logo',
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(
                            width: 5.w,
                          ),
                          Text(
                            'SEI',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white,
                              // fontFamily: 'Play',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: height,
                color: Colors.transparent,
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: const Color(
                0xff2c2f35,
              ),
              border: Border(
                top: BorderSide(
                  color: Color(
                    0xfff9d838,
                  ),
                  width: 1.5,
                ),
              ),
              borderRadius: BorderRadius.circular(
                30,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPlayerIcon("BHAVIK", Icons.account_circle),
                      _buildPlayerIcon("SEI", Icons.account_balance_wallet),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Gradient Separator
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.yellow, Colors.transparent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Earn per tap, Coins to level up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard("Earn per tap", "+1", Colors.orange),
                      _buildStatCard("Coins to level up", "10K", Colors.blue),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Coin Display
                  Column(
                    children: [
                      Icon(Icons.monetization_on,
                          color: Colors.yellow, size: 40),
                      SizedBox(height: 8),
                      Text(
                        "9942",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellow,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Progress Bar
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: 0.5,
                        minHeight: 8,
                        backgroundColor: Colors.grey,
                        valueColor: AlwaysStoppedAnimation(Colors.green),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Beginner",
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            "Level 0/10",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerIcon(String name, IconData icon) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white24,
          radius: 24,
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
