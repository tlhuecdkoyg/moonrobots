///|
fn clean_input_lines(text : String) -> (Array[String], Int) {
  let values : Array[String] = []
  let mut invalid = 0
  for raw in text.split("\n") {
    let value = raw.to_owned().trim().to_owned()
    if value.is_empty() || value.has_prefix("#") {
      continue
    }
    if value.contains(" ") || value.contains("\t") {
      invalid = invalid + 1
    } else {
      values.push(value)
    }
  }
  (values, invalid)
}

///|
/// Evaluate newline-separated URLs or paths for one crawler product token.
/// Blank lines and comment lines beginning with `#` are ignored.
pub fn evaluate_batch(
  policy : Policy,
  product_token : String,
  uri_lines : String,
) -> BatchReport {
  let (uris, invalid) = clean_input_lines(uri_lines)
  let results : Array[BatchResult] = []
  let mut allowed = 0
  let mut disallowed = 0
  for index, uri in uris {
    let decision = evaluate(policy, product_token, uri)
    if decision.allowed {
      allowed = allowed + 1
    } else {
      disallowed = disallowed + 1
    }
    results.push({ index: index + 1, uri, decision })
  }
  {
    product_token,
    results,
    allowed_count: allowed,
    disallowed_count: disallowed,
    invalid_count: invalid,
  }
}

///|
/// Compare several crawler product tokens across several URLs.
pub fn build_access_matrix(
  policy : Policy,
  product_token_lines : String,
  uri_lines : String,
) -> AccessMatrix {
  let (agents, _) = clean_input_lines(product_token_lines)
  let (uris, _) = clean_input_lines(uri_lines)
  let cells : Array[MatrixCell] = []
  let mut allowed = 0
  let mut disallowed = 0
  for agent in agents {
    for uri in uris {
      let decision = evaluate(policy, agent, uri)
      if decision.allowed {
        allowed = allowed + 1
      } else {
        disallowed = disallowed + 1
      }
      let matched_line = match decision.matched {
        Some(rule) => Some(rule.line)
        None => None
      }
      let matched_pattern = match decision.matched {
        Some(rule) => Some(rule.pattern)
        None => None
      }
      cells.push({
        product_token: agent,
        uri,
        allowed: decision.allowed,
        matched_line,
        matched_pattern,
      })
    }
  }
  {
    product_tokens: agents,
    uris,
    cells,
    allowed_count: allowed,
    disallowed_count: disallowed,
  }
}

///|
fn remove_pattern_extensions(pattern : String) -> String {
  let output = StringBuilder::new()
  for char in pattern {
    if char != '*' && char != '$' {
      output.write_char(char)
    }
  }
  let result = output.to_string()
  if result.is_empty() {
    "/"
  } else {
    result
  }
}

///|
fn append_unique(values : Array[String], value : String) -> Unit {
  if !values.contains(value) {
    values.push(value)
  }
}

///|
/// Generate useful boundary paths from the rules in a parsed policy.
/// The paths are deterministic and intended as test suggestions, not proofs.
pub fn suggest_test_paths(policy : Policy) -> Array[String] {
  let paths : Array[String] = ["/", "/robots.txt"]
  for group in policy.groups {
    for rule in group.rules {
      let base = remove_pattern_extensions(rule.pattern)
      append_unique(paths, base)
      if base != "/" {
        let child = if base.has_suffix("/") {
          base + "moonrobots-child"
        } else {
          base + "/moonrobots-child"
        }
        append_unique(paths, child)
      }
      if rule.pattern.has_suffix("$") {
        append_unique(paths, base + "?preview=1")
      }
      if rule.pattern.contains("*") {
        let expanded = rule.pattern
          .replace_all(old="*", new="sample")
          .replace_all(old="$", new="")
        append_unique(paths, expanded)
      }
    }
  }
  paths
}

///|
fn csv_escape(value : String) -> String {
  let escaped = value.replace_all(old="\"", new="\"\"")
  if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
    "\"" + escaped + "\""
  } else {
    escaped
  }
}

///|
/// Export a batch report as RFC 4180-style CSV text.
pub fn batch_to_csv(report : BatchReport) -> String {
  let output = StringBuilder::new()
  output.write_string(
    "index,product_token,uri,allowed,matched_kind,matched_pattern,matched_line\n",
  )
  for result in report.results {
    let kind = match result.decision.matched {
      Some(rule) => if rule.kind == Allow { "Allow" } else { "Disallow" }
      None => "Default"
    }
    let pattern = match result.decision.matched {
      Some(rule) => rule.pattern
      None => ""
    }
    let line = match result.decision.matched {
      Some(rule) => rule.line.to_string()
      None => ""
    }
    output.write_string(
      "\{result.index},\{csv_escape(report.product_token)},\{csv_escape(result.uri)},\{result.decision.allowed},\{kind},\{csv_escape(pattern)},\{line}\n",
    )
  }
  output.to_string()
}

///|
/// Export a batch report as a readable Markdown table.
pub fn batch_to_markdown(report : BatchReport) -> String {
  let output = StringBuilder::new()
  output.write_string("| # | URL or path | Decision | Matched rule |\n")
  output.write_string("|---:|---|---|---|\n")
  for result in report.results {
    let verdict = if result.decision.allowed { "Allowed" } else { "Disallowed" }
    let matched = match result.decision.matched {
      Some(rule) => {
        let kind = if rule.kind == Allow { "Allow" } else { "Disallow" }
        "\{kind}: `\{rule.pattern}` (line \{rule.line})"
      }
      None => "Default allow"
    }
    let safe_uri = result.uri.replace_all(old="|", new="\\|")
    output.write_string(
      "| \{result.index} | `\{safe_uri}` | \{verdict} | \{matched} |\n",
    )
  }
  output.write_string(
    "\nSummary: \{report.allowed_count} allowed, \{report.disallowed_count} disallowed, \{report.invalid_count} invalid input lines.\n",
  )
  output.to_string()
}
