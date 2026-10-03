import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:docsmind/core/haptics.dart';
import 'package:docsmind/core/widgets/app_bottom_sheet.dart';

/// Material Design 3 Document Options Modal & Confirmation Dialog.
void showDocumentOptionsSheet({
  required BuildContext context,
  required String path,
  required int index,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  AppHaptics.selectionClick();
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;
  final filename = path.split(Platform.pathSeparator).last;
  final docTitle = 'Document ${index + 1}';

  AppBottomSheet.show(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isPdf
                    ? Container(
                        width: 48,
                        height: 48,
                        color: colorScheme.errorContainer,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          color: colorScheme.onErrorContainer,
                        ),
                      )
                    : Image.file(
                        File(path),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 48,
                          height: 48,
                          color: colorScheme.surfaceContainerHigh,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.description_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
              ),
              title: Text(
                docTitle,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                filename,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 16),
            if (!isPdf)
              ListTile(
                leading: Icon(Icons.edit_outlined, color: colorScheme.primary),
                title: Text(
                  'Open & Edit Filters / OCR',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onEdit();
                },
              ),
            ListTile(
              leading: Icon(Icons.share_outlined, color: colorScheme.onSurfaceVariant),
              title: Text(
                'Share document',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Share.shareXFiles([XFile(path)], text: 'Scanned with DocsMind');
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded,
                  color: colorScheme.error),
              title: Text(
                'Delete',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteDialog(context, onDelete);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

void _showDeleteDialog(BuildContext context, VoidCallback onDelete) {
  final colorScheme = Theme.of(context).colorScheme;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Document'),
      content: const Text(
          'Are you sure you want to delete this document? This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
          ),
          onPressed: () {
            Navigator.pop(ctx);
            onDelete();
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
