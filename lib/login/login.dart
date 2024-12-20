import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'package:webapp/const/app_utils.dart';
import 'package:webapp/const/pref_const.dart';
import 'package:webapp/login/faucet_response.dart';
import 'package:webapp/login/sign_up_response.dart';
import 'package:webapp/login/user_details_response.dart';
import 'package:webapp/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webapp/phrase_dialog/verify_phrase_dialog.dart';
import 'package:webapp/presence/presence_bloc.dart';
import 'package:webapp/presence/presence_event.dart';
import 'dart:html' as html;
import 'dart:js' as js;

import '../main.dart';
import '../phrase_dialog/bloc/phrase_dialog_bloc.dart';
import '../phrase_dialog/phrase_dialog.dart';
import '../phrase_dialog/secure_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;
  bool isShown = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // context.read<PresenceBloc>().add(InitializePresence(user.uid));
        Navigator.pushReplacementNamed(context, '/home');
      } else {}
    });
  }

  Map<String, String>? checkTelegramData() {
    final scriptLoaded = html.document.querySelector(
            'script[src="https://telegram.org/js/telegram-web-app.js"]') !=
        null;
    if (!scriptLoaded) {
      return null;
      // throw Exception('Telegram Web App script not loaded.');
    }

    // Fetch initData from Telegram WebApp
    final initData = js.context['Telegram']['WebApp']['initData'];
    print('Telegram initData::: $initData');
    if (initData == null || initData.toString().trim().isEmpty) {
      print('No initData available. Is this running in Telegram?');
      return null;
    }

    // Parse initData into a Map
    final initDataMap = Uri.splitQueryString(initData);
    return initDataMap;
  }

  /// Handles the redirect result after signing in with Google
  Future<void> _handleRedirect() async {
    final UserCredential userCredential =
        await FirebaseAuth.instance.getRedirectResult();
    if (userCredential.user != null) {
      // User signed in successfully
      await createUserProfile(userCredential.user!);
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  /// Sign in with Google using redirect-based authentication
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      // Initiates the sign-in process
      await FirebaseAuth.instance.signInWithRedirect(googleProvider);
    } catch (e) {
      print('Error during Google Sign-In: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

/*
  @override
  void didChangeDependencies() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final telegramData = checkTelegramData();
        scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
          content: Text(telegramData.toString()),
          duration: Duration(seconds: 7),
        ));
        if (telegramData != null) {}
      } catch (e) {
        scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
          content: Text(e.toString()),
          duration: Duration(seconds: 7),
        ));
      }
    });

    super.didChangeDependencies();
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () async {
                final user =
                    await signInWithGoogle(); // Use the Google Sign-In logic from earlier
                if (user != null) {
                  final isSuccess = await createUserProfile(user);
                  // context.read<PresenceBloc>().add(InitializePresence(user.uid));
                  if (isSuccess) {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                }
              },
              child: const Text('Sign in with Google'),
            ),
          ),
          if (isLoading)
            Center(
              child: AbsorbPointer(
                absorbing: isLoading,
                child: const CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Future<bool?> showSecureDialog() {
    return showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return const SecureDialog();
      },
    );
  }

  Future<bool> showVerifyPhraseDialog(
    String salt, {
    int maxAttempts = 5,
  }) async {
    final pref = await SharedPreferences.getInstance();
    int attempts = 0;
    while (attempts < maxAttempts) {
      attempts++;
      final userShare = await showModalBottomSheet<String?>(
        context: context,
        useSafeArea: true,
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.transparent,
        builder: (dialogContext) {
          return VerifyPhraseDialog(
            salt: salt,
          );
        },
      );
      if (userShare != null) {
        pref.setString(PrefConst.userSharePrefKey, userShare);
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Failed to verify entered phrase. Attempt $attempts of $maxAttempts.'),
          duration: Duration(seconds: 3),
        ));
        await Future.delayed(Duration(milliseconds: 1500));
      }
    }
    // After max attempts
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Maximum verification attempts exceeded.'),
      duration: Duration(seconds: 3),
    ));
    return false;
  }

  Future<bool> createUserProfile(User user) async {
    setState(() {
      isLoading = true;
    });
    final pref = await SharedPreferences.getInstance();
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final userData = await userDoc.get();
    int walletPoints = AppUtils.loginWalletPoints;
    String? publicKey;
    int? backendUID;
    late bool isSecure;
    if (userData.exists &&
        userData.data() != null &&
        userData.data()!.isNotEmpty) {
      final user = UserProfile.fromMap(userData.data()!);
      backendUID = user.backendUID;
      walletPoints = user.wallet;
      isSecure = user.isSecure;
      publicKey = user.publicKey;
    }
    setState(() {
      isLoading = false;
    });

    if (backendUID == null) {
      final shouldSecure = (await showSecureDialog() ?? false);
      String? wordPhrases;
      if (shouldSecure) {
        final phrases = await _askForPhrases();
        if (phrases != null && phrases.isNotEmpty) {
          wordPhrases = phrases.join(" ");
        }
      }
      setState(() {
        isLoading = true;
      });

      final response = await _signUpWithBackend(
        email: user.email!,
        username: user.displayName ?? 'Unknown',
        phrases: wordPhrases,
        shouldSecure: shouldSecure,
      );
      if (response != null) {
        backendUID = response.userId!.toInt();
        pref.setInt(PrefConst.userIdPrefKey, backendUID);
        pref.setString(PrefConst.jwtSharePrefKey, response.jwtToken!);
        pref.setString(PrefConst.userSharePrefKey, response.userShare!);
      }
    } else {
      setState(() {
        isLoading = true;
      });
      final response = await _signUpWithBackend(
        email: user.email!,
      );
      bool isDeviceValid = false;
      String? salt;
      if (response != null) {
        isSecure = response.secure == true;
        isDeviceValid = response.deviceValid == true;
        salt = response.salt;
        backendUID = response.userId!.toInt();
        pref.setInt(PrefConst.userIdPrefKey, backendUID);
        pref.setString(PrefConst.jwtSharePrefKey, response.jwtToken!);
        pref.setString(PrefConst.userSharePrefKey, response.userShare!);
      }
      if (isSecure && salt != null) {
        final userShare = await showVerifyPhraseDialog(salt);
        if (!userShare) {
          pref.clear();
          await FirebaseAuth.instance.signOut();
          return false;
        }
      }
    }

    if (backendUID != null) {
      setState(() {
        isLoading = true;
      });
      final response = await _getUserDetailsApi(backendUID);
      if (response != null) {
        publicKey = response.userPublicAddress;
        pref.setString(
          PrefConst.userPublicAddressKey,
          publicKey!,
        );
        isSecure = response.secure == true;
        pref.setBool(
          PrefConst.userIsSecureKey,
          response.secure == true,
        );
        final faucetResponse = await _generateFaucet(
          publicAddress: publicKey,
        );
        if (faucetResponse != null) {
          print('ethTxHash:: ${faucetResponse.ethTxHash}');
          print('erc20TxHash:: ${faucetResponse.erc20TxHash}');
        }
      }
    }

    /*if (privateKey == null || publicKey == null) {
      final keys = createNewWallet();
      privateKey = keys['privateKeyHex'];
      publicKey = keys['publicKeyHex'];
    }*/

    final userProfile = UserProfile(
      uid: user.uid,
      backendUID: backendUID,
      name: user.displayName ?? 'Anonymous',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      publicKey: publicKey,
      wallet: walletPoints,
      isSecure: isSecure,
    );

    await userDoc.set(userProfile.toMap(), SetOptions(merge: true));
    setState(() {
      isLoading = false;
    });
    return true;
  }

  Future<List<String>?> _askForPhrases() {
    return showModalBottomSheet<List<String>?>(
      context: context,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return BlocProvider<PhraseDialogBloc>(
          create: (_) => PhraseDialogBloc(),
          child: const PhraseDialog(),
        );
      },
    );
  }

  Future<String> _getDeviceUniqueId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (kIsWeb) {
      // Web platform
      final webInfo = await deviceInfo.webBrowserInfo;
      return '${webInfo.userAgent}-${webInfo.vendor}-${webInfo.hardwareConcurrency}';
    } else if (Platform.isAndroid) {
      // Android
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id ?? 'UnknownAndroidId'; // Android ID
    } else if (Platform.isIOS) {
      // iOS
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ??
          'UnknowniOSId'; // Identifier for Vendor
    } else {
      return 'UnknownPlatform';
    }
  }

  Future<UserDetailsResponse?> _getUserDetailsApi(int userId) async {
    final response = await Dio().get(
      'https://bsnuds2t89.execute-api.ap-south-1.amazonaws.com/default/mpcSignUp',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
      ),
      queryParameters: {
        'user_id': userId,
      },
    );

    if (response.statusCode == 200) {
      if (response.data != null) {
        try {
          return UserDetailsResponse.fromJson(response.data);
        } catch (e) {
          print(e);
          return null;
        }
      }
    }
    return null;
  }

  Future<SignUpResponse?> _signUpWithBackend({
    required String email,
    String? username,
    String? phrases,
    bool? shouldSecure,
  }) async {
    final deviceId = await _getDeviceUniqueId();
    final response = await Dio().post(
      'https://bsnuds2t89.execute-api.ap-south-1.amazonaws.com/default/mpcSignUp',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'unique_identifier': email,
        'method': 'email',
        'expiry_hours': 24,
        'secure': shouldSecure,
        'password': phrases,
        'org_id': '1',
        'username': username,
        'device_info': deviceId,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      if (response.data != null) {
        try {
          return SignUpResponse.fromJson(response.data);
        } catch (e) {
          print(e);
          return null;
        }
      }
    } else if (response.statusCode == 400) {
      print(response.data);
    }
    return null;
  }

  Future<FaucetResponse?> _generateFaucet({
    required String publicAddress,
  }) async {
    final response = await Dio().post(
      'https://6kx6tuw8ag.execute-api.ap-southeast-2.amazonaws.com/default/faucetLogsV2',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': 'SQVkJvHTBS26Jy3PoxoRa6WSm1nW2d9t1sa4kUjR',
        },
      ),
      data: {
        "address": publicAddress,
        "chainId": 1328,
        "nativeAmount": "0.1",
        "network": "sei-testnet",
        "tokenAddress": "0x53cf07D5b07D093d453A6d9e0ed09207fA4b124e",
        "tokenAmount": "100"
      },
    );

    if (response.statusCode == 200) {
      if (response.data != null) {
        try {
          return FaucetResponse.fromJson(response.data);
        } catch (e) {
          print(e);
          return null;
        }
      }
    }
    return null;
  }

  Map<String, String> createNewWallet() {
    // Generate a random wallet
    final EthPrivateKey privateKey = EthPrivateKey.createRandom(Random());
    final EthereumAddress publicKey = privateKey.address;

    // Extract the wallet's private and public keys
    final String privateKeyHex = privateKey.privateKeyInt.toRadixString(16);
    final String publicKeyHex = publicKey.hexEip55;

    // Print the wallet details
    print('New Wallet Created');
    print('Public Address: $publicKeyHex');
    print('Private Key: $privateKeyHex');

    return {
      'privateKeyHex': privateKeyHex,
      'publicKeyHex': publicKeyHex,
    };
  }

  Future<User?> signInWithGoogle() async {
    // Trigger the authentication flow
    // FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    final GoogleSignInAccount? googleUser = await GoogleSignIn(
      scopes: ['email', 'profile'],
    ).signIn();

    if (googleUser == null) {
      // The user canceled the sign-in
      return null;
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    // FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    // Sign in to Firebase with the credential
    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

// print('login res: ${userCredential.user?.uid}');
    return userCredential.user;
  }
}
