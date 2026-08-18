///|
test "crawl URL parser normalizes origin path query and fragments" {
  guard @moonrobots.parse_crawl_url(
      "HTTPS://Example.COM:443/a/./b/../c?q=1#fragment",
    )
    is Some(url) else {
    fail("expected a valid URL")
  }
  assert_eq(url.scheme, "https")
  assert_eq(url.host, "example.com")
  assert_eq(url.port, 443)
  assert_eq(url.origin, "https://example.com")
  assert_eq(url.path_query, "/a/c?q=1")
  assert_eq(url.normalized, "https://example.com/a/c?q=1")
}

///|
test "crawl URL parser retains non-default ports" {
  guard @moonrobots.parse_crawl_url("http://example.com:8080") is Some(url) else {
    fail("expected a valid URL")
  }
  assert_eq(url.origin, "http://example.com:8080")
  assert_eq(url.normalized, "http://example.com:8080/")
}

///|
test "crawl URL parser rejects credentials IPv6 and unsupported schemes" {
  assert_eq(@moonrobots.parse_crawl_url("ftp://example.com/file"), None)
  assert_eq(@moonrobots.parse_crawl_url("https://user@example.com/"), None)
  assert_eq(@moonrobots.parse_crawl_url("https://[::1]/"), None)
  assert_eq(@moonrobots.parse_crawl_url("example.com"), None)
}

///|
test "relative crawl links resolve against document directory" {
  assert_eq(
    @moonrobots.resolve_crawl_link(
      "https://example.com/docs/start/index.html", "../guide/page.html#intro",
    ).map(fn(url) { url.normalized }),
    Some("https://example.com/docs/guide/page.html"),
  )
  assert_eq(
    @moonrobots.resolve_crawl_link(
      "https://example.com/docs/index.html?old=1", "?new=2",
    ).map(fn(url) { url.normalized }),
    Some("https://example.com/docs/index.html?new=2"),
  )
}

///|
test "same origin compares scheme host and effective port" {
  assert_true(
    @moonrobots.same_crawl_origin(
      "https://example.com/a", "https://EXAMPLE.com:443/b",
    ),
  )
  assert_false(
    @moonrobots.same_crawl_origin(
      "http://example.com/a", "https://example.com/a",
    ),
  )
  assert_false(
    @moonrobots.same_crawl_origin(
      "https://example.com/a", "https://other.example/a",
    ),
  )
}

///|
test "unsafe crawler host blocks local private and special ranges" {
  for
    host in [
      "localhost", "app.localhost", "printer.local", "10.0.0.1", "127.0.0.1", "169.254.169.254",
      "172.16.0.1", "172.31.255.255", "192.168.1.1", "100.64.0.1", "198.18.0.1",
      "224.0.0.1",
    ] {
    assert_true(@moonrobots.unsafe_crawl_host(host))
  }
  assert_false(@moonrobots.unsafe_crawl_host("example.com"))
  assert_false(@moonrobots.unsafe_crawl_host("8.8.8.8"))
  assert_false(@moonrobots.unsafe_crawl_host("172.32.0.1"))
}

///|
test "crawler config validates identity and clamps resource limits" {
  let raw : @moonrobots.CrawlConfig = {
    start_url: "https://example.com",
    product_token: "MoonCrawler",
    max_pages: 1000,
    max_depth: 20,
    delay_ms: 0,
    max_body_bytes: 20 * 1024 * 1024,
    respect_robots: true,
  }
  guard @moonrobots.normalize_crawl_config(raw) is Some(config) else {
    fail("expected valid config")
  }
  assert_eq(config.max_pages, 100)
  assert_eq(config.max_depth, 5)
  assert_eq(config.delay_ms, 100)
  assert_eq(config.max_body_bytes, 5 * 1024 * 1024)
  assert_eq(
    @moonrobots.normalize_crawl_config({ ..raw, product_token: "*" }),
    None,
  )
  assert_eq(
    @moonrobots.normalize_crawl_config({ ..raw, start_url: "http://127.0.0.1" }),
    None,
  )
}
