import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:docsmind/core/providers.dart';
import 'package:docsmind/core/haptics.dart';
import 'package:docsmind/core/widgets/app_responsive_scaffold.dart';
import 'package:docsmind/screens/compress_screen.dart';
import 'package:docsmind/screens/settings_screen.dart';
import 'package:docsmind/screens/document_editor_screen.dart';
import 'package:docsmind/screens/home/home_providers.dart';
import 'package:docsmind/screens/home/widgets/document_card.dart';
import 'package:docsmind/screens/home/widgets/home_search_bar.dart';
import 'package:docsmind/screens/home/widgets/home_filter_chips.dart';
import 'package:docsmind/screens/home/widgets/home_empty_state.dart';
import 'package:docsmind/screens/home/widgets/document_options_sheet.dart';
import 'package:docsmind/screens/home/widgets/create_document_sheet.dart';

// Re-export providers for any external listeners
export 'package:docsmind/screens/home/home_providers.dart';

// ── HomeScreen Shell with M3 Responsive Navigation ─────────────────────────
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabIndexProvider);

    final screens = const [
      _DocumentsTab(),
      CompressScreen(),
      SettingsScreen(),
    ];

    const destinations = [
      AppNavDestination(
        icon: Icon(Icons.folder_outlined),
        selectedIcon: Icon(Icons.folder_rounded),
        label: 'Documents',
      ),
      AppNavDestination(
        icon: Icon(Icons.compress_outlined),
        selectedIcon: Icon(Icons.compress_rounded),
        label: 'Compress',
      ),
      AppNavDestination(
        icon: Icon(Icons.tune_outlined),
        selectedIcon: Icon(Icons.tune_rounded),
        label: 'Settings',
      ),
    ];

    return AppResponsiveScaffold(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) {
        AppHaptics.selectionClick();
        ref.read(homeTabIndexProvider.notifier).state = i;
      },
      destinations: destinations,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: screens[currentIndex],
      ),
    );
  }
}

// ── Documents Tab ───────────────────────────────────────────────────────────
class _DocumentsTab extends ConsumerStatefulWidget {
  const _DocumentsTab();

  @override
  ConsumerState<_DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends ConsumerState<_DocumentsTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> _showSaveFormatDialog(int pageCount) async {
    AppHaptics.selectionClick();
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final textTheme = Theme.of(ctx).textTheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Save Scan As',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose format for $pageCount ${pageCount == 1 ? 'scanned page' : 'scanned pages'}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Card.outlined(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.picture_as_pdf_rounded,
                            color: colorScheme.onPrimaryContainer,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          'PDF Document (.pdf)',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          pageCount > 1
                              ? 'Combine $pageCount pages into a single PDF document'
                              : 'Standard single-page PDF document',
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
                          Navigator.pop(ctx, 'pdf');
                        },
                      ),
                      const Divider(height: 1, indent: 64),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.image_outlined,
                            color: colorScheme.onSecondaryContainer,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          'JPG Image (.jpg)',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          pageCount > 1
                              ? 'Save as $pageCount individual image files'
                              : 'Standard JPG photo format',
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
                          Navigator.pop(ctx, 'jpg');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _scanWithAutoScanner() async {
    try {
      AppHaptics.heavyImpact();
      final scannerService = ref.read(documentScannerProvider);
      final images = await scannerService.scanWithMLKit(pageLimit: 10);
      if (images.isNotEmpty && mounted) {
        final chosenFormat = await _showSaveFormatDialog(images.length);
        if (chosenFormat == null || !mounted) return;

        if (chosenFormat == 'pdf') {
          AppHaptics.heavyImpact();
          final pdfPath = await scannerService.buildPdfFromImages(images);
          if (pdfPath != null && mounted) {
            final docs = ref.read(documentsProvider);
            ref.read(documentsProvider.notifier).state = [...docs, pdfPath];
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Saved as PDF (${images.length} ${images.length == 1 ? 'page' : 'pages'})',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          AppHaptics.heavyImpact();
          final docs = ref.read(documentsProvider);
          ref.read(documentsProvider.notifier).state = [...docs, ...images];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Saved as JPG (${images.length} ${images.length == 1 ? 'image' : 'images'})',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          if (mounted) {
            _openEditor(images.last);
          }
        }
      }
    } catch (e) {
      debugPrint('MLKit scan error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      AppHaptics.lightImpact();
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null && mounted) {
        final chosenFormat = await _showSaveFormatDialog(1);
        if (chosenFormat == null || !mounted) return;

        if (chosenFormat == 'pdf') {
          final scannerService = ref.read(documentScannerProvider);
          final pdfPath = await scannerService.buildPdfFromImages([picked.path]);
          if (pdfPath != null && mounted) {
            final docs = ref.read(documentsProvider);
            ref.read(documentsProvider.notifier).state = [...docs, pdfPath];
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Saved as PDF document'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          final docs = ref.read(documentsProvider);
          ref.read(documentsProvider.notifier).state = [...docs, picked.path];
          if (mounted) {
            _openEditor(picked.path);
          }
        }
      }
    } catch (e) {
      debugPrint('Gallery pick error: $e');
    }
  }

  Future<void> _openEditor(String path) async {
    final isPdf = path.toLowerCase().endsWith('.pdf');
    if (isPdf) {
      final docs = ref.read(documentsProvider);
      final idx = docs.indexOf(path);
      showDocumentOptionsSheet(
        context: context,
        path: path,
        index: idx >= 0 ? idx : 0,
        onEdit: () {},
        onDelete: () => _deleteDocument(path),
      );
      return;
    }

    final didUpdate = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentEditorScreen(imagePath: path),
      ),
    );
    if (didUpdate == true && mounted) {
      PaintingBinding.instance.imageCache.evict(FileImage(File(path)));
      ref.read(documentsProvider.notifier).state = [
        ...ref.read(documentsProvider)
      ];
    }
  }

  void _deleteDocument(String path) {
    final docs = List<String>.from(ref.read(documentsProvider))..remove(path);
    ref.read(documentsProvider.notifier).state = docs;
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
    AppHaptics.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final documents = ref.watch(documentsProvider);
    final isGridView = ref.watch(isGridViewProvider);
    final activeFilter = ref.watch(selectedDocumentFilterProvider);
    final searchQuery = ref.watch(documentSearchQueryProvider);

    final filteredDocuments = documents.where((docPath) {
      final name = docPath.split(Platform.pathSeparator).last.toLowerCase();
      final isPdf = name.endsWith('.pdf');
      if (activeFilter == 'PDF' && !isPdf) return false;
      if (activeFilter == 'Images' && isPdf) return false;
      if (searchQuery.isNotEmpty && !name.contains(searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // ── Non-sticky App Bar with Search Bar ──
          SliverAppBar(
            pinned: false,
            floating: false,
            toolbarHeight: 80,
            titleSpacing: 16,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: colorScheme.surface,
            automaticallyImplyLeading: false,
            title: HomeSearchBar(searchController: _searchController),
          ),

          // ── Recent Scans Header & View Toggle ──
          const HomeViewToggleHeader(),

          // ── Filter Chips ──
          const HomeFilterChips(),

            // ── Empty State View ──
            if (filteredDocuments.isEmpty)
              HomeEmptyState(isSearchEmpty: searchQuery.isNotEmpty)

            // ── Grid View ──
            else if (isGridView)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.74,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => DocumentCard(
                      filePath: filteredDocuments[i],
                      index: i,
                      isGrid: true,
                      onTap: () => _openEditor(filteredDocuments[i]),
                      onMoreTap: () => showDocumentOptionsSheet(
                        context: context,
                        path: filteredDocuments[i],
                        index: i,
                        onEdit: () => _openEditor(filteredDocuments[i]),
                        onDelete: () => _deleteDocument(filteredDocuments[i]),
                      ),
                    ),
                    childCount: filteredDocuments.length,
                  ),
                ),
              )

            // ── List View ──
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DocumentCard(
                        filePath: filteredDocuments[i],
                        index: i,
                        isGrid: false,
                        onTap: () => _openEditor(filteredDocuments[i]),
                        onMoreTap: () => showDocumentOptionsSheet(
                          context: context,
                          path: filteredDocuments[i],
                          index: i,
                          onEdit: () => _openEditor(filteredDocuments[i]),
                          onDelete: () => _deleteDocument(filteredDocuments[i]),
                        ),
                      ),
                    ),
                    childCount: filteredDocuments.length,
                  ),
                ),
              ),
          ],
        ),

      // ── Floating Action Button (M3 Scan Action) ──
      floatingActionButton: Semantics(
        button: true,
        label: 'Scan document, hold for more options',
        child: GestureDetector(
          onLongPress: () => showCreateDocumentSheet(
            context: context,
            onScan: _scanWithAutoScanner,
            onImportGallery: _pickFromGallery,
          ),
          child: FloatingActionButton.extended(
            tooltip: 'Scan document (Hold for options)',
            onPressed: _scanWithAutoScanner,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
            highlightElevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            icon: const Icon(Icons.document_scanner_rounded),
            label: Text(
              'Scan',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
