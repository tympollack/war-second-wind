"use client";

import { useState, useEffect, useCallback, useMemo } from "react";
import { isSupabaseConfigured, createClient } from "@/lib/supabase-client";
import type { User } from "@supabase/supabase-js";
import AuthForm from "@/components/AuthForm";
import Lobby from "@/components/Lobby";
import GameBoard from "@/components/GameBoard";

type Screen = "auth" | "lobby" | "game" | "setup";

export default function Home() {
  const [user, setUser] = useState<User | null>(null);
  const [displayName, setDisplayName] = useState("Player");
  const configured = useMemo(() => isSupabaseConfigured(), []);
  const [screen, setScreen] = useState<Screen>(configured ? "auth" : "setup");
  const [matchId, setMatchId] = useState<string | null>(null);
  const [loading, setLoading] = useState(configured);

  useEffect(() => {
    if (!configured) return;

    const supabase = createClient();

    async function init() {
      const { data: { session } } = await supabase.auth.getSession();
      if (session?.user) {
        setUser(session.user);
        setScreen("lobby");

        const { data: profile } = await supabase
          .from("users")
          .select("display_name")
          .eq("id", session.user.id)
          .single();

        if (profile) {
          setDisplayName(profile.display_name);
        }
      }
      setLoading(false);
    }

    init();

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (_event, session) => {
        if (session?.user) {
          setUser(session.user);
          setScreen("lobby");

          const { data: profile } = await supabase
            .from("users")
            .select("display_name")
            .eq("id", session.user.id)
            .single();

          if (profile) {
            setDisplayName(profile.display_name);
          }
        } else {
          setUser(null);
          setScreen("auth");
          setMatchId(null);
        }
      }
    );

    return () => subscription.unsubscribe();
  }, [configured]);

  const handleJoinMatch = useCallback((id: string) => {
    setMatchId(id);
    setScreen("game");
  }, []);

  const handleSignOut = useCallback(async () => {
    if (!configured) return;
    const supabase = createClient();
    await supabase.auth.signOut();
    setUser(null);
    setScreen("auth");
    setMatchId(null);
  }, [configured]);

  const handleLeaveGame = useCallback(() => {
    setMatchId(null);
    setScreen("lobby");
  }, []);

  if (loading) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <div className="text-gray-400 text-lg">Loading...</div>
      </div>
    );
  }

  if (screen === "game" && matchId && user) {
    return (
      <GameBoard
        matchId={matchId}
        userId={user.id}
        onLeave={handleLeaveGame}
      />
    );
  }

  return (
    <div className="flex-1 flex flex-col items-center justify-center p-6">
      <div className="mb-8 text-center">
        <h1 className="text-5xl font-black text-white tracking-tight mb-2">
          WAR
        </h1>
        <p className="text-indigo-400 text-lg font-medium tracking-widest uppercase">
          Second Wind
        </p>
      </div>

      {screen === "setup" && (
        <div className="w-full max-w-md mx-auto">
          <div className="bg-gray-900 border border-gray-700 rounded-2xl p-8 shadow-2xl text-center">
            <h2 className="text-xl font-bold text-white mb-4">Setup Required</h2>
            <p className="text-gray-400 mb-4">
              Supabase is not configured. To get started:
            </p>
            <ol className="text-left text-gray-300 text-sm space-y-2 mb-6">
              <li>1. Create a project at <a href="https://supabase.com" className="text-indigo-400 hover:underline" target="_blank" rel="noopener noreferrer">supabase.com</a></li>
              <li>2. Run the SQL migration from <code className="text-xs bg-gray-800 px-1 py-0.5 rounded">supabase/migrations/</code></li>
              <li>3. Copy <code className="text-xs bg-gray-800 px-1 py-0.5 rounded">.env.local.example</code> to <code className="text-xs bg-gray-800 px-1 py-0.5 rounded">.env.local</code></li>
              <li>4. Add your Supabase URL and anon key</li>
              <li>5. Restart the dev server</li>
            </ol>
          </div>
        </div>
      )}

      {screen === "auth" && <AuthForm />}
      {screen === "lobby" && user && (
        <Lobby
          userId={user.id}
          displayName={displayName}
          onJoinMatch={handleJoinMatch}
          onSignOut={handleSignOut}
        />
      )}
    </div>
  );
}
