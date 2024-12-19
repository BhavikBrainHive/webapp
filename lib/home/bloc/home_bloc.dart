import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webapp/const/app_utils.dart';
import 'package:webapp/const/pref_const.dart';
import 'package:webapp/enums/game_status.dart';
import 'package:webapp/home/model/create_lsa_response.dart';
import 'package:webapp/model/game_session.dart';

import '../../model/user.dart';
import 'home_state.dart';
import 'home_event.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;
  final _fireStoreInstance = FirebaseFirestore.instance;
  final _fireAuthInstance = FirebaseAuth.instance;
  UserProfile? _profile;

  UserProfile? get userProfile => _profile;

  HomeBloc() : super(HomeInitialState()) {
    on<HomeInitialEvent>(_init);
    on<CreateLSAEvent>(_onCreateLSA);
    on<SecureWalletEvent>(_onSecureWallet);
    on<HomeStartGameEvent>(_start);
    add(HomeInitialEvent());
  }

  Future<void> _init(
    HomeInitialEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(ProfileLoadingState());
    final user = _fireAuthInstance.currentUser;
    print("Current user ${user?.uid}");
    if (user != null) {
      _userSubscription = _fireStoreInstance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.exists && snapshot.data()?.isNotEmpty == true) {
          _profile = UserProfile.fromMap(snapshot.data()!);
        } else {
          _profile = null;
        }
        if (_profile != null) {
          emit(ProfileUpdatedState(_profile!));
        }
      });

      final alreadyGoingSession = await _checkIfAnyGameGoing(user.uid);
      if (alreadyGoingSession != null) {
        emit(GameSessionFoundState(alreadyGoingSession));
      }
      emit(
        ProfileLoadingState(
          isLoading: false,
        ),
      );
    } else {
      emit(
        ProfileLoadingState(
          isLoading: false,
        ),
      );
      emit(UserNotFoundState());
    }
    await _userSubscription?.asFuture();
  }

  Future<void> _start(
    HomeStartGameEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (_profile != null) {
      if ((_profile?.wallet ?? 0) > 0 &&
          AppUtils.stakingPoints <= (_profile?.wallet ?? 0)) {
        emit(ProfileLoadingState());
        final gameSession = await joinGameSession();
        emit(ProfileLoadingState(isLoading: false));
        emit(GameSessionFoundState(gameSession));
      } else {
        emit(HomeInsufficientFundState());
      }
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
    final playerId = _profile!.uid;

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
        final currentTime = await getServerTime();
        for (var doc in availableSessions.docs) {
          final sessionDoc = await transaction.get(doc.reference);
          final sessionData = sessionDoc.data();
          if (sessionData != null && sessionData.isNotEmpty) {
            var session = GameSession.fromMap(sessionData);
            final isValidAmount = (session.totalAmount ?? 0) > 0 &&
                (_profile?.wallet ?? 0) > 0 &&
                (session.totalAmount ?? 0) <= _profile!.wallet;
            final expireTime = session.expireTime;
            if (isValidAmount && expireTime != null) {
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
                  'totalAmount': (session.totalAmount! * 2),
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

  Future<void> _onCreateLSA(
    CreateLSAEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(ProfileLoadingState());
    final response = await _createLSA();
    emit(ProfileLoadingState(isLoading: false));
    if (response != null) {
      print('LSA resp: ${response.message}');
      print('LSA resp: ${response.transactionHash}');
    }
  }

  Future<void> _onSecureWallet(
    SecureWalletEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(ProfileLoadingState());
    final wordPhrases = event.wordPhrases;
    final isSecure = await _makeWalletSecureApi(
      phrases: wordPhrases,
    );
    if (isSecure) {
      await _fireStoreInstance.collection('users').doc(_profile!.uid).update({
        'isSecure': true,
      });
    }
    emit(ProfileLoadingState(isLoading: false));
  }

  Future<bool> _makeWalletSecureApi({
    required String phrases,
  }) async {
    final pref = await SharedPreferences.getInstance();
    final userId = pref.getInt(PrefConst.userIdPrefKey);
    try {
      final response = await Dio().put(
        'https://bsnuds2t89.execute-api.ap-south-1.amazonaws.com/default/mpcSignUp',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "user_id": userId,
          "secure": true,
          "password": phrases,
        },
      );

      print(response.data);
      return response.statusCode == 200;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<CreateLsaResponse?> _createLSA() async {
    final pref = await SharedPreferences.getInstance();
    final userShare = pref.getString(PrefConst.userSharePrefKey);
    final userId = pref.getInt(PrefConst.userIdPrefKey);
    try {
      final response = await Dio().post(
        'https://vu38271big.execute-api.ap-south-1.amazonaws.com/default/lsav1',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "user_id": userId,
          "user_key": userShare,
        },
      );

      if (response.statusCode == 200) {
        if (response.data != null) {
          try {
            return CreateLsaResponse.fromJson(response.data);
          } catch (e) {
            print(e);
            return null;
          }
        }
      }
    } catch (e) {
      print(e);
    }
    return null;
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
      totalAmount: AppUtils.stakingPoints,
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
    print("Game created:: ${gameSession.sessionId}");
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
          _fireStoreInstance.collection('temp').doc(_profile!.uid);
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
      print("Error :: $e ${FirebaseAuth.instance.currentUser?.uid}mm");
      print("Stack Trace :: $stackTrace");
      return DateTime.timestamp().toUtc();
    }
  }
}
