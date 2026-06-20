import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_controller.dart';
import '../models/game_record.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'game_screen.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final name = user?.displayName ?? 'Player';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(child: _Header(name: name, initials: user?.initials ?? '?')),

            // ── New Game card ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                child: _NewGameCard(name: name),
              ),
            ),

            // ── Game history ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 8),
                child: Row(
                  children: [
                    const Text('Recent Games',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B2B4B))),
                    const Spacer(),
                    // FIREBASE: replace Consumer with StreamBuilder on
                    // FirestoreService.watchGameHistory(uid) for real-time updates.
                  ],
                ),
              ),
            ),

            // Reactive list — rebuilds whenever FirestoreService notifies
            // (e.g. after a game is saved).
            if (user != null)
              Consumer<FirestoreService>(
                builder: (ctx, fs, _) {
                  final games = fs.getGameHistory(user.id);
                  if (games.isEmpty) {
                    return const SliverToBoxAdapter(child: _EmptyHistory());
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 5),
                        child: _GameCard(record: games[i]),
                      ),
                      childCount: games.length,
                    ),
                  );
                },
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String name;
  final String initials;
  const _Header({required this.name, required this.initials});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_greeting,',
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8899BB),
                        fontWeight: FontWeight.w500)),
                Text(name,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B2B4B))),
              ],
            ),
          ),
          _Avatar(initials: initials),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFF1B2B4B),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── New Game card ─────────────────────────────────────────────────────────────
class _NewGameCard extends StatelessWidget {
  final String name;
  const _NewGameCard({required this.name});

  void _startGame(BuildContext context) {
    context.read<GameController>().newGame();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _startGame(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2B4B),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x30000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New Game',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('54 cards · Trump · Musk · Second Wind',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.55),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
      child: Column(
        children: [
          Text('🃏',
              style: TextStyle(
                  fontSize: 48,
                  color: const Color(0xFF1B2B4B).withOpacity(0.15))),
          const SizedBox(height: 12),
          Text('No games yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1B2B4B).withOpacity(0.4))),
          const SizedBox(height: 4),
          Text('Tap New Game to start your first match',
              style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF1B2B4B).withOpacity(0.25))),
        ],
      ),
    );
  }
}

// ── Game history card ─────────────────────────────────────────────────────────
class _GameCard extends StatelessWidget {
  final GameRecord record;
  const _GameCard({required this.record});

  Color get _accentColor {
    if (record.isOngoing)     return const Color(0xFF0284C7);
    if (record.player1Won)    return const Color(0xFF16A34A);
    if (record.player2Won)    return const Color(0xFFDC2626);
    return const Color(0xFF8899BB);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Accent bar
            Container(width: 4, color: accent),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: players + date
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${record.player1Name} vs ${record.player2Name}',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B2B4B)),
                          ),
                        ),
                        Text(record.relativeDate,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8899BB),
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 7),
                    // Middle row: result badge + stats
                    Row(
                      children: [
                        _ResultBadge(label: record.resultLabel, color: accent),
                        const SizedBox(width: 10),
                        _StatPill(
                            icon: Icons.repeat_rounded,
                            text: '${record.roundsPlayed}r'),
                        const SizedBox(width: 6),
                        _StatPill(
                            icon: Icons.local_fire_department_outlined,
                            text: '${record.totalWars}⚔'),
                      ],
                    ),
                    if (record.trumpSuit != null || record.muskRank != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (record.trumpSuit != null)
                            _Tag(
                                text: '👑 ${record.trumpSuit}',
                                color: const Color(0xFFF59E0B)),
                          if (record.trumpSuit != null && record.muskRank != null)
                            const SizedBox(width: 6),
                          if (record.muskRank != null)
                            _Tag(
                                text: '🔥 ${_rankLabel(record.muskRank!)}',
                                color: const Color(0xFF7C3AED)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _rankLabel(int r) => {
        11: 'J', 12: 'Q', 13: 'K', 14: 'A',
      }[r] ?? '$r';
}

class _ResultBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ResultBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5)),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _StatPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF8899BB)),
        const SizedBox(width: 3),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8899BB),
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }
}