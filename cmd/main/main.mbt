///|
fn usage() -> String {
  (
    #|MoonRobots - RFC 9309 robots.txt toolkit
    #|
    #|Usage:
    #|  moonrobots check <robots.txt> <product-token> <url-or-path>
    #|  moonrobots lint <robots.txt>
    #|  moonrobots format <robots.txt>
    #|  moonrobots analyze <robots.txt>
    #|  moonrobots trace <robots.txt> <product-token> <url-or-path>
    #|  moonrobots fix-safe <robots.txt>
    #|  moonrobots coverage <robots.txt> <product-token> <url-list.txt>
    #|  moonrobots matrix <robots.txt> <agent-list.txt> <url-list.txt>
    #|  moonrobots samples <robots.txt>
    #|  moonrobots audit <robots.txt> <product-token>
    #|  moonrobots diff <before.txt> <after.txt>
    #|  moonrobots generate <blank|blog|commerce|documentation|private> <origin>
    #|  moonrobots version
    #|
    #|Exit codes for check: 0 = allowed, 1 = disallowed, 2 = usage or I/O error
  )
}

///|
fn version() -> String {
  "MoonRobots Studio 0.1.0\nRFC 9309 engine · MoonBit"
}

///|
fn read_source(path : String) -> String? {
  Some(@fs.read_file_to_string(path)) catch {
    _ => {
      println("error: cannot read '\{path}' as UTF-8 text")
      None
    }
  }
}

///|
fn read_policy(path : String) -> @robots.Policy? {
  match read_source(path) {
    Some(source) => Some(@robots.parse(source))
    None => None
  }
}

///|
fn run_check(path : String, agent : String, uri : String) -> Unit {
  guard read_policy(path) is Some(policy) else {
    @sys.exit(2)
    return
  }
  let decision = @robots.evaluate(policy, agent, uri)
  println(@robots.explain(decision))
  if !decision.allowed {
    @sys.exit(1)
  }
}

///|
fn run_lint(path : String) -> Unit {
  guard read_policy(path) is Some(policy) else {
    @sys.exit(2)
    return
  }
  if policy.diagnostics.length() == 0 {
    println("OK: no diagnostics")
  } else {
    println(@robots.format_diagnostics(policy))
    @sys.exit(1)
  }
}

///|
fn run_format(path : String) -> Unit {
  guard read_policy(path) is Some(policy) else {
    @sys.exit(2)
    return
  }
  println(@robots.format_policy(policy))
}

///|
fn run_analyze(path : String) -> Unit {
  guard read_source(path) is Some(source) else {
    @sys.exit(2)
    return
  }
  let analysis = @robots.analyze(source)
  println(@robots.format_analysis(analysis))
  if analysis.findings.length() > 0 {
    @sys.exit(1)
  }
}

///|
fn run_trace(path : String, agent : String, uri : String) -> Unit {
  guard read_policy(path) is Some(policy) else {
    @sys.exit(2)
    return
  }
  println(@robots.format_trace(@robots.evaluate_with_trace(policy, agent, uri)))
}

///|
fn run_fix_safe(path : String) -> Unit {
  guard read_source(path) is Some(source) else {
    @sys.exit(2)
    return
  }
  let plan = @robots.build_fix_plan(source)
  if plan.safe_count == 0 {
    println(source)
  } else {
    println(@robots.apply_fix_plan(source, plan, false))
  }
}

///|
fn run_coverage(path : String, agent : String, sample_path : String) -> Unit {
  guard read_policy(path) is Some(policy) else {
    @sys.exit(2)
    return
  }
  guard read_source(sample_path) is Some(samples) else {
    @sys.exit(2)
    return
  }
  println(
    @robots.coverage_to_markdown(
      @robots.analyze_rule_coverage(policy, agent, samples),
    ),
  )
}

///|
fn run_diff(before_path : String, after_path : String) -> Unit {
  guard read_source(before_path) is Some(before) else {
    @sys.exit(2)
    return
  }
  guard read_source(after_path) is Some(after) else {
    @sys.exit(2)
    return
  }
  println(
    @robots.policy_diff_to_markdown(
      @robots.compare_policies(before, after, "", ""),
    ),
  )
}

///|
fn run_generate(profile : String, origin : String) -> Unit {
  let known = ["blank", "blog", "commerce", "documentation", "private"]
  if !known.contains(profile.to_lower()) {
    println("error: unknown generator profile '\{profile}'")
    @sys.exit(2)
    return
  }
  println(
    @robots.generate_policy(@robots.generator_preset(profile, origin)).source,
  )
}

///|
fn run_matrix(path : String, agent_path : String, sample_path : String) -> Unit {
  guard read_policy(path) is Some(policy) else {
    @sys.exit(2)
    return
  }
  guard read_source(agent_path) is Some(agents) else {
    @sys.exit(2)
    return
  }
  guard read_source(sample_path) is Some(samples) else {
    @sys.exit(2)
    return
  }
  println(
    @robots.access_matrix_to_markdown(
      @robots.build_access_matrix(policy, agents, samples),
    ),
  )
}

///|
fn run_samples(path : String) -> Unit {
  guard read_policy(path) is Some(policy) else {
    @sys.exit(2)
    return
  }
  for sample in @robots.suggest_test_paths(policy) {
    println(sample)
  }
}

///|
/// Produce a single review artifact combining quality, coverage and fixes.
fn run_audit(path : String, agent : String) -> Unit {
  guard read_source(path) is Some(source) else {
    @sys.exit(2)
    return
  }
  let policy = @robots.parse(source)
  let analysis = @robots.analyze(source)
  let coverage = @robots.analyze_suggested_coverage(policy, agent)
  let fixes = @robots.build_fix_plan(source)
  println(@robots.analysis_to_markdown(analysis))
  println("\n---\n")
  println(@robots.coverage_to_markdown(coverage))
  println("\n---\n")
  println(@robots.fix_plan_to_markdown(fixes))
  if analysis.findings.length() > 0 {
    @sys.exit(1)
  }
}

///|
fn main {
  match @env.args() {
    [_, "check", path, agent, uri] => run_check(path, agent, uri)
    [_, "lint", path] => run_lint(path)
    [_, "format", path] => run_format(path)
    [_, "analyze", path] => run_analyze(path)
    [_, "trace", path, agent, uri] => run_trace(path, agent, uri)
    [_, "fix-safe", path] => run_fix_safe(path)
    [_, "coverage", path, agent, samples] => run_coverage(path, agent, samples)
    [_, "matrix", path, agents, samples] => run_matrix(path, agents, samples)
    [_, "samples", path] => run_samples(path)
    [_, "audit", path, agent] => run_audit(path, agent)
    [_, "diff", before, after] => run_diff(before, after)
    [_, "generate", profile, origin] => run_generate(profile, origin)
    [_, "version"] | [_, "--version"] => println(version())
    [_, "--help"] | [_, "-h"] => println(usage())
    _ => {
      println(usage())
      @sys.exit(2)
    }
  }
}
