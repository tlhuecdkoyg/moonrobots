# Third-party notices

MoonRobots 的实现以公开标准为主要依据，源代码由项目独立编写。

## Normative reference

- RFC 9309, *Robots Exclusion Protocol*, IETF / RFC Editor, 2022.
  <https://www.rfc-editor.org/rfc/rfc9309.html>

RFC 文本不随本仓库重新分发。RFC 中的示例行为被用于编写独立测试。

## Behavioral references

- Google Robots.txt Parser and Matcher Library
  <https://github.com/google/robotstxt>
  License: Apache-2.0.
- Google Robots.txt Specification Test
  <https://github.com/google/robotstxt-spec-test>
  License: Apache-2.0.

当前仓库没有复制上述项目的 C++、Java 或测试框架源代码。若未来引入其测试数据，必须保留
相应版权头、许可证和来源路径。

## Dependencies

- `moonbitlang/core`：MoonBit 核心标准库
- `moonbitlang/x`：CLI 文件系统和进程退出适配
- `moonbitlang/async`：Native 异步 HTTP、TLS、DNS 与定时器

浏览器模式调用用户本机安装的 Microsoft Edge，并通过公开的 Chrome DevTools Protocol
通信；仓库不分发 Edge、Chromium、Playwright 或 Puppeteer 代码。Node.js 适配层仅使用
Node 内置模块，不引入 npm 运行时依赖。

依赖的精确版本记录在 `moon.mod` 中。
