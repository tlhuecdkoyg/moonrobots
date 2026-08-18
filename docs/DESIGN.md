# MoonRobots 设计说明

## 设计原则

1. 核心确定性：解析和匹配不直接访问文件系统或网络。
2. 部分容错：错误记录不应阻止其他有效记录生效。
3. 可解释：决策保留命中规则、行号和 specificity。
4. 跨后端：核心库避免操作系统专属 API。
5. 边界明确：纯核心不联网，Native 执行器在显式限制下负责真实抓取。

## 数据流

```text
robots.txt text
      │
      ▼
 line parser ───────► diagnostics / sitemaps
      │
      ▼
 Policy(groups, rules)
      │
      ├── product-token selection and group merge
      │
 URI ─┴── path/query extraction
             │
             ▼
   percent/UTF-8 canonicalization
             │
             ▼
       wildcard matching
             │
             ▼
 longest match + Allow tie break
             │
             ▼
 Decision(allowed, matched rule, source line)
```

## 模块

- `model.mbt`：公开数据类型
- `parser.mbt`：容错的逐行解析
- `uri.mbt`：从绝对 URI 或相对路径中提取 path/query
- `matcher.mbt`：八位组规范化、glob、规则选择和决策
- `report.mbt`：解释、诊断及确定性格式化
- `crawler_url.mbt` / `crawler_html.mbt`：URL 安全边界、同源队列与 HTML 链接发现
- `crawler/native`：异步 HTTP、DNS 安全检查、robots 获取和受限 BFS 执行器
- `cmd/crawler`：真实抓取 CLI 与 JSON 输出
- `tools/studio_server.mjs`：仅监听回环地址的 Studio 静态服务和进程桥接
- `cmd/main`：本地文件 CLI

## 真实抓取数据流

```text
Studio / CLI 配置
      │
      ▼
URL 解析 ──► 主机名与 DNS 私网拦截
      │
      ▼
获取 /robots.txt ──► RFC 9309 Policy
      │
      ▼
同源 BFS 队列 ──► 逐 URL 访问决策 ──► HTTP 获取
                                      │
                                      ▼
                         HTML 标题与 href 提取
                                      │
                                      ▼
                     CrawlReport / JSON / 中文界面
```

## 关键决策

### Product token API

核心 API 接收 RFC 9309 product token，而不是完整 HTTP `User-Agent` 头。调用者负责从自身
标识中选择稳定 token。匹配不区分大小写，路径匹配区分大小写。

### 未知字段

未知字段记录诊断但不会切断当前组。这避免 `Sitemap`、`Crawl-delay` 等扩展改变标准规则
的分组语义。

### 格式化

`format_policy` 是规范化投影，不是无损格式化器：注释、空白和未知扩展不会被重现。

### CLI

CLI 使用 `moonbitlang/x/fs` 读取 UTF-8 文件。核心包只依赖 MoonBit core 的 UTF-8 编码模块。
退出码可供 shell 和规范测试工具使用。
