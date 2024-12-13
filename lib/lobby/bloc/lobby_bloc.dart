import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:webapp/enums/game_status.dart';
import 'package:webapp/history/bloc/game_history_bloc.dart';
import 'package:webapp/model/game_session.dart';
import 'package:webapp/model/user.dart';
import 'lobby_state.dart';
import 'lobby_event.dart';

class LobbyBloc extends HydratedBloc<LobbyEvent, LobbyState> {
  late String _sessionId;
  late User _currentUser;
  static final _fireStoreInstance = FirebaseFirestore.instance;
  final _fireAuthInstance = FirebaseAuth.instance;
  UserProfile? player1, player2;
  bool player1Ready = false, player2Ready = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _gameSessionSubscription;
  GameSession? _gameSession;
  Timer? _timer;
  DateTime? _expireTime;

  LobbyBloc() : super(LobbyInitialState()) {
    on<LobbyInitialEvent>(_init);
    on<LobbyPlayerReadyEvent>(_updateReadyStatus);
    on<LobbyPlayerCancelEvent>(_onCancel);
    on<StartTimerEvent>(_startTimer);
    on<TimerTickEvent>(_timerTickEvent);
    on<StopTimerEvent>(_stopTimerEvent);

    if (_gameSession != null) {
      add(LobbyInitialEvent(
        gameSession: _gameSession!,
      ));
    }
  }

  void _startTimer(
    StartTimerEvent event,
    Emitter<LobbyState> emit,
  ) {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        final int remainingTime = event.duration - timer.tick;
        if (remainingTime > 0) {
          add(TimerTickEvent(remainingTime));
        } else {
          _timer?.cancel();
          add(TimerTickEvent(0));
        }
      },
    );
  }

  void _stopTimerEvent(
    StopTimerEvent event,
    Emitter<LobbyState> emit,
  ) {
    _timer?.cancel();
    if (event.isExpired) {
      add(TimerTickEvent(0));
    }
  }

  Future<void> _timerTickEvent(
    TimerTickEvent event,
    Emitter<LobbyState> emit,
  ) async {
    emit(
      TimerRunningState(
        remainingTime: event.remainingTime,
      ),
    );
    if (event.remainingTime <= 0) {
      if (!player2Ready || !player2Ready) {
        if (_currentUser.uid == player1!.uid) {
          await _gameSessionSubscription?.cancel();
          try {
            await _fireStoreInstance
                .collection('gameSessions')
                .doc(_sessionId)
                .delete();
          } catch (e) {
            print(e);
          }
        }
        emit(RoomExpiredState());
      }
    }
  }

  @override
  Map<String, dynamic>? toJson(LobbyState state) {
    // Persist only `gameSession` when available
    if (_gameSession != null) {
      return {
        'gameSession': _gameSession!.toMap(
          isCache: true,
        ),
      };
    }
    return null;
  }

  @override
  LobbyState? fromJson(Map<String, dynamic> json) {
    try {
      if (json.containsKey('gameSession')) {
        _gameSession = GameSession.fromMap(
          json['gameSession'],
          isCache: true,
        );
        print("lobby fromJson ${_gameSession?.sessionId}");
        if (_gameSession != null) {
          // Re-add the `LobbyInitialEvent` after restoration
          add(LobbyInitialEvent(gameSession: _gameSession!));
        }
      }
      return LobbyInitialState();
    } catch (e) {
      debugPrint('Error deserializing gameSession: $e');
      return null;
    }
  }

  Future<void> _init(
    LobbyInitialEvent event,
    Emitter<LobbyState> emit,
  ) async {
    emit(LobbyLoadingState());
    _currentUser = _fireAuthInstance.currentUser!;
    _gameSession = event.gameSession;
    _sessionId = _gameSession!.sessionId;
    await _listenToGameSessionChanges(emit);
    await _gameSessionSubscription?.asFuture();
  }

  Future<void> _listenToGameSessionChanges(
    Emitter<LobbyState> emit,
  ) async {
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
            final player1Id = gameSession.playerIds
                ?.firstWhereOrNull((e) => e == _currentUser.uid);
            final player2Id =
                player1Id != null && (gameSession.playerIds?.length ?? 0) > 1
                    ? gameSession.playerIds?.firstWhere((e) => e != player1Id)
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

            final expireTime = gameSession.expireTime!;
            if (_expireTime == null ||
                _expireTime!.compareTo(expireTime) != 0) {
              _expireTime = expireTime;
              int currentTime =
                  (await getServerTime()).millisecondsSinceEpoch ~/ 1000;
              int endTime = _expireTime!.millisecondsSinceEpoch ~/ 1000;
              int timeLeft = endTime - currentTime;
              _timer?.cancel();
              add(StartTimerEvent(timeLeft));
            }

            if (player2 != null &&
                player2Id == null &&
                player2!.uid == _currentUser.uid) {
              _timer?.cancel();
              await _gameSessionSubscription?.cancel();
              emit(LobbyExitedState());
              return;
            }

            if ((_player1 != null && player1 == null) ||
                (_player2 != null && player2 == null) ||
                (player2 != null && player2Id == null) ||
                _player1Ready != player1Ready ||
                _player2Ready != player2Ready) {
              if (_player1 != null && player1 == null) {
                player1 = _player1;
              }
              if (_player2 != null && player2 == null) {
                player2 = _player2;
              }

              if (player2 != null && player2Id == null) {
                player2 = null;
              }
              player1Ready = _player1Ready;
              player2Ready = _player2Ready;

              emit(
                LobbyPlayerUpdatedState(
                  player1: player1,
                  player2: player2,
                  isHost: _currentUser.uid == gameSession.playerIds?.first,
                  currentPlayerId: _currentUser.uid,
                  isPlayer1Ready: player1Ready,
                  isPlayer2Ready: player2Ready,
                ),
              );
              //if both players are ready
              if (gameSession.lastReady != null &&
                  player1Ready &&
                  player2Ready) {
                add(StopTimerEvent(isExpired: false));
                await _gameSessionSubscription?.cancel();
                if (_currentUser.uid == gameSession.lastReady!) {
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
        } else {
          await _gameSessionSubscription?.cancel();
          emit(LobbyLoadingState(isLoading: false));
          emit(LobbyExitedState());
        }
        emit(LobbyLoadingState(isLoading: false));
      },
    );
  }

  void _startTheGamePlay() {}

  Future<void> _onCancel(
    LobbyPlayerCancelEvent event,
    Emitter<LobbyState> emit,
  ) async {
    emit(LobbyLoadingState());
    final sessionRef =
        _fireStoreInstance.collection('gameSessions').doc(_sessionId);
    await _fireStoreInstance.runTransaction((transaction) async {
      // Get the current session document
      DocumentSnapshot snapshot = await transaction.get(sessionRef);

      if (snapshot.exists) {
        final gameSession = GameSession.fromMap(
          snapshot.data()! as Map<String, dynamic>,
        );
        final player1Id = gameSession.playerIds?.first;
        final player2Id = (gameSession.playerIds?.length ?? 0) > 1
            ? gameSession.playerIds?.last
            : null;
        bool _player1Ready = player1Id != null &&
                (gameSession.playerReady?[player1Id] ?? false),
            _player2Ready = player2Id != null &&
                (gameSession.playerReady?[player2Id] ?? false);
        final isAdmin = _currentUser.uid == player1Id;
        if (!_player1Ready || !_player2Ready) {
          if (isAdmin) {
            transaction.delete(sessionRef);
          } else {
            if (gameSession.playerIds?.contains(player2Id) == true) {
              transaction.update(sessionRef, {
                "playerIds": FieldValue.arrayRemove([player2Id]),
              });
            }
            if (gameSession.playerReady?[player2Id] != null) {
              transaction.update(sessionRef, {
                "playerReady.$player2Id": FieldValue.delete(),
              });
            }
            if (gameSession.scores?[player2Id] != null) {
              transaction.update(sessionRef, {
                "scores.$player2Id": FieldValue.delete(),
              });
            }
          }
        }
      }
    });
    emit(LobbyLoadingState(isLoading: false));
  }

  Future<UserProfile> _getOpponentPlayer(
    String playerId,
  ) async {
    final data =
        await _fireStoreInstance.collection('users').doc(playerId).get();
    return UserProfile.fromMap(data.data()!);
  }

  Future<DateTime> getServerTime() async {
    try {
      // Step 1: Write the temporary document with the server timestamp
      final DocumentReference tempDoc =
          _fireStoreInstance.collection('temp').doc(_currentUser.uid);
      await tempDoc.set({'timestamp': FieldValue.serverTimestamp()});

      // Step 2: Read the document
      DocumentSnapshot snapshot = await tempDoc.get();

      // Step 3: Retrieve the server timestamp
      Timestamp? serverTimestamp = snapshot.get('timestamp');

      // Step 4: Delete the temporary document
      await tempDoc.delete();

      // Step 5: Convert the server timestamp to DateTime and return it
      return serverTimestamp?.toDate() ?? DateTime.timestamp().toUtc();
    } catch (e, stackTrace) {
      print("Error :: $e ${FirebaseAuth.instance.currentUser?.uid} mmm");
      print("Stack Trace :: $stackTrace");
      return DateTime.timestamp().toUtc();
    }
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
    clear();
    _timer?.cancel();
    await _gameSessionSubscription?.cancel();
    return super.close();
  }
}
