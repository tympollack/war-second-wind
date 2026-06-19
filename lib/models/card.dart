import 'dart:math';

class PlayingCard {
  final int id;       // unique 0–53
  final String suit;  // '♠' '♥' '♦' '♣', or '' for joker
  final int rank;     // 2–14 regular, 15 for joker
  final bool isJoker;

  const PlayingCard._({
    required this.id,
    required this.suit,
    required this.rank,
    this.isJoker = false,
  });

  factory PlayingCard.regular(int id, String suit, int rank) =>
      PlayingCard._(id: id, suit: suit, rank: rank);

  factory PlayingCard.joker(int id) =>
      PlayingCard._(id: id, suit: '', rank: 15, isJoker: true);

  // ── Display helpers ───────────────────────────────────────
  String get rankLabel {
    if (isJoker) return '★';
    return {
      2: '2',  3: '3',  4: '4',  5: '5',  6: '6',  7: '7',
      8: '8',  9: '9', 10: '10', 11: 'J', 12: 'Q', 13: 'K', 14: 'A',
    }[rank] ?? '?';
  }

  String get rankName {
    if (isJoker) return 'Joker';
    return {
      2: '2',  3: '3',  4: '4',  5: '5',  6: '6',  7: '7',  8: '8',
      9: '9', 10: '10', 11: 'Jack', 12: 'Queen', 13: 'King', 14: 'Ace',
    }[rank] ?? 'Unknown';
  }

  bool get isRed => suit == '♥' || suit == '♦';

  @override
  bool operator ==(Object other) => other is PlayingCard && other.id == id;
  @override
  int get hashCode => id.hashCode;

  // ── Factory: build and shuffle a full 54-card deck ────────
  static List<PlayingCard> buildFullDeck() {
    final deck = <PlayingCard>[];
    int id = 0;
    for (final suit in const ['♠', '♥', '♦', '♣']) {
      for (int r = 2; r <= 14; r++) {
        deck.add(PlayingCard.regular(id++, suit, r));
      }
    }
    deck.add(PlayingCard.joker(id++)); // id 52
    deck.add(PlayingCard.joker(id++)); // id 53
    return deck..shuffle(Random());
  }
}
