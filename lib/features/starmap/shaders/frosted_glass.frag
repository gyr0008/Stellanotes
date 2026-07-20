#version 320 es
precision highp float;

#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform vec2 uResolution;
uniform vec2 uRectPos;      // 毛玻璃区域位置
uniform vec2 uRectSize;     // 毛玻璃区域大小
uniform float uBlurRadius;
uniform float uOpacity;
uniform vec4 uTintColor;    // 色调叠加 (rgba)
uniform float uBorderBrightness; // 边缘高光强度 0-1
uniform sampler2D uTexture; // 背景纹理（由宿主在运行时绑定）

layout(location = 0) out vec4 fragColor;

// 高质量高斯模糊采样
vec4 blur(sampler2D tex, vec2 uv, vec2 resolution, float radius) {
  vec4 color = vec4(0.0);
  float total = 0.0;
  float texelStep = 1.0 / resolution.x;

  for (float x = -4.0; x <= 4.0; x += 1.0) {
    for (float y = -4.0; y <= 4.0; y += 1.0) {
      float weight = 1.0 - length(vec2(x, y)) / 5.66;
      weight = max(weight, 0.0);
      color += texture(tex, uv + vec2(x, y) * texelStep * radius) * weight;
      total += weight;
    }
  }
  return color / total;
}

void main() {
  vec2 fragCoord = FlutterFragCoord();
  vec2 uv = fragCoord / uResolution;

  // 检查是否在毛玻璃区域内
  vec2 localPos = (fragCoord - uRectPos) / uRectSize;
  bool inside = all(greaterThanEqual(localPos, vec2(0.0))) &&
                all(lessThanEqual(localPos, vec2(1.0)));

  if (!inside) {
    fragColor = vec4(0.0);
    return;
  }

  // 基础模糊
  vec4 blurred = blur(
    uTexture,
    uv,
    uResolution,
    uBlurRadius
  );

  // 色调叠加
  vec3 tinted = mix(blurred.rgb, uTintColor.rgb, uTintColor.a * 0.3);

  // 边缘高光
  float edgeDist = min(
    min(localPos.x, 1.0 - localPos.x),
    min(localPos.y, 1.0 - localPos.y)
  );
  float edgeGlow = smoothstep(0.0, 0.05, edgeDist) * uBorderBrightness;
  tinted += vec3(edgeGlow * 0.15);

  // 透明度
  fragColor = vec4(tinted, uOpacity);
}
