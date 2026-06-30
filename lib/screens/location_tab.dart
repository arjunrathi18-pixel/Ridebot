import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';

class LocationTab extends StatefulWidget {
  const LocationTab({super.key});
  @override
  State<LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<LocationTab> {

  void _showAddDialog(BuildContext ctx) {
    final state = ctx.read<AppState>();
    if (state.savedLocations.length >= 5) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Maximum 5 locations save kar sakte ho'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final nameCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final latCtrl  = TextEditingController();
    final lngCtrl  = TextEditingController();
    int radius = 3;

    showDialog(
      context: ctx,
      barrierColor: Colors.black87,
      builder: (_) => StatefulBuilder(
        builder: (bCtx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('📍 New Location Add Karo',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // Name
              _field(nameCtrl, 'Location Name', 'e.g. Home, Office, Station'),
              const SizedBox(height: 12),

              // Area keyword
              _field(areaCtrl, 'Area Keyword (for text match)',
                  'e.g. Koramangala, Sector 18'),
              const SizedBox(height: 4),
              const Text(
                'Pickup address mein yeh word hoga toh accept hoga',
                style: TextStyle(color: Color(0xFF555555), fontSize: 11),
              ),
              const SizedBox(height: 16),

              const Divider(color: Color(0xFF2A2A2A)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('OR — GPS Coordinates (optional)',
                    style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
              ),

              // GPS
              Row(children: [
                Expanded(child: _field(latCtrl, 'Latitude',  '28.6139')),
                const SizedBox(width: 10),
                Expanded(child: _field(lngCtrl, 'Longitude', '77.2090')),
              ]),
              const SizedBox(height: 12),

              // Radius
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('GPS Radius: ${radius}km',
                    style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12)),
                Slider(
                  value: radius.toDouble(), min: 1, max: 20,
                  divisions: 19,
                  activeColor: const Color(0xFF00D46A),
                  inactiveColor: const Color(0xFF2A2A2A),
                  onChanged: (v) => setS(() => radius = v.round()),
                ),
              ]),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(bCtx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF555555))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D46A),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final loc = SavedLocation(
                  id:       DateTime.now().millisecondsSinceEpoch.toString(),
                  name:     nameCtrl.text.trim(),
                  area:     areaCtrl.text.trim(),
                  lat:      double.tryParse(latCtrl.text) ?? 0,
                  lng:      double.tryParse(lngCtrl.text) ?? 0,
                  radiusKm: radius,
                  enabled:  true,
                );
                ctx.read<AppState>().addLocation(loc);
                Navigator.pop(bCtx);
              },
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final locs  = state.savedLocations;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // ── Master toggle ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: state.locationFilterEnabled
                  ? [const Color(0xFF001a08), const Color(0xFF002210)]
                  : [const Color(0xFF111111), const Color(0xFF0d0d0d)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: state.locationFilterEnabled
                  ? const Color(0xFF00D46A44)
                  : const Color(0xFF1A1A1A),
            ),
          ),
          child: Row(children: [
            const Text('📍', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Location Filter',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                Text(
                  state.locationFilterEnabled
                      ? 'Sirf saved locations ke paas aane wali rides accept hongi'
                      : 'OFF — saari locations ki rides accept hongi',
                  style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
                ),
              ]),
            ),
            _Toggle(
              value: state.locationFilterEnabled,
              color: const Color(0xFF00D46A),
              onChanged: (v) {
                state.locationFilterEnabled = v;
                state.saveLocations();
              },
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // ── Locations list ───────────────────────────────────────
        Row(children: [
          const Text('Saved Locations',
              style: TextStyle(color: Color(0xFF888888), fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(
            '${locs.length}/5',
            style: TextStyle(
              color: locs.length >= 5 ? const Color(0xFFFF6600) : const Color(0xFF555555),
              fontSize: 12,
            ),
          ),
        ]),
        const SizedBox(height: 12),

        if (locs.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1A1A1A), style: BorderStyle.solid),
            ),
            child: Column(children: [
              const Text('🗺️', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 12),
              const Text('Koi location saved nahi',
                  style: TextStyle(color: Color(0xFF555555), fontSize: 14)),
              const SizedBox(height: 6),
              const Text('Niche + button se add karo',
                  style: TextStyle(color: Color(0xFF333333), fontSize: 12)),
            ]),
          )
        else
          ...locs.asMap().entries.map((entry) => _LocationCard(
            loc: entry.value,
            index: entry.key + 1,
            onToggle: (v) => context.read<AppState>().toggleLocation(entry.value.id, v),
            onDelete: () => context.read<AppState>().removeLocation(entry.value.id),
          )),

        const SizedBox(height: 16),

        // ── Add button ───────────────────────────────────────────
        if (locs.length < 5)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add_location_alt, color: Color(0xFF00D46A)),
              label: const Text('Location Add Karo',
                  style: TextStyle(color: Color(0xFF00D46A), fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF00D46A44)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

        const SizedBox(height: 24),

        // ── How it works ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A1A2E)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💡 Kaise Kaam Karta Hai',
                style: TextStyle(color: Color(0xFF276EF1), fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...[
              '📍 Area keyword: Pickup address mein word match hoga',
              '🛰️ GPS radius: Aap jis area mein ho, usske 3km ke rides',
              '🔢 5 locations tak save kar sakte ho',
              '🔘 Har location ko alag ON/OFF kar sakte ho',
              '📋 Koi location enabled nahi = location filter ignore hoga',
            ].map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(t, style: const TextStyle(color: Color(0xFF555555), fontSize: 12, height: 1.4)),
            )),
          ]),
        ),
      ],
    );
  }
}

// ── Location Card ────────────────────────────────────────────
class _LocationCard extends StatelessWidget {
  final SavedLocation loc;
  final int index;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _LocationCard({
    required this.loc, required this.index,
    required this.onToggle, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF00D46A);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: loc.enabled ? const Color(0xFF00D46A33) : const Color(0xFF1A1A1A),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: loc.enabled ? const Color(0xFF00D46A22) : const Color(0xFF1A1A1A),
              border: Border.all(
                  color: loc.enabled ? activeColor : const Color(0xFF333333)),
            ),
            child: Center(
              child: Text('$index',
                  style: TextStyle(
                    color: loc.enabled ? activeColor : const Color(0xFF555555),
                    fontSize: 12, fontWeight: FontWeight.w700,
                  )),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              loc.name,
              style: TextStyle(
                color: loc.enabled ? Colors.white : const Color(0xFF666666),
                fontWeight: FontWeight.w700, fontSize: 14,
              ),
            ),
          ),
          _Toggle(value: loc.enabled, color: activeColor, onChanged: onToggle),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A1A),
                  title: const Text('Delete?', style: TextStyle(color: Colors.white)),
                  content: Text('"${loc.name}" delete karna chahte ho?',
                      style: const TextStyle(color: Color(0xFF888888))),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Color(0xFF555555)))),
                    TextButton(onPressed: () { Navigator.pop(context); onDelete(); },
                        child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
            },
            child: const Icon(Icons.delete_outline, color: Color(0xFF444444), size: 20),
          ),
        ]),
        const SizedBox(height: 10),
        // Area keyword
        if (loc.area.isNotEmpty)
          _Tag('🔤 Keyword: "${loc.area}"', const Color(0xFFFFCC00)),
        // GPS
        if (loc.lat != 0 && loc.lng != 0) ...[
          const SizedBox(height: 6),
          _Tag(
            '🛰️ GPS: ${loc.lat.toStringAsFixed(4)}, ${loc.lng.toStringAsFixed(4)} · ${loc.radiusKm}km radius',
            const Color(0xFF276EF1),
          ),
        ],
        if (loc.area.isEmpty && loc.lat == 0)
          _Tag('⚠️ No match criteria — add keyword or GPS', const Color(0xFFFF6600)),
      ]),
    );
  }
}

Widget _Tag(String text, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  decoration: BoxDecoration(
    color: color.withOpacity(0.08),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: color.withOpacity(0.2)),
  ),
  child: Text(text, style: TextStyle(color: color, fontSize: 11)),
);

Widget _field(TextEditingController ctrl, String label, String hint) =>
    TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 12),
        hintStyle: const TextStyle(color: Color(0xFF444444), fontSize: 12),
        filled: true, fillColor: const Color(0xFF0D0D0D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00D46A)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );

class _Toggle extends StatelessWidget {
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.value, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 46, height: 26,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: value ? color : const Color(0xFF333333),
      ),
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
