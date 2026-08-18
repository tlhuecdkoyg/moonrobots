///|
fn json_escape(value : String) -> String {
  let output = StringBuilder::new()
  for char in value {
    match char {
      '"' => output.write_string("\\\"")
      '\\' => output.write_string("\\\\")
      '\n' => output.write_string("\\n")
      '\r' => output.write_string("\\r")
      '\t' => output.write_string("\\t")
      '\u{08}' => output.write_string("\\b")
      '\u{0C}' => output.write_string("\\f")
      _ => output.write_char(char)
    }
  }
  output.to_string()
}

///|
fn json_string(value : String) -> String {
  "\"\{json_escape(value)}\""
}

///|
fn json_bool(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}

///|
fn json_optional_int(value : Int?) -> String {
  match value {
    Some(number) => number.to_string()
    None => "null"
  }
}

///|
fn json_optional_string(value : String?) -> String {
  match value {
    Some(text) => json_string(text)
    None => "null"
  }
}

///|
fn rule_kind_name(kind : RuleKind) -> String {
  match kind {
    Allow => "allow"
    Disallow => "disallow"
  }
}

///|
fn severity_name(severity : Severity) -> String {
  match severity {
    Warning => "warning"
    Error => "error"
  }
}

///|
fn category_name(category : FindingCategory) -> String {
  match category {
    Syntax => "syntax"
    Correctness => "correctness"
    Redundancy => "redundancy"
    Maintainability => "maintainability"
    Security => "security"
  }
}

///|
fn candidate_status_name(status : CandidateStatus) -> String {
  match status {
    Selected => "selected"
    Matched => "matched"
    NotMatched => "not-matched"
    LessSpecific => "less-specific"
    LostAllowTie => "lost-allow-tie"
  }
}

///|
fn write_string_array(output : StringBuilder, values : Array[String]) -> Unit {
  output.write_char('[')
  for index, value in values {
    if index > 0 {
      output.write_char(',')
    }
    output.write_string(json_string(value))
  }
  output.write_char(']')
}

///|
fn write_int_array(output : StringBuilder, values : Array[Int]) -> Unit {
  output.write_char('[')
  for index, value in values {
    if index > 0 {
      output.write_char(',')
    }
    output.write_string(value.to_string())
  }
  output.write_char(']')
}

///|
fn write_stats(output : StringBuilder, stats : PolicyStats) -> Unit {
  output.write_string("\"stats\":{")
  output.write_string("\"sourceLines\":\{stats.source_lines},")
  output.write_string("\"sourceBytes\":\{stats.source_bytes},")
  output.write_string("\"groups\":\{stats.group_count},")
  output.write_string("\"agents\":\{stats.agent_count},")
  output.write_string("\"rules\":\{stats.rule_count},")
  output.write_string("\"allows\":\{stats.allow_count},")
  output.write_string("\"disallows\":\{stats.disallow_count},")
  output.write_string("\"sitemaps\":\{stats.sitemap_count},")
  output.write_string("\"wildcards\":\{stats.wildcard_count},")
  output.write_string("\"anchors\":\{stats.anchored_count},")
  output.write_string("\"diagnostics\":\{stats.diagnostic_count},")
  output.write_string("\"findings\":\{stats.finding_count}")
  output.write_char('}')
}

///|
fn write_matched_rule(output : StringBuilder, matched : MatchedRule?) -> Unit {
  output.write_string("\"matched\":")
  match matched {
    None => output.write_string("null")
    Some(rule) => {
      output.write_char('{')
      output.write_string("\"kind\":\{json_string(rule_kind_name(rule.kind))},")
      output.write_string("\"pattern\":\{json_string(rule.pattern)},")
      output.write_string("\"line\":\{rule.line},")
      output.write_string("\"specificity\":\{rule.specificity}")
      output.write_char('}')
    }
  }
}

///|
fn write_decision(output : StringBuilder, decision : Decision) -> Unit {
  output.write_string("\"decision\":{")
  output.write_string("\"allowed\":\{json_bool(decision.allowed)},")
  output.write_string("\"userAgent\":\{json_string(decision.user_agent)},")
  output.write_string("\"path\":\{json_string(decision.path)},")
  output.write_string(
    "\"usedWildcardGroup\":\{json_bool(decision.used_wildcard_group)},",
  )
  write_matched_rule(output, decision.matched)
  output.write_char('}')
}

///|
fn write_candidates(
  output : StringBuilder,
  candidates : Array[RuleCandidate],
) -> Unit {
  output.write_string("\"candidates\":[")
  for index, candidate in candidates {
    if index > 0 {
      output.write_char(',')
    }
    output.write_char('{')
    output.write_string(
      "\"kind\":\{json_string(rule_kind_name(candidate.kind))},",
    )
    output.write_string("\"pattern\":\{json_string(candidate.pattern)},")
    output.write_string("\"line\":\{candidate.line},")
    output.write_string("\"matched\":\{json_bool(candidate.matched)},")
    output.write_string("\"specificity\":\{candidate.specificity},")
    output.write_string(
      "\"status\":\{json_string(candidate_status_name(candidate.status))}",
    )
    output.write_char('}')
  }
  output.write_char(']')
}

///|
fn write_trace(output : StringBuilder, trace : DecisionTrace) -> Unit {
  output.write_string("\"trace\":{")
  output.write_string("\"selectedAgents\":")
  write_string_array(output, trace.selected_agents)
  output.write_string(",\"exactGroupCount\":\{trace.exact_group_count},")
  output.write_string("\"wildcardGroupCount\":\{trace.wildcard_group_count},")
  write_candidates(output, trace.candidates)
  output.write_char('}')
}

///|
fn write_findings(output : StringBuilder, findings : Array[Finding]) -> Unit {
  output.write_string("\"findings\":[")
  for index, item in findings {
    if index > 0 {
      output.write_char(',')
    }
    output.write_char('{')
    output.write_string(
      "\"severity\":\{json_string(severity_name(item.severity))},",
    )
    output.write_string(
      "\"category\":\{json_string(category_name(item.category))},",
    )
    output.write_string("\"code\":\{json_string(item.code)},")
    output.write_string("\"title\":\{json_string(item.title)},")
    output.write_string("\"message\":\{json_string(item.message)},")
    output.write_string("\"lines\":")
    write_int_array(output, item.lines)
    output.write_string(",\"suggestion\":\{json_string(item.suggestion)}")
    output.write_char('}')
  }
  output.write_char(']')
}

///|
fn write_diagnostics(
  output : StringBuilder,
  diagnostics : Array[Diagnostic],
) -> Unit {
  output.write_string("\"diagnostics\":[")
  for index, item in diagnostics {
    if index > 0 {
      output.write_char(',')
    }
    output.write_char('{')
    output.write_string(
      "\"severity\":\{json_string(severity_name(item.severity))},",
    )
    output.write_string("\"line\":\{item.line},")
    output.write_string("\"code\":\{json_string(item.code)},")
    output.write_string("\"message\":\{json_string(item.message)}")
    output.write_char('}')
  }
  output.write_char(']')
}

///|
fn write_groups(output : StringBuilder, groups : Array[Group]) -> Unit {
  output.write_string("\"groups\":[")
  for group_index, group in groups {
    if group_index > 0 {
      output.write_char(',')
    }
    output.write_char('{')
    output.write_string("\"line\":\{group.line},\"agents\":")
    write_string_array(output, group.agents)
    output.write_string(",\"rules\":[")
    for rule_index, rule in group.rules {
      if rule_index > 0 {
        output.write_char(',')
      }
      output.write_char('{')
      output.write_string("\"kind\":\{json_string(rule_kind_name(rule.kind))},")
      output.write_string("\"pattern\":\{json_string(rule.pattern)},")
      output.write_string("\"line\":\{rule.line}")
      output.write_char('}')
    }
    output.write_string("]}")
  }
  output.write_char(']')
}

///|
fn write_batch(output : StringBuilder, report : BatchReport) -> Unit {
  output.write_string("\"batch\":{")
  output.write_string("\"productToken\":\{json_string(report.product_token)},")
  output.write_string("\"allowedCount\":\{report.allowed_count},")
  output.write_string("\"disallowedCount\":\{report.disallowed_count},")
  output.write_string("\"invalidCount\":\{report.invalid_count},")
  output.write_string("\"results\":[")
  for index, result in report.results {
    if index > 0 {
      output.write_char(',')
    }
    output.write_char('{')
    output.write_string("\"index\":\{result.index},")
    output.write_string("\"uri\":\{json_string(result.uri)},")
    output.write_string("\"allowed\":\{json_bool(result.decision.allowed)},")
    let matched_line = match result.decision.matched {
      Some(rule) => Some(rule.line)
      None => None
    }
    let matched_pattern = match result.decision.matched {
      Some(rule) => Some(rule.pattern)
      None => None
    }
    output.write_string("\"matchedLine\":\{json_optional_int(matched_line)},")
    output.write_string(
      "\"matchedPattern\":\{json_optional_string(matched_pattern)}",
    )
    output.write_char('}')
  }
  output.write_string("]}")
}

///|
fn write_fix_plan(
  output : StringBuilder,
  plan : FixPlan,
  safe_source : String,
) -> Unit {
  output.write_string("\"fixPlan\":{")
  output.write_string("\"safeCount\":\{plan.safe_count},")
  output.write_string("\"reviewCount\":\{plan.review_count},")
  output.write_string("\"safeSource\":\{json_string(safe_source)},")
  output.write_string("\"edits\":[")
  for index, edit in plan.edits {
    if index > 0 {
      output.write_char(',')
    }
    let kind = match edit.kind {
      DeleteLine => "delete-line"
      ReplaceLine => "replace-line"
      InsertAfter => "insert-after"
    }
    let safety = if edit.safety == Safe { "safe" } else { "review" }
    output.write_char('{')
    output.write_string("\"kind\":\{json_string(kind)},")
    output.write_string("\"line\":\{edit.line},")
    output.write_string("\"replacement\":\{json_string(edit.replacement)},")
    output.write_string("\"code\":\{json_string(edit.code)},")
    output.write_string("\"title\":\{json_string(edit.title)},")
    output.write_string("\"reason\":\{json_string(edit.reason)},")
    output.write_string("\"safety\":\{json_string(safety)}")
    output.write_char('}')
  }
  output.write_string("]}")
}

///|
fn write_coverage(output : StringBuilder, report : CoverageReport) -> Unit {
  output.write_string("\"coverage\":{")
  output.write_string("\"sampleCount\":\{report.sample_count},")
  output.write_string("\"ruleCount\":\{report.rule_count},")
  output.write_string("\"exercisedCount\":\{report.exercised_count},")
  output.write_string("\"selectedRuleCount\":\{report.selected_rule_count},")
  output.write_string("\"unusedRuleCount\":\{report.unused_rule_count},")
  output.write_string("\"shadowedRuleCount\":\{report.shadowed_rule_count},")
  output.write_string("\"percent\":\{report.coverage_percent},")
  output.write_string("\"rules\":[")
  for index, usage in report.usages {
    if index > 0 {
      output.write_char(',')
    }
    output.write_char('{')
    output.write_string("\"line\":\{usage.line},")
    output.write_string("\"kind\":\{json_string(rule_kind_name(usage.kind))},")
    output.write_string("\"pattern\":\{json_string(usage.pattern)},")
    output.write_string("\"considered\":\{usage.considered_count},")
    output.write_string("\"matched\":\{usage.matched_count},")
    output.write_string("\"selected\":\{usage.selected_count}")
    output.write_char('}')
  }
  output.write_string("]}")
}

///|
/// Build the complete JSON view model consumed by MoonRobots Studio.
/// Parsing, matching, tracing, scoring and batch simulation all happen here
/// in MoonBit; the browser layer only renders this result.
pub fn studio_snapshot(
  source : String,
  product_token : String,
  uri : String,
  batch_uris : String,
) -> String {
  let analysis = analyze(source)
  let trace = evaluate_with_trace(analysis.policy, product_token, uri)
  let batch = evaluate_batch(analysis.policy, product_token, batch_uris)
  let suggestions = suggest_test_paths(analysis.policy)
  let fix_plan = build_fix_plan(source)
  let coverage = analyze_rule_coverage(
    analysis.policy,
    product_token,
    batch_uris,
  )
  let output = StringBuilder::new()
  output.write_char('{')
  output.write_string("\"schemaVersion\":1,")
  output.write_string("\"score\":\{analysis.score},")
  output.write_string("\"grade\":\{json_string(analysis.grade)},")
  write_stats(output, analysis.stats)
  output.write_char(',')
  write_decision(output, trace.decision)
  output.write_char(',')
  write_trace(output, trace)
  output.write_char(',')
  write_findings(output, analysis.findings)
  output.write_char(',')
  write_diagnostics(output, analysis.policy.diagnostics)
  output.write_char(',')
  write_groups(output, analysis.policy.groups)
  output.write_string(",\"sitemaps\":")
  write_string_array(output, analysis.policy.sitemaps)
  output.write_string(",\"suggestedPaths\":")
  write_string_array(output, suggestions)
  output.write_string(
    ",\"formatted\":\{json_string(format_policy(analysis.policy))},",
  )
  write_batch(output, batch)
  output.write_char(',')
  write_fix_plan(output, fix_plan, apply_fix_plan(source, fix_plan, false))
  output.write_char(',')
  write_coverage(output, coverage)
  output.write_char('}')
  output.to_string()
}
