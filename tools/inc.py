import os
import re

root = "."
N = 15  # Change this threshold

pattern = re.compile(r'\bmov dh,\s*(\d+)', re.IGNORECASE)

for dirpath, dirs, filenames in os.walk(root):
	for filename in filenames:
		path = os.path.join(dirpath, filename)

		try:
			with open(path, "r", encoding="utf-8") as f:
				content = f.read()
		except (UnicodeDecodeError, OSError):
			continue

		def increment(match):
			x = int(match.group(1))

			if x <= N:
				return match.group(0)

			return f"{match.group(0)[:match.group(0).rfind(match.group(1))]}{x + 1}"

		new_content = pattern.sub(increment, content)

		if new_content != content:
			with open(path, "w", encoding="utf-8") as f:
				f.write(new_content)

			print(f"Modified: {path}")

print("Done.")