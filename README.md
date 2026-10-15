# Días de Supervisor

PWA para marcar los días trabajados como **Supervisor** y generar el informe del periodo (del 16 de un mes al 15 del siguiente).

## Uso

- Toca un día del calendario → **✅ Día de Supervisor** o **✖ No fue de Supervisor** (nota opcional).
- **Informe**: elige el mes y se copian los días de supervisor del 16 de ese mes al 15 del siguiente.
- El indicador bajo el título muestra si todo está guardado en Supabase (verde), pendiente (amarillo) o con error (rojo).

## Base de datos en Supabase (proyecto socios-comicion)

Los días se guardan en la tabla `public.supervisor_dias`. El teléfono guarda una copia para funcionar sin conexión y sube los cambios pendientes al volver la red. Cada usuario solo puede ver y modificar sus propios días (RLS).

### 1. Crear la tabla

Supabase → proyecto **socios-comicion** → **SQL Editor** → pega
[`supabase/migrations/20261015000000_supervisor_dias.sql`](supabase/migrations/20261015000000_supervisor_dias.sql) → **Run**.

No toca ninguna otra tabla del proyecto y se puede ejecutar más de una vez.

### 2. Usuario

Usa tu usuario de socios-comicion si ya tienes uno con correo y contraseña. Si no:
**Authentication → Users → Add user → Create new user** (marca *Auto Confirm User*).

> Ojo: si socios-comicion tiene un trigger que crea un "socio" al registrar usuarios, crear uno nuevo también lo creará. Usar tu usuario existente lo evita.

### 3. Datos del proyecto

**Project Settings → API** (o *Data API*): copia la **Project URL** y la clave **anon public**.

- Opción A (recomendada): ponlas en `index.html`, en `SUPABASE_URL` y `SUPABASE_ANON_KEY`. Así en cada teléfono solo pides correo y contraseña.
- Opción B: escríbelas en la app, pestaña **Datos → Proyecto Supabase**.

La clave *anon* es pública por diseño; la protección la dan el inicio de sesión y las políticas RLS. **Nunca** uses la clave `service_role` en la app.

### 4. Conectar

En la app, pestaña **Datos** → correo y contraseña → **Iniciar sesión y subir mis días**.
Esto sube todos los días que ya tenías en el teléfono; no borra nada de Supabase. La contraseña no se guarda, solo la sesión.

### Consultar los días desde Supabase

```sql
select fecha, estado, nota from public.supervisor_dias
where estado = 'Supervisor' and fecha between '2026-09-16' and '2026-10-15'
order by fecha;
```
