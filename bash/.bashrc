#!/usr/bin/env bash

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
# Global (everywhere)
# -------------------------
export UV_ENV_FILE=".env"

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

alias withenv='dotenv -e .env --'

alias gita='git add .'
alias gitb='git branch -a --sort=-committerdate'
alias gits='git status'
alias gitp='git pull --rebase --autostash'

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias tree='tree -C'
export LESS='-R'

# -------------------------
# MSYS2 only
# -------------------------
if $is_msys2; then
  export MSYS2_PATH_TYPE=append

  if command -v cygpath >/dev/null 2>&1; then
    winpath() {
      cygpath -w "$@"
    }

    linpath() {
      cygpath -u "$@"
    }

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
  alias uvshell='source .venv/bin/activate'
fi

# -------------------------
# Raspberry Pi only
# -------------------------
if $is_rpi; then
  # Add Raspberry Pi-specific tweaks here as needed.
  :
fi