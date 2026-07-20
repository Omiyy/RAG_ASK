#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== RAG_ASK Git History Creator ==="
echo "This script will initialize/re-initialize your Git repository and create"
echo "a logical, backdated commit history from July 15 to July 20, 2026."
echo ""

# Safety check: If a .git directory already exists, ask the user or recommend cleaning it.
if [ -d ".git" ]; then
    echo "WARNING: A .git directory already exists in this folder."
    if [ "$1" = "-y" ] || [ "$1" = "--force" ]; then
        rm -rf .git
        echo "Removed existing .git directory (--force)."
    else
        echo "To create a clean new history, you should delete the existing .git directory first."
        echo "You can do this by running: rm -rf .git"
        read -p "Do you want to delete the existing .git folder and proceed? (y/N) " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            rm -rf .git
            echo "Removed existing .git directory."
        else
            echo "Aborting script to prevent overwriting your current git history."
            exit 1
        fi
    fi
fi

# 1. Initialize Git repository
git init
echo "Initialized empty Git repository."

# Set default branch to main
git branch -M main || git checkout -b main

# 2. Configure identity locally for this repository
echo "Setting local repository Git identity to Om Singhal..."
git config user.name "Om Singhal"
git config user.email "omsinghal@example.com"

# Helper function to make backdated commits
make_commit() {
    local date="$1"
    local message="$2"
    
    # Set Git author and committer dates
    export GIT_AUTHOR_DATE="$date"
    export GIT_COMMITTER_DATE="$date"
    
    # Commit the staged changes
    git commit -m "$message"
    
    # Unset the variables to avoid side effects
    unset GIT_AUTHOR_DATE
    unset GIT_COMMITTER_DATE
}

# -------------------------------------------------------------
# Commit 1: Project Setup (July 15, 2026)
# -------------------------------------------------------------
echo "Creating Commit 1 (July 15, 2026)..."
git add .gitignore LICENSE
make_commit "2026-07-15 10:00:00" "chore: initialize project with gitignore and license"

# -------------------------------------------------------------
# Commit 2: Notebook & Data Loading Prototyping (July 16, 2026)
# -------------------------------------------------------------
echo "Creating Commit 2 (July 16, 2026)..."
git add main.ipynb
if [ -d "vectorDB" ]; then
    git add -f vectorDB/
fi
make_commit "2026-07-16 14:30:00" "feat: add main.ipynb and generate local FAISS vector database"

# -------------------------------------------------------------
# Commit 3: Streamlit UI and RAG Implementation (July 18, 2026)
# -------------------------------------------------------------
echo "Creating Commit 3 (July 18, 2026)..."
git add app.py requirements.txt
make_commit "2026-07-18 11:15:00" "feat: implement Streamlit chat UI and Gemini integration"

# -------------------------------------------------------------
# Commit 4: Assets and Logo Integration (July 19, 2026)
# -------------------------------------------------------------
echo "Creating Commit 4 (July 19, 2026)..."
# Force-add images since standard formats (*.png, *.jpeg) are ignored in .gitignore
added_assets=false

if [ -f "screenshot.png" ]; then
    git add -f screenshot.png
    added_assets=true
fi

if [ -d "photo" ]; then
    git add -f photo/
    added_assets=true
fi

if [ "$added_assets" = true ]; then
    make_commit "2026-07-19 16:45:00" "style: add user interface screenshot and school logo"
else
    echo "No assets (screenshot or logo folder) found. Skipping Commit 4."
fi

# -------------------------------------------------------------
# Commit 5: Finalize Documentation (July 20, 2026)
# -------------------------------------------------------------
echo "Creating Commit 5 (July 20, 2026)..."
git add README.md commit.sh
make_commit "2026-07-20 09:30:00" "docs: finalize readme and add repository setup script"

echo ""
echo "=== Git History Successfully Created! ==="
echo "You can check the history using: git log --oneline --graph"
echo "To push this to a new GitHub repo, run:"
echo "  git remote add origin <your-github-repo-url>"
echo "  git push -u origin main"
