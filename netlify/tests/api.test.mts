// Tests de l'API avec un stockage en mémoire : node --experimental-strip-types --test netlify/tests/api.test.mts
import { test } from "node:test";
import assert from "node:assert/strict";
import { createApi, type Kv } from "../functions/api.mts";

function memory(): Kv & { writes: number } {
  const docs = new Map<string, { data: unknown; etag: string }>();
  let n = 0;
  return {
    writes: 0,
    async get(key) {
      const d = docs.get(key);
      return d ? { data: structuredClone(d.data), etag: d.etag } : null;
    },
    async set(key, data, cond) {
      const cur = docs.get(key);
      if (cond.onlyIfNew && cur) return { modified: false };
      if (cond.onlyIfMatch && cur?.etag !== cond.onlyIfMatch) return { modified: false };
      const etag = `e${++n}`;
      docs.set(key, { data: structuredClone(data), etag });
      this.writes++;
      return { modified: true, etag };
    },
  };
}

const call = (api: (r: Request) => Promise<Response>, method: string, path: string, body?: unknown, headers: Record<string, string> = {}) =>
  api(new Request(`https://exemple.netlify.app${path}`, { method, headers: { "content-type": "application/json", ...headers }, body: body === undefined ? undefined : JSON.stringify(body) }));

test("poser, lister, retirer une absence", async () => {
  const api = createApi(memory());
  let res = await call(api, "GET", "/api/absences");
  assert.deepEqual((await res.json()).items, []);
  res = await call(api, "PUT", "/api/absences/2026-11-20_Lucas", { date: "2026-11-20", person: "Lucas", kind: "conge", note: " Ski " });
  assert.equal(res.status, 200);
  res = await call(api, "GET", "/api/absences");
  const body = await res.json();
  assert.equal(body.items.length, 1);
  assert.equal(body.items[0].note, "Ski");
  // Même version : 304.
  res = await call(api, "GET", "/api/absences", undefined, { "if-none-match": body.version });
  assert.equal(res.status, 304);
  res = await call(api, "DELETE", "/api/absences/2026-11-20_Lucas");
  assert.equal(res.status, 200);
  assert.deepEqual((await (await call(api, "GET", "/api/absences")).json()).items, []);
});

test("refuse les données invalides", async () => {
  const api = createApi(memory());
  for (const [id, body] of [
    ["2026-11-20_Lucas", { date: "2026-11-20", person: "Inconnu", kind: "conge" }],
    ["2026-11-20_Lucas", { date: "2026-11-20", person: "Lucas", kind: "vacances" }],
    ["2026-11-21_Lucas", { date: "2026-11-20", person: "Lucas", kind: "conge" }],
    ["2026-11-20_Lucas", { date: "2026-11-20", person: "Lucas", kind: "conge", note: "x".repeat(81) }],
  ] as const) {
    assert.equal((await call(api, "PUT", `/api/absences/${id}`, body)).status, 400);
  }
});

test("des écritures simultanées ne se perdent pas", async () => {
  const api = createApi(memory());
  const people = ["Opaline", "Jenny", "Samuel", "Lucas", "Tom", "Romain", "Quentin"];
  await Promise.all(people.map((p) => call(api, "PUT", `/api/absences/2026-12-01_${p}`, { date: "2026-12-01", person: p, kind: "tt" })));
  const items = (await (await call(api, "GET", "/api/absences")).json()).items;
  assert.equal(items.length, 7);
});

test("les scores ne gardent que le record", async () => {
  const api = createApi(memory());
  const post = (person: string, score: number) => call(api, "POST", "/api/scores", { game: "route-des-conges", person, score }).then((r) => r.json());
  assert.deepEqual(await post("Tom", 300), { record: true });
  assert.deepEqual(await post("Tom", 100), { record: false });
  assert.deepEqual(await post("Jenny", 420), { record: true });
  const res = await call(api, "GET", "/api/scores?game=route-des-conges");
  assert.deepEqual((await res.json()).scores, { Tom: 300, Jenny: 420 });
  assert.equal((await call(api, "POST", "/api/scores", { game: "autre", person: "Tom", score: 1 })).status, 400);
});
