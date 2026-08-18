///|
fn finding(
  severity : Severity,
  category : FindingCategory,
  code : String,
  title : String,
  message : String,
  lines : Array[Int],
  suggestion : String,
) -> Finding {
  { severity, category, code, title, message, lines, suggestion }
}

///|
fn count_source_lines(text : String) -> Int {
  if text.is_empty() {
    0
  } else {
    text.split("\n").length()
  }
}

///|
fn pattern_has_wildcard(pattern : String) -> Bool {
  pattern.contains("*")
}

///|
fn pattern_is_anchored(pattern : String) -> Bool {
  pattern.has_suffix("$")
}

///|
fn pattern_is_broad(pattern : String) -> Bool {
  pattern == "/" || pattern == "/*" || pattern == "/*$"
}

///|
fn same_agents(left : Array[String], right : Array[String]) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for agent in left {
    if !right.contains(agent) {
      return false
    }
  }
  true
}

///|
fn contains_wildcard_agent(group : Group) -> Bool {
  group.agents.contains("*")
}

///|
fn contains_exact_agent(policy : Policy) -> Bool {
  for group in policy.groups {
    for agent in group.agents {
      if agent != "*" {
        return true
      }
    }
  }
  false
}

///|
fn collect_parser_findings(policy : Policy, findings : Array[Finding]) -> Unit {
  for diagnostic in policy.diagnostics {
    findings.push(
      finding(
        diagnostic.severity,
        Syntax,
        diagnostic.code,
        "Parser diagnostic",
        diagnostic.message,
        [diagnostic.line],
        "Correct or remove the record on this source line.",
      ),
    )
  }
}

///|
fn collect_empty_group_findings(
  policy : Policy,
  findings : Array[Finding],
) -> Unit {
  for group in policy.groups {
    if group.rules.length() == 0 {
      findings.push(
        finding(
          Warning,
          Maintainability,
          "empty-group",
          "User-agent group has no rules",
          "This group selects one or more crawlers but does not contain an effective Allow or Disallow rule.",
          [group.line],
          "Add an intentional rule or document why this group overrides wildcard restrictions.",
        ),
      )
    }
  }
}

///|
fn collect_duplicate_group_findings(
  policy : Policy,
  findings : Array[Finding],
) -> Unit {
  for i = 0; i < policy.groups.length(); i = i + 1 {
    for j = i + 1; j < policy.groups.length(); j = j + 1 {
      let left = policy.groups[i]
      let right = policy.groups[j]
      if same_agents(left.agents, right.agents) {
        findings.push(
          finding(
            Warning,
            Maintainability,
            "split-agent-group",
            "Equivalent User-agent groups are split",
            "RFC matching merges groups with the same product token, but maintaining them separately makes the effective policy harder to review.",
            [left.line, right.line],
            "Combine these records into one adjacent User-agent group.",
          ),
        )
      }
    }
  }
}

///|
fn collect_duplicate_rule_findings(
  policy : Policy,
  findings : Array[Finding],
) -> Unit {
  for group in policy.groups {
    for i = 0; i < group.rules.length(); i = i + 1 {
      for j = i + 1; j < group.rules.length(); j = j + 1 {
        let left = group.rules[i]
        let right = group.rules[j]
        if left.kind == right.kind && left.pattern == right.pattern {
          findings.push(
            finding(
              Warning,
              Redundancy,
              "duplicate-rule",
              "Duplicate path rule",
              "The same rule appears more than once in an equivalent group and cannot change the decision.",
              [left.line, right.line],
              "Keep one copy of the rule.",
            ),
          )
        } else if left.pattern == right.pattern && left.kind != right.kind {
          findings.push(
            finding(
              Warning,
              Correctness,
              "allow-disallow-tie",
              "Allow and Disallow use the same pattern",
              "Both records have identical specificity. RFC 9309 resolves the tie in favor of Allow.",
              [left.line, right.line],
              "Remove the losing Disallow rule or make the intended boundary more specific.",
            ),
          )
        }
      }
    }
  }
}

///|
fn collect_pattern_findings(policy : Policy, findings : Array[Finding]) -> Unit {
  for group in policy.groups {
    for rule in group.rules {
      if !rule.pattern.has_prefix("/") && !rule.pattern.has_prefix("*") {
        findings.push(
          finding(
            Warning,
            Correctness,
            "non-root-pattern",
            "Path pattern does not begin at the root",
            "Most robots path rules begin with '/'. This record is valid input but is unlikely to match a normalized request path.",
            [rule.line],
            "Prefix the pattern with '/' if it is intended to match a URL path.",
          ),
        )
      }
      if rule.pattern.contains("$") && !rule.pattern.has_suffix("$") {
        findings.push(
          finding(
            Warning,
            Correctness,
            "misplaced-anchor",
            "End anchor is not at the end",
            "The '$' extension is only treated as an end anchor when it is the final character.",
            [rule.line],
            "Move '$' to the final position or percent-encode a literal dollar sign.",
          ),
        )
      }
      if rule.kind == Disallow && pattern_is_broad(rule.pattern) {
        findings.push(
          finding(
            Warning,
            Security,
            "site-wide-disallow",
            "Rule blocks nearly the entire site",
            "A broad Disallow can remove most public pages from search and archival crawlers.",
            [rule.line],
            "Confirm this is intentional and add narrow Allow exceptions where required.",
          ),
        )
      }
      if rule.pattern.length() > 256 {
        findings.push(
          finding(
            Warning,
            Maintainability,
            "long-pattern",
            "Unusually long path pattern",
            "Long patterns are difficult to audit and may have been copied from a complete URL by mistake.",
            [rule.line],
            "Use the shortest path pattern that expresses the intended boundary.",
          ),
        )
      }
    }
  }
}

///|
fn collect_agent_findings(policy : Policy, findings : Array[Finding]) -> Unit {
  let mut has_wildcard = false
  for group in policy.groups {
    if contains_wildcard_agent(group) {
      has_wildcard = true
    }
    if group.agents.length() > 8 {
      findings.push(
        finding(
          Warning,
          Maintainability,
          "large-agent-group",
          "Group contains many product tokens",
          "Large groups are easy to edit incorrectly and difficult to scan during review.",
          [group.line],
          "Consider documenting why these crawlers share exactly the same policy.",
        ),
      )
    }
  }
  if !has_wildcard && contains_exact_agent(policy) {
    findings.push(
      finding(
        Warning,
        Maintainability,
        "no-wildcard-group",
        "No fallback User-agent group",
        "Unlisted crawlers receive the RFC default allow behavior because no User-agent: * group exists.",
        [],
        "Add an explicit wildcard group if unknown crawlers should follow a shared policy.",
      ),
    )
  }
}

///|
fn collect_sitemap_findings(policy : Policy, findings : Array[Finding]) -> Unit {
  for i = 0; i < policy.sitemaps.length(); i = i + 1 {
    let sitemap = policy.sitemaps[i]
    if !(sitemap.has_prefix("https://") || sitemap.has_prefix("http://")) {
      findings.push(
        finding(
          Warning,
          Correctness,
          "relative-sitemap",
          "Sitemap is not an absolute HTTP URL",
          "Crawler support is most reliable when Sitemap records contain an absolute URL.",
          [],
          "Use an absolute https:// URL.",
        ),
      )
    }
    for j = i + 1; j < policy.sitemaps.length(); j = j + 1 {
      if sitemap == policy.sitemaps[j] {
        findings.push(
          finding(
            Warning,
            Redundancy,
            "duplicate-sitemap",
            "Duplicate Sitemap record",
            "The same sitemap URL is declared more than once.",
            [],
            "Keep one copy of the Sitemap record.",
          ),
        )
      }
    }
  }
}

///|
fn calculate_stats(
  text : String,
  policy : Policy,
  finding_count : Int,
) -> PolicyStats {
  let mut agents = 0
  let mut rules = 0
  let mut allows = 0
  let mut disallows = 0
  let mut wildcards = 0
  let mut anchors = 0
  for group in policy.groups {
    agents = agents + group.agents.length()
    rules = rules + group.rules.length()
    for rule in group.rules {
      match rule.kind {
        Allow => allows = allows + 1
        Disallow => disallows = disallows + 1
      }
      if pattern_has_wildcard(rule.pattern) {
        wildcards = wildcards + 1
      }
      if pattern_is_anchored(rule.pattern) {
        anchors = anchors + 1
      }
    }
  }
  {
    source_lines: count_source_lines(text),
    source_bytes: text.length(),
    group_count: policy.groups.length(),
    agent_count: agents,
    rule_count: rules,
    allow_count: allows,
    disallow_count: disallows,
    sitemap_count: policy.sitemaps.length(),
    wildcard_count: wildcards,
    anchored_count: anchors,
    diagnostic_count: policy.diagnostics.length(),
    finding_count,
  }
}

///|
fn calculate_score(findings : Array[Finding]) -> Int {
  let mut score = 100
  for item in findings {
    let penalty = match item.severity {
      Error => 15
      Warning =>
        match item.category {
          Correctness => 8
          Security => 7
          Syntax => 6
          Redundancy => 3
          Maintainability => 3
        }
    }
    score = score - penalty
  }
  if score < 0 {
    0
  } else {
    score
  }
}

///|
fn grade_for_score(score : Int) -> String {
  if score >= 95 {
    "A+"
  } else if score >= 90 {
    "A"
  } else if score >= 80 {
    "B"
  } else if score >= 70 {
    "C"
  } else if score >= 60 {
    "D"
  } else {
    "F"
  }
}

///|
/// Perform static analysis beyond syntax parsing and calculate dashboard data.
pub fn analyze(text : String) -> PolicyAnalysis {
  let policy = parse(text)
  let findings : Array[Finding] = []
  collect_parser_findings(policy, findings)
  collect_empty_group_findings(policy, findings)
  collect_duplicate_group_findings(policy, findings)
  collect_duplicate_rule_findings(policy, findings)
  collect_pattern_findings(policy, findings)
  collect_agent_findings(policy, findings)
  collect_sitemap_findings(policy, findings)
  let score = calculate_score(findings)
  {
    policy,
    stats: calculate_stats(text, policy, findings.length()),
    findings,
    score,
    grade: grade_for_score(score),
  }
}
