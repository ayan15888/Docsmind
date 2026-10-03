import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:docsmind/constants/app_constants.dart';
import 'package:docsmind/features/document_scanner/services/document_scanner_service.dart';

// ══════════════════════════════════════════════════════
//  OCR Result Bottom Sheet
// ══════════════════════════════════════════════════════

/// Shows a full-featured bottom sheet with selectable, copyable OCR text.
/// Call via [OcrResultSheet.show].
class OcrResultSheet extends StatefulWidget {
  final OcrResult result;

  const OcrResultSheet({super.key, required this.result});

  /// Convenience method — opens the sheet from any [BuildContext].
  static Future<void> show(BuildContext context, OcrResult result) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => OcrResultSheet(result: result),
    );
  }

  @override
  State<OcrResultSheet> createState() => _OcrResultSheetState();
}

class _OcrResultSheetState extends State<OcrResultSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Tab state: 0 = full text, 1 = blocks
  int _tab = 0;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: widget.result.fullText));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _copyBlock(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Block copied',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          expand: false,
          snap: true,
          snapSizes: const [0.45, 0.62, 0.92],
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHandle(),
                    _buildHeader(),
                    _buildTabBar(),
                    const SizedBox(height: 4),
                    Expanded(
                      child: _tab == 0
                          ? _buildFullTextView(scrollController)
                          : _buildBlocksView(scrollController),
                    ),
                    _buildBottomBar(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Drag Handle ──────────────────────────────────
  Widget _buildHandle() => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  // ─── Header ───────────────────────────────────────
  Widget _buildHeader() {
    final hasError = widget.result.hasError;
    final charCount = widget.result.fullText.length;
    final blockCount = widget.result.blocks.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.document_scanner_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Extracted Text',
                  style: GoogleFonts.inter(
                    color: AppColors.darkTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasError
                      ? 'OCR failed — ${widget.result.error}'
                      : widget.result.hasText
                          ? '$charCount chars · $blockCount blocks · ${widget.result.processingMs}ms'
                          : 'No text detected in this document',
                  style: GoogleFonts.inter(
                    color: hasError
                        ? Colors.red.shade300
                        : AppColors.darkTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: AppColors.darkTextSecondary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ─── Tab Bar ──────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.darkBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _tabItem(0, 'Full Text'),
            _tabItem(1, 'Blocks'),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(int index, String label) {
    final isActive = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color:
                    isActive ? AppColors.primary : AppColors.darkTextSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Full Text View ───────────────────────────────
  Widget _buildFullTextView(ScrollController scrollController) {
    if (!widget.result.hasText) {
      return _buildEmptyState();
    }

    return Scrollbar(
      controller: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selectable rich text — users can tap & drag to select
            SelectableText(
              widget.result.fullText,
              style: GoogleFonts.inter(
                color: AppColors.darkTextPrimary,
                fontSize: 14.5,
                height: 1.65,
                fontWeight: FontWeight.w400,
              ),
              contextMenuBuilder: (context, editableTextState) {
                return AdaptiveTextSelectionToolbar.editableText(
                  editableTextState: editableTextState,
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Blocks View ─────────────────────────────────
  Widget _buildBlocksView(ScrollController scrollController) {
    if (!widget.result.hasText) return _buildEmptyState();

    return Scrollbar(
      controller: scrollController,
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        itemCount: widget.result.blocks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final block = widget.result.blocks[i];
          return _BlockCard(
            block: block,
            index: i + 1,
            onCopy: () => _copyBlock(block.text),
          );
        },
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.text_fields_rounded,
                size: 56,
                color: AppColors.darkTextSecondary.withValues(alpha: 0.35)),
            const SizedBox(height: 16),
            Text(
              widget.result.hasError
                  ? 'Recognition Failed'
                  : 'No Text Detected',
              style: GoogleFonts.inter(
                color: AppColors.darkTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.result.hasError
                  ? widget.result.error ?? 'An unknown error occurred.'
                  : 'Make sure the document is well-lit and in focus.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.darkTextSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Action Bar ────────────────────────────
  Widget _buildBottomBar() {
    final hasText = widget.result.hasText;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.07),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: _copied ? 'Copied' : 'Copy All',
                isPrimary: true,
                isEnabled: hasText,
                onTap: hasText ? _copyAll : null,
              ),
            ),
            const SizedBox(width: 12),
            _ActionButton(
              label: 'Share',
              isPrimary: false,
              isEnabled: hasText,
              onTap: hasText ? () => Share.share(widget.result.fullText) : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  Block Card
// ══════════════════════════════════════════════════════
class _BlockCard extends StatefulWidget {
  final OcrBlock block;
  final int index;
  final VoidCallback onCopy;

  const _BlockCard({
    required this.block,
    required this.index,
    required this.onCopy,
  });

  @override
  State<_BlockCard> createState() => _BlockCardState();
}

class _BlockCardState extends State<_BlockCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'P${widget.index}',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${widget.block.lines.length} line${widget.block.lines.length == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(
                        color: AppColors.darkTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Copy block
                  GestureDetector(
                    onTap: widget.onCopy,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.copy_rounded,
                          size: 16, color: AppColors.darkTextSecondary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Collapse toggle
                  AnimatedRotation(
                    turns: _expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(Icons.expand_more_rounded,
                        size: 18, color: AppColors.darkTextSecondary),
                  ),
                ],
              ),
            ),
          ),
          // Divider
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          // Block text — selectable
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeOut,
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: SelectableText(
                widget.block.text,
                style: GoogleFonts.inter(
                  color: AppColors.darkTextPrimary,
                  fontSize: 13.5,
                  height: 1.6,
                ),
                contextMenuBuilder: (context, editableTextState) {
                  return AdaptiveTextSelectionToolbar.editableText(
                    editableTextState: editableTextState,
                  );
                },
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  Action Button
// ══════════════════════════════════════════════════════
class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.isPrimary,
    required this.isEnabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isEnabled
        ? (isPrimary ? AppColors.onPrimary : AppColors.darkTextPrimary)
        : AppColors.darkTextSecondary;
    final bgColor = isPrimary
        ? (isEnabled ? AppColors.primary : AppColors.darkBg)
        : AppColors.darkBg;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: isPrimary
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 0.5,
                ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: effectiveColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
