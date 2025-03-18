# Misc Scripts Documentation

## calc.sh
Basic calculator that supports standard arithmetic operations. Results are automatically copied to clipboard.

```bash
./calc.sh "2 + 2"    # Basic arithmetic
./calc.sh "2 x 3"    # Multiplication (use 'x' instead of '*')
./calc.sh "[2 + 2]"  # Supports brackets
```

## help.sh
Interactive help viewer for commands using fzf. Shows man pages or --help output.

```bash
./help.sh <command>  # e.g., ./help.sh git
```

## tax.sh
Tax calculation utility with VAT (19%) handling. All results are copied to clipboard.

```bash
# Calculate income, total and VAT for hourly rate
./tax.sh calc <hours> <rate>

# Calculate VAT (19%) for amount
./tax.sh calcVat <amount>

# Calculate gross income (119%)
./tax.sh calcIncome <amount>

# Calculate total with VAT
./tax.sh calcTotal <amount>
```

Note: All calculations use scale=2 for decimal precision and en_US locale for number formatting.
