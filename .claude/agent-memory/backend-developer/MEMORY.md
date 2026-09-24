# backend-developer memory

- `import main` runs `SchemaUpgradeService.execute_safe_startup_upgrade` at import time: it applies DDL and, if
  the DB file exists and is non-empty, writes a backup snapshot to `backups/`. For smoke checks set
  `DATABASE_PATH` to a fresh temp file and `SECRET_KEY` (32+ chars) so nothing touches the live DB or `.env`.
- `settings.py` appends a generated `SECRET_KEY` to `.env` when none is set.
- tests: `tests/conftest.py` sets `DATABASE_PATH` to a temp DB and `ALLOW_DEV_AUTH_BYPASS=true`.
- Undefined-name sweep that works: `python -m pyflakes modules database utils main.py` (install pyflakes to a
  scratch dir with `pip install --target`). String annotations with function-local imports are false positives.
- `modules/import_documentation/{router,service}.py` use `from ...schemas import *` — pyflakes cannot check
  them; import models explicitly there (e.g. `CustomsDeclarationDraft` from `.model`).
- `modules/cargox/city_port_resolver.py` loads a 4.5 MB JSON cache once per process.
