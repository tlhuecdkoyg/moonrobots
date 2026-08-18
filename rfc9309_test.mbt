///|
test "RFC 9309 section 5.1 simple example" {
  let robots =
    #|User-Agent: ExampleBot
    #|Disallow: /example/
    #|Disallow: /*.gif$
    #|Allow: /publications/
  assert_false(@moonrobots.is_allowed(robots, "ExampleBot", "/example/page"))
  assert_false(@moonrobots.is_allowed(robots, "ExampleBot", "/image.gif"))
  assert_true(@moonrobots.is_allowed(robots, "ExampleBot", "/image.gif?x=1"))
  assert_true(
    @moonrobots.is_allowed(robots, "ExampleBot", "/publications/book"),
  )
  assert_true(@moonrobots.is_allowed(robots, "OtherBot", "/example/page"))
}

///|
test "RFC 9309 matching groups with the same product token are combined" {
  let robots =
    #|User-agent: ExampleBot
    #|Disallow: /foo
    #|Disallow: /bar
    #|
    #|User-agent: ExampleBot
    #|Disallow: /baz
  assert_false(@moonrobots.is_allowed(robots, "examplebot", "/foo"))
  assert_false(@moonrobots.is_allowed(robots, "examplebot", "/bar"))
  assert_false(@moonrobots.is_allowed(robots, "examplebot", "/baz"))
}

///|
test "RFC 9309 wildcard group applies only when no exact group exists" {
  let robots =
    #|User-agent: *
    #|Disallow: /foo
    #|Disallow: /bar
    #|
    #|User-agent: BazBot
    #|Disallow: /baz
  assert_false(@moonrobots.is_allowed(robots, "ExampleBot", "/foo"))
  assert_true(@moonrobots.is_allowed(robots, "ExampleBot", "/baz"))
  assert_false(@moonrobots.is_allowed(robots, "BazBot", "/baz"))
  assert_true(@moonrobots.is_allowed(robots, "BazBot", "/foo"))
}

///|
test "RFC 9309 most specific octet match is used" {
  let robots =
    #|User-agent: *
    #|Disallow: /page
    #|Allow: /page/public
  let decision = @moonrobots.evaluate(
    @moonrobots.parse(robots),
    "bot",
    "/page/public/index",
  )
  assert_true(decision.allowed)
  guard decision.matched is Some(rule) else { fail("expected a matched rule") }
  assert_eq(rule.pattern, "/page/public")
}

///|
test "RFC 9309 parseable rules survive unsupported records" {
  let robots =
    #|User-agent: *
    #|Crawl-delay: 10
    #|Sitemap: https://example.com/sitemap.xml
    #|Disallow: /private
  let policy = @moonrobots.parse(robots)
  assert_false(@moonrobots.evaluate(policy, "bot", "/private").allowed)
  assert_eq(policy.sitemaps, ["https://example.com/sitemap.xml"])
  assert_eq(policy.diagnostics.length(), 1)
}

///|
test "query text participates in matching and fragments do not" {
  let robots = "User-agent: *\nDisallow: /search?q=secret\n"
  assert_false(
    @moonrobots.is_allowed(
      robots, "bot", "https://example.com/search?q=secret#result",
    ),
  )
  assert_true(@moonrobots.is_allowed(robots, "bot", "/search?q=public"))
}
