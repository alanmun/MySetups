# ai-killswitch

## Why
One command to stop every Claude Code and Codex process of this user, plus everything they started, if an agent misbehaves.

## What it does
`~/ai-killswitch.sh` finds `claude` / `codex*` processes (and npm-launched ones), walks their child processes, sends SIGTERM, then sends SIGKILL to any left after 2 s. It never kills itself or its parent shell. `--dry-run` (`-n`) only lists what it would stop.

## Status
- 2026-11-19: written. Not Fedora-specific; works on any Linux.
