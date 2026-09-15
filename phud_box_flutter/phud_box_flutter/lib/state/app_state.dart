import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/batch.dart';
import '../services/ble_service.dart';
import '../services/db_service.dart';

enum DeviceStatus { idle, disinfecting }

class AppState extends ChangeNotifier {
  final BleService ble = BleService();
  final DBService db = DBService.instance;

  StreamSubscription<Map<String, dynamic>>? _msgSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  Timer? _localTicker;

  BluetoothConnectionState connectionState = BluetoothConnectionState.disconnected;
  String? connectionError;

  int battery = 0;
  DeviceStatus status = DeviceStatus.idle;
  bool doorOpen = true;
  int chamberSlotsLeft = 3;
  int secondsLeft = 0;
  ActiveBatch? activeBatch;
  final List<BatchLog> logs = [];

  AppState() {
    _loadPersistedLogs();
  }

  Future<void> _loadPersistedLogs() async {
    final persisted = await db.getLogs();
    logs
      ..clear()
      ..addAll(persisted);
    notifyListeners();
  }

  bool get isConnected => connectionState == BluetoothConnectionState.connected;

  Stream<List<ScanResult>> scan() => ble.scan();
  Future<void> stopScan() => ble.stopScan();

  Future<void> connect(BluetoothDevice device) async {
    connectionError = null;
    notifyListeners();
    try {
      await ble.connect(device);
      _connSub = ble.connectionState.listen((s) {
        connectionState = s;
        if (s == BluetoothConnectionState.disconnected) {
          _localTicker?.cancel();
        }
        notifyListeners();
      });
      _msgSub = ble.messages.listen(_onMessage);
    } catch (e) {
      connectionError = e.toString();
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await ble.disconnect();
    _msgSub?.cancel();
    _connSub?.cancel();
    _localTicker?.cancel();
  }

  void _onMessage(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == 'telemetry') {
      battery = json['battery'] as int? ?? battery;
      status = (json['status'] as String? ?? 'idle') == 'disinfecting'
          ? DeviceStatus.disinfecting
          : DeviceStatus.idle;
      doorOpen = json['door_open'] as bool? ?? doorOpen;
      chamberSlotsLeft = json['chamber_slots_left'] as int? ?? chamberSlotsLeft;
      secondsLeft = json['seconds_left'] as int? ?? secondsLeft;
      activeBatch = json['active_batch'] != null
          ? ActiveBatch.fromJson(json['active_batch'] as Map<String, dynamic>)
          : null;

      _restartLocalTicker();
      notifyListeners();
    } else if (type == 'log_entry') {
      final log = BatchLog.fromJson(json);
      logs.insert(0, log);
      db.insertLog(log);
      notifyListeners();
    }
  }

  /// The device only needs to push telemetry periodically (e.g. once a
  /// second); this local ticker smooths the countdown between updates and
  /// resyncs whenever a fresh telemetry frame arrives.
  void _restartLocalTicker() {
    _localTicker?.cancel();
    if (status != DeviceStatus.disinfecting) return;
    _localTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsLeft > 0) {
        secondsLeft -= 1;
        notifyListeners();
      }
    });
  }

  Future<void> startCycle() => ble.startCycle();
  Future<void> endCycle() => ble.endCycle();

  Future<void> clearLogs() async {
    logs.clear();
    await db.clearAll();
    notifyListeners();
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _connSub?.cancel();
    _localTicker?.cancel();
    ble.dispose();
    super.dispose();
  }
}
