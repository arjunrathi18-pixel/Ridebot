import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';

class SetupTab extends StatelessWidget {
  const SetupTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final accessOk = state.accessibilityEnabled;
    final overlayOk = state.overlayEnabled;
    final allOk = accessOk && overlayOk;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: allOk
                  ? [const Color(0xFF001a08), const Color(0xFF002210)]
                  : [const Color(0xFF1a0a00), const Color(0xFF220e00)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: allOk ? const Color(0xFF00D46A33) : const Color(0xFFFF660033),
            ),
          ),
          child: Row(children: [
            Text(allOk ? '✅' : '⚠️', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  allOk ? 'Setup Complete!' : 'Setup Zaroori Hai',
                  style: TextStyle(
                    color: allOk ? const Color(0xFF00D46A) : const Color(0xFFFF6600),
                    fontWeight: FontWeight.w700, fontSize: 15,
                  ),
                ),
                Text(
                  allOk
                      ? 'RideBot kaam karne ke liye taiyar hai'
                      : '${!accessOk ? "Accessibility " : ""}${!accessOk && !overlayOk ? "& " : ""}${!overlayOk ? "Overlay " : ""}permission baaqi hai',
                  style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // Step 1: Accessibility
        _PermissionStep(
          stepNo: '1',
          title: 'Accessibility Service',
          description:
              'RideBot ko screen read karne ki permission chahiye taaki woh ride popups detect kar sake. '
              'Settings mein jaake "RideBot" dhundo aur enable karo.',
          icon: '♿',
          isDone: accessOk,
          buttonText: 'Accessibility Settings Kholo',
          onTap: () => state.openAccessibilitySettings(),
        ),
        const SizedBox(height: 12),

        // Step 2: Overlay
        _PermissionStep(
          stepNo: '2',
          title: 'Display Over Apps',
          description:
              'RideBot ko doosri apps ke upar button click karne ki permission chahiye. '
              '"Allow display over other apps" toggle ON karo.',
          icon: '🪟',
          isDone: overlayOk,
          buttonText: 'Overlay Permission Kholo',
          onTap: () => state.openOverlayPermission(),
        ),
        const SizedBox(height: 12),

        // Step 3: Battery
        _InfoStep(
          stepNo: '3',
          title: 'Battery Optimization Band Karo',
          description:
              'Settings → Apps → RideBot → Battery → "Unrestricted" select karo. '
              'Warna Android background mein service band kar dega.',
          icon: '🔋',
        ),
        const SizedBox(height: 12),

        // Step 4: Don't Kill My App tip
        _InfoStep(
          stepNo: '4',
          title: 'Background Activity',
          description:
              'Kuch phones (Xiaomi, Oppo, Vivo) background apps kill kar dete hain. '
              'Phone ke liye specific steps dontkillmyapp.com pe mil jayenge.',
          icon: '📱',
          link: 'dontkillmyapp.com',
        ),

        const SizedBox(height: 20),

        // Refresh button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => state.checkPermissions(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('🔄 Permission Status Refresh Karo'),
          ),
        ),

        const SizedBox(height: 24),

        // Supported apps
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A1A1A)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Supported Apps',
                style: TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _AppRow('🏍️', 'Rapido Driver', 'com.rapido.driver'),
            _AppRow('🚗', 'Ola Driver',    'com.olacabs.driver'),
            _AppRow('🚙', 'Uber Driver',   'com.ubercab.driver'),
          ]),
        ),
      ],
    );
  }
}

class _PermissionStep extends StatelessWidget {
  final String stepNo, title, description, icon, buttonText;
  final bool isDone;
  final VoidCallback onTap;

  const _PermissionStep({
    required this.stepNo, required this.title, required this.description,
    required this.icon, required this.isDone, required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone ? const Color(0xFF00D46A) : const Color(0xFFFF6600);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? const Color(0xFF00D46A22) : const Color(0xFF1A1A1A),
              border: Border.all(color: color),
            ),
            child: Center(
              child: Text(
                isDone ? '✓' : stepNo,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isDone ? 'Done ✓' : 'Pending',
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Text(description, style: const TextStyle(color: Color(0xFF666666), fontSize: 12, height: 1.5)),
        if (!isDone) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withOpacity(0.15),
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(buttonText, style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ]),
    );
  }
}

class _InfoStep extends StatelessWidget {
  final String stepNo, title, description, icon;
  final String? link;
  const _InfoStep({required this.stepNo, required this.title,
      required this.description, required this.icon, this.link});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A1A1A)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Center(
            child: Text(stepNo,
                style: const TextStyle(color: Color(0xFF555555), fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(
                  color: Color(0xFFCCCCCC), fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(color: Color(0xFF555555), fontSize: 12, height: 1.5)),
            if (link != null) ...[
              const SizedBox(height: 4),
              Text(link!, style: const TextStyle(color: Color(0xFF276EF1), fontSize: 11)),
            ],
          ]),
        ),
      ]),
    );
  }
}

Widget _AppRow(String icon, String name, String pkg) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Row(children: [
    Text(icon, style: const TextStyle(fontSize: 16)),
    const SizedBox(width: 8),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12)),
      Text(pkg, style: const TextStyle(color: Color(0xFF444444), fontSize: 10, fontFamily: 'monospace')),
    ]),
  ]),
);
