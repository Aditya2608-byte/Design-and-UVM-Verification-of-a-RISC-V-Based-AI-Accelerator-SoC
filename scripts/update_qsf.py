with open("de10_lite.qsf", "r") as f:
    text = f.read()

assignment = 'set_global_assignment -name INTERNAL_FLASH_UPDATE_MODE "SINGLE IMAGE WITH ERAM"\n'
if "INTERNAL_FLASH_UPDATE_MODE" not in text:
    text = assignment + text
    with open("de10_lite.qsf", "w") as f:
        f.write(text)
    print("Added INTERNAL_FLASH_UPDATE_MODE to de10_lite.qsf")
else:
    print("Already present")
