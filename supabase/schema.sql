-- Le Guide des Congés : table des journées posées dans l'app.
-- À coller une fois dans Supabase > SQL Editor > New query, puis Run.

create table if not exists public.absences (
  id          text primary key,                 -- AAAA-MM-JJ_Prenom
  date        date not null,
  person      text not null,
  kind        text not null check (kind in ('conge', 'tt', 'bureau')),
  note        text not null default '' check (char_length(note) <= 80),
  updated_at  timestamptz not null default now()
);

create index if not exists absences_person_date on public.absences (person, date);

-- Sécurité : l'app n'a pas encore de comptes, la clé publique peut donc lire et écrire.
-- À resserrer quand on ajoutera la connexion (chacun ne modifiera que ses propres lignes).
alter table public.absences enable row level security;

drop policy if exists "absences lisibles" on public.absences;
create policy "absences lisibles" on public.absences
  for select to anon, authenticated using (true);

drop policy if exists "absences ajout" on public.absences;
create policy "absences ajout" on public.absences
  for insert to anon, authenticated with check (true);

drop policy if exists "absences modification" on public.absences;
create policy "absences modification" on public.absences
  for update to anon, authenticated using (true) with check (true);

drop policy if exists "absences suppression" on public.absences;
create policy "absences suppression" on public.absences
  for delete to anon, authenticated using (true);

-- Temps réel : tout le monde voit les congés des autres apparaître sans recharger.
do $$
begin
  alter publication supabase_realtime add table public.absences;
exception when duplicate_object then null;
end $$;
