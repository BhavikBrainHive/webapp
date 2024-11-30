import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webapp/const/app_utils.dart';
import 'package:webapp/enums/game_status.dart';
import 'package:webapp/model/game_session.dart';
import 'package:webapp/model/user.dart';
import 'gameplay_event.dart';
import 'gameplay_state.dart';

class GameplayBloc extends Bloc<GameplayEvent, GameplayState> {
  static final _fireStoreInstance = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _gameSessionSubscription;
  final _fireAuthInstance = FirebaseAuth.instance;
  late GameSession _gameSession;
  late User _currentUser;
  DateTime? _startTime;
  int? _score;
  Timer? _timer;
  Timer? _scoreTimer;
  int _lastSavedScore = 0;

  GameplayBloc() : super(GameplayInitialState()) {
    on<GameplayInitialEvent>(_init);
    on<StartTimerEvent>(_startTimer);
    on<TimerTickEvent>(_timerTickEvent);
    on<StopTimerEvent>(_stopTimerEvent);
    on<OnHitTapEvent>(_onTapEvent);
  }

  Future<void> _init(
    GameplayInitialEvent event,
    Emitter<GameplayState> emit,
  ) async {
    emit(GameplayLoadingState());
    _gameSession = event.gameSession;
    _currentUser = _fireAuthInstance.currentUser!;
    await _listenToGameSessionChanges(emit);
    await _gameSessionSubscription?.asFuture();
  }

  Future<void> _listenToGameSessionChanges(
    Emitter<GameplayState> emit,
  ) async {
    final sessionSnapshot = _fireStoreInstance
        .collection('gameSessions')
        .doc(_gameSession.sessionId)
        .snapshots();
    _gameSessionSubscription = sessionSnapshot.listen(
      (snapshot) async {
        final data = snapshot.data();
        if (snapshot.exists && data != null && data.isNotEmpty) {
          print(snapshot.id);
          _gameSession = GameSession.fromMap(data);
          final score = _gameSession.scores?[_currentUser.uid] ?? 0;
          final startTime = _gameSession.startTime;

          if (_score == null) {
            _score = score;
            emit(
              OnScoreChangeState(
                score: _score!,
              ),
            );
            _startScoreTimer();
          }

          if (_gameSession.isActive == true &&
              _gameSession.gameStatus == GameStatus.started.name) {
            if (startTime == null) {
              //save start as now
              await _fireStoreInstance.runTransaction(
                (transaction) async {
                  final sessionRef = _fireStoreInstance
                      .collection('gameSessions')
                      .doc(_gameSession.sessionId);
                  final startTime = await getServerTime();
                  transaction.update(sessionRef, {
                    'startTime': startTime,
                  });
                },
              );
            } else {
              //startTimer
              if (_startTime == null ||
                  _startTime!.compareTo(startTime) != 0 ||
                  (_timer?.isActive ?? false) == false) {
                _startTime = startTime;
                int currentTime =
                    (await getServerTime()).millisecondsSinceEpoch ~/ 1000;
                int endTime = _startTime!
                        .add(
                          const Duration(
                            milliseconds: AppUtils.gamePlayTimeInMills,
                          ),
                        )
                        .millisecondsSinceEpoch ~/
                    1000;
                int timeLeft = endTime - currentTime;
                _timer?.cancel();
                emit(GameplayLoadingState(isLoading: false));
                add(StartTimerEvent(timeLeft));
              } else {
                emit(GameplayLoadingState(isLoading: false));
              }
            }
          } else {
            if (_gameSession.gameStatus == GameStatus.finished.name) {
              await _gameSessionSubscription?.cancel();
              final sessionSnapshot = await _fireStoreInstance
                  .collection('gameSessions')
                  .doc(_gameSession.sessionId)
                  .get();
              _gameSession = GameSession.fromMap(sessionSnapshot.data()!);
              final player1Id = _gameSession.playerIds!.first!;
              final player2Id = (_gameSession.playerIds!.length ?? 0) > 1
                  ? _gameSession.playerIds!.last!
                  : null;
              final player1score = _gameSession.scores?[player1Id] ?? 0;
              final player2score = _gameSession.scores?[player2Id] ?? 0;
              final player1Snapshot = await _fireStoreInstance
                  .collection('users')
                  .doc(player1Id)
                  .get();
              final player1 = UserProfile.fromMap(player1Snapshot.data()!);
              final player2Snapshot = await _fireStoreInstance
                  .collection('users')
                  .doc(player2Id)
                  .get();
              final player2 = UserProfile.fromMap(player2Snapshot.data()!);

              //determine winner
              final result = _determineWinner();
              emit(GameplayLoadingState(isLoading: false));
              emit(
                GameCompleteState(
                  player1Name: player1.name,
                  player2Name: player2.name,
                  player1Score: player1score,
                  player2Score: player2score,
                  isDraw: result == 'draw',
                  isWinner: result == _currentUser.uid,
                ),
              );
            } else {
              emit(GameplayLoadingState(isLoading: false));
            }
          }
        } else {
          emit(GameplayLoadingState(isLoading: false));
        }
      },
    );
  }

  void _startTimer(
    StartTimerEvent event,
    Emitter<GameplayState> emit,
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

  String _determineWinner() {
    final player1Id = _gameSession.playerIds!.first!;
    final player2Id = (_gameSession.playerIds!.length ?? 0) > 1
        ? _gameSession.playerIds!.last!
        : null;
    final player1score = _gameSession.scores?[player1Id] ?? 0;
    final player2score = _gameSession.scores?[player2Id] ?? 0;

    if (player1score > player2score) {
      return player1Id; // Player 1 wins
    } else if (player2score > player1score) {
      return player2Id!; // Player 2 wins
    } else {
      return 'draw'; // It's a draw
    }
  }

  void _stopTimerEvent(
    StopTimerEvent event,
    Emitter<GameplayState> emit,
  ) {
    _timer?.cancel();
    add(TimerTickEvent(0));
  }

  Future<void> _timerTickEvent(
    TimerTickEvent event,
    Emitter<GameplayState> emit,
  ) async {
    emit(
      TimerRunningState(
        remainingTime: event.remainingTime,
      ),
    );
    if (event.remainingTime == 0) {
      await _onGameplayEnd(emit);
      //save last score and s=change game status to finished
    }
  }

  Future<void> _onGameplayEnd(
    Emitter<GameplayState> emit,
  ) async {
    emit(GameplayLoadingState());
    _scoreTimer?.cancel();
    await Future.delayed(Duration(seconds: 2));
    await _updateScoreInTransaction(
      forceUpdate: true,
    );
    await Future.delayed(Duration(seconds: 1));
    await _fireStoreInstance
        .collection('gameSessions')
        .doc(_gameSession.sessionId)
        .update({
      'isActive': false,
      'gameStatus': GameStatus.finished.name,
    });
  }

  void _onTapEvent(
    OnHitTapEvent event,
    Emitter<GameplayState> emit,
  ) {
    _score = (_score ?? 0) + 1;
    emit(OnScoreChangeState(score: _score!));
  }

  void _startScoreTimer() {
    _scoreTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) async {
        _updateScoreInTransaction();
      },
    );
  }

  Future<void> _updateScoreInTransaction({
    bool forceUpdate = false,
  }) async {
    final gameSessionRef = FirebaseFirestore.instance
        .collection('gameSessions')
        .doc(_gameSession.sessionId);
    final scoreToSave = _score ?? 0;
    if (scoreToSave > 0 && (forceUpdate || scoreToSave != _lastSavedScore)) {
      try {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          // Get the current document
          DocumentSnapshot snapshot = await transaction.get(gameSessionRef);
          if (snapshot.exists) {
            final gameSession =
                GameSession.fromMap(snapshot.data() as Map<String, dynamic>);
            if (gameSession.gameStatus == GameStatus.started.name) {
              Map<String, dynamic> scores = gameSession.scores ?? {};

              // Update the user's score in the scores map
              scores[_currentUser.uid] = scoreToSave;

              // Commit the updated scores map back to Firestore
              transaction.update(gameSessionRef, {
                'scores': scores,
              });
              return scoreToSave;
            }
          }
          return null;
        }).then((value) {
          if (value != null) {
            _lastSavedScore = value;
          }
        });

        print('Score updated successfully!');
      } catch (e) {
        print('Error updating score: $e');
      }
    }
  }

  Future<DateTime> getServerTime() async {
    try {
      // Step 1: Write the temporary document with the server timestamp
      final DocumentReference tempDoc =
          _fireStoreInstance.collection('temp').doc('tempDoc');
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
      print("Error :: $e ${FirebaseAuth.instance.currentUser?.uid}");
      print("Stack Trace :: $stackTrace");
    }
    return DateTime.timestamp().toUtc();
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _updateScoreInTransaction(
      forceUpdate: true,
    );
    await _gameSessionSubscription?.cancel();
    return super.close();
  }
}
