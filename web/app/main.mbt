///|
extern "js" fn mount_studio(
  analyze : (String, String, String, String) -> String,
) -> Unit =
  #| (analyze) => {
  #|   const byId = (id) => document.getElementById(id);
  #|   const source = byId("source");
  #|   const agent = byId("agent");
  #|   const uri = byId("uri");
  #|   const batch = byId("batch-input");
  #|   const status = byId("runtime-status");
  #|   const languageSelect = byId("language-select");
  #|   const translations = {
  #|     "zh-CN": {
  #|       brandSubtitle: "RFC 9309 分析工作台", exportReport: "导出报告", documentation: "使用文档",
  #|       eyebrow: "网站抓取与访问策略监控", heroTitle: "MoonRobots<br /><em>网站抓取与策略监控中心</em>",
  #|       heroDescription: "实时编辑策略、运行受限的真实网站爬虫，并检查每一次 RFC 9309 匹配决策。", policyHealth: "策略健康度", crawlHealth: "抓取健康度",
  #|       policySource: "策略源码", editorTitle: "robots.txt 编辑器", copy: "复制", format: "格式化", examples: "示例",
  #|       balanced: "均衡策略", risky: "风险策略", multipleAgents: "多爬虫策略", liveSimulator: "实时模拟器",
  #|       testOneRequest: "测试单个请求", productToken: "爬虫 Product Token", urlOrPath: "URL 或路径",
  #|       accessDecision: "访问决策", decisionTrace: "决策追踪", candidateRules: "候选规则", specificity: "匹配长度",
  #|       deepInspection: "深度检查", understandPolicy: "理解完整策略", findings: "分析结果", ruleGroups: "规则组",
  #|       batchSimulator: "批量模拟", optimizer: "源码保留型优化器", urlsOrPaths: "URL 或路径", onePerLine: "每行一个",
  #|       generatedCases: "自动生成的边界用例", clickToAdd: "点击添加", simulationResults: "模拟结果",
  #|       rfcAware: "遵循 RFC", rfcAwareText: "支持最长匹配、Allow 平局、通配规则组和百分号编码。",
  #|       explainable: "可解释", explainableText: "每个决策都保留候选规则、匹配长度和源码行。",
  #|       localFirst: "本地优先", localFirstText: "策略留在浏览器中，无需上传到远程服务器。",
  #|       moonbitPowered: "MoonBit 驱动", moonbitPoweredText: "同一套经过测试的引擎运行于 CLI、JS、Wasm 和 Native。",
  #|       builtWith: "使用 MoonBit 构建 · RFC 9309", groups: "规则组", agents: "爬虫", rules: "规则",
  #|       allow: "允许", disallow: "禁止", findingCount: "问题", allowed: "允许访问", disallowed: "禁止访问",
  #|       exactGroups: "精确规则组", wildcardGroup: "通配规则组", noGroup: "无适用规则组", defaultAllow: "默认允许",
  #|       engineReady: "MoonBit 引擎已就绪", analyzing: "分析中…", analysisFailed: "分析失败",
  #|       noRules: "此爬虫没有需要比较的规则。", cleanPolicy: "策略检查通过", noFindings: "没有发现解析或质量问题。",
  #|       suggestion: "建议", line: "行", group: "规则组", noEffectiveRules: "没有有效规则",
  #|       noValidGroups: "没有解析到有效的 User-agent 规则组。", addBatch: "每行添加一个 URL 或路径以运行批量模拟。",
  #|       result: "结果", matchedRule: "命中规则", safe: "安全", review: "需复核", noEdits: "暂无修改建议",
  #|       applySafe: "应用安全修复", noSafeFixes: "没有安全修复", ruleCoverage: "规则覆盖率", copied: "已复制",
  #|       selected: "最终命中", matched: "已匹配", "not-matched": "未匹配", "less-specific": "匹配较短",
  #|       "lost-allow-tie": "Allow 平局胜出", syntax: "语法", correctness: "正确性", redundancy: "冗余",
  #|       maintainability: "可维护性", security: "风险", defaultReason: "没有适用的路径规则，按照 RFC 默认允许访问。",
  #|       robotsReason: "RFC 9309 明确允许访问 robots.txt 文件本身。", matchedAt: "命中", specificityWord: "匹配长度",
  #|       realCrawler: "真实网站爬虫", crawlTitle: "从一个网址开始，实际抓取并验证策略", crawlReady: "等待开始",
  #|       startUrl: "起始 URL", crawlerToken: "Product Token", maxPages: "最多页面", maxDepth: "最大深度",
  #|       requestDelay: "请求间隔 (ms)", startCrawl: "开始真实抓取", crawling: "正在真实抓取…",
  #|       crawlMode: "抓取模式", browserMode: "浏览器渲染", httpMode: "快速 HTTP", testSites: "可用测试站",
  #|       crawlSafety: "浏览器模式使用 Edge 执行 JavaScript、处理重定向并保存截图；两种模式都遵守 robots.txt，并阻止本机、内网和特殊用途地址。",
  #|       crawlDone: "抓取完成", fetchedPages: "成功", blockedPages: "阻止", failedPages: "失败", skippedPages: "跳过",
  #|       elapsed: "已用时", estimated: "预计剩余", policyAssessment: "抓取后策略评估", improvement: "改进建议",
  #|       Fetched: "已抓取", BlockedByRobots: "robots.txt 阻止", SkippedNonHtml: "非 HTML", HttpError: "HTTP 错误", NetworkError: "网络错误", TooLarge: "响应过大",
  #|     },
  #|     en: {
  #|       brandSubtitle: "RFC 9309 Studio", exportReport: "Export report", documentation: "Documentation",
  #|       eyebrow: "Website crawling and access-policy monitoring", heroTitle: "MoonRobots<br /><em>Crawling & Policy Operations Center</em>",
  #|       heroDescription: "Edit policies, run a bounded live-site crawler, and inspect every RFC 9309 decision.", policyHealth: "Policy health", crawlHealth: "Crawl health",
  #|       policySource: "Policy source", editorTitle: "robots.txt editor", copy: "Copy", format: "Format", examples: "Examples",
  #|       balanced: "Balanced", risky: "Risky policy", multipleAgents: "Multiple agents", liveSimulator: "Live simulator",
  #|       testOneRequest: "Test one request", productToken: "Product token", urlOrPath: "URL or path", accessDecision: "Access decision",
  #|       decisionTrace: "Decision trace", candidateRules: "Candidate rules", specificity: "specificity", deepInspection: "Deep inspection",
  #|       understandPolicy: "Understand the whole policy", findings: "Findings", ruleGroups: "Rule groups", batchSimulator: "Batch simulator",
  #|       optimizer: "Source-preserving optimizer", urlsOrPaths: "URLs or paths", onePerLine: "one per line",
  #|       generatedCases: "Generated boundary cases", clickToAdd: "click to add", simulationResults: "Simulation results",
  #|       rfcAware: "RFC-aware", rfcAwareText: "Longest match, Allow ties, wildcard groups and percent encoding.",
  #|       explainable: "Explainable", explainableText: "Every decision retains candidate rules, scores and source lines.",
  #|       localFirst: "Local-first", localFirstText: "Your policy stays in the browser. No server or upload is required.",
  #|       moonbitPowered: "MoonBit-powered", moonbitPoweredText: "The same tested engine runs in CLI, JS, Wasm and native targets.",
  #|       builtWith: "Built with MoonBit · RFC 9309", groups: "Groups", agents: "Agents", rules: "Rules", allow: "Allow",
  #|       disallow: "Disallow", findingCount: "Findings", allowed: "Allowed", disallowed: "Disallowed", exactGroups: "exact group(s)",
  #|       wildcardGroup: "Wildcard group", noGroup: "No applicable group", defaultAllow: "Default allow", engineReady: "MoonBit engine ready",
  #|       analyzing: "Analyzing…", analysisFailed: "Analysis failed", noRules: "No rules were considered for this crawler.",
  #|       cleanPolicy: "Clean policy", noFindings: "No parser or quality findings.", suggestion: "Suggestion", line: "line", group: "Group",
  #|       noEffectiveRules: "No effective rules", noValidGroups: "No valid User-agent groups were parsed.",
  #|       addBatch: "Add one URL or path per line to run a batch simulation.", result: "Result", matchedRule: "Matched rule",
  #|       safe: "safe", review: "review", noEdits: "No edits suggested", applySafe: "Apply safe fixes", noSafeFixes: "No safe fixes",
  #|       ruleCoverage: "rule coverage", copied: "Copied", selected: "selected", matched: "matched", "not-matched": "not matched",
  #|       "less-specific": "less specific", "lost-allow-tie": "lost Allow tie", syntax: "syntax", correctness: "correctness",
  #|       redundancy: "redundancy", maintainability: "maintainability", security: "security",
  #|       defaultReason: "No applicable path rule matched; default allow applies", robotsReason: "RFC 9309 implicitly allows the robots.txt resource",
  #|       matchedAt: "Matched", specificityWord: "specificity",
  #|       realCrawler: "Real website crawler", crawlTitle: "Fetch a live site and verify its policy", crawlReady: "Ready",
  #|       startUrl: "Start URL", crawlerToken: "Product token", maxPages: "Max pages", maxDepth: "Max depth",
  #|       requestDelay: "Request delay (ms)", startCrawl: "Start real crawl", crawling: "Crawling live site…",
  #|       crawlMode: "Crawl mode", browserMode: "Browser rendering", httpMode: "Fast HTTP", testSites: "Test sites",
  #|       crawlSafety: "Browser mode runs JavaScript in Edge, follows redirects, and saves screenshots. Both modes respect robots.txt and block local/private addresses.",
  #|       crawlDone: "Crawl complete", fetchedPages: "fetched", blockedPages: "blocked", failedPages: "failed", skippedPages: "skipped",
  #|       elapsed: "Elapsed", estimated: "Estimated remaining", policyAssessment: "Post-crawl policy assessment", improvement: "Recommendation",
  #|       Fetched: "Fetched", BlockedByRobots: "Blocked by robots.txt", SkippedNonHtml: "Non-HTML", HttpError: "HTTP error", NetworkError: "Network error", TooLarge: "Too large",
  #|     }
  #|   };
  #|   let currentLang = localStorage.getItem("moonrobots-language") || "zh-CN";
  #|   if (!translations[currentLang]) currentLang = "zh-CN";
  #|   const t = (key) => translations[currentLang][key] ?? translations.en[key] ?? key;
  #|   const findingZh = {
  #|     "missing-colon": ["记录缺少冒号", "该行不是有效的“字段: 值”记录，解析时已忽略。", "补充冒号和值，或者删除该行。"],
  #|     "invalid-user-agent": ["爬虫标识无效", "User-agent 必须是有效且非空的 product token。", "仅使用字母、下划线或连字符。"],
  #|     "orphan-rule": ["规则缺少 User-agent", "Allow/Disallow 出现在任何 User-agent 记录之前。", "在规则前添加 User-agent。"],
  #|     "unknown-record": ["未知扩展字段", "该字段不属于 MoonRobots 支持的 RFC 9309 核心记录。", "确认它是否为必要的厂商扩展。"],
  #|     "empty-group": ["规则组没有有效规则", "该组选择了爬虫，但没有有效的 Allow 或 Disallow。", "添加规则，或说明此空组用于覆盖通配限制。"],
  #|     "split-agent-group": ["相同爬虫规则组被拆分", "RFC 会合并相同 product token 的规则，但拆分会增加维护难度。", "将这些记录整理到同一个相邻规则组中。"],
  #|     "duplicate-rule": ["发现重复路径规则", "同一有效规则组中重复的规则不会改变决策。", "保留其中一条即可。"],
  #|     "allow-disallow-tie": ["Allow 与 Disallow 使用相同模式", "两条规则匹配长度相同，RFC 9309 将优先选择 Allow。", "删除无效的 Disallow，或明确更具体的边界。"],
  #|     "non-root-pattern": ["路径模式没有从根目录开始", "规范化请求路径以 / 开始，这条规则很可能无法命中。", "如果它表示 URL 路径，请添加 / 前缀。"],
  #|     "misplaced-anchor": ["结束锚点位置错误", "只有最后一个字符为 $ 时才表示路径结尾。", "把 $ 移到末尾，或对字面量美元符号进行编码。"],
  #|     "site-wide-disallow": ["规则几乎禁止整个网站", "宽泛的 Disallow 可能让公开页面无法被搜索或归档。", "确认这是有意设置，并为需要公开的路径添加精确 Allow。"],
  #|     "long-pattern": ["路径模式异常长", "过长模式难以审查，也可能误粘贴了完整 URL。", "使用能够表达边界的最短路径模式。"],
  #|     "large-agent-group": ["规则组包含大量爬虫标识", "大型规则组容易编辑出错，也不便于审查。", "记录这些爬虫共享完全相同策略的原因。"],
  #|     "no-wildcard-group": ["缺少通配规则组", "未列出的爬虫会因为没有 User-agent: * 而默认允许。", "如需统一约束未知爬虫，请添加通配规则组。"],
  #|     "relative-sitemap": ["Sitemap 不是绝对 URL", "使用绝对 HTTP(S) URL 能获得更可靠的爬虫支持。", "改用完整的 https:// URL。"],
  #|     "duplicate-sitemap": ["重复的 Sitemap", "同一个 Sitemap URL 被声明了多次。", "保留一条 Sitemap 记录即可。"],
  #|   };
  #|   function applyLanguage() {
  #|     document.documentElement.lang = currentLang === "zh-CN" ? "zh-CN" : "en";
  #|     languageSelect.value = currentLang;
  #|     document.querySelectorAll("[data-i18n]").forEach((node) => node.textContent = t(node.dataset.i18n));
  #|     document.querySelectorAll("[data-i18n-html]").forEach((node) => node.innerHTML = t(node.dataset.i18nHtml));
  #|     document.title = currentLang === "zh-CN" ? "MoonRobots Studio｜可视化 robots.txt 分析器" : "MoonRobots Studio";
  #|   }
  #|   const escapeHtml = (value) => String(value ?? "")
  #|     .replaceAll("&", "&amp;")
  #|     .replaceAll("<", "&lt;")
  #|     .replaceAll(">", "&gt;")
  #|     .replaceAll('"', "&quot;")
  #|     .replaceAll("'", "&#039;");
  #|   const icon = (allowed) => allowed ? "✓" : "×";
  #|   const label = (allowed) => allowed ? t("allowed") : t("disallowed");
  #|   const empty = (text) => `<div class="empty-state">${escapeHtml(text)}</div>`;
  #|   let lastSnapshot = null;
  #|   let timer = 0;
  #|   function setHealthScore(score, grade, label) {
  #|     byId("score-value").textContent = score;
  #|     byId("score-grade").textContent = grade;
  #|     byId("policy-health-label").textContent = label;
  #|     const circumference = 2 * Math.PI * 52;
  #|     byId("score-ring").style.strokeDashoffset = String(circumference * (1 - score / 100));
  #|   }
  #|
  #|   function renderStats(data) {
  #|     const values = [
  #|       [t("groups"), data.stats.groups],
  #|       [t("agents"), data.stats.agents],
  #|       [t("rules"), data.stats.rules],
  #|       [t("allow"), data.stats.allows],
  #|       [t("disallow"), data.stats.disallows],
  #|       [t("findingCount"), data.stats.findings],
  #|     ];
  #|     byId("stats").innerHTML = values.map(([name, value]) =>
  #|       `<div class="stat"><span>${name}</span><strong>${value}</strong></div>`
  #|     ).join("");
  #|     setHealthScore(data.score, data.grade, t("policyHealth"));
  #|   }
  #|
  #|   function renderDecision(data) {
  #|     const decision = data.decision;
  #|     const card = byId("decision-card");
  #|     card.className = `decision-card ${decision.allowed ? "allowed" : "denied"}`;
  #|     byId("decision-icon").textContent = icon(decision.allowed);
  #|     byId("decision-label").textContent = label(decision.allowed);
  #|     byId("decision-path").textContent = decision.path;
  #|     const reason = decision.matched
  #|       ? `${t("matchedAt")}: ${decision.matched.kind === "allow" ? t("allow") : t("disallow")}: ${decision.matched.pattern} · ${t("line")} ${decision.matched.line} · ${t("specificityWord")} ${decision.matched.specificity}`
  #|       : decision.path === "/robots.txt"
  #|         ? t("robotsReason")
  #|         : t("defaultReason");
  #|     byId("decision-reason").textContent = reason;
  #|     byId("group-mode").textContent = data.trace.exactGroupCount > 0
  #|       ? `${data.trace.exactGroupCount} ${t("exactGroups")}`
  #|       : data.trace.wildcardGroupCount > 0
  #|         ? t("wildcardGroup")
  #|         : t("noGroup");
  #|   }
  #|
  #|   function renderCandidates(data) {
  #|     const target = byId("candidate-list");
  #|     if (!data.trace.candidates.length) {
  #|       target.innerHTML = empty(t("noRules"));
  #|       return;
  #|     }
  #|     target.innerHTML = data.trace.candidates.map((item) => `
  #|       <button class="candidate ${item.status}" data-line="${item.line}">
  #|         <span class="rule-kind ${item.kind}">${escapeHtml(item.kind === "allow" ? t("allow") : t("disallow"))}</span>
  #|         <code>${escapeHtml(item.pattern)}</code>
  #|         <span class="specificity">${item.specificity}</span>
  #|         <span class="candidate-status">${escapeHtml(t(item.status))}</span>
  #|         <span class="line-ref">L${item.line}</span>
  #|       </button>`).join("");
  #|     target.querySelectorAll("[data-line]").forEach((button) => {
  #|       button.addEventListener("click", () => focusLine(Number(button.dataset.line)));
  #|     });
  #|   }
  #|
  #|   function renderFindings(data) {
  #|     const target = byId("finding-list");
  #|     byId("finding-count").textContent = data.findings.length;
  #|     if (!data.findings.length) {
  #|       target.innerHTML = `<div class="success-state"><span>✓</span><div><strong>${t("cleanPolicy")}</strong><p>${t("noFindings")}</p></div></div>`;
  #|       return;
  #|     }
  #|     target.innerHTML = data.findings.map((item) => {
  #|       const zh = currentLang === "zh-CN" ? findingZh[item.code] : null;
  #|       const title = zh ? zh[0] : item.title;
  #|       const message = zh ? zh[1] : item.message;
  #|       const suggestion = zh ? zh[2] : item.suggestion;
  #|       return `
  #|       <article class="finding ${item.severity}">
  #|         <div class="finding-top">
  #|           <span class="finding-category">${escapeHtml(t(item.category))}</span>
  #|           <code>${escapeHtml(item.code)}</code>
  #|           ${item.lines.length ? `<button class="line-button" data-line="${item.lines[0]}">${t("line")} ${item.lines.join(", ")}</button>` : ""}
  #|         </div>
  #|         <h4>${escapeHtml(title)}</h4>
  #|         <p>${escapeHtml(message)}</p>
  #|         <div class="suggestion"><span>${t("suggestion")}</span>${escapeHtml(suggestion)}</div>
  #|       </article>`;
  #|     }).join("");
  #|     target.querySelectorAll("[data-line]").forEach((button) => {
  #|       button.addEventListener("click", () => focusLine(Number(button.dataset.line)));
  #|     });
  #|   }
  #|
  #|   function renderFixes(data) {
  #|     const plan = data.fixPlan;
  #|     const summary = byId("fix-summary");
  #|     const button = byId("apply-safe-button");
  #|     summary.textContent = `${plan.safeCount} ${t("safe")} · ${plan.reviewCount} ${t("review")}`;
  #|     button.disabled = plan.safeCount === 0;
  #|     button.textContent = plan.safeCount > 0 ? `${t("applySafe")} (${plan.safeCount})` : t("noSafeFixes");
  #|   }
  #|
  #|   function renderGroups(data) {
  #|     const target = byId("group-list");
  #|     if (!data.groups.length) {
  #|       target.innerHTML = empty(t("noValidGroups"));
  #|       return;
  #|     }
  #|     target.innerHTML = data.groups.map((group, index) => `
  #|       <article class="group-card">
  #|         <header><span>${t("group")} ${index + 1}</span><button data-line="${group.line}">${t("line")} ${group.line}</button></header>
  #|         <div class="agent-chips">${group.agents.map((name) => `<span>${escapeHtml(name)}</span>`).join("")}</div>
  #|         <div class="group-rules">${group.rules.length ? group.rules.map((rule) => `
  #|           <div><span class="rule-dot ${rule.kind}"></span><b>${escapeHtml(rule.kind === "allow" ? t("allow") : t("disallow"))}</b><code>${escapeHtml(rule.pattern)}</code><button data-line="${rule.line}">L${rule.line}</button></div>`).join("") : `<em>${t("noEffectiveRules")}</em>`}</div>
  #|       </article>`).join("");
  #|     target.querySelectorAll("[data-line]").forEach((button) => {
  #|       button.addEventListener("click", () => focusLine(Number(button.dataset.line)));
  #|     });
  #|   }
  #|
  #|   function renderBatch(data) {
  #|     const target = byId("batch-results");
  #|     byId("batch-summary").textContent =
  #|       `${data.batch.allowedCount} ${t("allowed")} · ${data.batch.disallowedCount} ${t("disallowed")} · ${data.coverage.percent}% ${t("ruleCoverage")}`;
  #|     if (!data.batch.results.length) {
  #|       target.innerHTML = empty(t("addBatch"));
  #|       return;
  #|     }
  #|     target.innerHTML = `
  #|       <div class="table-head"><span>${t("result")}</span><span>${t("urlOrPath")}</span><span>${t("matchedRule")}</span></div>
  #|       ${data.batch.results.map((item) => `
  #|         <div class="table-row ${item.allowed ? "allowed" : "denied"}">
  #|           <span class="result-pill">${icon(item.allowed)} ${label(item.allowed)}</span>
  #|           <code title="${escapeHtml(item.uri)}">${escapeHtml(item.uri)}</code>
  #|           <span>${item.matchedPattern ? `<code>${escapeHtml(item.matchedPattern)}</code> <small>L${item.matchedLine}</small>` : t("defaultAllow")}</span>
  #|         </div>`).join("")}`;
  #|   }
  #|
  #|   function renderSuggestions(data) {
  #|     byId("suggested-paths").innerHTML = data.suggestedPaths.map((path) =>
  #|       `<button data-path="${escapeHtml(path)}"><code>${escapeHtml(path)}</code><span>＋</span></button>`
  #|     ).join("");
  #|     byId("suggested-paths").querySelectorAll("[data-path]").forEach((button) => {
  #|       button.addEventListener("click", () => {
  #|         const existing = batch.value.trim();
  #|         batch.value = existing ? `${existing}\n${button.dataset.path}` : button.dataset.path;
  #|         schedule();
  #|       });
  #|     });
  #|   }
  #|
  #|   function renderLineNumbers() {
  #|     const count = Math.max(1, source.value.split("\n").length);
  #|     byId("line-numbers").textContent = Array.from({length: count}, (_, i) => i + 1).join("\n");
  #|     byId("source-meta").textContent = `${count} lines · ${new Blob([source.value]).size} bytes`;
  #|   }
  #|
  #|   function focusLine(line) {
  #|     const lines = source.value.split("\n");
  #|     const start = lines.slice(0, Math.max(0, line - 1)).reduce((sum, item) => sum + item.length + 1, 0);
  #|     const end = start + (lines[line - 1] || "").length;
  #|     source.focus();
  #|     source.setSelectionRange(start, end);
  #|     const lineHeight = Number.parseFloat(getComputedStyle(source).lineHeight) || 22;
  #|     source.scrollTop = Math.max(0, (line - 3) * lineHeight);
  #|     byId("line-numbers").scrollTop = source.scrollTop;
  #|   }
  #|
  #|   function run() {
  #|     try {
  #|       const raw = analyze(source.value, agent.value.trim() || "*", uri.value.trim() || "/", batch.value);
  #|       const data = JSON.parse(raw);
  #|       lastSnapshot = data;
  #|       renderStats(data);
  #|       renderDecision(data);
  #|       renderCandidates(data);
  #|       renderFindings(data);
  #|       renderFixes(data);
  #|       renderGroups(data);
  #|       renderBatch(data);
  #|       renderSuggestions(data);
  #|       renderLineNumbers();
  #|       status.textContent = t("engineReady");
  #|       status.className = "runtime-status ready";
  #|     } catch (error) {
  #|       console.error(error);
  #|       status.textContent = `${t("analysisFailed")}: ${error.message}`;
  #|       status.className = "runtime-status error";
  #|     }
  #|   }
  #|
  #|   function schedule() {
  #|     clearTimeout(timer);
  #|     status.textContent = t("analyzing");
  #|     status.className = "runtime-status busy";
  #|     timer = setTimeout(run, 90);
  #|   }
  #|
  #|   function download(name, content, type) {
  #|     const link = document.createElement("a");
  #|     link.href = URL.createObjectURL(new Blob([content], {type}));
  #|     link.download = name;
  #|     link.click();
  #|     setTimeout(() => URL.revokeObjectURL(link.href), 1000);
  #|   }
  #|
  #|   [source, agent, uri, batch].forEach((element) => element.addEventListener("input", schedule));
  #|   source.addEventListener("scroll", () => byId("line-numbers").scrollTop = source.scrollTop);
  #|   byId("format-button").addEventListener("click", () => {
  #|     if (lastSnapshot) { source.value = lastSnapshot.formatted.trimEnd(); schedule(); }
  #|   });
  #|   byId("apply-safe-button").addEventListener("click", () => {
  #|     if (lastSnapshot && lastSnapshot.fixPlan.safeCount > 0) {
  #|       source.value = lastSnapshot.fixPlan.safeSource;
  #|       schedule();
  #|     }
  #|   });
  #|   byId("copy-button").addEventListener("click", async () => {
  #|     await navigator.clipboard.writeText(source.value);
  #|     byId("copy-button").textContent = t("copied");
  #|     setTimeout(() => byId("copy-button").textContent = t("copy"), 1200);
  #|   });
  #|   byId("export-button").addEventListener("click", () => {
  #|     if (lastSnapshot) download("moonrobots-analysis.json", JSON.stringify(lastSnapshot, null, 2), "application/json");
  #|   });
  #|   byId("theme-button").addEventListener("click", () => {
  #|     document.documentElement.classList.toggle("light");
  #|     localStorage.setItem("moonrobots-theme", document.documentElement.classList.contains("light") ? "light" : "dark");
  #|   });
  #|   const formatDuration = ms => { const seconds = Math.max(0, Math.round(ms / 1000)); return seconds < 60 ? `${seconds}s` : `${Math.floor(seconds / 60)}m ${seconds % 60}s`; };
  #|   function renderLivePages(pages) {
  #|     byId("crawl-results").innerHTML = pages.map(page => `<div class="crawl-page"><b class="${page.status}">${escapeHtml(t(page.status))}</b><code title="${escapeHtml(page.url || page.requested_url)}">${escapeHtml(page.url || page.requested_url)}</code><small>${page.http_status ?? "—"} · ${page.bytes || 0} B${page.title ? ` · ${escapeHtml(page.title)}` : ""}</small><div class="crawl-page-detail">${page.final_url && page.final_url !== page.url ? `<span>最终 URL：${escapeHtml(page.final_url)}</span>` : ""}${page.matched_rule ? `<span>命中规则：${escapeHtml(page.matched_rule)}</span>` : ""}${page.message ? `<span>${escapeHtml(page.message)}</span>` : ""}${page.protocol ? `<span>${escapeHtml(page.protocol)}</span>` : ""}${page.screenshot ? `<a href="${escapeHtml(page.screenshot)}" target="_blank">查看截图</a>` : ""}</div></div>`).join("");
  #|   }
  #|   function renderProgress(progress) {
  #|     const box = byId("crawl-progress"); box.hidden = false;
  #|     const known = Math.max(1, Math.min(progress.max_pages, progress.processed + progress.queued));
  #|     const percent = Math.min(100, Math.round(progress.processed / known * 100));
  #|     const remainingPages = Math.min(progress.queued, Math.max(0, progress.max_pages - progress.processed));
  #|     const remaining = progress.processed ? progress.elapsed_ms / progress.processed * remainingPages : null;
  #|     byId("crawl-progress-bar").style.width = `${percent}%`;
  #|     byId("crawl-phase").textContent = `${progress.message} · ${progress.processed}/${known}`;
  #|     byId("crawl-eta").textContent = `${t("elapsed")} ${formatDuration(progress.elapsed_ms)} · ${t("estimated")} ${remaining == null ? "计算中" : formatDuration(remaining)}`;
  #|     byId("crawl-current-url").textContent = progress.current_url || "";
  #|     renderLivePages(progress.pages || []);
  #|   }
  #|   function renderAssessment(assessment) {
  #|     byId("crawl-assessment").innerHTML = assessment ? `<div class="assessment-head"><b class="assessment-score">${assessment.score}</b><div><strong>${t("policyAssessment")} · ${escapeHtml(assessment.grade)}</strong><p>${assessment.findings.length} 项结论</p></div></div>` + assessment.findings.map(item => `<div class="assessment-item ${item.severity}"><strong>${escapeHtml(item.title)}</strong><p>${escapeHtml(item.detail)}</p><small>${t("improvement")}：${escapeHtml(item.suggestion)}</small></div>`).join("") : "";
  #|     if (assessment) setHealthScore(assessment.score, assessment.grade, t("crawlHealth"));
  #|   }
  #|   byId("crawl-button").addEventListener("click", async () => {
  #|     const button = byId("crawl-button");
  #|     const crawlStatus = byId("crawl-status");
  #|     const results = byId("crawl-results");
  #|     button.disabled = true;
  #|     crawlStatus.textContent = t("crawling");
  #|     crawlStatus.className = "runtime-status busy";
  #|     results.innerHTML = "";
  #|     byId("crawl-assessment").innerHTML = "";
  #|     try {
  #|       const browserMode = byId("crawl-mode").value === "browser";
  #|       const endpoint = browserMode ? "/api/browser-crawl/start" : "/api/crawl";
  #|       const response = await fetch(endpoint, { method: "POST", headers: {"Content-Type": "application/json"}, body: JSON.stringify({
  #|         url: byId("crawl-url").value, productToken: byId("crawl-token").value,
  #|         maxPages: Number(byId("crawl-pages").value), maxDepth: Number(byId("crawl-depth").value), delayMs: Number(byId("crawl-delay").value),
  #|       })});
  #|       let report = await response.json();
  #|       if (!response.ok) throw new Error(report.error || `HTTP ${response.status}`);
  #|       if (browserMode) {
  #|         while (true) {
  #|           await new Promise(resolve => setTimeout(resolve, 450));
  #|           const jobResponse = await fetch(`/api/crawl-jobs/${report.job_id}`);
  #|           const job = await jobResponse.json();
  #|           if (!jobResponse.ok) throw new Error(job.error || `HTTP ${jobResponse.status}`);
  #|           renderProgress(job.progress);
  #|           if (job.state === "failed") throw new Error(job.error);
  #|           if (job.state === "complete") { report = job.report; break; }
  #|         }
  #|       }
  #|       results.innerHTML = `<div class="crawl-summary"><span>${report.engine ? escapeHtml(report.engine) : "MoonBit HTTP"}</span><span>${t("fetchedPages")}: <b>${report.fetched_count}</b></span><span>${t("blockedPages")}: <b>${report.blocked_count}</b></span><span>${t("failedPages")}: <b>${report.failed_count}</b></span><span>${t("skippedPages")}: <b>${report.skipped_count}</b></span><span>${escapeHtml(report.stopped_reason)}</span></div>` + report.pages.map(page => `<div class="crawl-page"><b class="${page.status}">${escapeHtml(t(page.status))}</b><code title="${escapeHtml(page.url)}">${escapeHtml(page.url)}</code><small>${page.http_status ?? "—"} · ${page.bytes} B${page.title ? ` · ${escapeHtml(page.title)}` : ""}</small><div class="crawl-page-detail">${page.final_url && page.final_url !== page.url ? `<span>最终 URL：${escapeHtml(page.final_url)}</span>` : ""}${page.matched_rule ? `<span>命中规则：${escapeHtml(page.matched_rule)}</span>` : ""}${page.message ? `<span>${escapeHtml(page.message)}</span>` : ""}${page.protocol ? `<span>${escapeHtml(page.protocol)}</span>` : ""}${page.screenshot ? `<a href="${escapeHtml(page.screenshot)}" target="_blank">查看截图</a>` : ""}</div></div>`).join("");
  #|       renderAssessment(report.assessment);
  #|       byId("crawl-progress-bar").style.width = "100%";
  #|       crawlStatus.textContent = t("crawlDone");
  #|       crawlStatus.className = "runtime-status ready";
  #|     } catch (error) {
  #|       crawlStatus.textContent = `${t("analysisFailed")}: ${error.message}`;
  #|       crawlStatus.className = "runtime-status error";
  #|       results.textContent = error.message;
  #|     } finally { button.disabled = false; }
  #|   });
  #|   document.querySelectorAll("[data-crawl-example]").forEach(button => {
  #|     button.addEventListener("click", () => { byId("crawl-url").value = button.dataset.crawlExample; });
  #|   });
  #|   document.querySelectorAll("[data-example]").forEach((button) => {
  #|     button.addEventListener("click", () => {
  #|       const examples = {
  #|         balanced: `${currentLang === "zh-CN" ? "# 均衡的生产环境策略" : "# A balanced production policy"}\nUser-agent: *\nDisallow: /private/\nAllow: /private/public/\nDisallow: /*.pdf$\n\nUser-agent: ArchiveBot\nDisallow: /drafts/\n\nSitemap: https://example.com/sitemap.xml`,
  #|         risky: "User-agent: *\nDisallow: /\nDisallow: /\nAllow: /public\nAllow: /public\nSitemap: sitemap.xml\nUnknown-field: value",
  #|         agents: "User-agent: SearchBot\nDisallow: /account/\nAllow: /account/help/\n\nUser-agent: ArchiveBot\nDisallow: /drafts/\n\nUser-agent: *\nDisallow: /tmp/",
  #|       };
  #|       source.value = examples[button.dataset.example];
  #|       schedule();
  #|     });
  #|   });
  #|   document.querySelectorAll("[data-tab]").forEach((button) => {
  #|     button.addEventListener("click", () => {
  #|       document.querySelectorAll("[data-tab]").forEach((item) => item.classList.toggle("active", item === button));
  #|       document.querySelectorAll("[data-panel]").forEach((panel) => panel.classList.toggle("active", panel.dataset.panel === button.dataset.tab));
  #|     });
  #|   });
  #|   languageSelect.addEventListener("change", () => {
  #|     currentLang = languageSelect.value;
  #|     localStorage.setItem("moonrobots-language", currentLang);
  #|     applyLanguage();
  #|     run();
  #|   });
  #|   if (localStorage.getItem("moonrobots-theme") === "light") document.documentElement.classList.add("light");
  #|   applyLanguage();
  #|   run();
  #| }

///|
fn main {
  mount_studio(@robots.studio_snapshot)
}
