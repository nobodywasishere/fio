numToPrint = 43
a = 0
b = 1

print(f"idx{' '*10}num hex")
for i in range(numToPrint):
    c = a + b
    a = b
    b = c
    print(f"{i:4}: {a:9} {hex(a)}")