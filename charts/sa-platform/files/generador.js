import http from "k6/http";
import { sleep } from "k6";

const BASE = __ENV.BASE_URL;
const JSON_H = { headers: { "Content-Type": "application/json" } };
const USUARIO = { username: "generador-trafico", email: "generador@printhub.local", password: "Generador-2026" };

export const options = {
  scenarios: {
    usuarios: {
      executor: "constant-arrival-rate",
      rate: Number(__ENV.RPS),
      timeUnit: "1s",
      duration: "24h",
      preAllocatedVUs: 5,
      maxVUs: 20,
    },
  },
};

// Registro unico (409 si ya existe tras un reinicio: se ignora).
export function setup() {
  for (let i = 0; i < 30; i++) {
    const r = http.post(`${BASE}/api/auth/register`, JSON.stringify(USUARIO), JSON_H);
    if (r.status === 201 || r.status === 409) return;
    sleep(10);
  }
}

// El JWT llega en la cookie "token" (2 h). No se depende del cookie jar
// de k6 (no guarda cookies de hosts sin dominio, como el nombre del
// Service): se lee de la respuesta y se envia como Bearer, que el
// gateway acepta. Cada VU renueva la sesion cada 30 min.
let token = null;
let sesionHasta = 0;

function iniciarSesion() {
  const r = http.post(`${BASE}/api/auth/login`,
    JSON.stringify({ username: USUARIO.username, password: USUARIO.password }), JSON_H);
  const c = r.cookies.token;
  if (r.status !== 200 || !c || !c.length) return false;
  token = c[0].value;
  sesionHasta = Date.now() + 30 * 60 * 1000;
  return true;
}

export default function () {
  if ((!token || Date.now() > sesionHasta) && !iniciarSesion()) return;
  const params = { headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` } };

  // Catalogo inicial de figuras-service: ids 1-3 en todas las replicas.
  const figuraId = 1 + Math.floor(Math.random() * 3);
  if (Math.random() < 0.5) {
    http.post(`${BASE}/api/ordenes`,
      JSON.stringify({ cliente: "cliente-simulado", figuraId, cantidad: 1 + Math.floor(Math.random() * 3) }),
      params);
  } else {
    http.post(`${BASE}/api/figuras/graphql`,
      JSON.stringify({ query: "query($id: ID!) { figura(id: $id) { id nombre precio } }", variables: { id: figuraId } }),
      params);
  }
}
