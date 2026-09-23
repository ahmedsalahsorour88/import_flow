# qa-verifier memory

- pytest console summary ("N passed in Xs") and `--collect-only` output are suppressed once a test imports
  `main`. Always use `--junitxml` + exit code. Exit code 3 + INTERNALERROR = pytest crashed; rerun once.
- Full backend suite: ~8 min, 930 tests (2026-09-23). A one-off run hung ~2.5 h and ended in MemoryError
  while formatting a traceback; it did not reproduce on rerun — treat as environmental, rerun before blaming code.
- Environment-dependent tests (since 2026-09-23 they skip themselves when the environment is missing):
  - `tests/unit/test_arabic_ocr_engine.py` — needs the OCR engine installed.
  - `tests/unit/test_md09_ports_tariff_exchange_audit.py` — needs seeded reference data (100+ ports, 50+ tariffs).
  - `tests/unit/test_version_and_updates_api.py::test_uat_environment_staging_integrity` — needs `sorour_logistics_uat.db`.
- Slow tests: `tests/unit/test_cargox_standard_invoice.py` takes ~4.5 min alone (several tests 17-60 s).
- Tests write into the repo (`dist/`, `logs/`, `backups/`); these are gitignored.
