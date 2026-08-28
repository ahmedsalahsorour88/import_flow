"""
Unit Tests for MigrationLinter
"""
import pytest
from pathlib import Path
from utils.migration_linter import MigrationLinter


def test_migration_linter_passes_on_project_migrations():
    """Ensures that all actual Alembic migrations in the project pass safety linting."""
    root = Path(__file__).resolve().parent.parent.parent
    versions_dir = root / "alembic" / "versions"
    is_safe, issues = MigrationLinter.lint_directory(versions_dir)
    assert is_safe is True
    assert len(issues) == 0


def test_migration_linter_catches_destructive_upgrade(tmp_path):
    """Ensures that destructive operations in upgrade() are caught by the linter."""
    unsafe_file = tmp_path / "unsafe_migration.py"
    unsafe_file.write_text("""
def upgrade():
    op.drop_table('important_customer_table')
    op.drop_column('suppliers', 'tax_id')

def downgrade():
    pass
""", encoding="utf-8")

    issues = MigrationLinter.lint_file(unsafe_file)
    assert len(issues) >= 2
    types = [iss["type"] for iss in issues]
    assert "DROP_TABLE" in types
    assert "DROP_COLUMN" in types
