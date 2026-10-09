# Guía de Ejecución - Proyecto Aeropuerto API

## Requisitos previos
- Node.js instalado
- Un IDE de base de datos SQL (como MySQL Workbench, SQL Server Management Studio, etc.)
- Un navegador web

## Pasos para ejecutar el proyecto

### 1. Configurar la Base de Datos

Antes de iniciar el servidor, debe crear la base de datos ejecutando los archivos SQL en su IDE de preferencia:

1. Abre tu IDE de base de datos
2. Ejecuta los siguientes archivos en orden (se encuentran en la carpeta `SQL/`):
   - `aeropuerto_db_up.sql` - Crea la base de datos y las tablas
   - `roles.sql` - Configura los roles y permisos
   - `Views.sql` - Crea las vistas
   - `Stored_Procedures.sql` - Crea los procedimientos almacenados
   - `Triggers.sql` - Crea los triggers
   - `Transactions.sql` - Configura las transacciones

### 2. Configurar el archivo .env

1. En la carpeta aero del `aeropuerto-api`, modifica el archivo `.env`
2. Configura las siguientes variables con tus credenciales:

```
DB_HOST=localhost
DB_USER=tu_usuario
DB_PASSWORD=tu_contraseña
DB_NAME=aeropuerto_db
DB_PORT=3306
```

Reemplaza `tu_usuario` y `tu_contraseña` con las credenciales que usas para conectarte a tu base de datos.

### 3. Instalar dependencias

1. Abre una terminal (CMD, PowerShell o bash)
2. Navega a la carpeta `aeropuerto-api`:
   ```
   cd aeropuerto-api
   ```
3. Instala las dependencias del proyecto:
   ```
   npm install
   ```

### 4. Iniciar el servidor

En la misma terminal de la carpeta `aeropuerto-api`, ejecuta:

```
node server.js
```

Deberías ver un mensaje indicando que el servidor se está ejecutando. Generalmente estará disponible en `http://localhost:3000`

### 5. Acceder a la aplicación web

1. Abre tu navegador web
2. Ve a la carpeta `PaginaWeb/`
3. Abre el archivo `index.html` en tu navegador
4. ¡Ahora podrás ver la página web funcionando con el servidor y la base de datos conectados!

## Estructura del Proyecto

- **aeropuerto-api/** - Servidor backend con Node.js
- **PaginaWeb/** - Frontend de la aplicación web
- **SQL/** - Scripts para crear la base de datos

## Solución de problemas

Si encuentras problemas de conexión a la base de datos:
- Verifica que la base de datos esté ejecutándose
- Comprueba que las credenciales en el archivo `.env` sean correctas
- Asegúrate de que el servidor de base de datos está escuchando en el puerto configurado
- Revisa la consola para ver mensajes de error específicos