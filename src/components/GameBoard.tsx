"use client";

import { useState, useEffect, useCallback } from "react";
import { createClient } from "@/lib/supabase-client";
import type { SerializedGameState, GameStateRow } from "@/lib/types";
import { advanceGame, canAdvance, createInitialGameState } from "@/lib/game-engine";
import PlayingCardDisplay, { FaceDownCard } from "./PlayingCardDisplay";

interface GameBoardProps {
  matchId: string;
  userId: string;
  onLeave: () => void;
}

export default function GameBoard({ matchId, userId, onLeave }: GameBoardProps) {
  const [gameState, setGameState] = useState<SerializedGameState | null>(null);
  const [gameStateId, setGameStateId] = useState<string | null>(null);
  const [version, setVersion] = useState(0);
  const [playerNum, setPlayerNum] = useState<1 | 2>(1);
  const [error, setError] = useState<string | null>(null);

  const supabase = createClient();

  // Load initial game state
  useEffect(() => {
    async function load() {
      const { data: match } = await supabase
        .from("matches")
        .select()
        .eq("id", matchId)
        .single();

      if (match) {
        setPlayerNum(match.player1_id === userId ? 1 : 2);
      }

      const { data: gs, error: gsError } = await supabase
        .from("game_states")
        .select()
        .eq("match_id", matchId)
        .single();

      if (gsError || !gs) {
        setError("Failed to load game state");
        return;
      }

      const gsRow = gs as GameStateRow;
      setGameState(gsRow.state);
      setGameStateId(gsRow.id);
      setVersion(gsRow.version);
    }

    load();
  }, [matchId, userId, supabase]);

  // Subscribe to realtime updates
  useEffect(() => {
    const channel = supabase
      .channel(`game-${matchId}`)
      .on(
        "postgres_changes",
        {
          event: "UPDATE",
          schema: "public",
          table: "game_states",
          filter: `match_id=eq.${matchId}`,
        },
        (payload) => {
          const updated = payload.new as GameStateRow;
          setGameState(updated.state);
          setVersion(updated.version);
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [matchId, supabase]);

  const handleAdvance = useCallback(async () => {
    if (!gameState || !canAdvance(gameState) || !gameStateId) return;

    const playerLabel = `Player ${playerNum}`;
    const nextState = advanceGame(gameState, playerLabel);

    // Optimistic update
    setGameState(nextState);
    const nextVersion = version + 1;
    setVersion(nextVersion);

    const { error: updateError } = await supabase
      .from("game_states")
      .update({
        state: nextState,
        version: nextVersion,
      })
      .eq("id", gameStateId);

    if (updateError) {
      setError("Failed to sync game state");
    }
  }, [gameState, gameStateId, version, playerNum, supabase]);

  const handleNewGame = useCallback(async () => {
    if (!gameStateId) return;

    const freshState = createInitialGameState();
    setGameState(freshState);
    setVersion(0);

    await supabase
      .from("game_states")
      .update({
        state: freshState,
        version: 0,
      })
      .eq("id", gameStateId);

    await supabase
      .from("matches")
      .update({ status: "in-progress", winner_id: null })
      .eq("id", matchId);
  }, [gameStateId, matchId, supabase]);

  if (!gameState) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-gray-400 text-lg">Loading game...</div>
      </div>
    );
  }

  const isGameOver = gameState.phase === "game-over";
  const isWar = gameState.phase === "war-pending" || gameState.phase === "war-result";
  const showCards = gameState.p1BattleCard && gameState.p2BattleCard;

  return (
    <div className="min-h-screen bg-gray-950 flex flex-col">
      {/* Top bar */}
      <div className="flex items-center justify-between px-6 py-3 bg-gray-900 border-b border-gray-800">
        <button
          onClick={onLeave}
          className="text-sm text-gray-500 hover:text-gray-300 transition-colors"
        >
          Leave Game
        </button>
        <div className="text-sm text-gray-400">
          Round {gameState.round} | You are Player {playerNum}
        </div>
        <div className="text-sm text-gray-500">
          {gameState.warDepth > 0 && (
            <span className="text-red-400 font-bold">
              WAR {gameState.warDepth > 1 ? `x${gameState.warDepth}` : ""}
            </span>
          )}
        </div>
      </div>

      {/* Status banner */}
      {gameState.statusBanner && (
        <div className="bg-indigo-900/50 border-b border-indigo-700 px-4 py-2 text-center text-indigo-200 font-medium">
          {gameState.statusBanner}
        </div>
      )}

      {/* Game info bar */}
      <div className="flex items-center justify-center gap-6 px-6 py-2 bg-gray-900/50 text-xs text-gray-500">
        {gameState.trumpSuit && (
          <span>Trump: <span className="text-yellow-400 font-bold capitalize">{gameState.trumpSuit}</span></span>
        )}
        {gameState.muskRank !== null && (
          <span>Musketeer: <span className="text-purple-400 font-bold">{gameState.muskRank}</span></span>
        )}
        {gameState.pot.length > 0 && (
          <span>Pot: <span className="text-orange-400 font-bold">{gameState.pot.length}</span></span>
        )}
        {gameState.secondWindUsed && (
          <span className="text-cyan-400">Second Wind Used</span>
        )}
      </div>

      {/* Main game area */}
      <div className="flex-1 flex flex-col items-center justify-center gap-8 p-6">
        {/* Opponent area */}
        <div className="text-center">
          <div className="text-gray-400 text-sm mb-2">
            {playerNum === 1 ? "Player 2" : "Player 1"} (Opponent)
          </div>
          <div className="bg-gray-800/50 rounded-xl px-8 py-4 border border-gray-700">
            <span className="text-3xl font-bold text-white">
              {playerNum === 1 ? gameState.p2Deck.length : gameState.p1Deck.length}
            </span>
            <span className="text-gray-500 ml-2 text-sm">cards</span>
          </div>
        </div>

        {/* Battle area */}
        <div className="flex items-center gap-12">
          {/* Face down cards (war) */}
          {isWar && (
            <FaceDownCard count={playerNum === 1 ? gameState.p2FaceDownCount : gameState.p1FaceDownCount} size="sm" />
          )}

          {/* Opponent card */}
          <div className="flex flex-col items-center gap-2">
            {showCards && (
              <PlayingCardDisplay
                card={playerNum === 1 ? gameState.p2BattleCard! : gameState.p1BattleCard!}
                gameState={gameState}
                isWinner={
                  (playerNum === 1 && gameState.lastResult === "p2-wins") ||
                  (playerNum === 2 && gameState.lastResult === "p1-wins")
                }
                size="lg"
              />
            )}
            {!showCards && (
              <div className="w-32 h-48 rounded-xl border-2 border-dashed border-gray-700 flex items-center justify-center">
                <span className="text-gray-600 text-sm">Opponent</span>
              </div>
            )}
          </div>

          {/* VS divider */}
          <div className="flex flex-col items-center">
            {gameState.roundReason && (
              <div className="text-sm text-gray-300 font-medium mb-2 text-center max-w-[200px]">
                {gameState.roundReason}
              </div>
            )}
            <div className={`text-2xl font-black ${isWar ? "text-red-500 animate-pulse" : "text-gray-600"}`}>
              VS
            </div>
          </div>

          {/* Player card */}
          <div className="flex flex-col items-center gap-2">
            {showCards && (
              <PlayingCardDisplay
                card={playerNum === 1 ? gameState.p1BattleCard! : gameState.p2BattleCard!}
                gameState={gameState}
                isWinner={
                  (playerNum === 1 && gameState.lastResult === "p1-wins") ||
                  (playerNum === 2 && gameState.lastResult === "p2-wins")
                }
                size="lg"
              />
            )}
            {!showCards && (
              <div className="w-32 h-48 rounded-xl border-2 border-dashed border-gray-700 flex items-center justify-center">
                <span className="text-gray-600 text-sm">You</span>
              </div>
            )}
          </div>

          {/* Face down cards (war) */}
          {isWar && (
            <FaceDownCard count={playerNum === 1 ? gameState.p1FaceDownCount : gameState.p2FaceDownCount} size="sm" />
          )}
        </div>

        {/* Player area */}
        <div className="text-center">
          <div className="bg-gray-800/50 rounded-xl px-8 py-4 border border-gray-700">
            <span className="text-3xl font-bold text-white">
              {playerNum === 1 ? gameState.p1Deck.length : gameState.p2Deck.length}
            </span>
            <span className="text-gray-500 ml-2 text-sm">cards</span>
          </div>
          <div className="text-indigo-400 text-sm mt-2">
            You (Player {playerNum})
          </div>
        </div>

        {/* Second Wind indicator */}
        {!gameState.secondWindUsed && gameState.secondWindDeck.length > 0 && (
          <div className="flex items-center gap-2 px-4 py-2 bg-cyan-900/30 border border-cyan-700 rounded-lg">
            <span className="text-cyan-400 text-sm font-medium">
              Second Wind Available ({gameState.secondWindDeck.length} cards)
            </span>
          </div>
        )}
      </div>

      {/* Action area */}
      <div className="px-6 py-6 bg-gray-900 border-t border-gray-800">
        {isGameOver ? (
          <div className="text-center space-y-4">
            <div className="text-2xl font-bold text-white">
              {gameState.gameWinner === `Player ${playerNum}` ? (
                <span className="text-green-400">You Win!</span>
              ) : (
                <span className="text-red-400">You Lose</span>
              )}
            </div>
            <div className="flex gap-4 justify-center">
              <button
                onClick={handleNewGame}
                className="px-6 py-3 bg-indigo-600 hover:bg-indigo-500 text-white font-semibold rounded-lg transition-colors"
              >
                Play Again
              </button>
              <button
                onClick={onLeave}
                className="px-6 py-3 border border-gray-600 text-gray-400 hover:bg-gray-800 rounded-lg transition-colors"
              >
                Leave
              </button>
            </div>
          </div>
        ) : (
          <div className="text-center">
            <button
              onClick={handleAdvance}
              disabled={!canAdvance(gameState)}
              className={`
                px-12 py-4 rounded-xl font-bold text-lg transition-all
                ${canAdvance(gameState)
                  ? "bg-indigo-600 hover:bg-indigo-500 text-white shadow-lg shadow-indigo-500/20 hover:shadow-indigo-500/40"
                  : "bg-gray-800 text-gray-600 cursor-not-allowed"
                }
              `}
            >
              {gameState.phase === "idle" && "Play Card"}
              {gameState.phase === "result" && gameState.lastResult === "tie" && "Go to War!"}
              {gameState.phase === "result" && gameState.lastResult !== "tie" && "Collect Cards"}
              {gameState.phase === "war-pending" && "Flip War Card"}
              {gameState.phase === "war-result" && gameState.lastResult === "tie" && "Double War!"}
              {gameState.phase === "war-result" && gameState.lastResult !== "tie" && "Collect All"}
            </button>
            <p className="text-gray-600 text-xs mt-2">
              {gameState.phase === "idle" && "Tap to flip the next card"}
              {gameState.phase === "war-pending" && "3 cards face down, 1 face up"}
            </p>
          </div>
        )}
      </div>

      {error && (
        <div className="fixed bottom-4 right-4 bg-red-900/80 text-red-200 px-4 py-2 rounded-lg text-sm">
          {error}
        </div>
      )}
    </div>
  );
}
