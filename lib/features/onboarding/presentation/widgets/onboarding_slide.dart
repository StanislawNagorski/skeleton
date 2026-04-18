import 'package:flutter/material.dart';
import 'package:skeleton/core/extensions/context_extension.dart';
import 'package:skeleton/core/presentation/app_dimensions.dart';

/// A single onboarding slide with image, title, and subtitle.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String imagePath;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingExtraLarge,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppDimensions.spacingXXL),
            Image.asset(
              imagePath,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppDimensions.spacingLarge),
            Text(
              title,
              style: context.theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            Text(
              subtitle,
              style: context.theme.textTheme.bodyLarge?.copyWith(
                color: context.theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
