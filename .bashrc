export MSYS2_PATH_TYPE=append #  appends the Windows PATH entries only from MSYS2 processes (not full Windows system PATH).
export UV_ENV_FILE=".env"

# unix → windows
winpath() {
  cygpath -w "$@"
}

# windows → unix
linpath() {
  cygpath -u "$@"
}

#with dotenv-cli, an easier alias to type
alias withenv='dotenv -e .env --'

# uv shell (fake pipenv shell)
alias uvshell='source .venv/Scripts/activate'

# git status faster
alias gits="git status"

export PATH="$PATH:/c/Users/Alan/AppData/Local/Programs/Microsoft VS Code/bin"
export PATH="$PATH:$(linpath 'C:\Users\Alan\AppData\Local\Programs\Python\Python312\')"
export PATH="$PATH:$(linpath 'C:\Users\Alan\AppData\Local\Programs\Python\Python312\Scripts')"
export PATH="$PATH:$(linpath 'c:\programdata\chocolatey\bin\')"
export PATH="$PATH:$(linpath 'c:\program files\Docker\Docker\resources\bin\')"
# export PATH="$PATH:$(linpath 'C:\Program Files\Git LFS\')"
export PATH="$(linpath 'c:\program files\Git\cmd\'):$PATH" # mingw & msys git versions just fight w each other & appear to be buggy. Just running the windows copy of git works
export PATH="$PATH:$(linpath 'C:\Users\Alan\.local\bin')"
export PATH="$PATH:$(linpath 'C:\nvm4w\nodejs\')"
export PATH="$PATH:$(linpath 'C:\program files\Amazon\AWSCLIV2\')"
export PATH="$PATH:$(linpath 'C:\Users\Alan\AppData\Roaming\nvm\')"
export PATH="$PATH:/ucrt64/bin"
export PATH="$PATH:$(linpath 'C:\Users\Alan\Handle')"

# Colorize by default
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias tree='tree -C'
export LESS='-R' # Seems to colorize git commands too

# Use exa where available, fallback to ls if exa can't work
# ! Disabled because I'm not sure if MSYS2 has exa support yet or not
# if command -v exa >/dev/null; then
#   alias ls='exa --icons --group-directories-first --color=auto'
# else
#   alias ls='ls --color=auto --group-directories-first'
# fi
