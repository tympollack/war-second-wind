import 'package:flutter/foundation.dart';
import '../models/game_record.dart';
import '../models/player_stats.dart';

// ── FIREBASE SWAP-IN ────────────────────────────────────────────────────────
// 1. Add to pubspec.yaml:
//      cloud_firestore: ^5.0.0
//
// 2. Replace mock methods with Firestore calls.
//    Firestore schema:
//
//    /games/{gameId}          ← GameRecord documents (see GameRecord.toMap)
//    /users/{uid}             ← UserModel + PlayerStats merged document
//    /users/{uid}/settings/prefs ← AppSettings document
//
// 3. Key stream replacements:
//    watchGameHistory(uid) →
//      _db.collection('games')
//         .where('userId', isEqualTo: uid)
//         .orderBy('startedAt', descending: true)
//         .snapshots()
//         .map((s) => s.docs.map((d) => GameRecord.fromDoc(d)).toList());
//
//    getPlayerStats(uid) →
//      _db.collection('users').doc(uid).get()
//         .then((d) => PlayerStats.fromMap(d.data() ?? {}));
//
//    saveGameRecord(record) →
//      batch = _db.batch()
//      batch.set(_db.collection('games').doc(), record.toMap())
//      batch.set(_db.collection('users').doc(record.userId),
//                newStats.toMap(), SetOptions(merge: true))
//      await batch.commit();
// ────────────────────────────────────────────────────────────────────────────

class FirestoreService extends ChangeNotifier {
  // In-memory store (replaced by Firestore in production)
  final List<GameRecord> _records = [];
  final Map<String, PlayerStats> _stats = {};
  final Map<String, Map<String, dynamic>> _settings = {};
  String? _seededUserId;

  // ── Game History ──────────────────────────────────────────────────────────
  List<GameRecord> getGameHistory(String userId) {
    _seedMockData(userId); // populate demo data on first call
    return _records
        .where((r) => r.userId == userId)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  // ── Player Stats ──────────────────────────────────────────────────────────
  Future<PlayerStats> getPlayerStats(String userId) async {
    // FIREBASE: see swap-in comment at top
    await Future.delayed(const Duration(milliseconds: 350));
    _seedMockData(userId);
    return _stats[userId] ?? PlayerStats.empty;
  }

  // ── Save a completed game ─────────────────────────────────────────────────
  Future<void> saveGameRecord(GameRecord record) async {
    // FIREBASE: see swap-in comment at top
    await Future.delayed(const Duration(milliseconds: 400));
    _records.removeWhere((r) => r.id == record.id); // avoid dupes
    _records.add(record);

    // Update cumulative stats
    final current = _stats[record.userId] ?? PlayerStats.empty;
    _stats[record.userId] = current.applyGame(record);

    notifyListeners();
  }

  // ── Settings ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getSettings(String userId) async {
    // FIREBASE: _db.collection('users').doc(uid).collection('settings').doc('prefs').get()
    await Future.delayed(const Duration(milliseconds: 200));
    return _settings[userId] ?? _defaultSettings;
  }

  Future<void> saveSettings(String userId, Map<String, dynamic> settings) async {
    // FIREBASE: _db.collection('users').doc(uid).collection('settings').doc('prefs').set(settings)
    await Future.delayed(const Duration(milliseconds: 200));
    _settings[userId] = {..._defaultSettings, ...settings};
    notifyListeners();
  }

  Map<String, dynamic> get _defaultSettings => {
        'soundEnabled':   true,
        'hapticEnabled':  true,
      };

  // ── Delete all data for a user ────────────────────────────────────────────
  Future<void> deleteUserData(String userId) async {
    // FIREBASE: batch-delete all games + user doc
    _records.removeWhere((r) => r.userId == userId);
    _stats.remove(userId);
    _settings.remove(userId);
    if (_seededUserId == userId) _seededUserId = null;
    notifyListeners();
  }

  // ── Demo seed data ────────────────────────────────────────────────────────
  void _seedMockData(String userId) {
    if (_seededUserId == userId) return;
    _seededUserId = userId;

    final now = DateTime.now();
    final seed = [
      GameRecord(
        id:            'demo-001',
        userId:        userId,
        player1Name:   'You',
        player2Name:   'Alex',
        winner:        'player1',
        isOngoing:     false,
        startedAt:     now.subtract(const Duration(hours: 2, minutes: 10)),
        endedAt:       now.subtract(const Duration(hours: 1, minutes: 52)),
        roundsPlayed:  47,
        p1WarsWon:     5,
        p2WarsWon:     3,
        cardsRemoved:  8,
        trumpSuit:     '♥',
        muskRank:      7,
        achievements:  ['firstBlood', 'warWinner', 'trumpWin', 'muskCreator'],
        usedSecondWind: false,
      ),
      GameRecord(
        id:            'demo-002',
        userId:        userId,
        player1Name:   'You',
        player2Name:   'Sam',
        winner:        'player2',
        isOngoing:     false,
        startedAt:     now.subtract(const Duration(days: 1, hours: 3)),
        endedAt:       now.subtract(const Duration(days: 1, hours: 2)),
        roundsPlayed:  83,
        p1WarsWon:     4,
        p2WarsWon:     7,
        cardsRemoved:  14,
        trumpSuit:     '♠',
        muskRank:      null,
        achievements:  ['firstWar', 'doubleWar', 'secondWindReceiver'],
        usedSecondWind: true,
        secondWindRecipient: 'Player 2',
      ),
      GameRecord(
        id:            'demo-003',
        userId:        userId,
        player1Name:   'You',
        player2Name:   'Jordan',
        winner:        'player1',
        isOngoing:     false,
        startedAt:     now.subtract(const Duration(days: 3)),
        endedAt:       now.subtract(const Duration(days: 2, hours: 23, minutes: 30)),
        roundsPlayed:  19,
        p1WarsWon:     2,
        p2WarsWon:     1,
        cardsRemoved:  4,
        trumpSuit:     '♦',
        muskRank:      10,
        achievements:  ['speedDemon', 'jokerWin', 'trumpSetter'],
        usedSecondWind: false,
      ),
      GameRecord(
        id:            'demo-004',
        userId:        userId,
        player1Name:   'You',
        player2Name:   'Riley',
        winner:        'player1',
        isOngoing:     false,
        startedAt:     now.subtract(const Duration(days: 7)),
        endedAt:       now.subtract(const Duration(days: 6, hours: 22)),
        roundsPlayed:  112,
        p1WarsWon:     9,
        p2WarsWon:     6,
        cardsRemoved:  22,
        trumpSuit:     '♣',
        muskRank:      14,
        achievements:  ['marathon', 'warMachine', 'muskWin', 'domination', 'cleanSweep'],
        usedSecondWind: false,
      ),
    ];

    for (final r in seed) {
      _records.add(r);
    }

    // Compute seeded stats
    var stats = PlayerStats.empty;
    for (final r in seed) {
      stats = stats.applyGame(r);
    }
    _stats[userId] = stats;
  }
}