import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsmind/features/camera/models/camera_filter.dart';
import 'package:docsmind/features/camera/providers/camera_providers.dart';
import 'package:docsmind/features/camera/widgets/document_preview_dialog.dart';

/// Full-screen camera preview with optional filter overlay and tap-to-focus.
class CameraPreviewLayer extends ConsumerStatefulWidget {
  const CameraPreviewLayer({super.key});

  @override
  ConsumerState<CameraPreviewLayer> createState() => _CameraPreviewLayerState();
}

class _CameraPreviewLayerState extends ConsumerState<CameraPreviewLayer> {
  double _baseZoom = 1.0;

  @override
  Widget build(BuildContext context) {
    final controllerAsync = ref.watch(cameraControllerProvider);
    final filter = ref.watch(cameraFilterProvider);
    final focusPoint = ref.watch(cameraFocusPointProvider);
    final minZoom = ref.watch(cameraMinZoomProvider);
    final maxZoom = ref.watch(cameraMaxZoomProvider);
    final hasLiveDoc = ref.watch(liveDocumentDetectedProvider);
    final liveCorners = ref.watch(liveDocumentCornersProvider);

    return controllerAsync.when(
      data: (controller) {
        if (controller == null) return const _Loading();
        Widget preview = CameraPreview(controller);
        if (filter.colorFilter != null) {
          preview = ColorFiltered(
            colorFilter: filter.colorFilter!,
            child: preview,
          );
        }
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => _onTapToFocus(context, ref, controller, details),
          onScaleStart: (_) {
            _baseZoom = ref.read(cameraZoomLevelProvider);
          },
          onScaleUpdate: (details) {
            final next = (_baseZoom * details.scale).clamp(minZoom, maxZoom);
            ref.read(cameraZoomLevelProvider.notifier).state = next;
            // Apply immediately for responsiveness.
            controller.setZoomLevel(next);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              preview,
              if (hasLiveDoc)
                CustomPaint(
                  painter: DocumentBoundaryPainter(
                    hasDocument: true,
                    corners: liveCorners.isNotEmpty ? liveCorners : defaultDocumentCorners(),
                  ),
                  size: Size.infinite,
                ),
              if (focusPoint != null) _FocusIndicator(offset: focusPoint),
            ],
          ),
        );
      },
      loading: () => const _Loading(),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  void _onTapToFocus(BuildContext context, WidgetRef ref, CameraController controller, TapUpDetails details) {
    ref.read(cameraFocusPointProvider.notifier).state = details.localPosition;
    final size = MediaQuery.sizeOf(context);
    final point = Offset(
      details.localPosition.dx / size.width,
      details.localPosition.dy / size.height,
    );
    controller.setFocusPoint(point).then((_) {
      ref.read(cameraFocusPointProvider.notifier).state = null;
    }).catchError((_) {
      ref.read(cameraFocusPointProvider.notifier).state = null;
    });
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _FocusIndicator extends StatelessWidget {
  final Offset offset;

  const _FocusIndicator({required this.offset});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx - 40,
      top: offset.dy - 40,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
