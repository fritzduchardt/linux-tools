Here's a concise documentation for the fabric scripts:

```markdown
# Fabric Scripts Documentation

Collection of scripts for interacting with a fabric pattern system.

## Core Script (fabric.sh)

Main interface for fabric operations.

```bash
fbrc [OPTIONS] [prompt]

Options:
  -i INPUTFILE     Input file to process
  -o              Overwrite input file
  -s SESSION      Specify session ID
  -c              Toggle clipboard copy
  -h              Show help
  --continue      Continue last session
```

## Utility Scripts

### fabric_build.sh
Generates files from descriptions provided via stdin.
```bash
echo "path/to/file -- description" | fbrc_build
```

### fabric_chat.sh
Interactive chat interface using last fabric command.
```bash
fbrc_chat [prompt]
```

### fabric_improve.sh
Improves content of specified files.
```bash
fbrc_improve -i file [-s session] [--continue]
```

### fabric_stdin.sh
Process multi-line input from stdin.
```bash
echo -e "line1\nline2" | fbrc_stdin [options]
```

## Library (fabric_lib.sh)
Common utilities for clipboard operations and session management.
```
```
