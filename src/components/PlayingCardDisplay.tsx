"use client";

import type { PlayingCard } from "@/lib/types";
import type { SerializedGameState } from "@/lib/types";
import { getRankLabel, getSuitSymbol, isRedCard } from "@/lib/deck";
import { getCardStatus } from "@/lib/game-engine";

interface PlayingCardDisplayProps {
  card: PlayingCard;
  gameState: SerializedGameState;
  isWinner?: boolean;
  size?: "sm" | "md" | "lg";
}

const STATUS_COLORS = {
  trump: "ring-yellow-400 bg-gradient-to-br from-yellow-900/30 to-gray-900",
  musketeer: "ring-purple-400 bg-gradient-to-br from-purple-900/30 to-gray-900",
  normal: "ring-gray-600 bg-gray-900",
  joker: "ring-cyan-400 bg-gradient-to-br from-cyan-900/30 to-gray-900",
};

const STATUS_LABELS = {
  trump: "TRUMP",
  musketeer: "MUSK",
  normal: "",
  joker: "JOKER",
};

const SIZE_CLASSES = {
  sm: "w-16 h-24 text-lg",
  md: "w-24 h-36 text-2xl",
  lg: "w-32 h-48 text-3xl",
};

export default function PlayingCardDisplay({
  card,
  gameState,
  isWinner = false,
  size = "md",
}: PlayingCardDisplayProps) {
  const status = getCardStatus(card, gameState);
  const red = isRedCard(card);
  const suitSym = getSuitSymbol(card);
  const rankLbl = getRankLabel(card);

  return (
    <div
      className={`
        relative rounded-xl ring-2 flex flex-col items-center justify-center
        transition-all duration-300
        ${SIZE_CLASSES[size]}
        ${STATUS_COLORS[status]}
        ${isWinner ? "scale-110 shadow-lg shadow-green-500/30" : ""}
      `}
    >
      {/* Status badge */}
      {STATUS_LABELS[status] && (
        <div
          className={`
            absolute -top-2 left-1/2 -translate-x-1/2 px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider
            ${status === "trump" ? "bg-yellow-500 text-black" : ""}
            ${status === "musketeer" ? "bg-purple-500 text-white" : ""}
            ${status === "joker" ? "bg-cyan-500 text-black" : ""}
          `}
        >
          {STATUS_LABELS[status]}
        </div>
      )}

      {/* Rank */}
      <span className={`font-bold ${red ? "text-red-400" : "text-white"}`}>
        {rankLbl}
      </span>

      {/* Suit */}
      <span className={`text-lg ${red ? "text-red-400" : "text-gray-300"}`}>
        {suitSym}
      </span>

      {/* Winner glow */}
      {isWinner && (
        <div className="absolute -bottom-2 left-1/2 -translate-x-1/2 px-2 py-0.5 rounded-full text-[10px] font-bold bg-green-500 text-black uppercase">
          Win
        </div>
      )}
    </div>
  );
}

export function FaceDownCard({ count, size = "md" }: { count: number; size?: "sm" | "md" | "lg" }) {
  if (count === 0) return null;

  return (
    <div className="flex items-center gap-1">
      {Array.from({ length: Math.min(count, 3) }).map((_, i) => (
        <div
          key={i}
          className={`
            rounded-xl ring-2 ring-gray-600 flex items-center justify-center
            bg-gradient-to-br from-indigo-900 to-gray-900
            ${SIZE_CLASSES[size]}
          `}
          style={{ marginLeft: i > 0 ? "-1rem" : "0" }}
        >
          <span className="text-indigo-400 text-2xl">?</span>
        </div>
      ))}
    </div>
  );
}
