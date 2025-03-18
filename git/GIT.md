# Git Utility Scripts Documentation

A collection of bash scripts to simplify common git operations.

## Scripts

### checkout.sh
Interactive branch checkout using fzf with preview of branch commits.
```bash
./checkout.sh [branch-query]
```

### clean_all_branches.sh
Delete all local branches except main. Optionally delete remote branches.
```bash
./clean_all_branches.sh [force]  # Use 'force' to delete remote branches
```

### clean_branches.sh
Delete all merged branches into main branch.
```bash
./clean_branches.sh
```

### delete_branch.sh
Delete both local and remote branch.
```bash
./delete_branch.sh <branch-name>
```

### simple_commit.sh
Smart commit with optional AI-generated messages and MR creation.
```bash
./simple_commit.sh [-m create-mr] [-f force-push] [-p push] [commit-message]
```

### switch_branch.sh
Switch to a new or existing branch, stashing changes.
```bash
./switch_branch.sh <branch-name>
```

### update_branch.sh
Update current branch with latest changes from main.
```bash
./update_branch.sh
```

## Library

### git_lib.sh
Utility functions:
- `find_main_branch()`: Detect repository's main branch
- `find_current_branch()`: Get current branch name
