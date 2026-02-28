import os
import re

d = 'assets/icons'
pattern = re.compile(r'#([A-Fa-f0-9]{2})([A-Fa-f0-9]{6})\b')

for f in os.listdir(d):
    if f.endswith('.svg'):
        path = os.path.join(d, f)
        with open(path, 'r') as file:
            content = file.read()
        
        new_content = pattern.sub(r'#\2', content)
        
        if content != new_content:
            with open(path, 'w') as file:
                file.write(new_content)
            print(f"Fixed colors in {f}")
