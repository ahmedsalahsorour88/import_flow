@AGENTS.md
@.agents/rules/CORE_RULES.md

# Claude Code setup

- Domain rules (customs, landed cost, lifecycle): read `.agents/rules/DOMAIN_RULES.md` before touching calculation code.
- UI screen standards: read `.agents/rules/UI_SCREEN_STANDARDS.md` before building or refactoring a Flutter screen.
- Hooks (`.claude/settings.json`):
  - After every backend `.py` edit, the edited module is imported against a throwaway DB; an import error blocks and must be fixed before continuing.
  - `history/*.md` is append-only (Edit to append, never Write over an existing file); `.env` and `*.db` files are never edited.
- Before any release: `/release-check`.
- Subagents: `endpoint-auth-auditor` after router changes; `customs-rules-reviewer` after customs / landed-cost calculation changes.
- CI and local runs use Python 3.12. Annotations are evaluated eagerly there, so a missing `typing` import breaks the boot even if it works on 3.14.
