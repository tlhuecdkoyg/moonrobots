///|
fn first_colon(text : String) -> Int? {
  for i = 0; i < text.length(); i = i + 1 {
    if text.get_char(i) == Some(':') {
      return Some(i)
    }
  }
  None
}

///|
fn without_comment(text : String) -> String {
  for i = 0; i < text.length(); i = i + 1 {
    if text.get_char(i) == Some('#') {
      return text[:i].to_owned()
    }
  }
  text
}

///|
fn valid_product_token(token : String) -> Bool {
  if token == "*" {
    return true
  }
  if token.is_empty() {
    return false
  }
  for c in token {
    if !((c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z') ||
      c == '_' ||
      c == '-') {
      return false
    }
  }
  true
}

///|
fn push_group(
  groups : Array[Group],
  agents : Array[String],
  rules : Array[Rule],
  line : Int,
) -> Unit {
  if agents.length() > 0 {
    groups.push({ agents: agents.copy(), rules: rules.copy(), line })
  }
}

///|
/// Parse a robots.txt document. Invalid lines are reported and skipped so that
/// valid rules remain usable, as required by RFC 9309 section 2.3.1.5.
pub fn parse(text : String) -> Policy {
  let groups : Array[Group] = []
  let sitemaps : Array[String] = []
  let diagnostics : Array[Diagnostic] = []
  let mut agents : Array[String] = []
  let mut rules : Array[Rule] = []
  let mut group_line = 0
  let mut saw_rule = false
  for line_index, raw_view in text.split("\n") {
    let line_number = line_index + 1
    let raw = raw_view.to_owned()
    let cleaned = without_comment(raw).trim().to_owned()
    if cleaned.is_empty() {
      continue
    }
    guard first_colon(cleaned) is Some(colon) else {
      diagnostics.push({
        severity: Warning,
        line: line_number,
        code: "missing-colon",
        message: "Ignored a record without a colon.",
      })
      continue
    }
    let name = cleaned[:colon].to_owned().trim().to_owned().to_lower()
    let value = cleaned[colon + 1:].to_owned().trim().to_owned()
    match name {
      "user-agent" => {
        if saw_rule {
          push_group(groups, agents, rules, group_line)
          agents = []
          rules = []
          saw_rule = false
        }
        if agents.length() == 0 {
          group_line = line_number
        }
        if valid_product_token(value) {
          agents.push(value.to_lower())
        } else {
          diagnostics.push({
            severity: Warning,
            line: line_number,
            code: "invalid-user-agent",
            message: "Ignored an invalid or empty product token.",
          })
        }
      }
      "allow" | "disallow" =>
        if agents.length() == 0 {
          diagnostics.push({
            severity: Warning,
            line: line_number,
            code: "orphan-rule",
            message: "Ignored a path rule before any User-agent record.",
          })
        } else {
          saw_rule = true
          if !value.is_empty() {
            rules.push({
              kind: if name == "allow" {
                Allow
              } else {
                Disallow
              },
              pattern: value,
              line: line_number,
            })
          }
        }
      "sitemap" => if !value.is_empty() { sitemaps.push(value) }
      _ =>
        diagnostics.push({
          severity: Warning,
          line: line_number,
          code: "unknown-record",
          message: "Ignored an unsupported record named '\{name}'.",
        })
    }
  }
  push_group(groups, agents, rules, group_line)
  { groups, sitemaps, diagnostics }
}
