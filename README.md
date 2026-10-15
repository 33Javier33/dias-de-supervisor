# Días de Supervisor

PWA para marcar los días trabajados como **Supervisor** y generar el informe del periodo (del 16 de un mes al 15 del siguiente).

## Uso

- Toca un día del calendario → **✅ Día de Supervisor** o **✖ No fue de Supervisor** (nota opcional).
- **Informe**: elige el mes y se copian los días de supervisor del 16 de ese mes al 15 del siguiente.
- El indicador bajo el título muestra si todo está guardado en Supabase (verde), pendiente (amarillo) o con error (rojo).

## Base de datos (Supabase · socios-comicion)

La app se conecta sola al proyecto **socios-comicion** (`teemahksasdougehrcly`) con la clave pública *anon*, igual que la app de socios. No hay que configurar nada en el teléfono.

- Tabla `public.dias_supervisor`: un registro por fecha (`estado` = `Supervisor` o `Libre`).
- Tabla `public.dias_supervisor_historial`: cada alta y cambio queda registrado automáticamente.
- La app puede leer, crear y modificar días, pero **no borrar**; el historial no es accesible desde la app.
- Sin conexión, los cambios quedan en el teléfono y se suben solos al volver la red.
- La primera vez que se abre, la app sube los días que ya había en el teléfono.

### Instalación (una sola vez)

Abre el SQL Editor del proyecto:
https://supabase.com/dashboard/project/teemahksasdougehrcly/sql/new

Pega [`supabase/migrations/20261015120000_dias_supervisor.sql`](supabase/migrations/20261015120000_dias_supervisor.sql) y pulsa **Run**.

### Consultas útiles

```sql
-- Días de supervisor de un periodo
select fecha, nota from public.dias_supervisor
where estado = 'Supervisor' and fecha between '2026-09-16' and '2026-10-15'
order by fecha;

-- Historial de cambios
select * from public.dias_supervisor_historial order by id desc;
```
