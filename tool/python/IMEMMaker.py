instructionFile = "/Users/zpogrebin/Desktop/f.txt"
i=0
with open(instructionFile) as binaryFile:
    for line in binaryFile.readlines():
        if line[0:4] != "16'h": continue
        print(f'-- {line[58:]}', end="")
        print(f'imemBytes({4*i+3}) <= "{line[21:29]}";')
        print(f'imemBytes({4*i+2}) <= "{line[29:37]}";')
        print(f'imemBytes({4*i+1}) <= "{line[37:45]}";')
        print(f'imemBytes({4*i+0}) <= "{line[45:53]}";')
        print("")
        i+=1
    for j in range(4):
        print(f"-- NOP {i}")
        print(f'imemBytes({4*i+3}) <= "00000000";')
        print(f'imemBytes({4*i+2}) <= "00000000";')
        print(f'imemBytes({4*i+1}) <= "00000000";')
        print(f'imemBytes({4*i+0}) <= "00000000";')
        print("")
        i+=1