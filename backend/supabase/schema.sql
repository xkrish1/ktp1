-- Enable helpful extensions
create extension if not exists pgcrypto;

-- 1) Profiles (1 per user)
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  allergens text[] not null default '{}',
  restrictions text[] not null default '{}',
  severity jsonb not null default '{}'::jsonb
);

-- 2) Menu items (public read; only service role writes)
create table if not exists public.menu_items (
  id uuid primary key default gen_random_uuid(),
  hall text not null check (hall in ('Atrium', 'Busch')),
  date date not null,
  meal text not null check (meal in ('Breakfast','Lunch','Dinner')),
  station text null,
  name text not null,
  ingredients text null,
  source_url text not null,
  source_key text null,
  scraped_at timestamptz not null default now(),
  raw_hash text null
);

create index if not exists idx_menu_items_query
  on public.menu_items (hall, date, meal);

-- Uniqueness: prefer source_key when present
create unique index if not exists ux_menu_items_source_key
  on public.menu_items (hall, date, meal, source_key)
  where source_key is not null;

-- Fallback uniqueness when source_key is missing
create unique index if not exists ux_menu_items_fallback
  on public.menu_items (hall, date, meal, name, coalesce(station,''))
  where source_key is null;

-- 3) Orders (mock pickup tickets)
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  hall text not null check (hall in ('Atrium', 'Busch')),
  pickup_time timestamptz not null,
  item_ids uuid[] not null default '{}',
  status text not null check (status in ('submitted','prepping','ready','picked_up')),
  note text null
);

create index if not exists idx_orders_user_created
  on public.orders (user_id, created_at desc);
