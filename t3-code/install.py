"""Apply the shared T3 Code settings to an existing userdata directory."""

import argparse
import json
import os
import shutil
import stat
from pathlib import Path
from tempfile import NamedTemporaryFile


def read_json(path):
    with path.open(encoding="utf-8-sig") as file:
        return json.load(file)


def merge_keybindings(current, shared):
    # Remove the bundled terminal close shortcut so the shell receives Ctrl+W.
    old_close = {"key": "mod+w", "command": "terminal.close", "when": "terminalFocus"}
    # T3 Code gives the last matching shortcut priority.
    return [binding for binding in current if binding != old_close and binding not in shared] + shared


def write_config(path, current, updated):
    if current == updated:
        return

    file = NamedTemporaryFile(
        mode="w", encoding="utf-8", newline="\n", dir=path.parent, delete=False
    )
    temporary = Path(file.name)
    try:
        with file:
            json.dump(updated, file, ensure_ascii=False, indent=2)
            file.write("\n")
        if path.exists():
            shutil.copy2(path, path.with_name(path.name + ".mysetups.bak"))
            temporary.chmod(stat.S_IMODE(path.stat().st_mode))
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)
    print(f"Updated {path}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    default_dir = Path(os.environ.get("T3_HOME") or (Path.home() / ".t3")) / "userdata"
    parser.add_argument("--userdata", type=Path, default=default_dir)
    target = parser.parse_args().userdata
    if not target.is_dir():
        print(f"Skipping T3 Code setup because {target} does not exist.")
        return

    source = Path(__file__).resolve().parent
    for name in ("keybindings.json", "client-settings.json", "settings.json"):
        path = target / name
        shared = read_json(source / name)
        current = read_json(path) if path.exists() else type(shared)()
        if isinstance(shared, list):
            updated = merge_keybindings(current, shared)
        else:
            updated = {**current, **shared}
        write_config(path, current, updated)


if __name__ == "__main__":
    main()
