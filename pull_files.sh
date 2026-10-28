#!/usr/bin/env bash

# Exit on unexpected pipeline failures
set -uo pipefail

# 1. Determine script directory and destination path (.src)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${SCRIPT_DIR}/.src"

# 2. Check for the input file argument (defaults to 'list.txt')
INPUT_FILE="${1:-source_dirs.txt}"

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "[-] Error: Input file '$INPUT_FILE' not found."
    echo "    Usage: $0 [path_to_list.txt]"
    exit 1
fi

# 3. Check for root privileges (recommended for system/read-only folders)
if [[ $EUID -ne 0 ]]; then
    echo "[!] Warning: You are not running as root/sudo."
    echo "    Accessing restricted system files may result in 'Permission Denied' errors."
    echo ""
fi

# 4. Create the target destination if it doesn't exist
mkdir -p "$TARGET_DIR"

echo "[*] Pulling files listed in '$INPUT_FILE' to '$TARGET_DIR'..."
echo "------------------------------------------------------------"

# 5. Read the input file line by line
while IFS= read -r line || [[ -n "$line" ]]; do
    # Trim leading/trailing whitespace
    path="$(echo -n "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Skip empty lines and comment lines (starting with #)
    if [[ -z "$path" || "$path" =~ ^# ]]; then
        continue
    fi

    # Check if source exists
    if [[ ! -e "$path" ]]; then
        echo "[x] Missing: '$path' does not exist. Skipping."
        continue
    fi

    echo "[+] Copying: $path"

    # Use rsync with -a (archive: preserve permissions, times, symlinks) 
    # and -R (relative: preserves the directory tree)
    if command -v rsync &> /dev/null; then
        rsync -aR "$path" "$TARGET_DIR/"
    else
        # Fallback to 'cp' if rsync is not installed
        cp -a --parents "$path" "$TARGET_DIR/"
    fi

done < "$INPUT_FILE"

echo "------------------------------------------------------------"
echo "[✓] Done! Files copied to: $TARGET_DIR"