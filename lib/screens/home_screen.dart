import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_controller.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              _Title(),
              const Spacer(flex: 2),
              _RulesList(),
              const Spacer(flex: 3),
              _DealButton(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Title block ───────────────────────────────────────────────────────────────
class _Title extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'WAR',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 88,
            fontWeight: FontWeight.w900,
            letterSpacing: 18,
            color: Color(0xFF1B2B4B),
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'CARD GAME FOR TWO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 4.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B2B4B).withOpacity(0.32),
          ),
        ),
      ],
    );
  }
}

// ── Rules list ────────────────────────────────────────────────────────────────
class _RulesList extends StatelessWidget {
  static const _rules = [
    (Icons.style_outlined,
        '18 cards each · 18-card Second Wind reserve'),
    (Icons.military_tech_outlined,
        'Joker beats every card'),
    (Icons.star_outline_rounded,
        'First same-suit round sets the Trump suit'),
    (Icons.local_fire_department_outlined,
        'First War removes tied cards and creates Musk'),
    (Icons.whatshot_rounded,
        'Musk beats everything except Jokers'),
    (Icons.air_rounded,
        'First to run out claims the Second Wind deck'),
    (Icons.emoji_events_outlined,
        'Opponent empties with no Second Wind = you win'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _rules.map((r) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2B4B).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(r.$1, size: 18, color: const Color(0xFF1B2B4B)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  r.$2,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF2C3E60),
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Deal button ───────────────────────────────────────────────────────────────
class _DealButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.read<GameController>().newGame();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1B2B4B),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: const Text(
        'Deal Cards',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
