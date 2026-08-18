///|
test "studio snapshot includes every dashboard section" {
  let snapshot = @moonrobots.studio_snapshot(
    "User-agent: *\nDisallow: /private\n", "ExampleBot", "/private/report", "/\n/private/report",
  )
  assert_true(snapshot.has_prefix("{\"schemaVersion\":1,"))
  assert_true(snapshot.contains("\"stats\":"))
  assert_true(snapshot.contains("\"decision\":{"))
  assert_true(snapshot.contains("\"allowed\":false"))
  assert_true(snapshot.contains("\"trace\":{"))
  assert_true(snapshot.contains("\"findings\":"))
  assert_true(snapshot.contains("\"groups\":"))
  assert_true(snapshot.contains("\"suggestedPaths\":"))
  assert_true(snapshot.contains("\"formatted\":"))
  assert_true(snapshot.contains("\"batch\":{"))
  assert_true(snapshot.contains("\"fixPlan\":{"))
  assert_true(snapshot.contains("\"coverage\":{"))
}

///|
test "studio snapshot escapes untrusted strings as JSON" {
  let snapshot = @moonrobots.studio_snapshot(
    "User-agent: *\nDisallow: /quoted\\\"path\n", "Bot", "/quoted\\\"path?line=one\ntwo",
    "/quoted\\\"path",
  )
  assert_true(snapshot.contains("\\\\\\\""))
  assert_true(snapshot.contains("\\n"))
}
