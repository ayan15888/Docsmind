import 'dart:io';
import 'package:flutter/material.dart';

/// Unified Material Design 3 Document Card supporting Grid and List layouts.
///
/// Features:
/// - Uses M3 `Card.outlined` with tonal background and theme outline
/// - M3 typography from `Theme.of(context).textTheme`
/// - M3 ColorScheme mapping with zero hardcoded colors
/// - Semantics labels for screen readers and accessibility
/// - 48x48dp touch targets on interactive elements
class DocumentCard extends StatelessWidget {
  final String filePath;
  final int index;
  final bool isGrid;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const DocumentCard({
    super.key,
    required this.filePath,
    required this.index,
    required this.isGrid,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final filename = filePath.split(Platform.pathSeparator).last;
    final isPdf = filename.toLowerCase().endsWith('.pdf');
    final docTitle = 'Document ${index + 1}';

    final badgeBg = isPdf
        ? colorScheme.errorContainer
        : colorScheme.secondaryContainer;
    final badgeFg = isPdf
        ? colorScheme.onErrorContainer
        : colorScheme.onSecondaryContainer;

    final thumbnail = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: isPdf
          ? Container(
              color: colorScheme.surfaceContainerHigh,
              alignment: Alignment.center,
              child: Icon(
                Icons.picture_as_pdf_rounded,
                size: isGrid ? 36 : 24,
                color: colorScheme.error,
              ),
            )
          : Image.file(
              File(filePath),
              fit: BoxFit.cover,
              key: ValueKey('${filePath}_thumb'),
              errorBuilder: (_, __, ___) => Container(
                color: colorScheme.surfaceContainerHigh,
                alignment: Alignment.center,
                child: Icon(
                  Icons.description_rounded,
                  size: isGrid ? 36 : 24,
                  color: colorScheme.primary,
                ),
              ),
            ),
    );

    // ── M3 List Layout ──
    if (!isGrid) {
      return Semantics(
        button: true,
        label: '$docTitle, $filename, format ${isPdf ? 'PDF' : 'JPG'}',
        child: Card.outlined(
          margin: EdgeInsets.zero,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            onTap: onTap,
            leading: SizedBox(
              width: 48,
              height: 48,
              child: thumbnail,
            ),
            title: Text(
              docTitle,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 6, top: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPdf ? 'PDF' : 'JPG',
                    style: textTheme.labelSmall?.copyWith(
                      color: badgeFg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    filename,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'Document options',
              color: colorScheme.onSurfaceVariant,
              onPressed: onMoreTap,
            ),
          ),
        ),
      );
    }

    // ── M3 Grid Layout ──
    return Semantics(
      button: true,
      label: '$docTitle, $filename, format ${isPdf ? 'PDF' : 'JPG'}',
      child: Card.outlined(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    thumbnail,
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPdf ? 'PDF' : 'JPG',
                          style: textTheme.labelSmall?.copyWith(
                            color: badgeFg,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            docTitle,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            filename,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                      tooltip: 'Document options',
                      color: colorScheme.onSurfaceVariant,
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                      onPressed: onMoreTap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
