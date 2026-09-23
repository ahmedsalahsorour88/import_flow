# importflow-lead memory

## Project state (as of 2026-09-23)
- CI (`build_and_release.yml`) was red on main from 2026-08-28 (last green: c6a2f66, v1.0.58) through
  2026-09-23: 97 consecutive failures at step "Run Backend Pytest Suite". Cause: backend failed to import on
  Python 3.12 (missing typing/schema imports) plus environment-dependent tests. Check with `/ci-status`.
- Consequence: no GitHub Release after v1.0.60 was published, while `version.json` on main advertised newer
  versions -> in-app update downloads 404. `/release-check` flags this ("Installer published").
- Auth gap: only ~6 of 50 routers have an auth dependency; most business endpoints are public. Fixing this is
  the top security backlog item (see security-reviewer memory).
- Auto-updater runs the downloaded installer with no SHA-256 / signature verification.

## Working conventions
- User: CTO, prefers Egyptian Arabic, wants to stay on the current branch, Opus 5.5 at medium effort for agents.
- Track 1 daily work: never bump versions or touch `version.json` / `package_production.py`.
- Full backend suite takes ~8 minutes (930 tests on 2026-09-23).
