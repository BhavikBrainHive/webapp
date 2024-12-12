import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:peer2play_plugin/peer2play_plugin.dart';
import 'package:webapp/unity_widget.dart';
import 'dart:html' as html;
import 'dart:js' as js;

import 'model/bottom_tab_item.dart';

class PluginTest extends StatefulWidget {
  const PluginTest({super.key});

  @override
  State<PluginTest> createState() => _PluginTestState();
}

class _PluginTestState extends State<PluginTest> {
  /*@override
  void initState() {
    super.initState();
    validateTelegramData();
    // Listen for Telegram login messages
    */ /*html.window.onMessage.listen((event) {
      final data = event.data;
      print("Authentication failed:: $data");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data),
        duration: Duration(seconds: 3),
      ));
      if (data != null && data is Map) {
        if (data['type'] == 'telegram-auth-success') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("User logged in: ${jsonEncode(data['user'])}"),
            duration: Duration(seconds: 7),
          ));
          print("User logged in: ${jsonEncode(data['user'])}");
        } else {
          print("Authentication failed.");
        }
      }
    });*/ /*
  }*/

  void checkTelegramContext() {
    final telegram = js.context['Telegram'];
    if (telegram == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Telegram context is not available $telegram"),
        duration: Duration(seconds: 2),
      ));
      print('Telegram context is not available.');
    } else if (telegram['WebApp'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text("Telegram WebApp is not initialized ${telegram['WebApp']}"),
        duration: Duration(seconds: 2),
      ));
      print('Telegram WebApp is not initialized.');
    } else {
      print('Telegram WebApp context exists.');
      final initData = telegram['WebApp']['initData'];
      print('initData: $initData');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Telegram WebApp context exists $initData"),
        duration: Duration(seconds: 2),
      ));
    }
  }

  void validateTelegramData() {
    // checkTelegramContext();
    final scriptLoaded = html.document.querySelector(
            'script[src="https://telegram.org/js/telegram-web-app.js"]') !=
        null;
    if (!scriptLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Telegram Web App script not loaded."),
        duration: Duration(seconds: 2),
      ));
      // throw Exception('Telegram Web App script not loaded.');
    }

    // Fetch initData from Telegram WebApp
    final initData = js.context['Telegram']['WebApp']['initData'];
    print('Telegram initData::: $initData');
    if (initData == null || initData.toString().trim().isEmpty) {
      print('No initData available. Is this running in Telegram?');
      return;
    }

    // Parse initData into a Map
    final initDataMap = Uri.splitQueryString(initData);

    // Your bot token (replace with your bot token)
    const botToken = '7161468044:AAGoHhPmZ9nqhrEUmSZzgy5bAq7jUaZ6CMo';

    bool isValid = false;
    try {
      // Validate the data
      isValid = validateData(initDataMap, botToken);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Catch isValid:: $e"),
        duration: Duration(seconds: 2),
      ));
    }

    if (isValid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("User logged in $isValid:: $initDataMap"),
        duration: Duration(seconds: 2),
      ));
      print('Telegram data is valid.');
      print('User data: ${initDataMap}');
    } else {
      print('Telegram data validation failed!');
    }
  }

  bool validateData(Map<String, String> initData, String botToken) {
    // Extract the hash from initData
    final receivedHash = initData['hash'];
    if (receivedHash == null) return false;

    // Remove the hash key from initData
    final dataToValidate = Map.of(initData)..remove('hash');
    // Create the checkString by sorting the keys and concatenating key=value pairs
    final entries = dataToValidate.entries.toList();
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //   content: Text(
    //       "Before:: ${entries.map((e) => "${e.key}: ${e.value},").join('\n')}"),
    //   duration: Duration(seconds: 5),
    // ));
    entries.sort((a, b) => a.key.compareTo(b.key));
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //   content: Text(
    //       "After:: ${entries.map((e) => "${e.key}: ${e.value},").join('\n')}"),
    //   duration: Duration(seconds: 5),
    // ));
    // final checkString =
    //     entries.map((entry) => '${entry.key}=${entry.value}').join('\n');

    final checkString = entries.map((entry) {
      final value = entry.value is Map || entry.value is List
          ? jsonEncode(entry.value)
          : entry.value;
      return '${entry.key}=$value';
    }).join('\n');

    final hmac = Hmac(sha256, utf8.encode(botToken));
    final digest = hmac.convert(utf8.encode(checkString));
    final calculatedHash = digest.toString();

    // Generate the HMAC signature using the bot token
    // final secretKey = sha256.convert(utf8.encode(botToken)).bytes;
    // final hmac = Hmac(sha256, secretKey);
    // final calculatedHash = hmac.convert(utf8.encode(checkString)).toString();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("validateData:: ${receivedHash == calculatedHash}"),
      duration: Duration(seconds: 1),
    ));
    // Compare the received hash with the calculated hash
    return receivedHash == calculatedHash;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BottomSheetContent(),
      ),
    );
  }

/*@override
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
              duration: Duration(seconds: 10),
            ));
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UnityWidget(
                  ssId: ssid,
                  gameUrl: gameUrl,
                ),
              ),
            );
          },
          onError: (onError) {
            print(onError);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(onError), duration: Duration(seconds: 15)));
          },
        ),
      ),
    );
  }*/
}

class BottomAppBar extends StatefulWidget {
  BottomAppBar({super.key});

  @override
  State<BottomAppBar> createState() => _BottomAppBarState();
}

class _BottomAppBarState extends State<BottomAppBar> {
  int selectedId = 0;

  final data = [
    BottomTabItem(
      id: 0,
      icon: 'assets/svg/sei.svg',
      title: 'Mine',
    ),
    BottomTabItem(
      id: 1,
      icon: 'assets/svg/quests.svg',
      title: 'Quests',
    ),
    BottomTabItem(
      id: 2,
      icon: 'assets/images/airdrop.png',
      title: 'Airdrop',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xff30343a),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          12.r,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 2.5.w,
          vertical: 5.w,
        ),
        child: Row(
          children: data.map((e) {
            return BottomBarItem(
              bottomTabItem: e,
              isSelected: e.id == selectedId,
              onSelect: (id) {
                setState(() {
                  selectedId = id;
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class BottomBarItem extends StatelessWidget {
  final bool isSelected;
  final BottomTabItem bottomTabItem;
  final Function(int id) onSelect;

  const BottomBarItem({
    super.key,
    required this.bottomTabItem,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5.w / 2),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(
                  0xff292c32,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(
            8.r,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(
              8.r,
            ),
            onTap: isSelected
                ? null
                : () => onSelect(
                      bottomTabItem.id,
                    ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 9.w,
                horizontal: 15.w,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 22,
                    width: 22,
                    child: bottomTabItem.icon.endsWith('.svg')
                        ? SvgPicture.asset(
                            bottomTabItem.icon,
                            color: bottomTabItem.id == 0 ? Colors.red : null,
                          )
                        : Image.asset(
                            bottomTabItem.icon,
                          ),
                  ),
                  SizedBox(
                    height: 2.h,
                  ),
                  Text(
                    bottomTabItem.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11.sp,
                      color: isSelected
                          ? Colors.white
                          : Color(0xffFFFFFF).withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BottomSheetContent extends StatefulWidget {
  @override
  State<BottomSheetContent> createState() => _BottomSheetContentState();
}

class _BottomSheetContentState extends State<BottomSheetContent> {
  double firstWidgetHeight = 0;

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.of(context).size.height * 0.9);
    final bgHeight = 160.toDouble();
    return Stack(
      clipBehavior: Clip.none,
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
                      Color(0xFF1E1E1E).withOpacity(0.7),
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
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(
                  30.r,
                ),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 30.w,
                      vertical: 30.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CoinsToLevelUpScreen(),
                        SizedBox(
                          height: 20.h,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 30.w,
                              width: 30.w,
                              child: SvgPicture.asset(
                                'assets/svg/coin.svg',
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "9942",
                              style: TextStyle(
                                fontSize: 30.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 20.h,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                            SizedBox(height: 7.h),
                            GradientProgressBar(),
                          ],
                        ),
                        Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(
                              10.r,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                10.r,
                              ),
                              onTap: () {},
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 12.w,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'MULTIPLAYER',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10.w,
                                    ),
                                    SizedBox(
                                      height: 20.w,
                                      width: 20.w,
                                      child: SvgPicture.asset(
                                        'assets/svg/coin.svg',
                                      ),
                                    ),
                                    SizedBox(
                                      width: 3.w,
                                    ),
                                    Text(
                                      '20',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Spacer(),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: firstWidgetHeight,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 20.w,
          left: 20.w,
          right: 20.w,
          child: MeasureSize(
            child: BottomAppBar(),
            onChange: (size) {
              setState(() {
                firstWidgetHeight =
                    size.height; // Capture the height dynamically
              });
            },
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

class MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onChange;

  const MeasureSize({Key? key, required this.child, required this.onChange})
      : super(key: key);

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MeasureSize oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
  }

  void _notifySize() {
    final RenderBox renderBox =
        _key.currentContext?.findRenderObject() as RenderBox;
    widget.onChange(renderBox.size);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _key,
      child: widget.child,
    );
  }
}

class CoinsToLevelUpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width * 0.02,
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: 15.h,
                  horizontal: 10.w,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Earn per tap',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.attach_money,
                          color: Colors.orange,
                          size: 18,
                        ),
                        Flexible(
                          child: Text(
                            '+1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Second Button/Card
            SizedBox(
              width: 15.w,
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 10.w),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Coins to level up',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '10K',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GradientProgressBar extends StatelessWidget {
  double progress = 0.6;

  // Value between 0.0 (0%) and 1.0 (100%)
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // Background bar
        Container(
          width: width,
          height: 9.h,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        // Gradient progress bar
        Container(
          width: width * progress, // Dynamic width based on progress
          height: 9.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.greenAccent,
                Colors.purpleAccent,
                Colors.blueAccent,
              ],
              stops: [0.0, 0.5, 1.0], // Control gradient distribution
            ),
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      ],
    );
  }
}
