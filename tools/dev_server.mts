// Serveur local : sert build/web et la vraie API (netlify/functions/api.mts) avec des données en mémoire.
//   flutter build web --dart-define=API_URL=http://localhost:8787/api
//   node --experimental-strip-types tools/dev_server.mts
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { createApi, type Kv } from "../netlify/functions/api.mts";

const docs = new Map<string, { data: unknown; etag: string }>();
let n = 0;
const kv: Kv = {
  async get(key) {
    const d = docs.get(key);
    return d ? { data: structuredClone(d.data), etag: d.etag } : null;
  },
  async set(key, data, cond) {
    const cur = docs.get(key);
    if ((cond.onlyIfNew && cur) || (cond.onlyIfMatch && cur?.etag !== cond.onlyIfMatch)) return { modified: false };
    const etag = `dev-${++n}`;
    docs.set(key, { data: structuredClone(data), etag });
    return { modified: true, etag };
  },
};
const api = createApi(kv);
const root = join(process.cwd(), "build/web");
const types: Record<string, string> = { ".html": "text/html", ".js": "text/javascript", ".mjs": "text/javascript", ".json": "application/json", ".wasm": "application/wasm", ".png": "image/png", ".jpg": "image/jpeg", ".otf": "font/otf", ".ttf": "font/ttf" };
const port = Number(process.env.PORT ?? 8787);

createServer(async (req, res) => {
  const url = new URL(req.url ?? "/", `http://localhost:${port}`);
  if (url.pathname.startsWith("/api/")) {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    const body = chunks.length ? Buffer.concat(chunks) : undefined;
    const r = await api(new Request(url, { method: req.method, headers: req.headers as Record<string, string>, body: req.method === "GET" || req.method === "HEAD" ? undefined : body }));
    res.writeHead(r.status, Object.fromEntries(r.headers));
    res.end(Buffer.from(await r.arrayBuffer()));
    return;
  }
  const file = normalize(join(root, url.pathname === "/" ? "index.html" : decodeURIComponent(url.pathname)));
  try {
    if (!file.startsWith(root)) throw new Error("hors du dossier");
    const data = await readFile(file);
    res.writeHead(200, { "content-type": types[extname(file)] ?? "application/octet-stream" });
    res.end(data);
  } catch {
    res.writeHead(404).end("Introuvable");
  }
}).listen(port, () => console.log(`Guide des Congés : http://localhost:${port}`));
