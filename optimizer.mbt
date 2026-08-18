///|
fn source_edit(
  kind : EditKind,
  line : Int,
  replacement : String,
  code : String,
  title : String,
  reason : String,
  safety : FixSafety,
) -> SourceEdit {
  { kind, line, replacement, code, title, reason, safety }
}

///|
fn source_line(lines : Array[String], line : Int) -> String {
  if line > 0 && line <= lines.length() {
    lines[line - 1]
  } else {
    ""
  }
}

///|
fn directive_name(line : String) -> String {
  let cleaned = line.trim().to_owned()
  for index = 0; index < cleaned.length(); index = index + 1 {
    if cleaned.get_char(index) == Some(':') {
      return cleaned[:index].to_owned().trim().to_owned().to_lower()
    }
  }
  ""
}

///|
fn directive_value(line : String) -> String {
  let cleaned = line.trim().to_owned()
  for index = 0; index < cleaned.length(); index = index + 1 {
    if cleaned.get_char(index) == Some(':') {
      let tail = cleaned[index + 1:].to_owned()
      let mut value = tail
      for comment = 0; comment < tail.length(); comment = comment + 1 {
        if tail.get_char(comment) == Some('#') {
          value = tail[:comment].to_owned()
          break
        }
      }
      return value.trim().to_owned()
    }
  }
  ""
}

///|
fn has_edit_at(edits : Array[SourceEdit], line : Int, code : String) -> Bool {
  for edit in edits {
    if edit.line == line && edit.code == code {
      return true
    }
  }
  false
}

///|
fn collect_duplicate_rule_edits(
  policy : Policy,
  lines : Array[String],
  edits : Array[SourceEdit],
) -> Unit {
  for group in policy.groups {
    for later = 1; later < group.rules.length(); later = later + 1 {
      let rule = group.rules[later]
      let mut duplicate_line = 0
      for earlier = 0; earlier < later; earlier = earlier + 1 {
        let previous = group.rules[earlier]
        if previous.kind == rule.kind && previous.pattern == rule.pattern {
          duplicate_line = previous.line
        }
      }
      if duplicate_line > 0 {
        edits.push(
          source_edit(
            DeleteLine,
            rule.line,
            "",
            "remove-duplicate-rule",
            "Remove duplicate rule",
            "Line \{rule.line} duplicates the effective rule on line \{duplicate_line}.",
            Safe,
          ),
        )
      }
    }
  }
  ignore(lines)
}

///|
fn collect_duplicate_agent_edits(
  lines : Array[String],
  edits : Array[SourceEdit],
) -> Unit {
  let mut current_agents : Array[String] = []
  let mut saw_rule = false
  for index, line in lines {
    let name = directive_name(line)
    let value = directive_value(line).to_lower()
    if name == "user-agent" {
      if saw_rule {
        current_agents = []
        saw_rule = false
      }
      if current_agents.contains(value) && !value.is_empty() {
        edits.push(
          source_edit(
            DeleteLine,
            index + 1,
            "",
            "remove-duplicate-agent",
            "Remove duplicate User-agent",
            "This adjacent product token is already present in the same group.",
            Safe,
          ),
        )
      } else if !value.is_empty() {
        current_agents.push(value)
      }
    } else if name == "allow" || name == "disallow" {
      saw_rule = true
    }
  }
}

///|
fn collect_duplicate_sitemap_edits(
  lines : Array[String],
  edits : Array[SourceEdit],
) -> Unit {
  let seen : Array[String] = []
  for index, line in lines {
    if directive_name(line) == "sitemap" {
      let value = directive_value(line)
      if seen.contains(value) && !value.is_empty() {
        edits.push(
          source_edit(
            DeleteLine,
            index + 1,
            "",
            "remove-duplicate-sitemap",
            "Remove duplicate Sitemap",
            "This exact sitemap URL was already declared earlier.",
            Safe,
          ),
        )
      } else if !value.is_empty() {
        seen.push(value)
      }
    }
  }
}

///|
fn collect_whitespace_edits(
  lines : Array[String],
  edits : Array[SourceEdit],
) -> Unit {
  for index, line in lines {
    let trimmed = line.trim_end().to_owned()
    if trimmed != line && !has_edit_at(edits, index + 1, "trim-whitespace") {
      edits.push(
        source_edit(
          ReplaceLine,
          index + 1,
          trimmed,
          "trim-whitespace",
          "Trim trailing whitespace",
          "Trailing whitespace has no policy meaning and creates noisy diffs.",
          Safe,
        ),
      )
    }
  }
}

///|
fn replace_directive_value(line : String, new_value : String) -> String {
  for index = 0; index < line.length(); index = index + 1 {
    if line.get_char(index) == Some(':') {
      let prefix = line[:index + 1].to_owned()
      return prefix + " " + new_value
    }
  }
  line
}

///|
fn collect_pattern_review_edits(
  policy : Policy,
  lines : Array[String],
  edits : Array[SourceEdit],
) -> Unit {
  for group in policy.groups {
    for rule in group.rules {
      let original = source_line(lines, rule.line)
      if !rule.pattern.has_prefix("/") && !rule.pattern.has_prefix("*") {
        edits.push(
          source_edit(
            ReplaceLine,
            rule.line,
            replace_directive_value(original, "/" + rule.pattern),
            "prefix-root-slash",
            "Prefix pattern with '/'",
            "Normalized request paths begin with '/'; this change makes the rule reachable.",
            Review,
          ),
        )
      }
      if rule.pattern.contains("$") && !rule.pattern.has_suffix("$") {
        let fixed = rule.pattern.replace_all(old="$", new="") + "$"
        edits.push(
          source_edit(
            ReplaceLine,
            rule.line,
            replace_directive_value(original, fixed),
            "move-end-anchor",
            "Move '$' anchor to the end",
            "Only a final '$' acts as an end anchor. Review whether the symbol was intended literally.",
            Review,
          ),
        )
      }
    }
  }
}

///|
fn collect_sitemap_review_edits(
  lines : Array[String],
  edits : Array[SourceEdit],
) -> Unit {
  for index, line in lines {
    if directive_name(line) == "sitemap" {
      let value = directive_value(line)
      if !value.is_empty() &&
        !has_edit_at(edits, index + 1, "remove-duplicate-sitemap") &&
        !(value.has_prefix("https://") || value.has_prefix("http://")) {
        edits.push(
          source_edit(
            ReplaceLine,
            index + 1,
            replace_directive_value(line, "https://example.com/" + value),
            "absolute-sitemap",
            "Use an absolute Sitemap URL",
            "The host is a placeholder and must be reviewed before applying.",
            Review,
          ),
        )
      }
    }
  }
}

///|
fn collect_unknown_record_edits(
  policy : Policy,
  edits : Array[SourceEdit],
) -> Unit {
  for diagnostic in policy.diagnostics {
    if diagnostic.code == "unknown-record" {
      edits.push(
        source_edit(
          DeleteLine,
          diagnostic.line,
          "",
          "remove-unknown-record",
          "Remove unsupported record",
          "MoonRobots cannot prove whether a vendor-specific directive is needed, so this edit requires review.",
          Review,
        ),
      )
    }
  }
}

///|
/// Build a source-preserving fix plan. Safe edits do not alter access decisions;
/// review edits may change semantics and are never applied implicitly.
pub fn build_fix_plan(source : String) -> FixPlan {
  let lines : Array[String] = []
  for line in source.split("\n") {
    lines.push(line.to_owned())
  }
  let policy = parse(source)
  let edits : Array[SourceEdit] = []
  collect_duplicate_rule_edits(policy, lines, edits)
  collect_duplicate_agent_edits(lines, edits)
  collect_duplicate_sitemap_edits(lines, edits)
  collect_whitespace_edits(lines, edits)
  collect_pattern_review_edits(policy, lines, edits)
  collect_sitemap_review_edits(lines, edits)
  collect_unknown_record_edits(policy, edits)
  let mut safe_count = 0
  let mut review_count = 0
  for edit in edits {
    match edit.safety {
      Safe => safe_count = safe_count + 1
      Review => review_count = review_count + 1
    }
  }
  { edits, safe_count, review_count }
}

///|
fn should_apply(edit : SourceEdit, include_review : Bool) -> Bool {
  edit.safety == Safe || include_review
}

///|
/// Apply a fix plan while retaining untouched comments and source layout.
pub fn apply_fix_plan(
  source : String,
  plan : FixPlan,
  include_review : Bool,
) -> String {
  let output = StringBuilder::new()
  let lines : Array[String] = []
  for line in source.split("\n") {
    lines.push(line.to_owned())
  }
  for index, source_text in lines {
    let line_number = index + 1
    let mut deleted = false
    let mut replacement = source_text
    let insertions : Array[String] = []
    for edit in plan.edits {
      if edit.line == line_number && should_apply(edit, include_review) {
        match edit.kind {
          DeleteLine => deleted = true
          ReplaceLine => replacement = edit.replacement
          InsertAfter => insertions.push(edit.replacement)
        }
      }
    }
    if !deleted {
      output.write_string(replacement)
      if index + 1 < lines.length() || insertions.length() > 0 {
        output.write_char('\n')
      }
    }
    for insertion_index, insertion in insertions {
      output.write_string(insertion)
      if index + 1 < lines.length() || insertion_index + 1 < insertions.length() {
        output.write_char('\n')
      }
    }
  }
  output.to_string()
}

///|
/// Apply only decision-preserving cleanup edits discovered by the optimizer.
pub fn apply_safe_fixes(source : String) -> String {
  apply_fix_plan(source, build_fix_plan(source), false)
}

///|
fn edit_kind_text(kind : EditKind) -> String {
  match kind {
    DeleteLine => "delete"
    ReplaceLine => "replace"
    InsertAfter => "insert after"
  }
}

///|
/// Render a reviewable Markdown checklist for a fix plan.
pub fn fix_plan_to_markdown(plan : FixPlan) -> String {
  let output = StringBuilder::new()
  output.write_string("# MoonRobots fix plan\n\n")
  output.write_string(
    "\{plan.safe_count} safe edit(s), \{plan.review_count} edit(s) requiring review.\n\n",
  )
  if plan.edits.length() == 0 {
    output.write_string("No automatic source edits are suggested.\n")
  }
  for edit in plan.edits {
    let safety = if edit.safety == Safe { "SAFE" } else { "REVIEW" }
    output.write_string(
      "- [ ] **\{safety}** line \{edit.line}: \{edit.title} (`\{edit_kind_text(edit.kind)}`)\n",
    )
    output.write_string("  - \{edit.reason}\n")
    if !edit.replacement.is_empty() {
      output.write_string("  - Replacement: `\{edit.replacement}`\n")
    }
  }
  output.to_string()
}
