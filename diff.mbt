///|
fn policy_change(
  kind : PolicyChangeKind,
  summary : String,
  detail : String,
  before_line : Int?,
  after_line : Int?,
  risk : Severity,
) -> PolicyChange {
  { kind, summary, detail, before_line, after_line, risk }
}

///|
fn kind_label(kind : RuleKind) -> String {
  match kind {
    Allow => "Allow"
    Disallow => "Disallow"
  }
}

///|
fn group_label(group : Group) -> String {
  let output = StringBuilder::new()
  for index, agent in group.agents {
    if index > 0 {
      output.write_string(", ")
    }
    output.write_string(agent)
  }
  output.to_string()
}

///|
fn find_equivalent_group(groups : Array[Group], wanted : Group) -> Group? {
  for group in groups {
    if same_agents(group.agents, wanted.agents) {
      return Some(group)
    }
  }
  None
}

///|
fn find_rule(rules : Array[Rule], wanted : Rule) -> Rule? {
  for rule in rules {
    if rule.kind == wanted.kind && rule.pattern == wanted.pattern {
      return Some(rule)
    }
  }
  None
}

///|
fn collect_group_changes(
  before : Policy,
  after : Policy,
  changes : Array[PolicyChange],
) -> Unit {
  for old_group in before.groups {
    if find_equivalent_group(after.groups, old_group) is None {
      changes.push(
        policy_change(
          GroupRemoved,
          "User-agent group removed",
          "The group for \{group_label(old_group)} no longer exists. Its crawlers may now fall back to a wildcard group or default allow.",
          Some(old_group.line),
          None,
          Warning,
        ),
      )
    }
  }
  for new_group in after.groups {
    if find_equivalent_group(before.groups, new_group) is None {
      changes.push(
        policy_change(
          GroupAdded,
          "User-agent group added",
          "A new policy group now applies to \{group_label(new_group)}.",
          None,
          Some(new_group.line),
          Warning,
        ),
      )
    }
  }
}

///|
fn collect_rule_changes(
  before : Policy,
  after : Policy,
  changes : Array[PolicyChange],
) -> Unit {
  for old_group in before.groups {
    guard find_equivalent_group(after.groups, old_group) is Some(new_group) else {
      continue
    }
    for old_rule in old_group.rules {
      if find_rule(new_group.rules, old_rule) is None {
        changes.push(
          policy_change(
            RuleRemoved,
            "\{kind_label(old_rule.kind)} rule removed",
            "\{group_label(old_group)} no longer contains '\{old_rule.pattern}'.",
            Some(old_rule.line),
            None,
            Warning,
          ),
        )
      }
    }
    for new_rule in new_group.rules {
      if find_rule(old_group.rules, new_rule) is None {
        changes.push(
          policy_change(
            RuleAdded,
            "\{kind_label(new_rule.kind)} rule added",
            "\{group_label(new_group)} now contains '\{new_rule.pattern}'.",
            None,
            Some(new_rule.line),
            Warning,
          ),
        )
      }
    }
  }
}

///|
fn string_array_contains(values : Array[String], wanted : String) -> Bool {
  values.contains(wanted)
}

///|
fn collect_sitemap_changes(
  before : Policy,
  after : Policy,
  changes : Array[PolicyChange],
) -> Unit {
  for sitemap in before.sitemaps {
    if !string_array_contains(after.sitemaps, sitemap) {
      changes.push(
        policy_change(
          SitemapRemoved,
          "Sitemap removed",
          sitemap,
          None,
          None,
          Warning,
        ),
      )
    }
  }
  for sitemap in after.sitemaps {
    if !string_array_contains(before.sitemaps, sitemap) {
      changes.push(
        policy_change(
          SitemapAdded,
          "Sitemap added",
          sitemap,
          None,
          None,
          Warning,
        ),
      )
    }
  }
}

///|
fn add_unique(values : Array[String], value : String) -> Unit {
  if !value.is_empty() && !values.contains(value) {
    values.push(value)
  }
}

///|
fn parse_list(text : String) -> Array[String] {
  let values : Array[String] = []
  for line in text.split("\n") {
    let value = line.to_owned().trim().to_owned()
    if !value.is_empty() && !value.has_prefix("#") {
      add_unique(values, value)
    }
  }
  values
}

///|
fn inferred_agents(before : Policy, after : Policy) -> Array[String] {
  let agents : Array[String] = []
  for policy in [before, after] {
    for group in policy.groups {
      for agent in group.agents {
        if agent != "*" {
          add_unique(agents, agent)
        }
      }
    }
  }
  add_unique(agents, "MoonRobotsBot")
  agents
}

///|
fn inferred_paths(before : Policy, after : Policy) -> Array[String] {
  let paths : Array[String] = []
  for path in suggest_test_paths(before) {
    add_unique(paths, path)
  }
  for path in suggest_test_paths(after) {
    add_unique(paths, path)
  }
  paths
}

///|
fn optional_matched_pattern(decision : Decision) -> String? {
  match decision.matched {
    Some(rule) => Some(rule.pattern)
    None => None
  }
}

///|
fn collect_decision_changes(
  before : Policy,
  after : Policy,
  agents : Array[String],
  paths : Array[String],
) -> (Array[DecisionChange], Int, Int, Int) {
  let decisions : Array[DecisionChange] = []
  let mut opened = 0
  let mut closed = 0
  let mut unchanged = 0
  for agent in agents {
    for path in paths {
      let old_decision = evaluate(before, agent, path)
      let new_decision = evaluate(after, agent, path)
      if old_decision.allowed == new_decision.allowed {
        unchanged = unchanged + 1
      } else {
        if new_decision.allowed {
          opened = opened + 1
        } else {
          closed = closed + 1
        }
        decisions.push({
          product_token: agent,
          uri: path,
          before_allowed: old_decision.allowed,
          after_allowed: new_decision.allowed,
          before_pattern: optional_matched_pattern(old_decision),
          after_pattern: optional_matched_pattern(new_decision),
        })
      }
    }
  }
  (decisions, opened, closed, unchanged)
}

///|
fn append_access_changes(
  decision_changes : Array[DecisionChange],
  changes : Array[PolicyChange],
) -> Unit {
  for decision in decision_changes {
    if decision.after_allowed {
      changes.push(
        policy_change(
          AccessOpened,
          "Crawler access opened",
          "\{decision.product_token} can now access \{decision.uri}.",
          None,
          None,
          Warning,
        ),
      )
    } else {
      changes.push(
        policy_change(
          AccessClosed,
          "Crawler access closed",
          "\{decision.product_token} can no longer access \{decision.uri}.",
          None,
          None,
          Warning,
        ),
      )
    }
  }
}

///|
/// Compare two policies structurally and simulate their behavior. When agent
/// or path lists are empty, deterministic cases are inferred from both files.
pub fn compare_policies(
  before_source : String,
  after_source : String,
  agent_lines : String,
  path_lines : String,
) -> PolicyDiff {
  let before = parse(before_source)
  let after = parse(after_source)
  let changes : Array[PolicyChange] = []
  collect_group_changes(before, after, changes)
  collect_rule_changes(before, after, changes)
  collect_sitemap_changes(before, after, changes)
  let requested_agents = parse_list(agent_lines)
  let requested_paths = parse_list(path_lines)
  let agents = if requested_agents.length() > 0 {
    requested_agents
  } else {
    inferred_agents(before, after)
  }
  let paths = if requested_paths.length() > 0 {
    requested_paths
  } else {
    inferred_paths(before, after)
  }
  let (decisions, opened, closed, unchanged) = collect_decision_changes(
    before, after, agents, paths,
  )
  append_access_changes(decisions, changes)
  {
    changes,
    decisions,
    opened_count: opened,
    closed_count: closed,
    unchanged_count: unchanged,
  }
}

///|
fn change_kind_text(kind : PolicyChangeKind) -> String {
  match kind {
    GroupAdded => "group-added"
    GroupRemoved => "group-removed"
    RuleAdded => "rule-added"
    RuleRemoved => "rule-removed"
    SitemapAdded => "sitemap-added"
    SitemapRemoved => "sitemap-removed"
    AccessOpened => "access-opened"
    AccessClosed => "access-closed"
  }
}

///|
/// Render a semantic comparison as Markdown for review or pull requests.
pub fn policy_diff_to_markdown(diff : PolicyDiff) -> String {
  let output = StringBuilder::new()
  output.write_string("# robots.txt semantic diff\n\n")
  output.write_string(
    "Behavior: **\{diff.opened_count} opened**, **\{diff.closed_count} closed**, \{diff.unchanged_count} unchanged sampled requests.\n\n",
  )
  output.write_string("## Structural and behavioral changes\n\n")
  if diff.changes.length() == 0 {
    output.write_string("No semantic changes detected.\n")
  }
  for change in diff.changes {
    output.write_string(
      "- **\{change_kind_text(change.kind)}**: \{change.summary} — \{change.detail}\n",
    )
  }
  if diff.decisions.length() > 0 {
    output.write_string("\n## Changed decisions\n\n")
    output.write_string("| Product token | Path | Before | After |\n")
    output.write_string("|---|---|---|---|\n")
    for decision in diff.decisions {
      let before_text = if decision.before_allowed {
        "Allowed"
      } else {
        "Disallowed"
      }
      let after_text = if decision.after_allowed {
        "Allowed"
      } else {
        "Disallowed"
      }
      output.write_string(
        "| \{decision.product_token} | `\{decision.uri}` | \{before_text} | \{after_text} |\n",
      )
    }
  }
  output.to_string()
}
