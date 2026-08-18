///|
/// Whether a matching path rule permits or rejects a crawl request.
pub(all) enum RuleKind {
  Allow
  Disallow
} derive(Eq, Debug, ToJson)

///|
/// A parsed Allow or Disallow record.
pub(all) struct Rule {
  kind : RuleKind
  pattern : String
  line : Int
} derive(Eq, Debug)

///|
/// A robots group: one or more product tokens followed by path rules.
pub(all) struct Group {
  agents : Array[String]
  rules : Array[Rule]
  line : Int
} derive(Eq, Debug)

///|
/// Severity of a parser or linter diagnostic.
pub(all) enum Severity {
  Warning
  Error
} derive(Eq, Debug)

///|
/// A non-fatal problem found while parsing untrusted input.
pub(all) struct Diagnostic {
  severity : Severity
  line : Int
  code : String
  message : String
} derive(Eq, Debug)

///|
/// Parsed robots.txt policy and diagnostics.
pub(all) struct Policy {
  groups : Array[Group]
  sitemaps : Array[String]
  diagnostics : Array[Diagnostic]
} derive(Eq, Debug)

///|
/// The rule responsible for an access decision.
pub(all) struct MatchedRule {
  kind : RuleKind
  pattern : String
  line : Int
  specificity : Int
} derive(Eq, Debug)

///|
/// Complete, explainable result of evaluating one URL.
pub(all) struct Decision {
  allowed : Bool
  user_agent : String
  path : String
  matched : MatchedRule?
  used_wildcard_group : Bool
} derive(Eq, Debug)

///|
/// Why an individual candidate rule did or did not determine a decision.
pub(all) enum CandidateStatus {
  Selected
  Matched
  NotMatched
  LessSpecific
  LostAllowTie
} derive(Eq, Debug)

///|
/// One rule considered while producing an explainable decision.
pub(all) struct RuleCandidate {
  kind : RuleKind
  pattern : String
  line : Int
  matched : Bool
  specificity : Int
  status : CandidateStatus
} derive(Eq, Debug)

///|
/// A decision together with every intermediate rule comparison.
pub(all) struct DecisionTrace {
  decision : Decision
  selected_agents : Array[String]
  candidates : Array[RuleCandidate]
  exact_group_count : Int
  wildcard_group_count : Int
} derive(Eq, Debug)

///|
/// Category assigned to an advanced policy finding.
pub(all) enum FindingCategory {
  Syntax
  Correctness
  Redundancy
  Maintainability
  Security
} derive(Eq, Debug)

///|
/// A higher-level finding produced after parsing succeeds.
pub(all) struct Finding {
  severity : Severity
  category : FindingCategory
  code : String
  title : String
  message : String
  lines : Array[Int]
  suggestion : String
} derive(Eq, Debug)

///|
/// Aggregate statistics used by both reports and the visual dashboard.
pub(all) struct PolicyStats {
  source_lines : Int
  source_bytes : Int
  group_count : Int
  agent_count : Int
  rule_count : Int
  allow_count : Int
  disallow_count : Int
  sitemap_count : Int
  wildcard_count : Int
  anchored_count : Int
  diagnostic_count : Int
  finding_count : Int
} derive(Eq, Debug)

///|
/// Complete static analysis result for one robots.txt document.
pub(all) struct PolicyAnalysis {
  policy : Policy
  stats : PolicyStats
  findings : Array[Finding]
  score : Int
  grade : String
} derive(Eq, Debug)

///|
/// Result for one URL in a batch simulation.
pub(all) struct BatchResult {
  index : Int
  uri : String
  decision : Decision
} derive(Eq, Debug)

///|
/// Aggregate result for a batch of URL checks.
pub(all) struct BatchReport {
  product_token : String
  results : Array[BatchResult]
  allowed_count : Int
  disallowed_count : Int
  invalid_count : Int
} derive(Eq, Debug)

///|
/// One cell in a crawler-by-URL access matrix.
pub(all) struct MatrixCell {
  product_token : String
  uri : String
  allowed : Bool
  matched_line : Int?
  matched_pattern : String?
} derive(Eq, Debug)

///|
/// Comparison matrix for multiple crawlers and URLs.
pub(all) struct AccessMatrix {
  product_tokens : Array[String]
  uris : Array[String]
  cells : Array[MatrixCell]
  allowed_count : Int
  disallowed_count : Int
} derive(Eq, Debug)

///|
/// Safety classification for an automatically proposed source edit.
pub(all) enum FixSafety {
  Safe
  Review
} derive(Eq, Debug)

///|
/// Type of source transformation proposed by the policy optimizer.
pub(all) enum EditKind {
  DeleteLine
  ReplaceLine
  InsertAfter
} derive(Eq, Debug)

///|
/// A source-level edit that can be previewed before it is applied.
pub(all) struct SourceEdit {
  kind : EditKind
  line : Int
  replacement : String
  code : String
  title : String
  reason : String
  safety : FixSafety
} derive(Eq, Debug)

///|
/// Ordered set of optimizer edits and summary counts.
pub(all) struct FixPlan {
  edits : Array[SourceEdit]
  safe_count : Int
  review_count : Int
} derive(Eq, Debug)

///|
/// Semantic type of a change between two policies.
pub(all) enum PolicyChangeKind {
  GroupAdded
  GroupRemoved
  RuleAdded
  RuleRemoved
  SitemapAdded
  SitemapRemoved
  AccessOpened
  AccessClosed
} derive(Eq, Debug)

///|
/// One human-readable difference between two policies.
pub(all) struct PolicyChange {
  kind : PolicyChangeKind
  summary : String
  detail : String
  before_line : Int?
  after_line : Int?
  risk : Severity
} derive(Eq, Debug)

///|
/// A request whose decision changed between policy revisions.
pub(all) struct DecisionChange {
  product_token : String
  uri : String
  before_allowed : Bool
  after_allowed : Bool
  before_pattern : String?
  after_pattern : String?
} derive(Eq, Debug)

///|
/// Complete semantic comparison of two robots.txt documents.
pub(all) struct PolicyDiff {
  changes : Array[PolicyChange]
  decisions : Array[DecisionChange]
  opened_count : Int
  closed_count : Int
  unchanged_count : Int
} derive(Eq, Debug)

///|
/// Runtime usage statistics for one concrete source rule.
pub(all) struct RuleUsage {
  kind : RuleKind
  pattern : String
  line : Int
  considered_count : Int
  matched_count : Int
  selected_count : Int
  allow_decision_count : Int
  disallow_decision_count : Int
} derive(Eq, Debug)

///|
/// Sample-driven rule coverage report for one crawler.
pub(all) struct CoverageReport {
  product_token : String
  sample_count : Int
  rule_count : Int
  exercised_count : Int
  selected_rule_count : Int
  unused_rule_count : Int
  shadowed_rule_count : Int
  coverage_percent : Int
  usages : Array[RuleUsage]
} derive(Eq, Debug)

///|
/// A crawler-specific group used by the policy generator.
pub(all) struct GeneratedAgentGroup {
  agents : Array[String]
  disallow_paths : Array[String]
  allow_paths : Array[String]
} derive(Eq, Debug)

///|
/// Declarative input for generating a maintainable robots.txt policy.
pub(all) struct GeneratorConfig {
  site_origin : String
  project_name : String
  default_disallow_paths : Array[String]
  default_allow_paths : Array[String]
  agent_groups : Array[GeneratedAgentGroup]
  sitemap_paths : Array[String]
  include_header : Bool
  include_guidance : Bool
} derive(Eq, Debug)

///|
/// Generated policy together with configuration warnings.
pub(all) struct GeneratedPolicy {
  source : String
  warnings : Array[String]
  rule_count : Int
  group_count : Int
  sitemap_count : Int
} derive(Eq, Debug)

///|
/// User-controlled limits for a real crawl session.
pub(all) struct CrawlConfig {
  start_url : String
  product_token : String
  max_pages : Int
  max_depth : Int
  delay_ms : Int
  max_body_bytes : Int
  respect_robots : Bool
} derive(Eq, Debug, ToJson)

///|
/// Parsed HTTP(S) URL used by the crawler queue and same-origin checks.
pub(all) struct CrawlUrl {
  scheme : String
  host : String
  port : Int
  path_query : String
  origin : String
  normalized : String
} derive(Eq, Debug, ToJson)

///|
/// Why a discovered link was accepted or rejected before network access.
pub(all) enum LinkDisposition {
  Queued
  Duplicate
  DifferentOrigin
  UnsupportedScheme
  UnsafeHost
  InvalidUrl
  DepthExceeded
} derive(Eq, Debug, ToJson)

///|
/// A link discovered while parsing a fetched HTML page.
pub(all) struct DiscoveredLink {
  source_url : String
  raw_href : String
  normalized_url : String?
  depth : Int
  disposition : LinkDisposition
} derive(Eq, Debug, ToJson)

///|
/// Terminal status of a URL handled by the real crawler.
pub(all) enum CrawlPageStatus {
  Fetched
  BlockedByRobots
  SkippedNonHtml
  HttpError
  NetworkError
  TooLarge
} derive(Eq, Debug, ToJson)

///|
/// One completed page in a crawl report.
pub(all) struct CrawlPage {
  url : String
  depth : Int
  status : CrawlPageStatus
  http_status : Int?
  content_type : String
  title : String
  bytes : Int
  elapsed_ms : Int
  matched_rule : String?
  message : String
  outgoing_links : Int
} derive(Eq, Debug, ToJson)

///|
/// Queue entry passed from the pure planner to the network executor.
pub(all) struct CrawlTask {
  url : String
  depth : Int
  discovered_from : String?
} derive(Eq, Debug, ToJson)

///|
/// Aggregate real-crawl result suitable for CLI and Studio rendering.
pub(all) struct CrawlReport {
  start_url : String
  origin : String
  product_token : String
  robots_url : String
  robots_status : Int?
  robots_text : String
  started_at : String
  finished_at : String
  pages : Array[CrawlPage]
  links : Array[DiscoveredLink]
  fetched_count : Int
  blocked_count : Int
  failed_count : Int
  skipped_count : Int
  bytes_downloaded : Int
  stopped_reason : String
} derive(Eq, Debug, ToJson)
