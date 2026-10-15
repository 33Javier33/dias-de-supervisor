# Días de Supervisor

PWA para marcar los días trabajados como **Supervisor** y generar el informe del periodo (del 16 de un mes al 15 del siguiente).

## Uso

- Toca un día del calendario → **✅ Día de Supervisor** o **✖ No fue de Supervisor** (nota opcional).
- **Informe**: elige el mes y se copian los días de supervisor del 16 de ese mes al 15 del siguiente.
- El indicador bajo el título muestra si todo está guardado en Supabase (verde), pendiente (amarillo) o con error (rojo).

## Seguridad: PIN y huella / rostro

- La primera vez la app pide **crear un PIN de 6 números**. Ese PIN vale para todos tus dispositivos.
- La app se bloquea al abrirse y tras 1 minuto en segundo plano.
- Opcional: **huella o rostro** (Datos → Activar huella / rostro) para desbloquear en ese teléfono.
- El PIN se comprueba en Supabase: sin él no se puede leer ni guardar nada, aunque alguien tenga el link o la clave pública.
- 5 PIN incorrectos seguidos bloquean el acceso durante 15 minutos.
- Sin conexión se puede desbloquear con el último PIN válido usado en ese teléfono.
- **¿Olvidaste el PIN?** En el SQL Editor ejecuta
  `update public.dias_supervisor_config set pin_hash = null;` y la app pedirá crear uno nuevo (los días no se pierden).

## Base de datos (Supabase · socios-comicion)

La app se conecta sola al proyecto **socios-comicion** (`teemahksasdougehrcly`). No hay que configurar nada.

- Al marcar un día se guarda **al instante** en Supabase.
- Los demás dispositivos se actualizan **solos**: reciben un aviso en tiempo real (Supabase Realtime) y además revisan cada 15 segundos.
- Sin conexión, los cambios quedan en el teléfono y se suben al volver la red.
- Tablas: `dias_supervisor` (un registro por fecha), `dias_supervisor_historial` (cada cambio) y `dias_supervisor_config` (PIN cifrado).
- Las tablas no son accesibles directamente con la clave pública; solo mediante funciones que exigen el PIN. Nada se borra.

### Instalación / actualización

Abre el SQL Editor del proyecto:
https://supabase.com/dashboard/project/teemahksasdougehrcly/sql/new

Pega [`supabase/migrations/20261015120000_dias_supervisor.sql`](supabase/migrations/20261015120000_dias_supervisor.sql) y pulsa **Run**.
Se puede ejecutar más de una vez y conserva los datos.

### Consultas útiles

```sql
-- Días de supervisor de un periodo
select fecha, nota from public.dias_supervisor
where estado = 'Supervisor' and fecha between '2026-09-16' and '2026-10-15'
order by fecha;

-- Historial de cambios
select * from public.dias_supervisor_historial order by id desc;
```

---
Carlos P. Nauto Interactive® 2026
