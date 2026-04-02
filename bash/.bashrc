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
# Linux / WSL only
# -------------------------
if $is_linux && ! $is_msys2; then
  export PATH="$HOME/.local/bin:$PATH"

  alias ls='ls --color=auto'
  alias grep='grep --color=auto'

  if command -v tree >/dev/null 2>&1; then
    alias tree='tree -C'
  fi

  if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
      . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
      . /etc/bash_completion
    fi
  fi
fi

# -------------------------
# Raspberry Pi only
# -------------------------
if $is_rpi; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
fi
