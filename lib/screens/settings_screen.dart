import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:docsmind/core/providers.dart';
import 'package:docsmind/core/haptics.dart';
import 'package:docsmind/core/widgets/app_bottom_sheet.dart';

/// Material Design 3 (Material You) Settings Screen.
///
/// Features:
/// - M3 `SliverAppBar` with responsive typography and Newsreader semi-bold 600 font
/// - Support for System, Light, and Dark theme modes with M3 `RadioListTile` in an `AppBottomSheet`
/// - Dedicated toggle for Pure White Light Mode
/// - Backup / Transfer tool for exporting, saving, or restoring document scans
/// - M3 `Card.outlined` groups with standard `ListTile` and tonal containers
/// - Zero hardcoded colors; all values bound to `Theme.of(context).colorScheme`
/// - Minimum 48x48dp touch targets and accessibility semantics
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
    AppHaptics.selectionClick();
    final themeMode = ref.watch(themeModeProvider);

    AppBottomSheet.show(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final textTheme = Theme.of(ctx).textTheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Choose Theme',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  title: const Text('System default'),
                  subtitle: const Text('Follows system dark/light mode'),
                  secondary: const Icon(Icons.brightness_auto_outlined),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onChanged: (newMode) {
                    if (newMode != null) {
                      AppHaptics.selectionClick();
                      ref.read(themeModeProvider.notifier).state = newMode;
                      Navigator.pop(ctx);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  title: const Text('Light mode'),
                  subtitle: const Text('Always use light theme'),
                  secondary: const Icon(Icons.light_mode_outlined),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onChanged: (newMode) {
                    if (newMode != null) {
                      AppHaptics.selectionClick();
                      ref.read(themeModeProvider.notifier).state = newMode;
                      ref.read(darkModeProvider.notifier).state = false;
                      Navigator.pop(ctx);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  title: const Text('Dark mode'),
                  subtitle: const Text('Always use dark theme'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onChanged: (newMode) {
                    if (newMode != null) {
                      AppHaptics.selectionClick();
                      ref.read(themeModeProvider.notifier).state = newMode;
                      ref.read(darkModeProvider.notifier).state = true;
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBackupTransferSheet(BuildContext context, WidgetRef ref) {
    AppHaptics.lightImpact();
    AppBottomSheet.show(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final textTheme = Theme.of(ctx).textTheme;
        final docs = ref.watch(documentsProvider);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.swap_horiz_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Backup / Transfer',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${docs.length} ${docs.length == 1 ? 'document' : 'documents'} ready',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Share / Direct transfer
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.share_outlined,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Direct Device Transfer / Share',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Transfer scans directly via Quick Share, Nearby, or apps',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (docs.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No scanned documents to transfer yet.'),
                        ),
                      );
                      return;
                    }
                    AppHaptics.selectionClick();
                    final xfiles = docs.map((p) => XFile(p)).toList();
                    await Share.shareXFiles(
                      xfiles,
                      text: 'DocsMind Document Backup',
                    );
                  },
                ),
                const Divider(height: 16),

                // Save to folder
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.folder_zip_outlined,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Export to Local Folder',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Save all document copies to a chosen local directory',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (docs.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No scanned documents to export yet.'),
                        ),
                      );
                      return;
                    }
                    AppHaptics.selectionClick();
                    final selectedDir = await FilePicker.getDirectoryPath(
                      dialogTitle: 'Select Backup Destination Folder',
                    );
                    if (selectedDir != null) {
                      int count = 0;
                      for (int i = 0; i < docs.length; i++) {
                        final file = File(docs[i]);
                        if (await file.exists()) {
                          final ext = docs[i].split('.').last;
                          final name =
                              'docsmind_backup_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.$ext';
                          await file.copy('$selectedDir/$name');
                          count++;
                        }
                      }
                      AppHaptics.heavyImpact();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Successfully exported $count documents to $selectedDir',
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 16),

                // Import / Restore
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.file_download_outlined,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Import & Restore Documents',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Import scanned documents or transfer files from another phone',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    AppHaptics.selectionClick();
                    final result = await FilePicker.pickFiles(
                      allowMultiple: true,
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                      dialogTitle: 'Select Documents to Import',
                    );
                    if (result != null && result.paths.isNotEmpty) {
                      final validPaths =
                          result.paths.whereType<String>().toList();
                      if (validPaths.isNotEmpty) {
                        final current = ref.read(documentsProvider);
                        ref.read(documentsProvider.notifier).state = [
                          ...current,
                          ...validPaths,
                        ];
                        AppHaptics.heavyImpact();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Imported ${validPaths.length} documents successfully!',
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getThemeSubtitle(ThemeMode mode, bool isDarkSystem) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default (${isDarkSystem ? 'Dark' : 'Light'})';
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final currentThemeMode = ref.watch(themeModeProvider);
    final isSystemDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Material 3 Pinned Top App Bar ──
          SliverAppBar(
            toolbarHeight: 96,
            title: Text(
              'Settings',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimary,
                fontSize: 30,
              ),
            ),
            iconTheme: IconThemeData(color: colorScheme.onPrimary),
            pinned: false,
            floating: false,
            centerTitle: false,
            backgroundColor: colorScheme.primary,
            scrolledUnderElevation: 0,
            elevation: 0,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Appearance Section ──
                  const _M3SectionHeader(title: 'Appearance'),
                  Card.outlined(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          currentThemeMode == ThemeMode.dark
                              ? Icons.dark_mode_outlined
                              : (currentThemeMode == ThemeMode.light
                                  ? Icons.light_mode_outlined
                                  : Icons.brightness_auto_outlined),
                          color: colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Theme Mode',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        _getThemeSubtitle(currentThemeMode, isSystemDark),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onTap: () => _showThemeSelector(context, ref),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Backup & Transfer Section ──
                  const _M3SectionHeader(title: 'Backup & Transfer'),
                  Card.outlined(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.backup_outlined,
                          color: colorScheme.onSecondaryContainer,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Backup / Transfer',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Export, backup, or transfer scanned documents to other devices',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onTap: () => _showBackupTransferSheet(context, ref),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Security & Privacy Section ──
                  const _M3SectionHeader(title: 'Privacy & Security'),
                  Card.outlined(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified_user_outlined,
                          color: colorScheme.onSecondaryContainer,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Local Processing Only',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '100% on-device processing. No scans or documents are uploaded to cloud servers.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── About Section ──
                  const _M3SectionHeader(title: 'About'),
                  Card.outlined(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Version',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            'DocsMind Document Scanner',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'v1.0.0',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Open Source Licenses',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            'Third-party software notices and attribution',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onTap: () {
                            AppHaptics.selectionClick();
                            showLicensePage(
                              context: context,
                              applicationName: 'DocsMind',
                              applicationVersion: 'v1.0.0',
                              applicationIcon: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.document_scanner_rounded,
                                  size: 48,
                                  color: colorScheme.primary,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Footer ──
                  Center(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Made with ',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const TextSpan(
                            text: '💖',
                            style: TextStyle(fontSize: 13),
                          ),
                          TextSpan(
                            text: ' by Ayanode',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _M3SectionHeader extends StatelessWidget {
  final String title;

  const _M3SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
