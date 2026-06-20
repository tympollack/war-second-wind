import 'package:flutter_test/flutter_test.dart';
import 'package:war_card_game/models/card.dart';
import 'package:war_card_game/game/game_controller.dart';

void main() {
  group('PlayingCard', () {
    test('buildFullDeck produces 54 cards with unique ids', () {
      final deck = PlayingCard.buildFullDeck();
      expect(deck.length, 54);
      final ids = deck.map((c) => c.id).toSet();
      expect(ids.length, 54);
    });

    test('deck contains 2 jokers', () {
      final deck = PlayingCard.buildFullDeck();
      final jokers = deck.where((c) => c.isJoker).toList();
      expect(jokers.length, 2);
      for (final j in jokers) {
        expect(j.rank, 15);
      }
    });

    test('regular cards have correct rank labels', () {
      final card = PlayingCard.regular(0, '♠', 14);
      expect(card.rankLabel, 'A');
      expect(card.rankName, 'Ace');
      expect(card.isRed, false);

      final heart = PlayingCard.regular(1, '♥', 2);
      expect(heart.rankLabel, '2');
      expect(heart.isRed, true);
    });
  });

  group('GameController', () {
    late GameController game;

    setUp(() {
      game = GameController();
      game.newGame();
    });

    test('newGame initializes correct card counts', () {
      expect(game.p1Count, 18);
      expect(game.p2Count, 18);
      expect(game.secondWindAvailable, true);
      expect(game.phase, GamePhase.idle);
      expect(game.round, 0);
    });

    test('cardsInPlay starts at 54', () {
      expect(game.cardsInPlay, 54);
    });

    test('newGame resets all state', () {
      expect(game.trumpSuit, isNull);
      expect(game.muskRank, isNull);
      expect(game.gameWinner, isNull);
      expect(game.warDepth, 0);
      expect(game.allUnlocked, isEmpty);
    });
  });
}
