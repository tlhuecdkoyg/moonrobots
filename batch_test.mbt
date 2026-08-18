///|
test "batch evaluation ignores blanks and comments" {
  let policy = @moonrobots.parse("User-agent: *\nDisallow: /private\n")
  let report = @moonrobots.evaluate_batch(
    policy, "ExampleBot", "/public\n\n# note\n/private/data\nbad path\n/robots.txt\n",
  )
  assert_eq(report.results.length(), 3)
  assert_eq(report.allowed_count, 2)
  assert_eq(report.disallowed_count, 1)
  assert_eq(report.invalid_count, 1)
}

///|
test "access matrix compares crawler-specific policies" {
  let policy = @moonrobots.parse(
    (
      #|User-agent: *
      #|Disallow: /shared
      #|User-agent: FriendlyBot
      #|Allow: /
    ),
  )
  let matrix = @moonrobots.build_access_matrix(
    policy, "FriendlyBot\nOtherBot", "/shared\n/public",
  )
  assert_eq(matrix.product_tokens.length(), 2)
  assert_eq(matrix.uris.length(), 2)
  assert_eq(matrix.cells.length(), 4)
  assert_eq(matrix.allowed_count, 3)
  assert_eq(matrix.disallowed_count, 1)
}

///|
test "suggested paths include boundaries and wildcard expansions" {
  let policy = @moonrobots.parse(
    "User-agent: *\nDisallow: /files/*.pdf$\nAllow: /public/\n",
  )
  let paths = @moonrobots.suggest_test_paths(policy)
  assert_true(paths.contains("/"))
  assert_true(paths.contains("/robots.txt"))
  assert_true(paths.contains("/files/.pdf"))
  assert_true(paths.contains("/files/sample.pdf"))
  assert_true(paths.contains("/public/moonrobots-child"))
}

///|
test "batch CSV quotes special values" {
  let policy = @moonrobots.parse("User-agent: *\nAllow: /\n")
  let report = @moonrobots.evaluate_batch(
    policy, "ExampleBot", "/products?id=1,2",
  )
  let csv = @moonrobots.batch_to_csv(report)
  assert_true(csv.has_prefix("index,product_token,uri"))
  assert_true(csv.contains("\"/products?id=1,2\""))
}

///|
test "batch Markdown contains decisions and summary" {
  let policy = @moonrobots.parse("User-agent: *\nDisallow: /private\n")
  let report = @moonrobots.evaluate_batch(
    policy, "Bot", "/public\n/private/report",
  )
  let markdown = @moonrobots.batch_to_markdown(report)
  assert_true(markdown.contains("| 1 | `/public` | Allowed"))
  assert_true(markdown.contains("| 2 | `/private/report` | Disallowed"))
  assert_true(
    markdown.has_suffix("1 allowed, 1 disallowed, 0 invalid input lines.\n"),
  )
}
