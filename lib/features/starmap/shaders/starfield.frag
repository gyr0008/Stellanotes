#version 320 es
precision highp float;

#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform vec2 uResolution;
uniform float uParticleDensity;

layout(location = 0) out vec4 fragColor;

// 伪随机函数
float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 噪声函数
float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void main() {
  vec2 fragCoord = FlutterFragCoord();
  vec2 uv = fragCoord / uResolution;

  // 深空渐变背景
  vec3 topColor = vec3(0.039, 0.055, 0.153);    // #0A0E27
  vec3 bottomColor = vec3(0.102, 0.102, 0.243);  // #1A1A3E
  vec3 bgColor = mix(bottomColor, topColor, uv.y);

  // 星云效果（低频噪声）
  float nebula = noise(uv * 3.0 + uTime * 0.01) * 0.08;
  bgColor += vec3(0.1, 0.05, 0.2) * nebula;

  // 星点粒子
  float starField = 0.0;
  float density = uParticleDensity;

  for (int layer = 0; layer < 3; layer++) {
    float scale = 50.0 + float(layer) * 30.0;
    vec2 grid = floor(uv * uResolution / scale);
    float h = hash(grid + float(layer) * 100.0);

    if (h > (1.0 - 0.3 * density)) {
      vec2 center = (grid + vec2(hash(grid + 0.1), hash(grid + 0.2))) * scale;
      float dist = length(fragCoord - center);
      float twinkle = sin(uTime * (2.0 + h * 3.0) + h * 6.28) * 0.5 + 0.5;
      float brightness = smoothstep(2.0, 0.0, dist) * (0.3 + twinkle * 0.7);
      starField += brightness * (1.0 - float(layer) * 0.25);
    }
  }

  vec3 finalColor = bgColor + vec3(starField);
  fragColor = vec4(finalColor, 1.0);
}
