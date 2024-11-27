import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webapp/model/game_session.dart';
import 'gameplay_event.dart';
import 'gameplay_state.dart';

class GameplayBloc extends Bloc<GameplayEvent, GameplayState> {
  static final _fireStoreInstance = FirebaseFirestore.instance;
  final _fireAuthInstance = FirebaseAuth.instance;
  late GameSession gameSession;

  GameplayBloc() : super(GameplayInitialState()) {
    on<GameplayInitialEvent>(_init);
  }

  Future<void> _init(
    GameplayInitialEvent event,
    Emitter<GameplayState> emit,
  ) async {
    gameSession = event.gameSession;
    await _fetchGameSession();
  }

  Future<void> _fetchGameSession() async {
    final sessionSnapshot = await FirebaseFirestore.instance
        .collection('gameSessions')
        .doc(gameSession.sessionId)
        .get();
    final data = sessionSnapshot.data();
    if (data != null && data.isNotEmpty) {
      gameSession = GameSession.fromMap(data);
    }
  }
}
