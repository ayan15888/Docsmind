import 'package:flutter/material.dart';

/// Material Design 3 Empty State View for HomeScreen.
class HomeEmptyState extends StatelessWidget {
  final bool isSearchEmpty;

  const HomeEmptyState({
    super.key,
    required this.isSearchEmpty,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSearchEmpty
                      ? Icons.search_off_rounded
                      : Icons.folder_open_rounded,
                  size: 38,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isSearchEmpty ? 'No matching documents' : 'No documents yet',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isSearchEmpty
                    ? 'Try searching with another keyword'
                    : 'Scan documents or import files to get started',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
