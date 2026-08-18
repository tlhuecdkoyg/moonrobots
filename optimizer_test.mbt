///|
test "fix plan separates safe and review edits" {
  let source =
    #|User-agent: Bot
    #|User-agent: Bot
    #|Disallow: /draft
    #|Disallow: /draft
    #|Allow: relative
    #|Sitemap: sitemap.xml
    #|Sitemap: sitemap.xml
    #|Vendor-rule: enabled
  let plan = @moonrobots.build_fix_plan(source)
  assert_eq(plan.safe_count, 3)
  assert_eq(plan.review_count, 3)
  let codes = plan.edits.map(fn(edit) { edit.code })
  assert_true(codes.contains("remove-duplicate-agent"))
  assert_true(codes.contains("remove-duplicate-rule"))
  assert_true(codes.contains("remove-duplicate-sitemap"))
  assert_true(codes.contains("prefix-root-slash"))
  assert_true(codes.contains("absolute-sitemap"))
  assert_true(codes.contains("remove-unknown-record"))
}

///|
test "safe fixes preserve access decisions" {
  let source =
    #|User-agent: *
    #|Disallow: /private
    #|Disallow: /private
    #|Allow: /public
    #|Sitemap: https://example.com/sitemap.xml
    #|Sitemap: https://example.com/sitemap.xml
  let fixed = @moonrobots.apply_safe_fixes(source)
  assert_eq(
    fixed, "User-agent: *\nDisallow: /private\nAllow: /public\nSitemap: https://example.com/sitemap.xml\n",
  )
  for path in ["/", "/private/data", "/public/page", "/robots.txt"] {
    assert_eq(
      @moonrobots.is_allowed(source, "Bot", path),
      @moonrobots.is_allowed(fixed, "Bot", path),
    )
  }
}

///|
test "review fixes are opt in" {
  let source = "User-agent: *\nDisallow: relative\n"
  let plan = @moonrobots.build_fix_plan(source)
  assert_eq(@moonrobots.apply_fix_plan(source, plan, false), source)
  assert_eq(
    @moonrobots.apply_fix_plan(source, plan, true),
    "User-agent: *\nDisallow: /relative\n",
  )
}

///|
test "trailing whitespace cleanup retains comments" {
  let source = "User-agent: *   \nDisallow: /private # keep this   \n"
  let fixed = @moonrobots.apply_safe_fixes(source)
  assert_eq(fixed, "User-agent: *\nDisallow: /private # keep this\n")
}

///|
test "fix plan markdown is reviewable" {
  let plan = @moonrobots.build_fix_plan(
    "User-agent: *\nDisallow: /private\nDisallow: /private\n",
  )
  let markdown = @moonrobots.fix_plan_to_markdown(plan)
  assert_true(markdown.has_prefix("# MoonRobots fix plan"))
  assert_true(markdown.contains("**SAFE** line 3"))
  assert_true(markdown.contains("Remove duplicate rule"))
}
