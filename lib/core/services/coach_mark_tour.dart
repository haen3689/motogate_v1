import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import '../theme/app_colors.dart';

/// Shared building blocks for the app's coach-mark (Showcase) onboarding
/// tours, so each screen doesn't redefine the same Skip / Next / Got-it
/// button styling and first-launch gating logic.
class CoachMarkTour {
  CoachMarkTour._();

  /// Runs [start] once per install, gated by [prefKey] in SharedPreferences.
  static Future<void> maybeStart({
    required String prefKey,
    required VoidCallback start,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(prefKey) == true) return;
    await prefs.setBool(prefKey, true);
    WidgetsBinding.instance.addPostFrameCallback((_) => start());
  }

  /// Default Skip + Next buttons applied globally to every tooltip
  /// (set once on the app's [ShowCaseWidget]).
  static List<TooltipActionButton> get globalActions => [
        TooltipActionButton(
          type: TooltipDefaultActionType.skip,
          name: 'ຂ້າມ',
          backgroundColor: Colors.transparent,
          textStyle: const TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w700),
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          name: 'ຖັດໄປ',
          backgroundColor: AppColors.primary,
          textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ];

  /// Skip + "Got it" buttons for the final step of a tour — dismisses the
  /// tour instead of advancing to a next step that doesn't exist.
  static List<TooltipActionButton> lastStepActions(BuildContext context) => [
        TooltipActionButton(
          type: TooltipDefaultActionType.skip,
          name: 'ຂ້າມ',
          backgroundColor: Colors.transparent,
          textStyle: const TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w700),
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          name: 'ເຂົ້າໃຈແລ້ວ',
          backgroundColor: AppColors.primary,
          textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          onTap: () => ShowCaseWidget.of(context).dismiss(),
        ),
      ];
}
