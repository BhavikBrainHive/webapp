import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:webapp/firebase_options.dart';
import 'package:webapp/game/bloc/gameplay_bloc.dart';
import 'package:webapp/game/gameplay.dart';
import 'package:webapp/home/home.dart';
import 'package:webapp/lobby/bloc/lobby_bloc.dart';
import 'package:webapp/lobby/lobby.dart';
import 'package:webapp/login/login.dart';

import 'history/bloc/game_history_bloc.dart';
import 'history/game_history.dart';
import 'home/bloc/home_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false, // Disable offline persistence
  );

  final storage = await HydratedStorage.build(
    storageDirectory: HydratedStorage.webStorageDirectory,
  );
  HydratedBloc.storage = storage;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      initialRoute: '/login',
      builder: (_, child) {
        const mobileWidth = 400.0; // Typical mobile width in pixels
        const mobileHeight = 865.0; // Typical mobile height in pixels
        return LayoutBuilder(builder: (_, __) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: mobileWidth,
                maxHeight: mobileHeight,
              ),
              child: AspectRatio(
                aspectRatio: mobileWidth / mobileHeight,
                child: MediaQuery(
                  data: const MediaQueryData(
                    size: Size(
                      mobileWidth,
                      mobileHeight,
                    ),
                    // iPhone X dimensions
                    devicePixelRatio: 2.0,
                    // High DPI
                    padding: EdgeInsets.zero,
                    viewInsets: EdgeInsets.zero,
                    viewPadding: EdgeInsets.zero,
                  ),
                  child: child!,
                ),
              ),
            ),
          );
        });
      },
      routes: {
        '/login': (_) => const LoginScreen(),
        '/gamePlay': (_) => BlocProvider<GameplayBloc>(
              create: (_) => GameplayBloc(),
              child: const Gameplay(),
            ),
        '/history': (_) => BlocProvider<GameHistoryBloc>(
              create: (_) => GameHistoryBloc(),
              child: const GameHistory(),
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
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
    );
  }
}
