USE aeropuerto_db_up;


CREATE OR REPLACE VIEW vuelos_dia AS
SELECT 
    v.vuelo_id,
    a.nombre AS Aerolinea,
    a.codigo_iata,
    r.aeropuerto_origen,
    r.aeropuerto_destino,
    v.fecha_salida,
    v.fecha_llegada_estimada,
    v.puerta_embarque,
    v.estado,
    v.asientos_disponibles
FROM vuelos v
INNER JOIN aerolineas a USING (aerolinea_id)
INNER JOIN rutas r USING (ruta_id)
WHERE DATE(v.fecha_salida) = CURRENT_DATE();

CREATE OR REPLACE VIEW pasajeros_frecuentes AS
SELECT 
    p.pasajero_id,
    p.pasaporte,
    p.nombre,
    p.apellido,
    p.email,
    p.programa_fidelidad,
    COUNT(r.reservacion_id) AS vuelos_ultimo_anio
FROM pasajeros p
INNER JOIN reservaciones r USING(pasajero_id)
INNER JOIN vuelos v USING(vuelo_id)
WHERE r.estado NOT IN ('En Espera', 'Cancelada')
AND v.fecha_salida <= NOW()
AND DATEDIFF(v.fecha_salida, NOW()) <= 365
GROUP BY p.pasajero_id
HAVING COUNT(r.reservacion_id) >= 10;


CREATE OR REPLACE VIEW aeronaves_mantenimiento AS
SELECT
    ar.aeronave_id,
    ar.modelo,
    al.nombre as aerolinea,
    ar.ultimo_mantenimiento,
    ar.estado
FROM aeronaves ar
INNER JOIN aerolineas al USING(aerolinea_id)
WHERE ar.estado = 'Mantenimiento';


