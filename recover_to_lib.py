import os
import glob
import pathlib

def copy_recovered_to_lib():
    src_dir = r'C:\Users\ADMIN\Desktop\WOMEN TRACKER\glow_mobile_recovered_edits'
    dest_root = r'C:\Users\ADMIN\Desktop\WOMEN TRACKER\glow_mobile\lib'
    # Find all .txt files
    for txt_path in glob.glob(os.path.join(src_dir, '**', '*.txt'), recursive=True):
        # Determine relative path inside src_dir
        rel_path = os.path.relpath(txt_path, src_dir)
        # Remove .txt extension and ensure .dart extension
        base, _ = os.path.splitext(rel_path)
        # Some files may have naming like screens_dashboard_screen.dart.txt => we want lib/screens/dashboard_screen.dart
        # Replace underscores that separate directories with os.sep where appropriate
        # The convention: <folder>_<filename>.dart.txt indicates folder/filename.dart
        parts = base.split('_')
        # If the first part is a folder name like 'screens', then join accordingly
        if parts[0] in ['screens', 'widgets', 'services', 'models', 'theme']:
            # join folder with the rest as filename (joined with underscores for multi-part names)
            folder = parts[0]
            # Ensure we don't double append .dart
            rest = '_'.join(parts[1:])
            if rest.endswith('.dart'):
                filename = rest
            else:
                filename = rest + '.dart'
            dest_path = os.path.join(dest_root, folder, filename)
        else:
            # fallback: ensure it ends with .dart
            if not base.endswith('.dart'):
                dest_path = os.path.join(dest_root, base + '.dart')
            else:
                dest_path = os.path.join(dest_root, base)
        os.makedirs(os.path.dirname(dest_path), exist_ok=True)
        with open(txt_path, 'r', encoding='utf-8') as src_f:
            content = src_f.read()
        # Write content to destination
        with open(dest_path, 'w', encoding='utf-8') as dst_f:
            dst_f.write(content)
        print(f"Copied {txt_path} -> {dest_path}")

if __name__ == '__main__':
    copy_recovered_to_lib()
