///|
test "parse groups, comments, case, and sitemap" {
  let policy = @moonrobots.parse(
    (
      #|# sample
      #|User-Agent: ExampleBot
      #|Disallow: /private/ # hidden
      #|ALLOW: /private/public/
      #|Sitemap: https://example.com/sitemap.xml
      #|
      #|user-agent: *
      #|Disallow: /tmp
    ),
  )
  assert_eq(policy.groups.length(), 2)
  assert_eq(policy.groups[0].agents, ["examplebot"])
  assert_eq(policy.groups[0].rules.length(), 2)
  assert_eq(policy.sitemaps, ["https://example.com/sitemap.xml"])
  assert_eq(policy.diagnostics.length(), 0)
}

///|
test "merge consecutive user-agent lines into one group" {
  let policy = @moonrobots.parse(
    (
      #|User-agent: AlphaBot
      #|User-agent: BetaBot
      #|Disallow: /shared
    ),
  )
  assert_eq(policy.groups.length(), 1)
  assert_eq(policy.groups[0].agents, ["alphabot", "betabot"])
}

///|
test "keep parseable records and diagnose malformed ones" {
  let policy = @moonrobots.parse(
    (
      #|Disallow: /orphan
      #|bad record
      #|User-agent: Bad Bot
      #|User-agent: GoodBot
      #|Unknown: value
      #|Disallow: /valid
    ),
  )
  assert_eq(policy.groups.length(), 1)
  assert_eq(policy.groups[0].agents, ["goodbot"])
  assert_eq(policy.groups[0].rules.length(), 1)
  assert_eq(policy.diagnostics.length(), 4)
}

///|
test "empty allow and disallow records impose no rule" {
  let policy = @moonrobots.parse(
    (
      #|User-agent: *
      #|Disallow:
      #|Allow:   # empty
    ),
  )
  assert_eq(policy.groups.length(), 1)
  assert_eq(policy.groups[0].rules.length(), 0)
}

///|
test "empty user-agent is diagnosed and ignored" {
  let policy = @moonrobots.parse("User-agent:\nDisallow: /private\n")
  assert_eq(policy.groups.length(), 0)
  assert_eq(policy.diagnostics.length(), 2)
  assert_eq(policy.diagnostics[0].code, "invalid-user-agent")
  assert_eq(policy.diagnostics[1].code, "orphan-rule")
}
