import { spawn } from "node:child_process";
import { promises as fs } from "node:fs";
import { createServer } from "node:net";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { lookup } from "node:dns/promises";

const edgeCandidates = [
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
  "C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe",
];

const sleep = ms => new Promise(resolvePromise => setTimeout(resolvePromise, ms));

export function privateAddress(address) {
  if (address.includes(":")) {
    const value = address.toLowerCase();
    return value === "::1" || value === "::" || value.startsWith("fc") || value.startsWith("fd") || value.startsWith("fe8") || value.startsWith("fe9") || value.startsWith("fea") || value.startsWith("feb") || value.startsWith("::ffff:127.") || value.startsWith("::ffff:10.") || value.startsWith("::ffff:192.168.");
  }
  const [a, b] = address.split(".").map(Number);
  return a === 0 || a === 10 || a === 127 || (a === 100 && b >= 64 && b <= 127) || (a === 169 && b === 254) || (a === 172 && b >= 16 && b <= 31) || (a === 192 && (b === 0 || b === 168)) || (a === 198 && (b === 18 || b === 19)) || a >= 224;
}

async function safeUrl(raw, origin) {
  let url;
  try { url = new URL(raw); } catch { return false; }
  if (!/^https?:$/.test(url.protocol) || url.username || url.password) return false;
  if (origin && url.origin !== origin) return false;
  const records = await lookup(url.hostname, { all: true, verbatim: true });
  return records.length > 0 && records.every(record => !privateAddress(record.address));
}

async function freePort() {
  return new Promise((resolvePromise, reject) => {
    const server = createServer();
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const port = server.address().port;
      server.close(() => resolvePromise(port));
    });
  });
}

class Cdp {
  constructor(socket) { this.socket = socket; this.nextId = 1; this.pending = new Map(); this.listeners = new Map();
    socket.addEventListener("message", event => {
      const message = JSON.parse(event.data);
      if (message.id) { const pending = this.pending.get(message.id); if (pending) { this.pending.delete(message.id); message.error ? pending.reject(new Error(message.error.message)) : pending.resolve(message.result); } }
      else if (message.method) for (const listener of this.listeners.get(message.method) || []) listener(message.params || {});
    });
  }
  send(method, params = {}) { const id = this.nextId++; return new Promise((resolvePromise, reject) => { this.pending.set(id, { resolve: resolvePromise, reject }); this.socket.send(JSON.stringify({ id, method, params })); }); }
  on(method, listener) { const list = this.listeners.get(method) || []; list.push(listener); this.listeners.set(method, list); }
  close() { this.socket.close(); }
}

async function connectBrowser(profile) {
  let edge = null;
  for (const candidate of edgeCandidates) { try { await fs.access(candidate); edge = candidate; break; } catch {} }
  if (!edge) throw new Error("没有找到 Microsoft Edge");
  const port = await freePort();
  const child = spawn(edge, ["--headless=new", `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`, "--no-first-run", "--disable-extensions", "--disable-background-networking", "--disable-sync", "--disable-default-apps", "--hide-scrollbars", "about:blank"], { windowsHide: true, stdio: "ignore" });
  let targets;
  for (let attempt = 0; attempt < 60; attempt++) {
    try { targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json(); if (targets.some(t => t.type === "page")) break; } catch {}
    await sleep(100);
  }
  const target = targets?.find(item => item.type === "page");
  if (!target) { child.kill(); throw new Error("Edge DevTools 启动超时"); }
  const socket = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((resolvePromise, reject) => { socket.addEventListener("open", resolvePromise, { once: true }); socket.addEventListener("error", reject, { once: true }); });
  return { child, cdp: new Cdp(socket) };
}

async function renderPage(cdp, url, options, screenshotPath) {
  let documentResponse = null;
  let inflight = 0;
  let lastActivity = Date.now();
  cdp.on("Network.requestWillBeSent", () => { inflight++; lastActivity = Date.now(); });
  cdp.on("Network.loadingFinished", () => { inflight = Math.max(0, inflight - 1); lastActivity = Date.now(); });
  cdp.on("Network.loadingFailed", () => { inflight = Math.max(0, inflight - 1); lastActivity = Date.now(); });
  cdp.on("Network.responseReceived", event => { if (event.type === "Document") documentResponse = event.response; });
  cdp.on("Fetch.requestPaused", async event => {
    try {
      const requestUrl = event.request.url;
      const scheme = new URL(requestUrl).protocol;
      const allowed = ["data:", "blob:"].includes(scheme) || await safeUrl(requestUrl, event.resourceType === "Document" ? options.origin : undefined);
      await cdp.send(allowed ? "Fetch.continueRequest" : "Fetch.failRequest", allowed ? { requestId: event.requestId } : { requestId: event.requestId, errorReason: "BlockedByClient" });
    } catch { await cdp.send("Fetch.failRequest", { requestId: event.requestId, errorReason: "BlockedByClient" }).catch(() => {}); }
  });
  await cdp.send("Page.enable"); await cdp.send("Runtime.enable"); await cdp.send("Network.enable");
  await cdp.send("Fetch.enable", { patterns: [{ urlPattern: "*", requestStage: "Request" }] });
  await cdp.send("Emulation.setDeviceMetricsOverride", { width: 1440, height: 1000, deviceScaleFactor: 1, mobile: false });
  await cdp.send("Network.setUserAgentOverride", { userAgent: options.userAgent });
  const navigation = await cdp.send("Page.navigate", { url });
  if (navigation.errorText) throw new Error(navigation.errorText);
  const deadline = Date.now() + options.timeoutMs;
  while (Date.now() < deadline) {
    if (inflight === 0 && Date.now() - lastActivity >= options.idleMs) break;
    await sleep(100);
  }
  await sleep(options.settleMs);
  const evaluate = expression => cdp.send("Runtime.evaluate", { expression, returnByValue: true, awaitPromise: true }).then(value => value.result.value);
  const finalUrl = await evaluate("location.href");
  const title = await evaluate("document.title || ''");
  const html = await evaluate("document.documentElement ? document.documentElement.outerHTML : ''");
  const description = await evaluate("document.querySelector('meta[name=description]')?.content || ''");
  const links = await evaluate("Array.from(document.querySelectorAll('a[href],area[href]'), a => a.href)");
  const screenshot = await cdp.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: false });
  await fs.writeFile(screenshotPath, Buffer.from(screenshot.data, "base64"));
  return { requested_url: url, final_url: finalUrl, title, description, html, links, status: Math.round(documentResponse?.status || 0), content_type: documentResponse?.mimeType || "text/html", protocol: documentResponse?.protocol || "", from_cache: Boolean(documentResponse?.fromDiskCache || documentResponse?.fromServiceWorker), screenshot: screenshotPath };
}

function runNativeGate(crawler, url, options) {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(crawler, [url, options.productToken, "1", "0", "100", "--json"], { windowsHide: true });
    const out = [], err = [];
    child.stdout.on("data", chunk => out.push(chunk)); child.stderr.on("data", chunk => err.push(chunk));
    child.on("error", reject);
    child.on("close", code => { if (code !== 0) reject(new Error(Buffer.concat(err).toString("utf8") || Buffer.concat(out).toString("utf8"))); else { try { resolvePromise(JSON.parse(Buffer.concat(out).toString("utf8"))); } catch (error) { reject(error); } } });
  });
}

export function assessReport(report) {
  let score = 100;
  const findings = [];
  const add = (severity, title, detail, suggestion, penalty) => { findings.push({ severity, title, detail, suggestion }); score -= penalty; };
  if (report.robots_status === 404) add("warning", "缺少明确的 robots.txt", "站点返回 404，当前等同于未设置抓取策略。", "为站点添加 /robots.txt，明确允许范围、禁止目录和 Sitemap。", 10);
  if (report.robots_status == null) add("error", "robots.txt 无法验证", "抓取器无法可靠取得站点策略。", "检查 DNS、TLS 证书、服务器可用性和 /robots.txt 响应。", 25);
  if (report.blocked_count > 0) add("info", "存在被策略阻止的页面", `${report.blocked_count} 个 URL 被 robots.txt 阻止。`, "核对这些路径是否确实不应被当前 Product Token 访问。", 0);
  if (report.failed_count > 0) add("error", "抓取存在失败页面", `${report.failed_count} 个 URL 出现 HTTP、网络或体积错误。`, "检查状态码、重定向链、证书和服务器稳定性。", Math.min(25, report.failed_count * 5));
  const untitled = report.pages.filter(page => page.status === "Fetched" && !page.title).length;
  if (untitled) add("warning", "部分页面缺少标题", `${untitled} 个成功页面没有可用的 title。`, "为每个可索引页面设置唯一且清晰的 <title>。", Math.min(15, untitled * 3));
  const missingDescription = report.pages.filter(page => page.status === "Fetched" && !page.description).length;
  if (missingDescription) add("warning", "部分页面缺少描述", `${missingDescription} 个页面未提供 meta description。`, "为核心页面添加简洁、唯一的 meta description。", Math.min(10, missingDescription * 2));
  const redirects = report.pages.filter(page => page.final_url && page.final_url !== page.url).length;
  if (redirects) add("info", "抓取路径包含重定向", `${redirects} 个 URL 发生重定向。`, "更新站内链接直接指向最终 URL，减少额外请求。", 2);
  if (!findings.length) findings.push({ severity: "success", title: "未发现明显策略问题", detail: "本次受限样本内，robots.txt、页面访问和基础元数据表现正常。", suggestion: "扩大抓取页数和深度后再次验证。" });
  score = Math.max(0, score);
  return { score, grade: score >= 90 ? "优秀" : score >= 75 ? "良好" : score >= 60 ? "需改进" : "高风险", findings };
}

export async function browserCrawl(input, paths, onProgress = () => {}) {
  const start = new URL(input.url); const origin = start.origin;
  if (!(await safeUrl(start.href))) throw new Error("起始地址无效，或解析到本机/内网/特殊用途地址");
  const options = { origin, productToken: input.productToken, maxPages: Math.min(30, Math.max(1, Number(input.maxPages) || 10)), maxDepth: Math.min(4, Math.max(0, Number(input.maxDepth) || 2)), delayMs: Math.min(10000, Math.max(200, Number(input.delayMs) || 700)), timeoutMs: 20000, idleMs: 600, settleMs: 400, userAgent: `${input.productToken} Mozilla/5.0 AppleWebKit/537.36 Chrome/120 Safari/537.36` };
  const session = `crawl-${Date.now()}`; const artifacts = join(paths.root, "_build", "crawl-artifacts", session); await fs.mkdir(artifacts, { recursive: true });
  const profile = await fs.mkdtemp(join(tmpdir(), "moonrobots-edge-"));
  const { child, cdp } = await connectBrowser(profile);
  const queue = [{ url: start.href, depth: 0 }], seen = new Set([start.href]), pages = [];
  const started = Date.now();
  onProgress({ phase: "browser-start", message: "正在启动隔离浏览器", current_url: start.href, processed: 0, queued: 1, max_pages: options.maxPages, elapsed_ms: 0, pages: [] });
  try {
    while (queue.length && pages.length < options.maxPages) {
      const task = queue.shift();
      onProgress({ phase: "robots", message: "正在获取并检查 robots.txt", current_url: task.url, processed: pages.length, queued: queue.length + 1, max_pages: options.maxPages, elapsed_ms: Date.now() - started, pages });
      const gate = await runNativeGate(paths.crawler, task.url, options);
      const gatePage = gate.pages[0];
      if (pages.length === 0) { input._robotsStatus = gate.robots_status; input._robotsUrl = gate.robots_url; }
      const redirect = gatePage?.http_status >= 300 && gatePage?.http_status < 400;
      if (!gatePage || (gatePage.status !== "Fetched" && !redirect)) {
        pages.push({ ...gatePage, requested_url: task.url, final_url: task.url, rendered: false, screenshot: "", description: "", protocol: "", from_cache: false });
        onProgress({ phase: "page-complete", message: gatePage?.message || "页面处理失败", current_url: task.url, processed: pages.length, queued: queue.length, max_pages: options.maxPages, elapsed_ms: Date.now() - started, pages });
        continue;
      }
      onProgress({ phase: "render", message: "Edge 正在加载并执行 JavaScript", current_url: task.url, processed: pages.length, queued: queue.length + 1, max_pages: options.maxPages, elapsed_ms: Date.now() - started, pages });
      const file = join(artifacts, `page-${String(pages.length + 1).padStart(3, "0")}.png`);
      const rendered = await renderPage(cdp, task.url, options, file);
      const publicScreenshot = "/" + rendered.screenshot.slice(paths.root.length + 1).replaceAll("\\", "/");
      pages.push({ ...gatePage, status: "Fetched", url: task.url, requested_url: task.url, final_url: rendered.final_url, rendered: true, screenshot: publicScreenshot, title: rendered.title, description: rendered.description, http_status: rendered.status || gatePage.http_status, content_type: rendered.content_type, protocol: rendered.protocol, from_cache: rendered.from_cache, bytes: Buffer.byteLength(rendered.html), outgoing_links: rendered.links.length, message: rendered.final_url !== task.url ? `浏览器渲染成功；重定向到 ${rendered.final_url}` : "浏览器渲染成功" });
      for (const raw of rendered.links) {
        try { const link = new URL(raw, rendered.final_url); link.hash = ""; if (link.origin !== origin || seen.has(link.href) || task.depth >= options.maxDepth || !(await safeUrl(link.href, origin))) continue; seen.add(link.href); queue.push({ url: link.href, depth: task.depth + 1 }); } catch {}
      }
      onProgress({ phase: "page-complete", message: `已完成：${rendered.title || task.url}`, current_url: task.url, processed: pages.length, queued: queue.length, max_pages: options.maxPages, elapsed_ms: Date.now() - started, pages });
      if (queue.length) await sleep(options.delayMs);
    }
  } finally {
    cdp.close();
    const exited = new Promise(resolvePromise => child.once("exit", resolvePromise));
    child.kill();
    await Promise.race([exited, sleep(3000)]);
    for (let attempt = 0; attempt < 5; attempt++) {
      try { await fs.rm(profile, { recursive: true, force: true, maxRetries: 2, retryDelay: 100 }); break; }
      catch { await sleep(300); }
    }
  }
  const report = { mode: "browser", engine: "Microsoft Edge (CDP)", start_url: start.href, origin, product_token: options.productToken, robots_url: input._robotsUrl, robots_status: input._robotsStatus, pages, fetched_count: pages.filter(p => p.status === "Fetched").length, blocked_count: pages.filter(p => p.status === "BlockedByRobots").length, failed_count: pages.filter(p => ["HttpError", "NetworkError", "TooLarge"].includes(p.status)).length, skipped_count: pages.filter(p => p.status === "SkippedNonHtml").length, stopped_reason: queue.length ? `达到最大页面数 ${options.maxPages}` : "队列已处理完毕", elapsed_ms: Date.now() - started, artifact_directory: "/" + artifacts.slice(paths.root.length + 1).replaceAll("\\", "/") };
  report.assessment = assessReport(report);
  return report;
}
