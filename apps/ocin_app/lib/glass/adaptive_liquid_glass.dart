import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

/// Platform agnostic API; OS-specific routing is restricted to this module.
///
/// Native Apple rendering is only attempted on large/static navigation surfaces.
/// Repeated cards/buttons use a single Impeller shader program when available.
enum GlassSurfaceType { navigationBar, card, button }
enum GlassBackend { nativeApple, shader, safeFallback }

class GlassCapabilityResolver {
  GlassCapabilityResolver._();

  static const MethodChannel _channel = MethodChannel('ocin/native_glass');
  static Future<bool>? _nativeSupport;
  static Future<bool>? _reduceTransparency;
  static Future<ui.FragmentProgram>? _shaderProgram;

  static Future<bool> nativeGlassAvailable() {
    return _nativeSupport ??= _probeNativeGlass();
  }

  static Future<bool> _probeNativeGlass() async {
    if (!Platform.isIOS && !Platform.isMacOS) return false;
    try {
      // Swift handles #available(iOS/macOS 26, *) and accessibility conditions.
      return await _channel.invokeMethod<bool>('available') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> reduceTransparencyRequested() {
    return _reduceTransparency ??= _probeReduceTransparency();
  }

  static Future<bool> _probeReduceTransparency() async {
    if (!onApple) return false;
    try {
      return await _channel.invokeMethod<bool>('reduceTransparency') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<ui.FragmentProgram> program() =>
      _shaderProgram ??= ui.FragmentProgram.fromAsset('shaders/liquid_glass.frag');

  static bool get shaderBackendAvailable => ui.ImageFilter.isShaderFilterSupported;

  static bool get onApple => Platform.isIOS || Platform.isMacOS;

  @visibleForTesting
  static void resetCache() {
    _nativeSupport = null;
    _reduceTransparency = null;
    _shaderProgram = null;
  }
}

class AdaptiveLiquidGlass extends StatefulWidget {
  const AdaptiveLiquidGlass({
    super.key,
    required this.child,
    this.surface = GlassSurfaceType.card,
    this.borderRadius = 22,
    this.intensity = 0.7,
    this.enableRefraction = true,
    this.enableChromaticAberration = true,
    this.enableSpecularHighlights = true,
    this.enableFluidMorphing = true,
    this.adaptiveQuality = true,
    this.backendOverride,
    this.onBackendResolved,
  });

  final Widget child;
  final GlassSurfaceType surface;
  final double borderRadius;
  final double intensity;
  final bool enableRefraction;
  final bool enableChromaticAberration;
  final bool enableSpecularHighlights;
  final bool enableFluidMorphing;
  final bool adaptiveQuality;

  /// For deterministic widget tests and manual benchmark comparison only.
  final GlassBackend? backendOverride;
  final ValueChanged<GlassBackend>? onBackendResolved;

  @override
  State<AdaptiveLiquidGlass> createState() => _AdaptiveLiquidGlassState();
}

class _AdaptiveLiquidGlassState extends State<AdaptiveLiquidGlass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spring;
  Future<bool>? _nativeProbe;
  Future<bool>? _accessibilityProbe;
  Offset _pointer = const Offset(0.5, 0.5);
  GlassBackend? _lastReported;

  @override
  void initState() {
    super.initState();
    _spring = AnimationController.unbounded(vsync: this, value: 1.0);
    if (GlassCapabilityResolver.onApple) {
      _accessibilityProbe = GlassCapabilityResolver.reduceTransparencyRequested();
    }
    if (widget.surface == GlassSurfaceType.navigationBar &&
        GlassCapabilityResolver.onApple) {
      _nativeProbe = GlassCapabilityResolver.nativeGlassAvailable();
    }
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  void _animatePress(bool pressed) {
    if (!widget.enableFluidMorphing || MediaQuery.disableAnimationsOf(context)) {
      _spring.value = pressed ? 0.987 : 1.0;
      return;
    }
    final target = pressed ? 0.987 : 1.0;
    _spring.animateWith(SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 240, damping: 24),
      _spring.value,
      target,
      _spring.velocity,
    ));
  }

  void _updatePointer(PointerEvent event, BoxConstraints constraints) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return;
    setState(() => _pointer = Offset(
          (event.localPosition.dx / w).clamp(0.0, 1.0),
          (event.localPosition.dy / h).clamp(0.0, 1.0),
        ));
  }

  void _report(GlassBackend backend) {
    if (_lastReported == backend || widget.onBackendResolved == null) return;
    _lastReported = backend;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onBackendResolved?.call(backend);
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Current Flutter does not universally expose OS Reduce Transparency.
    // A native probe handles Apple Reduce Transparency; high-contrast and
    // disableAnimations are conservative application-level fallbacks.
    final accessibilityFallback = media.highContrast;

    return LayoutBuilder(builder: (context, constraints) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerHover: (event) => _updatePointer(event, constraints),
        onPointerMove: (event) => _updatePointer(event, constraints),
        onPointerDown: (event) {
          _updatePointer(event, constraints);
          _animatePress(true);
        },
        onPointerUp: (_) => _animatePress(false),
        onPointerCancel: (_) => _animatePress(false),
        child: AnimatedBuilder(
          animation: _spring,
          builder: (context, child) => Transform.scale(
            scale: _spring.value,
            alignment: Alignment.center,
            child: child,
          ),
          child: _chooseWithAccessibility(accessibilityFallback),
        ),
      );
    });
  }

  Widget _chooseWithAccessibility(bool systemFallback) {
    if (_accessibilityProbe != null) {
      return FutureBuilder<bool>(
        future: _accessibilityProbe,
        builder: (context, snap) => _chooseBackend(systemFallback || snap.data == true),
      );
    }
    return _chooseBackend(systemFallback);
  }

  Widget _chooseBackend(bool accessibilityFallback) {
    if (accessibilityFallback ||
        widget.backendOverride == GlassBackend.safeFallback) {
      _report(GlassBackend.safeFallback);
      return _safeSurface();
    }
    if (widget.backendOverride == GlassBackend.shader) {
      return _shaderOrSafe();
    }
    if (widget.backendOverride == GlassBackend.nativeApple &&
        GlassCapabilityResolver.onApple &&
        widget.surface == GlassSurfaceType.navigationBar) {
      return _nativeSurface();
    }
    if (widget.surface == GlassSurfaceType.navigationBar &&
        GlassCapabilityResolver.onApple &&
        _nativeProbe != null) {
      return FutureBuilder<bool>(
        future: _nativeProbe,
        builder: (context, snap) => snap.data == true
            ? _nativeSurface()
            : _shaderOrSafe(),
      );
    }
    return _shaderOrSafe();
  }

  Widget _nativeSurface() {
    _report(GlassBackend.nativeApple);
    final platformView = Platform.isIOS
        ? const UiKitView(
            viewType: 'ocin/native_glass_surface',
            creationParamsCodec: StandardMessageCodec(),
            creationParams: {'radius': 24.0},
          )
        : const AppKitView(
            viewType: 'ocin/native_glass_surface',
            creationParamsCodec: StandardMessageCodec(),
            creationParams: {'radius': 24.0},
          );
    // Restrict this to static navigation surfaces. If a platform view fails to
    // composite correctly, smoke tests must force shader/fallback instead.
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(fit: StackFit.passthrough, children: [
        Positioned.fill(child: IgnorePointer(child: platformView)),
        Padding(padding: const EdgeInsets.all(12), child: widget.child),
      ]),
    );
  }

  Widget _shaderOrSafe() {
    if (!GlassCapabilityResolver.shaderBackendAvailable) {
      _report(GlassBackend.safeFallback);
      return _safeSurface();
    }
    return FutureBuilder<ui.FragmentProgram>(
      future: GlassCapabilityResolver.program(),
      builder: (context, snap) {
        if (!snap.hasData) {
          _report(GlassBackend.safeFallback);
          return _safeSurface();
        }
        try {
          final shader = snap.data!.fragmentShader();
          // u_size(vec2) is populated by ImageFilter.shader, not by Dart.
          // Explicit floats are u_pointer(vec2), u_strength(float),
          // u_chroma(float), u_specular(float) at offsets 2..6.
          shader.setFloat(2, _pointer.dx);
          shader.setFloat(3, _pointer.dy);
          shader.setFloat(4, widget.enableRefraction ? widget.intensity : 0);
          shader.setFloat(5, widget.enableChromaticAberration ? 1 : 0);
          shader.setFloat(6, widget.enableSpecularHighlights ? 1 : 0);
          final filter = ui.ImageFilter.shader(shader, filterQuality: ui.FilterQuality.low);
          _report(GlassBackend.shader);
          return ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(fit: StackFit.passthrough, children: [
              Positioned.fill(child: BackdropFilter(
                filter: filter,
                child: const ColoredBox(color: Colors.transparent),
              )),
              _glassRim(),
              Padding(padding: const EdgeInsets.all(12), child: widget.child),
            ]),
          );
        } on UnsupportedError {
          _report(GlassBackend.safeFallback);
          return _safeSurface();
        } on StateError {
          _report(GlassBackend.safeFallback);
          return _safeSurface();
        }
      },
    );
  }

  Widget _glassRim() => IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_pointer.dx * 2 - 1, _pointer.dy * 2 - 1),
              end: Alignment(-_pointer.dx * 2 + 1, -_pointer.dy * 2 + 1),
              colors: const [Color(0x18FFFFFF), Color(0x06D6E5FF)],
            ),
            border: Border.all(color: const Color(0x80FFFFFF), width: 0.8),
          ),
        ),
      );

  Widget _safeSurface() => ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(fit: StackFit.passthrough, children: [
          Positioned.fill(child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
            child: ColoredBox(color: MediaQuery.of(context).highContrast
                ? const Color(0xFF0B2230) : const Color(0x66FFFFFF)),
          )),
          _glassRim(),
          Padding(padding: const EdgeInsets.all(12), child: widget.child),
        ]),
      );
}
