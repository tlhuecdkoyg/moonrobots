///|
test "coverage counts matched selected and unused rules" {
  let policy = @moonrobots.parse(
    (
      #|User-agent: *
      #|Disallow: /private
      #|Allow: /private/public
      #|Disallow: /never-sampled
    ),
  )
  let report = @moonrobots.analyze_rule_coverage(
    policy, "Bot", "/\n/private/report\n/private/public/page",
  )
  assert_eq(report.sample_count, 3)
  assert_eq(report.rule_count, 3)
  assert_eq(report.exercised_count, 2)
  assert_eq(report.selected_rule_count, 2)
  assert_eq(report.unused_rule_count, 1)
  assert_eq(report.coverage_percent, 66)
  assert_eq(report.usages[0].matched_count, 2)
  assert_eq(report.usages[0].selected_count, 1)
  assert_eq(report.usages[1].selected_count, 1)
}

///|
test "coverage identifies a shadowed matching rule" {
  let policy = @moonrobots.parse(
    "User-agent: *\nDisallow: /private\nAllow: /private/public\n",
  )
  let report = @moonrobots.analyze_rule_coverage(
    policy, "Bot", "/private/public/page",
  )
  assert_eq(report.shadowed_rule_count, 1)
  assert_eq(report.usages[0].matched_count, 1)
  assert_eq(report.usages[0].selected_count, 0)
  assert_eq(report.usages[1].selected_count, 1)
}

///|
test "suggested coverage exercises generated boundaries" {
  let policy = @moonrobots.parse(
    "User-agent: *\nDisallow: /private\nAllow: /private/public\n",
  )
  let report = @moonrobots.analyze_suggested_coverage(policy, "Bot")
  assert_true(report.sample_count >= 4)
  assert_eq(report.coverage_percent, 100)
}

///|
test "coverage Markdown includes empirical warning" {
  let report = @moonrobots.analyze_rule_coverage(
    @moonrobots.parse("User-agent: *\nDisallow: /private\n"),
    "Bot",
    "/private",
  )
  let markdown = @moonrobots.coverage_to_markdown(report)
  assert_true(markdown.has_prefix("# robots.txt rule coverage"))
  assert_true(markdown.contains("**100%**"))
  assert_true(markdown.contains("sample-driven coverage"))
}

///|
test "sample path filters separate defaults and blocks" {
  let policy = @moonrobots.parse("User-agent: *\nDisallow: /private\n")
  let samples = "/\n/public\n/private/report\n/robots.txt"
  assert_eq(@moonrobots.default_allowed_paths(policy, "Bot", samples), [
    "/", "/public", "/robots.txt",
  ])
  assert_eq(@moonrobots.blocked_sample_paths(policy, "Bot", samples), [
    "/private/report",
  ])
}
