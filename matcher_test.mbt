///|
test "longest match wins and allow wins an equivalent tie" {
  let robots =
    #|User-agent: *
    #|Disallow: /folder
    #|Allow: /folder/public
    #|Disallow: /same
    #|Allow: /same
  assert_false(@moonrobots.is_allowed(robots, "AnyBot", "/folder/private"))
  assert_true(@moonrobots.is_allowed(robots, "AnyBot", "/folder/public/page"))
  assert_true(@moonrobots.is_allowed(robots, "AnyBot", "/same"))
}

///|
test "exact agent groups override wildcard groups and repeated groups merge" {
  let robots =
    #|User-agent: *
    #|Disallow: /
    #|User-agent: ExampleBot
    #|Allow: /first
    #|User-agent: ExampleBot
    #|Disallow: /second
  assert_true(@moonrobots.is_allowed(robots, "examplebot", "/first"))
  assert_false(@moonrobots.is_allowed(robots, "EXAMPLEBOT", "/second"))
  assert_true(@moonrobots.is_allowed(robots, "examplebot", "/other"))
  assert_false(@moonrobots.is_allowed(robots, "otherbot", "/anything"))
}

///|
test "wildcard and end anchor matching" {
  let robots =
    #|User-agent: *
    #|Disallow: /*.gif$
    #|Allow: /public/*.gif$
  assert_false(@moonrobots.is_allowed(robots, "bot", "/image.gif"))
  assert_true(@moonrobots.is_allowed(robots, "bot", "/image.gif?size=2"))
  assert_true(@moonrobots.is_allowed(robots, "bot", "/public/image.gif"))
}

///|
test "URI extraction excludes authority and fragment but includes query" {
  assert_eq(
    @moonrobots.path_from_uri("https://example.com/a/b?q=1#fragment"),
    "/a/b?q=1",
  )
  assert_eq(@moonrobots.path_from_uri("https://example.com"), "/")
  assert_eq(@moonrobots.path_from_uri("https://example.com?q=1"), "/?q=1")
}

///|
test "percent encoded unreserved octets and UTF-8 compare canonically" {
  let robots =
    #|User-agent: *
    #|Disallow: /foo/bar
    #|Disallow: /caf%C3%A9
  assert_false(@moonrobots.is_allowed(robots, "bot", "/foo/%62ar"))
  assert_false(@moonrobots.is_allowed(robots, "bot", "/café"))
}

///|
test "robots.txt itself is implicitly allowed" {
  let robots = "User-agent: *\nDisallow: /\n"
  assert_true(@moonrobots.is_allowed(robots, "bot", "/robots.txt"))
}

///|
test "an explicit empty group does not fall back to wildcard restrictions" {
  let robots =
    #|User-agent: *
    #|Disallow: /
    #|User-agent: FriendlyBot
    #|Disallow:
  assert_true(@moonrobots.is_allowed(robots, "friendlybot", "/private"))
  assert_false(@moonrobots.is_allowed(robots, "otherbot", "/private"))
}

///|
test "path matching is case sensitive" {
  let robots = "User-agent: *\nDisallow: /Private\n"
  assert_false(@moonrobots.is_allowed(robots, "bot", "/Private/file"))
  assert_true(@moonrobots.is_allowed(robots, "bot", "/private/file"))
}

///|
test "malformed percent escapes remain literal" {
  let robots = "User-agent: *\nDisallow: /bad%2G\n"
  assert_false(@moonrobots.is_allowed(robots, "bot", "/bad%2G/file"))
  assert_true(@moonrobots.is_allowed(robots, "bot", "/bad%20/file"))
}

///|
test "a trailing wildcard may match an empty suffix" {
  let robots = "User-agent: *\nDisallow: /download*\n"
  assert_false(@moonrobots.is_allowed(robots, "bot", "/download"))
  assert_false(@moonrobots.is_allowed(robots, "bot", "/downloads/file"))
}

///|
test "multiple wildcards backtrack across path segments" {
  let robots = "User-agent: *\nDisallow: /a*b*c$\n"
  assert_false(@moonrobots.is_allowed(robots, "bot", "/a/one/b/two/c"))
  assert_true(@moonrobots.is_allowed(robots, "bot", "/a/one/b/two/c/more"))
}

///|
test "lowercase percent hex and relative paths are normalized" {
  let robots = "User-agent: *\nDisallow: /caf%C3%A9\nDisallow: /plain\n"
  assert_false(@moonrobots.is_allowed(robots, "bot", "/caf%c3%a9"))
  assert_false(@moonrobots.is_allowed(robots, "bot", "plain"))
}
