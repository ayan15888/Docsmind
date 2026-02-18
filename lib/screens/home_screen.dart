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
          if (errorMessage != null)
            Container(
              color: Colors.red.withOpacity(0.2),
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
          // if (lastPath != null)
          //   Padding(
          //     padding: const EdgeInsets.all(8.0),
          //     // child: Text('Last photo: $lastPath'),
          //   ),
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
