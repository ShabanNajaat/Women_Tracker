import os
import re
import json

def sanitize_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    clean_lines = []
    for line in lines:
        # Skip log headers
        if line.strip().startswith('---') and '---' in line[3:]:
            continue
        
        # Skip lines that are just whitespace after header removal
        if not line.strip():
            # But keep one newline if the previous line wasn't empty
            if clean_lines and clean_lines[-1].strip():
                clean_lines.append('\n')
            continue

        # Check if the line is a JSON-escaped string (common in recovered logs)
        # e.g., "import 'package:flutter/material.dart';\n..."
        if line.strip().startswith('"') and line.strip().endswith('"'):
            try:
                # Try to unescape it
                unescaped = json.loads(line.strip())
                clean_lines.append(unescaped)
                continue
            except json.JSONDecodeError:
                pass
        
        # Check for truncated indicator and skip
        if '<truncated' in line:
            continue
            
        clean_lines.append(line)

    content = "".join(clean_lines)
    
    # If the whole content is a quoted string with escaped newlines
    if content.strip().startswith('"') and content.strip().endswith('"'):
        try:
            content = json.loads(content.strip())
        except:
            pass

    # Fix literal \n and \t
    content = content.replace('\\n', '\n').replace('\\t', '\t').replace('\\"', '"')
    
    # Remove any remaining log artifacts like <truncated ...>
    content = re.sub(r'<truncated.*?>', '', content)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Sanitized: {filepath}")

def sanitize_lib(lib_path):
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                sanitize_file(os.path.join(root, file))

if __name__ == '__main__':
    lib_dir = r'C:\Users\ADMIN\Desktop\WOMEN TRACKER\glow_mobile\lib'
    sanitize_lib(lib_dir)
