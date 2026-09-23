# security-reviewer memory — known-issue baseline (2026-09-23)

## Fixed upstream before 2026-09-23
- Password hashing: PBKDF2-HMAC-SHA256, 600k iterations, per-user salt. Token signing: real HMAC + compare_digest.
- `SECRET_KEY` from `.env`/env. Header impersonation and first-admin fallback gated by `ALLOW_DEV_AUTH_BYPASS` (default false).
- CORS restricted to localhost + private LAN ranges. `/shutdown` requires `get_current_user`.
- production_sync restore / sync-to-prod / pull-to-dev require `require_admin`.

## Still open
- CRITICAL: only ~6 of 50 routers declare any auth dependency (537 endpoints); e.g.
  `modules/financial_settlement/router.py` has none. No global auth middleware in `main.py`.
- HIGH: `frontend/.../auto_updater_service.dart` runs the installer silently with only a size check; no
  `installer_sha256` in `version.json`; installer not code-signed.
- MEDIUM: `/api/v1/production-sync/check-updates?remote_url=` lets any signed-in user point the update check
  at an arbitrary URL.
- MEDIUM: `/restore?filename=` — verify path normalisation in `ProductionSyncService.restore_backup`.
- Transport: frontend talks plain `http://<host>:28080` on the LAN.
