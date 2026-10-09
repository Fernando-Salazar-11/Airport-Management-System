# ✈️ Airport Management System

![Node.js](https://img.shields.io/badge/Node.js-v18%2B-green?style=flat&logo=node.js)
![Express.js](https://img.shields.io/badge/Express.js-4.18-blue?style=flat&logo=express)
![MySQL](https://img.shields.io/badge/MySQL-8.0-orange?style=flat&logo=mysql)
![License](https://img.shields.io/badge/License-MIT-brightgreen)

An end-to-end relational database and API solution designed to model, manage, and optimize core airport operations. Built as part of an Advanced Database Systems course, this system integrates complex SQL logic (stored procedures, triggers, views, transactions, and role-based access control) with a RESTful API and an interactive web interface.

---

## 📌 Table of Contents
- [Features](#-features)
- [Architecture & Tech Stack](#-architecture--tech-stack)
- [Database Architecture](#-database-architecture)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [1. Database Setup](#1-database-setup)
  - [2. Environment Configuration](#2-environment-configuration)
  - [3. Backend Setup](#3-backend-setup)
  - [4. Frontend Access](#4-frontend-access)
- [API Reference](#-api-reference)
- [License](#-license)

---

## ✨ Features

- **Airlines & Fleet Management:** Track active aircraft, fleet capacities, and maintenance status.
- **Flight Scheduling & Operations:** Real-time monitoring of flight departures, arrival estimates, gate assignments, and seat availability.
- **Passenger Tracking & Frequent Flyer Logs:** Loyalty program status tracking and frequent traveler reporting.
- **Advanced Database Automation:**
  - **Stored Procedures:** Streamlined complex query operations and data manipulation.
  - **Triggers:** Automated logging, seat capacity checks, and row-level updates (`myLogUP`).
  - **Views:** Optimized analytical queries for daily flight operational dashboards and frequent flyer analytics.
  - **Transactions:** Atomicity and data integrity for multi-table operations.
  - **RBAC (Role-Based Access Control):** Granular SQL user management.

---

## 🛠️ Architecture & Tech Stack

- **Backend:** Node.js, Express.js
- **Database:** MySQL (using `mysql2/promise` pool connection)
- **Frontend:** Vanilla JavaScript, HTML5, CSS3
- **Configuration & Utilities:** `dotenv`, `cors`, `nodemon`

---

## 🗄️ Database Architecture

The relational schema handles core entities including:
- `aerolineas` (Airlines)
- `aeronaves` (Aircraft Fleet)
- `rutas` (Flight Routes with origin/destination constraints)
- `vuelos` (Scheduled and Active Flights)
- `pasajeros` (Passenger Records & Loyalty Programs)
- `tripulacion` (Crew Allocation)

*For interactive exploration, view the included ER Diagram (`diagrama_ER.html`) or inspect the Data Dictionary (`diccionario_datos_1.pdf`).*

---

## 📂 Project Structure

```text
Airport-Management-System/
├── aeropuerto-api/          # Node.js REST API
│   ├── server.js            # Express application entry point & routes
│   ├── package.json         # Dependencies and scripts
│   └── .env                 # Environment variables configuration
├── PaginaWeb/               # Frontend dashboard UI
│   ├── index.html           # Main HTML dashboard
│   └── index.js             # Client-side API interactions
├── SQL/                     # Database creation & initialization scripts
│   ├── aeropuerto_db_up.sql # Table creation and schema definition
│   ├── roles.sql            # User roles and permissions setup
│   ├── Views.sql            # Analytical views creation
│   ├── Stored_Procedures.sql# Stored procedures
│   ├── Triggers.sql         # Automated DB triggers
│   └── Transactions.sql     # Transaction scenarios
├── diagrama_ER.html         # Interactive Entity-Relationship Diagram
└── diccionario_datos_1.pdf  # Comprehensive Data Dictionary
```

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed:
- [Node.js](https://nodejs.org/) (v16.x or higher)
- [MySQL Server](https://dev.mysql.com/downloads/mysql/) (v8.0 recommended) or MySQL Workbench

---

### 1. Database Setup

Execute the SQL scripts located in the `SQL/` directory in the following sequential order using your preferred SQL client:

1. `aeropuerto_db_up.sql` — Creates database and tables.
2. `roles.sql` — Configures system security roles.
3. `Views.sql` — Generates database views.
4. `Stored_Procedures.sql` — Builds stored routines.
5. `Triggers.sql` — Attaches automated triggers.
6. `Transactions.sql` — Executes baseline transaction logic.

---

### 2. Environment Configuration

Navigate to `aeropuerto-api/` and create or edit the `.env` file with your local MySQL credentials:

```env
DB_HOST=localhost
DB_USER=your_db_user
DB_PASSWORD=your_db_password
DB_NAME=aeropuerto_db_up
DB_PORT=3306
PORT=3000
```

---

### 3. Backend Setup

Open a terminal and run:

```bash
# Navigate to API directory
cd aeropuerto-api

# Install dependencies
npm install

# Start development server with auto-reload
npm run dev

# Or start standard production server
npm start
```

The API server will run at `http://localhost:3000`.

---

### 4. Frontend Access

Open `PaginaWeb/index.html` directly in your web browser or serve it with a static file server to access the live dashboard connected to the REST API.

---

## 📡 API Reference

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/health` | Verifies API health and MySQL database connection status |
| `GET` | `/api/vuelos-dia` | Fetches all scheduled flights for the current day |
| `GET` | `/api/pasajeros-frecuentes` | Retrieves frequent flyer analytics |
| `GET` | `/api/aeronaves-mantenimiento` | Returns list of aircraft currently undergoing maintenance |
