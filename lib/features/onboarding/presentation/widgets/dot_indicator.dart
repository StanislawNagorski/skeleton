import 'package:flutter/material.dart';
import 'package:skeleton/core/presentation/app_dimensions.dart';

/// Animated dot indicator for PageView position.
class DotIndicator extends StatelessWidget {
  const DotIndicator({
    required this.count,
    required this.currentIndex,
    super.key,
  });

  final int count;
  final int currentIndex;

  static const double _dotSize = 8;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingSmall / 2,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == currentIndex
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        ),
      );
}
