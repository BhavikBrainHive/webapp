import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webapp/model/game_session.dart';
import 'package:webapp/model/user.dart';
import 'lobby_state.dart';
import 'lobby_event.dart';

class LobbyBloc extends Bloc<LobbyEvent, LobbyState> {
  static final _fireStoreInstance = FirebaseFirestore.instance;
  UserProfile? player1, player2;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _gameSessionSubscription;
  late GameSession gameSession;

  LobbyBloc() : super(LobbyInitialState()) {
    on<LobbyInitialEvent>(_init);
  }

  Future<void> _init(
    LobbyInitialEvent event,
    Emitter<LobbyState> emit,
  ) async {
    await _listenToGameSessionChanges(
      event.gameSession.sessionId,
    );
  }

  Future<void> _listenToGameSessionChanges(
    String sessionId,
  ) async {}
}
