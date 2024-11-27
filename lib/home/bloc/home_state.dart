import 'package:webapp/model/game_session.dart';
import 'package:webapp/model/user.dart';

abstract class HomeState {}

class HomeInitialState extends HomeState {}

class ProfileUpdatedState extends HomeState {
  final UserProfile profile;

  ProfileUpdatedState(this.profile);
}

class ProfileLoadingState extends HomeState {
  final bool isLoading;

  ProfileLoadingState({
    this.isLoading = true,
  });
}

class GameSessionFoundState extends HomeState {
  final GameSession gameSession;

  GameSessionFoundState(this.gameSession);
}
