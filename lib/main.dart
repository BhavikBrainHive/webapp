import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webapp/firebase_options.dart';
import 'package:webapp/game/bloc/gameplay_bloc.dart';
import 'package:webapp/game/gameplay.dart';
import 'package:webapp/home/home.dart';
import 'package:webapp/lobby/bloc/lobby_bloc.dart';
import 'package:webapp/lobby/lobby.dart';
import 'package:webapp/login/login.dart';

import 'home/bloc/home_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false, // Disable offline persistence
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/gamePlay': (_) => BlocProvider<GameplayBloc>(
              create: (_) => GameplayBloc(),
              child: const Gameplay(),
            ),
        '/home': (_) => BlocProvider<HomeBloc>(
              create: (_) => HomeBloc(),
              child: const Home(),
            ),
        '/lobby': (_) => BlocProvider<LobbyBloc>(
              create: (_) => LobbyBloc(),
              child: const Lobby(),
            ),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
    );
  }
}
