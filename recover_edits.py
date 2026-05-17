import json
import os
import glob
import re

out_dir = r'C:\Users\ADMIN\Desktop\WOMEN TRACKER\glow_mobile_recovered_edits'
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
            if not line: continue
            try:
                data = json.loads(line)
                if 'tool_calls' in data:
                    for call in data['tool_calls']:
                        name = call['name']
                        if name in ['replace_file_content', 'multi_replace_file_content']:
                            args = call['args']
                            target = args.get('TargetFile', '').replace('\"', '').replace('\\\\', '/').replace('\\', '/')
                            if 'glow_mobile/lib/' not in target: continue
                            rel_path = target.split('glow_mobile/lib/')[1]
                            
                            safe_name = rel_path.replace('/', '_')
                            out_path = os.path.join(out_dir, safe_name + '.txt')
                            
                            with open(out_path, 'a', encoding='utf-8') as out_f:
                                out_f.write(f"\n\n--- {name} from {log_file} ---\n")
                                if name == 'replace_file_content':
                                    content = args.get('ReplacementContent', '')
                                    if content.startswith('\"') and content.endswith('\"'):
                                        content = content[1:-1].replace('\\n', '\n').replace('\\\"', '\"').replace('\\\\', '\\')
                                    out_f.write(content)
                                else:
                                    chunks = args.get('ReplacementChunks', [])
                                    if isinstance(chunks, str):
                                        try:
                                            chunks = json.loads(chunks.replace('\\"', '"'))
                                        except:
                                            pass
                                    if isinstance(chunks, list):
                                        for chunk in chunks:
                                            content = chunk.get('ReplacementContent', '')
                                            out_f.write(content + "\n\n")
                                print(f"Dumped edit for {rel_path}")
            except Exception as e:
                pass
