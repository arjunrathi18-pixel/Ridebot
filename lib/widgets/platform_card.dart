import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';

const _meta = {
  'rapido': {'name': 'Rapido', 'icon': '🏍️', 'color': Color(0xFFFFCC00)},
  'ola':    {'name': 'Ola',    'icon': '🚗',  'color': Color(0xFF25D366)},
  'uber':   {'name': 'Uber',   'icon': '🚙',  'color': Color(0xFF276EF1)},
};

const _types = {
  'rapido': ['Bike', 'Auto', 'Cab Economy'],
  'ola':    ['Mini', 'Auto', 'Prime Sedan', 'Prime SUV', 'Bike'],
  'uber':   ['UberGo', 'UberAuto', 'Moto', 'Premier', 'UberXL'],
};

class PlatformCard extends StatelessWidget {
  final String platformKey;
  const PlatformCard({super.key, required this.platformKey});

  @override
  Widget build(BuildContext context) {
    final state  = context.watch<AppState>();
    final config = state.platforms[platformKey]!;
    final meta   = _meta[platformKey]!;
    final color  = meta['color'] as Color;
    final types  = _types[platformKey]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [const Color(0xFF1A1A1A), Color.lerp(const Color(0xFF111111), color, 0.04)!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Text(meta['icon'] as String, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(meta['name'] as String,
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
            Text(config.enabled ? 'Active' : 'Disabled',
                style: const TextStyle(color: Color(0xFF555555), fontSize: 11)),
          ])),
          _Toggle(value: config.enabled, color: color, onChanged: (v) => _update(context, platformKey, config, enabled: v)),
        ]),

        if (config.enabled) ...[
          const SizedBox(height: 20),

          // Price range (min + max) — 30 to 3000
          const Text('💰 Price Range', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12)),
          const SizedBox(height: 10),
          _RangeRow(
            minVal: config.minPrice, maxVal: config.maxPrice,
            absMin: 30, absMax: 3000,
            divisions: 297,
            unit: '₹', color: color,
            onMinChanged: (v) => _update(context, platformKey, config, minPrice: v),
            onMaxChanged: (v) => _update(context, platformKey, config, maxPrice: v),
          ),
          const SizedBox(height: 20),

          // Distance range — 0 to 200
          const Text('📍 Distance Range', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12)),
          const SizedBox(height: 10),
          _RangeRow(
            minVal: config.minKm, maxVal: config.maxKm,
            absMin: 0, absMax: 200,
            divisions: 200,
            unit: ' km', color: color,
            onMinChanged: (v) => _update(context, platformKey, config, minKm: v),
            onMaxChanged: (v) => _update(context, platformKey, config, maxKm: v),
          ),
          const SizedBox(height: 20),

          // Ride types
          const Text('🏷️ Ride Types', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: types.map((type) {
              final sel = config.rideTypes.contains(type);
              return GestureDetector(
                onTap: () {
                  final nt = List<String>.from(config.rideTypes);
                  sel ? nt.remove(type) : nt.add(type);
                  _update(context, platformKey, config, rideTypes: nt);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? color.withOpacity(0.15) : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? color : const Color(0xFF333333)),
                  ),
                  child: Text(type,
                      style: TextStyle(
                        color: sel ? color : const Color(0xFF666666),
                        fontSize: 12, fontWeight: FontWeight.w600,
                      )),
                ),
              );
            }).toList(),
          ),
        ],
      ]),
    );
  }

  void _update(BuildContext ctx, String key, PlatformConfig c, {
    bool?   enabled,
    double? minPrice, double? maxPrice,
    double? minKm,   double? maxKm,
    List<String>? rideTypes,
  }) {
    ctx.read<AppState>().updatePlatform(key, PlatformConfig(
      enabled:   enabled   ?? c.enabled,
      minPrice:  minPrice  ?? c.minPrice,
      maxPrice:  maxPrice  ?? c.maxPrice,
      minKm:     minKm     ?? c.minKm,
      maxKm:     maxKm     ?? c.maxKm,
      rideTypes: rideTypes ?? c.rideTypes,
    ));
  }
}

// ── Range row: two sliders side by side ──────────────────────
class _RangeRow extends StatelessWidget {
  final double minVal, maxVal, absMin, absMax;
  final int divisions;
  final String unit;
  final Color color;
  final ValueChanged<double> onMinChanged, onMaxChanged;

  const _RangeRow({
    required this.minVal, required this.maxVal,
    required this.absMin, required this.absMax,
    required this.divisions,
    required this.unit, required this.color,
    required this.onMinChanged, required this.onMaxChanged,
  });

  @override
  Widget build(BuildContext ctx) => Column(
    children: [
      Row(children: [
        Expanded(child: Column(children: [
          Text('Min: ${minVal.round()}$unit',
              style: TextStyle(color: color, fontSize: 12, fontFamily: 'monospace')),
          SliderTheme(
            data: _sliderTheme(ctx, color),
            child: Slider(
              value: minVal.clamp(absMin, maxVal - 1),
              min: absMin, max: maxVal - 1,
              divisions: (maxVal - absMin).round().clamp(1, 9999),
              onChanged: onMinChanged,
            ),
          ),
        ])),
        const SizedBox(width: 8),
        Expanded(child: Column(children: [
          Text('Max: ${maxVal.round()}$unit',
              style: TextStyle(color: color, fontSize: 12, fontFamily: 'monospace')),
          SliderTheme(
            data: _sliderTheme(ctx, color),
            child: Slider(
              value: maxVal.clamp(minVal + 1, absMax),
              min: minVal + 1, max: absMax,
              divisions: (absMax - minVal).round().clamp(1, 9999),
              onChanged: onMaxChanged,
            ),
          ),
        ])),
      ]),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${absMin.round()}$unit', style: const TextStyle(color: Color(0xFF444444), fontSize: 10)),
          Text('${absMax.round()}$unit', style: const TextStyle(color: Color(0xFF444444), fontSize: 10)),
        ]),
      ),
    ],
  );

  SliderThemeData _sliderTheme(BuildContext ctx, Color c) =>
      SliderTheme.of(ctx).copyWith(
        trackHeight: 3,
        activeTrackColor: c,
        inactiveTrackColor: const Color(0xFF2A2A2A),
        thumbColor: c,
        overlayColor: c.withOpacity(0.15),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      );
}

class _Toggle extends StatelessWidget {
  final bool value; final Color color; final ValueChanged<bool> onChanged;
  const _Toggle({required this.value, required this.color, required this.onChanged});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 46, height: 26,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: value ? color : const Color(0xFF333333)),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 250),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.all(3), width: 20, height: 20,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        ),
      ),
    ),
  );
}
