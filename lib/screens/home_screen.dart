import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:docsmind/constants/app_constants.dart';
import 'package:docsmind/core/providers.dart';
import 'package:docsmind/screens/camera_screen.dart';
import 'package:docsmind/features/settings/services/settings_service.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _holdTimer;

  void _handleLongPressStart(LongPressStartDetails details) {
    // start a 2-second timer before showing options
    _holdTimer = Timer(const Duration(milliseconds: 500), () {
      _showOptions();
    });
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  void _showOptions() {
    // provide haptic feedback when options are shown
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Wrap(
            spacing: 12,
            children: [
              ActionChip(
                label: const Text('Merge PDF'),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Merge PDF selected')),
                  );
                },
              ),
              ActionChip(
                label: const Text('Scan business card'),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Scan business card selected')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCamera(WidgetRef ref, BuildContext context) async {
    // ensure permission granted
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied')),
        );
        return;
      }
    }

    // navigate to camera screen instead of using image picker
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CameraScreen()),
      );
    }
  }

  void _showSettings() {
    SettingsService.showSettingsDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(documentsProvider);
    final errorMessage = ref.watch(errorMessageProvider);
    final opencvStatus = ref.watch(opencvStatusProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── OpenCV Developer Status Banner ──
          _OpenCVStatusBanner(opencvStatus: opencvStatus),
          if (errorMessage != null)
            Container(
              color: Colors.red.withValues(alpha: 0.2),
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      ref.read(errorMessageProvider.notifier).state = null;
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: documents.isEmpty
                ? Center(
                    child: Text(
                      'No documents scanned yet',
                      style: GoogleFonts.pixelifySans().copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) => ListTile(
                      leading: const Icon(Icons.description),
                      title: Text('Document #${index + 1}'),
                      subtitle: Text(documents[index]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onLongPressStart: _handleLongPressStart,
        onLongPressEnd: _handleLongPressEnd,
        child: FloatingActionButton(
          onPressed: () async {
            await _openCamera(ref, context);
          },
          child: const Icon(Icons.camera_alt),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// Developer status banner showing OpenCV connection state.
class _OpenCVStatusBanner extends StatelessWidget {
  final AsyncValue opencvStatus;

  const _OpenCVStatusBanner({required this.opencvStatus});

  @override
  Widget build(BuildContext context) {
    return opencvStatus.when(
      loading: () => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          border: Border(bottom: BorderSide(color: Colors.amber.shade300)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.amber),
            ),
            SizedBox(width: 10),
            Text(
              '🔍  Checking OpenCV connection...',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      error: (err, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border(bottom: BorderSide(color: Colors.red.shade200)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '❌  OpenCV Error: $err',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade800),
              ),
            ),
          ],
        ),
      ),
      data: (status) {
        final isAvailable = status.isAvailable;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
            border: Border(
              bottom: BorderSide(
                color:
                    isAvailable ? Colors.green.shade200 : Colors.red.shade200,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isAvailable ? Icons.check_circle : Icons.cancel,
                size: 18,
                color:
                    isAvailable ? Colors.green.shade700 : Colors.red.shade700,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAvailable
                      ? '✅  OpenCV Connected (v${status.version})'
                      : '❌  OpenCV Disconnected: ${status.error ?? "Unknown"}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isAvailable
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ),
              // Refresh button
              InkWell(
                onTap: () {
                  // Force re-check by invalidating the provider
                  final container = ProviderScope.containerOf(context);
                  container.invalidate(opencvStatusProvider);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.refresh,
                    size: 18,
                    color: isAvailable
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
