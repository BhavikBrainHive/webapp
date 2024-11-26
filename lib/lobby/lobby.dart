import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webapp/lobby/bloc/lobby_bloc.dart';
import 'package:webapp/lobby/bloc/lobby_event.dart';
import 'package:webapp/model/game_session.dart';

class Lobby extends StatefulWidget {
  const Lobby({super.key});

  @override
  State<Lobby> createState() => _LobbyState();
}

class _LobbyState extends State<Lobby> {
  LobbyBloc? _lobbyBloc;

  @override
  Future<void> didChangeDependencies() async {
    if (_lobbyBloc == null) {
      final gameArgs =
          ModalRoute.of(context)?.settings.arguments as GameSession?;
      _lobbyBloc ??= BlocProvider.of<LobbyBloc>(context);
      _lobbyBloc?.add(
        LobbyInitialEvent(
          gameSession: GameSession(
            sessionId: 'mpskrouehuiFof9YjmmD',
          ),
        ),
      );
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
