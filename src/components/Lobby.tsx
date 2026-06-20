"use client";

import { useState, useEffect } from "react";
import { createClient } from "@/lib/supabase-client";
import type { MatchRow } from "@/lib/types";
import { createInitialGameState } from "@/lib/game-engine";

interface LobbyProps {
  userId: string;
  displayName: string;
  onJoinMatch: (matchId: string) => void;
  onSignOut: () => void;
}

export default function Lobby({ userId, displayName, onJoinMatch, onSignOut }: LobbyProps) {
  const [joinCode, setJoinCode] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [waitingMatch, setWaitingMatch] = useState<MatchRow | null>(null);

  const supabase = createClient();

  // Listen for opponent joining
  useEffect(() => {
    if (!waitingMatch) return;

    const channel = supabase
      .channel(`match-${waitingMatch.id}`)
      .on(
        "postgres_changes",
        {
          event: "UPDATE",
          schema: "public",
          table: "matches",
          filter: `id=eq.${waitingMatch.id}`,
        },
        (payload) => {
          const updated = payload.new as MatchRow;
          if (updated.status === "in-progress" && updated.player2_id) {
            onJoinMatch(updated.id);
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [waitingMatch, supabase, onJoinMatch]);

  async function handleCreateGame() {
    setError(null);
    setLoading(true);

    try {
      const { data: match, error: matchError } = await supabase
        .from("matches")
        .insert({ player1_id: userId, status: "waiting" })
        .select()
        .single();

      if (matchError) throw matchError;

      // Create initial game state
      const { error: stateError } = await supabase
        .from("game_states")
        .insert({
          match_id: match.id,
          state: createInitialGameState(),
          version: 0,
        });

      if (stateError) throw stateError;

      setWaitingMatch(match as MatchRow);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to create game");
    } finally {
      setLoading(false);
    }
  }

  async function handleJoinGame() {
    if (!joinCode.trim()) return;
    setError(null);
    setLoading(true);

    try {
      // Find match by code
      const { data: match, error: findError } = await supabase
        .from("matches")
        .select()
        .eq("join_code", joinCode.toUpperCase().trim())
        .eq("status", "waiting")
        .single();

      if (findError || !match) throw new Error("Game not found or already started");
      if (match.player1_id === userId) throw new Error("You cannot join your own game");

      // Join the match
      const { error: updateError } = await supabase
        .from("matches")
        .update({
          player2_id: userId,
          status: "in-progress",
        })
        .eq("id", match.id);

      if (updateError) throw updateError;

      onJoinMatch(match.id);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to join game");
    } finally {
      setLoading(false);
    }
  }

  async function handleCancelWaiting() {
    if (!waitingMatch) return;

    await supabase.from("game_states").delete().eq("match_id", waitingMatch.id);
    await supabase.from("matches").delete().eq("id", waitingMatch.id);
    setWaitingMatch(null);
  }

  if (waitingMatch) {
    return (
      <div className="w-full max-w-md mx-auto">
        <div className="bg-gray-900 border border-gray-700 rounded-2xl p-8 shadow-2xl text-center">
          <h2 className="text-2xl font-bold text-white mb-4">Waiting for Opponent</h2>
          <p className="text-gray-400 mb-6">Share this code with your opponent:</p>

          <div className="bg-gray-800 rounded-xl p-6 mb-6">
            <p className="text-4xl font-mono font-bold text-indigo-400 tracking-[0.3em]">
              {waitingMatch.join_code}
            </p>
          </div>

          <div className="flex items-center justify-center gap-3 mb-6">
            <div className="w-3 h-3 bg-indigo-500 rounded-full animate-pulse" />
            <p className="text-gray-400">Waiting for player 2...</p>
          </div>

          <button
            onClick={handleCancelWaiting}
            className="px-6 py-2 border border-gray-600 text-gray-400 rounded-lg hover:bg-gray-800 transition-colors"
          >
            Cancel
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="w-full max-w-md mx-auto">
      <div className="bg-gray-900 border border-gray-700 rounded-2xl p-8 shadow-2xl">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h2 className="text-2xl font-bold text-white">Lobby</h2>
            <p className="text-gray-400 text-sm">Welcome, {displayName}</p>
          </div>
          <button
            onClick={onSignOut}
            className="text-sm text-gray-500 hover:text-gray-300 transition-colors"
          >
            Sign Out
          </button>
        </div>

        <div className="space-y-6">
          {/* Create Game */}
          <div>
            <button
              onClick={handleCreateGame}
              disabled={loading}
              className="w-full py-4 px-6 bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 text-white font-semibold rounded-xl transition-colors text-lg"
            >
              {loading ? "Creating..." : "Create Game"}
            </button>
          </div>

          <div className="flex items-center gap-4">
            <div className="flex-1 h-px bg-gray-700" />
            <span className="text-gray-500 text-sm">or</span>
            <div className="flex-1 h-px bg-gray-700" />
          </div>

          {/* Join Game */}
          <div>
            <label className="block text-sm text-gray-400 mb-2">Enter Game Code</label>
            <div className="flex gap-3">
              <input
                type="text"
                placeholder="ABC123"
                value={joinCode}
                onChange={(e) => setJoinCode(e.target.value.toUpperCase())}
                maxLength={6}
                className="flex-1 px-4 py-3 bg-gray-800 border border-gray-600 rounded-lg text-white font-mono text-lg tracking-widest text-center placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 uppercase"
              />
              <button
                onClick={handleJoinGame}
                disabled={loading || !joinCode.trim()}
                className="px-6 py-3 bg-green-600 hover:bg-green-500 disabled:opacity-50 text-white font-semibold rounded-lg transition-colors"
              >
                Join
              </button>
            </div>
          </div>
        </div>

        {error && (
          <p className="mt-4 text-sm text-red-400 text-center">{error}</p>
        )}
      </div>
    </div>
  );
}
