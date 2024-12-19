import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/phrase_dialog_bloc.dart';
import 'widgets/confirm_phrase_page.dart';
import 'widgets/secure_wallet_page.dart';

class PhraseDialog extends StatelessWidget {
  const PhraseDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PageController();
    final PhraseDialogBloc phraseDialogBloc = BlocProvider.of<PhraseDialogBloc>(
      context,
      listen: false,
    );
    debugPrint("State updated");
    return PopScope(
      canPop: false,
      child: Card(
        color: const Color(0xff000000),
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 20.0,
            horizontal: 20.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPaginationSteps(
                phraseDialogBloc,
              ),
              const SizedBox(
                height: 20,
              ),
              Expanded(
                child: PageView(
                  allowImplicitScrolling: false,
                  physics: const NeverScrollableScrollPhysics(),
                  controller: controller,
                  onPageChanged: (index) => phraseDialogBloc.add(
                    OnPageChangedEvent(
                      index,
                    ),
                  ),
                  children: [
                    SecureWalletPage(
                      phraseDialogBloc: phraseDialogBloc,
                    ),
                    ConfirmPhrasePage(
                      phraseDialogBloc: phraseDialogBloc,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 5,
              ),
              BlocBuilder<PhraseDialogBloc, PhraseDialogState>(
                buildWhen: (_, current) =>
                    current is PhraseDialogPageChangeState ||
                    current is OnPhrasesFilledState ||
                    current is EnteredPhraseUpdatedState,
                builder: (_, state) {
                  final enteredPhrases = state is EnteredPhraseUpdatedState
                      ? state.updatedData
                      : phraseDialogBloc.enteredWordPhrase;
                  final shouldShow = state is OnPhrasesFilledState
                      ? !state.isValid
                      : (phraseDialogBloc.currentIndex == 1 &&
                              enteredPhrases.every((e) => e.trim().isNotEmpty))
                          ? !phraseDialogBloc.areKeywordsValid
                          : false;
                  if (shouldShow) {
                    return const Text(
                      "Invalid phrase order",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w300,
                        fontSize: 15,
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
              SizedBox(
                height: 7,
              ),
              BlocBuilder<PhraseDialogBloc, PhraseDialogState>(
                buildWhen: (_, current) =>
                    current is PhraseDialogPageChangeState ||
                    current is OnValidateState,
                builder: (_, state) {
                  final currentStep = state is PhraseDialogPageChangeState
                      ? state.index
                      : phraseDialogBloc.currentIndex;
                  final isValid = state is OnValidateState
                      ? state.isValid
                      : phraseDialogBloc.isValid;
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xffFFFFFF).withOpacity(
                        isValid ? 0.9 : 0.5,
                      ),
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isValid
                            ? (currentStep == 0
                                ? () => controller.nextPage(
                                      curve: Curves.easeIn,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                    )
                                : () {
                                    final enteredWords =
                                        phraseDialogBloc.enteredWordPhrase;
                                    final originalWords =
                                        phraseDialogBloc.wordPhrase;
                                    if (phraseDialogBloc.areKeywordsValid &&
                                        (originalWords?.length ?? 0) > 0 &&
                                        enteredWords.every(
                                          (e) => e.trim().isNotEmpty,
                                        ) &&
                                        listEquals(
                                          enteredWords,
                                          originalWords,
                                        )) {
                                      Navigator.pop(context, enteredWords);
                                    }
                                  })
                            : null,
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5.0,
                            vertical: 10,
                          ),
                          child: Center(
                            child: Text(
                              currentStep == 0 ? 'Continue' : 'Complete Backup',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xff000000).withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationSteps(
    PhraseDialogBloc phraseDialogBloc,
  ) {
    return BlocBuilder<PhraseDialogBloc, PhraseDialogState>(
      buildWhen: (_, current) =>
          current is PhraseDialogPageChangeState ||
          current is OnPhrasesFilledState,
      builder: (_, state) {
        final currentStep = state is PhraseDialogPageChangeState
            ? state.index
            : phraseDialogBloc.currentIndex;
        final isFirstStep = currentStep == 0;
        final isSecondStep = currentStep == 1;
        final areAllKeywordsValid = isSecondStep &&
            (state is OnPhrasesFilledState
                ? state.isValid
                : phraseDialogBloc.areKeywordsValid);
        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 50,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 22,
                width: 22,
                decoration: BoxDecoration(
                  color: isSecondStep ? Colors.lightBlue : null,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.lightBlue,
                  ),
                ),
                child: const Center(
                  child: Text(
                    "1",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: isSecondStep
                      ? Colors.lightBlue
                      : const Color(0xffFFFFFF).withOpacity(0.7),
                ),
              ),
              Container(
                height: 22,
                width: 22,
                decoration: BoxDecoration(
                  color: areAllKeywordsValid ? Colors.lightBlue : null,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSecondStep
                        ? Colors.lightBlue
                        : const Color(0xffFFFFFF).withOpacity(0.7),
                  ),
                ),
                child: Center(
                  child: areAllKeywordsValid
                      ? const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "2",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
