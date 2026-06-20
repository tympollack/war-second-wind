import 'package:flutter/material.dart';
import '../models/card.dart';
import '../theme/app_colors.dart';
import '../theme/card_dimensions.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CardFace  — renders a playing card right-side up
//
// Visual priority for border/glow:
//   winner (green)  >  Musk (purple)  >  Trump (amber)  >  none
// ══════════════════════════════════════════════════════════════════════════════
class CardFace extends StatelessWidget {
  final PlayingCard card;
  final double width;
  final bool winner;   // green glow  — beat the other card
  final bool isMusk;   // purple glow — this card is Musk
  final bool isTrump;  // amber glow  — this card is the trump suit

  const CardFace({
    super.key,
    required this.card,
    this.width = 88,
    this.winner = false,
    this.isMusk = false,
    this.isTrump = false,
  });

  // ── Derived colours ──────────────────────────────────────────────────────
  Color? get _accentColor {
    if (winner) return AppColors.green;
    if (isMusk) return AppColors.purple;
    if (isTrump) return AppColors.amber;
    return null;
  }

  Color get _inkColor {
    if (card.isJoker) return AppColors.purple;
    return card.isRed ? AppColors.red : AppColors.inkDark;
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final h      = CardDimensions.height(width);
    final radius = CardDimensions.radius(width);
    final accent = _accentColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Card body ────────────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          width:  width,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: accent != null
                ? Border.all(color: accent, width: 2.5)
                : Border.all(color: AppColors.border, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: accent != null
                    ? accent.withOpacity(0.38)
                    : Colors.black.withOpacity(0.13),
                blurRadius: accent != null ? 20 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - 1),
            child: card.isJoker
                ? _JokerFace(width: width)
                : _RegularFace(card: card, width: width, inkColor: _inkColor),
          ),
        ),

        // ── Top-right badge: 🔥 Musk  or  ★ Trump ───────────────────────
        if (isMusk || isTrump)
          Positioned(
            top:   -6,
            right: -6,
            child: _CardBadge(isMusk: isMusk),
          ),
      ],
    );
  }
}

// ── Regular card face (2 – A) ───────────────────────────────────────────────
class _RegularFace extends StatelessWidget {
  final PlayingCard card;
  final double width;
  final Color inkColor;

  const _RegularFace({
    required this.card,
    required this.width,
    required this.inkColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-left corner
        Positioned(
          top:  width * 0.07,
          left: width * 0.1,
          child: _CornerPip(
            rankLabel: card.rankLabel,
            suit:      card.suit,
            color:     inkColor,
            size:      width,
          ),
        ),

        // Centre suit glyph
        Center(
          child: Text(
            card.suit,
            style: TextStyle(
              fontSize: width * 0.44,
              color:    inkColor,
              height:   1.0,
            ),
          ),
        ),

        // Bottom-right corner (rotated 180°)
        Positioned(
          bottom: width * 0.07,
          right:  width * 0.1,
          child: RotatedBox(
            quarterTurns: 2,
            child: _CornerPip(
              rankLabel: card.rankLabel,
              suit:      card.suit,
              color:     inkColor,
              size:      width,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Joker card face ─────────────────────────────────────────────────────────
class _JokerFace extends StatelessWidget {
  final double width;
  const _JokerFace({required this.width});

  @override
  Widget build(BuildContext context) {
    const color = AppColors.purple;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purple.withOpacity(0.06),
            Colors.white,
            AppColors.purple.withOpacity(0.06),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '★',
              style: TextStyle(
                fontSize: width * 0.44,
                color: color,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'JOKER',
              style: TextStyle(
                fontSize:    width * 0.13,
                fontWeight:  FontWeight.w900,
                letterSpacing: 2.5,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Corner pip: rank + suit stacked ─────────────────────────────────────────
class _CornerPip extends StatelessWidget {
  final String rankLabel;
  final String suit;
  final Color color;
  final double size;

  const _CornerPip({
    required this.rankLabel,
    required this.suit,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          rankLabel,
          style: TextStyle(
            fontSize:   size * 0.20,
            fontWeight: FontWeight.w800,
            color:      color,
            height:     1.0,
          ),
        ),
        Text(
          suit,
          style: TextStyle(
            fontSize: size * 0.17,
            color:    color,
            height:   1.0,
          ),
        ),
      ],
    );
  }
}

// ── Musk / Trump badge dot ───────────────────────────────────────────────────
class _CardBadge extends StatelessWidget {
  final bool isMusk;
  const _CardBadge({required this.isMusk});

  @override
  Widget build(BuildContext context) {
    final bg = isMusk ? AppColors.purple : AppColors.amber;
    return Container(
      width:  22,
      height: 22,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Text(
          isMusk ? '🔥' : '★',
          style: TextStyle(
            fontSize: isMusk ? 10 : 12,
            color:    isMusk ? null : Colors.white,
            height:   1.0,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CardBack  — face-down card, navy with inner border and ✦ glyph
// ══════════════════════════════════════════════════════════════════════════════
class CardBack extends StatelessWidget {
  final double width;
  const CardBack({super.key, this.width = 88});

  @override
  Widget build(BuildContext context) {
    final h      = CardDimensions.height(width);
    final radius = CardDimensions.radius(width);
    return Container(
      width:  width,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color:      Color(0x28000000),
            blurRadius: 10,
            offset:     Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(width * 0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius * 0.55),
            border: Border.all(
              color: Colors.white.withOpacity(0.17),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '✦',
              style: TextStyle(
                color:    Colors.white.withOpacity(0.26),
                fontSize: width * 0.32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CardSlotEmpty  — placeholder outline when no card occupies a slot
// ══════════════════════════════════════════════════════════════════════════════
class CardSlotEmpty extends StatelessWidget {
  final double width;
  const CardSlotEmpty({super.key, this.width = 88});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  width,
      height: CardDimensions.height(width),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CardDimensions.radius(width)),
        border: Border.all(
          color: AppColors.cardBack,
          width: 1.5,
        ),
      ),
    );
  }
}
