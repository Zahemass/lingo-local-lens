import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sample_proj/utils/base_shader.dart';
import 'package:sample_proj/widgets/shader_painter.dart';

class BackgroundCaptureWidget extends StatefulWidget {
  final GlobalKey backgroundKey;
  final BaseShader shader;
  final Widget child;

  const BackgroundCaptureWidget({
    super.key,
    required this.backgroundKey,
    required this.shader,
    required this.child,
  });

  @override
  State<BackgroundCaptureWidget> createState() => _BackgroundCaptureWidgetState();
}

class _BackgroundCaptureWidgetState extends State<BackgroundCaptureWidget> {
  ui.Image? _backgroundImage;
  Timer? _captureTimer;
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _scheduleCapture();
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _backgroundImage?.dispose();
    super.dispose();
  }

  void _scheduleCapture() {
    _captureTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) _captureBackground();
    });
  }

  Future<void> _captureBackground() async {
    try {
      final boundary = widget.backgroundKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || !boundary.attached) return;

      final image = await boundary.toImage();
      if (mounted) {
        setState(() {
          _backgroundImage?.dispose();
          _backgroundImage = image;
        });
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  void _updateShader(Size size) {
    if (_backgroundImage == null || size.isEmpty) return;

    widget.shader.updateShaderUniforms(
      width: size.width,
      height: size.height,
      backgroundImage: _backgroundImage,
    );
    _lastSize = size;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;

        // Only update shader if size changed
        if (_lastSize != size && !size.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _updateShader(size);
          });
        }

        // If shader and background image are ready, show the advanced glass effect
        if (_backgroundImage != null && widget.shader.isLoaded) {
          return Stack(
            children: [
              CustomPaint(
                painter: ShaderPainter(widget.shader.shader),
                size: size,
              ),
              widget.child,
            ],
          );
        }

        // Fallback: Always show a glassmorphism effect using BackdropFilter and opacity
        return Stack(
          children: [
            // This creates a frosted glass effect even while loading
            ClipRRect(
              borderRadius: BorderRadius.circular(20), // Adjust as needed
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 14.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}
