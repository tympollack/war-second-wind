# War: Second Wind

A real-time, multiplayer web-based card game — an advanced variant of the classic "War" with special card statuses, comeback mechanics, and real-time multiplayer.

## Tech Stack

- **Frontend**: Next.js (React), Tailwind CSS, TypeScript
- **Backend/Database**: Supabase (PostgreSQL)
- **Realtime**: Supabase Realtime Channels
- **Auth**: Supabase Auth (Anonymous or Email/Password)
- **Hosting**: Vercel

## Game Rules

### Standard War with Twists

- **54-card deck** (52 + 2 Jokers), split into 18 cards per player + 18 reserve (Second Wind deck)
- Cards have values 2-14 (Ace high) plus Jokers (rank 15)

### Card Statuses

- **Normal**: Standard card
- **Trump**: First time two cards share a suit, that suit becomes Trump (beats Normal)
- **Musketeer**: First War's tied rank becomes Musketeer (beats Trump and Normal)
- **Joker**: Beats everything

### The "Always War" Rule

If two cards share the same numeric value, it **always** triggers a War — regardless of suit or status.

### War Resolution

Both players place 3 cards face down and 1 face up. The face-up cards follow the same comparison rules. Equal values = Double War.

### Second Wind

When a player's deck hits 0 cards for the first time, they receive the 18-card reserve deck instead of losing. This can only happen once per game.

## Setup

```bash
npm install
cp .env.local.example .env.local
# Fill in your Supabase URL and anon key in .env.local
npm run dev
```

### Supabase Setup

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Run the SQL migration in `supabase/migrations/00001_initial_schema.sql` in the Supabase SQL Editor
3. Enable Anonymous Sign-in in Authentication > Providers
4. Copy your project URL and anon key into `.env.local`

## Development

```bash
npm run dev      # Start dev server
npm run build    # Production build
npm run lint     # Run linter
```
