import re

filepath = r"c:\project\MAKTAB\lib\app_localizations.dart"

with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

# Match each language map section: 'lang': { ... }
def clean_lang_map(match):
    header = match.group(1) # e.g. "'ur': {"
    body = match.group(2)
    footer = match.group(3) # e.g. "    },"

    # Parse key-value lines
    seen = set()
    new_lines = []
    for line in body.split("\n"):
        m = re.search(r"^\s*'([^']+)'\s*:", line)
        if m:
            key = m.group(1)
            if key in seen:
                continue
            seen.add(key)
        new_lines.append(line)
    
    return header + "\n".join(new_lines) + footer

pattern = r"('[a-z]{2}':\s*\{)(.*?)(^\s*\},)"
new_content = re.sub(pattern, clean_lang_map, content, flags=re.DOTALL | re.MULTILINE)

with open(filepath, "w", encoding="utf-8") as f:
    f.write(new_content)

print("Deduplicated app_localizations.dart successfully")
