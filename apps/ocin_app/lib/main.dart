import 'package:flutter/material.dart';
import 'package:ocin_app/src/rust/api/ocin.dart';
import 'package:ocin_app/src/rust/frb_generated.dart';
import 'package:ocin_app/widgets/status_badge.dart';
import 'package:ocin_app/pages/glass_benchmark_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await RustLib.init();
    runApp(const OcinApp());
  } catch (error) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Rust bridge belum siap: $error'),
        )),
      ),
    ));
  }
}

class OcinApp extends StatelessWidget {
  const OcinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCIN — POC-01',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF238A95)),
      ),
      home: const OcinDiagnosticsPage(),
    );
  }
}

class OcinDiagnosticsPage extends StatefulWidget {
  const OcinDiagnosticsPage({super.key});

  @override
  State<OcinDiagnosticsPage> createState() => _OcinDiagnosticsPageState();
}

class _OcinDiagnosticsPageState extends State<OcinDiagnosticsPage> {
  CoreStatus? _status;
  RuntimeCapabilities? _capabilities;
  String? _error;
  bool _loading = true;
  String _proofResult = 'Belum diuji';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() { _loading = true; _error = null; });
    try {
      final status = await getCoreStatus();
      final capabilities = await detectRuntimeCapabilities();
      if (!mounted) return;
      setState(() { _status = status; _capabilities = capabilities; });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkEphemeralIdentity() async {
    try {
      final challenge = 'ocin-poc01-${DateTime.now().toUtc().toIso8601String()}';
      final proof = await createEphemeralIdentityProof(challenge: challenge);
      final ok = await verifyIdentityProof(
        challenge: challenge,
        publicKeyHex: proof.publicKeyHex,
        signatureHex: proof.signatureHex,
      );
      if (!mounted) return;
      setState(() => _proofResult = ok
          ? 'PASS — Ed25519 valid, BLAKE3 ${proof.challengeHashHex.substring(0, 16)}…'
          : 'FAIL — signature verification failed');
    } catch (error) {
      if (mounted) setState(() => _proofResult = 'ERROR — $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    final c = _capabilities;
    return Scaffold(
      appBar: AppBar(title: const Text('OCIN · Core Diagnostics')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Text('OCIN', style: Theme.of(context).textTheme.displaySmall),
            const Text('POC-01 / Flutter + Rust FFI — bukan aplikasi remote siap pakai'),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) Text('Error: $_error'),
            if (s != null) Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Rust Core', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                StatusBadge(label: s.initialized ? 'Bridge aktif' : 'Belum siap', positive: s.initialized),
                Text('Nama: ${s.appName}'),
                Text('Versi core: ${s.coreVersion}'),
                Text('Platform: ${s.platform} / ${s.architecture}'),
                Text('Protokol: v${s.protocolVersion}'),
              ]),
            )),
            if (c != null) Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Capability candidates', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const StatusBadge(label: 'EXPERIMENTAL / NOT TESTED', positive: false),
                Text('LAN API candidate: ${c.localNetworkCandidate}'),
                Text('BLE API candidate: ${c.bleApiCandidate}'),
                Text('Screen API candidate: ${c.screenCaptureApiCandidate}'),
                Text('Remote input API candidate: ${c.remoteInputApiCandidate}'),
                Text('Apple glass candidate: ${c.nativeAppleGlassCandidate}'),
                const SizedBox(height: 8),
                Text(c.note),
              ]),
            )),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.layers_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const GlassBenchmarkPage(),
              )),
              label: const Text('Buka POC-02 · Liquid Glass Benchmark'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              icon: const Icon(Icons.verified_user_outlined),
              onPressed: _checkEphemeralIdentity,
              label: const Text('Uji tanda tangan Ed25519'),
            ),
            const SizedBox(height: 10),
            Text(_proofResult),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _refresh,
              label: const Text('Perbarui diagnostik'),
            ),
            const SizedBox(height: 16),
            const Text('Peringatan: Kunci identitas di PoC ini hanya sementara. '
                'Belum ada pairing, BLE, transfer file, atau remote desktop.'),
          ]),
        ),
      ),
    );
  }
}
