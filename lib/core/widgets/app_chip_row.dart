import 'package:flutter/material.dart';
import 'package:docsmind/core/haptics.dart';

/// Material Design 3 Filter / Choice Chip Row with 8dp grid spacing.
class AppChipRow extends StatelessWidget {
  final List<String> items;
  final String selectedItem;
  final ValueChanged<String> onSelected;
  final EdgeInsetsGeometry padding;

  const AppChipRow({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: items.map((item) {
          final isSelected = item == selectedItem;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: 'Filter by $item',
              child: FilterChip(
                selected: isSelected,
                showCheckmark: false,
                label: Text(item),
                labelStyle: textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                ),
                backgroundColor: colorScheme.surfaceContainer,
                selectedColor: colorScheme.primaryContainer,
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : colorScheme.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                visualDensity: const VisualDensity(horizontal: 1, vertical: 0),
                onSelected: (_) {
                  AppHaptics.selectionClick();
                  onSelected(item);
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
