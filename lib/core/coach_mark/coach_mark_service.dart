import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'package:skeleton/core/preferences/preferences_service.dart';
import 'package:skeleton/core/presentation/app_dimensions.dart';

/// Wrapper over `tutorial_coach_mark` for first-visit feature tours.
///
/// Usage:
/// 1. Register targets: `coachMarkService.register('home', fabKey, 'Tap to increment')`
/// 2. Show tour: `coachMarkService.showTour('home', context)`
///
/// Tours auto-persist a `tour_{tourId}_seen` flag in `PreferencesService`
/// and never re-show once completed. Per-screen scoping only (D-15).
@lazySingleton
class CoachMarkService {
  CoachMarkService(this._preferencesService);

  final PreferencesService _preferencesService;
  final Map<String, List<_CoachTarget>> _tours = {};

  /// Registers a [key]-attached widget as a coach mark target for [tourId].
  void register(
    String tourId,
    GlobalKey key,
    String description, {
    String? title,
  }) {
    _tours.putIfAbsent(tourId, () => []);
    _tours[tourId]!.add(
      _CoachTarget(key: key, title: title, description: description),
    );
  }

  /// Clears all registered targets for [tourId].
  ///
  /// Call this in dispose to prevent stale references.
  void unregister(String tourId) {
    _tours.remove(tourId);
  }

  /// Shows the tour for [tourId] if it has not been seen before.
  ///
  /// Wraps the display in [addPostFrameCallback] to ensure all
  /// target widgets have been laid out (Pitfall 3).
  Future<void> showTour(String tourId, BuildContext context) async {
    final prefKey = 'tour_${tourId}_seen';
    final seen = await _preferencesService.getBool(prefKey);
    if (seen == true) return;

    final targets = _tours[tourId];
    if (targets == null || targets.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      TutorialCoachMark(
        targets: targets
            .map(
              (t) => TargetFocus(
                keyTarget: t.key,
                shape: ShapeLightFocus.RRect,
                radius: AppDimensions.radiusMedium,
                paddingFocus: AppDimensions.radiusMedium,
                contents: [
                  TargetContent(
                    align: ContentAlign.bottom,
                    builder: (context, controller) => Container(
                      padding: const EdgeInsets.all(
                        AppDimensions.spacingBase,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMedium,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (t.title != null)
                            Text(
                              t.title!,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                            ),
                          if (t.title != null)
                            const SizedBox(
                              height: AppDimensions.spacingSmall,
                            ),
                          Text(
                            t.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
        colorShadow: Colors.black,
        opacityShadow: 0.7,
        onFinish: () {
          // ignore: discarded_futures
          _preferencesService.setBool(prefKey, value: true);
        },
      ).show(context: context);
    });
  }
}

class _CoachTarget {
  const _CoachTarget({
    required this.key,
    required this.description,
    this.title,
  });

  final GlobalKey key;
  final String? title;
  final String description;
}
