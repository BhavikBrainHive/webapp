part of 'phrase_dialog_bloc.dart';

abstract class PhraseDialogState {}

class PhraseDialogInitialState extends PhraseDialogState {}

class PhraseLoadingState extends PhraseDialogState {
  final bool isLoading;

  PhraseLoadingState({
    this.isLoading = true,
  });
}

class PhraseVisibilityChangedState extends PhraseDialogState {
  final bool isVisible;

  PhraseVisibilityChangedState(
    this.isVisible,
  );
}

class OnValidateState extends PhraseDialogState {
  final bool isValid;

  OnValidateState(
    this.isValid,
  );
}

class OnPhrasesFilledState extends PhraseDialogState {
  final bool isValid;

  OnPhrasesFilledState(
    this.isValid,
  );
}

class PhraseDialogPageChangeState extends PhraseDialogState {
  final int index;

  PhraseDialogPageChangeState(
    this.index,
  );
}

class PhraseBoxSelectedChangeState extends PhraseDialogState {
  final int index;

  PhraseBoxSelectedChangeState(
    this.index,
  );
}

class EnteredPhraseUpdatedState extends PhraseDialogState {
  final List<String> updatedData;

  EnteredPhraseUpdatedState(
    this.updatedData,
  );
}

class AllPhraseSectionUpdatedState extends PhraseDialogState {
  final List<String> updatedData;

  AllPhraseSectionUpdatedState(
    this.updatedData,
  );
}
