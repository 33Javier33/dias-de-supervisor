# Días de Supervisor

PWA para marcar los días trabajados como **Supervisor** y generar el informe del periodo (del 16 de un mes al 15 del siguiente).

## Uso

- Toca un día del calendario → **✅ Día de Supervisor** o **✖ No fue de Supervisor** (nota opcional).
- **Informe**: elige el mes y se copian los días de supervisor del 16 de ese mes al 15 del siguiente.
- El indicador bajo el título muestra si todo está guardado en Google Sheets.

## Base de datos en Google Sheets

Los días se guardan en una hoja de cálculo tuya. El teléfono guarda una copia para funcionar sin conexión y sube los cambios pendientes al volver la red.

1. Crea una hoja nueva en [Google Sheets](https://sheets.new).
2. Menú **Extensiones → Apps Script**. Borra el contenido y pega [`apps-script/Code.gs`](apps-script/Code.gs). Guarda.
3. (Opcional) Escribe una clave en `const TOKEN = '...'`.
4. **Implementar → Nueva implementación** → tipo **Aplicación web**:
   - Ejecutar como: **Yo**
   - Quién tiene acceso: **Cualquier usuario**
5. Autoriza los permisos y copia la URL que termina en `/exec`.
6. En la app, pestaña **Datos** → pega la URL (y la clave si pusiste una) → **Conectar y subir mis días**.
   Esto sube todos los días que ya tenías en el teléfono; no borra nada de la hoja.

La hoja `Dias` tiene las columnas `fecha | estado | nota | actualizado`.

> Si cambias el código del script, usa **Implementar → Gestionar implementaciones → Editar → Nueva versión** para que la URL siga siendo la misma.
