import json
import os
import glob
import re

out_dir = r'C:\Users\ADMIN\Desktop\WOMEN TRACKER\glow_mobile_recovered'
os.makedirs(out_dir, exist_ok=True)

brain_dir = r'C:\Users\ADMIN\.gemini\antigravity\brain'
log_files = glob.glob(os.path.join(brain_dir, '*', '.system_generated', 'logs', 'overview.txt'))

for log_file in log_files:
    with open(log_file, encoding='utf-8') as f:
        for line in f:
            line = line.strip()
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
                                print(f"Recovered {rel_path} from {log_file}")
            except Exception as e:
                pass
