# Compatibility boundary

MoonRobots targets the Robots Exclusion Protocol standardized by RFC 9309. It does not claim
bug-for-bug compatibility with any particular crawler. Vendor extensions such as accepting a
missing colon, treating `/directory` as `/directory/index.html`, or silently truncating an
invalid product token at whitespace are intentionally outside version 0.1.

For caller convenience, an unescaped Unicode URI argument is converted to canonical UTF-8
octets before matching. Crawlers should still pass a correctly encoded URI as required by the
RFC. Unknown records are ignored with a diagnostic, keeping extensions visible to linting
without changing access decisions.
