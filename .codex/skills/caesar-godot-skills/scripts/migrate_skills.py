#!/usr/bin/env python3
"""Merge source skills into this project's .codex/skills directory."""

from __future__ import annotations

import argparse
import shutil
import sys
import tempfile
from pathlib import Path


DEFAULT_SOURCE = Path(
    "/Users/hortor/workspace2/builda/web_env/builda_agent/project-skills"
)
DEFAULT_TARGET = Path(__file__).resolve().parents[2]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Replace target skills that exist in the source, add new source skills, "
            "and preserve every target-only skill."
        )
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show the migration plan without changing the target.",
    )
    return parser.parse_args()


def remove_path(path: Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)


def discover_skills(root: Path) -> dict[str, Path]:
    return {
        child.name: child
        for child in sorted(root.iterdir(), key=lambda item: item.name)
        if not child.name.startswith(".")
        and child.is_dir()
        and (child / "SKILL.md").is_file()
    }


def validate_roots(source: Path, target: Path) -> None:
    if not source.is_dir():
        raise ValueError(f"source skills directory does not exist: {source}")
    if not target.is_dir():
        raise ValueError(f"target skills directory does not exist: {target}")
    source = source.resolve()
    target = target.resolve()
    if source == target or source in target.parents or target in source.parents:
        raise ValueError(
            "source and target skills directories must be separate and non-nested"
        )


def migrate(source: Path, target: Path, dry_run: bool) -> int:
    source = source.expanduser().resolve()
    target = target.expanduser().resolve()
    validate_roots(source, target)

    source_skills = discover_skills(source)
    if not source_skills:
        raise ValueError(f"source contains no direct child skills: {source}")

    target_skills = discover_skills(target)
    conflicts = sorted(
        name
        for name in source_skills
        if ((target / name).exists() or (target / name).is_symlink())
        and name not in target_skills
    )
    if conflicts:
        raise ValueError(
            "target contains same-name entries that are not valid skills: "
            + ", ".join(conflicts)
        )

    added = sorted(set(source_skills) - set(target_skills))
    replaced = sorted(set(source_skills) & set(target_skills))
    preserved = sorted(set(target_skills) - set(source_skills))

    print(f"source: {source}")
    print(f"target: {target}")
    print(f"add ({len(added)}): {', '.join(added) or '-'}")
    print(f"replace ({len(replaced)}): {', '.join(replaced) or '-'}")
    print(f"preserve target-only ({len(preserved)}): {', '.join(preserved) or '-'}")

    if dry_run:
        print("dry-run: no files changed")
        return 0

    lock_path = target / ".caesar-godot-skills.lock"
    try:
        lock_path.mkdir()
    except FileExistsError as error:
        raise ValueError(
            f"migration lock exists; inspect before retrying: {lock_path}"
        ) from error

    keep_lock = False
    try:
        transaction_root = Path(
            tempfile.mkdtemp(prefix=".caesar-godot-skills-", dir=target)
        )
        staged_root = transaction_root / "staged"
        backup_root = transaction_root / "backup"
        staged_root.mkdir()
        backup_root.mkdir()
        installed: list[str] = []
        backed_up: list[str] = []

        try:
            for name, source_skill in source_skills.items():
                shutil.copytree(source_skill, staged_root / name, symlinks=True)

            for name in source_skills:
                destination = target / name
                if destination.exists() or destination.is_symlink():
                    backed_up.append(name)
                    destination.rename(backup_root / name)

            for name in source_skills:
                installed.append(name)
                (staged_root / name).rename(target / name)
        except BaseException as error:
            rollback_errors: list[str] = []
            for name in reversed(installed):
                try:
                    remove_path(target / name)
                except BaseException as rollback_error:
                    rollback_errors.append(f"remove {name}: {rollback_error}")
            for name in reversed(backed_up):
                backup = backup_root / name
                if backup.exists() or backup.is_symlink():
                    try:
                        backup.rename(target / name)
                    except BaseException as rollback_error:
                        rollback_errors.append(
                            f"restore {name}: {rollback_error}"
                        )
            if rollback_errors:
                keep_lock = True
                details = "; ".join(rollback_errors)
                raise RuntimeError(
                    f"migration failed and rollback was incomplete; recovery data is "
                    f"at {transaction_root}: {details}"
                ) from error
            remove_path(transaction_root)
            raise
        else:
            remove_path(transaction_root)
    finally:
        if not keep_lock:
            remove_path(lock_path)

    print(
        "migration complete: "
        f"added={len(added)}, replaced={len(replaced)}, "
        f"preserved_target_only={len(preserved)}"
    )
    return 0


def main() -> int:
    args = parse_args()
    try:
        return migrate(DEFAULT_SOURCE, DEFAULT_TARGET, args.dry_run)
    except (OSError, RuntimeError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
