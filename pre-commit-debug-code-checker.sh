#!/bin/bash
# Search for keywords "test", "testing", "debug", 
# single-line comments starting with any number of '#' or '//', followed by '!', and
# Python multi-line comments where '!' is at the start of a line or the start of a comment.

# Regex pattern to match "test", "testing", or "debug" (case-insensitive)
pattern_keywords="(\b(test|debug)|!)"

# Regex pattern to match single-line comments with '#', followed by spaces and '!'
pattern_single_comment=".*(#|//)+\s*${pattern_keywords}"

# Regex pattern to match Python triple-quoted multiline comments (""") and (''')
# where '!' appears at the beginning of a line
pattern_multiline_comment_python="^.*(\"\"\"|''').*?\n\s*!\s*(.|\n)*?(\"\"\"|''')"

# Combine all patterns
final_pattern="${pattern_single_comment}|${pattern_multiline_comment_python}"

# Get the list of files that are staged for commit
staged_files=$(git diff --cached --name-only)

# Initialize an empty variable to hold offending lines
offending_lines=""

# Loop over each staged file and check for suspicious comments
for file in $staged_files; do
    if [[ -f "$file" ]]; then  # Ensure it is a file
        # Search the file for matching patterns
        matches=$(pcregrep -inM "$final_pattern" "$file")
        if [[ -n "$matches" ]]; then
          offending_lines+=$(echo -e "\n\n$file:\n$matches\n\n")
        fi
    fi
done

if [[ -n "$offending_lines" ]]; then
    echo "WARNING: Found suspicious debugging comments in your code: $offending_lines"

    exit 1
fi

exit 0 # Allow commit, just show the warning
