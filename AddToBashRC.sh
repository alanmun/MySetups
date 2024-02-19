# The below snippets are meant to be pasted into a bashrc.
# source ~/.bashrc to reload

# c - a function to go to a directory and "see" its contents
c() {
    cd "$1" && ls -a
}

# make python default to python3 (used on ubuntu at least)
alias python=python3
