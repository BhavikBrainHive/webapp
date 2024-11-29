import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:webapp/const/app_utils.dart';
import 'package:webapp/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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

    final userProfile = UserProfile(
      uid: user.uid,
      name: user.displayName ?? 'Anonymous',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      wallet: AppUtils.loginWalletPoints,
    );

    await userDoc.set(userProfile.toMap(), SetOptions(merge: true));
  }

  Future<User?> signInWithGoogle() async {
    // Trigger the authentication flow
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

    // Sign in to Firebase with the credential
    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    return userCredential.user;
  }
}
