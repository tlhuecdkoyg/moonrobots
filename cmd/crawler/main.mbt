///|
fn usage() -> String {
  "Usage: moon run --target native cmd/crawler -- <URL> [product-token] [max-pages] [max-depth] [delay-ms] [--json]"
}

///|
fn int_arg(args : Array[String], index : Int, fallback : Int) -> Int {
  if index >= args.length() {
    return fallback
  }
  @string.parse_int(args[index]) catch {
    _ => fallback
  }
}

///|
async fn main {
  let args = @env.args()
  if args.length() < 2 {
    println(usage())
    @sys.exit(2)
    return
  }
  let report = @nativecrawler.crawl({
    start_url: args[1],
    product_token: if args.length() > 2 {
      args[2]
    } else {
      "MoonRobotsBot"
    },
    max_pages: int_arg(args, 3, 20),
    max_depth: int_arg(args, 4, 2),
    delay_ms: int_arg(args, 5, 500),
    max_body_bytes: 1048576,
    respect_robots: true,
  }) catch {
    err => {
      println("抓取失败：\{err}")
      @sys.exit(1)
      return
    }
  }
  if args.contains("--json") {
    println(@robots.crawl_report_to_json(report))
  } else {
    println(@robots.format_crawl_report(report))
  }
}
