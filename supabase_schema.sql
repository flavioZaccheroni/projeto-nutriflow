create table if not exists public.patients (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  age integer not null,
  weight double precision not null,
  height double precision not null,
  goal text not null,
  observations text not null default '',
  next_visit text not null,
  created_at text not null,
  updated_at text not null
);

create table if not exists public.meal_plans (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  patient_id text not null references public.patients(id) on delete cascade,
  updated_at text not null,
  unique (patient_id)
);

create table if not exists public.meals (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  meal_plan_id text not null references public.meal_plans(id) on delete cascade,
  name text not null,
  time text not null,
  sort_order integer not null
);

create table if not exists public.food_items (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  meal_id text not null references public.meals(id) on delete cascade,
  name text not null,
  quantity text not null,
  sort_order integer not null
);

create table if not exists public.history_events (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  patient_id text references public.patients(id) on delete set null,
  meal_plan_id text references public.meal_plans(id) on delete set null,
  type text not null,
  description text not null,
  created_at text not null
);

alter table public.patients enable row level security;
alter table public.meal_plans enable row level security;
alter table public.meals enable row level security;
alter table public.food_items enable row level security;
alter table public.history_events enable row level security;

create policy "patients owner access"
on public.patients
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "meal plans owner access"
on public.meal_plans
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "meals owner access"
on public.meals
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "food items owner access"
on public.food_items
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "history owner access"
on public.history_events
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
