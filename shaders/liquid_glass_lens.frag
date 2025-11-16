#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform vec2 uMouse;
uniform float uEffectSize;
uniform float uBlurIntensity;
uniform float uDispersionStrength;
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord();
    vec2 uv = fragCoord / uResolution.xy;
    vec2 center = uMouse.xy / uResolution.xy;
    vec2 m2 = (uv - center);

    float effectRadius = uEffectSize * 0.5;
    float sizeMultiplier = 1.0 / (effectRadius * effectRadius);
    float roundedBox = pow(abs(m2.x * uResolution.x / uResolution.y), 4.0) +
                       pow(abs(m2.y), 4.0);

    float baseIntensity = 100.0 * sizeMultiplier;
    float rb1 = clamp((1.0 - roundedBox * baseIntensity) * 8.0, 0.0, 1.0);
    float rb2 = clamp((0.95 - roundedBox * baseIntensity * 0.95) * 16.0, 0.0, 1.0) -
                clamp(pow(0.9 - roundedBox * baseIntensity * 0.95, 1.0) * 16.0, 0.0, 1.0);
    float rb3 = clamp((1.5 - roundedBox * baseIntensity * 1.1) * 2.0, 0.0, 1.0) -
                clamp(pow(1.0 - roundedBox * baseIntensity * 1.1, 1.0) * 2.0, 0.0, 1.0);

    fragColor = vec4(0.0);

    if (rb1 + rb2 > 0.0) {
        float distortionStrength = 50.0 * sizeMultiplier;
        vec2 lens = ((uv - 0.5) * (1.0 - roundedBox * distortionStrength) + 0.5);

        vec2 dir = normalize(m2);
        float dispersionScale = uDispersionStrength * 0.05;
        float dispersionMask = smoothstep(0.3, 0.7, roundedBox * baseIntensity);

        vec2 redOffset = dir * dispersionScale * 2.0 * dispersionMask;
        vec2 greenOffset = dir * dispersionScale * 1.0 * dispersionMask;
        vec2 blueOffset = dir * dispersionScale * -1.5 * dispersionMask;

        vec4 colorResult = vec4(0.0);

        if (uBlurIntensity > 0.0) {
            float blurRadius = uBlurIntensity / max(uResolution.x, uResolution.y);
            float total = 0.0;
            vec3 colorSum = vec3(0.0);
            for (float x = -2.0; x <= 2.0; x += 1.0) {
                for (float y = -2.0; y <= 2.0; y += 1.0) {
                    vec2 offset = vec2(x, y) * blurRadius;
                    colorSum.r += texture(uTexture, lens + offset + redOffset).r;
                    colorSum.g += texture(uTexture, lens + offset + greenOffset).g;
                    colorSum.b += texture(uTexture, lens + offset + blueOffset).b;
                    total += 1.0;
                }
            }
            colorResult = vec4(colorSum / total, 1.0);
        } else {
            colorResult.r = texture(uTexture, lens + redOffset).r;
            colorResult.g = texture(uTexture, lens + greenOffset).g;
            colorResult.b = texture(uTexture, lens + blueOffset).b;
            colorResult.a = 1.0;
        }

        float gradient = clamp((clamp(m2.y, 0.0, 0.2) + 0.1) / 2.0, 0.0, 1.0) +
                         clamp((clamp(-m2.y, -1000.0, 0.2) * rb3 + 0.1) / 2.0, 0.0, 1.0);

        fragColor = mix(
                texture(uTexture, uv),
                colorResult,
                rb1
        );
        fragColor = clamp(fragColor + vec4(rb2 * 0.3) + vec4(gradient * 0.2), 0.0, 1.0);
    } else {
        fragColor = texture(uTexture, uv);
    }
}