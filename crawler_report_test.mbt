///|
fn sample_crawl_report() -> CrawlReport {
  {
    start_url: "https://example.com/",
    origin: "https://example.com",
    product_token: "MoonRobotsBot",
    robots_url: "https://example.com/robots.txt",
    robots_status: Some(404),
    robots_text: "",
    started_at: "",
    finished_at: "",
    pages: [
      {
        url: "https://example.com/",
        depth: 0,
        status: Fetched,
        http_status: Some(200),
        content_type: "text/html",
        title: "Example Domain",
        bytes: 559,
        elapsed_ms: 0,
        matched_rule: None,
        message: "抓取成功",
        outgoing_links: 1,
      },
    ],
    links: [],
    fetched_count: 1,
    blocked_count: 0,
    failed_count: 0,
    skipped_count: 0,
    bytes_downloaded: 559,
    stopped_reason: "队列已处理完毕",
  }
}

///|
test "crawl report JSON exposes stable fields" {
  let json = crawl_report_to_json(sample_crawl_report())
  assert_true(json.contains("\"fetched_count\": 1"))
  assert_true(json.contains("\"status\": \"Fetched\""))
  assert_true(json.contains("Example Domain"))
}

///|
test "crawl report terminal output defaults to Chinese" {
  let text = format_crawl_report(sample_crawl_report())
  assert_true(text.contains("真实抓取报告"))
  assert_true(text.contains("[已抓取]"))
  assert_true(text.contains("1 成功"))
}
