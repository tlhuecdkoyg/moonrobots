///|
test "analysis calculates policy statistics" {
  let source =
    #|User-agent: *
    #|Disallow: /private/*
    #|Allow: /private/public$
    #|Sitemap: https://example.com/sitemap.xml
  let result = @moonrobots.analyze(source)
  assert_eq(result.stats.source_lines, 4)
  assert_eq(result.stats.group_count, 1)
  assert_eq(result.stats.agent_count, 1)
  assert_eq(result.stats.rule_count, 2)
  assert_eq(result.stats.allow_count, 1)
  assert_eq(result.stats.disallow_count, 1)
  assert_eq(result.stats.wildcard_count, 1)
  assert_eq(result.stats.anchored_count, 1)
  assert_eq(result.stats.sitemap_count, 1)
  assert_eq(result.score, 100)
  assert_eq(result.grade, "A+")
}

///|
test "analysis reports duplicate and contradictory rules" {
  let source =
    #|User-agent: ExampleBot
    #|Disallow: /draft
    #|Disallow: /draft
    #|Allow: /draft
  let result = @moonrobots.analyze(source)
  let codes = result.findings.map(fn(item) { item.code })
  assert_true(codes.contains("duplicate-rule"))
  assert_true(codes.contains("allow-disallow-tie"))
  assert_true(codes.contains("no-wildcard-group"))
  assert_true(result.score < 100)
}

///|
test "analysis reports broad policy and unusual patterns" {
  let source =
    #|User-agent: *
    #|Disallow: /
    #|Allow: relative
    #|Disallow: /price$draft
  let result = @moonrobots.analyze(source)
  let codes = result.findings.map(fn(item) { item.code })
  assert_true(codes.contains("site-wide-disallow"))
  assert_true(codes.contains("non-root-pattern"))
  assert_true(codes.contains("misplaced-anchor"))
}

///|
test "analysis reports split groups and empty groups" {
  let source =
    #|User-agent: Bot
    #|Disallow:
    #|User-agent: Bot
    #|Allow: /public
  let result = @moonrobots.analyze(source)
  let codes = result.findings.map(fn(item) { item.code })
  assert_true(codes.contains("empty-group"))
  assert_true(codes.contains("split-agent-group"))
}

///|
test "analysis reports sitemap quality" {
  let source =
    #|User-agent: *
    #|Allow: /
    #|Sitemap: sitemap.xml
    #|Sitemap: sitemap.xml
  let result = @moonrobots.analyze(source)
  let codes = result.findings.map(fn(item) { item.code })
  assert_true(codes.contains("relative-sitemap"))
  assert_true(codes.contains("duplicate-sitemap"))
}

///|
test "trace explains selection and discarded candidates" {
  let source =
    #|User-agent: *
    #|Disallow: /private
    #|Disallow: /private/public
    #|Allow: /private/public
    #|Allow: /other
  let trace = @moonrobots.evaluate_with_trace(
    @moonrobots.parse(source),
    "ExampleBot",
    "/private/public/page",
  )
  assert_true(trace.decision.allowed)
  assert_eq(trace.selected_agents, ["*"])
  assert_eq(trace.candidates.length(), 4)
  assert_eq(trace.candidates[0].status, @moonrobots.LessSpecific)
  assert_eq(trace.candidates[1].status, @moonrobots.LostAllowTie)
  assert_eq(trace.candidates[2].status, @moonrobots.Selected)
  assert_eq(trace.candidates[3].status, @moonrobots.NotMatched)
}

///|
test "public pattern matcher reports specificity" {
  let (matched, specificity) = @moonrobots.match_pattern(
    "/products/*.json$", "/products/catalog.json",
  )
  assert_true(matched)
  assert_eq(specificity, 15)
}
