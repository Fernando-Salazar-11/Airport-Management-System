// =============================================
//   AEROPUERTO API - server.js
//   Materia: Bases de Datos Avanzadas
//   Desarrollador: OA
// =============================================

require("dotenv").config();
const express = require("express");
const mysql = require("mysql2/promise");
const cors = require("cors");

const app = express();
const PORT = process.env.PORT || 3000;

// ─── MIDDLEWARES ──────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());                  // Permite leer JSON en el body de los POST

// ─── CONEXION A LA BASE DE DATOS ─────────────────────────────────────────────
const pool = mysql.createPool({
  host:     process.env.DB_HOST,
  port:     process.env.DB_PORT,
  user:     process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
});

// ─── FUNCION HELPER: Respuesta exitosa ────────────────────────────────────────
function respuestaOk(res, data, message = "Operacion exitosa") {
  return res.status(200).json({
    ok: true,
    data: data,
    message: message,
  });
}

// ─── FUNCION HELPER: Respuesta de error ──────────────────────────────────────
function respuestaError(res, statusCode, code, message) {
  return res.status(statusCode).json({
    ok: false,
    error: {
      code: code,
      message: message,
    },
  });
}

// =============================================================================
//   ENDPOINTS
// =============================================================================

// ─── GET /api/health ─────────────────────────────────────────────────────────
// Verifica que el servidor y la BD esten corriendo
app.get("/api/health", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    return respuestaOk(res, { servidor: "OK", base_de_datos: "OK" }, "Servidor y BD funcionando correctamente");
  } catch (err) {
    return respuestaError(res, 500, "DB_ERROR", "No se pudo conectar a la base de datos: " + err.message);
  }
});


// ─── GET /api/vuelos-dia ─────────────────────────────────────────────────────
// Consume la vista vuelos_dia — muestra vuelos programados para hoy
app.get("/api/vuelos-dia", async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT * FROM vuelos_dia");
    return respuestaOk(res, rows);
  } catch (err) {
    return respuestaError(res, 500, "DB_ERROR", "No se pudo obtener los vuelos del dia: " + err.message);
  }
});

// ─── GET /api/pasajeros-frecuentes ───────────────────────────────────────────
// Consume la vista pasajeros_frecuentes — pasajeros con mas de 10 vuelos en el ultimo año
app.get("/api/pasajeros-frecuentes", async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT * FROM pasajeros_frecuentes");
    return respuestaOk(res, rows);
  } catch (err) {
    return respuestaError(res, 500, "DB_ERROR", "No se pudo obtener los pasajeros frecuentes: " + err.message);
  }
});

// ─── GET /api/aeronaves-mantenimiento ────────────────────────────────────────
// Consume la vista aeronaves_mantenimiento — aeronaves en estado Mantenimiento
app.get("/api/aeronaves-mantenimiento", async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT * FROM aeronaves_mantenimiento");
    return respuestaOk(res, rows);
  } catch (err) {
    return respuestaError(res, 500, "DB_ERROR", "No se pudo obtener aeronaves en mantenimiento: " + err.message);
  }
});



// ─── POST /api/reservaciones ─────────────────────────────────────────────────
// Ejecuta sp_proceso_reservacion para crear una reservacion completa
// Body esperado: { vuelo_id, pasajero_id, clase, asiento, precio, metodo_pago }
app.post("/api/reservaciones", async (req, res) => {
  const { vuelo_id, pasajero_id, clase, asiento, precio, metodo_pago } = req.body;

  // Validacion de campos requeridos
  if (!vuelo_id || !pasajero_id || !clase || !asiento || !precio || !metodo_pago) {
    return respuestaError(res, 400, "MISSING_FIELDS", "Faltan campos requeridos: vuelo_id, pasajero_id, clase, asiento, precio, metodo_pago");
  }

  try {
    // Fernando hace el SP, nosotros solo hacemos el CALL
    const [rows] = await pool.query(
      "CALL sp_proceso_reservacion(?, ?, ?, ?, ?, ?)",
      [vuelo_id, pasajero_id, clase, asiento, precio, metodo_pago]
    );

    // El SP regresa un result set en rows[0]
    const resultado = rows[0][0];
    return respuestaOk(res, resultado, "Reservacion creada");
  } catch (err) {
    // Si el SP lanza un error de negocio (SQLSTATE 45000), lo capturamos aqui
    return respuestaError(res, 400, "SP_ERROR", err.message);
  }
});

// ─── POST /api/checkin ───────────────────────────────────────────────────────
// Ejecuta checkin_automatico — check-in masivo para un vuelo
// Body esperado: { vuelo_id }
app.post("/api/checkin", async (req, res) => {
  const { vuelo_id } = req.body;

  if (!vuelo_id) {
    return respuestaError(res, 400, "MISSING_FIELDS", "Falta el campo requerido: vuelo_id");
  }

  try {
    const [rows] = await pool.query(
      "CALL checkin_automatico(?)",
      [vuelo_id]
    );

    const resultado = rows[0];
    return respuestaOk(res, resultado, "Check-in automatico realizado con exito");
  } catch (err) {
    return respuestaError(res, 400, "SP_ERROR", err.message);
  }
});

// ─── POST /api/tripulacion/asignar ───────────────────────────────────────────
// Ejecuta asignar_tripulacion — asigna tripulacion a un vuelo por fecha y ruta
// Body esperado: { fecha_vuelo, ruta_id }
app.post("/api/tripulacion/asignar", async (req, res) => {
  const { fecha_vuelo, ruta_id } = req.body;

  if (!fecha_vuelo || !ruta_id) {
    return respuestaError(res, 400, "MISSING_FIELDS", "Faltan campos requeridos: fecha_vuelo, ruta_id");
  }

  try {
    const [rows] = await pool.query(
      "CALL asignar_tripulacion(?, ?)",
      [fecha_vuelo, ruta_id]
    );

    const resultado = rows[0];
    return respuestaOk(res, resultado, "Tripulacion asignada correctamente");
  } catch (err) {
    // Si no hay vuelo valido o ya tiene tripulacion, el SP lanza SQLSTATE 45000
    return respuestaError(res, 400, "SP_ERROR", err.message);
  }
});

// ─── GET /api/estadisticas-puntualidad ───────────────────────────────────────
// Ejecuta calcular_estadisticas_puntualidad — reporte mensual por aerolinea
// Query params: ?anio=2026&mes=6
app.get("/api/estadisticas-puntualidad", async (req, res) => {
  const { anio, mes } = req.query;

  if (!anio || !mes) {
    return respuestaError(res, 400, "MISSING_PARAMS", "Faltan parametros requeridos: anio, mes  (ej: ?anio=2026&mes=6)");
  }

  try {
    const [rows] = await pool.query(
      "CALL calcular_estadisticas_puntualidad(?, ?)",
      [parseInt(anio), parseInt(mes)]
    );

    const resultado = rows[0];
    return respuestaOk(res, resultado, `Estadisticas de puntualidad para ${mes}/${anio}`);
  } catch (err) {
    return respuestaError(res, 500, "SP_ERROR", "No se pudo calcular las estadisticas: " + err.message);
  }
});

// ─── RUTA NO ENCONTRADA (404) ─────────────────────────────────────────────────
app.use((req, res) => {
  return respuestaError(res, 404, "NOT_FOUND", `La ruta ${req.method} ${req.originalUrl} no existe`);
});

// ─── INICIAR SERVIDOR ────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log("=============================================");
  console.log(`  AEROPUERTO API corriendo en puerto ${PORT}`);
  console.log(`  Base de datos: ${process.env.DB_NAME}`);
  console.log(`  Health check: http://localhost:${PORT}/api/health`);
  console.log("=============================================");
});
