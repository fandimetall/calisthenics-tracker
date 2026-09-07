-- ============================================================================
-- Calisthenics Tracker - Supabase Database Schema (Phase 4)
-- Paste this script into Supabase SQL Editor and click 'Run'.
-- ============================================================================

-- 1. Profiles Table (sync with auth.users)
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text not null,
  name text,
  avatar_url text,
  created_at timestamptz default timezone('utc'::text, now()) not null,
  updated_at timestamptz default timezone('utc'::text, now()) not null
);

-- 2. User Fitness Metrics & Evaluation
create table if not exists public.user_metrics (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  gender text default 'male',
  age int default 25,
  weight numeric default 70.0,
  height numeric default 170.0,
  experience text default 'never',
  pushup_count int default 0,
  squat_count int default 0,
  pace numeric default 0,
  tier text default 'Tier 1 - Calisthenics Foundation',
  created_at timestamptz default timezone('utc'::text, now()) not null,
  updated_at timestamptz default timezone('utc'::text, now()) not null
);

-- 3. Generated Workout Plans (JSONB)
create table if not exists public.workout_plans (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  plan_data jsonb not null,
  is_active boolean default true,
  created_at timestamptz default timezone('utc'::text, now()) not null
);

-- 4. Workout Session Logs
create table if not exists public.workout_logs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  session_name text not null,
  duration_seconds int default 0,
  completed_at timestamptz default timezone('utc'::text, now()) not null,
  details jsonb
);

-- ============================================================================
-- Row Level Security (RLS) Policies
-- Ensures users can only access and modify their own data
-- ============================================================================

alter table public.profiles enable row level security;
alter table public.user_metrics enable row level security;
alter table public.workout_plans enable row level security;
alter table public.workout_logs enable row level security;

-- Profiles Policies
create policy "Users can view their own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Metrics Policies
create policy "Users can view own metrics"
  on public.user_metrics for select
  using (auth.uid() = user_id);

create policy "Users can insert own metrics"
  on public.user_metrics for insert
  with check (auth.uid() = user_id);

create policy "Users can update own metrics"
  on public.user_metrics for update
  using (auth.uid() = user_id);

-- Plans Policies
create policy "Users can view own plans"
  on public.workout_plans for select
  using (auth.uid() = user_id);

create policy "Users can insert own plans"
  on public.workout_plans for insert
  with check (auth.uid() = user_id);

create policy "Users can update own plans"
  on public.workout_plans for update
  using (auth.uid() = user_id);

-- Logs Policies
create policy "Users can view own logs"
  on public.workout_logs for select
  using (auth.uid() = user_id);

create policy "Users can insert own logs"
  on public.workout_logs for insert
  with check (auth.uid() = user_id);

-- ============================================================================
-- Automatic Profile Trigger on Signup
-- ============================================================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$ language plpgsql security definer;

-- Drop trigger if exists and recreate
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
