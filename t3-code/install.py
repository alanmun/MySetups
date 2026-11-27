"""Apply the shared T3 Code settings to an existing userdata directory."""

import argparse
import json
import os
import re
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


def configure_codex(settings, source):
    launch = read_json(source / "codex-launch.json")
    profile = source.parent / "codex" / f"{launch['profile']}.config.toml"
    contents = profile.read_text(encoding="utf-8")
    instances = settings.get("providerInstances", {}).copy()
    instance = instances.get("codex", {"driver": "codex"}).copy()
    config = (instance.get("config") or {}).copy()
    args = config.get("launchArgs", "")
    for key in launch["settings"]:
        quoted_string = r'(?:"""\n(.*?)\n"""|("[^"\n]*"))'
        match = re.search(rf'^{re.escape(key)}[ \t]*=[ \t]*{quoted_string}', contents, re.M | re.S)
        if match is None:
            raise ValueError(f"No quoted {key} setting in {profile}")
        prompt, literal = match.groups()
        value = literal if literal is not None else json.dumps(prompt + "\n", ensure_ascii=False)
        # T3's argv tokenizer unescapes double quotes and backslashes. Replace
        # our previously generated flag while keeping other local arguments.
        args = re.sub(rf'(?:^|\s)-c "{re.escape(key)}=(?:\\.|[^"\\])*"', "", args).strip()
        override = json.dumps(f"{key}={value}", ensure_ascii=False)
        args = f"{args} -c {override}".strip()
    config["launchArgs"] = args
    instances["codex"] = {**instance, "config": config}
    return {**settings, "providerInstances": instances}


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
    # desktop-settings.json turns on Tailscale Serve. T3 Code logs a warning
    # and starts normally on a machine where Tailscale is missing or logged out.
    for name in ("keybindings.json", "client-settings.json", "settings.json", "desktop-settings.json"):
        path = target / name
        shared = read_json(source / name)
        current = read_json(path) if path.exists() else type(shared)()
        if isinstance(shared, list):
            updated = merge_keybindings(current, shared)
        else:
            updated = {**current, **shared}
        if name == "settings.json":
            updated = configure_codex(updated, source)
        write_config(path, current, updated)


if __name__ == "__main__":
    main()
