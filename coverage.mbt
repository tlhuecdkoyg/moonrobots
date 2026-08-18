///|
fn empty_usage(rule : Rule) -> RuleUsage {
  {
    kind: rule.kind,
    pattern: rule.pattern,
    line: rule.line,
    considered_count: 0,
    matched_count: 0,
    selected_count: 0,
    allow_decision_count: 0,
    disallow_decision_count: 0,
  }
}

///|
fn collect_rule_usages(policy : Policy) -> Array[RuleUsage] {
  let usages : Array[RuleUsage] = []
  for group in policy.groups {
    for rule in group.rules {
      let mut exists = false
      for usage in usages {
        if usage.line == rule.line {
          exists = true
        }
      }
      if !exists {
        usages.push(empty_usage(rule))
      }
    }
  }
  usages
}

///|
fn update_candidate_usage(
  usages : Array[RuleUsage],
  candidate : RuleCandidate,
  decision : Decision,
) -> Unit {
  for index, old in usages {
    if old.line == candidate.line {
      let selected = candidate.status == Selected
      let matched_increment = if candidate.matched { 1 } else { 0 }
      let selected_increment = if selected { 1 } else { 0 }
      let allow_decisions = if selected && decision.allowed { 1 } else { 0 }
      let disallow_decisions = if selected && !decision.allowed { 1 } else { 0 }
      usages[index] = {
        kind: old.kind,
        pattern: old.pattern,
        line: old.line,
        considered_count: old.considered_count + 1,
        matched_count: old.matched_count + matched_increment,
        selected_count: old.selected_count + selected_increment,
        allow_decision_count: old.allow_decision_count + allow_decisions,
        disallow_decision_count: old.disallow_decision_count +
        disallow_decisions,
      }
      return
    }
  }
}

///|
fn finalize_coverage(
  product_token : String,
  sample_count : Int,
  usages : Array[RuleUsage],
) -> CoverageReport {
  let mut exercised = 0
  let mut selected = 0
  let mut unused = 0
  let mut shadowed = 0
  for usage in usages {
    if usage.matched_count > 0 {
      exercised = exercised + 1
    } else {
      unused = unused + 1
    }
    if usage.selected_count > 0 {
      selected = selected + 1
    } else if usage.matched_count > 0 {
      shadowed = shadowed + 1
    }
  }
  let percent = if usages.length() == 0 {
    100
  } else {
    exercised * 100 / usages.length()
  }
  {
    product_token,
    sample_count,
    rule_count: usages.length(),
    exercised_count: exercised,
    selected_rule_count: selected,
    unused_rule_count: unused,
    shadowed_rule_count: shadowed,
    coverage_percent: percent,
    usages,
  }
}

///|
/// Measure which rules are considered, matched and selected for sampled paths.
/// Coverage is empirical: a rule marked unused may still match an unsampled URL.
pub fn analyze_rule_coverage(
  policy : Policy,
  product_token : String,
  uri_lines : String,
) -> CoverageReport {
  let paths = parse_list(uri_lines)
  let usages = collect_rule_usages(policy)
  for path in paths {
    let trace = evaluate_with_trace(policy, product_token, path)
    for candidate in trace.candidates {
      update_candidate_usage(usages, candidate, trace.decision)
    }
  }
  finalize_coverage(product_token, paths.length(), usages)
}

///|
/// Run coverage using deterministic paths inferred from every policy rule.
pub fn analyze_suggested_coverage(
  policy : Policy,
  product_token : String,
) -> CoverageReport {
  let output = StringBuilder::new()
  let paths = suggest_test_paths(policy)
  for index, path in paths {
    if index > 0 {
      output.write_char('\n')
    }
    output.write_string(path)
  }
  analyze_rule_coverage(policy, product_token, output.to_string())
}

///|
fn usage_state(usage : RuleUsage) -> String {
  if usage.selected_count > 0 {
    "selected"
  } else if usage.matched_count > 0 {
    "shadowed"
  } else if usage.considered_count > 0 {
    "not matched"
  } else {
    "group not selected"
  }
}

///|
/// Render sample-based rule coverage as a Markdown report.
pub fn coverage_to_markdown(report : CoverageReport) -> String {
  let output = StringBuilder::new()
  output.write_string("# robots.txt rule coverage\n\n")
  output.write_string("- Product token: `\{report.product_token}`\n")
  output.write_string("- Samples: \{report.sample_count}\n")
  output.write_string(
    "- Exercised rules: \{report.exercised_count}/\{report.rule_count} (**\{report.coverage_percent}%**)\n",
  )
  output.write_string("- Selected rules: \{report.selected_rule_count}\n")
  output.write_string("- Shadowed rules: \{report.shadowed_rule_count}\n")
  output.write_string("- Unused rules: \{report.unused_rule_count}\n\n")
  output.write_string(
    "| Line | Kind | Pattern | Considered | Matched | Selected | Result |\n",
  )
  output.write_string("|---:|---|---|---:|---:|---:|---|\n")
  for usage in report.usages {
    output.write_string(
      "| \{usage.line} | \{kind_label(usage.kind)} | `\{usage.pattern}` | \{usage.considered_count} | \{usage.matched_count} | \{usage.selected_count} | \{usage_state(usage)} |\n",
    )
  }
  output.write_string(
    "\n> This is sample-driven coverage, not proof that an unmatched rule is unreachable.\n",
  )
  output.to_string()
}

///|
/// Return paths that did not select any explicit rule for the given crawler.
pub fn default_allowed_paths(
  policy : Policy,
  product_token : String,
  uri_lines : String,
) -> Array[String] {
  let paths : Array[String] = []
  for path in parse_list(uri_lines) {
    let decision = evaluate(policy, product_token, path)
    if decision.allowed && decision.matched is None {
      paths.push(path)
    }
  }
  paths
}

///|
/// Return disallowed paths grouped from a newline-separated sample.
pub fn blocked_sample_paths(
  policy : Policy,
  product_token : String,
  uri_lines : String,
) -> Array[String] {
  let paths : Array[String] = []
  for path in parse_list(uri_lines) {
    if !evaluate(policy, product_token, path).allowed {
      paths.push(path)
    }
  }
  paths
}
