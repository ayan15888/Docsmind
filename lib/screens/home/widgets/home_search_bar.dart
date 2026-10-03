import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsmind/constants/app_constants.dart';
import 'package:docsmind/core/haptics.dart';
import 'package:docsmind/screens/home/home_providers.dart';

/// Material Design 3 SearchBar placed within the HomeScreen AppBar.
///
/// Implements:
/// - Native M3 `SearchBar` with leading search icon, clear button, and settings action
/// - Complete theme binding via `Theme.of(context).colorScheme` and `textTheme`
/// - 48x48dp minimum touch targets and accessibility semantics
class HomeSearchBar extends ConsumerWidget {
  final TextEditingController searchController;

  const HomeSearchBar({
    super.key,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final searchQuery = ref.watch(documentSearchQueryProvider);

    return Semantics(
      label: 'Search documents',
      textField: true,
      child: SearchBar(
        controller: searchController,
        hintText: AppStrings.searchPrompt,
        constraints: const BoxConstraints(minHeight: 64, maxHeight: 64),
        hintStyle: WidgetStatePropertyAll(
          textTheme.bodyLarge?.copyWith(
            fontSize: 18,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: -0.2,
          ),
        ),
        textStyle: WidgetStatePropertyAll(
          textTheme.bodyLarge?.copyWith(
            fontSize: 18,
            color: colorScheme.onSurface,
            letterSpacing: -0.2,
          ),
        ),
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(
          colorScheme.surfaceContainerHigh,
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, right: 4),
          child: Icon(
            Icons.search_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ),
        trailing: [
          if (searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded, size: 20),
              tooltip: 'Clear search',
              color: colorScheme.onSurfaceVariant,
              onPressed: () {
                searchController.clear();
                ref.read(documentSearchQueryProvider.notifier).state = '';
              },
            ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 20),
            tooltip: 'Settings',
            color: colorScheme.primary,
            onPressed: () {
              AppHaptics.selectionClick();
              ref.read(homeTabIndexProvider.notifier).state = 2;
            },
          ),
        ],
        onChanged: (val) {
          ref.read(documentSearchQueryProvider.notifier).state = val;
        },
      ),
    );
  }
}

/// Header for "Recent Scans" and Grid/List view toggle in HomeScreen.
class HomeViewToggleHeader extends ConsumerWidget {
  const HomeViewToggleHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isGridView = ref.watch(isGridViewProvider);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Scans',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Semantics(
              label: 'Switch between grid and list view',
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.grid_view_rounded, size: 18),
                    tooltip: 'Grid view',
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.view_agenda_outlined, size: 18),
                    tooltip: 'List view',
                  ),
                ],
                selected: {isGridView},
                onSelectionChanged: (newSelection) {
                  AppHaptics.selectionClick();
                  ref.read(isGridViewProvider.notifier).state =
                      newSelection.first;
                },
                showSelectedIcon: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
