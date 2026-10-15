-- Días de Supervisor → proyecto Supabase socios-comicion (teemahksasdougehrcly).
-- Pegar en: https://supabase.com/dashboard/project/teemahksasdougehrcly/sql/new  → Run.
-- Se puede ejecutar más de una vez sin problema. No toca ninguna otra tabla y conserva los datos.
--
-- Seguridad: la tabla NO es accesible directamente con la clave pública (anon).
-- La app solo puede leer y guardar a través de funciones que exigen el PIN.
-- 5 PIN incorrectos seguidos bloquean el acceso 15 minutos.
-- ¿Olvidaste el PIN? Ejecuta:  update public.dias_supervisor_config set pin_hash = null;
-- y la app pedirá crear uno nuevo.

-- 1) Tabla principal: un registro por fecha.
create table if not exists public.dias_supervisor (
  fecha      date        primary key,
  estado     text        not null default 'Supervisor' check (estado in ('Supervisor', 'Libre')),
  nota       text        not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Reparación: columnas y clave única por fecha si la tabla ya existía con otra forma.
alter table public.dias_supervisor add column if not exists fecha      date;
alter table public.dias_supervisor add column if not exists estado     text        not null default 'Supervisor';
alter table public.dias_supervisor add column if not exists nota       text        not null default '';
alter table public.dias_supervisor add column if not exists created_at timestamptz not null default now();
alter table public.dias_supervisor add column if not exists updated_at timestamptz not null default now();
create unique index if not exists dias_supervisor_fecha_key on public.dias_supervisor (fecha);

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

-- 3) Configuración del PIN (una sola fila).
create table if not exists public.dias_supervisor_config (
  id              int         primary key default 1 check (id = 1),
  pin_hash        text,
  pin_salt        text,
  intentos        int         not null default 0,
  bloqueado_hasta timestamptz,
  updated_at      timestamptz not null default now()
);
insert into public.dias_supervisor_config (id) values (1) on conflict (id) do nothing;

-- 4) Triggers: updated_at e historial.
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

-- 5) Funciones internas (no accesibles desde la app).
create or replace function public.dias_supervisor_hash_(p_salt text, p_pin text)
returns text
language sql
immutable
set search_path = ''
as $$
  select encode(sha256(convert_to(p_salt || ':' || coalesce(p_pin, ''), 'UTF8')), 'hex');
$$;

-- Devuelve null si el PIN es correcto; si no, el código de error.
create or replace function public.dias_supervisor_verificar_(p_pin text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  c public.dias_supervisor_config;
begin
  select * into c from public.dias_supervisor_config where id = 1 for update;
  if c.pin_hash is null then
    return jsonb_build_object('ok', false, 'error', 'sin_pin');
  end if;
  if c.bloqueado_hasta is not null and c.bloqueado_hasta > now() then
    return jsonb_build_object('ok', false, 'error', 'bloqueado', 'hasta', c.bloqueado_hasta);
  end if;
  if public.dias_supervisor_hash_(c.pin_salt, p_pin) = c.pin_hash then
    update public.dias_supervisor_config set intentos = 0, bloqueado_hasta = null where id = 1;
    return null;
  end if;
  if c.intentos + 1 >= 5 then
    update public.dias_supervisor_config
      set intentos = 0, bloqueado_hasta = now() + interval '15 minutes' where id = 1;
    return jsonb_build_object('ok', false, 'error', 'bloqueado', 'hasta', now() + interval '15 minutes');
  end if;
  update public.dias_supervisor_config set intentos = c.intentos + 1 where id = 1;
  return jsonb_build_object('ok', false, 'error', 'pin_incorrecto', 'restantes', 5 - (c.intentos + 1));
end;
$$;

create or replace function public.dias_supervisor_dias_()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object('ok', true, 'dias', coalesce(jsonb_agg(jsonb_build_object(
           'fecha', d.fecha, 'estado', d.estado, 'nota', d.nota) order by d.fecha), '[]'::jsonb))
  from public.dias_supervisor d;
$$;

-- 6) Funciones que usa la app (exigen PIN).
create or replace function public.dias_supervisor_pin_configurado()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select pin_hash is not null from public.dias_supervisor_config where id = 1;
$$;

create or replace function public.dias_supervisor_crear_pin(p_pin text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_salt text := gen_random_uuid()::text;
begin
  if coalesce(p_pin, '') !~ '^[0-9]{6}$' then
    return jsonb_build_object('ok', false, 'error', 'pin_invalido');
  end if;
  update public.dias_supervisor_config
    set pin_salt = v_salt, pin_hash = public.dias_supervisor_hash_(v_salt, p_pin),
        intentos = 0, bloqueado_hasta = null, updated_at = now()
    where id = 1 and pin_hash is null;
  if not found then
    return jsonb_build_object('ok', false, 'error', 'ya_existe');
  end if;
  return public.dias_supervisor_dias_();
end;
$$;

create or replace function public.dias_supervisor_cambiar_pin(p_pin text, p_nuevo text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_err  jsonb := public.dias_supervisor_verificar_(p_pin);
  v_salt text  := gen_random_uuid()::text;
begin
  if v_err is not null then return v_err; end if;
  if coalesce(p_nuevo, '') !~ '^[0-9]{6}$' then
    return jsonb_build_object('ok', false, 'error', 'pin_invalido');
  end if;
  update public.dias_supervisor_config
    set pin_salt = v_salt, pin_hash = public.dias_supervisor_hash_(v_salt, p_nuevo), updated_at = now()
    where id = 1;
  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.dias_supervisor_listar(p_pin text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_err jsonb := public.dias_supervisor_verificar_(p_pin);
begin
  if v_err is not null then return v_err; end if;
  return public.dias_supervisor_dias_();
end;
$$;

-- p_dias: [{ "fecha": "2026-10-15", "estado": "Supervisor" | "Libre", "nota": "" }, ...]
create or replace function public.dias_supervisor_guardar(p_pin text, p_dias jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_err jsonb := public.dias_supervisor_verificar_(p_pin);
begin
  if v_err is not null then return v_err; end if;
  insert into public.dias_supervisor (fecha, estado, nota)
  select (x->>'fecha')::date, x->>'estado', left(coalesce(x->>'nota', ''), 500)
  from jsonb_array_elements(case when jsonb_typeof(p_dias) = 'array' then p_dias else '[]'::jsonb end) x
  where x->>'fecha' ~ '^\d{4}-\d{2}-\d{2}$' and x->>'estado' in ('Supervisor', 'Libre')
  on conflict (fecha) do update set estado = excluded.estado, nota = excluded.nota;
  return public.dias_supervisor_dias_();
end;
$$;

-- 7) Permisos: nada directo sobre las tablas; solo las funciones con PIN.
alter table public.dias_supervisor           enable row level security;
alter table public.dias_supervisor_historial enable row level security;
alter table public.dias_supervisor_config    enable row level security;

-- Quitar cualquier política anterior (también las creadas a mano): sin políticas no hay acceso directo.
do $$
declare p record;
begin
  for p in select tablename, policyname from pg_policies
           where schemaname = 'public'
             and tablename in ('dias_supervisor', 'dias_supervisor_historial', 'dias_supervisor_config') loop
    execute format('drop policy %I on public.%I', p.policyname, p.tablename);
  end loop;
end;
$$;

revoke all on public.dias_supervisor, public.dias_supervisor_historial, public.dias_supervisor_config
  from anon, authenticated;

revoke all on function
  public.dias_supervisor_touch(), public.dias_supervisor_log(),
  public.dias_supervisor_hash_(text, text), public.dias_supervisor_verificar_(text),
  public.dias_supervisor_dias_()
  from public, anon, authenticated;

revoke all on function
  public.dias_supervisor_pin_configurado(), public.dias_supervisor_crear_pin(text),
  public.dias_supervisor_cambiar_pin(text, text), public.dias_supervisor_listar(text),
  public.dias_supervisor_guardar(text, jsonb)
  from public;
grant execute on function
  public.dias_supervisor_pin_configurado(), public.dias_supervisor_crear_pin(text),
  public.dias_supervisor_cambiar_pin(text, text), public.dias_supervisor_listar(text),
  public.dias_supervisor_guardar(text, jsonb)
  to anon, authenticated;

-- 8) Comprobación: debe mostrar las 5 funciones de la app.
select p.proname as funcion
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname like 'dias_supervisor_%' and p.proname not like '%\_'
  and p.proname not in ('dias_supervisor_touch', 'dias_supervisor_log')
order by 1;
