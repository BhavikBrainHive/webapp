import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/phrase_dialog_bloc.dart';

class ConfirmPhrasePage extends StatelessWidget {
  final PhraseDialogBloc phraseDialogBloc;

  const ConfirmPhrasePage({
    super.key,
    required this.phraseDialogBloc,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhraseDialogBloc, PhraseDialogState>(
      buildWhen: (_, current) =>
          current is EnteredPhraseUpdatedState ||
          current is AllPhraseSectionUpdatedState ||
          current is PhraseBoxSelectedChangeState,
      builder: (_, state) {
        final selectedPhraseBoxIndex = state is PhraseBoxSelectedChangeState
            ? state.index
            : phraseDialogBloc.selectedPhraseBoxIndex;
        final wordPhrases = state is EnteredPhraseUpdatedState
            ? state.updatedData
            : phraseDialogBloc.enteredWordPhrase;
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
                'Confirm seed phrase',
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
                  "Select each word in the order it was presented to you.",
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 17,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GridView.builder(
                  itemCount: reorderedItems.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnCount,
                    crossAxisSpacing: 13,
                    mainAxisSpacing: 13,
                    childAspectRatio: 3.8,
                  ),
                  itemBuilder: (context, index) {
                    final currentItem = reorderedItems[index];
                    final currentIndex = currentItem.key;
                    final isSelected =
                        selectedPhraseBoxIndex == currentItem.key;
                    return Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${currentIndex <= 9 ? '  $currentIndex' : '$currentIndex'}.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: CustomPaint(
                            painter: RoundedDottedBorderPainter(
                              dashWidth: 6,
                              dashSpace: 4,
                              borderRadius: 30,
                              color: (isSelected ||
                                      currentItem.value.trim().isNotEmpty)
                                  ? Colors.blue
                                  : Colors.white.withOpacity(0.5),
                              dashThickness: 0.7,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => phraseDialogBloc.add(
                                  SelectPhraseBoxEvent(
                                    reorderedItems[index].key,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(
                                  30,
                                ),
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.grey.withOpacity(0.3)
                                        : null,
                                    borderRadius: BorderRadius.circular(
                                      30,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      currentItem.value,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: BlocBuilder<PhraseDialogBloc, PhraseDialogState>(
                  buildWhen: (_, current) =>
                      current is AllPhraseSectionUpdatedState ||
                      current is EnteredPhraseUpdatedState,
                  builder: (_, state) {
                    final shuffledPhrases =
                        state is AllPhraseSectionUpdatedState
                            ? state.updatedData
                            : (phraseDialogBloc.shuffledWords ?? []);
                    final enteredPhrases = state is EnteredPhraseUpdatedState
                        ? state.updatedData
                        : phraseDialogBloc.enteredWordPhrase;
                    return GridView.builder(
                      itemCount: shuffledPhrases.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 3.5,
                      ),
                      itemBuilder: (context, index) {
                        final currentItem = shuffledPhrases[index];
                        return OutlinedButton(
                          onPressed: () => phraseDialogBloc.add(
                            SelectWordPhraseEvent(
                              index,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: enteredPhrases.contains(currentItem)
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            currentItem,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Function to rearrange items into a vertical-first order
  List<MapEntry<int, String>> getVerticalFirstOrder(
    List<String>? items,
    int columnCount,
  ) {
    if (items != null) {
      int rowCount = (items.length / columnCount).ceil();
      List<MapEntry<int, String>> reordered = [];

      for (int row = 0; row < rowCount; row++) {
        for (int col = 0; col < columnCount; col++) {
          int index = row + (col * rowCount); // Calculate vertical-first index
          if (index < items.length) {
            reordered.add(MapEntry(index + 1, items[index]));
          }
        }
      }
      return reordered;
    }
    return [];
  }
}

class RoundedDottedBorderPainter extends CustomPainter {
  final double dashWidth;
  final double dashSpace;
  final double dashThickness;
  final double borderRadius;
  final Color color;

  RoundedDottedBorderPainter({
    required this.dashWidth,
    required this.dashSpace,
    required this.dashThickness,
    required this.borderRadius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = dashThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Create a path for the rounded rectangle
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    // Convert path to dashed
    final path = Path();
    path.addRRect(rect);

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    // Get path metrics
    final pathMetrics = path.computeMetrics();
    for (ui.PathMetric metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = metric.length;
        final extractedPath = metric.extractPath(
          distance,
          distance + dashWidth > length ? length : distance + dashWidth,
        );
        canvas.drawPath(extractedPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant RoundedDottedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.dashThickness != dashThickness;
  }
}
