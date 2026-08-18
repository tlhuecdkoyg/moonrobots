///|
fn kind_text(kind : RuleKind) -> String {
  match kind {
    Allow => "Allow"
    Disallow => "Disallow"
  }
}

///|
/// Render a compact explanation suitable for a CLI or log message.
pub fn explain(decision : Decision) -> String {
  let verdict = if decision.allowed { "ALLOWED" } else { "DISALLOWED" }
  match decision.matched {
    Some(rule) =>
      "\{verdict}: \{decision.path}\n" +
      "User-agent: \{decision.user_agent}\n" +
      "Matched: \{kind_text(rule.kind)}: \{rule.pattern} (line \{rule.line})"
    None => {
      let reason = if decision.path == "/robots.txt" {
        "The /robots.txt resource is implicitly allowed by RFC 9309."
      } else {
        "No applicable path rule matched; access is allowed by default."
      }
      "\{verdict}: \{decision.path}\n" +
      "User-agent: \{decision.user_agent}\n" +
      "Reason: \{reason}"
    }
  }
}

///|
/// Render a deterministic normalized representation of the supported records.
/// Comments and unsupported extensions are intentionally not reproduced.
pub fn format_policy(policy : Policy) -> String {
  let output = StringBuilder::new()
  for group_index, group in policy.groups {
    if group_index > 0 {
      output.write_char('\n')
    }
    for agent in group.agents {
      output.write_string("User-agent: \{agent}\n")
    }
    for rule in group.rules {
      output.write_string("\{kind_text(rule.kind)}: \{rule.pattern}\n")
    }
  }
  if policy.sitemaps.length() > 0 {
    if policy.groups.length() > 0 {
      output.write_char('\n')
    }
    for sitemap in policy.sitemaps {
      output.write_string("Sitemap: \{sitemap}\n")
    }
  }
  output.to_string()
}

///|
/// Render parser diagnostics one per line.
pub fn format_diagnostics(policy : Policy) -> String {
  let output = StringBuilder::new()
  for diagnostic in policy.diagnostics {
    let severity = match diagnostic.severity {
      Warning => "warning"
      Error => "error"
    }
    output.write_string(
      "\{severity}[\{diagnostic.code}] line \{diagnostic.line}: \{diagnostic.message}\n",
    )
  }
  output.to_string()
}
