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

  # Handy function from old bashrc
  c() { cd "$@" && ls; }

  # User-local bins
  export PATH="$HOME/.local/bin:$PATH"

  # Python alias from old config
  alias python="/usr/bin/python3"

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

  # bun
  export BUN_INSTALL="$HOME/.bun"
  [ -d "$BUN_INSTALL/bin" ] && export PATH="$BUN_INSTALL/bin:$PATH"

  # rust/cargo
  [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

  # opencode
  export PATH="$HOME/.opencode/bin:$PATH"

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

# -------------------------
# Zellij auto-attach (VS Code)
# -------------------------
# In VS Code's integrated terminal, drop straight into a per-project Zellij
# session named after the folder VS Code opened. Pair with the VS Code setting
# terminal.integrated.enablePersistentSessions=false so opening/reloading a
# folder spawns a fresh terminal (which runs this) instead of a dead one.
# Opt a shell/project out with:  ZELLIJ_AUTO=0
if [[ $- == *i* ]] \
   && [[ "${TERM_PROGRAM:-}" == "vscode" ]] \
   && [[ -z "${ZELLIJ:-}" ]] \
   && [[ "${ZELLIJ_AUTO:-1}" != "0" ]] \
   && command -v zellij >/dev/null 2>&1; then
  zj_session="${PWD##*/}"          # basename of the workspace folder
  zj_session="${zj_session// /-}"  # spaces -> dashes (Zellij dislikes spaces)

  # Work around a VS Code + Zellij startup race: a *newly created* session reads
  # the pty size too early and is born tiny (~80 cols), leaving dead space and a
  # glitchy state (new panes render off-screen). So:
  #   1. create it DETACHED — no mis-sized render happens at creation
  #   2. wait until VS Code has finished sizing the pty (width climbs past the
  #      bogus ~80-col default)
  #   3. ATTACH — the attach path tracks the real terminal size correctly, which
  #      is why attaching to pre-existing sessions always worked
  zellij attach --create-background "$zj_session"
  for _ in {1..20}; do [[ "$(tput cols 2>/dev/null || echo 0)" -gt 80 ]] && break; sleep 0.05; done
  exec zellij attach --create "$zj_session"
fi

# helpme
source "/home/alan/.config/helpme/helpme.bash"
