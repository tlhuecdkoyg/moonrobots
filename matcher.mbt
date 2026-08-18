///|
fn is_hex(byte : Byte) -> Bool {
  (byte >= b'0' && byte <= b'9') ||
  (byte >= b'a' && byte <= b'f') ||
  (byte >= b'A' && byte <= b'F')
}

///|
fn hex_value(byte : Byte) -> Int {
  if byte >= b'0' && byte <= b'9' {
    byte.to_int() - b'0'.to_int()
  } else if byte >= b'a' && byte <= b'f' {
    byte.to_int() - b'a'.to_int() + 10
  } else {
    byte.to_int() - b'A'.to_int() + 10
  }
}

///|
fn hex_digit(value : Int) -> Byte {
  if value < 10 {
    (b'0'.to_int() + value).to_byte()
  } else {
    (b'A'.to_int() + value - 10).to_byte()
  }
}

///|
fn is_unreserved(byte : Byte) -> Bool {
  (byte >= b'a' && byte <= b'z') ||
  (byte >= b'A' && byte <= b'Z') ||
  (byte >= b'0' && byte <= b'9') ||
  byte == b'-' ||
  byte == b'.' ||
  byte == b'_' ||
  byte == b'~'
}

///|
fn push_encoded(output : Array[Byte], byte : Byte) -> Unit {
  output.push(b'%')
  output.push(hex_digit(byte.to_int() >> 4))
  output.push(hex_digit(byte.to_int() & 15))
}

///|
/// Canonicalize octets for the RFC 9309 comparison operation. Non-ASCII
/// octets are percent encoded, encoded unreserved ASCII is decoded, and hex
/// digits for reserved octets are uppercased.
fn canonical_octets(text : String) -> Bytes {
  let input = @utf8.encode(text)
  let output : Array[Byte] = []
  let mut i = 0
  while i < input.length() {
    let byte = input[i]
    if byte == b'%' &&
      i + 2 < input.length() &&
      is_hex(input[i + 1]) &&
      is_hex(input[i + 2]) {
      let decoded = (hex_value(input[i + 1]) * 16 + hex_value(input[i + 2])).to_byte()
      if is_unreserved(decoded) {
        output.push(decoded)
      } else {
        push_encoded(output, decoded)
      }
      i = i + 3
    } else if byte.to_int() >= 128 {
      push_encoded(output, byte)
      i = i + 1
    } else {
      output.push(byte)
      i = i + 1
    }
  }
  Bytes::from_array(output)
}

///|
fn pattern_specificity(pattern : Bytes, end : Int) -> Int {
  let mut score = 0
  let mut i = 0
  while i < end {
    if pattern[i] != b'*' {
      score = score + 1
    }
    if pattern[i] == b'%' &&
      i + 2 < end &&
      is_hex(pattern[i + 1]) &&
      is_hex(pattern[i + 2]) {
      i = i + 3
    } else {
      i = i + 1
    }
  }
  score
}

///|
fn glob_prefix_matches(
  pattern_text : String,
  target_text : String,
) -> (Bool, Int) {
  let pattern = canonical_octets(pattern_text)
  let target = canonical_octets(target_text)
  let anchored = pattern.length() > 0 && pattern[pattern.length() - 1] == b'$'
  let plen = if anchored { pattern.length() - 1 } else { pattern.length() }
  let mut pi = 0
  let mut ti = 0
  let mut star = -1
  let mut after_star = 0
  while ti < target.length() {
    if pi < plen && pattern[pi] == target[ti] {
      pi = pi + 1
      ti = ti + 1
    } else if pi < plen && pattern[pi] == b'*' {
      star = pi
      after_star = ti
      pi = pi + 1
    } else if star >= 0 {
      after_star = after_star + 1
      ti = after_star
      pi = star + 1
    } else {
      return (false, pattern_specificity(pattern, plen))
    }
    if pi == plen && !anchored {
      return (true, pattern_specificity(pattern, plen))
    }
  }
  while pi < plen && pattern[pi] == b'*' {
    pi = pi + 1
  }
  (pi == plen, pattern_specificity(pattern, plen))
}

///|
fn selected_rules(
  policy : Policy,
  product_token : String,
) -> (Array[Rule], Bool) {
  let token = product_token.to_lower()
  let exact : Array[Rule] = []
  let wildcard : Array[Rule] = []
  let mut found_exact_group = false
  let mut found_wildcard_group = false
  for group in policy.groups {
    let mut group_exact = false
    let mut group_wildcard = false
    for agent in group.agents {
      if agent == token {
        group_exact = true
      } else if agent == "*" {
        group_wildcard = true
      }
    }
    if group_exact {
      found_exact_group = true
      for rule in group.rules {
        exact.push(rule)
      }
    } else if group_wildcard {
      found_wildcard_group = true
      for rule in group.rules {
        wildcard.push(rule)
      }
    }
  }
  if found_exact_group {
    (exact, false)
  } else {
    (wildcard, found_wildcard_group)
  }
}

///|
fn selected_group_details(
  policy : Policy,
  product_token : String,
) -> (Array[String], Int, Int) {
  let token = product_token.to_lower()
  let exact_agents : Array[String] = []
  let wildcard_agents : Array[String] = []
  let mut exact_count = 0
  let mut wildcard_count = 0
  for group in policy.groups {
    let mut exact = false
    let mut wildcard = false
    for agent in group.agents {
      if agent == token {
        exact = true
      }
      if agent == "*" {
        wildcard = true
      }
    }
    if exact {
      exact_count = exact_count + 1
      for agent in group.agents {
        if !exact_agents.contains(agent) {
          exact_agents.push(agent)
        }
      }
    } else if wildcard {
      wildcard_count = wildcard_count + 1
      for agent in group.agents {
        if !wildcard_agents.contains(agent) {
          wildcard_agents.push(agent)
        }
      }
    }
  }
  if exact_count > 0 {
    (exact_agents, exact_count, wildcard_count)
  } else {
    (wildcard_agents, exact_count, wildcard_count)
  }
}

///|
/// Match one robots pattern against a path and return its RFC specificity.
/// This is useful for visualizers that need to explain candidate rules.
pub fn match_pattern(pattern : String, uri_or_path : String) -> (Bool, Int) {
  glob_prefix_matches(pattern, path_from_uri(uri_or_path))
}

///|
/// Evaluate whether `product_token` may access `uri` under a parsed policy.
pub fn evaluate(
  policy : Policy,
  product_token : String,
  uri : String,
) -> Decision {
  let path = path_from_uri(uri)
  if path == "/robots.txt" {
    return {
      allowed: true,
      user_agent: product_token,
      path,
      matched: None,
      used_wildcard_group: false,
    }
  }
  let (rules, used_wildcard_group) = selected_rules(policy, product_token)
  let mut best : MatchedRule? = None
  for rule in rules {
    let (matches, specificity) = glob_prefix_matches(rule.pattern, path)
    if matches {
      let replace = match best {
        None => true
        Some(old) =>
          specificity > old.specificity ||
          (
            specificity == old.specificity &&
            rule.kind == Allow &&
            old.kind == Disallow
          )
      }
      if replace {
        best = Some({
          kind: rule.kind,
          pattern: rule.pattern,
          line: rule.line,
          specificity,
        })
      }
    }
  }
  let allowed = match best {
    Some(rule) => rule.kind == Allow
    None => true
  }
  {
    allowed,
    user_agent: product_token,
    path,
    matched: best,
    used_wildcard_group,
  }
}

///|
/// Evaluate a request while retaining every rule considered by the matcher.
pub fn evaluate_with_trace(
  policy : Policy,
  product_token : String,
  uri : String,
) -> DecisionTrace {
  let decision = evaluate(policy, product_token, uri)
  let (rules, _) = selected_rules(policy, product_token)
  let (agents, exact_count, wildcard_count) = selected_group_details(
    policy, product_token,
  )
  let candidates : Array[RuleCandidate] = []
  for rule in rules {
    let (matched, specificity) = glob_prefix_matches(
      rule.pattern,
      decision.path,
    )
    let status = if !matched {
      NotMatched
    } else {
      match decision.matched {
        None => Matched
        Some(best) =>
          if best.line == rule.line &&
            best.pattern == rule.pattern &&
            best.kind == rule.kind {
            Selected
          } else if specificity < best.specificity {
            LessSpecific
          } else if specificity == best.specificity &&
            rule.kind == Disallow &&
            best.kind == Allow {
            LostAllowTie
          } else {
            Matched
          }
      }
    }
    candidates.push({
      kind: rule.kind,
      pattern: rule.pattern,
      line: rule.line,
      matched,
      specificity,
      status,
    })
  }
  {
    decision,
    selected_agents: agents,
    candidates,
    exact_group_count: exact_count,
    wildcard_group_count: wildcard_count,
  }
}

///|
/// Convenience API for the most common one-shot use case.
pub fn is_allowed(text : String, product_token : String, uri : String) -> Bool {
  evaluate(parse(text), product_token, uri).allowed
}
