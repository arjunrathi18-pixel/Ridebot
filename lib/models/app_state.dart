import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ── Saved Location model ─────────────────────────────────────
class SavedLocation {
  final String id;
  String name;
  String area;         // keyword for text match (e.g. "Koramangala")
  double lat;
  double lng;
  int    radiusKm;
  bool   enabled;

  SavedLocation({
    required this.id,
    required this.name,
    this.area    = '',
    this.lat     = 0,
    this.lng     = 0,
    this.radiusKm = 3,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'area': area,
    'lat': lat, 'lng': lng, 'radiusKm': radiusKm, 'enabled': enabled,
  };

  factory SavedLocation.fromJson(Map<String, dynamic> j) => SavedLocation(
    id:       j['id']       ?? '',
    name:     j['name']     ?? '',
    area:     j['area']     ?? '',
    lat:      (j['lat']     ?? 0.0).toDouble(),
    lng:      (j['lng']     ?? 0.0).toDouble(),
    radiusKm: j['radiusKm'] ?? 3,
    enabled:  j['enabled']  ?? true,
  );
}

// ── Platform config ──────────────────────────────────────────
class PlatformConfig {
  bool   enabled;
  double minPrice;
  double maxPrice;
  double minKm;
  double maxKm;
  List<String> rideTypes;

  PlatformConfig({
    required this.enabled,
    this.minPrice  = 50,
    this.maxPrice  = 3000,
    this.minKm     = 0,
    this.maxKm     = 200,
    required this.rideTypes,
  });

  Map<String, dynamic> toMap(String platform) => {
    'platform':  platform,
    'enabled':   enabled,
    'minPrice':  minPrice,
    'maxPrice':  maxPrice,
    'minKm':     minKm,
    'maxKm':     maxKm,
    'rideTypes': rideTypes.join(','),
  };
}

// ── Log entry ────────────────────────────────────────────────
class LogEntry {
  final String type;
  final String msg;
  final DateTime time;
  LogEntry({required this.type, required this.msg, required this.time});
}

// ── Stats ────────────────────────────────────────────────────
class Stats {
  int    accepted = 0;
  int    rejected = 0;
  double earnings = 0;
}

// ════════════════════════════════════════════════════════════════
//  AppState
// ════════════════════════════════════════════════════════════════
class AppState extends ChangeNotifier {

  static const _mc = MethodChannel('com.ridebot/control');
  static const _ec = EventChannel('com.ridebot/logs');

  bool accessibilityEnabled = false;
  bool overlayEnabled       = false;
  bool automationRunning    = false;

  // ── Saved locations (max 5) ───────────────────────────────────
  List<SavedLocation> savedLocations = [];
  bool locationFilterEnabled = false;

  // ── Platform configs ──────────────────────────────────────────
  Map<String, PlatformConfig> platforms = {
    'rapido': PlatformConfig(enabled: false, minPrice: 60,  maxPrice: 3000, minKm: 0, maxKm: 20,  rideTypes: ['Bike','Auto']),
    'ola':    PlatformConfig(enabled: false, minPrice: 80,  maxPrice: 3000, minKm: 0, maxKm: 25,  rideTypes: ['Mini','Auto']),
    'uber':   PlatformConfig(enabled: false, minPrice: 100, maxPrice: 3000, minKm: 0, maxKm: 30,  rideTypes: ['UberGo','UberAuto']),
  };

  // ── Global ────────────────────────────────────────────────────
  bool autoStartOnBoot = false;
  bool nightMode       = false;
  bool soundOnAccept   = true;
  bool surgeAccept     = true;

  // ── Logs & Stats ─────────────────────────────────────────────
  final List<LogEntry> logs  = [];
  final Stats          stats = Stats();
  StreamSubscription?  _logSub;

  AppState() { _init(); }

  Future<void> _init() async {
    await checkPermissions();
    await loadSettings();
    _listenToLogs();
  }

  // ────────────────────────────────────────────────────────────
  //  Permissions
  // ────────────────────────────────────────────────────────────
  Future<void> checkPermissions() async {
    try {
      accessibilityEnabled = await _mc.invokeMethod('isAccessibilityEnabled') ?? false;
      overlayEnabled       = await _mc.invokeMethod('hasOverlayPermission')   ?? false;
    } catch (_) {}
    notifyListeners();
  }
  Future<void> openAccessibilitySettings() => _mc.invokeMethod('openAccessibilitySettings');
  Future<void> openOverlayPermission()     => _mc.invokeMethod('openOverlayPermission');

  // ────────────────────────────────────────────────────────────
  //  Load settings
  // ────────────────────────────────────────────────────────────
  Future<void> loadSettings() async {
    try {
      final Map? s = await _mc.invokeMethod('getSettings');
      if (s == null) return;

      automationRunning      = s['automation_enabled']    ?? false;
      autoStartOnBoot        = s['auto_start_on_boot']    ?? false;
      nightMode              = s['night_mode']             ?? false;
      soundOnAccept          = s['sound_on_accept']        ?? true;
      surgeAccept            = s['surge_auto_accept']      ?? true;
      locationFilterEnabled  = s['location_filter_enabled']?? false;

      // Load saved locations
      final locStr = s['saved_locations'] as String? ?? '[]';
      try {
        final List decoded = jsonDecode(locStr);
        savedLocations = decoded.map((e) => SavedLocation.fromJson(Map<String,dynamic>.from(e))).toList();
      } catch (_) { savedLocations = []; }

      for (final plat in ['rapido','ola','uber']) {
        final typesStr = s['${plat}_ride_types'] as String? ?? '';
        platforms[plat] = PlatformConfig(
          enabled:   s['${plat}_enabled']   ?? false,
          minPrice: (s['${plat}_min_price'] ?? 50.0).toDouble(),
          maxPrice: (s['${plat}_max_price'] ?? 3000.0).toDouble(),
          minKm:    (s['${plat}_min_km']    ?? 0.0).toDouble(),
          maxKm:    (s['${plat}_max_km']    ?? 200.0).toDouble(),
          rideTypes: typesStr.isEmpty ? [] : typesStr.split(','),
        );
      }
    } catch (_) {}
    notifyListeners();
  }

  // ────────────────────────────────────────────────────────────
  //  Save
  // ────────────────────────────────────────────────────────────
  Future<void> setAutomation(bool v) async {
    automationRunning = v;
    await _mc.invokeMethod('setEnabled', {'enabled': v});
    _addLog(v ? 'info' : 'warn', v ? '🚀 Automation started — INSTANT MODE' : '⏹ Automation stopped');
    notifyListeners();
  }

  Future<void> updatePlatform(String key, PlatformConfig config) async {
    platforms[key] = config;
    await _mc.invokeMethod('savePlatformConfig', config.toMap(key));
    notifyListeners();
  }

  Future<void> saveGlobalSettings() async {
    await _mc.invokeMethod('saveGlobalSettings', {
      'autoStart':    autoStartOnBoot,
      'nightMode':    nightMode,
      'soundOnAccept':soundOnAccept,
      'surgeAccept':  surgeAccept,
    });
    notifyListeners();
  }

  // ── Location helpers ──────────────────────────────────────────
  Future<void> saveLocations() async {
    final jsonStr = jsonEncode(savedLocations.map((l) => l.toJson()).toList());
    await _mc.invokeMethod('saveLocations', {
      'locations': jsonStr,
      'locationFilterEnabled': locationFilterEnabled,
    });
    notifyListeners();
  }

  Future<void> addLocation(SavedLocation loc) async {
    if (savedLocations.length >= 5) return;
    savedLocations.add(loc);
    await saveLocations();
  }

  Future<void> removeLocation(String id) async {
    savedLocations.removeWhere((l) => l.id == id);
    await saveLocations();
  }

  Future<void> toggleLocation(String id, bool enabled) async {
    final loc = savedLocations.firstWhere((l) => l.id == id, orElse: () => SavedLocation(id:'', name:''));
    if (loc.id.isEmpty) return;
    loc.enabled = enabled;
    await saveLocations();
  }

  Future<void> updateDriverLocation(double lat, double lng) async {
    await _mc.invokeMethod('updateDriverLocation', {'lat': lat, 'lng': lng});
  }

  // ── Logs ─────────────────────────────────────────────────────
  void _listenToLogs() {
    _logSub = _ec.receiveBroadcastStream().listen((event) {
      final map = Map<String,dynamic>.from(event);
      _addLog(map['type'] ?? 'info', map['msg'] ?? '');
      if (map['type'] == 'accept') {
        stats.accepted++;
        final match = RegExp(r'₹(\d+)').firstMatch(map['msg'] ?? '');
        if (match != null) stats.earnings += double.tryParse(match.group(1)!) ?? 0;
      } else if (map['type'] == 'reject') {
        stats.rejected++;
      }
      notifyListeners();
    });
  }

  void _addLog(String type, String msg) {
    logs.add(LogEntry(type: type, msg: msg, time: DateTime.now()));
    if (logs.length > 300) logs.removeAt(0);
    notifyListeners();
  }

  @override
  void dispose() { _logSub?.cancel(); super.dispose(); }
}
