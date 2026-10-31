const test = require("node:test");
const assert = require("node:assert/strict");
const app = require("../src/server");
const http = require("node:http");

test("GET /health responde estado ok", async () => {
  const server = http.createServer(app);
  await new Promise(resolve => server.listen(0, resolve));
  const address = server.address();
  const response = await fetch(`http://127.0.0.1:${address.port}/health`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: "ok" });
  await new Promise(resolve => server.close(resolve));
});
