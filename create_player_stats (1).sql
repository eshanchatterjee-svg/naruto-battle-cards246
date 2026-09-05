-- 100% safe — no DROP statements at all
-- Run in: https://supabase.com/dashboard/project/icdmmmymqypcpobeyaeb/sql

-- 1. Create table (skips if already exists)
CREATE TABLE IF NOT EXISTS player_stats (
  username        text PRIMARY KEY,
  wins            integer DEFAULT 0,
  losses          integer DEFAULT 0,
  max_dmg         integer DEFAULT 0,
  best_streak     integer DEFAULT 0,
  current_streak  integer DEFAULT 0,
  last_match      timestamptz,
  match_history   jsonb DEFAULT '[]'::jsonb,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

-- 2. Enable row level security
ALTER TABLE player_stats ENABLE ROW LEVEL SECURITY;

-- 3. Create policies (skips each if already exists)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='player_stats' AND policyname='public read') THEN
    CREATE POLICY "public read" ON player_stats FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='player_stats' AND policyname='public insert') THEN
    CREATE POLICY "public insert" ON player_stats FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='player_stats' AND policyname='public update') THEN
    CREATE POLICY "public update" ON player_stats FOR UPDATE USING (true);
  END IF;
END $$;

-- 4. Auto-update trigger function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

-- 5. Create trigger only if it doesn't exist yet
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'player_stats_updated_at'
  ) THEN
    CREATE TRIGGER player_stats_updated_at
      BEFORE UPDATE ON player_stats
      FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  END IF;
END $$;
