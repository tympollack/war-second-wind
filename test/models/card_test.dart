import 'package:flutter_test/flutter_test.dart';
import 'package:war_card_game/models/card.dart';

void main() {
  group('PlayingCard.regular', () {
    test('stores id, suit, rank correctly', () {
      final card = PlayingCard.regular(0, '♠', 14);
      expect(card.id, 0);
      expect(card.suit, '♠');
      expect(card.rank, 14);
      expect(card.isJoker, false);
    });
  });

  group('PlayingCard.joker', () {
    test('creates a joker with rank 15 and empty suit', () {
      final joker = PlayingCard.joker(52);
      expect(joker.id, 52);
      expect(joker.suit, '');
      expect(joker.rank, 15);
      expect(joker.isJoker, true);
    });
  });

  group('rankLabel', () {
    test('returns ★ for joker', () {
      expect(PlayingCard.joker(0).rankLabel, '★');
    });

    test('returns numeric string for number cards', () {
      expect(PlayingCard.regular(0, '♠', 2).rankLabel, '2');
      expect(PlayingCard.regular(0, '♠', 10).rankLabel, '10');
    });

    test('returns letter for face cards', () {
      expect(PlayingCard.regular(0, '♠', 11).rankLabel, 'J');
      expect(PlayingCard.regular(0, '♠', 12).rankLabel, 'Q');
      expect(PlayingCard.regular(0, '♠', 13).rankLabel, 'K');
      expect(PlayingCard.regular(0, '♠', 14).rankLabel, 'A');
    });
  });

  group('rankName', () {
    test('returns Joker for joker', () {
      expect(PlayingCard.joker(0).rankName, 'Joker');
    });

    test('returns full name for face cards', () {
      expect(PlayingCard.regular(0, '♠', 11).rankName, 'Jack');
      expect(PlayingCard.regular(0, '♠', 12).rankName, 'Queen');
      expect(PlayingCard.regular(0, '♠', 13).rankName, 'King');
      expect(PlayingCard.regular(0, '♠', 14).rankName, 'Ace');
    });

    test('returns numeric string for number cards', () {
      expect(PlayingCard.regular(0, '♠', 5).rankName, '5');
    });
  });

  group('isRed', () {
    test('hearts and diamonds are red', () {
      expect(PlayingCard.regular(0, '♥', 2).isRed, true);
      expect(PlayingCard.regular(0, '♦', 2).isRed, true);
    });

    test('spades and clubs are not red', () {
      expect(PlayingCard.regular(0, '♠', 2).isRed, false);
      expect(PlayingCard.regular(0, '♣', 2).isRed, false);
    });

    test('joker is not red', () {
      expect(PlayingCard.joker(0).isRed, false);
    });
  });

  group('equality and hashCode', () {
    test('cards with same id are equal', () {
      final a = PlayingCard.regular(5, '♠', 10);
      final b = PlayingCard.regular(5, '♥', 3);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('cards with different ids are not equal', () {
      final a = PlayingCard.regular(0, '♠', 10);
      final b = PlayingCard.regular(1, '♠', 10);
      expect(a, isNot(equals(b)));
    });
  });

  group('buildFullDeck', () {
    test('produces 54 cards', () {
      final deck = PlayingCard.buildFullDeck();
      expect(deck.length, 54);
    });

    test('contains 52 regular cards and 2 jokers', () {
      final deck = PlayingCard.buildFullDeck();
      final jokers = deck.where((c) => c.isJoker).toList();
      final regulars = deck.where((c) => !c.isJoker).toList();
      expect(jokers.length, 2);
      expect(regulars.length, 52);
    });

    test('has 13 cards per suit', () {
      final deck = PlayingCard.buildFullDeck();
      for (final suit in ['♠', '♥', '♦', '♣']) {
        final count = deck.where((c) => c.suit == suit).length;
        expect(count, 13, reason: 'Expected 13 $suit cards');
      }
    });

    test('each suit has ranks 2 through 14', () {
      final deck = PlayingCard.buildFullDeck();
      for (final suit in ['♠', '♥', '♦', '♣']) {
        final ranks = deck
            .where((c) => c.suit == suit)
            .map((c) => c.rank)
            .toSet();
        expect(ranks, equals({2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}));
      }
    });

    test('all card ids are unique', () {
      final deck = PlayingCard.buildFullDeck();
      final ids = deck.map((c) => c.id).toSet();
      expect(ids.length, 54);
    });

    test('joker ids are 52 and 53', () {
      // buildFullDeck shuffles, so we find jokers by isJoker
      final deck = PlayingCard.buildFullDeck();
      final jokerIds = deck.where((c) => c.isJoker).map((c) => c.id).toSet();
      expect(jokerIds, equals({52, 53}));
    });
  });
}
