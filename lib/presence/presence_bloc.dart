import 'dart:async';
import 'dart:html' as html;

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'presence_event.dart';
import 'presence_state.dart';

class PresenceBloc extends Bloc<PresenceEvent, PresenceState> {
  final _auth = FirebaseAuth.instance;
  late DocumentReference<Map<String, dynamic>> _userRef;

  PresenceBloc() : super(PresenceInitial()) {
    on<InitializePresence>(_initializePresence);
    on<UpdatePresence>(_updatePresence);
    on<DisablePresence>(_disablePresence);
  }

  Future<void> _initializePresence(
    InitializePresence event,
    Emitter<PresenceState> emit,
  ) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      _userRef = firestore.collection('users').doc(event.userId);

      _auth.authStateChanges().listen((user) {
        print("Auth changed in presence:: ${user?.uid} ${user?.displayName}");
      });

      // Set up online/offline listeners
      html.window.onOnline.listen((_) => add(UpdatePresence(true)));
      html.window.onOffline.listen((_) => add(UpdatePresence(false)));
      html.window.onBeforeUnload.listen((_) => add(UpdatePresence(false)));

      // Set the user online initially
      add(UpdatePresence(true));
    } catch (e) {
      emit(PresenceError(e.toString()));
    }
  }

  Future<void> _updatePresence(
    UpdatePresence event,
    Emitter<PresenceState> emit,
  ) async {
    try {
      await _userRef.set({
        'online': event.isOnline,
      }, SetOptions(merge: true));

      if (event.isOnline) {
        emit(PresenceOnline());
      } else {
        emit(PresenceOffline());
      }
    } catch (e) {
      emit(PresenceError(e.toString()));
    }
  }

  Future<void> _disablePresence(
    DisablePresence event,
    Emitter<PresenceState> emit,
  ) async {
    try {
      await _userRef.set({
        'online': false,
      }, SetOptions(merge: true));
      emit(PresenceOffline());
    } catch (e) {
      emit(PresenceError(e.toString()));
    }
  }
}
