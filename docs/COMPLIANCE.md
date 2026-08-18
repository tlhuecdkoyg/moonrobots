# RFC 9309 符合性说明

本文件跟踪 MoonRobots `0.1.x` 对 RFC 9309 的实现范围。

| RFC 范围 | 状态 | 说明 |
|---|---|---|
| 2.1 Groups and rules | 已实现 | 支持多个 agent 与规则组 |
| 2.2 Formal syntax | 部分实现 | 容错逐行解析；非法内容产生诊断 |
| 2.2.1 User-Agent | 已实现 | token 大小写不敏感；相同 token 组合规则 |
| 2.2.2 Allow/Disallow | 已实现 | 路径区分大小写、最长匹配、Allow 平局优先 |
| 2.2.3 `*` and `$` | 已实现 | glob 通配和末尾锚点 |
| 2.2.4 Other records | 已实现 | Sitemap 收集；其他字段诊断并忽略 |
| 2.3 Access method | 调用者职责 | 核心不进行网络获取 |
| 2.3.1 HTTP results | 未实现 | 后续网络适配层功能 |
| 2.4 Caching | 未实现 | 后续网络适配层功能 |
| 2.5 Limits | 部分实现 | 尚未暴露显式字节上限选项 |

## 已知差异

- API 接收明确 product token，不从完整 HTTP User-Agent 字符串猜测 token。
- 不自动下载 `/robots.txt`，因此 HTTP 4xx/5xx、重定向和缓存不属于当前核心库。
- 格式化器不保留注释及未知扩展。

在声称“完整 RFC 9309 网络客户端符合性”之前，必须实现 2.3、2.4 的适配层并通过额外测试。
