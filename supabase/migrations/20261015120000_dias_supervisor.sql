-- Días de Supervisor → proyecto Supabase socios-comicion (teemahksasdougehrcly).
-- Pegar en: https://supabase.com/dashboard/project/teemahksasdougehrcly/sql/new  → Run.
-- Se puede ejecutar más de una vez sin problema. No toca ninguna otra tabla.

-- 1) Tabla principal: un registro por fecha.
create table if not exists public.dias_supervisor (
  fecha      date        primary key,
  estado     text        not null default 'Supervisor' check (estado in ('Supervisor', 'Libre')),
  nota       text        not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.dias_supervisor is 'App Días de Supervisor: días marcados como Supervisor (Libre = desmarcado).';

-- 2) Historial: guarda cada alta/cambio para poder recuperar cualquier dato.
create table if not exists public.dias_supervisor_historial (
  id         bigint generated always as identity primary key,
  fecha      date        not null,
  accion     text        not null,
  estado     text,
  nota       text,
  changed_at timestamptz not null default now()
);

create or replace function public.dias_supervisor_touch()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create or replace function public.dias_supervisor_log()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then
    insert into public.dias_supervisor_historial (fecha, accion, estado, nota)
    values (old.fecha, tg_op, old.estado, old.nota);
  else
    insert into public.dias_supervisor_historial (fecha, accion, estado, nota)
    values (new.fecha, tg_op, new.estado, new.nota);
  end if;
  return null;
end;
$$;

drop trigger if exists dias_supervisor_touch on public.dias_supervisor;
create trigger dias_supervisor_touch
  before update on public.dias_supervisor
  for each row execute function public.dias_supervisor_touch();

drop trigger if exists dias_supervisor_log on public.dias_supervisor;
create trigger dias_supervisor_log
  after insert or update or delete on public.dias_supervisor
  for each row execute function public.dias_supervisor_log();

-- 3) Seguridad (RLS): la app (clave anon) puede leer, crear y modificar días, pero NO borrar.
--    El historial no es accesible desde la app; solo desde el panel de Supabase.
alter table public.dias_supervisor enable row level security;
alter table public.dias_supervisor_historial enable row level security;

drop policy if exists "dias_supervisor_select" on public.dias_supervisor;
create policy "dias_supervisor_select" on public.dias_supervisor
  for select to anon, authenticated using (true);

drop policy if exists "dias_supervisor_insert" on public.dias_supervisor;
create policy "dias_supervisor_insert" on public.dias_supervisor
  for insert to anon, authenticated with check (true);

drop policy if exists "dias_supervisor_update" on public.dias_supervisor;
create policy "dias_supervisor_update" on public.dias_supervisor
  for update to anon, authenticated using (true) with check (true);

revoke all on public.dias_supervisor from anon, authenticated;
grant select, insert, update on public.dias_supervisor to anon, authenticated;
revoke all on public.dias_supervisor_historial from anon, authenticated;
revoke all on function public.dias_supervisor_log() from public, anon, authenticated;
revoke all on function public.dias_supervisor_touch() from public, anon, authenticated;
