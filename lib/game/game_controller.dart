import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card.dart';
import 'achievement.dart';

// ─────────────────────────────────────────────────────────────────────────────
enum GamePhase {
  idle,         // ready to flip
  flipping,     // cards animating face-down → auto-resolves
  result,       // round result visible
  warPending,   // war declared; face-down cards placed; awaiting flip
  warFlipping,  // war card animating → auto-resolves
  warResult,    // war result visible
  gameOver,
}

enum RoundResult { p1Wins, p2Wins, tie }

// ─────────────────────────────────────────────────────────────────────────────
class GameController extends ChangeNotifier {
  // ── Decks ──────────────────────────────────────────────────────────────────
  Queue<PlayingCard> _p1Deck = Queue();
  Queue<PlayingCard> _p2Deck = Queue();
  Queue<PlayingCard> _secondWindDeck = Queue();
  bool _secondWindUsed = false;
  String? _secondWindRecipient;

  // ── Rule State ─────────────────────────────────────────────────────────────
  String? _trumpSuit;               // null until first same-suit round
  int? _muskRank;                   // null until first war
  final Map<int, int> _removedByRank = {};   // rank → count removed from game
  final Set<int> _removedCardIds = {};

  // ── Battle State ───────────────────────────────────────────────────────────
  PlayingCard? _p1BattleCard;
  PlayingCard? _p2BattleCard;
  List<PlayingCard> _pot = [];
  int _p1FaceDownCount = 0;
  int _p2FaceDownCount = 0;

  // ── Game State ─────────────────────────────────────────────────────────────
  GamePhase _phase = GamePhase.idle;
  RoundResult? _lastResult;
  String? _gameWinner;
  int _round = 0;
  int _warDepth = 0;
  String? _roundReason;
  String? _statusBanner;     // e.g. "Player 1 received Second Wind!"

  // ── Achievement Tracking ───────────────────────────────────────────────────
  final Set<Achievement> _unlocked = {};
  final List<Achievement> _newlyUnlocked = [];
  int _p1WarsWon = 0;
  int _p2WarsWon = 0;
  int _maxP1Cards = 0;
  int _maxP2Cards = 0;
  bool _anyWarRuthless = false;     // set if any war in chain was ruthless
  bool _justSetMusk = false;
  int _p1CountAtRoundStart = 0;
  int _p2CountAtRoundStart = 0;

  // ── Getters ────────────────────────────────────────────────────────────────
  int get p1Count => _p1Deck.length;
  int get p2Count => _p2Deck.length;
  bool get secondWindAvailable => !_secondWindUsed && _secondWindDeck.isNotEmpty;

  PlayingCard? get p1BattleCard => _p1BattleCard;
  PlayingCard? get p2BattleCard => _p2BattleCard;
  bool get p1BattleWins => _lastResult == RoundResult.p1Wins;
  bool get p2BattleWins => _lastResult == RoundResult.p2Wins;

  GamePhase get phase => _phase;
  RoundResult? get lastResult => _lastResult;
  String? get gameWinner => _gameWinner;
  int get potSize => _pot.length;
  int get round => _round;
  int get warDepth => _warDepth;

  String? get trumpSuit => _trumpSuit;

  int? get muskRank => _muskRank;
  bool get muskIsActive {
    if (_muskRank == null) return false;
    return (_removedByRank[_muskRank] ?? 0) < 4;
  }

  String get muskLabel {
    if (_muskRank == null || !muskIsActive) return '—';
    return PlayingCard.rankLabels[_muskRank] ?? '—';
  }

  /// Total cards still in the game (not removed by war).
  int get cardsInPlay => 54 - _removedCardIds.length;
  /// How many cards have been permanently removed.
  int get cardsRemovedCount => _removedCardIds.length;

  bool get secondWindUsed => _secondWindUsed;
  String? get secondWindRecipient => _secondWindRecipient;
  String? get roundReason => _roundReason;
  String? get statusBanner => _statusBanner;
  int get p1FaceDownCount => _p1FaceDownCount;
  int get p2FaceDownCount => _p2FaceDownCount;

  List<Achievement> get newlyUnlocked => List.unmodifiable(_newlyUnlocked);
  Set<Achievement> get allUnlocked => Set.unmodifiable(_unlocked);
  int get p1WarsWon => _p1WarsWon;
  int get p2WarsWon => _p2WarsWon;

  bool isMuskCard(PlayingCard card) {
    if (!muskIsActive) return false;
    if (card.isJoker) return false;
    return card.rank == _muskRank;
  }

  bool isTrumpCard(PlayingCard card) {
    if (_trumpSuit == null) return false;
    if (card.isJoker) return false;
    return card.suit == _trumpSuit;
  }

  void clearNewlyUnlocked() {
    _newlyUnlocked.clear();
  }

  // ── Public API ─────────────────────────────────────────────────────────────
  void newGame() {
    final allCards = PlayingCard.buildFullDeck(); // already shuffled
    _p1Deck = Queue.from(allCards.sublist(0, 18));
    _p2Deck = Queue.from(allCards.sublist(18, 36));
    _secondWindDeck = Queue.from(allCards.sublist(36, 54));
    _secondWindUsed = false;
    _secondWindRecipient = null;

    _trumpSuit = null;
    _muskRank = null;
    _removedByRank.clear();
    _removedCardIds.clear();

    _p1BattleCard = null;
    _p2BattleCard = null;
    _pot = [];
    _p1FaceDownCount = 0;
    _p2FaceDownCount = 0;

    _phase = GamePhase.idle;
    _lastResult = null;
    _gameWinner = null;
    _round = 0;
    _warDepth = 0;
    _roundReason = null;
    _statusBanner = null;

    _unlocked.clear();
    _newlyUnlocked.clear();
    _p1WarsWon = 0;
    _p2WarsWon = 0;
    _maxP1Cards = 18;
    _maxP2Cards = 18;
    _anyWarRuthless = false;
    _justSetMusk = false;
    _p1CountAtRoundStart = 0;
    _p2CountAtRoundStart = 0;

    notifyListeners();
  }

  /// Single tap advances the game based on current phase.
  void advance() {
    _statusBanner = null;
    switch (_phase) {
      case GamePhase.idle:
        _playRound();
      case GamePhase.result:
        _lastResult == RoundResult.tie ? _startWar() : _awardPot();
      case GamePhase.warPending:
        _flipWarCard();
      case GamePhase.warResult:
        _lastResult == RoundResult.tie ? _startWar() : _awardPot();
      default:
        break;
    }
  }

  // ── Round ──────────────────────────────────────────────────────────────────
  void _playRound() {
    if (_p1Deck.isEmpty || _p2Deck.isEmpty) return;
    _p1CountAtRoundStart = _p1Deck.length;
    _p2CountAtRoundStart = _p2Deck.length;
    _p1BattleCard = _p1Deck.removeFirst();
    _p2BattleCard = _p2Deck.removeFirst();
    _round++;
    _roundReason = null;
    _phase = GamePhase.flipping;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 700), _resolveRound);
  }

  void _resolveRound() => _resolveBattle(GamePhase.result);

  // ── War ────────────────────────────────────────────────────────────────────
  void _startWar() {
    _warDepth++;
    _justSetMusk = false;

    // The two tied battle cards are permanently removed from the game
    _removeCardFromGame(_p1BattleCard!);
    _removeCardFromGame(_p2BattleCard!);

    // First war only: the removed rank becomes Musk (not if jokers)
    if (_muskRank == null && !_p1BattleCard!.isJoker) {
      _muskRank = _p1BattleCard!.rank;
      _justSetMusk = true;
    }

    // Each player places up to 3 cards face-down into the pot.
    // If they have fewer than 3, they place as many as they can leaving one face up.
    // The one with MORE cards always plays 3; comeback mechanic for the underdog.
    final p1Take = min(3, _p1Deck.length - 1);
    final p2Take = min(3, _p2Deck.length - 1);
    _p1FaceDownCount = p1Take;
    _p2FaceDownCount = p2Take;
    if (p1Take == 0 || p2Take == 0) _anyWarRuthless = true;

    for (int i = 0; i < p1Take; i++) {
      _pot.add(_p1Deck.removeFirst());
    }
    for (int i = 0; i < p2Take; i++) {
      _pot.add(_p2Deck.removeFirst());
    }

    // Keep battle cards set — UI shows the tied cards during warPending
    _phase = GamePhase.warPending;
    _checkAchievementsPostWar();
    notifyListeners();
  }

  void _flipWarCard() {
    // Check if either player needs Second Wind or is eliminated
    for (final (deck, num, opponent) in [
      (_p1Deck, 1, 'Player 2'),
      (_p2Deck, 2, 'Player 1'),
    ]) {
      if (deck.isEmpty) {
        if (!_secondWindUsed) {
          _giveSecondWind(num);
          notifyListeners();
          return;
        }
        _endGame(opponent);
        return;
      }
    }

    _p1BattleCard = _p1Deck.removeFirst();
    _p2BattleCard = _p2Deck.removeFirst();
    _roundReason = null;
    _phase = GamePhase.warFlipping;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 700), _resolveWarRound);
  }

  void _resolveWarRound() => _resolveBattle(GamePhase.warResult);

  void _resolveBattle(GamePhase resultPhase) {
    _maybeSetTrump(_p1BattleCard!, _p2BattleCard!);
    _lastResult = _compareCards(_p1BattleCard!, _p2BattleCard!);
    _roundReason = _buildReason(_p1BattleCard!, _p2BattleCard!, _lastResult!);

    if (_lastResult != RoundResult.tie) {
      _pot.addAll([_p1BattleCard!, _p2BattleCard!]);
    }

    _phase = resultPhase;
    _checkAchievementsPostRound();
    notifyListeners();
  }

  // ── Pot Award ──────────────────────────────────────────────────────────────
  void _awardPot() {
    final isP1Win = _lastResult == RoundResult.p1Wins;
    final winnerDeck = isP1Win ? _p1Deck : _p2Deck;
    final loserDeck  = isP1Win ? _p2Deck : _p1Deck;
    final loserNum   = isP1Win ? 2 : 1;

    final shuffled = List<PlayingCard>.from(_pot)..shuffle();
    for (final c in shuffled) {
      winnerDeck.add(c);
    }
    _pot = [];

    // Update max-cards records (after adding pot to winner)
    _maxP1Cards = max(_p1Deck.length, _maxP1Cards);
    _maxP2Cards = max(_p2Deck.length, _maxP2Cards);

    // Count war wins
    if (_warDepth > 0) {
      if (isP1Win) {
        _p1WarsWon++;
      } else {
        _p2WarsWon++;
      }
    }

    _checkAchievementsPostAward(isP1Win);

    // Reset war-round state
    _warDepth = 0;
    _p1BattleCard = null;
    _p2BattleCard = null;
    _lastResult = null;
    _p1FaceDownCount = 0;
    _p2FaceDownCount = 0;
    _anyWarRuthless = false;

    // Check if loser is out of cards
    if (loserDeck.isEmpty) {
      if (!_secondWindUsed) {
        _giveSecondWind(loserNum);
        _phase = GamePhase.idle;
        notifyListeners();
        return;
      } else {
        _endGame(isP1Win ? 'Player 1' : 'Player 2');
        return;
      }
    }

    _phase = GamePhase.idle;
    notifyListeners();
  }

  // ── Second Wind ────────────────────────────────────────────────────────────
  void _giveSecondWind(int playerNum) {
    final deck = playerNum == 1 ? _p1Deck : _p2Deck;
    for (final c in _secondWindDeck) {
      deck.add(c);
    }
    _secondWindDeck.clear();
    _secondWindUsed = true;
    _secondWindRecipient = 'Player $playerNum';
    _statusBanner = 'Player $playerNum received the Second Wind! 💨';
    _unlock(Achievement.secondWindReceiver);
  }

  // ── Card Removal ───────────────────────────────────────────────────────────
  void _removeCardFromGame(PlayingCard card) {
    _removedCardIds.add(card.id);
    if (!card.isJoker) {
      final prev = _removedByRank[card.rank] ?? 0;
      _removedByRank[card.rank] = prev + 1;
      // If musk rank reaches 4 total removed → Musk destroyed
      if (_muskRank != null && card.rank == _muskRank) {
        if (_removedByRank[card.rank]! >= 4) {
          _unlock(Achievement.muskDestroyer);
        }
      }
    }
  }

  // ── End Game ───────────────────────────────────────────────────────────────
  void _endGame(String winner) {
    _gameWinner = winner;
    _phase = GamePhase.gameOver;
    if (!_secondWindUsed) _unlock(Achievement.cleanSweep);
    if (_round < 100) _unlock(Achievement.speedDemon);
    if (_secondWindUsed && _secondWindRecipient == winner) {
      _unlock(Achievement.secondWindVictory);
    }
    notifyListeners();
  }

  // ── Trump & Comparison ─────────────────────────────────────────────────────
  void _maybeSetTrump(PlayingCard p1, PlayingCard p2) {
    if (_trumpSuit != null) return;
    if (p1.isJoker || p2.isJoker) return;
    if (p1.suit == p2.suit) {
      _trumpSuit = p1.suit;
      _unlock(Achievement.trumpSetter);
    }
  }

  /// Card priority: 3=Joker, 2=Musk, 1=Trump, 0=Regular
  int _categoryOf(PlayingCard card) {
    if (card.isJoker) return 3;
    if (isMuskCard(card)) return 2;
    if (isTrumpCard(card)) return 1;
    return 0;
  }

  RoundResult _compareCards(PlayingCard a, PlayingCard b) {
    final aLvl = _categoryOf(a);
    final bLvl = _categoryOf(b);
    if (a.rank == b.rank) return RoundResult.tie;
    if (aLvl != bLvl) return aLvl > bLvl ? RoundResult.p1Wins : RoundResult.p2Wins;
    return a.rank > b.rank ? RoundResult.p1Wins : RoundResult.p2Wins;
  }

  String _buildReason(PlayingCard p1, PlayingCard p2, RoundResult result) {
    if (result == RoundResult.tie) return 'Equal rank — WAR!';
    final winner = result == RoundResult.p1Wins ? p1 : p2;
    final loser  = result == RoundResult.p1Wins ? p2 : p1;
    if (winner.isJoker) return 'Joker beats all!';
    if (isMuskCard(winner)) return 'Musk card dominates!';
    if (isTrumpCard(winner) && !isTrumpCard(loser) && !winner.isJoker) {
      return 'Trump suit wins!';
    }
    return '${winner.rankName} beats ${loser.rankName}';
  }

  // ── Achievement Helpers ────────────────────────────────────────────────────
  void _unlock(Achievement a) {
    if (_unlocked.contains(a)) return;
    _unlocked.add(a);
    _newlyUnlocked.add(a);
  }

  /// Returns the card-count at round start for whichever player won.
  int get _winnerStartCount {
    if (_lastResult == RoundResult.p1Wins) return _p1CountAtRoundStart;
    if (_lastResult == RoundResult.p2Wins) return _p2CountAtRoundStart;
    return -1; // tie — not applicable
  }

  /// Shared pattern: check both-have, or winner-has for a card type.
  void _checkCardTypeAchievement({
    required bool p1Has,
    required bool p2Has,
    required Achievement bothAchievement,
    required Achievement winAchievement,
  }) {
    if (p1Has && p2Has) {
      _unlock(bothAchievement);
    } else if (_lastResult == RoundResult.p1Wins && p1Has) {
      _unlock(winAchievement);
    } else if (_lastResult == RoundResult.p2Wins && p2Has) {
      _unlock(winAchievement);
    }
  }

  void _checkAchievementsPostRound() {
    final p1 = _p1BattleCard!;
    final p2 = _p2BattleCard!;

    if (_round == 1 && _lastResult != RoundResult.tie) {
      _unlock(Achievement.firstBlood);
    }

    // Joker achievements
    _checkCardTypeAchievement(
      p1Has: p1.isJoker,
      p2Has: p2.isJoker,
      bothAchievement: Achievement.jokerVsJoker,
      winAchievement: Achievement.jokerWin,
    );

    // Musk achievements
    _checkCardTypeAchievement(
      p1Has: isMuskCard(p1),
      p2Has: isMuskCard(p2),
      bothAchievement: Achievement.muskVsMusk,
      winAchievement: Achievement.muskWin,
    );

    // Trump advantage win
    if (_lastResult != RoundResult.tie) {
      final winner = _lastResult == RoundResult.p1Wins ? p1 : p2;
      final loser  = _lastResult == RoundResult.p1Wins ? p2 : p1;
      if (isTrumpCard(winner) && !isTrumpCard(loser) &&
          !isMuskCard(winner) && !winner.isJoker) {
        _unlock(Achievement.trumpWin);
      }
    }

    // Cliffhanger: winner had exactly 1 card before this round
    if (_winnerStartCount == 1) _unlock(Achievement.cliffhanger);

    if (_round >= 250) _unlock(Achievement.marathon);
  }

  void _checkAchievementsPostWar() {
    if (_warDepth == 1) _unlock(Achievement.firstWar);
    if (_warDepth == 2) _unlock(Achievement.doubleWar);
    if (_warDepth >= 3) _unlock(Achievement.tripleWar);
    if (_justSetMusk) _unlock(Achievement.muskCreator);
  }

  void _checkAchievementsPostAward(bool p1Won) {
    if (_warDepth > 0) {
      _unlock(Achievement.warWinner);
      if (_anyWarRuthless) _unlock(Achievement.ruthless);
      final warWins = p1Won ? _p1WarsWon : _p2WarsWon;
      if (warWins >= 10) {
        _unlock(Achievement.apocalypse);
      } else if (warWins >= 5) {
        _unlock(Achievement.warMachine);
      }
    }
    final maxCards = max(_maxP1Cards, _maxP2Cards);
    if (maxCards >= 50) {
      _unlock(Achievement.totality);
    } else if (maxCards >= 40) {
      _unlock(Achievement.supremacy);
    } else if (maxCards >= 30) {
      _unlock(Achievement.domination);
    }
  }
}
