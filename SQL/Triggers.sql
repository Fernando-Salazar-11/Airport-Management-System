USE aeropuerto_db_up;

DELIMITER $$

DROP TRIGGER IF EXISTS tg_actualizar_estado_aeronave$$
CREATE TRIGGER tg_actualizar_estado_aeronave
BEFORE UPDATE ON aeronaves
FOR EACH ROW
BEGIN
    -- Verificar si lo que cambió fue la fecha de mantenimiento
    IF OLD.ultimo_mantenimiento <> NEW.ultimo_mantenimiento THEN
        -- Si la fecha de mantenimiento está dentro de los últimos 180 días es reciente
        IF NEW.ultimo_mantenimiento >= DATE_SUB(NOW(), INTERVAL 180 DAY) THEN
            SET NEW.estado = 'Activo';
        ELSE
            SET NEW.estado = 'Mantenimiento';
        END IF;
    END IF;
END $$


DROP TRIGGER IF EXISTS tg_notificacion_retrasos$$
CREATE TRIGGER tg_notificacion_retrasos
AFTER UPDATE ON vuelos
FOR EACH ROW
BEGIN
    -- Validar que se haya ingresado o modificado la fecha real de llegada
    IF NEW.fecha_llegada_real IS NOT NULL AND 
       (OLD.fecha_llegada_real IS NULL OR NEW.fecha_llegada_real <> OLD.fecha_llegada_real) THEN
        
        -- Validar si la diferencia de tiempo es mayor a 15 minutos
        IF TIMESTAMPDIFF(MINUTE, NEW.fecha_llegada_estimada, NEW.fecha_llegada_real) > 15 THEN
            
            -- Insertar notificacion a pasajeros afectados
            INSERT INTO notificaciones (pasajero_id, vuelo_id, tipo, mensaje, email_destino, enviada)
            SELECT 
                r.pasajero_id, 
                NEW.vuelo_id, 
                'Retraso', 
                CONCAT('Estimado pasajero, le notificamos que su vuelo presenta un retraso. Nueva hora real de llegada: ', NEW.fecha_llegada_real), 
                p.email, 
                0
            FROM reservaciones r
            JOIN pasajeros p ON r.pasajero_id = p.pasajero_id
            WHERE r.vuelo_id = NEW.vuelo_id AND r.estado IN ('Confirmada', 'Utilizada');
            
        END IF;
    END IF;
END $$


DROP TRIGGER IF EXISTS tg_programa_fidelidad$$
CREATE TRIGGER tg_programa_fidelidad
AFTER INSERT ON reservaciones
FOR EACH ROW
BEGIN
    -- Incrementar el contador de vuelos
    UPDATE pasajeros 
    SET vuelos_acumulados = vuelos_acumulados + 1 
    WHERE pasajero_id = NEW.pasajero_id;

    -- Actualizar el nivel del programa de fidelidad basado en el nuevo conteo
    UPDATE pasajeros 
    SET programa_fidelidad = CASE 
        WHEN vuelos_acumulados >= 20 THEN 'Platino'
        WHEN vuelos_acumulados >= 10 THEN 'Oro'
        ELSE 'Plata'
    END
    WHERE pasajero_id = NEW.pasajero_id;
END $$

DELIMITER ;