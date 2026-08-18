///|
test "semantic diff reports rule additions and access closure" {
  let before = "User-agent: *\nAllow: /\n"
  let after = "User-agent: *\nAllow: /\nDisallow: /private\n"
  let diff = @moonrobots.compare_policies(
    before, after, "ExampleBot", "/\n/private/report",
  )
  assert_eq(diff.opened_count, 0)
  assert_eq(diff.closed_count, 1)
  assert_eq(diff.unchanged_count, 1)
  assert_eq(diff.decisions.length(), 1)
  assert_false(diff.decisions[0].after_allowed)
  let kinds = diff.changes.map(fn(change) { change.kind })
  assert_true(kinds.contains(@moonrobots.RuleAdded))
  assert_true(kinds.contains(@moonrobots.AccessClosed))
}

///|
test "semantic diff reports access opening" {
  let before = "User-agent: *\nDisallow: /private\n"
  let after = "User-agent: *\nDisallow: /private\nAllow: /private/public\n"
  let diff = @moonrobots.compare_policies(
    before, after, "Bot", "/private/report\n/private/public/page",
  )
  assert_eq(diff.opened_count, 1)
  assert_eq(diff.closed_count, 0)
  assert_eq(diff.decisions[0].uri, "/private/public/page")
  assert_true(diff.decisions[0].after_allowed)
}

///|
test "semantic diff detects group and sitemap changes" {
  let before =
    #|User-agent: OldBot
    #|Disallow: /old
    #|Sitemap: https://example.com/old.xml
  let after =
    #|User-agent: NewBot
    #|Disallow: /new
    #|Sitemap: https://example.com/new.xml
  let diff = @moonrobots.compare_policies(before, after, "", "")
  let kinds = diff.changes.map(fn(change) { change.kind })
  assert_true(kinds.contains(@moonrobots.GroupRemoved))
  assert_true(kinds.contains(@moonrobots.GroupAdded))
  assert_true(kinds.contains(@moonrobots.SitemapRemoved))
  assert_true(kinds.contains(@moonrobots.SitemapAdded))
}

///|
test "identical policies have no semantic changes" {
  let source = "User-agent: *\nDisallow: /private\n"
  let diff = @moonrobots.compare_policies(source, source, "Bot", "/private")
  assert_eq(diff.changes.length(), 0)
  assert_eq(diff.decisions.length(), 0)
  assert_eq(diff.unchanged_count, 1)
}

///|
test "semantic diff renders Markdown report" {
  let diff = @moonrobots.compare_policies(
    "User-agent: *\nAllow: /\n", "User-agent: *\nDisallow: /\n", "Bot", "/",
  )
  let markdown = @moonrobots.policy_diff_to_markdown(diff)
  assert_true(markdown.has_prefix("# robots.txt semantic diff"))
  assert_true(markdown.contains("**1 closed**"))
  assert_true(markdown.contains("| Bot | `/` | Allowed | Disallowed |"))
}
