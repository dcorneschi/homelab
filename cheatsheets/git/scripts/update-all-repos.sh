#!/bin/bash

# update-all-repos.sh
# Iterates through all subdirectories in the current directory and runs
# 'git pull' on each one that contains a .git folder. Useful for keeping
# multiple cloned repositories up to date in one go.

echo "🔄 Updating all Git repositories in current directory..."

for i in */.git; do
    if [[ -d "$i" ]]; then
        repo_name=$(basename "$(dirname "$i")")
        echo "📁 Updating: $repo_name"
        (cd "$(dirname "$i")" && git pull)
    fi
done

echo "✅ Done!"
