import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<ScanResult> _results = [];
  bool _scanning = false;
  String? _connectingId;

  Future<void> _ensurePermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> _startScan() async {
    await _ensurePermissions();
    setState(() {
      _results = [];
      _scanning = true;
    });
    final appState = context.read<AppState>();
    appState.scan().listen((results) {
      if (!mounted) return;
      setState(() => _results = results);
    });
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) setState(() => _scanning = false);
    });
  }

  Future<void> _connect(ScanResult r) async {
    setState(() => _connectingId = r.device.remoteId.str);
    final appState = context.read<AppState>();
    await appState.stopScan();
    await appState.connect(r.device);
    if (!mounted) return;
    setState(() => _connectingId = null);
    if (appState.isConnected) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } else if (appState.connectionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: ${appState.connectionError}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBg,
      appBar: AppBar(
        backgroundColor: AppColors.navyBg,
        title: const Text('CONNECT DEVICE', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _scanning ? null : _startScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _scanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.bluetooth_searching),
                label: Text(_scanning ? 'Scanning...' : 'Scan for PHUD BOX'),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        _scanning
                            ? 'Looking for nearby devices...'
                            : 'No devices found yet. Make sure the box is powered on and in range.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final r = _results[i];
                        final name = r.device.platformName.isNotEmpty
                            ? r.device.platformName
                            : 'Unnamed device';
                        final id = r.device.remoteId.str;
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(
                                            color: Colors.white, fontWeight: FontWeight.w700)),
                                    Text('RSSI ${r.rssi} dBm',
                                        style: const TextStyle(
                                            color: AppColors.textMuted, fontSize: 12)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _connectingId == id ? null : () => _connect(r),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: _connectingId == id
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Connect'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
