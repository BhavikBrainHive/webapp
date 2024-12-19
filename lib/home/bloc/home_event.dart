abstract class HomeEvent {}

class HomeInitialEvent extends HomeEvent {}

class HomeStartGameEvent extends HomeEvent {}

class CreateLSAEvent extends HomeEvent {}

class SecureWalletEvent extends HomeEvent {
  final String wordPhrases;

  SecureWalletEvent(this.wordPhrases);
}
