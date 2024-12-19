import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/word_phrase_response.dart';

part 'phrase_dialog_event.dart';

part 'phrase_dialog_state.dart';

class PhraseDialogBloc extends Bloc<PhraseDialogEvent, PhraseDialogState> {
  int _currentPage = 0;
  List<String>? _wordPhrase, _shuffledWords;
  List<String> _enteredWordPhrase = List.generate(12, (i) => '');
  bool _isValid = false;
  bool _isPhraseVisible = false;
  bool _areKeywordsValid = false;
  int _selectedPhraseBoxIndex = 1;

  int get currentIndex => _currentPage;

  int get selectedPhraseBoxIndex => _selectedPhraseBoxIndex;

  List<String>? get wordPhrase => _wordPhrase;

  List<String>? get shuffledWords => _shuffledWords;

  List<String> get enteredWordPhrase => _enteredWordPhrase;

  bool get isValid => _isValid;

  bool get areKeywordsValid => _areKeywordsValid;

  bool get isPhraseVisible => _isPhraseVisible;

  PhraseDialogBloc() : super(PhraseDialogInitialState()) {
    on<PhraseDialogInitialEvent>(_onInitialEvent);
    on<OnPageChangedEvent>(_onPageChange);
    on<SelectWordPhraseEvent>(_onPhraseSelect);
    on<SelectPhraseBoxEvent>(_onSelectPhraseBoxChange);
    on<PhraseDialogVisibilityChangeEvent>(_onPhraseVisibilityChange);
    on<PhraseDialogValidateEvent>(_onValidate);
    on<CompleteBackupEvent>(_onCompleteBackUp);
    add(PhraseDialogInitialEvent());
  }

  Future<void> _onInitialEvent(
    PhraseDialogInitialEvent event,
    Emitter<PhraseDialogState> emit,
  ) async {
    _enteredWordPhrase = List.generate(12, (i) => '');
    emit(PhraseDialogPageChangeState(_currentPage));
    add(PhraseDialogValidateEvent());
    await _fetchPhraseKeywords(emit);
  }

  void _onPhraseVisibilityChange(
    PhraseDialogVisibilityChangeEvent event,
    Emitter<PhraseDialogState> emit,
  ) {
    _isPhraseVisible = event.isVisible;
    emit(
      PhraseVisibilityChangedState(
        _isPhraseVisible,
      ),
    );
  }

  void _onCompleteBackUp(
    CompleteBackupEvent event,
    Emitter<PhraseDialogState> emit,
  ) {
    if (_areKeywordsValid) {}
  }

  void _onPhraseSelect(
    SelectWordPhraseEvent event,
    Emitter<PhraseDialogState> emit,
  ) {
    final selectedPhrase = _shuffledWords![event.phraseIndex];
    int indexToUpdate = 1;
    if (_selectedPhraseBoxIndex > 0) {
      indexToUpdate = _selectedPhraseBoxIndex - 1;
    }
    if (indexToUpdate < _enteredWordPhrase.length) {
      _enteredWordPhrase[indexToUpdate] = selectedPhrase;
      final nextNearestIndex =
          _enteredWordPhrase.indexWhere((e) => e.trim().isEmpty);
      // final nextNearestIndex = _selectedPhraseBoxIndex + 1;
      if (nextNearestIndex != (-1)) {
        add(SelectPhraseBoxEvent(nextNearestIndex + 1));
      }
      emit(
        EnteredPhraseUpdatedState(
          _enteredWordPhrase,
        ),
      );
    }
    if (_enteredWordPhrase.every((e) => e.trim().isNotEmpty)) {
      add(PhraseDialogValidateEvent());
    }
  }

  void _onSelectPhraseBoxChange(
    SelectPhraseBoxEvent event,
    Emitter<PhraseDialogState> emit,
  ) {
    if (_selectedPhraseBoxIndex != event.index) {
      _selectedPhraseBoxIndex = event.index;
      emit(
        PhraseBoxSelectedChangeState(
          _selectedPhraseBoxIndex,
        ),
      );
    }
  }

  void _shufflePhraseSection(
    Emitter<PhraseDialogState> emit,
  ) {
    _shuffledWords = List<String>.from(_wordPhrase!);
    _shuffledWords!.shuffle(Random());
    emit(AllPhraseSectionUpdatedState(_shuffledWords!));
  }

  void _onValidate(
    PhraseDialogValidateEvent event,
    Emitter<PhraseDialogState> emit,
  ) {
    _areKeywordsValid = _enteredWordPhrase.length == 12 &&
        _enteredWordPhrase.every((e) => e.trim().isNotEmpty) &&
        (_wordPhrase?.length ?? 0) > 0 &&
        listEquals(_enteredWordPhrase, _wordPhrase);
    _isValid = _currentPage == 0
        ? _wordPhrase?.length == 12
        : _currentPage == 1
            ? _areKeywordsValid
            : false;
    emit(OnValidateState(_isValid));
    if (_currentPage == 1 &&
        _enteredWordPhrase.every((e) => e.trim().isNotEmpty)) {
      emit(OnPhrasesFilledState(_areKeywordsValid));
    }
  }

  void _onPageChange(
    OnPageChangedEvent event,
    Emitter<PhraseDialogState> emit,
  ) {
    if (_currentPage != event.page) {
      _currentPage = event.page;
      emit(PhraseDialogPageChangeState(_currentPage));
      if (_currentPage == 1) {
        _enteredWordPhrase = List.generate(12, (i) => '');
        emit(
          EnteredPhraseUpdatedState(
            _enteredWordPhrase,
          ),
        );
        add(SelectPhraseBoxEvent(1));
        _shufflePhraseSection(emit);
      }
      add(PhraseDialogValidateEvent());
    }
  }

  Future<void> _fetchPhraseKeywords(
    Emitter<PhraseDialogState> emit,
  ) async {
    emit(PhraseLoadingState());
    final dio = Dio();
    final response = await dio.get(
      'https://9dqjv3i89f.execute-api.ap-south-1.amazonaws.com/default/twelfront',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
      ),
      data: {
        "valid": "yes",
      },
    );
    debugPrint(response.toString());
    if (response.statusCode == 200 && response.data != null) {
      try {
        final parsedResponse = WordPhraseResponse.fromJson(
          response.data,
        );
        final splittedString = parsedResponse.words;
        if (splittedString?.length == 12) {
          _wordPhrase = splittedString;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    emit(
      PhraseLoadingState(
        isLoading: false,
      ),
    );
    add(
      PhraseDialogVisibilityChangeEvent(
        _isPhraseVisible,
      ),
    );
    add(PhraseDialogValidateEvent());
  }
}
