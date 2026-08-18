// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "tlhuecdkoyg/moonrobots"

version = "0.1.0"

readme = "README.mbt.md"

repository = "https://github.com/tlhuecdkoyg/moonrobots"

license = "Apache-2.0"

keywords = [
  "robots-txt",
  "crawler",
  "browser",
  "rfc9309",
  "monitoring",
  "wasm",
]

preferred_target = "wasm"

description = "A MoonBit-powered RFC 9309 policy analyzer and safe HTTP/browser crawling operations center."

import {
  "moonbitlang/x@0.4.50",
  "moonbitlang/async@0.20.2",
}
