import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webapp/enums/game_status.dart';
import 'package:webapp/history/model/game_history_model.dart';
import 'package:webapp/model/game_session.dart';
import 'package:webapp/model/user.dart';
import 'package:collection/collection.dart';
import 'game_history_event.dart';
import 'game_history_state.dart';

class GameHistoryBloc extends Bloc<GameHistoryEvent, GameHistoryState> {
  final _fireStoreInstance = FirebaseFirestore.instance;
  final _fireAuthInstance = FirebaseAuth.instance;
  late User _currentUser;
  late UserProfile _currentUserProfile;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _myGameSessionsSubscription;

  GameHistoryBloc() : super(GameHistoryInitialState()) {
    on<GameHistoryInitialEvent>(_init);
    add(GameHistoryInitialEvent());
  }

  Future<void> _init(
    GameHistoryInitialEvent event,
    Emitter<GameHistoryState> emit,
  ) async {
    emit(GameHistoryLoadingState());
    _currentUser = _fireAuthInstance.currentUser!;
    _currentUserProfile = await _getOpponentPlayer(
      _currentUser.uid,
    );
    _listenGameHistory(emit);
    await _myGameSessionsSubscription?.asFuture();
  }

  void _listenGameHistory(
    Emitter<GameHistoryState> emit,
  ) {
    final sessionSnapshot = _fireStoreInstance
        .collection('gameSessions')
        .where(
          'isActive',
          isEqualTo: false,
        )
        .where(
          'gameStatus',
          isEqualTo: GameStatus.finished.name,
        )
        .where(
          'playerIds',
          arrayContains: _currentUser.uid,
        )
        .orderBy(
          'timestamp',
          descending: true,
        )
        .snapshots();
    emit(GameHistoryLoadingState());
    _myGameSessionsSubscription = sessionSnapshot.listen(
      (snapshot) async {
        try {
          final sessions = <GameHistoryModel>[];
          await Future.forEach(snapshot.docs, (item) async {
            final session = GameSession.fromMap(item.data());
            final player2Id = session.playerIds?.firstWhereOrNull(
              (item) => item != _currentUser.uid,
            );
            UserProfile? opponent;
            if (player2Id != null) {
              opponent = await _getOpponentPlayer(
                player2Id,
              );
            }
            final result = _determineWinner(session);
            sessions.add(
              GameHistoryModel(
                players: [
                  _currentUserProfile,
                  opponent,
                ],
                gameSession: session,
                isDraw: result == 'draw',
                isWinner: result == _currentUserProfile.uid,
              ),
            );
          });

          emit(
            GameHistoryDataUpdated(
              gameHistoryList: sessions,
              currentPlayerId: _currentUserProfile.uid,
            ),
          );
          emit(
            GameHistoryLoadingState(
              isLoading: false,
            ),
          );
        } catch (e) {
          emit(
            GameHistoryLoadingState(
              isLoading: false,
            ),
          );
          print('Error fetching game sessions: $e');
          emit(GameHistoryDataUpdated(
            currentPlayerId: _currentUserProfile.uid,
          ));
        }
      },
    );
  }

  Future<UserProfile> _getOpponentPlayer(
    String playerId,
  ) async {
    final data =
        await _fireStoreInstance.collection('users').doc(playerId).get();
    return UserProfile.fromMap(data.data()!);
  }

  String _determineWinner(GameSession gameSession) {
    final player1Id = gameSession.playerIds!.first!;
    final player2Id = (gameSession.playerIds!.length) > 1
        ? gameSession.playerIds!.last!
        : null;
    final player1score = gameSession.scores?[player1Id] ?? 0;
    final player2score = gameSession.scores?[player2Id] ?? 0;

    if (player1score > player2score) {
      return player1Id; // Player 1 wins
    } else if (player2score > player1score) {
      return player2Id!; // Player 2 wins
    } else {
      return 'draw'; // It's a draw
    }
  }

  @override
  Future<void> close() async {
    await _myGameSessionsSubscription?.cancel();
    return super.close();
  }
}
