#!/usr/bin/env python3
"""Read concrete SSH aliases, following Include without running SSH commands."""
import glob
from pathlib import Path
import shlex

seen, hosts = set(), set()
def read(path):
    path = Path(path).expanduser().resolve()
    if path in seen or len(seen) >= 100 or not path.is_file():
        return
    seen.add(path)
    for line in path.read_text(errors='replace').splitlines():
        try:
            fields = shlex.split(line, comments=True)
        except ValueError:
            continue
        if not fields:
            continue
        key, *values = fields
        if '=' in key:
            key, value = key.split('=', 1)
            values.insert(0, value)
        if values and values[0] == '=':
            values.pop(0)
        if key.lower() == 'host':
            hosts.update(h for h in values if h and not h.startswith('-') and not any(c in h for c in '*?!'))
        elif key.lower() == 'include':
            for value in values:
                pattern = Path(value).expanduser()
                if not pattern.is_absolute():
                    pattern = Path.home() / '.ssh' / pattern
                for match in glob.glob(str(pattern)):
                    read(match)
read(Path.home() / '.ssh/config')
print('\n'.join(sorted(hosts)))
