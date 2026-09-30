from pathlib import Path
import re
import sys

if len(sys.argv) != 2:
    print("Usage: python set_rom_init.py <mem-file-name>")
    sys.exit(1)

mem_name = sys.argv[1]
rom_path = Path(__file__).resolve().parents[1] / "rom.vhd"
text = rom_path.read_text(encoding="utf-8")
new_text, count = re.subn(
    r'MEMORY_INIT_FILE\s*=>\s*"[^"]+"',
    f'MEMORY_INIT_FILE     => "{mem_name}"',
    text,
    count=1,
)

if count != 1:
    print("Could not find MEMORY_INIT_FILE line in rom.vhd")
    sys.exit(2)

rom_path.write_text(new_text, encoding="utf-8")
print(f"Updated rom.vhd to use {mem_name}")
