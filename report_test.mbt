///|
test "explain a matched decision" {
  let policy = @moonrobots.parse("User-agent: *\nDisallow: /private\n")
  let report = @moonrobots.explain(
    @moonrobots.evaluate(policy, "ExampleBot", "/private/data"),
  )
  assert_eq(
    report,
    "DISALLOWED: /private/data\n" +
    "User-agent: ExampleBot\n" +
    "Matched: Disallow: /private (line 2)",
  )
}

///|
test "explain the default allow decision" {
  let report = @moonrobots.explain(
    @moonrobots.evaluate(@moonrobots.parse(""), "Bot", "/public"),
  )
  assert_true(report.has_prefix("ALLOWED: /public"))
  assert_true(report.has_suffix("access is allowed by default."))
}

///|
test "format a supported policy deterministically" {
  let policy = @moonrobots.parse(
    "user-agent: A\nuser-agent: B\ndisallow: /x\n" +
    "sitemap: https://example.com/sitemap.xml\n",
  )
  assert_eq(
    @moonrobots.format_policy(policy),
    "User-agent: a\n" +
    "User-agent: b\n" +
    "Disallow: /x\n\n" +
    "Sitemap: https://example.com/sitemap.xml\n",
  )
}

///|
test "format diagnostics with stable codes and source lines" {
  let policy = @moonrobots.parse("broken\n")
  assert_eq(
    @moonrobots.format_diagnostics(policy),
    "warning[missing-colon] line 1: Ignored a record without a colon.\n",
  )
}

///|
test "explain the implicit robots.txt exception" {
  let policy = @moonrobots.parse("User-agent: *\nDisallow: /\n")
  let report = @moonrobots.explain(
    @moonrobots.evaluate(policy, "Bot", "/robots.txt"),
  )
  assert_true(
    report.has_suffix(
      "The /robots.txt resource is implicitly allowed by RFC 9309.",
    ),
  )
}

///|
test "format separates multiple groups" {
  let policy = @moonrobots.parse(
    "User-agent: A\nDisallow: /a\nUser-agent: B\nAllow: /b\n",
  )
  assert_eq(
    @moonrobots.format_policy(policy),
    "User-agent: a\nDisallow: /a\n\nUser-agent: b\nAllow: /b\n",
  )
}
