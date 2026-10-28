#!/usr/bin/env bash

set -euo pipefail

# 1. STRICT ROOT / SUDO CHECK
if [[ $EUID -ne 0 ]]; then
    echo "[-] Error: This script must be run as root because it modifies system files." >&2
    echo "    Please run using: sudo $0 [path_to_list.txt]" >&2
    exit 1
fi

# 2. Define directories and input file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/.src"
INPUT_FILE="${1:-source_dirs.txt}"

# 3. Validations
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "[-] Error: List file '$INPUT_FILE' not found." >&2
    exit 1
fi

if [[ ! -d "$SRC_DIR" ]]; then
    echo "[-] Error: Source directory '$SRC_DIR' does not exist." >&2
    exit 1
fi

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

echo "[*] Reading restore targets from: $INPUT_FILE"
echo "[*] Backups will use suffix: .bak_${TIMESTAMP}"
echo "------------------------------------------------------------"

# 4. Read list.txt line by line
while IFS= read -r line || [[ -n "$line" ]]; do
    # Trim leading/trailing whitespace
    path="$(echo -n "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Skip empty lines and comments
    if [[ -z "$path" || "$path" =~ ^# ]]; then
        continue
    fi

    # Normalize paths (remove leading slash for .src lookup)
    clean_path="${path#/}"
    src_item="${SRC_DIR}/${clean_path}"
    dest="/${clean_path}"

    # Check if the backup copy actually exists in .src
    if [[ ! -e "$src_item" ]]; then
        echo "[x] Missing in .src: '$src_item'. Skipping."
        continue
    fi

    # Case A: Restoring a DIRECTORY
    if [[ -d "$src_item" ]]; then
        if [[ -e "$dest" ]]; then
            backup_path="${dest}.bak_${TIMESTAMP}"
            echo "[!] Backing up directory: $dest -> $backup_path"
            cp -a "$dest" "$backup_path"
        fi

        echo "[+] Restoring directory:  $src_item -> $dest"
        mkdir -p "$dest"
        
        # Copy folder contents preserving permissions
        if command -v rsync &> /dev/null; then
            rsync -a "$src_item/" "$dest/"
        else
            cp -a "$src_item/." "$dest/"
        fi

    # Case B: Restoring a FILE or SYMLINK
    elif [[ -f "$src_item" || -L "$src_item" ]]; then
        mkdir -p "$(dirname "$dest")"

        if [[ -e "$dest" || -L "$dest" ]]; then
            backup_path="${dest}.bak_${TIMESTAMP}"
            echo "[!] Backing up file: $dest -> $backup_path"
            cp -af "$dest" "$backup_path"
        fi

        echo "[+] Restoring file:  $src_item -> $dest"
        cp -af "$src_item" "$dest"
    fi

done < "$INPUT_FILE"

echo "------------------------------------------------------------"
echo "[✓] Selected files/folders restored successfully."