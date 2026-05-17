import json
import os
import re

def extract_from_log(log_path, target_lib):
    with open(log_path, 'r', encoding='utf-8') as f:
        log_data = f.readlines()
    
    # Store the latest content of each file
    files_content = {}
    
    for line in log_data:
        try:
            entry = json.loads(line)
            if entry.get('source') == 'MODEL' and entry.get('type') == 'PLANNER_RESPONSE':
                tool_calls = entry.get('tool_calls', [])
                for call in tool_calls:
                    name = call.get('name')
                    args = call.get('args', {})
                    if isinstance(args, str):
                        try:
                            args = json.loads(args)
                        except:
                            continue
                            
                    target_file = args.get('TargetFile', '').strip('"')
                    if 'glow_mobile/lib' in target_file:
                        rel_path = target_file.split('glow_mobile/lib/')[1].strip('"')
                        
                        if name == 'write_to_file':
                            content = args.get('CodeContent', '')
                            files_content[rel_path] = content
                        elif name == 'replace_file_content':
                            # This is harder because it's a replacement. 
                            # For simplicity, if we don't have the base, we just store the replacement as "dirty"
                            # but many of these were likely full file writes disguised as replacements or just the important parts.
                            pass 
        except:
            continue

    for rel_path, content in files_content.items():
        dest = os.path.join(target_lib, rel_path)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        with open(dest, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Extracted: {rel_path}")

if __name__ == '__main__':
    log = r'C:\Users\ADMIN\.gemini\antigravity\brain\dc2384e2-bf47-4101-a151-b1a2a8ba75ab\.system_generated\logs\overview.txt'
    lib = r'C:\Users\ADMIN\Desktop\WOMEN TRACKER\glow_mobile\lib'
    extract_from_log(log, lib)
