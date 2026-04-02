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
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

export UV_ENV_FILE=".env"
export LESS='-R'

alias withenv='dotenv -e .env --'
alias uvshell='source .venv/bin/activate'

alias gita='git add -A'
alias gits='git status'
alias gitp='git push'

gitb() {
  git for-each-ref \
    --sort=-committerdate \
    --format='%(if)%(HEAD)%(then)* %(else)  %(end)%(refname:short)  %(committerdate:relative)' \
    refs/heads | less -R
}

# -------------------------
# MSYS2 only
# -------------------------
if $is_msys2; then
  export MSYS2_PATH_TYPE=append

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

    export PATH="$PATH:/c/Users/Alan/AppData/Local/Programs/Microsoft VS Code/bin"
    export PATH="$PATH:$(linpath 'C:\Users\Alan\AppData\Local\Programs\Python\Python312\')"
    export PATH="$PATH:$(linpath 'C:\Users\Alan\AppData\Local\Programs\Python\Python312\Scripts')"
    export PATH="$PATH:$(linpath 'c:\programdata\chocolatey\bin\')"
    export PATH="$PATH:$(linpath 'c:\program files\Docker\Docker\resources\bin\')"
    export PATH="$(linpath 'c:\program files\Git\cmd\'):$PATH"
    export PATH="$PATH:$(linpath 'C:\Users\Alan\.local\bin')"
    export PATH="$PATH:$(linpath 'C:\nvm4w\nodejs\')"
    export PATH="$PATH:$(linpath 'C:\program files\Amazon\AWSCLIV2\')"
    export PATH="$PATH:$(linpath 'C:\Users\Alan\AppData\Roaming\nvm\')"
    export PATH="$PATH:/ucrt64/bin"
    export PATH="$PATH:$(linpath 'C:\Users\Alan\Handle')"
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
  HISTSIZE=1000
  HISTFILESIZE=2000

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
  export PATH="/usr/local/go/bin:$PATH"

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
