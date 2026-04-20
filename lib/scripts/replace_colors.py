import os
import re

lib_dir = '/Users/macbook/Projects/dextera/lib'

def process_file(filepath):
    if 'app_theme.dart' in filepath:
        return
    with open(filepath, 'r') as f:
        content = f.read()

    # Replacements
    new_content = content
    # Replace Colors.white exactly
    new_content = re.sub(r'Colors\.white(?!\d|\.)', 'whiteClr', new_content)
    # Replace Colors.white54 etc.
    new_content = re.sub(r'Colors\.white(\d{2})', r'whiteClr.withOpacity(0.\1)', new_content)
    # Replace Colors.transparent with Colors.transparent (no change)
    # Replace hardcoded dark colors
    new_content = re.sub(r'const\s*Color\(0xFF2A3340\)', 'drawerClr', new_content)
    new_content = re.sub(r'Color\(0xFF2A3340\)', 'drawerClr', new_content)
    new_content = re.sub(r'const\s*Color\(0xFF1A1F27\)', 'drawerClr', new_content)
    new_content = re.sub(r'Color\(0xFF1A1F27\)', 'drawerClr', new_content)
    new_content = re.sub(r'const\s*Color\(0xFF2B3540\)', 'drawerClr', new_content)
    new_content = re.sub(r'Color\(0xFF2B3540\)', 'drawerClr', new_content)
    
    # We must ensure app_theme is imported if we are using whiteClr or drawerClr!
    if new_content != content:
        if 'package:dextera/core/app_theme.dart' not in new_content:
            # add import
            import_statement = "import 'package:dextera/core/app_theme.dart';\n"
            # find first import
            import_idx = new_content.find("import ")
            if import_idx != -1:
                new_content = new_content[:import_idx] + import_statement + new_content[import_idx:]
            else:
                new_content = import_statement + new_content
                
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, _, files in os.walk(lib_dir):
    for filename in files:
        if filename.endswith('.dart'):
            process_file(os.path.join(root, filename))

print("Done")
