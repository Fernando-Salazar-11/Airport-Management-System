USE aeropuerto_db_up;

CREATE ROLE IF NOT EXISTS 'admin_aerolinea';
CREATE ROLE IF NOT EXISTS 'empleado_checkin';
CREATE ROLE IF NOT EXISTS 'consulta_publica';


GRANT SELECT, INSERT, UPDATE, DELETE ON aeropuerto_db_up.reservaciones TO 'empleado_checkin';
GRANT SELECT, INSERT, UPDATE, DELETE ON aeropuerto_db_up.pasajeros TO 'empleado_checkin';


GRANT SELECT ON aeropuerto_db_up.vuelos_dia TO 'consulta_publica';

GRANT ALL PRIVILEGES ON aeropuerto_db_up.* TO 'admin_aerolinea';

FLUSH PRIVILEGES;