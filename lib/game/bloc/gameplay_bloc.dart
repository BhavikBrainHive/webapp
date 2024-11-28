import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webapp/model/game_session.dart';
import 'gameplay_event.dart';
import 'gameplay_state.dart';

class GameplayBloc extends Bloc<GameplayEvent, GameplayState> {
  static final _fireStoreInstance = FirebaseFirestore.instance;
  final _fireAuthInstance = FirebaseAuth.instance;
  late GameSession _gameSession;
  late User _currentUser;
  DateTime? _startTime;
  int? _score;
  Timer? _timer;

  GameplayBloc() : super(GameplayInitialState()) {
    on<GameplayInitialEvent>(_init);
    on<StartTimerEvent>(_startTimer);
    on<TimerTickEvent>(_timerTickEvent);
    on<StopTimerEvent>(_stopTimerEvent);
  }

  Future<void> _init(
    GameplayInitialEvent event,
    Emitter<GameplayState> emit,
  ) async {
    emit(GameplayLoadingState());
    _gameSession = event.gameSession;
    _currentUser = _fireAuthInstance.currentUser!;
    await _fetchGameSession(emit);
  }

  Future<void> _fetchGameSession(
    Emitter<GameplayState> emit,
  ) async {
    final sessionSnapshot = await FirebaseFirestore.instance
        .collection('gameSessions')
        .doc(_gameSession.sessionId)
        .get();
    final data = sessionSnapshot.data();
    if (data != null && data.isNotEmpty) {
      _gameSession = GameSession.fromMap(data);
      final startTime = _gameSession.startTime;

      if (startTime == null) {
        //save start as now
      } else {
        //startTimer
      }

      final score = _gameSession.scores?[_currentUser.uid] ?? 0;
      if (_score == null) {
        _score = score;
        emit(
          OnScoreChangeState(
            score: _score!,
          ),
        );
      }
    }
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
      emit(TimerCompleteState());
    }
  }
}
