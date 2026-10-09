USE aeropuerto_db_up;
DELIMITER $$

DROP PROCEDURE IF EXISTS asignar_tripulacion$$
CREATE PROCEDURE asignar_tripulacion(
    IN in_fecha_vuelo TIMESTAMP,
    IN in_ruta_id INT
)
BEGIN
    DECLARE v_vuelo_id INT;
    DECLARE v_aerolinea_id INT;

    -- Buscar vuelo y aerolínea correspondientes a la fecha y ruta
    SELECT v.vuelo_id, v.aerolinea_id
    INTO v_vuelo_id, v_aerolinea_id
    FROM vuelos v
    WHERE v.fecha_salida = in_fecha_vuelo
      AND v.ruta_id = in_ruta_id
      AND v.estado IN ('Programado', 'Retrasado')
      AND v.vuelo_id NOT IN (SELECT vuelo_id FROM tripulacion_vuelo GROUP BY vuelo_id)
    LIMIT 1;

    IF v_vuelo_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No existe un vuelo disponible o sin tripulación para esa fecha y ruta';
    END IF;

    -- Insertar Piloto
    INSERT INTO tripulacion_vuelo (vuelo_id, empleado_id, rol)
    SELECT v_vuelo_id, t.empleado_id, t.puesto
    FROM tripulacion t
    WHERE t.aerolinea_id = v_aerolinea_id
      AND t.puesto = 'Piloto'
      AND t.empleado_id NOT IN (
          SELECT tv.empleado_id 
          FROM tripulacion_vuelo tv 
          JOIN vuelos v ON tv.vuelo_id = v.vuelo_id 
          WHERE DATE(v.fecha_salida) = in_fecha_vuelo
      )
    ORDER BY t.horas_vuelo ASC
    LIMIT 1;

    -- Insertar Copiloto
    INSERT INTO tripulacion_vuelo (vuelo_id, empleado_id, rol)
    SELECT v_vuelo_id, t.empleado_id, t.puesto
    FROM tripulacion t
    WHERE t.aerolinea_id = v_aerolinea_id
      AND t.puesto = 'Copiloto'
      AND t.empleado_id NOT IN (
          SELECT tv.empleado_id 
          FROM tripulacion_vuelo tv 
          JOIN vuelos v ON tv.vuelo_id = v.vuelo_id 
          WHERE DATE(v.fecha_salida) = in_fecha_vuelo
      )
    ORDER BY t.horas_vuelo ASC
    LIMIT 1;

    -- Insertar 2 Azafatas
    INSERT INTO tripulacion_vuelo (vuelo_id, empleado_id, rol)
    SELECT v_vuelo_id, t.empleado_id, t.puesto
    FROM tripulacion t
    WHERE t.aerolinea_id = v_aerolinea_id
      AND t.puesto = 'Azafata'
      AND t.empleado_id NOT IN (
          SELECT tv.empleado_id 
          FROM tripulacion_vuelo tv 
          JOIN vuelos v ON tv.vuelo_id = v.vuelo_id 
          WHERE DATE(v.fecha_salida) = in_fecha_vuelo
      )
    ORDER BY t.horas_vuelo ASC
    LIMIT 2;

    -- Insertar Ingeniero
    INSERT INTO tripulacion_vuelo (vuelo_id, empleado_id, rol)
    SELECT v_vuelo_id, t.empleado_id, t.puesto
    FROM tripulacion t
    WHERE t.aerolinea_id = v_aerolinea_id
      AND t.puesto = 'Ingeniero'
      AND t.empleado_id NOT IN (
          SELECT tv.empleado_id 
          FROM tripulacion_vuelo tv 
          JOIN vuelos v ON tv.vuelo_id = v.vuelo_id 
          WHERE DATE(v.fecha_salida) = in_fecha_vuelo
      )
    ORDER BY t.horas_vuelo ASC
    LIMIT 1;

    -- Insertar Jefe de Cabina
    INSERT INTO tripulacion_vuelo (vuelo_id, empleado_id, rol)
    SELECT v_vuelo_id, t.empleado_id, t.puesto
    FROM tripulacion t
    WHERE t.aerolinea_id = v_aerolinea_id
      AND t.puesto = 'Jefe de Cabina'
      AND t.empleado_id NOT IN (
          SELECT tv.empleado_id 
          FROM tripulacion_vuelo tv 
          JOIN vuelos v ON tv.vuelo_id = v.vuelo_id 
          WHERE DATE(v.fecha_salida) = in_fecha_vuelo
      )
    ORDER BY t.horas_vuelo ASC
    LIMIT 1;

    -- Mostrar la tripulación asignada al finalizar
    SELECT 
        tv.vuelo_id,
        t.empleado_id,
        CONCAT(t.nombre, ' ', t.apellido) AS empleado,
        t.puesto AS rol_asignado
    FROM tripulacion_vuelo tv
    INNER JOIN tripulacion t USING(empleado_id)
    WHERE tv.vuelo_id = v_vuelo_id;
END $$


DROP PROCEDURE IF EXISTS checkin_automatico$$
CREATE PROCEDURE checkin_automatico(
    IN p_vuelo_id INT
)
BEGIN
    DECLARE v_vuelo_id INT;
    DECLARE v_reservacion_id INT;

    SELECT vuelo_id INTO v_vuelo_id FROM vuelos 
    WHERE p_vuelo_id = vuelo_id
    LIMIT 1;
    IF v_vuelo_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No existe un vuelo con ese id';
    END IF;

    SELECT reservacion_id INTO v_reservacion_id FROM reservaciones
    WHERE vuelo_id = p_vuelo_id
    AND estado = 'Utilizada'
    LIMIT 1;
    IF v_reservacion_id IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ya se realizo el check-in automatico para el vuelo con ese id';
    END IF; 
    -- Actualizar estado a 'Utilizada' y generar asiento aleatorio
    UPDATE reservaciones r
    JOIN vuelos v ON v.vuelo_id = r.vuelo_id
    SET r.estado = 'Utilizada',
        r.asiento = CONCAT(FLOOR(1 + RAND() * 30), CHAR(65 + FLOOR(RAND() * 6)))
    WHERE r.vuelo_id = p_vuelo_id
      AND r.estado = 'Confirmada'
      AND v.fecha_salida BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 24 HOUR);

    -- Insertar simulación de notificaciones con los asientos ya asignados
    INSERT INTO notificaciones (pasajero_id, vuelo_id, tipo, mensaje, email_destino, enviada)
    SELECT
        p.pasajero_id,
        r.vuelo_id,
        'Check-in',
        CONCAT('Check-in automático realizado con éxito. Su asiento asignado es: ', r.asiento),
        p.email,
        0
    FROM reservaciones r
    JOIN pasajeros p ON p.pasajero_id = r.pasajero_id
    JOIN vuelos v ON v.vuelo_id = r.vuelo_id
    WHERE r.vuelo_id = p_vuelo_id
      AND r.estado = 'Utilizada'
      AND v.fecha_salida BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 24 HOUR);

    -- Mostrar Check-in realizados
    SELECT
        reservacion_id,
        vuelo_id,
        pasajero_id,
        estado,
        asiento
    FROM reservaciones
    WHERE vuelo_id = p_vuelo_id
      AND estado = 'Utilizada';
END $$



DROP PROCEDURE IF EXISTS calcular_estadisticas_puntualidad$$
CREATE PROCEDURE calcular_estadisticas_puntualidad(
    IN in_anio INT,
    IN in_mes INT
)
BEGIN
    -- Validar que los parámetros de fecha tengan sentido
    IF in_mes < 1 OR in_mes > 12 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Mes inválido. Debe ser un valor entre 1 y 12.';
    END IF;

    -- Consulta principal del reporte mensual
    SELECT 
        a.nombre AS aerolinea,
        COUNT(v.vuelo_id) AS total_vuelos_mes,
        
        -- Contar vuelos a tiempo (Diferencia <= 15 min y estado Aterrizado)
        SUM(CASE 
            WHEN (TIMESTAMPDIFF(MINUTE, v.fecha_llegada_estimada, v.fecha_llegada_real) <= 15 
                  AND v.estado = 'Aterrizado') THEN 1 
            ELSE 0 
        END) AS vuelos_on_time,
        
        -- Contar vuelos retrasados (Diferencia > 15 min o estado Retrasado)
        SUM(CASE 
            WHEN (TIMESTAMPDIFF(MINUTE, v.fecha_llegada_estimada, v.fecha_llegada_real) > 15 
                  OR v.estado = 'Retrasado') THEN 1 
            ELSE 0 
        END) AS vuelos_retrasados,

        -- Calcular porcentaje On-Time
        ROUND(
            (SUM(CASE WHEN (TIMESTAMPDIFF(MINUTE, v.fecha_llegada_estimada, v.fecha_llegada_real) <= 15 AND v.estado = 'Aterrizado') THEN 1 ELSE 0 END) 
            / COUNT(v.vuelo_id)) * 100, 2
        ) AS porcentaje_on_time,

        -- Calcular porcentaje Retrasados
        ROUND(
            (SUM(CASE WHEN (TIMESTAMPDIFF(MINUTE, v.fecha_llegada_estimada, v.fecha_llegada_real) > 15 OR v.estado = 'Retrasado') THEN 1 ELSE 0 END) 
            / COUNT(v.vuelo_id)) * 100, 2
        ) AS porcentaje_retrasados

    FROM aerolineas a
    INNER JOIN vuelos v ON a.aerolinea_id = v.aerolinea_id
    WHERE YEAR(v.fecha_salida) = in_anio 
      AND MONTH(v.fecha_salida) = in_mes
    GROUP BY a.aerolinea_id, a.nombre
    ORDER BY porcentaje_on_time DESC;

END $$

DELIMITER ;

