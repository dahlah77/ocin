#include <flutter/runtime_effect.glsl>

// Must be first: Flutter's ImageFilter.shader injects backdrop size at [0..1].
uniform vec2 u_size;
// Dart sets these at offsets [2..6], in order. Do not add a float above u_size.
uniform vec2 u_pointer;
uniform float u_strength;
uniform float u_chroma;
uniform float u_specular;
// First sampler is populated by the renderer from the filtered backdrop.
uniform sampler2D u_backdrop;

out vec4 fragColor;

float roundedRectSdf(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + vec2(r);
  return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
  vec2 bounds = max(u_size, vec2(1.0));
  vec2 uv = FlutterFragCoord().xy / bounds;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif

  // Elliptically scaled rounded-rectangle signed-distance field.
  vec2 p = (uv - 0.5) * vec2(bounds.x / max(bounds.y, 1.0), 1.0);
  float aspect = bounds.x / max(bounds.y, 1.0);
  float corner = 0.12;
  float sd = roundedRectSdf(p, vec2(0.5 * aspect, 0.5), corner);
  float edge = 1.0 - smoothstep(0.0, 0.06, max(-sd, 0.0));
  vec2 n = normalize(p + vec2(0.0001, 0.0002));
  vec2 bend = n * edge * clamp(u_strength, 0.0, 1.0) * 0.015;
  vec2 safeUv = clamp(uv + bend, vec2(0.005), vec2(0.995));

  vec2 spectral = n * edge * (0.003 * u_chroma);
  vec3 refracted = vec3(
    texture(u_backdrop, clamp(safeUv + spectral, vec2(0.0), vec2(1.0))).r,
    texture(u_backdrop, safeUv).g,
    texture(u_backdrop, clamp(safeUv - spectral, vec2(0.0), vec2(1.0))).b
  );

  vec2 light = normalize(u_pointer - vec2(0.5) + vec2(0.001, 0.003));
  float spec = pow(max(0.0, dot(normalize(n), light)), 11.0)
      * edge * 0.25 * clamp(u_specular, 0.0, 1.0);
  float ambient = edge * 0.045;
  vec4 base = texture(u_backdrop, uv);
  fragColor = vec4(clamp(refracted + vec3(spec + ambient), 0.0, 1.0), base.a);
}
