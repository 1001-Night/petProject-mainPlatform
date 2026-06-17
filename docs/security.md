# Security Scan Notes

CI scans Docker images with Trivy and fails on HIGH and CRITICAL findings.

The `.trivyignore` file contains documented exceptions for Starlette vulnerabilities that affect code paths not used by this API:

- `CVE-2026-48818`: related to `StaticFiles`; this API does not mount static files.
- `CVE-2026-54283`: related to `request.form()` parsing; this API accepts JSON payloads and does not parse form data.

These exceptions should be removed when FastAPI supports a Starlette release that contains the upstream fixes.
