# DevOps Tools Collection

A collection of shell scripts and aliases designed to streamline common development workflows, with a focus on Git, AI assistance, and miscellaneous command-line utilities.

## Features

### Git Enhancements
- **Interactive Branch Management**: Interactively checkout branches with `fzf` and commit previews (`co`), and switch branches while auto-stashing changes (`sb`).
- **Automated Branch Cleanup**: Cleanly remove all local merged branches (`cb`) or all branches except main (`cab`).
- **Smart Commits**: A powerful commit wrapper (`scm`) that can:
    - Automatically stage files.
    - Generate commit messages using an external AI tool.
    - Create a GitLab/GitHub Merge Request on push.
- **Branch Syncing**: Easily update your current branch from the main branch (`ub`) or delete a branch locally and remotely (`db`).

### Miscellaneous Utilities
- **Calculators**: Perform quick command-line arithmetic (`calc`) and VAT calculations (`tax`). Results are copied to the clipboard.
- **Interactive Help**: View `man` pages or `--help` output for any command in an interactive `fzf` window (`help`).
- **Note Archiving**: Archive dated entries in markdown files, ideal for knowledge bases like Obsidian (`archive`).

## Prerequisites
- **Core Libraries**: Fetched via `vendir` from [github.com/fritzduchardt/k8s-tools](https://github.com/fritzduchardt/k8s-tools).
- **Required Tools**:
    - `fzf`
    - `bc`
    - `xclip`
    - An AI tool is needed for the AI commit feature.

## Setup
1. Run `vendir sync` to fetch the required libraries.
2. Source `configrc.sh` in your shell's startup file (e.g., `~/.bashrc`):
   ```bash
   source /path/to/your/repo/configrc.sh
   ```
