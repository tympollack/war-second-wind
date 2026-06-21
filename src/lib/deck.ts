import type { PlayingCard, Suit } from "./types";

const SUITS: Suit[] = ["spades", "hearts", "diamonds", "clubs"];

const RANK_LABELS: Record<number, string> = {
  2: "2", 3: "3", 4: "4", 5: "5", 6: "6", 7: "7",
  8: "8", 9: "9", 10: "10", 11: "J", 12: "Q", 13: "K", 14: "A",
};

const RANK_NAMES: Record<number, string> = {
  2: "2", 3: "3", 4: "4", 5: "5", 6: "6", 7: "7", 8: "8",
  9: "9", 10: "10", 11: "Jack", 12: "Queen", 13: "King", 14: "Ace",
};

const SUIT_SYMBOLS: Record<Suit, string> = {
  spades: "\u2660",
  hearts: "\u2665",
  diamonds: "\u2666",
  clubs: "\u2663",
};

export function buildFullDeck(): PlayingCard[] {
  const deck: PlayingCard[] = [];
  let id = 0;
  for (const suit of SUITS) {
    for (let r = 2; r <= 14; r++) {
      deck.push({ id: id++, suit, rank: r, isJoker: false });
    }
  }
  deck.push({ id: id++, suit: null, rank: 15, isJoker: true });
  deck.push({ id: id++, suit: null, rank: 15, isJoker: true });
  return shuffleArray(deck);
}

export function shuffleArray<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

export function getRankLabel(card: PlayingCard): string {
  if (card.isJoker) return "\u2605";
  return RANK_LABELS[card.rank] ?? "?";
}

export function getRankName(card: PlayingCard): string {
  if (card.isJoker) return "Joker";
  return RANK_NAMES[card.rank] ?? "?";
}

export function getSuitSymbol(card: PlayingCard): string {
  if (card.isJoker || !card.suit) return "\u2605";
  return SUIT_SYMBOLS[card.suit];
}

export function isRedCard(card: PlayingCard): boolean {
  return card.suit === "hearts" || card.suit === "diamonds";
}
