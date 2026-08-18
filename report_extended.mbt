///|
fn report_rule_kind(kind : RuleKind) -> String {
  match kind {
    Allow => "Allow"
    Disallow => "Disallow"
  }
}

///|
fn report_category(category : FindingCategory) -> String {
  match category {
    Syntax => "Syntax"
    Correctness => "Correctness"
    Redundancy => "Redundancy"
    Maintainability => "Maintainability"
    Security => "Security"
  }
}

///|
fn report_status(status : CandidateStatus) -> String {
  match status {
    Selected => "selected"
    Matched => "matched but not decisive"
    NotMatched => "not matched"
    LessSpecific => "less specific"
    LostAllowTie => "lost Allow tie"
  }
}

///|
fn joined_lines(lines : Array[Int]) -> String {
  if lines.length() == 0 {
    return "document"
  }
  let output = StringBuilder::new()
  for index, line in lines {
    if index > 0 {
      output.write_string(", ")
    }
    output.write_string(line.to_string())
  }
  output.to_string()
}

///|
/// Render a compact terminal summary of advanced policy analysis.
pub fn format_analysis(analysis : PolicyAnalysis) -> String {
  let stats = analysis.stats
  let output = StringBuilder::new()
  output.write_string("MoonRobots policy analysis\n")
  output.write_string("==========================\n")
  output.write_string("Health: \{analysis.score}/100 (\{analysis.grade})\n")
  output.write_string(
    "Source: \{stats.source_lines} lines, \{stats.source_bytes} bytes\n",
  )
  output.write_string(
    "Policy: \{stats.group_count} groups, \{stats.agent_count} agents, \{stats.rule_count} rules\n",
  )
  output.write_string(
    "Rules: \{stats.allow_count} Allow, \{stats.disallow_count} Disallow, \{stats.wildcard_count} wildcard, \{stats.anchored_count} anchored\n",
  )
  output.write_string(
    "Other: \{stats.sitemap_count} sitemaps, \{stats.finding_count} findings\n",
  )
  if analysis.findings.length() == 0 {
    output.write_string("\nOK: no syntax or quality findings.\n")
  } else {
    output.write_string("\nFindings\n--------\n")
    for item in analysis.findings {
      let severity = match item.severity {
        Warning => "WARN"
        Error => "ERROR"
      }
      output.write_string(
        "[\{severity}] \{item.code} (\{report_category(item.category)}, \{joined_lines(item.lines)}): \{item.title}\n",
      )
      output.write_string("  \{item.message}\n")
      output.write_string("  Suggestion: \{item.suggestion}\n")
    }
  }
  output.to_string()
}

///|
/// Render a full matching trace for terminals and build logs.
pub fn format_trace(trace : DecisionTrace) -> String {
  let output = StringBuilder::new()
  output.write_string(explain(trace.decision))
  output.write_string("\n\nGroup selection\n---------------\n")
  if trace.selected_agents.length() == 0 {
    output.write_string(
      "No applicable User-agent group; RFC default allow applies.\n",
    )
  } else {
    output.write_string("Selected agents: ")
    for index, agent in trace.selected_agents {
      if index > 0 {
        output.write_string(", ")
      }
      output.write_string(agent)
    }
    output.write_char('\n')
    output.write_string(
      "Exact groups: \{trace.exact_group_count}; wildcard groups: \{trace.wildcard_group_count}\n",
    )
  }
  output.write_string("\nCandidate rules\n---------------\n")
  if trace.candidates.length() == 0 {
    output.write_string("No candidate path rules.\n")
  }
  for candidate in trace.candidates {
    let marker = if candidate.status == Selected { ">" } else { "-" }
    output.write_string(
      "\{marker} L\{candidate.line} \{report_rule_kind(candidate.kind)}: \{candidate.pattern}\n",
    )
    output.write_string(
      "  specificity \{candidate.specificity}; \{report_status(candidate.status)}\n",
    )
  }
  output.to_string()
}

///|
/// Render static analysis as a portable Markdown audit report.
pub fn analysis_to_markdown(analysis : PolicyAnalysis) -> String {
  let stats = analysis.stats
  let output = StringBuilder::new()
  output.write_string("# MoonRobots policy audit\n\n")
  output.write_string(
    "**Health score: \{analysis.score}/100 (\{analysis.grade})**\n\n",
  )
  output.write_string("## Summary\n\n")
  output.write_string("| Metric | Value |\n|---|---:|\n")
  output.write_string("| Source lines | \{stats.source_lines} |\n")
  output.write_string("| Source bytes | \{stats.source_bytes} |\n")
  output.write_string("| Groups | \{stats.group_count} |\n")
  output.write_string("| Product tokens | \{stats.agent_count} |\n")
  output.write_string("| Rules | \{stats.rule_count} |\n")
  output.write_string("| Allow rules | \{stats.allow_count} |\n")
  output.write_string("| Disallow rules | \{stats.disallow_count} |\n")
  output.write_string("| Sitemaps | \{stats.sitemap_count} |\n")
  output.write_string("| Findings | \{stats.finding_count} |\n")
  output.write_string("\n## Findings\n\n")
  if analysis.findings.length() == 0 {
    output.write_string(
      "No syntax, correctness, redundancy, maintainability or security findings.\n",
    )
  }
  for index, item in analysis.findings {
    output.write_string("### \{index + 1}. \{item.title}\n\n")
    output.write_string("- Code: `\{item.code}`\n")
    output.write_string("- Category: \{report_category(item.category)}\n")
    output.write_string("- Lines: \{joined_lines(item.lines)}\n")
    output.write_string("- Detail: \{item.message}\n")
    output.write_string("- Suggestion: \{item.suggestion}\n\n")
  }
  output.write_string("## Normalized policy\n\n```text\n")
  output.write_string(format_policy(analysis.policy))
  output.write_string("```\n")
  output.to_string()
}

///|
/// Render a crawler-by-URL matrix as a Markdown table.
pub fn access_matrix_to_markdown(matrix : AccessMatrix) -> String {
  let output = StringBuilder::new()
  output.write_string("# Crawler access matrix\n\n")
  output.write_string(
    "| Product token | URL or path | Decision | Matched rule |\n",
  )
  output.write_string("|---|---|---|---|\n")
  for cell in matrix.cells {
    let decision = if cell.allowed { "Allowed" } else { "Disallowed" }
    let matched = match cell.matched_pattern {
      Some(pattern) =>
        match cell.matched_line {
          Some(line) => "`\{pattern}` (line \{line})"
          None => "`\{pattern}`"
        }
      None => "Default allow"
    }
    output.write_string(
      "| \{cell.product_token} | `\{cell.uri}` | \{decision} | \{matched} |\n",
    )
  }
  output.write_string(
    "\n\{matrix.allowed_count} allowed and \{matrix.disallowed_count} disallowed cells.\n",
  )
  output.to_string()
}

///|
/// Render a decision trace as a Markdown artifact for issues and reviews.
pub fn trace_to_markdown(trace : DecisionTrace) -> String {
  let decision = trace.decision
  let verdict = if decision.allowed { "Allowed" } else { "Disallowed" }
  let output = StringBuilder::new()
  output.write_string("# robots.txt decision trace\n\n")
  output.write_string("- Product token: `\{decision.user_agent}`\n")
  output.write_string("- Normalized path: `\{decision.path}`\n")
  output.write_string("- Decision: **\{verdict}**\n")
  output.write_string("- Exact groups: \{trace.exact_group_count}\n")
  output.write_string("- Wildcard groups: \{trace.wildcard_group_count}\n")
  output.write_string("\n## Candidate rules\n\n")
  output.write_string("| Line | Kind | Pattern | Specificity | Outcome |\n")
  output.write_string("|---:|---|---|---:|---|\n")
  for candidate in trace.candidates {
    output.write_string(
      "| \{candidate.line} | \{report_rule_kind(candidate.kind)} | `\{candidate.pattern}` | \{candidate.specificity} | \{report_status(candidate.status)} |\n",
    )
  }
  output.to_string()
}
