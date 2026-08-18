///|
/// Stable JSON representation consumed by the CLI and local Studio bridge.
pub fn crawl_report_to_json(report : CrawlReport) -> String {
  report.to_json().stringify(indent=2)
}

///|
fn crawl_status_label(status : CrawlPageStatus) -> String {
  match status {
    Fetched => "已抓取"
    BlockedByRobots => "robots.txt 已阻止"
    SkippedNonHtml => "非 HTML，已跳过"
    HttpError => "HTTP 错误"
    NetworkError => "网络错误"
    TooLarge => "响应体过大"
  }
}

///|
/// Human-readable Chinese summary for terminal users.
pub fn format_crawl_report(report : CrawlReport) -> String {
  let out = StringBuilder()
  out.write_string("MoonRobots 真实抓取报告\n")
  out.write_string("起始地址：\{report.start_url}\n")
  out.write_string(
    "抓取结果：\{report.fetched_count} 成功，\{report.blocked_count} 阻止，\{report.failed_count} 失败，\{report.skipped_count} 跳过\n",
  )
  out.write_string("下载字节：\{report.bytes_downloaded}\n")
  out.write_string("停止原因：\{report.stopped_reason}\n\n")
  for page in report.pages {
    out.write_string("[\{crawl_status_label(page.status)}] \{page.url}")
    if page.title != "" {
      out.write_string(" — \{page.title}")
    }
    out.write_char('\n')
  }
  out.to_string()
}
