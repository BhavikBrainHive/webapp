import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webapp/const/app_utils.dart';
import 'package:webapp/enums/game_status.dart';
import 'package:webapp/model/game_session.dart';

import '../../model/user.dart';
import 'home_state.dart';
import 'home_event.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;
  final _fireStoreInstance = FirebaseFirestore.instance;
  final _fireAuthInstance = FirebaseAuth.instance;
  UserProfile? profile;

  UserProfile? get userProfile => profile;

  HomeBloc() : super(HomeInitialState()) {
    on<HomeInitialEvent>(_init);
    on<HomeStartGameEvent>(_start);
    add(HomeInitialEvent());
  }

  Future<void> _init(
    HomeInitialEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(ProfileLoadingState());
    final user = _fireAuthInstance.currentUser;
    if (user != null) {
      _userSubscription = _fireStoreInstance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.exists && snapshot.data()?.isNotEmpty == true) {
          profile = UserProfile.fromMap(snapshot.data()!);
        } else {
          profile = null;
        }
        if (profile != null) {
          emit(ProfileUpdatedState(profile!));
        }
      });

      final alreadyGoingSession = await _checkIfAnyGameGoing(user.uid);
      if (alreadyGoingSession != null) {
        emit(GameSessionFoundState(alreadyGoingSession));
      }
    }
    emit(
      ProfileLoadingState(
        isLoading: false,
      ),
    );
    await _userSubscription?.asFuture();
  }

  Future<void> _start(
    HomeStartGameEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (profile != null) {
      emit(ProfileLoadingState());
      final gameSession = await joinGameSession();
      emit(ProfileLoadingState(isLoading: false));
      emit(GameSessionFoundState(gameSession));
    }
  }

  Future<GameSession?> _checkIfAnyGameGoing(
    String playerId,
  ) async {
    final waitingSessions = await FirebaseFirestore.instance
        .collection('gameSessions')
        .where('isActive', isEqualTo: true)
        .where(
          Filter.or(
            Filter('gameStatus', isEqualTo: GameStatus.waiting.name),
            Filter('gameStatus', isEqualTo: GameStatus.started.name),
          ),
        )
        .where(
          'playerIds',
          arrayContains: playerId,
        )
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (waitingSessions.docs.isNotEmpty &&
        waitingSessions.docs.first.data().isNotEmpty) {
      // Already in a session
      try {
        final session = GameSession.fromMap(
          waitingSessions.docs.first.data(),
        );
        final expireTime = session.expireTime;
        final currentTime = await getServerTime();

        if (expireTime != null) {
          final isSessionAlive = currentTime!.isBefore(
            expireTime,
          );
          if (isSessionAlive) {
            return session;
          }
        }
        return null;
      } catch (_) {}
    }
    return null;
  }

  Future<GameSession> joinGameSession() async {
    final playerId = profile!.uid;

    final alreadyGoingSession = await _checkIfAnyGameGoing(
      playerId,
    );
    if (alreadyGoingSession != null) {
      return alreadyGoingSession;
    }

    // Find a session with only one player
    final availableSessions = await FirebaseFirestore.instance
        .collection('gameSessions')
        .where('isActive', isEqualTo: true)
        .where('gameStatus', isEqualTo: GameStatus.waiting.name)
        .orderBy('timestamp', descending: true)
        .get();

    if (availableSessions.docs.isNotEmpty) {
      final resultSession =
          await FirebaseFirestore.instance.runTransaction((transaction) async {
        for (var doc in availableSessions.docs) {
          final sessionDoc = await transaction.get(doc.reference);
          final sessionData = sessionDoc.data();
          if (sessionData != null && sessionData.isNotEmpty) {
            var session = GameSession.fromMap(sessionData);
            final expireTime = session.expireTime;
            final currentTime = await getServerTime();
            if (expireTime != null) {
              final isSessionAlive = currentTime!.isBefore(
                expireTime,
              );
              if ((session.playerIds?.length ?? 0) >= 2) {
              } else if (isSessionAlive) {
                session
                  ..gameStatus = GameStatus.started.name
                  ..playerIds?.add(playerId);
                transaction.update(sessionDoc.reference, {
                  'playerIds': FieldValue.arrayUnion([playerId]),
                  'gameStatus': GameStatus.started.name,
                });
                return session;
              }
            }
          }
        }
        return null;
      });
      if (resultSession == null) {
        return _createGameSession(playerId);
      } else {
        return resultSession;
      }
    } else {
      // No available sessions; create a new one
      return _createGameSession(playerId);
    }
  }

  Future<GameSession> _createGameSession(
    String playerId,
  ) async {
    print("Create");
    final sessionId =
        FirebaseFirestore.instance.collection('gameSessions').doc().id;
    final gameSession = GameSession(
      sessionId: sessionId,
      playerIds: [playerId],
      isActive: true,
      expireTime: await calculateGameExpiration(),
      gameStatus: GameStatus.waiting.name,
    );

    await FirebaseFirestore.instance
        .collection('gameSessions')
        .doc(sessionId)
        .set(
          gameSession.toMap()
            ..putIfAbsent(
              'timestamp',
              () => FieldValue.serverTimestamp(),
            ),
        );

    return gameSession;
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }

  Future<DateTime> calculateGameExpiration() async {
    DateTime? serverTime = await getServerTime();
    return serverTime!.add(
      const Duration(
        milliseconds: AppUtils.gameSessionExpirationTimeInMills,
      ),
    );
  }

  Future<DateTime?> getServerTime() async {
    try {
      // Step 1: Write the temporary document with the server timestamp
      final DocumentReference tempDoc =
          _fireStoreInstance.collection('temp').doc('tempDoc');
      await tempDoc.set({'timestamp': FieldValue.serverTimestamp()});

      // Step 2: Read the document
      DocumentSnapshot snapshot = await tempDoc.get();

      // Step 3: Retrieve the server timestamp
      Timestamp serverTimestamp = snapshot.get('timestamp');

      // Step 4: Delete the temporary document
      await tempDoc.delete();

      // Step 5: Convert the server timestamp to DateTime and return it
      return serverTimestamp.toDate();
    } catch (e, stackTrace) {
      print("Error :: $e ${FirebaseAuth.instance.currentUser?.uid}");
      print("Stack Trace :: $stackTrace");
    }
    return null;
  }
}
