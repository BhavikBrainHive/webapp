import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webapp/enums/game_status.dart';
import 'package:webapp/model/game_session.dart';
import 'package:webapp/model/user.dart';
import 'lobby_state.dart';
import 'lobby_event.dart';

class LobbyBloc extends Bloc<LobbyEvent, LobbyState> {
  late String _sessionId;
  static final _fireStoreInstance = FirebaseFirestore.instance;
  final _fireAuthInstance = FirebaseAuth.instance;
  UserProfile? player1, player2;
  bool player1Ready = false, player2Ready = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _gameSessionSubscription;
  GameSession? _gameSession;

  LobbyBloc() : super(LobbyInitialState()) {
    on<LobbyInitialEvent>(_init);
    on<LobbyPlayerReadyEvent>(_updateReadyStatus);
    on<LobbyReloadEvent>(_onReload);
    on<OnDestroyEvent>(_onDestroy);
  }

  Future<void> _init(
    LobbyInitialEvent event,
    Emitter<LobbyState> emit,
  ) async {
    emit(LobbyLoadingState());
    _gameSession = event.gameSession;
    _sessionId = _gameSession!.sessionId;
    await _listenToGameSessionChanges(emit);
    await _gameSessionSubscription?.asFuture();
  }

  Future<void> _onReload(
    LobbyReloadEvent event,
    Emitter<LobbyState> emit,
  ) async {
    if (_gameSession != null) {
      add(LobbyInitialEvent(
        gameSession: _gameSession!,
      ));
    } else {
      print("Null on reload");
    }
  }

  Future<void> _listenToGameSessionChanges(
    Emitter<LobbyState> emit,
  ) async {
    final currentUser = _fireAuthInstance.currentUser;
    final sessionSnapshot = _fireStoreInstance
        .collection('gameSessions')
        .doc(_sessionId)
        .snapshots();
    await _gameSessionSubscription?.cancel();
    _gameSessionSubscription = sessionSnapshot.listen(
      (snapshot) async {
        if (snapshot.exists &&
            snapshot.data() != null &&
            snapshot.data()!.isNotEmpty) {
          try {
            final gameSession = GameSession.fromMap(snapshot.data()!);
            _sessionId = gameSession.sessionId;
            final player1Id = gameSession.playerIds?.first;
            final player2Id = (gameSession.playerIds?.length ?? 0) > 1
                ? gameSession.playerIds?.last
                : null;
            UserProfile? _player1, _player2;
            bool _player1Ready = player1Id != null &&
                    (gameSession.playerReady?[player1Id] ?? false),
                _player2Ready = player2Id != null &&
                    (gameSession.playerReady?[player2Id] ?? false);

            if (player1Id != null && player1 == null) {
              _player1 = await _getOpponentPlayer(player1Id);
            }
            if (player2Id != null && player2 == null) {
              _player2 = await _getOpponentPlayer(player2Id);
            }

            if ((_player1 != null && player1 == null) ||
                (_player2 != null && player2 == null) ||
                _player1Ready != player1Ready ||
                _player2Ready != player2Ready) {
              if (_player1 != null && player1 == null) {
                player1 = _player1;
              }
              if (_player2 != null && player2 == null) {
                player2 = _player2;
              }
              player1Ready = _player1Ready;
              player2Ready = _player2Ready;

              emit(
                LobbyPlayerUpdatedState(
                  player1: player1,
                  player2: player2,
                  currentPlayerId: currentUser!.uid,
                  isPlayer1Ready: player1Ready,
                  isPlayer2Ready: player2Ready,
                ),
              );
              //if both players are ready
              if (gameSession.lastReady != null &&
                  player1Ready &&
                  player2Ready) {
                await _gameSessionSubscription?.cancel();
                if (currentUser.uid == gameSession.lastReady!) {
                  await _fireStoreInstance
                      .collection('gameSessions')
                      .doc(gameSession.sessionId)
                      .update({
                    'gameStatus': GameStatus.started.name,
                  }).then((_) {
                    gameSession.gameStatus = GameStatus.started.name;
                  });
                }
                _startTheGamePlay();
                emit(OnPlayerReadyState(gameSession));
              }
            }
          } catch (e, stackTrace) {
            debugPrint("Error: $e");
            debugPrint("Stacktrace: $stackTrace");
          }
        }
        emit(LobbyLoadingState(isLoading: false));
      },
    );
  }

  void _startTheGamePlay() {}

  Future<UserProfile> _getOpponentPlayer(
    String playerId,
  ) async {
    final data =
        await _fireStoreInstance.collection('users').doc(playerId).get();
    return UserProfile.fromMap(data.data()!);
  }

  Future<void> _updateReadyStatus(
    LobbyPlayerReadyEvent event,
    Emitter<LobbyState> emit,
  ) async {
    emit(LobbyLoadingState());
    final isReady = event.isReady;
    final currentUserId = _fireAuthInstance.currentUser!.uid;
    final sessionRef =
        _fireStoreInstance.collection('gameSessions').doc(_sessionId);

    await _fireStoreInstance.runTransaction((transaction) async {
      // Get the current session document
      DocumentSnapshot snapshot = await transaction.get(sessionRef);

      if (snapshot.exists) {
        // Update the ready status and lastReady field
        Map<String, dynamic> currentData =
            snapshot.data() as Map<String, dynamic>;
        Map<String, bool> playerReady =
            Map<String, bool>.from(currentData['playerReady'] ?? {});

        // Update the player's ready status
        playerReady[currentUserId] = isReady;

        // Set the new ready status and update lastReady
        transaction.update(sessionRef, {
          'playerReady': playerReady,
          'lastReady': currentUserId,
        });
      } else {
        emit(LobbyLoadingState(isLoading: false));
      }
    });
  }

  @override
  Future<void> close() async {
    await _gameSessionSubscription?.cancel();
    return super.close();
  }

  Future<void> _onDestroy(
    OnDestroyEvent event,
    Emitter<LobbyState> emit,
  ) async {
    await _gameSessionSubscription?.cancel();
    print("On Destroy called");
  }
}
