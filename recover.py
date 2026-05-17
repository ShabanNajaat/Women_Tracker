import json
import os
import re

log_file = r'C:\Users\ADMIN\.gemini\antigravity\brain\dc2384e2-bf47-4101-a151-b1a2a8ba75ab\.system_generated\logs\overview.txt'
out_dir = r'C:\Users\ADMIN\Desktop\WOMEN TRACKER\glow_mobile_recovered'

os.makedirs(out_dir, exist_ok=True)

with open(log_file, encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        # Remove the preceding "123: " line number prefix if it exists
        match = re.match(r'^\d+:\s*(.*)$', line)
        if match:
            line = match.group(1)
        if not line:
            continue
        try:
            data = json.loads(line)
            if 'tool_calls' in data:
                for call in data['tool_calls']:
                    if call['name'] == 'write_to_file':
                        args = call['args']
                        target = args.get('TargetFile', '').replace('\"', '')
                        # Normalize path
                        target = target.replace('\\\\', '/').replace('\\', '/')
                        if 'glow_mobile/lib/' not in target:
                            continue
                        
                        rel_path = target.split('glow_mobile/lib/')[1]
                        content = args.get('CodeContent', '')
                        if content.startswith('\"') and content.endswith('\"'):
                            # Basic unescaping
                            content = content[1:-1].replace('\\n', '\n').replace('\\\"', '\"').replace('\\\\', '\\')
                        
                        full_path = os.path.join(out_dir, rel_path)
                        os.makedirs(os.path.dirname(full_path), exist_ok=True)
                        with open(full_path, 'w', encoding='utf-8') as out_f:
                            out_f.write(content)
                            print('Recovered', rel_path)
        except Exception as e:
            pass
