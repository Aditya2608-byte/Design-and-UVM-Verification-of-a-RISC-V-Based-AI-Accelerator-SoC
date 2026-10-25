import os

words = [int(line.strip(), 16) for line in open("sim/firmware.hex") if line.strip()]

with open("sim/firmware.mif", "w") as f:
    f.write("WIDTH=32;\nDEPTH=4096;\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\n\nCONTENT BEGIN\n")
    for idx, w in enumerate(words):
        f.write(f"    {idx:04X} : {w:08X};\n")
    if len(words) < 4096:
        f.write(f"    [{len(words):04X}..0FFF] : 00000013;\n")
    f.write("END;\n")

# Also copy to quartus directory
os.makedirs("quartus", exist_ok=True)
with open("quartus/firmware.mif", "w") as f:
    f.write(open("sim/firmware.mif").read())

print(f"[SUCCESS] Generated sim/firmware.mif and quartus/firmware.mif with {len(words)} instructions.")
