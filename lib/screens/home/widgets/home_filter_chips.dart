import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsmind/core/widgets/app_chip_row.dart';
import 'package:docsmind/screens/home/home_providers.dart';

/// Material Design 3 Filter Chips Row for HomeScreen.
class HomeFilterChips extends ConsumerWidget {
  const HomeFilterChips({super.key});

  static const _filters = ['All', 'PDF', 'Images'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(selectedDocumentFilterProvider);

    return SliverToBoxAdapter(
      child: AppChipRow(
        items: _filters,
        selectedItem: activeFilter,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        onSelected: (selected) {
          ref.read(selectedDocumentFilterProvider.notifier).state = selected;
        },
      ),
    );
  }
}
