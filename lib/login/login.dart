import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:webapp/const/app_utils.dart';
import 'package:webapp/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webapp/presence/presence_bloc.dart';
import 'package:webapp/presence/presence_event.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.read<PresenceBloc>().add(InitializePresence(user.uid));
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final user =
                await signInWithGoogle(); // Use the Google Sign-In logic from earlier
            if (user != null) {
              await createUserProfile(user);
              context.read<PresenceBloc>().add(InitializePresence(user.uid));
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
          child: const Text('Sign in with Google'),
        ),
      ),
    );
  }

  Future<void> createUserProfile(User user) async {
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final userData = await userDoc.get();
    int walletPoints = AppUtils.loginWalletPoints;
    if (userData.exists &&
        userData.data() != null &&
        userData.data()!.isNotEmpty) {
      final user = UserProfile.fromMap(userData.data()!);
      walletPoints = user.wallet;
    }

    final userProfile = UserProfile(
      uid: user.uid,
      name: user.displayName ?? 'Anonymous',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      wallet: walletPoints,
    );

    await userDoc.set(userProfile.toMap(), SetOptions(merge: true));
  }

  Future<User?> signInWithGoogle() async {
    // Trigger the authentication flow
    // FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    final GoogleSignInAccount? googleUser = await GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId:
          '250440102413-nvjoo5v910b8p46htqfic1vmt2q654oi.apps.googleusercontent.com',
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
