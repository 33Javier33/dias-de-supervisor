-- Días de Supervisor: tabla para el proyecto Supabase "socios-comicion".
-- Pegar en Supabase → SQL Editor → Run. Se puede ejecutar más de una vez sin problema.

create table if not exists public.supervisor_dias (
  user_id    uuid        not null default auth.uid() references auth.users (id) on delete cascade,
  fecha      date        not null,
  estado     text        not null default 'Supervisor' check (estado in ('Supervisor', 'Libre')),
  nota       text        not null default '',
  updated_at timestamptz not null default now(),
  primary key (user_id, fecha)
);

comment on table public.supervisor_dias is 'Días marcados en la app Días de Supervisor (uno por usuario y fecha).';

-- Mantener updated_at al día.
create or replace function public.supervisor_dias_touch()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists supervisor_dias_touch on public.supervisor_dias;
create trigger supervisor_dias_touch
  before update on public.supervisor_dias
  for each row execute function public.supervisor_dias_touch();

-- Seguridad: cada usuario solo ve y modifica sus propios días.
alter table public.supervisor_dias enable row level security;

drop policy if exists "supervisor_dias_select_own" on public.supervisor_dias;
create policy "supervisor_dias_select_own" on public.supervisor_dias
  for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists "supervisor_dias_insert_own" on public.supervisor_dias;
create policy "supervisor_dias_insert_own" on public.supervisor_dias
  for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists "supervisor_dias_update_own" on public.supervisor_dias;
create policy "supervisor_dias_update_own" on public.supervisor_dias
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "supervisor_dias_delete_own" on public.supervisor_dias;
create policy "supervisor_dias_delete_own" on public.supervisor_dias
  for delete to authenticated using ((select auth.uid()) = user_id);

revoke all on public.supervisor_dias from anon;
grant select, insert, update, delete on public.supervisor_dias to authenticated;
