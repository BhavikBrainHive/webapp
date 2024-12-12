import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:peer2play_plugin/peer2play_plugin.dart';
import 'package:webapp/firebase_options.dart';
import 'package:webapp/game/bloc/gameplay_bloc.dart';
import 'package:webapp/game/gameplay.dart';
import 'package:webapp/home/home.dart';
import 'package:webapp/lobby/bloc/lobby_bloc.dart';
import 'package:webapp/lobby/lobby.dart';
import 'package:webapp/login/login.dart';

import 'config/app_config.dart';
import 'game_home.dart';
import 'history/bloc/game_history_bloc.dart';
import 'history/game_history.dart';
import 'home/bloc/home_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Peer2playPlugin.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false, // Disable offline persistence
  );
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
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
    return ScreenUtilInit(
      designSize: const Size(
        AppConfig.figmaScreenWidth,
        AppConfig.figmaScreenHeight,
      ),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        initialRoute: '/login',
        // home: const PluginTest(),
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
          '/home': (_) => MultiBlocProvider(
                providers: [
                  BlocProvider<HomeBloc>(
                    create: (_) => HomeBloc(),
                  ),
                  BlocProvider<GameHistoryBloc>(
                    create: (_) => GameHistoryBloc(),
                  ),
                ],
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
          scaffoldBackgroundColor: Color(0xff1c1f24),
          useMaterial3: true,
          fontFamily: 'Play',
        ),
      ),
    );
  }
}
