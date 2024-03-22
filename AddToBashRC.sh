# The below snippets are meant to be pasted into a bashrc.
# source ~/.bashrc to reload

# Use neovim if present. Fallback to vim. Fallback to vi
if command -v nvim >/dev/null 2>&1; then
    export EDITOR='nvim'
elif command -v vim >/dev/null 2>&1; then
    export EDITOR='vim'
else
    export EDITOR='vi'
fi

# c - a function to go to a directory and "see" its contents
c() {
    cd "$1" && ls -a
}

# make python default to python3 (used on ubuntu at least)
alias python=python3
