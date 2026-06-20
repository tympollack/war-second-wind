import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/achievement.dart';
import '../game/game_controller.dart';
import '../widgets/achievement_toast.dart';
import '../widgets/card_widget.dart';

// ══════════════════════════════════════════════════════════════════════════════
// GameScreen
// ══════════════════════════════════════════════════════════════════════════════
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // ── Slide animation (cards entering the battle zone) ──────────────────────
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _p1Slide;
  late final Animation<Offset> _p2Slide;

  // ── Achievement toast queue ────────────────────────────────────────────────
  GameController? _game;
  final Queue<Achievement> _toastQueue = Queue();
  bool _showingToast = false;

  @override
  void initState() {
    super.initState();

    // value:1.0 → animation starts at rest (Offset.zero); forward(from:0)
    // will replay the slide-in each time the user taps.
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: 1.0,
    );
    _p1Slide = Tween<Offset>(
      begin: const Offset(0.9, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _p2Slide = Tween<Offset>(
      begin: const Offset(-0.9, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _game = context.read<GameController>();
      _game!.addListener(_onGameChanged);
    });
  }

  @override
  void dispose() {
    _game?.removeListener(_onGameChanged);
    _slideCtrl.dispose();
    super.dispose();
  }

  void _onGameChanged() {
    if (!mounted) return;
    final game = _game;
    if (game == null) return;
    for (final a in game.newlyUnlocked) {
      _toastQueue.add(a);
    }
    game.clearNewlyUnlocked();
    if (!_showingToast) _showNextToast();
  }

  void _showNextToast() {
    if (!mounted || _toastQueue.isEmpty) {
      _showingToast = false;
      return;
    }
    _showingToast = true;
    final achievement = _toastQueue.removeFirst();
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      _showingToast = false;
      return;
    }
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => AchievementToast(
        achievement: achievement,
        onDismissed: () {
          if (entry.mounted) entry.remove();
          Future.delayed(
            const Duration(milliseconds: 220),
            _showNextToast,
          );
        },
      ),
    );
    overlay.insert(entry);
  }

  void _handleAdvance(GameController game) {
    // Trigger slide-in animation when cards are about to flip
    final slidePhases = {GamePhase.idle, GamePhase.warPending};
    if (slidePhases.contains(game.phase)) {
      _slideCtrl.forward(from: 0);
    }
    game.advance();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (ctx, game, _) {
        if (game.phase == GamePhase.gameOver) {
          return _GameOverScreen(game: game);
        }
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: SafeArea(
            child: Column(
              children: [
                // ── Player 2 panel (rotated 180° for opposite player) ──────
                RotatedBox(
                  quarterTurns: 2,
                  child: _PlayerPanel(
                    label: 'Player 2',
                    cardCount: game.p2Count,
                    cardsInPlay: game.cardsInPlay,
                    isLeading: game.p2Count > game.p1Count,
                    gotSecondWind: game.secondWindRecipient == 'Player 2',
                  ),
                ),
                // ── HUD: Trump · Musk · Cards in play ─────────────────────
                _InfoBar(game: game),
                Container(height: 1, color: const Color(0xFFE0E6F0)),
                // ── Battle zone ────────────────────────────────────────────
                Expanded(
                  child: _BattleZone(
                    game: game,
                    p1Slide: _p1Slide,
                    p2Slide: _p2Slide,
                  ),
                ),
                // ── Action button ──────────────────────────────────────────
                _ActionButton(
                  game: game,
                  onTap: () => _handleAdvance(game),
                ),
                Container(height: 1, color: const Color(0xFFE0E6F0)),
                // ── Player 1 panel ─────────────────────────────────────────
                _PlayerPanel(
                  label: 'Player 1',
                  cardCount: game.p1Count,
                  cardsInPlay: game.cardsInPlay,
                  isLeading: game.p1Count > game.p2Count,
                  gotSecondWind: game.secondWindRecipient == 'Player 1',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Player Panel  — shown at top (rotated) and bottom (normal)
// ══════════════════════════════════════════════════════════════════════════════
class _PlayerPanel extends StatelessWidget {
  final String label;
  final int cardCount;
  final int cardsInPlay;
  final bool isLeading;
  final bool gotSecondWind;

  const _PlayerPanel({
    required this.label,
    required this.cardCount,
    required this.cardsInPlay,
    required this.isLeading,
    required this.gotSecondWind,
  });

  @override
  Widget build(BuildContext context) {
    final progress = cardsInPlay > 0 ? cardCount / cardsInPlay : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          _MiniDeckPile(count: cardCount),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Label row
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B2B4B),
                        letterSpacing: 0.4,
                      ),
                    ),
                    if (isLeading) ...[
                      const SizedBox(width: 6),
                      const _Chip(
                        text: 'LEADING',
                        bg: Color(0xFF16A34A),
                      ),
                    ],
                    if (gotSecondWind) ...[
                      const SizedBox(width: 5),
                      const _Chip(
                        text: '💨 SW',
                        bg: Color(0xFF0284C7),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: const Color(0xFFDDE3F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isLeading
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF4B6087),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$cardCount cards',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8899BB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini stacked deck visual ──────────────────────────────────────────────────
class _MiniDeckPile extends StatelessWidget {
  final int count;
  const _MiniDeckPile({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Container(
        width: 44,
        height: 61,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCDD5E8), width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.close, size: 14, color: Color(0xFFCDD5E8)),
      );
    }
    final layers = count.clamp(1, 4);
    return SizedBox(
      width: 44 + (layers - 1) * 2.5,
      height: 61 + (layers - 1) * 2.5,
      child: Stack(
        children: List.generate(layers, (i) {
          final shade = Color.lerp(
            const Color(0xFF2D4270),
            const Color(0xFF1B2B4B),
            i / layers,
          )!;
          return Positioned(
            left: i * 2.5,
            top: i * 2.5,
            child: Container(
              width: 44,
              height: 61,
              decoration: BoxDecoration(
                color: shade,
                borderRadius: BorderRadius.circular(5),
                boxShadow: i == layers - 1
                    ? const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: i == layers - 1
                  ? Center(
                      child: Text(
                        '✦',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.22),
                          fontSize: 14,
                        ),
                      ),
                    )
                  : null,
            ),
          );
        }),
      ),
    );
  }
}

// ── Small label chip ──────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String text;
  final Color bg;
  const _Chip({required this.text, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: bg,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Info Bar  — Trump · Musk · Cards in play
// ══════════════════════════════════════════════════════════════════════════════
class _InfoBar extends StatelessWidget {
  final GameController game;
  const _InfoBar({required this.game});

  @override
  Widget build(BuildContext context) {
    final trumpSet  = game.trumpSuit != null;
    final muskAlive = game.muskIsActive;

    return Container(
      color: const Color(0xFFF5F6FA),
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _InfoPill(
            label: 'TRUMP',
            value: game.trumpSuit ?? '—',
            active: trumpSet,
            activeColor: const Color(0xFFF59E0B),
            icon: '👑',
          ),
          Container(width: 1, height: 28, color: const Color(0xFFDDE3F0)),
          _InfoPill(
            label: 'MUSK',
            value: game.muskLabel,
            active: muskAlive,
            activeColor: const Color(0xFF7C3AED),
            icon: '🔥',
          ),
          Container(width: 1, height: 28, color: const Color(0xFFDDE3F0)),
          _InfoPill(
            label: 'CARDS',
            value: '${game.cardsInPlay}',
            active: true,
            activeColor: const Color(0xFF1B2B4B),
            icon: '🃏',
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final Color activeColor;
  final String icon;

  const _InfoPill({
    required this.label,
    required this.value,
    required this.active,
    required this.activeColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : const Color(0xFFB0BCCE);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: TextStyle(fontSize: 13, color: active ? null : const Color(0xFFCDD5E8))),
        const SizedBox(width: 5),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
                color: color.withOpacity(0.7),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Battle Zone
// ══════════════════════════════════════════════════════════════════════════════
class _BattleZone extends StatelessWidget {
  final GameController game;
  final Animation<Offset> p1Slide;
  final Animation<Offset> p2Slide;

  const _BattleZone({
    required this.game,
    required this.p1Slide,
    required this.p2Slide,
  });

  bool get _cardsVisible => game.p1BattleCard != null;
  bool get _faceDown =>
      game.phase == GamePhase.flipping ||
      game.phase == GamePhase.warFlipping;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // War depth / pot badge
                  if (game.warDepth > 0)
                    _WarBadge(
                      warDepth: game.warDepth,
                      potSize: game.potSize,
                    ),
                  const SizedBox(height: 4),
                  // Status label
                  _StatusLabel(game: game),
                  const SizedBox(height: 16),
                  // Cards row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // P2 card (left)
                      Column(
                        children: [
                          const _CardPlayerLabel(text: 'P2'),
                          const SizedBox(height: 4),
                          SlideTransition(
                            position: p2Slide,
                            child: _buildCard(isP1: false),
                          ),
                        ],
                      ),
                      const SizedBox(width: 18),
                      // Centre icon
                      _CenterIcon(game: game),
                      const SizedBox(width: 18),
                      // P1 card (right)
                      Column(
                        children: [
                          const _CardPlayerLabel(text: 'P1'),
                          const SizedBox(height: 4),
                          SlideTransition(
                            position: p1Slide,
                            child: _buildCard(isP1: true),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Round reason
                  const SizedBox(height: 10),
                  _RoundReason(game: game),
                  // War pending — show face-down pile
                  if (game.phase == GamePhase.warPending)
                    _WarPileDisplay(game: game),
                  // Second Wind banner
                  if (game.statusBanner != null)
                    _SecondWindBanner(text: game.statusBanner!),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard({required bool isP1}) {
    final card    = isP1 ? game.p1BattleCard : game.p2BattleCard;
    final wins    = isP1 ? game.p1BattleWins : game.p2BattleWins;

    if (!_cardsVisible || _faceDown) return const CardBack(width: 90);

    return AnimatedScale(
      scale: wins ? 1.06 : 1.0,
      duration: const Duration(milliseconds: 280),
      child: CardFace(
        card: card!,
        width: 90,
        winner: wins,
        isMusk: game.isMuskCard(card),
        isTrump: game.isTrumpCard(card),
      ),
    );
  }
}

// ── War depth + pot size badge ────────────────────────────────────────────────
class _WarBadge extends StatelessWidget {
  final int warDepth;
  final int potSize;
  const _WarBadge({required this.warDepth, required this.potSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDC2626).withOpacity(0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 13,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 5),
          Text(
            warDepth > 1
                ? 'WAR ×$warDepth  ·  $potSize cards at stake'
                : '$potSize cards at stake',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFDC2626),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Phase status label ────────────────────────────────────────────────────────
class _StatusLabel extends StatelessWidget {
  final GameController game;
  const _StatusLabel({required this.game});

  @override
  Widget build(BuildContext context) {
    final (text, color, weight) = _resolve();
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: color,
        fontWeight: weight,
        letterSpacing: 0.3,
      ),
    );
  }

  (String, Color, FontWeight) _resolve() {
    const navy = Color(0xFF1B2B4B);
    const red  = Color(0xFFDC2626);
    const grey = Color(0xFF8899BB);

    switch (game.phase) {
      case GamePhase.idle:
        return ('Round ${game.round + 1}  ·  Tap to flip', grey, FontWeight.w500);
      case GamePhase.flipping:
        return ('Flipping...', grey, FontWeight.w500);
      case GamePhase.result:
        if (game.lastResult == RoundResult.tie) {
          return ('⚔  TIE — WAR!', red, FontWeight.w700);
        }
        final who = game.lastResult == RoundResult.p1Wins ? 'Player 1' : 'Player 2';
        return ('$who wins round ${game.round}', navy, FontWeight.w600);
      case GamePhase.warPending:
        return ('Cards are face-down — ready?', red, FontWeight.w600);
      case GamePhase.warFlipping:
        return ('Flipping war card...', red, FontWeight.w500);
      case GamePhase.warResult:
        if (game.lastResult == RoundResult.tie) {
          return ('⚔  TIE AGAIN — MORE WAR!', red, FontWeight.w700);
        }
        final who = game.lastResult == RoundResult.p1Wins ? 'Player 1' : 'Player 2';
        return ('$who wins the war!', navy, FontWeight.w600);
      default:
        return ('', grey, FontWeight.w500);
    }
  }
}

// ── Small "P1" / "P2" label above cards ──────────────────────────────────────
class _CardPlayerLabel extends StatelessWidget {
  final String text;
  const _CardPlayerLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Color(0xFFB0BCCE),
        letterSpacing: 1,
      ),
    );
  }
}

// ── VS  /  ⚔ war icon ────────────────────────────────────────────────────────
class _CenterIcon extends StatelessWidget {
  final GameController game;
  const _CenterIcon({required this.game});

  bool get _isWarMode =>
      game.warDepth > 0 ||
      (game.phase == GamePhase.result    && game.lastResult == RoundResult.tie) ||
      (game.phase == GamePhase.warResult && game.lastResult == RoundResult.tie);

  @override
  Widget build(BuildContext context) {
    if (_isWarMode) {
      return Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Color(0xFFDC2626),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text('⚔️', style: TextStyle(fontSize: 18)),
        ),
      );
    }
    return const Text(
      'VS',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: Color(0xFFCDD5E8),
        letterSpacing: 2,
      ),
    );
  }
}

// ── Why someone won ───────────────────────────────────────────────────────────
class _RoundReason extends StatelessWidget {
  final GameController game;
  const _RoundReason({required this.game});

  @override
  Widget build(BuildContext context) {
    final reason = game.roundReason;
    final show   = reason != null &&
        (game.phase == GamePhase.result || game.phase == GamePhase.warResult);
    if (!show) return const SizedBox.shrink();

    final isTie = game.lastResult == RoundResult.tie;
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isTie
              ? const Color(0xFFDC2626).withOpacity(0.08)
              : const Color(0xFF1B2B4B).withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          reason,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isTie
                ? const Color(0xFFDC2626)
                : const Color(0xFF1B2B4B),
          ),
        ),
      ),
    );
  }
}

// ── Face-down card fan during war ─────────────────────────────────────────────
class _WarPileDisplay extends StatelessWidget {
  final GameController game;
  const _WarPileDisplay({required this.game});

  @override
  Widget build(BuildContext context) {
    final total      = game.potSize;
    final visible    = min(total, 9);
    final p1fd       = game.p1FaceDownCount;
    final p2fd       = game.p2FaceDownCount;

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        children: [
          // Fan of card backs
          SizedBox(
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(visible, (i) {
                final angle = (i - (visible - 1) / 2) * 0.11;
                final offset = (i - (visible - 1) / 2) * 6.0;
                return Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()
                    ..rotateZ(angle)
                    ..translate(offset, 0.0),
                  child: Container(
                    width: 34,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B2B4B),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x30000000),
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '✦',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.18),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          // Counts
          Text(
            '$total cards in pot  ·  P1: $p1fd down  ·  P2: $p2fd down',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFDC2626),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Second Wind received banner ───────────────────────────────────────────────
class _SecondWindBanner extends StatelessWidget {
  final String text;
  const _SecondWindBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7).withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF0284C7).withOpacity(0.28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💨', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0369A1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Action Button  — single tap to advance game state
// ══════════════════════════════════════════════════════════════════════════════
class _ActionButton extends StatelessWidget {
  final GameController game;
  final VoidCallback onTap;

  const _ActionButton({required this.game, required this.onTap});

  bool get _enabled {
    return const {
      GamePhase.idle,
      GamePhase.result,
      GamePhase.warPending,
      GamePhase.warResult,
    }.contains(game.phase);
  }

  bool get _isWarAction {
    return (game.phase == GamePhase.result    && game.lastResult == RoundResult.tie) ||
           (game.phase == GamePhase.warPending) ||
           (game.phase == GamePhase.warResult  && game.lastResult == RoundResult.tie);
  }

  String get _label {
    switch (game.phase) {
      case GamePhase.idle:
        return 'Flip Cards';
      case GamePhase.result:
        return game.lastResult == RoundResult.tie
            ? '⚔  Declare War!'
            : 'Collect Cards';
      case GamePhase.warPending:
        return 'Flip War Card';
      case GamePhase.warResult:
        return game.lastResult == RoundResult.tie
            ? '⚔  War Again!'
            : 'Collect All';
      default:
        return '···';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _enabled
        ? (_isWarAction ? const Color(0xFFDC2626) : const Color(0xFF1B2B4B))
        : const Color(0xFFCDD5E8);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          child: ElevatedButton(
            onPressed: _enabled ? onTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              disabledBackgroundColor: const Color(0xFFCDD5E8),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white.withOpacity(0.55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              _label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Game Over Screen
// ══════════════════════════════════════════════════════════════════════════════
class _GameOverScreen extends StatelessWidget {
  final GameController game;
  const _GameOverScreen({required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2B4B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Winner headline
              const Text('🏆', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 14),
              Text(
                game.gameWinner ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const Text(
                'WINS THE WAR',
                style: TextStyle(
                  color: Color(0xFF4F6D8A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
              const Spacer(flex: 1),
              // Stats row
              _StatsRow(game: game),
              const Spacer(flex: 1),
              // Achievements earned
              if (game.allUnlocked.isNotEmpty) ...[
                const Text(
                  'ACHIEVEMENTS',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F6D8A),
                  ),
                ),
                const SizedBox(height: 10),
                _AchievementGrid(unlocked: game.allUnlocked),
              ],
              const Spacer(flex: 2),
              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => game.newGame(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1B2B4B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    color: Color(0xFF4F6D8A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stats bubbles on game over ────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final GameController game;
  const _StatsRow({required this.game});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Stat(label: 'Rounds', value: '${game.round}'),
        _Stat(label: 'P1 Wars', value: '${game.p1WarsWon}'),
        _Stat(label: 'P2 Wars', value: '${game.p2WarsWon}'),
        _Stat(label: 'Removed', value: '${game.cardsRemovedCount}'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4F6D8A),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Achievement emoji grid on game over ───────────────────────────────────────
class _AchievementGrid extends StatelessWidget {
  final Set<Achievement> unlocked;
  const _AchievementGrid({required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: unlocked.map((a) {
        final meta = kAchievementMeta[a]!;
        return Tooltip(
          message: meta.title,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(meta.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
