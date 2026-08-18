///|
fn crawl_index_of(text : String, wanted : Char, start : Int) -> Int? {
  for index = start; index < text.length(); index = index + 1 {
    if text.get_char(index) == Some(wanted) {
      return Some(index)
    }
  }
  None
}

///|
fn crawl_first_of(text : String, chars : String, start : Int) -> Int? {
  for index = start; index < text.length(); index = index + 1 {
    guard text.get_char(index) is Some(char) else { continue }
    if chars.contains(char.to_string()) {
      return Some(index)
    }
  }
  None
}

///|
fn parse_decimal(text : String) -> Int? {
  if text.is_empty() {
    return None
  }
  let mut value = 0
  for char in text {
    if char < '0' || char > '9' {
      return None
    }
    value = value * 10 + char.to_int() - '0'.to_int()
    if value > 65535 {
      return None
    }
  }
  Some(value)
}

///|
fn default_port(scheme : String) -> Int {
  if scheme == "https" {
    443
  } else {
    80
  }
}

///|
fn normalized_origin(scheme : String, host : String, port : Int) -> String {
  if port == default_port(scheme) {
    "\{scheme}://\{host}"
  } else {
    "\{scheme}://\{host}:\{port}"
  }
}

///|
fn split_host_port(authority : String, scheme : String) -> (String, Int)? {
  if authority.is_empty() || authority.contains("@") {
    return None
  }
  if authority.has_prefix("[") {
    // IPv6 literals are deliberately rejected by the first crawler release.
    return None
  }
  let mut colon = -1
  for index = 0; index < authority.length(); index = index + 1 {
    if authority.get_char(index) == Some(':') {
      if colon >= 0 {
        return None
      }
      colon = index
    }
  }
  if colon < 0 {
    return Some((authority.to_lower(), default_port(scheme)))
  }
  let host = authority[:colon].to_owned().to_lower()
  guard parse_decimal(authority[colon + 1:].to_owned()) is Some(port) else {
    return None
  }
  if host.is_empty() || port < 1 {
    None
  } else {
    Some((host, port))
  }
}

///|
fn remove_fragment(value : String) -> String {
  match crawl_index_of(value, '#', 0) {
    Some(index) => value[:index].to_owned()
    None => value
  }
}

///|
fn collapse_path(path_query : String) -> String {
  let query_index = crawl_index_of(path_query, '?', 0)
  let path = match query_index {
    Some(index) => path_query[:index].to_owned()
    None => path_query
  }
  let query = match query_index {
    Some(index) => path_query[index:].to_owned()
    None => ""
  }
  let parts : Array[String] = []
  for view in path.split("/") {
    let part = view.to_owned()
    if part.is_empty() || part == "." {
      continue
    }
    if part == ".." {
      if parts.length() > 0 {
        ignore(parts.pop())
      }
    } else {
      parts.push(part)
    }
  }
  let output = StringBuilder::new()
  output.write_char('/')
  for index, part in parts {
    if index > 0 {
      output.write_char('/')
    }
    output.write_string(part)
  }
  if path.has_suffix("/") && parts.length() > 0 {
    output.write_char('/')
  }
  output.write_string(query)
  output.to_string()
}

///|
/// Parse and normalize an absolute HTTP or HTTPS URL for crawling.
pub fn parse_crawl_url(value : String) -> CrawlUrl? {
  let clean = remove_fragment(value.trim().to_owned())
  guard clean.find("://") is Some(separator) else { return None }
  let scheme = clean[:separator].to_owned().to_lower()
  if scheme != "http" && scheme != "https" {
    return None
  }
  let authority_start = separator + 3
  let authority_end = match crawl_first_of(clean, "/?", authority_start) {
    Some(index) => index
    None => clean.length()
  }
  let authority = clean[authority_start:authority_end].to_owned()
  guard split_host_port(authority, scheme) is Some((host, port)) else {
    return None
  }
  if host.is_empty() || host.contains(" ") || host.has_suffix(".") {
    return None
  }
  let raw_path = if authority_end == clean.length() {
    "/"
  } else {
    let suffix = clean[authority_end:].to_owned()
    if suffix.has_prefix("?") {
      "/" + suffix
    } else {
      suffix
    }
  }
  let path_query = collapse_path(raw_path)
  let origin = normalized_origin(scheme, host, port)
  { scheme, host, port, path_query, origin, normalized: origin + path_query }
  |> Some
}

///|
fn directory_of(path_query : String) -> String {
  let path = match crawl_index_of(path_query, '?', 0) {
    Some(index) => path_query[:index].to_owned()
    None => path_query
  }
  let mut last_slash = 0
  for index = 0; index < path.length(); index = index + 1 {
    if path.get_char(index) == Some('/') {
      last_slash = index
    }
  }
  path[:last_slash + 1].to_owned()
}

///|
/// Resolve a link from an HTML document without allowing non-HTTP schemes.
pub fn resolve_crawl_link(base_url : String, href : String) -> CrawlUrl? {
  guard parse_crawl_url(base_url) is Some(base) else { return None }
  let value = href.trim().to_owned()
  if value.is_empty() || value.has_prefix("#") {
    return None
  }
  let lower = value.to_lower()
  if lower.has_prefix("mailto:") ||
    lower.has_prefix("javascript:") ||
    lower.has_prefix("data:") ||
    lower.has_prefix("tel:") ||
    lower.has_prefix("file:") {
    return None
  }
  if value.contains("://") {
    return parse_crawl_url(value)
  }
  if value.has_prefix("//") {
    return parse_crawl_url(base.scheme + ":" + value)
  }
  if value.has_prefix("/") {
    return parse_crawl_url(base.origin + value)
  }
  if value.has_prefix("?") {
    let current_path = match crawl_index_of(base.path_query, '?', 0) {
      Some(index) => base.path_query[:index].to_owned()
      None => base.path_query
    }
    return parse_crawl_url(base.origin + current_path + value)
  }
  parse_crawl_url(base.origin + directory_of(base.path_query) + value)
}

///|
fn decimal_octets(host : String) -> Array[Int]? {
  let values : Array[Int] = []
  for part in host.split(".") {
    guard parse_decimal(part.to_owned()) is Some(value) else { return None }
    if value > 255 {
      return None
    }
    values.push(value)
  }
  if values.length() == 4 {
    Some(values)
  } else {
    None
  }
}

///|
/// Reject hostnames and literal addresses that must never be contacted by the
/// crawler. Native execution additionally performs a DNS preflight.
pub fn unsafe_crawl_host(host : String) -> Bool {
  let lower = host.to_lower()
  if lower == "localhost" ||
    lower.has_suffix(".localhost") ||
    lower.has_suffix(".local") ||
    lower.has_suffix(".internal") ||
    lower == "0" ||
    lower == "::1" ||
    lower == "[::1]" {
    return true
  }
  guard decimal_octets(lower) is Some(parts) else { return false }
  let a = parts[0]
  let b = parts[1]
  a == 0 ||
  a == 10 ||
  a == 127 ||
  (a == 169 && b == 254) ||
  (a == 172 && b >= 16 && b <= 31) ||
  (a == 192 && b == 168) ||
  (a == 100 && b >= 64 && b <= 127) ||
  (a == 198 && (b == 18 || b == 19)) ||
  a >= 224
}

///|
/// Check whether two URLs share scheme, hostname and effective port.
pub fn same_crawl_origin(left : String, right : String) -> Bool {
  guard parse_crawl_url(left) is Some(a) else { return false }
  guard parse_crawl_url(right) is Some(b) else { return false }
  a.origin == b.origin
}

///|
/// Validate and clamp user crawler settings before any request is sent.
pub fn normalize_crawl_config(config : CrawlConfig) -> CrawlConfig? {
  guard parse_crawl_url(config.start_url) is Some(url) else { return None }
  if unsafe_crawl_host(url.host) {
    return None
  }
  let token = config.product_token.trim().to_owned()
  if token.is_empty() || token == "*" || !valid_product_token(token) {
    return None
  }
  {
    start_url: url.normalized,
    product_token: token,
    max_pages: config.max_pages.clamp(min=1, max=100),
    max_depth: config.max_depth.clamp(min=0, max=5),
    delay_ms: config.delay_ms.clamp(min=100, max=10000),
    max_body_bytes: config.max_body_bytes.clamp(min=1024, max=5 * 1024 * 1024),
    respect_robots: config.respect_robots,
  }
  |> Some
}
