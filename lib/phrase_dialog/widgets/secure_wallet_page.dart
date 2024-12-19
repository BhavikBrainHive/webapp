import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../bloc/phrase_dialog_bloc.dart';

class SecureWalletPage extends StatelessWidget {
  final PhraseDialogBloc phraseDialogBloc;

  const SecureWalletPage({
    super.key,
    required this.phraseDialogBloc,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhraseDialogBloc, PhraseDialogState>(
      buildWhen: (_, current) =>
          current is PhraseLoadingState ||
          current is PhraseVisibilityChangedState,
      builder: (_, state) {
        final isLoading = state is PhraseLoadingState && state.isLoading;
        final wordPhrases = phraseDialogBloc.wordPhrase;
        const int columnCount = 2;

        // Reorder items to vertical-first order
        final reorderedItems = getVerticalFirstOrder(
          wordPhrases,
          columnCount,
        );
        return SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Write down your Secret \nRecovery Phrase',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                ),
                child: Text(
                  "This is your Secret Recovery Phrase.\nWrite it down on a paper and keep it in a safe place. You\'ll be asked to re-enter this phrase (in order) on next step.",
                  style: TextStyle(
                    fontSize: 15,
                    color: const Color(0xffFFFFFF).withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 700,
                ),
                child: isLoading
                    ? buildShimmerGrid()
                    : BlocBuilder<PhraseDialogBloc, PhraseDialogState>(
                        buildWhen: (_, current) =>
                            current is PhraseVisibilityChangedState,
                        builder: (_, state) {
                          final isVisible =
                              state is PhraseVisibilityChangedState
                                  ? state.isVisible
                                  : phraseDialogBloc.isPhraseVisible;
                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: Stack(
                              children: [
                                GridView.builder(
                                  itemCount: reorderedItems.length,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columnCount,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 3.5,
                                  ),
                                  itemBuilder: (context, index) {
                                    return OutlinedButton(
                                      onPressed: null,
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.blue,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Container(
                                        color: !isVisible ? Colors.white : null,
                                        child: Text(
                                          reorderedItems[index],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (!isVisible)
                                  Positioned.fill(
                                    child: ClipRect(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 10,
                                          sigmaY: 10,
                                        ), // Blur intensity
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            // Transparent white
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color:
                                                  Colors.white.withOpacity(0.3),
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.6),
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(7),
                                                  onTap: () =>
                                                      phraseDialogBloc.add(
                                                    PhraseDialogVisibilityChangeEvent(
                                                      true,
                                                    ),
                                                  ),
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5,
                                                    ),
                                                    child: Text(
                                                      '\u{1F441} Reveal phrase',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (!isLoading && wordPhrases != null)
                const SizedBox(
                  height: 10,
                ),
              if (!isLoading && wordPhrases != null)
                CopyClipboardWidget(
                  wordPhrases: wordPhrases,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget buildShimmerGrid() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        itemCount: 12,
        // Number of placeholder items
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3.5,
        ),
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[700]!,
            highlightColor: Colors.grey[500]!,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: SizedBox(
                  width: 70,
                  height: 15,
                  child: ColoredBox(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Function to rearrange items into a vertical-first order
  List<String> getVerticalFirstOrder(
    List<String>? items,
    int columnCount,
  ) {
    if (items != null) {
      int rowCount = (items.length / columnCount).ceil();
      List<String> reordered = [];

      for (int row = 0; row < rowCount; row++) {
        for (int col = 0; col < columnCount; col++) {
          int index = row + (col * rowCount); // Calculate vertical-first index
          if (index < items.length) {
            reordered.add('${index + 1}. ${items[index]}');
          }
        }
      }
      return reordered;
    }
    return [];
  }
}

class CopyClipboardWidget extends StatefulWidget {
  const CopyClipboardWidget({
    super.key,
    required this.wordPhrases,
  });

  final List<String> wordPhrases;

  @override
  State<CopyClipboardWidget> createState() => _CopyClipboardWidgetState();
}

class _CopyClipboardWidgetState extends State<CopyClipboardWidget> {
  bool isCopied = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
        ),
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: () async {
            final phraseToCopy = widget.wordPhrases.join(', ');
            await Clipboard.setData(ClipboardData(text: phraseToCopy));
            if (!isCopied) {
              setState(() {
                isCopied = true;
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCopied)
                  const Icon(
                    Icons.check,
                    color: Colors.green,
                  ),
                if (isCopied)
                  const SizedBox(
                    width: 3,
                  ),
                Text(
                  isCopied
                      ? 'Copied to clipboard'
                      : '\u{1F4CB}  Copy to clipboard',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
