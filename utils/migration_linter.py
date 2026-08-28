"""
Migration Linter (Pre-Build Migration Safety Checker)
=====================================================
Analyzes Alembic revision scripts for destructive DDL operations in the `upgrade()`
function to ensure that forward schema updates and production upgrades never destroy customer data.

Safety Rules:
1. Disallow unguarded `op.drop_table` or `DROP TABLE` in `upgrade()`.
2. Disallow unguarded `op.drop_column` or `batch_op.drop_column` in `upgrade()`.
3. Require newly added columns (`add_column`) in `upgrade()` to be nullable or specify a server_default.
"""
import re
import sys
from pathlib import Path
from typing import List, Dict, Any, Tuple


class MigrationLinter:
    DESTRUCTIVE_PATTERNS = [
        (r"op\.drop_table\s*\(", "DROP_TABLE", "Calling op.drop_table() in upgrade() can permanently delete user tables and data."),
        (r"op\.drop_column\s*\(", "DROP_COLUMN", "Calling op.drop_column() in upgrade() can permanently delete existing column data."),
        (r"batch_op\.drop_column\s*\(", "BATCH_DROP_COLUMN", "Calling batch_op.drop_column() in upgrade() deletes columns in SQLite table recreation."),
        (r"(?i)DROP\s+TABLE", "RAW_DROP_TABLE", "Raw SQL DROP TABLE detected in upgrade()."),
        (r"(?i)DROP\s+COLUMN", "RAW_DROP_COLUMN", "Raw SQL DROP COLUMN detected in upgrade()."),
    ]

    @classmethod
    def lint_file(cls, file_path: Path) -> List[Dict[str, Any]]:
        issues = []
        if not file_path.exists() or not file_path.is_file():
            return issues

        content = file_path.read_text(encoding="utf-8")
        lines = content.splitlines()

        in_upgrade = False
        in_downgrade = False

        for line_idx, line in enumerate(lines, start=1):
            stripped = line.strip()

            if stripped.startswith("def upgrade"):
                in_upgrade = True
                in_downgrade = False
                continue
            elif stripped.startswith("def downgrade"):
                in_upgrade = False
                in_downgrade = True
                continue

            if not in_upgrade:
                continue

            if stripped.startswith("#"):
                continue

            for pattern, issue_type, msg in cls.DESTRUCTIVE_PATTERNS:
                if re.search(pattern, line):
                    # Check if line has an explicit safety waiver comment like '# safe-drop-approved'
                    if "# safe-drop-approved" not in line:
                        issues.append({
                            "file": file_path.name,
                            "line": line_idx,
                            "type": issue_type,
                            "message": msg,
                            "content": stripped,
                        })

            # Check non-nullable add_column without default
            if "add_column" in line:
                if "nullable=False" in line and "server_default" not in line:
                    issues.append({
                        "file": file_path.name,
                        "line": line_idx,
                        "type": "NOT_NULL_WITHOUT_DEFAULT",
                        "message": "Adding a NOT NULL column without a server_default can break on tables with existing rows.",
                        "content": stripped,
                    })

        return issues

    @classmethod
    def lint_directory(cls, versions_dir: Path) -> Tuple[bool, List[Dict[str, Any]]]:
        all_issues = []
        if not versions_dir.exists():
            return True, []

        for py_file in sorted(versions_dir.glob("*.py")):
            if py_file.name == "__init__.py":
                continue
            file_issues = cls.lint_file(py_file)
            all_issues.extend(file_issues)

        is_safe = len(all_issues) == 0
        return is_safe, all_issues


def run_cli():
    root = Path(__file__).resolve().parent.parent
    versions_dir = root / "alembic" / "versions"
    is_safe, issues = MigrationLinter.lint_directory(versions_dir)

    print(f"==================================================")
    print(f"  ImportFlow Migration Safety Linter")
    print(f"==================================================")
    print(f"Scanning directory: {versions_dir}")
    print(f"Files scanned: {len(list(versions_dir.glob('*.py')))}")

    if is_safe:
        print("\n[PASSED] All migrations comply with Non-Destructive In-Place Upgrade safety rules!")
        sys.exit(0)
    else:
        print(f"\n[FAILED] Found {len(issues)} potential destructive migration issue(s):")
        for iss in issues:
            print(f" - [{iss['type']}] {iss['file']}:{iss['line']} -> {iss['message']}")
            print(f"   Code: {iss['content']}")
        sys.exit(1)


if __name__ == "__main__":
    run_cli()
