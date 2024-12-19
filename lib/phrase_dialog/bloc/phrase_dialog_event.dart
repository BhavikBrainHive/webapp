part of 'phrase_dialog_bloc.dart';

abstract class PhraseDialogEvent {}

class PhraseDialogInitialEvent extends PhraseDialogEvent {}

class PhraseDialogValidateEvent extends PhraseDialogEvent {}

class PhraseDialogVisibilityChangeEvent extends PhraseDialogEvent {
  final bool isVisible;

  PhraseDialogVisibilityChangeEvent(
    this.isVisible,
  );
}

class OnPageChangedEvent extends PhraseDialogEvent {
  final int page;

  OnPageChangedEvent(
    this.page,
  );
}

class SelectPhraseBoxEvent extends PhraseDialogEvent {
  final int index;

  SelectPhraseBoxEvent(
    this.index,
  );
}

class SelectWordPhraseEvent extends PhraseDialogEvent {
  final int phraseIndex;

  SelectWordPhraseEvent(
    this.phraseIndex,
  );
}

class CompleteBackupEvent extends PhraseDialogEvent{

}
