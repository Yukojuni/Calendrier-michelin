// API du Guide des Congés, hébergée sur Netlify (Functions + Blobs).
//
//   GET    /api/absences              → { version, items: Absence[] }   (If-None-Match → 304)
//   PUT    /api/absences/:id          ← Absence
//   DELETE /api/absences/:id
//   GET    /api/scores?game=…         → { scores: { prénom: score } }
//   POST   /api/scores                ← { game, person, score }  → { record }
//   GET    /api/health                → { ok: true }
//
// Les données tiennent dans deux documents JSON (« absences » et « scores »).
// Chaque écriture relit le document et ne l'enregistre que s'il n'a pas changé
// entre-temps (etag) : deux personnes qui écrivent en même temps ne s'écrasent pas.

import { getStore } from "@netlify/blobs";
import type { Config } from "@netlify/functions";

export const PEOPLE = ["Opaline", "Jenny", "Samuel", "Lucas", "Tom", "Romain", "Quentin"];
export const KINDS = ["conge", "tt", "bureau", "ecole"];
export const GAMES = ["attrape-quentin", "route-des-conges"];

export interface Absence {
  id: string;
  date: string;
  person: string;
  kind: string;
  note: string;
  updatedAt: string;
}

type Absences = Record<string, Absence>;
type Scores = Record<string, Record<string, number>>;

/** Ce dont l'API a besoin pour stocker ses documents. */
export interface Kv {
  get(key: string): Promise<{ data: unknown; etag?: string } | null>;
  set(key: string, data: unknown, cond: { onlyIfMatch?: string; onlyIfNew?: boolean }): Promise<{ modified: boolean; etag?: string }>;
}

const CORS = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET, PUT, POST, DELETE, OPTIONS",
  "access-control-allow-headers": "content-type, if-none-match",
  "access-control-expose-headers": "etag",
};

const json = (body: unknown, status = 200, extra: Record<string, string> = {}) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store", ...CORS, ...extra },
  });

const fail = (status: number, message: string) => json({ error: message }, status);

/** Lit un document, le modifie et l'enregistre, en recommençant si quelqu'un a écrit entre-temps. */
async function update<T>(kv: Kv, key: string, empty: T, change: (doc: T) => void): Promise<string | undefined> {
  for (let attempt = 0; attempt < 6; attempt++) {
    const current = await kv.get(key);
    const doc = (current?.data as T) ?? structuredClone(empty);
    change(doc);
    const res = await kv.set(key, doc, current?.etag ? { onlyIfMatch: current.etag } : { onlyIfNew: true });
    if (res.modified) return res.etag;
    await new Promise((r) => setTimeout(r, 40 + Math.random() * 120));
  }
  throw new Error("conflict");
}

export function validateAbsence(id: string, body: unknown): Absence | string {
  if (typeof body !== "object" || body === null) return "Corps JSON attendu.";
  const b = body as Record<string, unknown>;
  const date = b.date, person = b.person, kind = b.kind;
  const note = b.note ?? "";
  if (typeof date !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(date)) return "Date invalide (AAAA-MM-JJ).";
  if (typeof person !== "string" || !PEOPLE.includes(person)) return "Personne inconnue.";
  if (typeof kind !== "string" || !KINDS.includes(kind)) return "Statut inconnu.";
  if (typeof note !== "string" || note.length > 80) return "Le petit mot fait 80 caractères au plus.";
  if (id !== `${date}_${person}`) return "L'identifiant ne correspond pas à la date et à la personne.";
  return { id, date, person, kind, note: note.trim(), updatedAt: new Date().toISOString() };
}

export function createApi(kv: Kv) {
  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });
    const url = new URL(req.url);
    const parts = url.pathname.replace(/^\/(\.netlify\/functions\/)?api\/?/, "").split("/").filter(Boolean);
    try {
      if (parts[0] === "health") return json({ ok: true });

      if (parts[0] === "absences" && parts.length === 1 && req.method === "GET") {
        const doc = await kv.get("absences");
        const version = doc?.etag ?? "empty";
        if (req.headers.get("if-none-match") === version) return new Response(null, { status: 304, headers: { ...CORS, etag: version } });
        return json({ version, items: Object.values((doc?.data as Absences) ?? {}) }, 200, { etag: version });
      }

      if (parts[0] === "absences" && parts.length === 2) {
        const id = decodeURIComponent(parts[1]);
        if (req.method === "PUT") {
          const absence = validateAbsence(id, await req.json().catch(() => null));
          if (typeof absence === "string") return fail(400, absence);
          const version = await update<Absences>(kv, "absences", {}, (doc) => {
            doc[id] = absence;
          });
          return json({ ok: true, version, absence });
        }
        if (req.method === "DELETE") {
          const version = await update<Absences>(kv, "absences", {}, (doc) => {
            delete doc[id];
          });
          return json({ ok: true, version });
        }
      }

      if (parts[0] === "scores" && parts.length === 1) {
        if (req.method === "GET") {
          const game = url.searchParams.get("game") ?? "";
          if (!GAMES.includes(game)) return fail(400, "Jeu inconnu.");
          const doc = await kv.get("scores");
          return json({ scores: ((doc?.data as Scores) ?? {})[game] ?? {} });
        }
        if (req.method === "POST") {
          const b = (await req.json().catch(() => null)) as Record<string, unknown> | null;
          const game = b?.game, person = b?.person, score = b?.score;
          if (typeof game !== "string" || !GAMES.includes(game)) return fail(400, "Jeu inconnu.");
          if (typeof person !== "string" || !PEOPLE.includes(person)) return fail(400, "Personne inconnue.");
          if (typeof score !== "number" || !Number.isInteger(score) || score < 0 || score > 10_000_000) return fail(400, "Score invalide.");
          let record = false;
          await update<Scores>(kv, "scores", {}, (doc) => {
            const g = (doc[game] ??= {});
            record = score > (g[person] ?? -1);
            if (record) g[person] = score;
          });
          return json({ record });
        }
      }

      return fail(404, "Route inconnue.");
    } catch (e) {
      console.error(e);
      return fail(503, "Le serveur est occupé, réessaie dans un instant.");
    }
  };
}

/** Stockage Netlify Blobs (cohérence forte : on relit toujours la dernière version). */
function blobs(): Kv {
  const store = getStore({ name: "guide-des-conges", consistency: "strong" });
  return {
    async get(key) {
      const res = await store.getWithMetadata(key, { type: "json" });
      return res ? { data: res.data, etag: res.etag } : null;
    },
    async set(key, data, cond) {
      return cond.onlyIfMatch ? store.setJSON(key, data, { onlyIfMatch: cond.onlyIfMatch }) : store.setJSON(key, data, { onlyIfNew: true });
    },
  };
}

export default async (req: Request) => createApi(blobs())(req);

export const config: Config = { path: "/api/*" };
