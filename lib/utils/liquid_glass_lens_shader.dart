import 'dart:ui' as ui;
import 'package:sample_proj/utils/base_shader.dart';

class LiquidGlassLensShader extends BaseShader {
  LiquidGlassLensShader() : super(shaderAssetPath: 'shaders/liquid_glass_lens.frag');

  @override
  void updateShaderUniforms({
    required double width,
    required double height,
    required ui.Image? backgroundImage,
  }) {
    if (!isLoaded) return;

    shader.setFloat(0, width);
    shader.setFloat(1, height);
    shader.setFloat(2, width / 2); // Center X
    shader.setFloat(3, height / 2); // Center Y
    shader.setFloat(4, 5.0); // Effect size
    shader.setFloat(5, 25); // Blur intensity
    shader.setFloat(6, 0.4); // Dispersion strength

    if (backgroundImage != null) {
      shader.setImageSampler(0, backgroundImage);
    }
  }

  // Remove @override since BaseShader does not define dispose
  void dispose() {
    // If you add resources here in the future, dispose them here.
    // No super.dispose() call, since BaseShader has no such method.
  }
}
