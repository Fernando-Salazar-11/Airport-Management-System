const API = "http://localhost:3000/api";

function ocultarTodo() {
  document.querySelectorAll(".seccion").forEach(sec => {
    sec.style.display = "none";
  });
}

function modoAdmin() {
  ocultarTodo();

  document.querySelectorAll(".seccion").forEach(sec => {
    sec.style.display = "block";
  });

  cargarVuelos();
  cargarPasajeros();
  cargarMantenimiento();
}

function modoEmpleado() {
  ocultarTodo();

  document.getElementById("pasajeros").style.display = "block";
  document.getElementById("tripulacion").style.display = "block";

  cargarPasajeros();
}

function modoPublico() {
  ocultarTodo();

  document.getElementById("vuelos").style.display = "block";

  cargarVuelos();
}

function cargarVuelos() {
  fetch(API + "/vuelos-dia")
    .then(res => res.json())
    .then(data => {
      if (data.ok) {
        crearTabla("tablaVuelos", data.data);
      } else {
        console.error("Error vuelos:", data.error.message);
      }
    })
    .catch(err => console.error("Error de red vuelos:", err));
}

function cargarPasajeros() {
  fetch(API + "/pasajeros-frecuentes")
    .then(res => res.json())
    .then(data => {
      if (data.ok) {
        crearTabla("tablaPasajeros", data.data);
      } else {
        console.error("Error pasajeros:", data.error.message);
      }
    })
    .catch(err => console.error("Error de red pasajeros:", err));
}

function cargarMantenimiento() {
  fetch(API + "/aeronaves-mantenimiento")
    .then(res => res.json())
    .then(data => {
      if (data.ok) {
        crearTabla("tablaMantenimiento", data.data);
      } else {
        console.error("Error mantenimiento:", data.error.message);
      }
    })
    .catch(err => console.error("Error de red mantenimiento:", err));
}

function asignarTripulacion() {
  const fecha_vuelo = document.getElementById("fechaVuelo").value;
  const ruta_id = parseInt(document.getElementById("rutaId").value);

  console.log("Fecha:", fecha_vuelo);
  console.log("Ruta ID:", ruta_id);

  if (!fecha_vuelo || !ruta_id) {
    alert("Por favor ingresa la fecha del vuelo y el Ruta ID");
    return;
  }

  fetch(API + "/tripulacion/asignar", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ fecha_vuelo, ruta_id })
  })
    .then(res => res.json())
    .then(data => {
      if (data.ok) {
        alert(data.message);
        crearTabla("tablaMantenimiento", data.data);
      } else {
        alert("Error: " + data.error.message);
      }
    })
    .catch(err => console.error("Error de red tripulacion:", err));
}

function hacerCheckin() {
  const vuelo_id = parseInt(document.getElementById("vueloId").value);

  if (!vuelo_id) {
    alert("Por favor ingresa el Vuelo ID");
    return;
  }

  fetch(API + "/checkin", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ vuelo_id })
  })
    .then(res => res.json())
    .then(data => {
      if (data.ok) {
        alert(data.message);
      } else {
        alert("Error: " + data.error.message);
      }
    })
    .catch(err => console.error("Error de red checkin:", err));
}

function verEstadisticas() {
  fetch(API + "/estadisticas-puntualidad?anio=2026&mes=6")
    .then(res => res.json())
    .then(data => {
      const contenedor = document.getElementById("resultadoEstadisticas");
      const filas = data.data;

      if (!filas || filas.length === 0) {
        contenedor.innerHTML = "<p>No hay datos disponibles</p>";
        return;
      }

      let html = `
        <table border="1">
          <thead>
            <tr>
              ${Object.keys(filas[0]).map(col => `<th>${col}</th>`).join("")}
            </tr>
          </thead>
          <tbody>
      `;

      filas.forEach(fila => {
        html += "<tr>";
        Object.values(fila).forEach(valor => {
          html += `<td>${valor}</td>`;
        });
        html += "</tr>";
      });

      html += `
          </tbody>
        </table>
      `;

      contenedor.innerHTML = html;
    })
    .catch(err => console.error(err));
}

function crearTabla(id, datos) {
  const tabla = document.getElementById(id);

  if (!datos || datos.length === 0) {
    tabla.innerHTML = "<tr><td>No hay datos</td></tr>";
    return;
  }

  const columnas = Object.keys(datos[0]);

  let html = "<tr>";

  columnas.forEach(col => {
    html += `<th>${col}</th>`;
  });

  html += "</tr>";

  datos.forEach(fila => {
    html += "<tr>";

    columnas.forEach(col => {
      html += `<td>${fila[col]}</td>`;
    });

    html += "</tr>";
  });

  tabla.innerHTML = html;
}