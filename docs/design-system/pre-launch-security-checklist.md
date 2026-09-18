# 🛡️ Pre-Launch Security Checklist (12 Verification Items)

## 📌 Overview
Senior security audit checklist governing application lockdown before production deployment.

---

## 📋 The 12 Verification Items
1. **`.env` in `.gitignore` & No History Secrets:** Verified clean.
2. **SSL / HTTPS Enforced:** HSTS enabled; optional `ENFORCE_HTTPS` redirect.
3. **Dependency Vulnerabilities:** `pip-audit` zero CVEs policy.
4. **Database Connection Security:** Strict ORM AST parameterization; no raw SQL formatting.
5. **Authentication & Session Security:** PBKDF2-HMAC-SHA256 (600,000 rounds), HS256 JWT (24h TTL), secure storage.
6. **Role-Based Access Control (RBAC):** Hybrid RBAC on all endpoints via `require_permission`.
7. **Input Validation & Sanitisation:** Pydantic v2 schemas on all incoming payloads; path traversal defense.
8. **Rate Limiting:** `LoginRateLimiter` (5 attempts/min) on sensitive auth endpoints.
9. **Error Handling:** `DEBUG=false` in production; zero stack trace leakage to clients.
10. **CORS Configuration:** Strictly restricted to localhost and private enterprise LAN CIDRs.
11. **Security Headers:** HSTS, CSP, X-Frame-Options, X-Content-Type-Options, Permissions-Policy.
12. **Audit Logging:** Comprehensive event trail in `audit_logs` table.

---

## ✅ Definition of Done (Self-Verification Checklist)
- [ ] Pass 1 audit report documented and presented to user.
- [ ] Pass 2 fixes applied only upon explicit confirmation.
- [ ] All 853 automated tests pass with 100% success rate.
