///|
fn html_is_space(char : Char) -> Bool {
  char == ' ' ||
  char == '\t' ||
  char == '\r' ||
  char == '\n' ||
  char == '\u{0C}'
}

///|
fn html_name_char(char : Char) -> Bool {
  (char >= 'a' && char <= 'z') ||
  (char >= 'A' && char <= 'Z') ||
  (char >= '0' && char <= '9') ||
  char == '-' ||
  char == '_' ||
  char == ':'
}

///|
fn skip_html_space(text : String, start : Int, end : Int) -> Int {
  let mut index = start
  while index < end {
    guard text.get_char(index) is Some(char) else { break }
    if !html_is_space(char) {
      break
    }
    index = index + 1
  }
  index
}

///|
fn html_entity_decode(value : String) -> String {
  value
  .replace_all(old="&amp;", new="&")
  .replace_all(old="&quot;", new="\"")
  .replace_all(old="&#39;", new="'")
  .replace_all(old="&lt;", new="<")
  .replace_all(old="&gt;", new=">")
}

///|
fn find_tag_end(html : String, start : Int) -> Int? {
  let mut quote : Char? = None
  for index = start; index < html.length(); index = index + 1 {
    guard html.get_char(index) is Some(char) else { continue }
    match quote {
      Some(expected) => if char == expected { quote = None }
      None =>
        if char == '\'' || char == '"' {
          quote = Some(char)
        } else if char == '>' {
          return Some(index)
        }
    }
  }
  None
}

///|
fn parse_attribute(
  html : String,
  lower : String,
  start : Int,
  end : Int,
  wanted : String,
) -> String? {
  let mut index = start
  while index < end {
    index = skip_html_space(html, index, end)
    if index >= end || html.get_char(index) == Some('/') {
      break
    }
    let name_start = index
    while index < end {
      guard html.get_char(index) is Some(char) else { break }
      if !html_name_char(char) {
        break
      }
      index = index + 1
    }
    if index == name_start {
      index = index + 1
      continue
    }
    let name = lower[name_start:index].to_owned()
    index = skip_html_space(html, index, end)
    if index >= end || html.get_char(index) != Some('=') {
      continue
    }
    index = skip_html_space(html, index + 1, end)
    if index >= end {
      break
    }
    let mut value_start = index
    let mut value_end = index
    guard html.get_char(index) is Some(first) else { break }
    if first == '\'' || first == '"' {
      let quote = first
      value_start = index + 1
      index = value_start
      while index < end && html.get_char(index) != Some(quote) {
        index = index + 1
      }
      value_end = index
      if index < end {
        index = index + 1
      }
    } else {
      value_start = index
      while index < end {
        guard html.get_char(index) is Some(char) else { break }
        if html_is_space(char) || char == '>' {
          break
        }
        index = index + 1
      }
      value_end = index
    }
    if name == wanted {
      return Some(html_entity_decode(html[value_start:value_end].to_owned()))
    }
  }
  None
}

///|
/// Extract href values from anchor and area tags. Script text and malformed
/// markup are tolerated; this is a crawler-oriented scanner, not a DOM parser.
pub fn extract_html_hrefs(html : String) -> Array[String] {
  let lower = html.to_lower()
  let hrefs : Array[String] = []
  let mut index = 0
  while index < html.length() {
    guard crawl_index_of(lower, '<', index) is Some(open) else { break }
    guard find_tag_end(html, open + 1) is Some(close) else { break }
    let mut name_start = skip_html_space(html, open + 1, close)
    if html.get_char(name_start) == Some('/') ||
      html.get_char(name_start) == Some('!') ||
      html.get_char(name_start) == Some('?') {
      index = close + 1
      continue
    }
    let tag_start = name_start
    while name_start < close {
      guard html.get_char(name_start) is Some(char) else { break }
      if !html_name_char(char) {
        break
      }
      name_start = name_start + 1
    }
    let tag = lower[tag_start:name_start].to_owned()
    if tag == "a" || tag == "area" {
      match parse_attribute(html, lower, name_start, close, "href") {
        Some(href) => if !href.is_empty() { hrefs.push(href) }
        None => ()
      }
    }
    index = close + 1
  }
  hrefs
}

///|
fn strip_html_tags(fragment : String) -> String {
  let output = StringBuilder::new()
  let mut in_tag = false
  for char in fragment {
    if char == '<' {
      in_tag = true
    } else if char == '>' {
      in_tag = false
      output.write_char(' ')
    } else if !in_tag {
      output.write_char(char)
    }
  }
  let decoded = html_entity_decode(output.to_string())
  let clean = StringBuilder::new()
  let mut pending_space = false
  let mut wrote_content = false
  for char in decoded {
    if html_is_space(char) {
      if wrote_content {
        pending_space = true
      }
    } else {
      if pending_space {
        clean.write_char(' ')
        pending_space = false
      }
      clean.write_char(char)
      wrote_content = true
    }
  }
  clean.to_string()
}

///|
/// Extract a compact document title for crawl reports.
pub fn extract_html_title(html : String) -> String {
  let lower = html.to_lower()
  guard lower.find("<title") is Some(open) else { return "" }
  guard find_tag_end(html, open + 6) is Some(content_start) else { return "" }
  guard lower[content_start + 1:].to_owned().find("</title")
    is Some(relative_end) else {
    return ""
  }
  let content_end = content_start + 1 + relative_end
  let title = strip_html_tags(html[content_start + 1:content_end].to_owned())
  if title.length() <= 200 {
    title
  } else {
    title[:200].to_owned()
  }
}

///|
fn href_scheme_unsupported(href : String) -> Bool {
  let lower = href.trim().to_owned().to_lower()
  lower.has_prefix("mailto:") ||
  lower.has_prefix("javascript:") ||
  lower.has_prefix("data:") ||
  lower.has_prefix("tel:") ||
  lower.has_prefix("file:") ||
  (
    lower.contains("://") &&
    !(lower.has_prefix("http://") || lower.has_prefix("https://"))
  )
}

///|
/// Classify extracted links, enforce same-origin/depth constraints and append
/// newly accepted URLs to `seen` for deterministic breadth-first crawling.
pub fn classify_html_links(
  html : String,
  source_url : String,
  next_depth : Int,
  max_depth : Int,
  seen : Array[String],
) -> Array[DiscoveredLink] {
  let links : Array[DiscoveredLink] = []
  for href in extract_html_hrefs(html) {
    if href_scheme_unsupported(href) {
      links.push({
        source_url,
        raw_href: href,
        normalized_url: None,
        depth: next_depth,
        disposition: UnsupportedScheme,
      })
      continue
    }
    guard resolve_crawl_link(source_url, href) is Some(resolved) else {
      links.push({
        source_url,
        raw_href: href,
        normalized_url: None,
        depth: next_depth,
        disposition: InvalidUrl,
      })
      continue
    }
    let disposition = if unsafe_crawl_host(resolved.host) {
      UnsafeHost
    } else if !same_crawl_origin(source_url, resolved.normalized) {
      DifferentOrigin
    } else if next_depth > max_depth {
      DepthExceeded
    } else if seen.contains(resolved.normalized) {
      Duplicate
    } else {
      seen.push(resolved.normalized)
      Queued
    }
    links.push({
      source_url,
      raw_href: href,
      normalized_url: Some(resolved.normalized),
      depth: next_depth,
      disposition,
    })
  }
  links
}

///|
/// Return only URLs accepted by `classify_html_links`.
pub fn queued_link_tasks(links : Array[DiscoveredLink]) -> Array[CrawlTask] {
  let tasks : Array[CrawlTask] = []
  for link in links {
    if link.disposition == Queued {
      match link.normalized_url {
        Some(url) =>
          tasks.push({
            url,
            depth: link.depth,
            discovered_from: Some(link.source_url),
          })
        None => ()
      }
    }
  }
  tasks
}
