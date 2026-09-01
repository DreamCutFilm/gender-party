-- Гендер-паті Едуарда та Катерини — схема бази даних Supabase
-- Скопіюйте увесь цей файл у Supabase Dashboard → SQL Editor → New query → Run

-- 1. Таблиця голосів-вгадайок гостей
create table if not exists public.guesses (
  id uuid primary key default gen_random_uuid(),
  guess text not null check (guess in ('boy', 'girl')),
  guest_name text,
  created_at timestamptz not null default now()
);

-- 2. Таблиця побажань малюку
create table if not exists public.wishes (
  id uuid primary key default gen_random_uuid(),
  guest_name text not null,
  message text not null,
  created_at timestamptz not null default now()
);

-- 3. Таблиця самого розкриття — рівно один рядок (id = 1)
create table if not exists public.reveal (
  id int primary key,
  revealed boolean not null default false,
  gender text check (gender in ('boy', 'girl')),
  revealed_at timestamptz
);

insert into public.reveal (id, revealed, gender)
values (1, false, null)
on conflict (id) do nothing;

-- Увімкнути Row Level Security на всіх трьох таблицях
alter table public.guesses enable row level security;
alter table public.wishes  enable row level security;
alter table public.reveal  enable row level security;

-- guesses: будь-хто (анонімний відвідувач сайту) може читати й додавати голос,
-- але НЕ може редагувати чи видаляти чужі голоси
create policy "guesses_public_read" on public.guesses
  for select using (true);
create policy "guesses_public_insert" on public.guesses
  for insert with check (true);

-- wishes: так само — будь-хто читає й додає побажання
create policy "wishes_public_read" on public.wishes
  for select using (true);
create policy "wishes_public_insert" on public.wishes
  for insert with check (true);

-- reveal: гості можуть тільки ЧИТАТИ статус розкриття.
-- Навмисно немає insert/update policy для анонімних відвідувачів —
-- єдиний спосіб змінити цей рядок це зайти у Table Editor у Supabase
-- своїм акаунтом (Едуард/Катерина) і відредагувати рядок вручну.
create policy "reveal_public_read" on public.reveal
  for select using (true);

-- Увімкнути realtime-сповіщення для миттєвого оновлення сторінки
-- у всіх гостей одночасно (без перезавантаження) коли:
--  - хтось додає новий голос
--  - хтось залишає побажання
--  - ви вручну відкриваєте таємницю в таблиці reveal
alter publication supabase_realtime add table public.guesses;
alter publication supabase_realtime add table public.wishes;
alter publication supabase_realtime add table public.reveal;
