# Testing

MoonRobots uses black-box tests for the public API and integration smoke tests for the CLI.

Run the complete local gate from the repository root:

```sh
moon update
moon fmt --check
moon check --deny-warn
moon test --target all --deny-warn
moon build --target all
moon package --list
```

The suite covers parsing and diagnostics, group selection, longest-rule precedence, allow
ties, wildcards, end anchors, URI extraction, percent encoding, UTF-8, the implicit
`/robots.txt` exception, deterministic formatting, and RFC 9309 examples. CI additionally
executes allowed, denied, lint, and formatting CLI paths.

The Studio gate builds `web/app`, validates the generated JavaScript and checks the Node browser
adapter and SSRF tests. A Windows end-to-end gate serves the repository over localhost, loads
`web/index.html` in Microsoft Edge, runs a bounded crawl, verifies the screenshot endpoint, and
refreshes `docs/studio-screenshot-zh.png`. The generated Studio snapshot is independently parsed
as JSON before browser testing.

Localization is browser-tested with a fresh profile so no saved preference exists. The expected
first-run language is Simplified Chinese; the rendered page must show the Chinese engine status,
navigation, statistics, decision explanation, candidate statuses, and language selector.

The command-line entry point is integration-tested because process exits cannot be exercised
as ordinary in-process unit tests. Review core library coverage with `moon coverage analyze`.
