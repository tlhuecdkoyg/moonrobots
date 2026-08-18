///|
test "blog preset generates a parseable policy" {
  let generated = @moonrobots.generate_policy(
    @moonrobots.generator_preset("blog", "https://example.com/"),
  )
  assert_eq(generated.group_count, 1)
  assert_eq(generated.rule_count, 4)
  assert_eq(generated.sitemap_count, 1)
  assert_eq(generated.warnings.length(), 0)
  assert_true(generated.source.contains("Disallow: /admin/"))
  assert_true(
    generated.source.contains("Sitemap: https://example.com/sitemap.xml"),
  )
  assert_eq(@moonrobots.parse(generated.source).diagnostics.length(), 0)
}

///|
test "commerce preset deduplicates and normalizes output" {
  let config = @moonrobots.generator_preset("commerce", "https://shop.example/")
  let generated = @moonrobots.generate_policy(config)
  assert_true(generated.source.contains("Disallow: /*?sort="))
  assert_true(generated.source.contains("Allow: /products/"))
  assert_eq(generated.sitemap_count, 2)
  assert_false(generated.source.contains("https://shop.example//"))
}

///|
test "generator supports crawler-specific groups" {
  let config : @moonrobots.GeneratorConfig = {
    site_origin: "https://example.com",
    project_name: "Agent policy",
    default_disallow_paths: ["tmp", "tmp"],
    default_allow_paths: [],
    agent_groups: [
      {
        agents: ["ArchiveBot", "ArchiveBot"],
        disallow_paths: ["drafts"],
        allow_paths: ["drafts/public"],
      },
    ],
    sitemap_paths: ["sitemap.xml", "sitemap.xml"],
    include_header: true,
    include_guidance: true,
  }
  let generated = @moonrobots.generate_policy(config)
  assert_eq(generated.group_count, 2)
  assert_eq(generated.rule_count, 3)
  assert_eq(generated.sitemap_count, 1)
  assert_eq(generated.source.split("User-agent: archivebot").count(), 2)
  assert_true(generated.source.contains("Disallow: /drafts"))
}

///|
test "generator warns about risky configuration" {
  let config : @moonrobots.GeneratorConfig = {
    site_origin: "http://example.com/",
    project_name: "Warnings",
    default_disallow_paths: [],
    default_allow_paths: ["public"],
    agent_groups: [{ agents: ["Bad Bot"], disallow_paths: [], allow_paths: [] }],
    sitemap_paths: [],
    include_header: false,
    include_guidance: false,
  }
  let generated = @moonrobots.generate_policy(config)
  assert_true(generated.warnings.length() >= 2)
  assert_true(
    generated.warnings.contains(
      "Consider using HTTPS for the site origin and sitemap URLs.",
    ),
  )
  assert_true(generated.source.has_prefix("User-agent: *"))
}

///|
test "generated policy Markdown includes warnings and output" {
  let generated = @moonrobots.generate_policy(
    @moonrobots.generator_preset("private", ""),
  )
  let markdown = @moonrobots.generated_policy_to_markdown(generated)
  assert_true(markdown.has_prefix("# Generated robots.txt"))
  assert_true(markdown.contains("## Review warnings"))
  assert_true(markdown.contains("Disallow: /"))
}
