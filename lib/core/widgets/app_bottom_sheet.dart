import 'package:flutter/material.dart';

/// Reusable Material Design 3 Bottom Sheet helper.
///
/// Complies with M3 bottom sheet specifications:
/// - useSafeArea: true
/// - showDragHandle: true
/// - isScrollControlled: true
/// - top corner radius: 28dp
/// - tonal surfaceContainerLow background
class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    final theme = Theme.of(context);
    return showModalBottomSheet<T>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: builder,
    );
  }
}
