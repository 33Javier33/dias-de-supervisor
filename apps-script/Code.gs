/**
 * Base de datos en Google Sheets para "Días de Supervisor".
 *
 * Instalación (ver README.md):
 *  1. Crea una hoja de cálculo en Google Sheets.
 *  2. Extensiones > Apps Script, pega este archivo y guarda.
 *  3. (Opcional) Pon una clave en TOKEN y la misma en la app.
 *  4. Implementar > Nueva implementación > Aplicación web
 *     - Ejecutar como: Yo
 *     - Quién tiene acceso: Cualquier usuario
 *  5. Copia la URL que termina en /exec y pégala en la app (pestaña Datos).
 */

const SHEET_NAME = 'Dias';
const TOKEN = ''; // Clave opcional. Si la pones aquí, ponla también en la app.
const HEADERS = ['fecha', 'estado', 'nota', 'actualizado'];

function doGet(e) {
  const params = (e && e.parameter) || {};
  if (!authorized_(params.token)) return json_({ ok: false, error: 'Clave incorrecta' });
  return json_({ ok: true, days: readAll_(getSheet_()) });
}

function doPost(e) {
  let body;
  try {
    body = JSON.parse(e.postData.contents);
  } catch (err) {
    return json_({ ok: false, error: 'JSON inválido' });
  }
  if (!authorized_(body.token)) return json_({ ok: false, error: 'Clave incorrecta' });

  const lock = LockService.getScriptLock();
  lock.waitLock(20000);
  try {
    const sheet = getSheet_();
    applyOps_(sheet, Array.isArray(body.ops) ? body.ops : []);
    return json_({ ok: true, days: readAll_(sheet) });
  } finally {
    lock.releaseLock();
  }
}

function authorized_(token) {
  return !TOKEN || token === TOKEN;
}

function getSheet_() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(SHEET_NAME) || ss.insertSheet(SHEET_NAME);
  if (sheet.getLastRow() === 0) {
    sheet.appendRow(HEADERS);
    sheet.setFrozenRows(1);
    sheet.getRange(1, 1, 1, HEADERS.length).setFontWeight('bold');
  }
  // La fecha se guarda como texto para que Sheets no la convierta.
  sheet.getRange('A:A').setNumberFormat('@');
  return sheet;
}

function dateKey_(value) {
  if (value instanceof Date) {
    return Utilities.formatDate(value, Session.getScriptTimeZone(), 'yyyy-MM-dd');
  }
  return String(value).trim();
}

function readAll_(sheet) {
  const last = sheet.getLastRow();
  const days = {};
  if (last < 2) return days;
  sheet.getRange(2, 1, last - 1, 3).getValues().forEach(function (row) {
    const key = dateKey_(row[0]);
    if (key) days[key] = { status: String(row[1] || ''), note: String(row[2] || '') };
  });
  return days;
}

/** ops: [{ type: 'upsert' | 'delete', date: 'yyyy-MM-dd', status, note }] */
function applyOps_(sheet, ops) {
  const last = sheet.getLastRow();
  const index = {};
  if (last >= 2) {
    sheet.getRange(2, 1, last - 1, 1).getValues().forEach(function (row, i) {
      index[dateKey_(row[0])] = i + 2;
    });
  }

  const rowsToDelete = [];
  ops.forEach(function (op) {
    const key = String(op.date || '');
    if (!/^\d{4}-\d{2}-\d{2}$/.test(key)) return;
    const row = index[key];

    if (op.type === 'delete') {
      if (row) {
        rowsToDelete.push(row);
        delete index[key];
      }
      return;
    }

    const values = [key, String(op.status || ''), String(op.note || ''), new Date()];
    if (row) {
      sheet.getRange(row, 1, 1, values.length).setValues([values]);
    } else {
      sheet.appendRow(values);
      index[key] = sheet.getLastRow();
    }
  });

  // Borrar de abajo hacia arriba para no desplazar los índices.
  rowsToDelete.sort(function (a, b) { return b - a; }).forEach(function (r) { sheet.deleteRow(r); });

  const rows = sheet.getLastRow() - 1;
  if (rows > 1) sheet.getRange(2, 1, rows, HEADERS.length).sort(1);
}

function json_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}
