import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:docsmind/constants/app_constants.dart';
import 'package:docsmind/core/providers.dart';
import 'package:docsmind/screens/camera_screen.dart';
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
                    const SnackBar(content: Text('Scan business card selected')),
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

  @override
  Widget build(BuildContext context) {
    final lastPath = ref.watch(cameraPathProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Home'),
      ),
      body: Column(
        children: [
          if (lastPath != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Last photo: $lastPath'),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.description),
                title: Text('Item #${index + 1}'),
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
