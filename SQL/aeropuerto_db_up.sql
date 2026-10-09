DROP DATABASE IF EXISTS aeropuerto_db_up;
CREATE DATABASE aeropuerto_db_up
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
 
USE aeropuerto_db_up;

CREATE TABLE aerolineas (
  aerolinea_id    INT           AUTO_INCREMENT PRIMARY KEY,
  nombre          VARCHAR(120)  NOT NULL,
  codigo_IATA     CHAR(2)       NOT NULL UNIQUE,
  pais_origen     VARCHAR(80)   NOT NULL,
  fecha_fundacion DATE          NOT NULL,
  sitio_web       VARCHAR(200),
  myLogUP         TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP -- Ultima actualizacion 
);

CREATE TABLE aeronaves (
  aeronave_id          INT            AUTO_INCREMENT PRIMARY KEY,
  aerolinea_id         INT            NOT NULL,
  modelo               VARCHAR(80)    NOT NULL,
  capacidad_pasajeros  INT            NOT NULL,
  capacidad_carga      DECIMAL(10,2)  NOT NULL COMMENT 'En kg',
  fecha_fabricacion    YEAR           NOT NULL,
  ultimo_mantenimiento DATE,
  estado               ENUM('Activo','Mantenimiento','Inactivo') NOT NULL DEFAULT 'Activo',
  myLogUP              TIMESTAMP      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_aeronaves_aerolineas
    FOREIGN KEY (aerolinea_id) REFERENCES aerolineas(aerolinea_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE rutas (
  ruta_id             INT           AUTO_INCREMENT PRIMARY KEY,
  aeropuerto_origen   CHAR(3)       NOT NULL COMMENT 'Código IATA 3 letras',
  aeropuerto_destino  CHAR(3)       NOT NULL COMMENT 'Código IATA 3 letras',
  distancia_km        DECIMAL(8,2)  NOT NULL,
  tiempo_estimado_min INT           NOT NULL,
  myLogUP             TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT chk_rutas_distintas CHECK (aeropuerto_origen <> aeropuerto_destino)
);

CREATE TABLE vuelos (
  vuelo_id               INT        AUTO_INCREMENT PRIMARY KEY,
  aerolinea_id           INT        NOT NULL,
  ruta_id                INT        NOT NULL,
  aeronave_id            INT        NOT NULL,
  fecha_salida           TIMESTAMP  NOT NULL,
  fecha_llegada_estimada TIMESTAMP  NOT NULL,
  fecha_llegada_real     TIMESTAMP  NULL,
  puerta_embarque        VARCHAR(6) NOT NULL,
  asientos_disponibles   INT        NOT NULL DEFAULT 0,
  estado                 ENUM('Programado','En Vuelo','Aterrizado','Cancelado','Retrasado') NOT NULL DEFAULT 'Programado',
  myLogUP                TIMESTAMP  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_vuelos_aerolineas
    FOREIGN KEY (aerolinea_id) REFERENCES aerolineas(aerolinea_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_vuelos_rutas
    FOREIGN KEY (ruta_id) REFERENCES rutas(ruta_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_vuelos_aeronaves
    FOREIGN KEY (aeronave_id) REFERENCES aeronaves(aeronave_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE pasajeros (
  pasajero_id        INT          AUTO_INCREMENT PRIMARY KEY,
  pasaporte          VARCHAR(20)  NOT NULL UNIQUE,
  nombre             VARCHAR(60)  NOT NULL,
  apellido           VARCHAR(80)  NOT NULL,
  fecha_nacimiento   DATE         NOT NULL,
  nacionalidad       VARCHAR(60)  NOT NULL,
  telefono           VARCHAR(20),
  email              VARCHAR(120) UNIQUE,
  programa_fidelidad VARCHAR(80),
  vuelos_acumulados  INT          NOT NULL DEFAULT 0,
  myLogUP            TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE tripulacion (
  empleado_id        INT          AUTO_INCREMENT PRIMARY KEY,
  aerolinea_id       INT          NOT NULL,
  licencia           VARCHAR(30)  NOT NULL UNIQUE,
  nombre             VARCHAR(60)  NOT NULL,
  apellido           VARCHAR(80)  NOT NULL,
  puesto             ENUM('Piloto','Copiloto','Azafata','Ingeniero','Jefe de Cabina') NOT NULL,
  fecha_contratacion DATE         NOT NULL,
  horas_vuelo        DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  myLogUP            TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_tripulacion_aerolineas
    FOREIGN KEY (aerolinea_id) REFERENCES aerolineas(aerolinea_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE reservaciones (
  reservacion_id    INT            AUTO_INCREMENT PRIMARY KEY,
  vuelo_id          INT            NOT NULL,
  pasajero_id       INT            NOT NULL,
  clase             ENUM('Primera','Business','Turista','Premium') NOT NULL,
  asiento           VARCHAR(4)     NOT NULL,
  fecha_reservacion TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
  estado            ENUM('Confirmada','En Espera','Cancelada','Utilizada') NOT NULL DEFAULT 'Confirmada',
  precio            DECIMAL(10,2)  NOT NULL,
  metodo_pago       ENUM('Tarjeta','Efectivo','Transferencia') NOT NULL,
  myLogUP           TIMESTAMP      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_reservaciones_vuelos
    FOREIGN KEY (vuelo_id) REFERENCES vuelos(vuelo_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_reservaciones_pasajeros
    FOREIGN KEY (pasajero_id) REFERENCES pasajeros(pasajero_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  UNIQUE KEY uq_vuelo_asiento (vuelo_id, asiento)
);

CREATE TABLE tripulacion_vuelo (
  vuelo_id    INT          NOT NULL,
  empleado_id INT          NOT NULL,
  rol         VARCHAR(120) NOT NULL,
  myLogUP     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (vuelo_id, empleado_id),
  CONSTRAINT fk_tv_vuelos
    FOREIGN KEY (vuelo_id) REFERENCES vuelos(vuelo_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_tv_tripulacion
    FOREIGN KEY (empleado_id) REFERENCES tripulacion(empleado_id)
    ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE pagos (
  pago_id        INT            AUTO_INCREMENT PRIMARY KEY,
  reservacion_id INT            NOT NULL UNIQUE,
  monto          DECIMAL(10,2)  NOT NULL,
  metodo_pago    ENUM('Tarjeta','Efectivo','Transferencia') NOT NULL,
  estado         ENUM('Pendiente','Pagado','Rechazado','Reembolsado') NOT NULL DEFAULT 'Pagado',
  fecha_pago     TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
  referencia     VARCHAR(80)    NOT NULL UNIQUE,
  myLogUP        TIMESTAMP      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_pagos_reservaciones
    FOREIGN KEY (reservacion_id) REFERENCES reservaciones(reservacion_id)
    ON UPDATE CASCADE
);

CREATE TABLE notificaciones (
  notificacion_id INT          AUTO_INCREMENT PRIMARY KEY,
  pasajero_id     INT          NOT NULL,
  vuelo_id        INT          NOT NULL,
  tipo            ENUM('Retraso','Check-in','Reservacion','Mantenimiento') NOT NULL,
  mensaje         VARCHAR(255) NOT NULL,
  email_destino   VARCHAR(120) NOT NULL,
  enviada         TINYINT(1)   NOT NULL DEFAULT 0,
  fecha_creacion  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  myLogUP         TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_notificaciones_pasajeros
    FOREIGN KEY (pasajero_id) REFERENCES pasajeros(pasajero_id)
    ON UPDATE CASCADE,
  CONSTRAINT fk_notificaciones_vuelos
    FOREIGN KEY (vuelo_id) REFERENCES vuelos(vuelo_id)
    ON UPDATE CASCADE
);

-- INSERT'S
INSERT INTO aerolineas (nombre, codigo_IATA, pais_origen, fecha_fundacion, sitio_web) VALUES
('Aeromexico',         'AM', 'México',         '1934-09-15', 'https://www.aeromexico.com'),
('American Airlines',  'AA', 'Estados Unidos', '1934-04-15', 'https://www.aa.com'),
('Delta Air Lines',    'DL', 'Estados Unidos', '1929-05-30', 'https://www.delta.com'),
('Volaris',            'Y4', 'México',         '2004-03-01', 'https://www.volaris.com'),
('Interjet',           '4O', 'México',         '2005-01-01', 'https://www.interjet.com'),
('Iberia',             'IB', 'España',         '1927-06-28', 'https://www.iberia.com'),
('Air France',         'AF', 'Francia',        '1933-10-07', 'https://www.airfrance.com'),
('Lufthansa',          'LH', 'Alemania',       '1953-01-06', 'https://www.lufthansa.com'),
('United Airlines',    'UA', 'Estados Unidos', '1931-07-01', 'https://www.united.com'),
('Copa Airlines',      'CM', 'Panamá',         '1947-08-21', 'https://www.copaair.com'),
('Avianca',            'AV', 'Colombia',       '1919-12-05', 'https://www.avianca.com'),
('LATAM Airlines',     'LA', 'Chile',          '1929-03-05', 'https://www.latam.com');

INSERT INTO aeronaves (aerolinea_id, modelo, capacidad_pasajeros, capacidad_carga, fecha_fabricacion, ultimo_mantenimiento, estado) VALUES
(1,  'Boeing 737-800',    160,  17400.00, 2018, '2026-05-10', 'Activo'),
(1,  'Boeing 787-8',      246,  43100.00, 2020, '2026-04-22', 'Activo'),
(2,  'Airbus A321',       185,  20000.00, 2019, '2026-05-30', 'Activo'),
(3,  'Boeing 757-200',    200,  25500.00, 2015, '2026-03-15', 'Activo'),
(4,  'Airbus A320',       174,  17200.00, 2021, '2026-05-01', 'Activo'),
(5,  'Airbus A320neo',    180,  17500.00, 2022, '2026-02-28', 'Activo'),
(6,  'Airbus A350-900',   300,  60000.00, 2020, '2025-11-10', 'Mantenimiento'),
(7,  'Airbus A380-800',   555, 150000.00, 2017, '2025-10-05', 'Mantenimiento'),
(8,  'Boeing 747-8',      410, 137000.00, 2016, '2026-05-18', 'Activo'),
(9,  'Boeing 777-300ER',  396, 100000.00, 2018, '2026-05-25', 'Activo'),
(10, 'Embraer 190',        96,   9000.00, 2023, '2026-06-01', 'Activo'),
(11, 'Airbus A330-200',   250,  40000.00, 2019, '2026-04-10', 'Activo');

INSERT INTO rutas (aeropuerto_origen, aeropuerto_destino, distancia_km, tiempo_estimado_min) VALUES
('MEX', 'JFK', 3358.00,  290),
('MEX', 'LAX', 2567.00,  240),
('MEX', 'MIA', 2083.00,  200),
('GDL', 'MEX',  460.00,   55),
('MTY', 'MEX',  900.00,   80),
('MEX', 'MAD', 9091.00,  660),
('MEX', 'CDG', 9213.00,  665),
('MEX', 'LHR', 8921.00,  655),
('BOG', 'MEX', 3283.00,  310),
('SCL', 'MEX', 7077.00,  590),
('PTY', 'MEX', 2758.00,  265),
('MEX', 'CUN',  875.00,   85);

INSERT INTO vuelos (aerolinea_id, ruta_id, aeronave_id, fecha_salida, fecha_llegada_estimada, fecha_llegada_real, puerta_embarque, asientos_disponibles, estado) VALUES
-- Vuelos de HOY
(1,  4,  1,  CONCAT(CURDATE(),' 06:00:00'), CONCAT(CURDATE(),' 06:55:00'), NULL,'A01', 160, 'Programado'),
(4,  5,  5,  CONCAT(CURDATE(),' 08:30:00'), CONCAT(CURDATE(),' 09:50:00'), NULL,'B03', 174, 'Programado'),
(1,  12, 2,  CONCAT(CURDATE(),' 10:00:00'), CONCAT(CURDATE(),' 11:25:00'), NULL,'A05', 246, 'Programado'),
(2,  2,  3,  DATE_ADD(NOW(), INTERVAL 24 HOUR), CONCAT(CURDATE(),' 17:45:00'), NULL,'C08', 185, 'Programado'),
-- Vuelos pasados
(3,  3,  4,  '2026-06-05 13:00:00', '2026-06-05 16:20:00', '2026-06-05 16:18:00','C02', 200, 'Aterrizado'),
(1,  1,  1,  '2026-06-04 08:00:00', '2026-06-04 12:50:00', '2026-06-04 12:47:00','A12', 160, 'Aterrizado'),
(6,  6,  12, '2026-06-03 23:55:00', '2026-06-04 10:55:00', '2026-06-04 10:52:00','E10', 250, 'Aterrizado'),
(8,  8,  9,  '2026-06-02 22:30:00', '2026-06-03 09:25:00', '2026-06-03 09:22:00','G07', 410, 'Aterrizado'),
(10, 11, 11, '2026-06-01 14:20:00', '2026-06-01 18:45:00', '2026-06-01 18:43:00','C03', 96,  'Aterrizado'),
(12, 10, 12, '2026-05-30 11:45:00', '2026-05-30 21:35:00', '2026-05-30 21:31:00','H05', 250, 'Aterrizado'),
-- Vuelos futuros programados
(9,  1,  10, '2026-06-15 09:00:00', '2026-06-15 13:50:00', NULL,'D04', 96,  'Programado'),
(11, 9,  12, '2026-06-16 06:00:00', '2026-06-16 11:10:00', NULL,'B11', 250, 'Programado'),
-- Vuelos RETRASADOS
(1,  4,  1,  '2026-06-06 07:00:00', '2026-06-06 07:55:00', '2026-06-06 08:35:00','A03', 160, 'Aterrizado'),
(4,  5,  5,  '2026-06-05 09:15:00', '2026-06-05 10:35:00', '2026-06-05 11:10:00','D01', 174, 'Aterrizado'),
(2,  3,  3,  '2026-06-04 15:00:00', '2026-06-04 18:20:00', '2026-06-04 19:05:00','C11', 185, 'Aterrizado');


INSERT INTO pasajeros (pasaporte, nombre, apellido, fecha_nacimiento, nacionalidad, telefono, email, programa_fidelidad, vuelos_acumulados) VALUES
('MX1000001', 'Carlos',    'Ramírez Torres','1985-03-12', 'Mexicana','+52 222 111 0001', 'carlos.ramirez@email.com','Platino',47),
('MX1000002', 'Ana',       'López Herrera','1990-07-22', 'Mexicana','+52 222 111 0002', 'ana.lopez@email.com','Platino', 32),
('US1000003', 'John',      'Smith','1978-11-05', 'Americana','+1 555 200 0001','john.smith@email.com','Platino', 61),
('ES1000004', 'María',     'García Ruiz','1982-04-18', 'Española','+34 91 000 0001','maria.garcia@email.com','Platino', 28),
('CO1000005', 'Andrés',    'Martínez Silva','1980-09-30', 'Colombiana','+57 1 000 0001','andres.martinez@email.com', 'Oro',19),
('AR1000006', 'Lucas',     'Fernández Paz','1975-06-25', 'Argentina',  '+54 11 000 0001','lucas.fernandez@email.com',   'Platino',55),
('MX1000007', 'Sofía',     'Hernández Cruz','2000-01-15', 'Mexicana','+52 222 111 0003', 'sofia.hernandez@email.com', 'Plata', 2),
('FR1000008', 'Sophie',    'Dupont','1993-12-03', 'Francesa','+33 1 000 0001','sophie.dupont@email.com','Plata', 7),
('DE1000009', 'Thomas',    'Müller','1987-08-14', 'Alemana', '+49 30 000 0001','thomas.muller@email.com','Plata', 5),
('MX1000010', 'Valentina', 'Morales Díaz','2002-05-09', 'Mexicana','+52 222 111 0004', 'valentina.morales@email.com', 'Plata', 3),
('PA1000011', 'Roberto',   'Chen','1970-02-28', 'Panameña','+507 000 0001', 'roberto.chen@email.com','Plata', 8),
('CL1000012', 'Isabella',  'Vargas Campos','1998-10-11', 'Chilena', '+56 2 000 0001', 'isabella.vargas@email.com', 'Plata', 4);

INSERT INTO tripulacion (empleado_id, aerolinea_id, licencia, nombre, apellido, puesto, fecha_contratacion, horas_vuelo) VALUES
(1,  1, 'MEX-PIL-001', 'Roberto',  'Sánchez Vega',   'Piloto',         '2010-03-01', 8400.50),
(2,  1, 'MEX-COP-001', 'Elena',    'Fuentes Mora',   'Copiloto',       '2015-06-15', 4200.25),
(3,  1, 'MEX-AZF-001', 'Patricia', 'Luna Castillo',  'Azafata',        '2018-01-10', 3100.00),
(10, 1, 'MEX-AZF-002', 'Daniela',  'Castro Rojas',   'Azafata',        '2021-03-20', 1850.00),
(13, 1, 'MEX-ING-002', 'Alejandro', 'Gómez Prado',   'Ingeniero',      '2019-04-12', 2500.00),
(14, 1, 'MEX-JCA-001', 'Ricardo',  'Mendoza Ortiz',  'Jefe de Cabina', '2014-08-22', 5100.00),

(4,  2, 'USA-PIL-001', 'Michael',  'Johnson',        'Piloto',         '2008-07-20', 10200.75),
(5,  2, 'USA-COP-001', 'Sarah',    'Williams',       'Copiloto',       '2013-11-05', 5800.50),
(15, 2, 'USA-AZF-001', 'Emily',    'Davis',          'Azafata',        '2019-05-14', 2900.00),
(16, 2, 'USA-AZF-002', 'Jessica',  'Taylor',         'Azafata',        '2021-09-01', 1200.00),
(17, 2, 'USA-ING-001', 'David',    'Miller',         'Ingeniero',      '2016-02-11', 4300.00),
(18, 2, 'USA-JCA-001', 'James',    'Wilson',         'Jefe de Cabina', '2012-06-30', 6200.00),

(6,  3, 'USA-PIL-002', 'James',    'Brown',          'Piloto',         '2005-04-12', 14500.00),
(19, 3, 'USA-COP-002', 'John',     'Jones',          'Copiloto',       '2017-03-15', 3400.00),
(20, 3, 'USA-AZF-003', 'Linda',    'Garcia',         'Azafata',        '2018-11-20', 2100.00),
(21, 3, 'USA-AZF-004', 'Karen',    'Martinez',       'Azafata',        '2020-05-18', 1500.00),
(22, 3, 'USA-ING-002', 'Robert',   'Rodriguez',      'Ingeniero',      '2015-07-19', 5000.00),
(23, 3, 'USA-JCA-002', 'William',  'Smith',          'Jefe de Cabina', '2010-10-10', 7800.00),

(9,  4, 'MEX-ING-001', 'Fernando', 'Ríos Delgado',   'Ingeniero',      '2019-08-15', 2100.75),
(24, 4, 'Y4-PIL-001',  'Jorge',    'Hernández',      'Piloto',         '2012-01-10', 7300.00),
(25, 4, 'Y4-COP-001',  'Luis',     'Martínez',       'Copiloto',       '2016-05-20', 4100.00),
(26, 4, 'Y4-AZF-001',  'Gabriela', 'López',          'Azafata',        '2019-03-14', 2200.00),
(27, 4, 'Y4-AZF-002',  'Fernanda', 'Pérez',          'Azafata',        '2021-07-11', 1100.00),
(28, 4, 'Y4-JCA-001',  'Carlos',   'Sánchez',        'Jefe de Cabina', '2013-11-02', 5900.00),

(29, 5, '4O-PIL-001',  'Manuel',   'Jiménez',        'Piloto',         '2014-02-18', 6100.00),
(30, 5, '4O-COP-001',  'Ricardo',  'Ruiz',           'Copiloto',       '2018-06-12', 3200.00),
(31, 5, '4O-AZF-001',  'Paola',    'Díaz',           'Azafata',        '2017-09-05', 2800.00),
(32, 5, '4O-AZF-002',  'Natalia',  'Cruz',           'Azafata',        '2020-01-22', 1400.00),
(33, 5, '4O-ING-001',  'Eduardo',  'Alvarez',        'Ingeniero',      '2015-11-30', 4400.00),
(34, 5, '4O-JCA-001',  'Hugo',     'Morales',        'Jefe de Cabina', '2011-04-15', 8100.00),

(7,  6, 'ESP-PIL-001', 'Antonio',  'Pérez Navarro',  'Piloto',         '2009-09-01', 9300.25),
(8,  6, 'ESP-JCA-001', 'Carmen',   'Iglesias Torres','Jefe de Cabina', '2011-02-28', 6700.50),
(35, 6, 'IB-COP-001',  'Javier',   'Fernández',      'Copiloto',       '2016-08-12', 3900.00),
(36, 6, 'IB-AZF-001',  'Lucía',    'Blanco',         'Azafata',        '2018-02-20', 2700.00),
(37, 6, 'IB-AZF-002',  'Elena',    'Salvador',       'Azafata',        '2020-04-15', 1600.00),
(38, 6, 'IB-ING-001',  'Marcos',   'Suárez',         'Ingeniero',      '2014-10-05', 5200.00),

(39, 7, 'FRA-PIL-001', 'Pierre',   'Dubois',         'Piloto',         '2010-05-14', 8900.00),
(40, 7, 'FRA-COP-001', 'Jean',     'Moreau',         'Copiloto',       '2015-11-22', 4600.00),
(41, 7, 'FRA-AZF-001', 'Chloé',    'Bernard',        'Azafata',        '2017-03-10', 3100.00),
(42, 7, 'FRA-AZF-002', 'Camille',  'Petit',          'Azafata',        '2019-07-18', 2100.00),
(43, 7, 'FRA-ING-001', 'Lucas',    'Durand',         'Ingeniero',      '2013-09-25', 5800.00),
(44, 7, 'FRA-JCA-001', 'Thomas',   'Leroy',          'Jefe de Cabina', '2011-12-01', 7200.00),

(11, 8, 'DEU-PIL-001', 'Hans',     'Schmidt',        'Piloto',         '2006-05-10', 12800.00),
(45, 8, 'LH-COP-001',  'Klaus',    'Weber',          'Copiloto',       '2014-03-18', 5400.00),
(46, 8, 'LH-AZF-001',  'Anna',     'Wagner',         'Azafata',        '2018-06-25', 2900.00),
(47, 8, 'LH-AZF-002',  'Julia',    'Becker',         'Azafata',        '2021-02-14', 1300.00),
(48, 8, 'LH-ING-001',  'Stefan',   'Schulz',         'Ingeniero',      '2012-08-30', 6300.00),
(49, 8, 'LH-JCA-001',  'Uwe',      'Hoffmann',       'Jefe de Cabina', '2009-11-05', 9100.00),

(50, 9, 'UA-PIL-001',  'Brian',    'Clark',          'Piloto',         '2007-04-23', 11400.00),
(51, 9, 'UA-COP-001',  'Kevin',    'Rodriguez',      'Copiloto',       '2015-01-19', 4900.00),
(52, 9, 'UA-AZF-001',  'Michelle', 'Lewis',          'Azafata',        '2018-05-14', 3200.00),
(53, 9, 'UA-AZF-002',  'Kimberly', 'Lee',            'Azafata',        '2020-08-22', 1700.00),
(54, 9, 'UA-ING-001',  'Jason',    'Walker',         'Ingeniero',      '2013-03-11', 5900.00),
(55, 9, 'UA-JCA-001',  'Jeffrey',  'Hall',           'Jefe de Cabina', '2010-09-15', 8200.00),

(12, 10, 'PAN-COP-001','Andrea',   'González Ruiz',  'Copiloto',       '2020-10-01', 2600.50),
(56, 10, 'CM-PIL-001', 'Carlos',   'Castillo',       'Piloto',         '2011-06-14', 7900.00),
(57, 10, 'CM-AZF-001', 'María',    'Santos',         'Azafata',        '2016-02-20', 3800.00),
(58, 10, 'CM-AZF-002', 'Yanis',    'Vergara',        'Azafata',        '2019-11-05', 1900.00),
(59, 10, 'CM-ING-001', 'José',     'Arosemena',      'Ingeniero',      '2015-04-22', 4600.00),
(60, 10, 'CM-JCA-001', 'Luis',     'Barria',         'Jefe de Cabina', '2012-08-18', 6400.00),

(61, 11, 'AV-PIL-001', 'Juan',     'Castro',         'Piloto',         '2013-05-10', 6800.00),
(62, 11, 'AV-COP-001', 'Diego',    'Mendoza',        'Copiloto',       '2017-09-14', 3500.00),
(63, 11, 'AV-AZF-001', 'Carolina', 'Gómez',          'Azafata',        '2016-11-20', 4100.00),
(64, 11, 'AV-AZF-002', 'Diana',    'Rojas',          'Azafata',        '2020-04-12', 1600.00),
(65, 11, 'AV-ING-001', 'Andrés',   'Ortiz',          'Ingeniero',      '2014-07-19', 5100.00),
(66, 11, 'AV-JCA-001', 'Sergio',   'Silva',          'Jefe de Cabina', '2010-02-28', 8400.00),

(67, 12, 'LA-PIL-001', 'Felipe',   'Silva',          'Piloto',         '2009-12-05', 9200.00),
(68, 12, 'LA-COP-001', 'Christian', 'Muñoz',         'Copiloto',       '2014-06-18', 5100.00),
(69, 12, 'LA-AZF-001', 'Camila',   'Contreras',      'Azafata',        '2017-01-15', 3600.00),
(70, 12, 'LA-AZF-002', 'Valentina','Sepúlveda',      'Azafata',        '2021-03-10', 1400.00),
(71, 12, 'LA-ING-001', 'Gonzalo',  'Tapia',          'Ingeniero',      '2012-10-22', 6100.00),
(72, 12, 'LA-JCA-001', 'Rodrigo',  'Fuenzalida',     'Jefe de Cabina', '2011-05-30', 7300.00);
INSERT INTO reservaciones (vuelo_id, pasajero_id, clase, asiento, estado, precio, metodo_pago) VALUES
-- Reservaciones originales en vuelos de HOY / Pasados / Retrasados / Futuros
(1,  1,  'Business', '2A',  'Confirmada',  6800.00, 'Tarjeta'),
(2,  2,  'Turista',  '15C', 'Confirmada',  1500.00, 'Tarjeta'),
(3,  3,  'Primera',  '1A',  'Confirmada', 14500.00, 'Transferencia'),
(4,  4,  'Business', '4B',  'Confirmada',  7200.00, 'Tarjeta'),
(5,  5,  'Turista',  '22F', 'Utilizada',   1200.00, 'Efectivo'),
(6,  6,  'Business', '6D',  'Utilizada',   8500.00, 'Tarjeta'),
(7,  1,  'Turista',  '30A', 'Utilizada',   4200.00, 'Tarjeta'),
(8,  2,  'Primera',  '1B',  'Utilizada',  30000.00, 'Transferencia'),
(9,  3,  'Turista',  '18B', 'Utilizada',   5800.00, 'Tarjeta'),
(10, 4,  'Business', '8C',  'Utilizada',  15000.00, 'Tarjeta'),
(13, 1,  'Turista',  '10D', 'Utilizada',   1300.00, 'Tarjeta'),
(14, 2,  'Turista',  '20A', 'Utilizada',   1500.00, 'Efectivo'),
(15, 5,  'Business', '5C',  'Utilizada',   7000.00, 'Tarjeta'),
(11, 7,  'Turista',  '25E', 'Confirmada',  3800.00, 'Tarjeta'),
(12, 8,  'Business', '3D',  'Confirmada',  9500.00, 'Transferencia'),
-- NUEVAS RESERVACIONES para cumplir la condición de Vista 'pasajeros_frecuentes' (Carlos tiene ID=1)
(2,  1,  'Turista',  '15A', 'Utilizada',   1500.00, 'Tarjeta'),
(3,  1,  'Primera',  '1B',  'Utilizada',  14500.00, 'Tarjeta'),
(5,  1,  'Turista',  '22A', 'Utilizada',   1200.00, 'Tarjeta'),
(6,  1,  'Business', '6A',  'Utilizada',   8500.00, 'Tarjeta'),
(8,  1,  'Primera',  '1A',  'Utilizada',  30000.00, 'Tarjeta'),
(9,  1,  'Turista',  '18A', 'Utilizada',   5800.00, 'Tarjeta'),
(10, 1,  'Business', '8A',  'Utilizada',  15000.00, 'Tarjeta');

INSERT INTO tripulacion_vuelo (vuelo_id, empleado_id, rol) VALUES
(1,  1,  'Capitán del vuelo AM-GDL-MEX'),
(1,  2,  'Primer oficial'),
(1,  3,  'Azafata principal'),
(2,  9,  'Ingeniero de vuelo'),
(3,  1,  'Capitán del vuelo AM-MEX-CUN'),
(3,  10, 'Azafata servicio turista'),
(4,  4,  'Capitán del vuelo AA-MEX-LAX'),
(4,  5,  'Primer oficial'),
(6,  6,  'Capitán histórico DL305'),
(7,  7,  'Capitán histórico IB6501'),
(7,  8,  'Jefe de cabina IB6501'),
(8,  11, 'Capitán histórico LH400');

INSERT INTO pagos (reservacion_id, monto, metodo_pago, estado, referencia) VALUES
(1,   6800.00, 'Tarjeta','Pagado','REF-2026-0001'),
(2,   1500.00, 'Tarjeta','Pagado','REF-2026-0002'),
(3,  14500.00, 'Transferencia','Pagado','REF-2026-0003'),
(4,   7200.00, 'Tarjeta','Pagado','REF-2026-0004'),
(5,   1200.00, 'Efectivo','Pagado','REF-2026-0005'),
(6,   8500.00, 'Tarjeta','Pagado','REF-2026-0006'),
(7,   4200.00, 'Tarjeta','Pagado','REF-2026-0007'),
(8,  30000.00, 'Transferencia','Pagado','REF-2026-0008'),
(9,   5800.00, 'Tarjeta','Pagado','REF-2026-0009'),
(10, 15000.00, 'Tarjeta','Pagado','REF-2026-0010'),
(11,  1300.00, 'Tarjeta','Pagado','REF-2026-0011'),
(12,  1500.00, 'Efectivo','Pagado','REF-2026-0012'),
(13,  7000.00, 'Tarjeta','Pagado','REF-2026-0013'),
(14,  3800.00, 'Tarjeta','Pendiente','REF-2026-0014'),
(15,  9500.00, 'Transferencia', 'Pagado','REF-2026-0015');

INSERT INTO notificaciones (pasajero_id, vuelo_id, tipo, mensaje, email_destino, enviada) VALUES
(1,  1, 'Check-in',    'Su check-in para el vuelo de hoy GDL→MEX está disponible.','carlos.ramirez@email.com', 1),
(2,  2, 'Check-in',    'Su check-in para el vuelo de hoy MTY→MEX está disponible.','ana.lopez@email.com', 1),
(3,  3, 'Check-in',    'Su check-in para el vuelo de hoy MEX→CUN está disponible.','john.smith@email.com',1),
(4,  4, 'Check-in',    'Su check-in para el vuelo de hoy MEX→LAX está disponible.','maria.garcia@email.com',0),
(1, 13, 'Retraso',     'Su vuelo GDL→MEX del 06/06 llegó con 40 min de retraso.','carlos.ramirez@email.com',1),
(2, 14, 'Retraso',     'Su vuelo MTY→MEX del 05/06 llegó con 35 min de retraso.','ana.lopez@email.com',1),
(5, 15, 'Retraso',     'Su vuelo MEX→MIA del 04/06 llegó con 45 min de retraso.','andres.martinez@email.com',1),
(3,  3, 'Reservacion', 'Reservación confirmada. Vuelo MEX→CUN, asiento 1A, clase Primera.','john.smith@email.com', 1),
(4,  4, 'Reservacion', 'Reservación confirmada. Vuelo MEX→LAX, asiento 4B, Business.','maria.garcia@email.com',1),
(1,  6, 'Mantenimiento','Vuelo IB6501 asignado a aeronave alternativa por mantenimiento.', 'carlos.ramirez@email.com', 1),
(7, 11, 'Reservacion', 'Reservación confirmada. Vuelo MEX→JFK del 15/06, asiento 25E.', 'sofia.hernandez@email.com',1),
(8, 12, 'Reservacion', 'Reservación confirmada. Vuelo BOG→MEX del 16/06, asiento 3D.', 'sophie.dupont@email.com',0);



-- Inserts para poder realizar pruebas especificas

-- Creamos un nuevo vuelo limpio para Aeroméxico para evitar conflictos de horarios en la fecha de la prueba
INSERT INTO vuelos (aerolinea_id, ruta_id, aeronave_id, fecha_salida, fecha_llegada_estimada, puerta_embarque, asientos_disponibles, estado) 
VALUES (1, 4, 1, '2026-06-20 18:00:00', '2026-06-20 18:55:00', 'A09', 160, 'Programado');

-- Creamos un vuelo configurado dinámicamente para salir en 5 horas (dentro del rango de 24 horas requerido por el SP)
INSERT INTO vuelos (aerolinea_id, ruta_id, aeronave_id, fecha_salida, fecha_llegada_estimada, puerta_embarque, asientos_disponibles, estado) 
VALUES (1, 12, 1, DATE_ADD(NOW(), INTERVAL 5 HOUR), DATE_ADD(NOW(), INTERVAL 7 HOUR), 'A10', 160, 'Programado');
-- Registramos una reservación confirmada previa para este vuelo
INSERT INTO reservaciones (vuelo_id, pasajero_id, clase, asiento, estado, precio, metodo_pago) 
VALUES (17, 10, 'Turista', '12F', 'Confirmada', 2200.00, 'Efectivo');