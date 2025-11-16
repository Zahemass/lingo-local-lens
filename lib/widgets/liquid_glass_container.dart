import 'package:flutter/material.dart';
import 'package:sample_proj/utils/liquid_glass_lens_shader.dart';
import 'package:sample_proj/widgets/background_capture_widget.dart';

class LiquidGlassContainer extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsets padding;
  final GlobalKey backgroundKey;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.padding,
    required this.backgroundKey,
  });

  @override
  State<LiquidGlassContainer> createState() => _LiquidGlassContainerState();
}

class _LiquidGlassContainerState extends State<LiquidGlassContainer> {
  final LiquidGlassLensShader _shader = LiquidGlassLensShader();
  bool _shaderLoaded = false;
  bool _shaderError = false;

  @override
  void initState() {
    super.initState();
    _initializeShader();
  }

  Future<void> _initializeShader() async {
    try {
      await _shader.initialize();
      if (mounted) {
        setState(() {
          _shaderLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Shader initialization error: $e');
      if (mounted) {
        setState(() {
          _shaderError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _shader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        color: _getBackgroundColor(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: _buildContent(),
      ),
    );
  }

  Color? _getBackgroundColor() {
    if (!_shaderLoaded || _shaderError) {
      return Colors.white.withOpacity(0.2);
    }
    return null;
  }

  Widget _buildContent() {
    if (_shaderError) {
      return widget.child; // Fallback to normal child if shader failed
    }

    if (!_shaderLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return BackgroundCaptureWidget(
      backgroundKey: widget.backgroundKey,
      shader: _shader,
      child: widget.child,
    );
  }
}
