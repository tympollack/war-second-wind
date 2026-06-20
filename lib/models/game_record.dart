class GameRecord {
  final String id;
  final String userId;        // owning player's UID
  final String player1Name;
  final String player2Name;
  final String? winner;       // 'player1' | 'player2' | null (ongoing / draw)
  final bool isOngoing;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int roundsPlayed;
  final int p1WarsWon;
  final int p2WarsWon;
  final int cardsRemoved;     // cards permanently removed by war
  final String? trumpSuit;    // '♠' '♥' '♦' '♣' or null
  final int? muskRank;        // 2-14 or null
  final List<String> achievements;  // Achievement.name strings
  final bool usedSecondWind;
  final String? secondWindRecipient;

  const GameRecord({
    required this.id,
    required this.userId,
    required this.player1Name,
    required this.player2Name,
    required this.isOngoing,
    required this.startedAt,
    required this.roundsPlayed,
    required this.p1WarsWon,
    required this.p2WarsWon,
    required this.cardsRemoved,
    required this.achievements,
    required this.usedSecondWind,
    this.winner,
    this.endedAt,
    this.trumpSuit,
    this.muskRank,
    this.secondWindRecipient,
  });

  // ── Derived ───────────────────────────────────────────────────────────────
  bool get player1Won  => winner == 'player1';
  bool get player2Won  => winner == 'player2';
  int  get totalWars   => p1WarsWon + p2WarsWon;

  Duration? get duration =>
      endedAt != null ? endedAt!.difference(startedAt) : null;

  String get resultLabel {
    if (isOngoing) return 'Ongoing';
    if (winner == 'player1') return 'Won';
    if (winner == 'player2') return 'Lost';
    return 'Draw';
  }

  String get relativeDate {
    final now = DateTime.now();
    final diff = now.difference(startedAt);
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24)  return '${diff.inHours}h ago';
    if (diff.inDays    == 1)  return 'Yesterday';
    if (diff.inDays    < 7)   return '${diff.inDays}d ago';
    return '${startedAt.month}/${startedAt.day}/${startedAt.year}';
  }

  // ── Firestore serialisation ───────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'userId':               userId,
        'player1Name':          player1Name,
        'player2Name':          player2Name,
        'winner':               winner,
        'isOngoing':            isOngoing,
        'startedAt':            startedAt.toIso8601String(),
        'endedAt':              endedAt?.toIso8601String(),
        'roundsPlayed':         roundsPlayed,
        'p1WarsWon':            p1WarsWon,
        'p2WarsWon':            p2WarsWon,
        'cardsRemoved':         cardsRemoved,
        'trumpSuit':            trumpSuit,
        'muskRank':             muskRank,
        'achievements':         achievements,
        'usedSecondWind':       usedSecondWind,
        'secondWindRecipient':  secondWindRecipient,
      };

  factory GameRecord.fromMap(String id, Map<String, dynamic> m) => GameRecord(
        id:                   id,
        userId:               m['userId']              as String,
        player1Name:          m['player1Name']         as String,
        player2Name:          m['player2Name']         as String,
        winner:               m['winner']              as String?,
        isOngoing:            m['isOngoing']           as bool,
        startedAt:            DateTime.parse(m['startedAt'] as String),
        endedAt:              m['endedAt'] != null
                                ? DateTime.parse(m['endedAt'] as String)
                                : null,
        roundsPlayed:         m['roundsPlayed']        as int,
        p1WarsWon:            m['p1WarsWon']           as int,
        p2WarsWon:            m['p2WarsWon']           as int,
        cardsRemoved:         m['cardsRemoved']        as int,
        trumpSuit:            m['trumpSuit']           as String?,
        muskRank:             m['muskRank']            as int?,
        achievements:         List<String>.from(m['achievements'] as List),
        usedSecondWind:       m['usedSecondWind']      as bool,
        secondWindRecipient:  m['secondWindRecipient'] as String?,
      );

  // FIREBASE: In Firestore, use Timestamp instead of ISO strings:
  // 'startedAt': FieldValue.serverTimestamp(),
  // factory GameRecord.fromDoc(DocumentSnapshot doc) =>
  //     GameRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>);
}