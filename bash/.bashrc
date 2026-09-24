# ~/.bashrc: executed by bash(1) for non-login interactive shells.

# -------------------------
# Interactive shells only
# -------------------------
case $- in
  *i*) ;;
  *) return ;;
esac

# -------------------------
# Environment detection
# -------------------------
is_msys2=false
is_linux=false
is_wsl=false
is_rpi=false

case "${MSYSTEM:-}" in
  UCRT64|MINGW64|MSYS) is_msys2=true ;;
esac

case "${OSTYPE:-}" in
  linux*) is_linux=true ;;
esac

if grep -qi microsoft /proc/version 2>/dev/null; then
  is_wsl=true
fi

if [ -f /proc/device-tree/model ] && grep -qi "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
  is_rpi=true
fi

# -------------------------
# Global interactive settings
# -------------------------
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=50000
HISTFILESIZE=100000
shopt -s checkwinsize

history_sync_command='history -a'
case "${PROMPT_COMMAND:-}" in
  *"history -a"*) ;;
  "") PROMPT_COMMAND="$history_sync_command" ;;
  *) PROMPT_COMMAND="$history_sync_command; $PROMPT_COMMAND" ;;
esac
unset history_sync_command

export UV_ENV_FILE=".env"
export LESS='-R'

alias withenv='dotenv -e .env --'
alias uvshell='source .venv/bin/activate'

alias gita='git add -A'
alias gits='git status'
alias gitp='git push'
alias gitb='git for-each-ref --sort=-committerdate --format="%(if)%(HEAD)%(then)* %(else)  %(end)%(refname:short)  %(committerdate:relative)" refs/heads | less -R'

# Apply the shared response style to every Codex CLI session.
alias codex='codex --profile claude-style'

# -------------------------
# MSYS2 only
# -------------------------
if $is_msys2; then
  # Only 'strict', 'inherit', and 'minimal' exist. This was 'append' -- not a real
  # value, so /etc/profile fell through to its default branch and built a *minimal*
  # PATH (System32/Wbem/PowerShell only), discarding the Windows PATH entirely.
  # Harmless in the shell that sets it (profile already ran), but it's exported, so
  # every child login shell got the stripped PATH -- e.g. every tmux pane, since
  # .tmux.conf sets default-command "/bin/bash -l".
  # 'inherit' is what 'append' was meant to be: /etc/profile puts the MSYS2 dirs
  # first and *appends* the Windows PATH after them, so MSYS2 wins collisions.
  export MSYS2_PATH_TYPE=inherit

  alias ls='ls --color=auto'
  alias grep='grep --color=auto'

  if command -v tree >/dev/null 2>&1; then
    alias tree='tree -C'
  fi

  # Fixes leaked terminal mouse/alt-screen modes after ssh exits badly under tmux
  fix_terminal_leak() {
    printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1015l\e[?2004l\e[?1049l'
    stty sane 2>/dev/null || true
  }

  ssh() {
    command ssh "$@"
    local rc=$?
    fix_terminal_leak
    return $rc
  }

  if command -v cygpath >/dev/null 2>&1; then
    winpath() {
      cygpath -w "$@"
    }

    linpath() {
      cygpath -u "$@"
    }

    # Override because venv activation path differs on Windows
    alias uvshell='source .venv/Scripts/activate'

    # With MSYS2_PATH_TYPE=inherit the Windows PATH arrives appended after the MSYS2
    # dirs, so most of what this block used to add is already present (claude via
    # .local/bin, nvm, nodejs, Python, VS Code, Docker...). Two reasons to still list
    # dirs here: a tool may be installed on one machine without being on that
    # machine's Windows PATH, and $HOME-relative dirs are personal ones no installer
    # registers.
    #
    # The old block hardcoded /c/Users/Alan, which is only correct on the desktop --
    # on a machine with a different Windows username every such entry pointed at a
    # nonexistent directory, which is what hid claude and nvm here.
    #
    # $HOME resolves per-machine (/c/Users/Alan vs /c/Users/alanm). The -d guard
    # makes absent dirs free, so this same list is correct on every machine. The
    # dedupe keeps nested login shells (tmux panes) from stacking duplicates.
    # /ucrt64/bin is deliberately absent: /etc/profile already puts it first.
    # All tests are shell builtins -- no cygpath subshells, so this stays fast.
    for _d in \
      "$HOME/Handle" \
      "$HOME/claude-openrouter" \
      "$HOME/.local/bin" \
      "$HOME/AppData/Roaming/nvm" \
      "$HOME/AppData/Local/Programs/Microsoft VS Code/bin" \
      "$HOME"/AppData/Local/Programs/Python/Python3* \
      "$HOME"/AppData/Local/Programs/Python/Python3*/Scripts \
      /c/nvm4w/nodejs \
      /c/ProgramData/chocolatey/bin \
      "/c/Program Files/Docker/Docker/resources/bin" \
      "/c/Program Files/Amazon/AWSCLIV2"
    do
      if [ -d "$_d" ]; then
        case ":$PATH:" in
          *":$_d:"*) ;;
          *) PATH="$PATH:$_d" ;;
        esac
      fi
    done
    unset _d
    export PATH

    # Windows git must beat any msys/mingw git -- those two fight with each other
    # and the Windows build is the one that behaves. Must stay a prepend: 'inherit'
    # appends the Windows PATH *after* /usr/bin, so a pacman-installed git would
    # otherwise win.
    export PATH="/c/Program Files/Git/cmd:$PATH"
  fi
fi

# -------------------------
# Ubuntu Linux / WSL only
# -------------------------
if $is_linux && ! $is_msys2; then
  # If not running interactively, stop here for Linux shells
  case $- in
    *i*) ;;
    *) return ;;
  esac

  # History / shell behavior
  HISTCONTROL=ignoreboth
  shopt -s histappend
  shopt -s checkwinsize
  HISTSIZE=50000
  HISTFILESIZE=100000

  # lesspipe
  [ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

  # Debian chroot marker for prompt
  if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot="$(cat /etc/debian_chroot)"
  fi

  # Color support for prompt
  case "$TERM" in
    xterm-color|*-256color) color_prompt=yes ;;
  esac

  if [ "${color_prompt:-}" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
  else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
  fi
  unset color_prompt

  # Set terminal title for xterm-like terminals
  case "$TERM" in
    xterm*|rxvt*)
      PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
      ;;
  esac

  # dircolors
  if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  fi

  # Aliases that used to exist in Ubuntu bashrc
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
  alias ll='ls -alF'
  alias la='ls -A'
  alias l='ls -CF'
  alias sentry-cli='sentry'  # agents keep recalling the old name from stale training data

  # Handy function from old bashrc
  c() { cd "$@" && ls; }

  # User-local bins
  export PATH="$HOME/.local/bin:$PATH"

  # Note: do not alias python to an absolute path such as /usr/bin/python3.
  # Aliases take precedence over PATH, so it silently defeats every virtualenv:
  # an activated venv's `python` would still run the system interpreter.

  # Go
  export PATH="$HOME/.local/go/bin:$PATH"

  # Linuxbrew
  if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi

  # nvm (Linux-side only)
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

  # WSL integration
  export BROWSER="wslview"
  export XDG_CONFIG_HOME="$HOME/.config"
  export EDITOR="code --wait"
  export GIT_EDITOR="nvim"

  if $is_wsl; then
    # `code` inside WSL is a thin client that talks to the VS Code extension host
    # over a unix socket named by VSCODE_IPC_HOOK_CLI. Two things rot that value:
    #
    #  1. The socket is per extension host. Every window reload, VS Code upgrade
    #     or WSL reconnect makes a new one. Herdr is a persistent server whose
    #     panes inherit *its* environment, so every Herdr shell keeps pointing at
    #     the socket of whatever terminal launched `herdr` in the first place.
    #  2. WSL sets XDG_RUNTIME_DIR=/run/user/1000 but never registers a logind
    #     session, so unless linger is enabled that directory does not exist and
    #     VS Code fails to bind the socket at all (see
    #     ~/.vscode-server/server-env-setup). Fix: sudo loginctl enable-linger $USER
    #
    # So instead of trusting the inherited value, probe it, and if it is dead find
    # the newest socket that actually accepts a connection. This also selects the
    # freshest launcher, since VS Code deletes the old server build on upgrade.
    __vscode_socket_alive() {
      # $1 = socket path, $2 = node binary to use for the probe
      [ -S "$1" ] || return 1
      "$2" -e '
        const s = require("net").connect(process.argv[1]);
        s.once("connect", () => { s.destroy(); process.exit(0); });
        s.once("error", () => process.exit(1));
        setTimeout(() => process.exit(1), 700).unref();
      ' "$1" >/dev/null 2>&1
    }

    __vscode_find_socket() {
      # Newest connectable vscode-ipc socket across the dirs VS Code may use.
      local node="$1" dir sock
      for dir in "${XDG_RUNTIME_DIR:-}" /tmp; do
        [ -n "$dir" ] && [ -d "$dir" ] || continue
        # shellcheck disable=SC2012
        for sock in $(ls -t "$dir"/vscode-ipc-*.sock 2>/dev/null); do
          if __vscode_socket_alive "$sock" "$node"; then
            printf '%s\n' "$sock"
            return 0
          fi
        done
      done
      return 1
    }

    code() {
      local launcher candidate node sock

      for candidate in "$HOME"/.vscode-server/bin/*/bin/remote-cli/code; do
        [ -x "$candidate" ] || continue
        if [ -z "${launcher:-}" ] || [ "$candidate" -nt "$launcher" ]; then
          launcher="$candidate"
        fi
      done

      if [ -n "${launcher:-}" ]; then
        node="${launcher%/bin/remote-cli/code}/node"
        [ -x "$node" ] || node="$(type -P node)"

        if [ -n "$node" ] && ! __vscode_socket_alive "${VSCODE_IPC_HOOK_CLI:-}" "$node"; then
          if sock="$(__vscode_find_socket "$node")"; then
            VSCODE_IPC_HOOK_CLI="$sock" "$launcher" "$@"
            return $?
          fi
          printf 'code: no live VS Code IPC socket found.\n' >&2
          printf '      Open a new VS Code integrated terminal (that binds a fresh socket) and retry.\n' >&2
          printf '      If none appear, /run/user/%s is probably missing: sudo loginctl enable-linger %s\n' "$(id -u)" "$USER" >&2
          return 1
        fi

        "$launcher" "$@"
        return $?
      fi

      # The WSL server may not be installed yet. Force a fresh PATH lookup instead
      # of consulting a stale Bash hash, then use the Windows launcher if present.
      hash -d code 2>/dev/null || true
      launcher="$(type -P code)"
      if [ -n "$launcher" ] && [ -x "$launcher" ]; then
        "$launcher" "$@"
        return $?
      fi

      printf 'code: no usable VS Code launcher found\n' >&2
      return 127
    }
  fi

  # bun
  export BUN_INSTALL="$HOME/.bun"
  [ -d "$BUN_INSTALL/bin" ] && export PATH="$BUN_INSTALL/bin:$PATH"

  # rust/cargo
  [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

  # opencode
  export PATH="$HOME/.opencode/bin:$PATH"

  # The three below exist for Troutwood app development
  # jdk 17 — the gradle wrapper (9.3.1) and the maestro cli both need it
  [ -d /usr/lib/jvm/java-17-openjdk-amd64 ] && export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"

  # android sdk — adb, sdkmanager. USB is invisible to WSL2 under NAT networking, so the
  # device is attached over wireless debugging: adb pair, adb connect, then
  # `adb reverse tcp:8081 tcp:8081` so the phone can reach Metro.
  export ANDROID_HOME="$HOME/Android/Sdk"
  [ -d "$ANDROID_HOME/platform-tools" ] && export PATH="$ANDROID_HOME/platform-tools:$PATH"
  [ -d "$ANDROID_HOME/cmdline-tools/latest/bin" ] && export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

  # bash aliases file
  if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
  fi

  # bash completion
  if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
      . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
      . /etc/bash_completion
    fi
  fi

  # # Remove Windows Node/npm paths from WSL PATH so Linux tools stay Linux-native
  # PATH="$(printf '%s' "$PATH" | awk -v RS=: -v ORS=: '
  #   !/\/mnt\/c\/.*AppData\/Roaming\/nvm/ &&
  #   !/\/mnt\/c\/.*\/nodejs/ &&
  #   !/\/mnt\/c\/nvm4w\/nodejs/ { print }
  # ' | sed 's/:$//')"
  # export PATH
fi

# -------------------------
# Raspberry Pi only
# -------------------------
if $is_rpi; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
fi

# helpme
[ -f "$HOME/.config/helpme/helpme.bash" ] && source "$HOME/.config/helpme/helpme.bash"
export BUILDX_NO_DEFAULT_ATTESTATIONS=1
