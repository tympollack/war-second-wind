class PlayerStats {
  final int totalGames;
  final int wins;
  final int losses;
  final int totalRounds;
  final int totalWarsWon;
  final int totalCardsRemoved;
  final List<String> achievements;  // Achievement.name strings
  final int fastestWin;             // 0 = never won
  final int longestGame;            // 0 = never played
  final int mostWarsInGame;         // 0 = no wars yet

  const PlayerStats({
    required this.totalGames,
    required this.wins,
    required this.losses,
    required this.totalRounds,
    required this.totalWarsWon,
    required this.totalCardsRemoved,
    required this.achievements,
    required this.fastestWin,
    required this.longestGame,
    required this.mostWarsInGame,
  });

  // ── Derived ───────────────────────────────────────────────────────────────
  double get winRate       => totalGames > 0 ? wins / totalGames : 0;
  int    get draws         => totalGames - wins - losses;
  double get avgRounds     => totalGames > 0 ? totalRounds / totalGames : 0;
  int    get achievementCount => achievements.length;

  // ── Empty baseline ────────────────────────────────────────────────────────
  static const empty = PlayerStats(
    totalGames:        0,
    wins:              0,
    losses:            0,
    totalRounds:       0,
    totalWarsWon:      0,
    totalCardsRemoved: 0,
    achievements:      [],
    fastestWin:        0,
    longestGame:       0,
    mostWarsInGame:    0,
  );

  // ── Update from a newly finished game ─────────────────────────────────────
  PlayerStats applyGame(GameRecord r) {
    final isWin  = r.player1Won;
    final isLoss = r.player2Won;
    final wars   = r.p1WarsWon + r.p2WarsWon;
    final newAchievements = {
      ...achievements,
      ...r.achievements,
    }.toList();

    return PlayerStats(
      totalGames:        totalGames + 1,
      wins:              wins  + (isWin  ? 1 : 0),
      losses:            losses + (isLoss ? 1 : 0),
      totalRounds:       totalRounds + r.roundsPlayed,
      totalWarsWon:      totalWarsWon + r.p1WarsWon,
      totalCardsRemoved: totalCardsRemoved + r.cardsRemoved,
      achievements:      newAchievements,
      fastestWin:        isWin
          ? (fastestWin == 0
              ? r.roundsPlayed
              : fastestWin < r.roundsPlayed ? fastestWin : r.roundsPlayed)
          : fastestWin,
      longestGame:  r.roundsPlayed > longestGame ? r.roundsPlayed : longestGame,
      mostWarsInGame: wars > mostWarsInGame ? wars : mostWarsInGame,
    );
  }

  // ── Firestore serialisation ───────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'totalGames':        totalGames,
        'wins':              wins,
        'losses':            losses,
        'totalRounds':       totalRounds,
        'totalWarsWon':      totalWarsWon,
        'totalCardsRemoved': totalCardsRemoved,
        'achievements':      achievements,
        'fastestWin':        fastestWin,
        'longestGame':       longestGame,
        'mostWarsInGame':    mostWarsInGame,
      };

  factory PlayerStats.fromMap(Map<String, dynamic> m) => PlayerStats(
        totalGames:        (m['totalGames']        as int?) ?? 0,
        wins:              (m['wins']              as int?) ?? 0,
        losses:            (m['losses']            as int?) ?? 0,
        totalRounds:       (m['totalRounds']       as int?) ?? 0,
        totalWarsWon:      (m['totalWarsWon']      as int?) ?? 0,
        totalCardsRemoved: (m['totalCardsRemoved'] as int?) ?? 0,
        achievements:      List<String>.from((m['achievements'] as List?) ?? []),
        fastestWin:        (m['fastestWin']        as int?) ?? 0,
        longestGame:       (m['longestGame']       as int?) ?? 0,
        mostWarsInGame:    (m['mostWarsInGame']    as int?) ?? 0,
      );

  // FIREBASE: Store under /users/{uid}/stats or merge into /users/{uid}
  // Update atomically with:
  // _db.collection('users').doc(uid).set(stats.toMap(), SetOptions(merge: true));
}