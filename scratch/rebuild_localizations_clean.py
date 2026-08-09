import re

filepath = r"c:\project\MAKTAB\lib\app_localizations.dart"

with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

# Locate _localizedValues
match = re.search(r"(static const _localizedValues = <String, Map<String, String>>\{)(.*?)(\n  \};\n)", content, re.DOTALL)
if match:
    prefix = content[:match.start()]
    map_body = match.group(2)
    suffix = content[match.end():]

    # Find each 'xx': { ... }
    lang_blocks = re.findall(r"('[a-z]{2}':\s*\{)(.*?)(^\s*\},)", map_body, re.DOTALL | re.MULTILINE)
    
    rebuilt_map = ["static const _localizedValues = <String, Map<String, String>>{"]

    for header, body, footer in lang_blocks:
        rebuilt_map.append(f"  {header}")
        seen_keys = set()
        for line in body.split("\n"):
            # Extract key if line is 'key': 'val',
            km = re.search(r"^\s*'([^']+)'\s*:", line)
            if km:
                k = km.group(1)
                if k in seen_keys:
                    continue
                seen_keys.add(k)
            if line.strip():
                rebuilt_map.append(line)
        rebuilt_map.append("    },")
    
    rebuilt_map.append("  };")
    
    final_content = prefix + "\n".join(rebuilt_map) + "\n" + suffix

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(final_content)

    print("Rebuilt app_localizations.dart cleanly!")
