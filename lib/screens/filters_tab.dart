import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../widgets/platform_card.dart';
import '../widgets/global_settings_card.dart';

class FiltersTab extends StatelessWidget {
  const FiltersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1A1A1A)),
          ),
          child: const Row(children: [
            Text('⚡', style: TextStyle(fontSize: 14)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ride aane par automatically filter check hoga — match karne par accept',
                style: TextStyle(color: Color(0xFF555555), fontSize: 12),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        const PlatformCard(platformKey: 'rapido'),
        const PlatformCard(platformKey: 'ola'),
        const PlatformCard(platformKey: 'uber'),
        const SizedBox(height: 8),
        const GlobalSettingsCard(),
      ],
    );
  }
}
