const express = require("express");
const client = require("prom-client");

const app = express();
const port = process.env.PORT || 3000;

// Recolecta métricas estándar del proceso Node.js.
client.collectDefaultMetrics({ prefix: "pf_app_" });
const httpRequests = new client.Counter({
  name: "pf_http_requests_total",
  help: "Cantidad total de solicitudes HTTP",
  labelNames: ["method", "route", "status"]
});

app.use((req, res, next) => {
  res.on("finish", () => {
    httpRequests.inc({
      method: req.method,
      route: req.route?.path || req.path,
      status: String(res.statusCode)
    });
  });
  next();
});

app.get("/", (_req, res) => {
  res.type("html").send(`<!doctype html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>PF DevOps</title><style>body{font:16px Arial;max-width:760px;margin:12vh auto;padding:24px;background:#101827;color:#e8eef8}
.card{padding:28px;border:1px solid #34445e;border-radius:14px;background:#1b2940}
h1{color:#7dd3fc}code{color:#a7f3d0}</style></head>
<body><div class="card"><h1>Proyecto Final DevOps</h1>
<p>Aplicación de demostración desplegada mediante un pipeline CI/CD.</p>
<p>Estado: <strong>funcionando</strong></p><p>Endpoints: <code>/health</code> y <code>/metrics</code></p>
</div></body></html>`);
});

app.get("/health", (_req, res) => res.status(200).json({ status: "ok" }));
app.get("/metrics", async (_req, res) => {
  res.set("Content-Type", client.register.contentType);
  res.end(await client.register.metrics());
});

if (require.main === module) {
  app.listen(port, "0.0.0.0", () => console.log(`Aplicación escuchando en ${port}`));
}
module.exports = app;
