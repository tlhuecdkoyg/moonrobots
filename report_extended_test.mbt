///|
test "extended terminal analysis includes score and findings" {
  let report = @moonrobots.format_analysis(
    @moonrobots.analyze("User-agent: *\nDisallow: /\nDisallow: /\n"),
  )
  assert_true(report.has_prefix("MoonRobots policy analysis"))
  assert_true(report.contains("Health:"))
  assert_true(report.contains("duplicate-rule"))
  assert_true(report.contains("site-wide-disallow"))
}

///|
test "extended trace names selected and losing rules" {
  let trace = @moonrobots.evaluate_with_trace(
    @moonrobots.parse(
      "User-agent: *\nDisallow: /private\nAllow: /private/public\n",
    ),
    "Bot",
    "/private/public/page",
  )
  let report = @moonrobots.format_trace(trace)
  assert_true(report.contains("Selected agents: *"))
  assert_true(report.contains("less specific"))
  assert_true(report.contains("> L3 Allow: /private/public"))
}

///|
test "analysis Markdown includes normalized policy" {
  let report = @moonrobots.analysis_to_markdown(
    @moonrobots.analyze("user-agent: Bot\nallow: /public\n"),
  )
  assert_true(report.has_prefix("# MoonRobots policy audit"))
  assert_true(report.contains("| Product tokens | 1 |"))
  assert_true(report.contains("User-agent: bot\nAllow: /public"))
}

///|
test "access matrix Markdown renders all cells" {
  let matrix = @moonrobots.build_access_matrix(
    @moonrobots.parse("User-agent: *\nDisallow: /private\n"),
    "BotA\nBotB",
    "/\n/private",
  )
  let report = @moonrobots.access_matrix_to_markdown(matrix)
  assert_true(report.contains("| BotA | `/private` | Disallowed"))
  assert_true(report.contains("| BotB | `/` | Allowed"))
  assert_true(report.has_suffix("2 allowed and 2 disallowed cells.\n"))
}

///|
test "trace Markdown renders candidate table" {
  let trace = @moonrobots.evaluate_with_trace(
    @moonrobots.parse("User-agent: *\nDisallow: /private\n"),
    "Bot",
    "/private",
  )
  let report = @moonrobots.trace_to_markdown(trace)
  assert_true(report.has_prefix("# robots.txt decision trace"))
  assert_true(report.contains("| 2 | Disallow | `/private` | 8 | selected |"))
}
