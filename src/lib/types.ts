// ── Card Types ─────────────────────────────────────────────
export type Suit = "spades" | "hearts" | "diamonds" | "clubs";
export type CardStatus = "trump" | "musketeer" | "normal";

export interface PlayingCard {
  id: number; // 0-53
  suit: Suit | null; // null for jokers
  rank: number; // 2-14 for regular, 15 for joker
  isJoker: boolean;
}

// ── Game Types ─────────────────────────────────────────────
export type GamePhase =
  | "idle"
  | "flipping"
  | "result"
  | "war-pending"
  | "war-flipping"
  | "war-result"
  | "game-over";

export type RoundResult = "p1-wins" | "p2-wins" | "tie";

export interface SerializedGameState {
  p1Deck: PlayingCard[];
  p2Deck: PlayingCard[];
  secondWindDeck: PlayingCard[];
  secondWindUsed: boolean;
  secondWindRecipient: string | null;
  trumpSuit: Suit | null;
  muskRank: number | null;
  removedByRank: Record<number, number>;
  removedCardIds: number[];
  p1BattleCard: PlayingCard | null;
  p2BattleCard: PlayingCard | null;
  pot: PlayingCard[];
  p1FaceDownCount: number;
  p2FaceDownCount: number;
  phase: GamePhase;
  lastResult: RoundResult | null;
  gameWinner: string | null;
  round: number;
  warDepth: number;
  roundReason: string | null;
  statusBanner: string | null;
  lastActionBy: string | null;
  lastActionTimestamp: number;
}

// ── Supabase Row Types ─────────────────────────────────────
export type MatchStatus = "waiting" | "in-progress" | "completed";

export interface MatchRow {
  id: string;
  join_code: string;
  status: MatchStatus;
  player1_id: string | null;
  player2_id: string | null;
  winner_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface GameStateRow {
  id: string;
  match_id: string;
  state: SerializedGameState;
  version: number;
  updated_at: string;
}

export interface UserRow {
  id: string;
  display_name: string;
  wins: number;
  losses: number;
  created_at: string;
  updated_at: string;
}
