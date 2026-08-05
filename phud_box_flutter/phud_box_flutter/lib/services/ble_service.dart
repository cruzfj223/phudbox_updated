import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// ---------------------------------------------------------------------
/// PHUD BOX BLE protocol
///
/// One custom GATT service exposes two characteristics. Every message,
/// in either direction, is a single JSON object encoded as UTF-8 and
/// terminated with a '\n' newline byte. Messages longer than the
/// negotiated MTU are split across multiple BLE writes/notifications and
/// reassembled here by buffering until a newline is seen.
///
/// Telemetry characteristic (peripheral -> phone, notify):
///   {"type":"telemetry","battery":92,"status":"idle","door_open":true,
///    "chamber_slots_left":3,"seconds_left":0,"active_batch":null}
///
///   {"type":"log_entry","id":"#004","color":"RED","date":"08/05/2026",
///    "result":"PASS","instruments":"Scalpel, Forceps","time":"10:30 AM - 10:40 AM",
///    "uv_intensity":"275nm","expiry":"08/06/2026 @ 10:30 AM","error":null}
///
/// Command characteristic (phone -> peripheral, write):
///   {"cmd":"start_cycle"}
///   {"cmd":"end_cycle"}
/// ---------------------------------------------------------------------
class BleProtocol {
  static final Guid serviceUuid = Guid('b3f1e100-0a1e-4b8b-9a53-4f0e6d6a10a0');
  static final Guid telemetryCharUuid = Guid('b3f1e101-0a1e-4b8b-9a53-4f0e6d6a10a0');
  static final Guid commandCharUuid = Guid('b3f1e102-0a1e-4b8b-9a53-4f0e6d6a10a0');
}

class BleService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _telemetryChar;
  BluetoothCharacteristic? _commandChar;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  final List<int> _rxBuffer = [];

  final _telemetryController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<BluetoothConnectionState>.broadcast();

  /// Emits one decoded JSON message per event (telemetry or log_entry).
  Stream<Map<String, dynamic>> get messages => _telemetryController.stream;

  Stream<BluetoothConnectionState> get connectionState => _connectionController.stream;

  bool get isConnected => _device != null;

  /// Scans for peripherals advertising the PHUD BOX service UUID.
  Stream<List<ScanResult>> scan({Duration timeout = const Duration(seconds: 8)}) {
    FlutterBluePlus.startScan(
      withServices: [BleProtocol.serviceUuid],
      timeout: timeout,
    );
    return FlutterBluePlus.scanResults;
  }

  Future<void> stopScan() => FlutterBluePlus.stopScan();

  Future<void> connect(BluetoothDevice device) async {
    _device = device;
    await device.connect(timeout: const Duration(seconds: 12), autoConnect: false);

    _connSub = device.connectionState.listen((state) {
      _connectionController.add(state);
      if (state == BluetoothConnectionState.disconnected) {
        _cleanupAfterDisconnect();
      }
    });

    // Ask for a bigger MTU (Android only; ignored elsewhere) so JSON
    // payloads mostly fit in a single notification/write.
    try {
      await device.requestMtu(517);
    } catch (_) {
      // MTU negotiation isn't supported on every platform/peripheral;
      // the newline-delimited buffering below handles fragmentation anyway.
    }

    final services = await device.discoverServices();
    final service = services.firstWhere(
      (s) => s.uuid == BleProtocol.serviceUuid,
      orElse: () => throw Exception(
          'PHUD BOX GATT service not found on this device. Check firmware UUIDs.'),
    );

    _telemetryChar = service.characteristics.firstWhere(
      (c) => c.uuid == BleProtocol.telemetryCharUuid,
    );
    _commandChar = service.characteristics.firstWhere(
      (c) => c.uuid == BleProtocol.commandCharUuid,
    );

    await _telemetryChar!.setNotifyValue(true);
    _notifySub = _telemetryChar!.lastValueStream.listen(_onChunkReceived);
  }

  void _onChunkReceived(List<int> chunk) {
    if (chunk.isEmpty) return;
    _rxBuffer.addAll(chunk);

    while (true) {
      final newlineIndex = _rxBuffer.indexOf(0x0A); // '\n'
      if (newlineIndex == -1) break;

      final lineBytes = _rxBuffer.sublist(0, newlineIndex);
      _rxBuffer.removeRange(0, newlineIndex + 1);

      if (lineBytes.isEmpty) continue;
      try {
        final decoded = utf8.decode(lineBytes);
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        _telemetryController.add(json);
      } catch (e) {
        // Malformed/partial frame - drop it rather than crash the stream.
      }
    }
  }

  /// Sends a JSON command to the peripheral, chunked to the current MTU.
  Future<void> sendCommand(Map<String, dynamic> command) async {
    final char = _commandChar;
    if (char == null) {
      throw StateError('Not connected to a PHUD BOX device.');
    }
    final bytes = Uint8List.fromList(utf8.encode('${jsonEncode(command)}\n'));

    final mtu = _device?.mtuNow ?? 23;
    final chunkSize = (mtu - 3).clamp(20, 512); // 3 bytes of ATT overhead

    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = (offset + chunkSize < bytes.length) ? offset + chunkSize : bytes.length;
      await char.write(bytes.sublist(offset, end), withoutResponse: false);
    }
  }

  Future<void> startCycle() => sendCommand({'cmd': 'start_cycle'});
  Future<void> endCycle() => sendCommand({'cmd': 'end_cycle'});

  Future<void> disconnect() async {
    await _device?.disconnect();
    _cleanupAfterDisconnect();
  }

  void _cleanupAfterDisconnect() {
    _notifySub?.cancel();
    _notifySub = null;
    _telemetryChar = null;
    _commandChar = null;
    _device = null;
    _rxBuffer.clear();
  }

  void dispose() {
    _notifySub?.cancel();
    _connSub?.cancel();
    _telemetryController.close();
    _connectionController.close();
  }
}
