import 'package:flutter/material.dart';
import 'package:docsmind/features/settings/screens/settings_bottom_sheet.dart';

class SettingsService {
  static void showSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const SettingsBottomSheet(),
    );
  }
}
