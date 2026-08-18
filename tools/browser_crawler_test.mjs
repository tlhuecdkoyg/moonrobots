import test from "node:test";
import assert from "node:assert/strict";
import { assessReport, privateAddress } from "./browser_crawler.mjs";

test("blocks private and special IPv4 destinations", () => {
  for (const address of ["127.0.0.1", "10.0.0.1", "172.16.2.3", "192.168.1.2", "169.254.169.254", "224.0.0.1"]) assert.equal(privateAddress(address), true, address);
  assert.equal(privateAddress("93.184.216.34"), false);
});

test("blocks local and unique-local IPv6 destinations", () => {
  for (const address of ["::1", "::", "fc00::1", "fd12::1", "fe80::1"]) assert.equal(privateAddress(address), true, address);
  assert.equal(privateAddress("2606:2800:220:1:248:1893:25c8:1946"), false);
});

test("post-crawl assessment produces actionable findings", () => {
  const assessment = assessReport({
    robots_status: 404,
    blocked_count: 0,
    failed_count: 1,
    pages: [{ status: "Fetched", title: "", description: "", url: "https://example.com/", final_url: "https://example.com/" }],
  });
  assert.ok(assessment.score < 90);
  assert.ok(assessment.findings.some(finding => finding.title.includes("robots.txt")));
  assert.ok(assessment.findings.every(finding => finding.suggestion));
});

test("healthy crawl keeps a passing score", () => {
  const assessment = assessReport({
    robots_status: 200,
    blocked_count: 0,
    failed_count: 0,
    pages: [{ status: "Fetched", title: "Home", description: "Site description", url: "https://example.com/", final_url: "https://example.com/" }],
  });
  assert.equal(assessment.score, 100);
  assert.equal(assessment.grade, "优秀");
});
