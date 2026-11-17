import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ocin_app/glass/adaptive_liquid_glass.dart';

/// Manual PoC sandbox: scroll, tap, FPS and frame-build/raster monitoring.
/// Run PROFILE mode on a physical device before treating numbers as evidence.
class GlassBenchmarkPage extends StatefulWidget {
  const GlassBenchmarkPage({super.key});

  @override
  State<GlassBenchmarkPage> createState() => _GlassBenchmarkPageState();
}

class _GlassBenchmarkPageState extends State<GlassBenchmarkPage> {
  final List<double> _frameMs = [];
  final List<double> _rasterMs = [];
  int _frames = 0;
  int _tapCount = 0;
  int _janky = 0;
  bool _forceFallback = false;
  GlassBackend? _navBackend;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    super.dispose();
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    for (final frame in timings) {
      final total = frame.totalSpan.inMicroseconds / 1000;
      final raster = frame.rasterDuration.inMicroseconds / 1000;
      _frameMs.add(total);
      _rasterMs.add(raster);
      _frames++;
      if (total > 16.67) _janky++;
      if (_frameMs.length > 240) _frameMs.removeAt(0);
      if (_rasterMs.length > 240) _rasterMs.removeAt(0);
    }
    if (mounted && _frames % 30 < timings.length) setState(() {});
  }

  double _percentile(List<double> input, double p) {
    if (input.isEmpty) return 0;
    final sorted = [...input]..sort();
    return sorted[math.min(sorted.length - 1, (sorted.length * p).floor())];
  }

  @override
  Widget build(BuildContext context) {
    final fallback = _forceFallback ? GlassBackend.safeFallback : null;
    return Scaffold(
      appBar: AppBar(title: const Text('OCIN · Liquid Glass PoC-02')),
      body: Stack(children: [
        Positioned.fill(child: DecoratedBox(
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF092935), Color(0xFF316F80), Color(0xFFE2EAF4)],
          )),
          child: CustomPaint(painter: _PatternPainter()),
        )),
        SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AdaptiveLiquidGlass(
              key: const ValueKey('ocin-glass-nav'),
              surface: GlassSurfaceType.navigationBar,
              backendOverride: fallback,
              onBackendResolved: (backend) {
                if (_navBackend == backend) return;
                setState(() => _navBackend = backend);
              },
              child: Row(children: [
                const Expanded(child: Text('OCIN · Device Lab',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                const Icon(Icons.wifi, color: Colors.white),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Text('Renderer: ${_navBackend?.name ?? "resolving"}',
                      style: const TextStyle(color: Colors.white)),
                  Text('Frame p95: ${_percentile(_frameMs, .95).toStringAsFixed(1)} ms '
                      '· raster p95: ${_percentile(_rasterMs, .95).toStringAsFixed(1)} ms',
                      style: const TextStyle(color: Colors.white)),
                  Text('Samples: $_frames · >16.7 ms: $_janky · taps: $_tapCount',
                      style: const TextStyle(color: Colors.white)),
                  SwitchListTile.adaptive(
                    title: const Text('Force safe fallback', style: TextStyle(color: Colors.white)),
                    value: _forceFallback,
                    onChanged: (value) => setState(() => _forceFallback = value),
                  ),
                  const Text('Measure in PROFILE mode, on device. No results claimed yet.',
                      style: TextStyle(color: Colors.white70)),
                ]),
              ),
            ),
          ),
          Expanded(child: ListView.builder(
            key: const ValueKey('ocin-glass-list'),
            padding: const EdgeInsets.all(16),
            itemCount: 40,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AdaptiveLiquidGlass(
                surface: GlassSurfaceType.card,
                backendOverride: fallback,
                child: InkWell(
                  key: ValueKey('ocin-glass-tap-$index'),
                  onTap: () => setState(() => _tapCount++),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(children: [
                      const Icon(Icons.devices, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(child: Text('OCIN Device ${index + 1}',
                          style: const TextStyle(color: Colors.white))),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ]),
                  ),
                ),
              ),
            ),
          )),
        ])),
      ]),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x66FFFFFF)..strokeWidth = 1.5;
    for (var y = 8.0; y < size.height; y += 38) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (var x = 8.0; x < size.width; x += 38) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) => false;
}
