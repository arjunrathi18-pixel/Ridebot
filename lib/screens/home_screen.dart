import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import 'filters_tab.dart';
import 'live_tab.dart';
import 'stats_tab.dart';
import 'setup_tab.dart';
import 'location_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
  late TabController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 5, vsync: this);
    _tc.addListener(() => setState(() => _tab = _tc.index));
  }

  @override
  void dispose() { _tc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state    = context.watch<AppState>();
    final running  = state.automationRunning;
    final hasPerms = state.accessibilityEnabled && state.overlayEnabled;
    final enabled  = state.platforms.values.where((p) => p.enabled).length;
    final locCount = state.savedLocations.where((l) => l.enabled).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(children: [

          // ── Header ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A))),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: running ? const Color(0xFF00D46A) : const Color(0xFF555555),
                      boxShadow: running ? [BoxShadow(color: const Color(0xFF00D46A).withOpacity(0.6), blurRadius: 8, spreadRadius: 2)] : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    running ? '⚡ INSTANT MODE ACTIVE' : 'STOPPED',
                    style: TextStyle(
                      color: running ? const Color(0xFF00D46A) : const Color(0xFF666666),
                      fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5,
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                const Text('RideBot Pro',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                Row(children: [
                  Text('$enabled platform${enabled != 1 ? "s" : ""}',
                      style: const TextStyle(color: Color(0xFF555555), fontSize: 12)),
                  if (state.locationFilterEnabled && locCount > 0) ...[
                    const Text('  ·  ', style: TextStyle(color: Color(0xFF333333))),
                    Text('📍 $locCount loc${locCount != 1 ? "s" : ""}',
                        style: const TextStyle(color: Color(0xFF00D46A), fontSize: 12)),
                  ],
                ]),
              ])),

              // Start/Stop
              GestureDetector(
                onTap: () {
                  if (!hasPerms && !running) {
                    _tc.animateTo(4);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('⚠️ Pehle Setup tab mein permissions do'),
                      backgroundColor: Color(0xFFFF6600),
                    ));
                    return;
                  }
                  context.read<AppState>().setAutomation(!running);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: running
                        ? [const Color(0xFFFF2222), const Color(0xFFCC0000)]
                        : [const Color(0xFF00D46A), const Color(0xFF00A852)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                      color: (running ? const Color(0xFFFF2222) : const Color(0xFF00D46A)).withOpacity(0.35),
                      blurRadius: 12, offset: const Offset(0, 4),
                    )],
                  ),
                  child: Text(running ? '⏹ Stop' : '▶ Start',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ]),
          ),

          // ── Tabs ──────────────────────────────────────────────
          Container(
            color: const Color(0xFF0F0F0F),
            child: TabBar(
              controller: _tc,
              labelColor: const Color(0xFF00D46A),
              unselectedLabelColor: const Color(0xFF555555),
              indicatorColor: const Color(0xFF00D46A),
              indicatorSize: TabBarIndicatorSize.tab,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: '⚙️ Filters'),
                Tab(text: '📍 Location'),
                Tab(text: '📡 Live'),
                Tab(text: '📊 Stats'),
                Tab(text: '🔧 Setup'),
              ],
            ),
          ),

          // ── Content ───────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tc,
              children: const [
                FiltersTab(),
                LocationTab(),
                LiveTab(),
                StatsTab(),
                SetupTab(),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
