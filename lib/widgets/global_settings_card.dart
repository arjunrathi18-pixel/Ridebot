import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';

class GlobalSettingsCard extends StatelessWidget {
  const GlobalSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final settings = [
      (
        label: 'Surge Auto-Accept',
        sub: '1.5x+ surge rides bhi accept karo',
        value: state.surgeAccept,
        onChanged: (v) { state.surgeAccept = v; state.saveGlobalSettings(); },
      ),
      (
        label: 'Night Mode (10PM–6AM)',
        sub: 'Raat mein sirf premium rides accept',
        value: state.nightMode,
        onChanged: (v) { state.nightMode = v; state.saveGlobalSettings(); },
      ),
      (
        label: 'Sound on Accept',
        sub: 'Accept hone par beep bajaye',
        value: state.soundOnAccept,
        onChanged: (v) { state.soundOnAccept = v; state.saveGlobalSettings(); },
      ),
      (
        label: 'Auto-start on Boot',
        sub: 'Phone on hote hi automation shuru ho',
        value: state.autoStartOnBoot,
        onChanged: (v) { state.autoStartOnBoot = v; state.saveGlobalSettings(); },
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A1A1A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔧 Global Settings',
              style: TextStyle(color: Color(0xFF888888), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ...settings.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return Column(
              children: [
                if (i > 0)
                  const Divider(color: Color(0xFF1A1A1A), height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.label,
                              style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 13)),
                          Text(s.sub,
                              style: const TextStyle(color: Color(0xFF555555), fontSize: 11)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => s.onChanged(!s.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 46, height: 26,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          color: s.value ? const Color(0xFF00D46A) : const Color(0xFF333333),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 250),
                          alignment: s.value ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            width: 20, height: 20,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
