/**
 * Static file server (no Vite = no Host-header blocking). Good behind Cloudflare Tunnel.
 *
 * Port: SHADOW_BOX_PORT (default 8844).
 * SHADOW_BOX_STATIC_ROOT: if set (e.g. "dist"), only that folder under this project is served.
 * Otherwise tries project root, then public/, then dist/.
 *
 * (XO catalog + API moved to DreamSystemz.COM under /xo/ — see that repo's static-server.mjs.)
 */
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.SHADOW_BOX_PORT || 8844) || 8844;

function basesFromEnv() {
  const sub = process.env.SHADOW_BOX_STATIC_ROOT;
  if (!sub || !String(sub).trim()) {
    return [__dirname, path.join(__dirname, "public"), path.join(__dirname, "dist")];
  }
  const abs = path.resolve(__dirname, String(sub).trim());
  const rel = path.relative(__dirname, abs);
  if (rel.startsWith("..") || path.isAbsolute(rel)) {
    throw new Error("SHADOW_BOX_STATIC_ROOT must stay inside the project directory.");
  }
  return [abs];
}

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".png": "image/png",
  ".webp": "image/webp",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".woff2": "font/woff2",
  ".txt": "text/plain; charset=utf-8",
};

function safeRel(root, pathname) {
  const decoded = decodeURIComponent(pathname.split("?")[0] || "/");
  let rel = path.posix.normalize(decoded.replace(/\\/g, "/")).replace(/^(\.\.(\/|$))+/, "");
  if (rel.startsWith("..")) return null;
  const abs = path.join(root, rel);
  const relToRoot = path.relative(root, abs);
  if (relToRoot.startsWith("..") || path.isAbsolute(relToRoot)) return null;
  return abs;
}

const BASES = basesFromEnv();

/** Where legacy `/xo` and `/XO` URLs redirect (local dev: `http://127.0.0.1:8845/xo/`). */
const XO_REDIRECT = (process.env.SHADOW_BOX_XO_REDIRECT || "https://dreamsystemz.com/xo/").trim();

const server = http.createServer((req, res) => {
  const host = req.headers.host || "localhost";
  const url = new URL(req.url || "/", `http://${host}`);

  let pathname = url.pathname;
  if (pathname === "/") pathname = "/index.html";

  let rel = pathname.slice(1) || "index.html";
  if (rel.includes("..")) {
    res.writeHead(403).end("Forbidden");
    return;
  }

  /** Legacy XO storefront (was `/XO/` on disk) → DreamSystemz. */
  const low = rel.toLowerCase();
  if (low === "xo" || low.startsWith("xo/") || low === "xo/index.html") {
    res.writeHead(302, { Location: XO_REDIRECT });
    res.end();
    return;
  }

  function walkBases(i) {
    if (i >= BASES.length) {
      res.writeHead(404).end("Not found");
      return;
    }
    const filePath = safeRel(BASES[i], rel);
    if (!filePath) {
      walkBases(i + 1);
      return;
    }
    fs.stat(filePath, (err, st) => {
      if (!err && st.isFile()) {
        streamFile(filePath, res);
        return;
      }
      if (!err && st.isDirectory()) {
        const indexPath = path.join(filePath, "index.html");
        fs.stat(indexPath, (e2, st2) => {
          if (!e2 && st2.isFile()) streamFile(indexPath, res);
          else walkBases(i + 1);
        });
        return;
      }
      walkBases(i + 1);
    });
  }

  walkBases(0);
});

function streamFile(filePath, res) {
  const ext = path.extname(filePath).toLowerCase();
  const type = MIME[ext] || "application/octet-stream";
  res.writeHead(200, { "Content-Type": type, "Cache-Control": "no-cache" });
  fs.createReadStream(filePath).pipe(res);
}

server.listen(PORT, "127.0.0.1", () => {
  const mode =
    BASES.length === 1 ? `dist-only (${path.relative(__dirname, BASES[0]) || "."})` : "root | public | dist";
  console.log(`Shadow-box.ORG static (${mode}) -> http://127.0.0.1:${PORT}/`);
});
