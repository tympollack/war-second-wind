import type {
  PlayingCard,
  Suit,
  RoundResult,
  SerializedGameState,
} from "./types";
import { buildFullDeck, shuffleArray, getRankName } from "./deck";

// ─────────────────────────────────────────────────────────────
// GameEngine: pure-logic engine for "War: Second Wind"
// All state is serializable for Supabase JSONB storage.
// ─────────────────────────────────────────────────────────────

export function createInitialGameState(): SerializedGameState {
  const allCards = buildFullDeck();
  return {
    p1Deck: allCards.slice(0, 18),
    p2Deck: allCards.slice(18, 36),
    secondWindDeck: allCards.slice(36, 54),
    secondWindUsed: false,
    secondWindRecipient: null,
    trumpSuit: null,
    muskRank: null,
    removedByRank: {},
    removedCardIds: [],
    p1BattleCard: null,
    p2BattleCard: null,
    pot: [],
    p1FaceDownCount: 0,
    p2FaceDownCount: 0,
    phase: "idle",
    lastResult: null,
    gameWinner: null,
    round: 0,
    warDepth: 0,
    roundReason: null,
    statusBanner: null,
    lastActionBy: null,
    lastActionTimestamp: Date.now(),
  };
}

// ── Card Status Helpers ──────────────────────────────────────

function isMuskCard(card: PlayingCard, muskRank: number | null, removedByRank: Record<number, number>): boolean {
  if (muskRank === null || card.isJoker) return false;
  if ((removedByRank[muskRank] ?? 0) >= 4) return false;
  return card.rank === muskRank;
}

function isTrumpCard(card: PlayingCard, trumpSuit: Suit | null): boolean {
  if (trumpSuit === null || card.isJoker) return false;
  return card.suit === trumpSuit;
}

function categoryOf(
  card: PlayingCard,
  trumpSuit: Suit | null,
  muskRank: number | null,
  removedByRank: Record<number, number>
): number {
  if (card.isJoker) return 3;
  if (isMuskCard(card, muskRank, removedByRank)) return 2;
  if (isTrumpCard(card, trumpSuit)) return 1;
  return 0;
}

// ── "Always War" Rule ────────────────────────────────────────
// CRITICAL: If two cards have the same numeric value, it is
// ALWAYS a tie (War), regardless of suit or status.
// Status hierarchy only applies when values differ.
function compareCards(
  a: PlayingCard,
  b: PlayingCard,
  trumpSuit: Suit | null,
  muskRank: number | null,
  removedByRank: Record<number, number>
): RoundResult {
  // Same rank = ALWAYS WAR (the "Always War" rule)
  if (a.rank === b.rank) return "tie";

  // Different ranks: use status hierarchy
  const aLvl = categoryOf(a, trumpSuit, muskRank, removedByRank);
  const bLvl = categoryOf(b, trumpSuit, muskRank, removedByRank);

  if (aLvl !== bLvl) {
    return aLvl > bLvl ? "p1-wins" : "p2-wins";
  }

  // Same category, different rank: higher rank wins
  return a.rank > b.rank ? "p1-wins" : "p2-wins";
}

function buildReason(
  p1: PlayingCard,
  p2: PlayingCard,
  result: RoundResult,
  trumpSuit: Suit | null,
  muskRank: number | null,
  removedByRank: Record<number, number>
): string {
  if (result === "tie") return "Equal rank \u2014 WAR!";
  const winner = result === "p1-wins" ? p1 : p2;
  const loser = result === "p1-wins" ? p2 : p1;
  if (winner.isJoker) return "Joker beats all!";
  if (isMuskCard(winner, muskRank, removedByRank)) return "Musketeer card dominates!";
  if (isTrumpCard(winner, trumpSuit) && !isTrumpCard(loser, trumpSuit) && !winner.isJoker) {
    return "Trump suit wins!";
  }
  return `${getRankName(winner)} beats ${getRankName(loser)}`;
}

// ── State Transitions ────────────────────────────────────────

function maybeSetTrump(state: SerializedGameState): void {
  if (state.trumpSuit !== null) return;
  const p1 = state.p1BattleCard;
  const p2 = state.p2BattleCard;
  if (!p1 || !p2 || p1.isJoker || p2.isJoker) return;
  if (p1.suit === p2.suit) {
    state.trumpSuit = p1.suit;
  }
}

function removeCardFromGame(state: SerializedGameState, card: PlayingCard): void {
  state.removedCardIds.push(card.id);
  if (!card.isJoker) {
    const prev = state.removedByRank[card.rank] ?? 0;
    state.removedByRank[card.rank] = prev + 1;
  }
}

function giveSecondWind(state: SerializedGameState, playerNum: 1 | 2): void {
  const deck = playerNum === 1 ? state.p1Deck : state.p2Deck;
  for (const c of state.secondWindDeck) {
    deck.push(c);
  }
  state.secondWindDeck = [];
  state.secondWindUsed = true;
  state.secondWindRecipient = `Player ${playerNum}`;
  state.statusBanner = `Player ${playerNum} received the Second Wind!`;
}

function endGame(state: SerializedGameState, winner: string): void {
  state.gameWinner = winner;
  state.phase = "game-over";
}

// ── Play Round ───────────────────────────────────────────────

function playRound(state: SerializedGameState): SerializedGameState {
  if (state.p1Deck.length === 0 || state.p2Deck.length === 0) {
    const winner = state.p2Deck.length === 0 ? "Player 1" : "Player 2";
    endGame(state, winner);
    return state;
  }

  state.p1BattleCard = state.p1Deck.shift()!;
  state.p2BattleCard = state.p2Deck.shift()!;
  state.round++;
  state.roundReason = null;
  state.warDepth = 0;

  maybeSetTrump(state);
  state.lastResult = compareCards(
    state.p1BattleCard,
    state.p2BattleCard,
    state.trumpSuit,
    state.muskRank,
    state.removedByRank
  );
  state.roundReason = buildReason(
    state.p1BattleCard,
    state.p2BattleCard,
    state.lastResult,
    state.trumpSuit,
    state.muskRank,
    state.removedByRank
  );

  if (state.lastResult !== "tie") {
    state.pot.push(state.p1BattleCard, state.p2BattleCard);
  }

  state.phase = state.lastResult === "tie" ? "result" : "result";
  return state;
}

// ── Start War ────────────────────────────────────────────────

function startWar(state: SerializedGameState): SerializedGameState {
  state.warDepth++;

  // Remove tied battle cards from the game permanently
  if (state.p1BattleCard) removeCardFromGame(state, state.p1BattleCard);
  if (state.p2BattleCard) removeCardFromGame(state, state.p2BattleCard);

  // First war: the removed rank becomes Musketeer
  if (state.muskRank === null && state.p1BattleCard && !state.p1BattleCard.isJoker) {
    state.muskRank = state.p1BattleCard.rank;
  }

  // Each player places up to 3 face-down cards
  const p1Take = Math.max(0, Math.min(3, state.p1Deck.length - 1));
  const p2Take = Math.max(0, Math.min(3, state.p2Deck.length - 1));
  state.p1FaceDownCount = p1Take;
  state.p2FaceDownCount = p2Take;

  for (let i = 0; i < p1Take; i++) {
    state.pot.push(state.p1Deck.shift()!);
  }
  for (let i = 0; i < p2Take; i++) {
    state.pot.push(state.p2Deck.shift()!);
  }

  state.phase = "war-pending";
  return state;
}

// ── Flip War Card ────────────────────────────────────────────

function flipWarCard(state: SerializedGameState): SerializedGameState {
  // Check if either player needs second wind
  if (state.p1Deck.length === 0) {
    if (!state.secondWindUsed) {
      giveSecondWind(state, 1);
      if (state.p1Deck.length === 0) {
        endGame(state, "Player 2");
        return state;
      }
    } else {
      endGame(state, "Player 2");
      return state;
    }
  }
  if (state.p2Deck.length === 0) {
    if (!state.secondWindUsed) {
      giveSecondWind(state, 2);
      if (state.p2Deck.length === 0) {
        endGame(state, "Player 1");
        return state;
      }
    } else {
      endGame(state, "Player 1");
      return state;
    }
  }

  state.p1BattleCard = state.p1Deck.shift()!;
  state.p2BattleCard = state.p2Deck.shift()!;
  state.roundReason = null;

  maybeSetTrump(state);
  state.lastResult = compareCards(
    state.p1BattleCard,
    state.p2BattleCard,
    state.trumpSuit,
    state.muskRank,
    state.removedByRank
  );
  state.roundReason = buildReason(
    state.p1BattleCard,
    state.p2BattleCard,
    state.lastResult,
    state.trumpSuit,
    state.muskRank,
    state.removedByRank
  );

  if (state.lastResult !== "tie") {
    state.pot.push(state.p1BattleCard, state.p2BattleCard);
  }

  state.phase = "war-result";
  return state;
}

// ── Award Pot ────────────────────────────────────────────────

function awardPot(state: SerializedGameState): SerializedGameState {
  const isP1Win = state.lastResult === "p1-wins";
  const winnerDeck = isP1Win ? state.p1Deck : state.p2Deck;
  const loserDeck = isP1Win ? state.p2Deck : state.p1Deck;
  const loserNum: 1 | 2 = isP1Win ? 2 : 1;

  const shuffled = shuffleArray(state.pot);
  for (const c of shuffled) {
    winnerDeck.push(c);
  }
  state.pot = [];

  // Reset war state
  state.warDepth = 0;
  state.p1BattleCard = null;
  state.p2BattleCard = null;
  state.lastResult = null;
  state.p1FaceDownCount = 0;
  state.p2FaceDownCount = 0;

  // Check if loser is out
  if (loserDeck.length === 0) {
    if (!state.secondWindUsed) {
      giveSecondWind(state, loserNum);
      state.phase = "idle";
      return state;
    } else {
      endGame(state, isP1Win ? "Player 1" : "Player 2");
      return state;
    }
  }

  state.phase = "idle";
  return state;
}

// ── Main Advance Function ────────────────────────────────────
// This is the single entry point for all game state transitions.
// It takes the current state and returns the next state.

export function advanceGame(
  currentState: SerializedGameState,
  actionBy: string
): SerializedGameState {
  const state = structuredClone(currentState);
  state.statusBanner = null;
  state.lastActionBy = actionBy;
  state.lastActionTimestamp = Date.now();

  switch (state.phase) {
    case "idle":
      return playRound(state);
    case "result":
      if (state.lastResult === "tie") {
        return startWar(state);
      }
      return awardPot(state);
    case "war-pending":
      return flipWarCard(state);
    case "war-result":
      if (state.lastResult === "tie") {
        return startWar(state);
      }
      return awardPot(state);
    default:
      return state;
  }
}

// ── Helpers for UI ───────────────────────────────────────────

export function getCardStatus(
  card: PlayingCard,
  state: SerializedGameState
): "trump" | "musketeer" | "normal" | "joker" {
  if (card.isJoker) return "joker";
  if (isMuskCard(card, state.muskRank, state.removedByRank)) return "musketeer";
  if (isTrumpCard(card, state.trumpSuit)) return "trump";
  return "normal";
}

export function canAdvance(state: SerializedGameState): boolean {
  return (
    state.phase === "idle" ||
    state.phase === "result" ||
    state.phase === "war-pending" ||
    state.phase === "war-result"
  );
}
