# Final audit evidence

- [publication-local-test-summary.json](publication-local-test-summary.json): fresh 2026-10-30 publication verification, 27 unit-test functions plus 5 UI tests passing. See [VALIDATION.md](../../VALIDATION.md) for the preceding simulator-input failure and final commands.

Small actual execution records, retained without build products or personal filesystem paths:

- [audit-test-summary.json](audit-test-summary.json): unmodified `xcresulttool get test-results summary` output from `/tmp/MarketPulse-Audit-Final.xcresult`. It reports 32 functions (27 unit + 5 UI), zero failures/skips, and 46 device invocations including parameterized cases.
- [audit-real-echo.txt](audit-real-echo.txt): complete fresh stdout from the production-source diagnostic requiring 75 accepted Postman echoes. This is not UI-test fixture output.
- [audit-build-inputs.sha256](audit-build-inputs.sha256): SHA-256 of the 45 application/project/resource/test/diagnostic inputs at audit completion. They matched the clean source export then. Later control-alignment changes are documented separately in VALIDATION.md; this historical manifest is intentionally not rewritten to imply those changes were part of the earlier audit.

Full local bundles/logs remain outside the repository at paths recorded in [AUDIT.md](../../AUDIT.md). They may be removed by the operating system because they are in `/tmp`; these portable summaries, source and screenshots remain in the project. The summaries are evidence of local execution, not a GitHub Actions result.
