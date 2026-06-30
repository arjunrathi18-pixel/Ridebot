import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';

class LiveTab extends StatefulWidget {
  const LiveTab({super.key});
  @override
  State<LiveTab> createState() => _LiveTabState();
}

class _LiveTabState extends State<LiveTab> {
  final ScrollController _scroll = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-scroll to bottom when new log comes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _logColor(String type) {
    return switch (type) {
      'accept' => const Color(0xFF00D46A),
      'reject' => const Color(0xFFFF4444),
      'warn'   => const Color(0xFFFFCC00),
      _        => const Color(0xFF444444),
    };
  }

  String _logIcon(String type) {
    return switch (type) {
      'accept' => '✓',
      'reject' => '✗',
      'warn'   => '⚠',
      _        => '→',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final logs = state.logs;
    final running = state.automationRunning;

    return Column(
      children: [
        // Status bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF0D0D0D),
          child: Row(children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: running ? const Color(0xFFFF4444) : const Color(0xFF333333),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              running ? 'LIVE — rides scan ho rahe hain...' : 'Automation start karo logs dekhne ke liye',
              style: TextStyle(
                color: running ? const Color(0xFF888888) : const Color(0xFF444444),
                fontSize: 12,
              ),
            ),
            const Spacer(),
            if (logs.isNotEmpty)
              GestureDetector(
                onTap: () {
                  state.logs.clear();
                  state.notifyListeners();
                },
                child: const Text('Clear', style: TextStyle(color: Color(0xFF333333), fontSize: 12)),
              ),
          ]),
        ),

        // Log terminal
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1A1A1A)),
            ),
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'Koi activity nahi abhi...\nAutomation start karo ▶',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF333333), fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    itemCount: logs.length,
                    itemBuilder: (_, i) {
                      final e = logs[i];
                      final color = _logColor(e.type);
                      final icon  = _logIcon(e.type);
                      final timeStr =
                          '${e.time.hour.toString().padLeft(2, '0')}:'
                          '${e.time.minute.toString().padLeft(2, '0')}:'
                          '${e.time.second.toString().padLeft(2, '0')}';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                            children: [
                              TextSpan(
                                text: '[$timeStr] ',
                                style: const TextStyle(color: Color(0xFF333333)),
                              ),
                              TextSpan(
                                text: '$icon ',
                                style: TextStyle(color: color),
                              ),
                              TextSpan(
                                text: e.msg,
                                style: TextStyle(color: color),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),

        // Recent cards
        if (logs.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Recent Activity',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: logs.reversed.take(5).length,
              itemBuilder: (_, i) {
                final e = logs.reversed.toList()[i];
                final color = _logColor(e.type);
                return Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 10, bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(left: BorderSide(color: color, width: 3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.type == 'accept' ? '✅ Accepted' : e.type == 'reject' ? '❌ Skipped' : 'ℹ️ Info',
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(e.msg, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 11),
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Text(
                        '${e.time.hour}:${e.time.minute.toString().padLeft(2,"0")}',
                        style: const TextStyle(color: Color(0xFF444444), fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
