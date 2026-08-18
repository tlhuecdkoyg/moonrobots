import http from "node:http";
import { createReadStream, existsSync } from "node:fs";
import { extname, join, normalize, resolve } from "node:path";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { randomUUID } from "node:crypto";
import { browserCrawl } from "./browser_crawler.mjs";

const root = resolve(fileURLToPath(new URL("..", import.meta.url)));
const crawler = join(root, "_build", "native", "debug", "build", "cmd", "crawler", "crawler.exe");
const port = Number(process.env.MOONROBOTS_PORT || 8877);
const mime = new Map([
  [".html", "text/html; charset=utf-8"], [".css", "text/css; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"], [".wasm", "application/wasm"],
  [".md", "text/markdown; charset=utf-8"], [".png", "image/png"],
]);
let crawlRunning = false;
const crawlJobs = new Map();

function localOrigin(req) {
  const origin = req.headers.origin;
  return !origin || origin === `http://127.0.0.1:${port}` || origin === `http://localhost:${port}`;
}

function json(res, status, value) {
  const body = JSON.stringify(value);
  res.writeHead(status, { "Content-Type": "application/json; charset=utf-8", "Content-Length": Buffer.byteLength(body) });
  res.end(body);
}

async function readJson(req) {
  const chunks = [];
  let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    if (size > 16_384) throw new Error("请求内容过大");
    chunks.push(chunk);
  }
  return JSON.parse(Buffer.concat(chunks).toString("utf8"));
}

function boundedInt(value, fallback, min, max) {
  const number = Number(value);
  return Number.isInteger(number) ? Math.min(max, Math.max(min, number)) : fallback;
}

async function runCrawler(req, res) {
  if (!localOrigin(req)) return json(res, 403, { error: "拒绝非本地来源的抓取请求。" });
  if (crawlRunning) return json(res, 429, { error: "已有抓取任务正在运行，请稍候。" });
  if (!existsSync(crawler)) return json(res, 503, { error: "原生爬虫尚未构建，请重新运行 scripts/serve.ps1。" });
  let input;
  try { input = await readJson(req); } catch (error) { return json(res, 400, { error: String(error.message || error) }); }
  const url = typeof input.url === "string" ? input.url.trim() : "";
  const token = typeof input.productToken === "string" ? input.productToken.trim() : "MoonRobotsBot";
  if (!/^https?:\/\//i.test(url) || !/^[A-Za-z_-]+$/.test(token)) return json(res, 400, { error: "请输入 HTTP(S) URL 和有效的 Product Token。" });
  const args = [url, token, String(boundedInt(input.maxPages, 20, 1, 100)), String(boundedInt(input.maxDepth, 2, 0, 5)), String(boundedInt(input.delayMs, 500, 100, 10000)), "--json"];
  crawlRunning = true;
  const child = spawn(crawler, args, { cwd: root, windowsHide: true, stdio: ["ignore", "pipe", "pipe"] });
  const stdout = [], stderr = [];
  let outputBytes = 0;
  const timer = setTimeout(() => child.kill(), 180_000);
  child.stdout.on("data", chunk => { outputBytes += chunk.length; if (outputBytes <= 10_000_000) stdout.push(chunk); else child.kill(); });
  child.stderr.on("data", chunk => stderr.push(chunk));
  child.on("error", error => { clearTimeout(timer); crawlRunning = false; json(res, 500, { error: String(error.message || error) }); });
  child.on("close", code => {
    clearTimeout(timer); crawlRunning = false;
    if (res.writableEnded) return;
    const out = Buffer.concat(stdout).toString("utf8").trim();
    if (code !== 0) return json(res, 502, { error: Buffer.concat(stderr).toString("utf8").trim() || out || "抓取进程异常退出。" });
    try { json(res, 200, JSON.parse(out)); } catch { json(res, 502, { error: "爬虫返回了无法解析的结果。" }); }
  });
}

async function runBrowserCrawler(req, res) {
  if (!localOrigin(req)) return json(res, 403, { error: "拒绝非本地来源的抓取请求。" });
  if (crawlRunning) return json(res, 429, { error: "已有抓取任务正在运行，请稍候。" });
  let input;
  try { input = await readJson(req); } catch (error) { return json(res, 400, { error: String(error.message || error) }); }
  const url = typeof input.url === "string" ? input.url.trim() : "";
  const token = typeof input.productToken === "string" ? input.productToken.trim() : "MoonRobotsBot";
  if (!/^https?:\/\//i.test(url) || !/^[A-Za-z_-]+$/.test(token)) return json(res, 400, { error: "请输入 HTTP(S) URL 和有效的 Product Token。" });
  crawlRunning = true;
  try {
    const report = await browserCrawl({ ...input, url, productToken: token }, { root, crawler });
    json(res, 200, report);
  } catch (error) {
    json(res, 502, { error: String(error.message || error) });
  } finally { crawlRunning = false; }
}

async function startBrowserCrawl(req, res) {
  if (!localOrigin(req)) return json(res, 403, { error: "拒绝非本地来源的抓取请求。" });
  if (crawlRunning) return json(res, 429, { error: "已有抓取任务正在运行，请稍候。" });
  let input;
  try { input = await readJson(req); } catch (error) { return json(res, 400, { error: String(error.message || error) }); }
  const url = typeof input.url === "string" ? input.url.trim() : "";
  const token = typeof input.productToken === "string" ? input.productToken.trim() : "MoonRobotsBot";
  if (!/^https?:\/\//i.test(url) || !/^[A-Za-z_-]+$/.test(token)) return json(res, 400, { error: "请输入 HTTP(S) URL 和有效的 Product Token。" });
  const id = randomUUID();
  const job = { id, state: "running", created_at: Date.now(), updated_at: Date.now(), progress: { phase: "queued", message: "任务已创建", current_url: url, processed: 0, queued: 1, max_pages: boundedInt(input.maxPages, 10, 1, 30), elapsed_ms: 0, pages: [] }, report: null, error: null };
  crawlJobs.set(id, job); crawlRunning = true;
  json(res, 202, { job_id: id });
  browserCrawl({ ...input, url, productToken: token }, { root, crawler }, progress => {
    job.progress = { ...progress, pages: progress.pages.map(page => ({ ...page })) };
    job.updated_at = Date.now();
  }).then(report => { job.state = "complete"; job.report = report; job.updated_at = Date.now(); })
    .catch(error => { job.state = "failed"; job.error = String(error.message || error); job.updated_at = Date.now(); })
    .finally(() => { crawlRunning = false; setTimeout(() => crawlJobs.delete(id), 30 * 60_000); });
}

const server = http.createServer(async (req, res) => {
  if (req.method === "POST" && req.url === "/api/crawl") return runCrawler(req, res);
  if (req.method === "POST" && req.url === "/api/browser-crawl") return runBrowserCrawler(req, res);
  if (req.method === "POST" && req.url === "/api/browser-crawl/start") return startBrowserCrawl(req, res);
  if (req.method === "GET" && req.url?.startsWith("/api/crawl-jobs/")) {
    if (!localOrigin(req)) return json(res, 403, { error: "拒绝非本地来源的请求。" });
    const job = crawlJobs.get(req.url.slice("/api/crawl-jobs/".length));
    return job ? json(res, 200, job) : json(res, 404, { error: "抓取任务不存在或已过期。" });
  }
  if (req.method !== "GET" && req.method !== "HEAD") return json(res, 405, { error: "Method not allowed" });
  const rawPath = decodeURIComponent((req.url || "/").split("?")[0]);
  const relative = rawPath === "/" ? "web/index.html" : rawPath.replace(/^\/+/, "");
  const file = resolve(root, normalize(relative));
  if (!file.startsWith(root + "\\") || !existsSync(file)) return json(res, 404, { error: "Not found" });
  const headers = { "Content-Type": mime.get(extname(file).toLowerCase()) || "application/octet-stream", "X-Content-Type-Options": "nosniff" };
  res.writeHead(200, headers);
  if (req.method === "HEAD") return res.end();
  createReadStream(file).pipe(res);
});

server.listen(port, "127.0.0.1", () => {
  console.log(`MoonRobots Studio: http://127.0.0.1:${port}/web/index.html`);
  console.log("按 Ctrl+C 停止本地服务。");
});
