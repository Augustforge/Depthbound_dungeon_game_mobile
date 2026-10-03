#!/usr/bin/env python3
"""Model textures for phones: VRAM-compressed (ETC2/ASTC on Android) and capped in size.

Run after adding a model: python3 tools/tex_settings.py  (then re-import: tools/godot_check.sh)
Characters: 1024 px, props: 512 px (GDD 18.3: textures up to 1024 px).
"""
import glob
import os
import re

ROOT = os.path.join(os.path.dirname(__file__), "..")
for path in glob.glob(os.path.join(ROOT, "assets", "models", "**", "*.import"), recursive=True):
    if path.endswith(".glb.import"):
        continue
    limit = 512 if os.sep + "props" + os.sep in path else 1024
    text = open(path).read()
    new = re.sub(r"compress/mode=\d+", "compress/mode=2", text)
    new = re.sub(r"process/size_limit=\d+", "process/size_limit=%d" % limit, new)
    if new != text:
        open(path, "w").write(new)
        print("updated", os.path.relpath(path, ROOT))
