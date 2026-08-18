# MoonRobots 项目申报书

## 基本信息

项目名称：MoonRobots：网站抓取与访问策略监控中心  
参赛者：王孜心 
联系方式：电话18613379833邮箱18613379833@163.com
GitHub 仓库链接：https://github.com/tlhuecdkoyg/moonrobots.git  
项目方向：MoonBit Web 工具链 / robots.txt 策略分析 / 安全浏览器爬虫  
是否为移植项目：否，原创项目

## 项目简介

MoonRobots 是一个以 MoonBit 为主要实现语言的 RFC 9309 `robots.txt` 分析与网站抓取工作台。项目将可解释的访问策略引擎、MoonBit Native 异步 HTTP 爬虫和 Microsoft Edge 浏览器渲染结合起来，用于回答“指定 Product Token 能否访问某个 URL、命中了哪条规则、抓取结果是否健康以及应如何改进”。本项目属于 MoonBit Web 工具链和可视化运维基础设施，面向站点管理员、SEO/安全审计人员、爬虫与 AI Agent 开发者，可用于上线前 robots.txt 校验、真实页面可抓取性验证、动态网站巡检、访问策略回归和抓取边界说明。

## 核心功能范围

- 容错解析 `User-agent`、`Allow`、`Disallow`、`Sitemap`，支持重复规则组合并、通配组回退、最长八位组匹配、Allow 平局、`*`、`$`、UTF-8 与百分号编码；
- 提供命中源码行、候选规则追踪、结构化诊断、规则覆盖率、批量模拟、访问矩阵、策略差异、优化建议及 JSON/CSV/Markdown 报告；
- 使用 MoonBit Native 异步 HTTP 获取真实 `robots.txt` 和页面，按页面数、深度、请求间隔、超时、响应体积及同源边界执行 BFS 抓取；
- 通过 Edge DevTools Protocol 执行 JavaScript、处理同源重定向、读取最终 DOM、标题和描述、发现动态链接并保存页面截图；
- 实时展示当前阶段、URL、已处理页面、队列、耗时、ETA 和逐页结果，完成后生成抓取健康度、问题等级及可执行改进建议；
- 对初始 URL、DNS 结果和浏览器网络请求实施 SSRF 防护，拒绝本机、内网和特殊用途地址；默认遵守 robots.txt，策略无法可靠取得时保守停止；
- 提供 Native、JavaScript、Wasm、Wasm-GC 多目标构建、自动化测试、CI、完整 README、设计和兼容性文档。

## 原创与参考说明

项目的数据模型、RFC 9309 解析/匹配算法、诊断分析、抓取调度、报告和界面均为原创 MoonBit 实现，不是对既有开源项目的移植。规范行为参考 IETF RFC 9309；浏览器适配使用 Microsoft Edge 所支持的 Chrome DevTools Protocol 公共协议，未复制 Playwright、Puppeteer 等项目代码。项目采用 Apache-2.0 许可证，MoonBit 依赖及第三方协议来源在 `NOTICE.md` 中说明。
