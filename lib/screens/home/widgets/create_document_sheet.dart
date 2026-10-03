import 'package:flutter/material.dart';
import 'package:docsmind/core/haptics.dart';
import 'package:docsmind/core/widgets/app_bottom_sheet.dart';

/// Material Design 3 Create or Import Document Bottom Sheet.
void showCreateDocumentSheet({
  required BuildContext context,
  required VoidCallback onScan,
  required VoidCallback onImportGallery,
}) {
  AppHaptics.mediumImpact();
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;

  AppBottomSheet.show(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Create or Import',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.document_scanner_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              title: Text(
                'Scan document',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Scan camera pages with auto edge detection',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onScan();
              },
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.photo_library_outlined,
                  color: colorScheme.onSecondaryContainer,
                  size: 22,
                ),
              ),
              title: Text(
                'Import from gallery',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Choose photo from device storage',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onImportGallery();
              },
            ),
          ],
        ),
      ),
    ),
  );
}
