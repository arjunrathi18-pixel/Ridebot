// ════════════════════════════════════════════════════════════
//  stats_tab.dart
// ════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  static const _platforms = ['rapido', 'ola', 'uber'];
  static const _icons = {'rapido': '🏍️', 'ola': '🚗', 'uber': '🚙'};
  static const _colors = {
    'rapido': Color(0xFFFFCC00),
    'ola':    Color(0xFF25D366),
    'uber':   Color(0xFF276EF1),
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.stats;
    final total = s.accepted + s.rejected;
    final rate = total > 0 ? (s.accepted / total * 100).round() : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Top stats ───────────────────────────────────────────
        Row(children: [
          _StatCard('✓', s.accepted.toString(), 'Accepted', const Color(0xFF00D46A)),
          const SizedBox(width: 10),
          _StatCard('✗', s.rejected.toString(), 'Rejected', const Color(0xFFFF4444)),
          const SizedBox(width: 10),
          _StatCard('₹', '${s.earnings.round()}', 'Earned', const Color(0xFFFFCC00)),
        ]),
        const SizedBox(height: 14),

        // ── Acceptance rate ─────────────────────────────────────
        _Card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Acceptance Rate',
                style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rate / 100,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF222222),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF00D46A)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                total > 0 ? '$rate%' : '—',
                style: const TextStyle(
                  color: Color(0xFF00D46A),
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  fontSize: 18,
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 12),

        // ── Per-platform ────────────────────────────────────────
        const Text('Platform Filters',
            style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
        const SizedBox(height: 10),
        ..._platforms.map((plat) {
          final config = state.platforms[plat]!;
          final color  = _colors[plat]!;
          final icon   = _icons[plat]!;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: config.enabled ? color.withOpacity(0.25) : const Color(0xFF1A1A1A),
              ),
            ),
            child: Row(children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    plat[0].toUpperCase() + plat.substring(1),
                    style: TextStyle(
                      color: config.enabled ? color : const Color(0xFF555555),
                      fontWeight: FontWeight.w700, fontSize: 14,
                    ),
                  ),
                  Text(
                    '${config.rideTypes.length} types  •  Min ₹${config.minPrice.round()}  •  Max ${config.maxKm.round()}km',
                    style: const TextStyle(color: Color(0xFF555555), fontSize: 11),
                  ),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: config.enabled ? color.withOpacity(0.12) : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  config.enabled ? 'ON' : 'OFF',
                  style: TextStyle(
                    color: config.enabled ? color : const Color(0xFF555555),
                    fontSize: 11, fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ]),
          );
        }),
      ],
    );
  }
}

Widget _StatCard(String icon, String value, String label, Color color) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
              color: color, fontSize: 22,
              fontWeight: FontWeight.w800, fontFamily: 'monospace',
            )),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF555555), fontSize: 10)),
      ]),
    ),
  );
}

Widget _Card({required Widget child}) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: const Color(0xFF111111),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFF1A1A1A)),
  ),
  child: child,
);
