#!/usr/bin/env python3
import os
import re
import sys


def _replace(m):
    key = m.group(1)
    val = m.group(2)
    if val.startswith('"'):
        return key + '""'
    if val.startswith("'"):
        return key + "''"
    return key


def strip_passwords(filepath):
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()
    # Matches password, pass, passwd fields
    pattern = re.compile(
        r'(["\']?(?:password|passwd|pass)["\']?\s*[:=]\s*)("([^"]*)"|\'([^\']*)\'|[^\s"\',;]+)', re.IGNORECASE
    )
    new_content = pattern.sub(_replace, content)
    if new_content != content:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(new_content)
        return True
    return False


def main():
    list_file = sys.argv[1] if len(sys.argv) > 1 else "source-sensitive.txt"
    if not os.path.isfile(list_file):
        print(f"Error: {list_file} not found")
        sys.exit(1)
    with open(list_file) as f:
        files = [l.strip() for l in f if l.strip() and not l.strip().startswith("#")]
    for fp in files:
        if os.path.isfile(fp):
            print(f"{'Stripped' if strip_passwords(fp) else 'No changes'}: {fp}")
        else:
            print(f"Skipped (not found): {fp}")


if __name__ == "__main__":
    main()
