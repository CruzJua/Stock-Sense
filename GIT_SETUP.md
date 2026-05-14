# StockSense — Git Setup & Workflow Guide

This document covers everything you need to initialize the repository, make your first commit, connect to GitHub, and follow a professional Git workflow for the duration of the project.

---

## Table of Contents

- [Initial Repository Setup](#initial-repository-setup)
- [First Commit](#first-commit)
- [Connecting to GitHub](#connecting-to-github)
- [Pushing to GitHub](#pushing-to-github)
- [Daily Workflow](#daily-workflow)
- [Branch Strategy](#branch-strategy)
- [Commit Message Convention](#commit-message-convention)
- [Useful Git Commands](#useful-git-commands)
- [GitHub Actions CI (Optional)](#github-actions-ci-optional)

---

## Initial Repository Setup

If you haven't initialized Git yet, run these commands from the project root:

```bash
# Navigate to your project folder
cd path/to/stocksense

# Initialize a new Git repository
git init

# Set the default branch name to 'main'
git branch -M main

# Configure your identity (required for commits)
git config user.name "Your Name"
git config user.email "jucruz@student.neumont.edu"
```

---

## First Commit

Stage all project files and create the initial commit:

```bash
# Stage all files (respects .gitignore)
git add .

# Verify what is staged before committing
git status

# Create the initial commit
git commit -m "feat: initial project setup — Flutter + Supabase scaffold

- Add README.md with full project documentation
- Add .gitignore for Flutter/Dart, Supabase, and secrets
- Add GIT_SETUP.md with workflow guide
- Add project pitch document
- Add recommended folder structure"
```

---

## Connecting to GitHub

### Option A — Create a new repository on GitHub first (recommended)

1. Go to [github.com/new](https://github.com/new)
2. Set the repository name to `stocksense`
3. Set visibility to **Private** (course project)
4. **Do NOT** initialize with a README, .gitignore, or license (you already have these)
5. Click **Create repository**
6. Copy the remote URL shown (HTTPS or SSH)

```bash
# Add GitHub as the remote origin (replace with your actual URL)
git remote add origin https://github.com/<your-username>/stocksense.git

# Confirm the remote was added
git remote -v
```

### Option B — If you already have a remote set up

```bash
# Check your current remotes
git remote -v

# Update the remote URL if needed
git remote set-url origin https://github.com/<your-username>/stocksense.git
```

---

## Pushing to GitHub

```bash
# Push the main branch and set it as the upstream tracking branch
git push -u origin main
```

After the first push, subsequent pushes only require:

```bash
git push
```

---

## Daily Workflow

Follow this pattern for every development session:

```bash
# 1. Pull the latest changes from GitHub before starting work
git pull origin main

# 2. Create a new feature branch for your work
git checkout -b feature/scan-camera-integration

# 3. Make your changes, then stage specific files
git add lib/features/scan/

# 4. Or stage all modified tracked files
git add -A

# 5. Check what you're about to commit
git status
git diff --staged

# 6. Commit with a descriptive message
git commit -m "feat(scan): integrate Flutter camera plugin with image compression"

# 7. Push your feature branch to GitHub
git push origin feature/scan-camera-integration

# 8. Open a Pull Request on GitHub to merge into main
```

---

## Branch Strategy

Use the following branching model for the 4-week development timeline:

```
main                  ← stable, always deployable
  └── develop         ← integration branch (optional for larger teams)
        ├── feature/auth-setup
        ├── feature/ai-scan-core
        ├── feature/inventory-list
        ├── feature/semantic-search
        ├── feature/push-notifications
        ├── feature/offline-hive-cache
        └── fix/scan-confirmation-ui-bug
```

### Branch naming conventions

| Type | Pattern | Example |
|---|---|---|
| New feature | `feature/<short-description>` | `feature/inventory-semantic-search` |
| Bug fix | `fix/<short-description>` | `fix/expiry-date-null-crash` |
| Supabase / backend | `supabase/<description>` | `supabase/edge-function-orchestrator` |
| UI work | `ui/<screen-name>` | `ui/scan-confirmation-screen` |
| Documentation | `docs/<description>` | `docs/update-setup-guide` |
| Hotfix on main | `hotfix/<description>` | `hotfix/auth-token-refresh` |

```bash
# Create and switch to a new branch
git checkout -b feature/inventory-semantic-search

# List all local branches
git branch

# List all branches (including remote)
git branch -a

# Switch to an existing branch
git checkout main

# Delete a merged feature branch locally
git branch -d feature/inventory-semantic-search

# Delete a remote branch after merging
git push origin --delete feature/inventory-semantic-search
```

---

## Commit Message Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/) for clear, readable history.

### Format

```
<type>(<scope>): <short summary>

[optional body]

[optional footer]
```

### Types

| Type | When to use |
|---|---|
| `feat` | A new feature |
| `fix` | A bug fix |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `style` | Formatting, missing semicolons, whitespace (no logic change) |
| `test` | Adding or updating tests |
| `docs` | Documentation only changes |
| `chore` | Build process, dependency updates, config changes |
| `perf` | Performance improvement |

### Scopes (optional but recommended)

`auth`, `scan`, `inventory`, `search`, `notifications`, `supabase`, `ui`, `core`

### Examples

```bash
git commit -m "feat(auth): add Google OAuth sign-in via Supabase Auth"
git commit -m "feat(scan): integrate GPT-4o Vision for receipt OCR"
git commit -m "feat(inventory): implement pgvector semantic search"
git commit -m "fix(scan): handle null response from Cloud Vision API"
git commit -m "chore: upgrade flutter_riverpod to 2.5.1"
git commit -m "docs: update README with Supabase schema section"
git commit -m "test(inventory): add unit tests for item expiry logic"
```

---

## Useful Git Commands

### Viewing History

```bash
# View commit history (compact)
git log --oneline

# View commit history with branch graph
git log --oneline --graph --all

# View changes in the last commit
git show HEAD

# View all changes since last commit
git diff
```

### Undoing Changes

```bash
# Unstage a file (keeps your changes)
git restore --staged lib/features/scan/scan_screen.dart

# Discard local changes to a file (destructive — cannot be undone)
git restore lib/features/scan/scan_screen.dart

# Undo the last commit but keep your changes staged
git reset --soft HEAD~1

# Create a new commit that undoes a previous commit (safe for shared branches)
git revert <commit-hash>
```

### Syncing & Merging

```bash
# Fetch updates from GitHub without merging
git fetch origin

# Pull and rebase (cleaner history than merge)
git pull --rebase origin main

# Merge a feature branch into main
git checkout main
git merge feature/inventory-semantic-search

# Rebase your branch on top of main (keeps history linear)
git checkout feature/scan-camera-integration
git rebase main
```

### Stashing

```bash
# Stash uncommitted work temporarily (e.g., to switch branches)
git stash

# List all stashes
git stash list

# Apply the most recent stash and remove it from the stash list
git stash pop

# Apply a specific stash without removing it
git stash apply stash@{2}
```

### Tags (for course milestones)

```bash
# Tag a release or milestone
git tag -a v0.1.0-mvp -m "MVP: AI scan + inventory + semantic search complete"

# Push tags to GitHub
git push origin --tags

# List all tags
git tag
```

---

## GitHub Actions CI (Optional)

For automated testing on every push, create `.github/workflows/flutter_ci.yml`:

```yaml
name: Flutter CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

This will automatically lint and test your code on every push and pull request, ensuring the `main` branch stays green.

---

## Quick Reference Card

```bash
# --- Setup (one time) ---
git init && git branch -M main
git remote add origin https://github.com/<you>/stocksense.git

# --- Every session ---
git pull                                  # get latest
git checkout -b feature/<name>            # new branch
# ... make changes ...
git add .                                 # stage
git commit -m "feat(<scope>): <summary>"  # commit
git push origin feature/<name>            # push

# --- Merge to main (via GitHub PR or locally) ---
git checkout main
git merge feature/<name>
git push

# --- Cleanup ---
git branch -d feature/<name>
git push origin --delete feature/<name>
```

---

*StockSense · Git Workflow Guide · Neumont College of Computer Science · 2026*
