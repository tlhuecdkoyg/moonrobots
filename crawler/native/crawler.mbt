///|
fn private_ipv4(ip : UInt) -> Bool {
  let a = ((ip >> 24) & 0xff).reinterpret_as_int()
  let b = ((ip >> 16) & 0xff).reinterpret_as_int()
  a == 0 ||
  a == 10 ||
  a == 127 ||
  (a == 100 && b >= 64 && b <= 127) ||
  (a == 169 && b == 254) ||
  (a == 172 && b >= 16 && b <= 31) ||
  (a == 192 && b == 0) ||
  (a == 192 && b == 168) ||
  (a == 198 && (b == 18 || b == 19)) ||
  a >= 224
}

///|
async fn safe_dns(url : @robots.CrawlUrl) -> Bool {
  let addr = @socket.Addr::resolve(
    url.host,
    port=url.port,
    protocol=@socket.OnlyV4,
  )
  !addr.is_ipv6() && !private_ipv4(addr.ip())
}

///|
fn response_header(headers : Map[String, String], name : String) -> String {
  let wanted = name.to_lower()
  for key, value in headers {
    if key.to_lower() == wanted {
      return value
    }
  }
  ""
}

///|
async fn fetch_text(
  url : String,
  product_token : String,
) -> (@http.Response, String, Int) {
  let headers = {
    "User-Agent": product_token,
    "Accept": "text/html,application/xhtml+xml,text/plain;q=0.8,*/*;q=0.1",
    "Accept-Encoding": "identity",
  }
  let (response, data) = @async.with_timeout(15000, () => {
    @http.get(url, headers~)
  })
  let bytes = data.binary().length()
  (response, data.text(), bytes)
}

///|
fn matched_rule_text(decision : @robots.Decision) -> String? {
  match decision.matched {
    Some(rule) => Some("第 \{rule.line} 行：\{rule.pattern}")
    None => None
  }
}

///|
fn failed_page(task : @robots.CrawlTask, message : String) -> @robots.CrawlPage {
  {
    url: task.url,
    depth: task.depth,
    status: @robots.NetworkError,
    http_status: None,
    content_type: "",
    title: "",
    bytes: 0,
    elapsed_ms: 0,
    matched_rule: None,
    message,
    outgoing_links: 0,
  }
}

///|
/// Execute a bounded, same-origin crawl with robots.txt enforcement.
/// Private and special-use IPv4 destinations are rejected after DNS resolution.
pub async fn crawl(input : @robots.CrawlConfig) -> @robots.CrawlReport {
  guard @robots.normalize_crawl_config(input) is Some(config) else {
    fail("invalid crawl configuration")
  }
  guard @robots.parse_crawl_url(config.start_url) is Some(start) else {
    fail("invalid start URL")
  }
  if @robots.unsafe_crawl_host(start.host) {
    fail("unsafe start host")
  }
  if !(safe_dns(start) catch { _ => false }) {
    fail("DNS resolution failed or resolved to a private/special address")
  }
  let robots_url = start.origin + "/robots.txt"
  let mut robots_status : Int? = None
  let mut robots_text = ""
  let mut robots_available = true
  let mut robots_error = ""
  if config.respect_robots {
    try {
      let (response, text, bytes) = fetch_text(robots_url, config.product_token)
      robots_status = Some(response.code)
      if response.code >= 200 &&
        response.code < 300 &&
        bytes <= config.max_body_bytes {
        robots_text = text
      } else if response.code >= 500 {
        robots_available = false
      }
    } catch {
      err => {
        robots_available = false
        robots_error = "\{err}"
      }
    }
  }
  let policy = @robots.parse(robots_text)
  let pages : Array[@robots.CrawlPage] = []
  let links : Array[@robots.DiscoveredLink] = []
  let queue : Array[@robots.CrawlTask] = [
    { url: start.normalized, depth: 0, discovered_from: None },
  ]
  let seen : Array[String] = [start.normalized]
  let mut cursor = 0
  let mut fetched = 0
  let mut blocked = 0
  let mut failed = 0
  let mut skipped = 0
  let mut downloaded = 0
  while cursor < queue.length() && pages.length() < config.max_pages {
    let task = queue[cursor]
    cursor = cursor + 1
    if config.respect_robots && !robots_available {
      pages.push({
        url: task.url,
        depth: task.depth,
        status: @robots.BlockedByRobots,
        http_status: None,
        content_type: "",
        title: "",
        bytes: 0,
        elapsed_ms: 0,
        matched_rule: None,
        message: if robots_error == "" {
          "robots.txt 暂时不可用；依据 RFC 9309 采取保守拒绝"
        } else {
          "robots.txt 获取失败（\{robots_error}）；依据 RFC 9309 采取保守拒绝"
        },
        outgoing_links: 0,
      })
      blocked = blocked + 1
      continue
    }
    let decision = @robots.evaluate(policy, config.product_token, task.url)
    if config.respect_robots && !decision.allowed {
      pages.push({
        url: task.url,
        depth: task.depth,
        status: @robots.BlockedByRobots,
        http_status: None,
        content_type: "",
        title: "",
        bytes: 0,
        elapsed_ms: 0,
        matched_rule: matched_rule_text(decision),
        message: "请求被 robots.txt 规则阻止",
        outgoing_links: 0,
      })
      blocked = blocked + 1
      continue
    }
    if fetched + failed + skipped > 0 {
      @async.sleep(config.delay_ms)
    }
    try {
      let (response, body, byte_count) = fetch_text(
        task.url,
        config.product_token,
      )
      downloaded = downloaded + byte_count
      let content_type = response_header(response.headers, "content-type")
      if byte_count > config.max_body_bytes {
        pages.push({
          url: task.url,
          depth: task.depth,
          status: @robots.TooLarge,
          http_status: Some(response.code),
          content_type,
          title: "",
          bytes: byte_count,
          elapsed_ms: 0,
          matched_rule: matched_rule_text(decision),
          message: "响应体超过 \{config.max_body_bytes} 字节上限",
          outgoing_links: 0,
        })
        failed = failed + 1
      } else if response.code < 200 || response.code >= 300 {
        pages.push({
          url: task.url,
          depth: task.depth,
          status: @robots.HttpError,
          http_status: Some(response.code),
          content_type,
          title: "",
          bytes: byte_count,
          elapsed_ms: 0,
          matched_rule: matched_rule_text(decision),
          message: "HTTP \{response.code} \{response.reason}",
          outgoing_links: 0,
        })
        failed = failed + 1
      } else if !content_type.to_lower().contains("html") {
        pages.push({
          url: task.url,
          depth: task.depth,
          status: @robots.SkippedNonHtml,
          http_status: Some(response.code),
          content_type,
          title: "",
          bytes: byte_count,
          elapsed_ms: 0,
          matched_rule: matched_rule_text(decision),
          message: "只记录非 HTML 响应，不从中发现链接",
          outgoing_links: 0,
        })
        skipped = skipped + 1
      } else {
        let found = @robots.classify_html_links(
          body,
          task.url,
          task.depth + 1,
          config.max_depth,
          seen,
        )
        for link in found {
          links.push(link)
        }
        for next in @robots.queued_link_tasks(found) {
          queue.push(next)
        }
        pages.push({
          url: task.url,
          depth: task.depth,
          status: @robots.Fetched,
          http_status: Some(response.code),
          content_type,
          title: @robots.extract_html_title(body),
          bytes: byte_count,
          elapsed_ms: 0,
          matched_rule: matched_rule_text(decision),
          message: "抓取成功",
          outgoing_links: found.length(),
        })
        fetched = fetched + 1
      }
    } catch {
      err => {
        pages.push(failed_page(task, "网络请求失败：\{err}"))
        failed = failed + 1
      }
    }
  }
  let stopped_reason = if pages.length() >= config.max_pages &&
    cursor < queue.length() {
    "达到最大页面数 \{config.max_pages}"
  } else {
    "队列已处理完毕"
  }
  {
    start_url: start.normalized,
    origin: start.origin,
    product_token: config.product_token,
    robots_url,
    robots_status,
    robots_text,
    started_at: "",
    finished_at: "",
    pages,
    links,
    fetched_count: fetched,
    blocked_count: blocked,
    failed_count: failed,
    skipped_count: skipped,
    bytes_downloaded: downloaded,
    stopped_reason,
  }
}
