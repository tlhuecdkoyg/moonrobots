///|
test "HTML scanner extracts quoted unquoted and entity hrefs" {
  let html =
    #|<!doctype html>
    #|<a class="primary" href="/docs?a=1&amp;b=2">Docs</a>
    #|<AREA HREF='/map'>Map</AREA>
    #|<a href=relative/page>Relative</a>
    #|<img href="/not-an-anchor">
  assert_eq(@moonrobots.extract_html_hrefs(html), [
    "/docs?a=1&b=2", "/map", "relative/page",
  ])
}

///|
test "HTML title extraction ignores tags and collapses whitespace" {
  let html = "<html><head><TITLE>  Moon <b>Robots</b>\n Studio &amp; Tools </TITLE></head></html>"
  assert_eq(@moonrobots.extract_html_title(html), "Moon Robots Studio & Tools")
  assert_eq(@moonrobots.extract_html_title("<p>No title</p>"), "")
}

///|
test "link classifier queues same-origin links and records exclusions" {
  let html =
    #|<a href="/new">new</a>
    #|<a href="/seen">seen</a>
    #|<a href="https://other.example/page">other</a>
    #|<a href="mailto:test@example.com">mail</a>
    #|<a href="http://127.0.0.1/admin">unsafe</a>
  let seen = ["https://example.com/", "https://example.com/seen"]
  let links = @moonrobots.classify_html_links(
    html, "https://example.com/", 1, 2, seen,
  )
  assert_eq(links.length(), 5)
  assert_eq(links[0].disposition, @moonrobots.Queued)
  assert_eq(links[1].disposition, @moonrobots.Duplicate)
  assert_eq(links[2].disposition, @moonrobots.DifferentOrigin)
  assert_eq(links[3].disposition, @moonrobots.UnsupportedScheme)
  assert_eq(links[4].disposition, @moonrobots.UnsafeHost)
  assert_true(seen.contains("https://example.com/new"))
  assert_eq(@moonrobots.queued_link_tasks(links).length(), 1)
}

///|
test "link classifier enforces maximum depth" {
  let seen = ["https://example.com/"]
  let links = @moonrobots.classify_html_links(
    "<a href='/deep'>deep</a>", "https://example.com/", 3, 2, seen,
  )
  assert_eq(links[0].disposition, @moonrobots.DepthExceeded)
  assert_false(seen.contains("https://example.com/deep"))
}
