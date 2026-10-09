USE aeropuerto_db_up;
DELIMITER $$

DROP PROCEDURE IF EXISTS transaccion_registrar_reservacion$$
CREATE PROCEDURE transaccion_registrar_reservacion(
    IN p_vuelo_id INT,
    IN p_pasajero_id INT,
    IN p_clase ENUM('Primera','Business','Turista','Premium'),
    IN p_asiento VARCHAR(10),
    IN p_precio DECIMAL(10,2),
    IN p_metodo_pago ENUM('Tarjeta','Efectivo','Transferencia'),
    IN p_monto_pago DECIMAL(10,2),
    IN p_referencia_pago VARCHAR(80)
)
BEGIN
    DECLARE v_nueva_reservacion_id INT;
    DECLARE v_asientos_libres INT;
    DECLARE v_pasajero_id INT;

    START TRANSACTION;

    -- Obtener disponibilidad de asientos
    SELECT asientos_disponibles INTO v_asientos_libres 
    FROM vuelos 
    WHERE vuelo_id = p_vuelo_id;

    -- Validar que si existe ese vuelo
    IF v_asientos_libres IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: No se encontro vuelo con ese id';
    END IF;

    -- Validar disponibilidad de asientos
    IF v_asientos_libres <= 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: No hay asientos disponibles en este vuelo.';
    END IF;

    -- Verificar que si exista ese pasajero
    SELECT pasajero_id INTO v_pasajero_id 
    FROM pasajeros 
    WHERE pasajero_id = p_pasajero_id;

    IF v_pasajero_id IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: No se encontro pasajero con ese id';
    END IF;

    -- Crear el registro en Reservaciones
    INSERT INTO reservaciones (vuelo_id, pasajero_id, clase, asiento, fecha_reservacion, estado, precio, metodo_pago)
    VALUES (p_vuelo_id, p_pasajero_id, p_clase, p_asiento, NOW(), 'Confirmada', p_precio, p_metodo_pago);

    -- Verificar si el INSERT funcionó
    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error al registrar la reservación.';
    END IF;

    -- Recuperar el ID de la reservación recién creada
    SET v_nueva_reservacion_id = LAST_INSERT_ID();

    -- Registrar el pago ligado a esa reservación
    INSERT INTO pagos (reservacion_id, monto, metodo_pago, estado, referencia)
    VALUES (v_nueva_reservacion_id, p_monto_pago, p_metodo_pago, 'Pagado', p_referencia_pago);

    -- Verificar si el pago se registró
    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error al registrar el pago financiero.';
    END IF;

    -- Restar el asiento del inventario del vuelo
    UPDATE vuelos 
    SET asientos_disponibles = asientos_disponibles - 1 
    WHERE vuelo_id = p_vuelo_id;

    -- Verificar éxito de la actualización de asientos
    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error al actualizar los asientos disponibles del vuelo.';
    ELSE
        -- Si todo fue exitoso y pasó los IF anteriores, guardamos permanentemente
        COMMIT;
        SELECT 'Transacción exitosa. Reservación y Pago procesados (COMMIT).' AS estado_proceso;
    END IF;

END $$


DROP PROCEDURE IF EXISTS transaccion_ejecutar_checkin$$
CREATE PROCEDURE transaccion_ejecutar_checkin(
    IN p_reservacion_id INT
)
BEGIN
    DECLARE v_pasaporte VARCHAR(30);
    DECLARE v_asientos_libres INT;
    DECLARE v_vuelo_id INT;

    START TRANSACTION;

    -- Obtener pasaporte, asientos y id del vuelo
    SELECT p.pasaporte, v.asientos_disponibles, r.vuelo_id
    INTO v_pasaporte, v_asientos_libres, v_vuelo_id
    FROM reservaciones r
    JOIN pasajeros p ON r.pasajero_id = p.pasajero_id
    JOIN vuelos v ON r.vuelo_id = v.vuelo_id
    WHERE r.reservacion_id = p_reservacion_id;

    -- Verificar que el pasaporte no sea nulo y este verificado
    IF v_pasaporte IS NULL OR v_pasaporte = '' THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Denegado: El pasajero no cuenta con un pasaporte válido registrado.';
    END IF;

    -- Verificar que si se encontro el id del vuelo
    IF v_vuelo_id IS NULL THEN 
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Denegado: No se encontro el id del vuelo';
    END IF;

    -- Verificar que si hayan asientos disponibles
    IF v_asientos_libres <= 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Denegado: El vuelo no cuenta con asientos disponibles para abordar.';
    END IF;

    -- Actualizar estado de la reservación a 'Utilizada'
    UPDATE reservaciones 
    SET estado = 'Utilizada' 
    WHERE reservacion_id = p_reservacion_id;

    # Verificar si el UPDATE realmente modificó la reservación
    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Fallo en check-in: Reservación inválida o ya procesada.';
    ELSE
        # Si pasó todas las reglas de negocio, confirmamos
        COMMIT;
        SELECT 'Check-in realizado y aprobado con éxito (COMMIT).' AS estado_proceso;
    END IF;

END $$
DELIMITER ;