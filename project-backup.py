#python3 project-backup.py > project-code.txt

#!/usr/bin/env python3
import os
from pathlib import Path

skip = {'node_modules', '.git', '__pycache__', '.env', '.env.local', 
        '.DS_Store', 'Thumbs.db', '*.log', 'backup*', '*.pyc', 
        'package-lock.json'}

def should_skip(path):
    p = str(path)
    return any(s in p for s in skip) or any(p.endswith(ext.replace('*', '')) for ext in skip if ext.startswith('*'))

files = sorted([f for f in Path('.').rglob('*') 
                if f.is_file() and not should_skip(f)])

for f in files:
    print(f'\n# {f}\n')
    try:
        print(f.read_text(encoding='utf-8'))
    except:
        print(f.read_text(encoding='latin-1'))