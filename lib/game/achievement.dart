enum Achievement {
  // ── Basics ────────────────────
  firstBlood,
  firstWar,
  // ── Joker ─────────────────────
  jokerWin,
  jokerVsJoker,
  // ── Trump ─────────────────────
  trumpSetter,
  trumpWin,
  // ── Musk ──────────────────────
  muskCreator,
  muskWin,
  muskVsMusk,
  muskDestroyer,
  // ── War ───────────────────────
  warWinner,
  ruthless,
  doubleWar,
  tripleWar,
  warMachine,
  // ── Comeback ──────────────────
  secondWindReceiver,
  secondWindVictory,
  cliffhanger,
  // ── Dominance ─────────────────
  domination,
  supremacy,
  // ── Length ────────────────────
  speedDemon,
  marathon,
  // ── Other ─────────────────────
  cleanSweep,
}

class AchievementMeta {
  final String title;
  final String description;
  final String emoji;
  const AchievementMeta({
    required this.title,
    required this.description,
    required this.emoji,
  });
}

const Map<Achievement, AchievementMeta> kAchievementMeta = {
  Achievement.firstBlood: AchievementMeta(
    title: 'First Blood', emoji: '🩸',
    description: 'Win the very first round',
  ),
  Achievement.firstWar: AchievementMeta(
    title: 'Trial by Fire', emoji: '⚔️',
    description: 'Survive the first War',
  ),
  Achievement.jokerWin: AchievementMeta(
    title: 'Wild Card', emoji: '🃏',
    description: 'Win a round by playing a Joker',
  ),
  Achievement.jokerVsJoker: AchievementMeta(
    title: 'Clash of Fools', emoji: '🤡',
    description: 'Both players flip a Joker at once',
  ),
  Achievement.trumpSetter: AchievementMeta(
    title: 'Kingmaker', emoji: '👑',
    description: 'Your card helped set the Trump suit',
  ),
  Achievement.trumpWin: AchievementMeta(
    title: 'Home Field', emoji: '🏆',
    description: 'Win a round by Trump suit advantage',
  ),
  Achievement.muskCreator: AchievementMeta(
    title: 'Musk Protocol', emoji: '🔥',
    description: 'Your war created the Musk card value',
  ),
  Achievement.muskWin: AchievementMeta(
    title: 'Unstoppable', emoji: '💀',
    description: 'Win a round with a Musk card',
  ),
  Achievement.muskVsMusk: AchievementMeta(
    title: 'Musk Collision', emoji: '💥',
    description: 'Both players play a Musk card simultaneously',
  ),
  Achievement.muskDestroyer: AchievementMeta(
    title: 'Power Vacuum', emoji: '⚡',
    description: 'All four Musk-rank cards are destroyed in war',
  ),
  Achievement.warWinner: AchievementMeta(
    title: 'Warlord', emoji: '⚔️',
    description: 'Win your first War',
  ),
  Achievement.ruthless: AchievementMeta(
    title: 'Ruthless', emoji: '😈',
    description: 'Win a War where the opponent played 0 face-down cards',
  ),
  Achievement.doubleWar: AchievementMeta(
    title: 'Double Trouble', emoji: '⚔️⚔️',
    description: 'Survive a War-within-a-War',
  ),
  Achievement.tripleWar: AchievementMeta(
    title: 'Apocalypse', emoji: '🌋',
    description: 'Survive three Wars in a chain',
  ),
  Achievement.warMachine: AchievementMeta(
    title: 'War Machine', emoji: '🤖',
    description: 'Win 5 Wars in a single game',
  ),
  Achievement.secondWindReceiver: AchievementMeta(
    title: 'Second Wind', emoji: '💨',
    description: 'Receive the reserve deck when your hand runs out',
  ),
  Achievement.secondWindVictory: AchievementMeta(
    title: 'Phoenix Rising', emoji: '🦅',
    description: 'Win the game after receiving the Second Wind',
  ),
  Achievement.cliffhanger: AchievementMeta(
    title: 'On the Edge', emoji: '😰',
    description: 'Win a round when you had only 1 card left',
  ),
  Achievement.domination: AchievementMeta(
    title: 'Domination', emoji: '💪',
    description: 'Hold 30 or more cards at once',
  ),
  Achievement.supremacy: AchievementMeta(
    title: 'Supremacy', emoji: '👊',
    description: 'Hold 40 or more cards at once',
  ),
  Achievement.speedDemon: AchievementMeta(
    title: 'Speed Demon', emoji: '⚡',
    description: 'Win the game in under 20 rounds',
  ),
  Achievement.marathon: AchievementMeta(
    title: 'Marathon', emoji: '🏃',
    description: 'Play 100 or more rounds in one game',
  ),
  Achievement.cleanSweep: AchievementMeta(
    title: 'Clean Sweep', emoji: '✨',
    description: 'Win without needing the Second Wind',
  ),
};
