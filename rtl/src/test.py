buf = []

with open("inputs/input5.txt") as f:
    for line in f:
        n1, n2 = line[:-1].split('-')
        buf.append((int(n1), int(n2)))

def sort_chunk(chunk: int) -> list:    
    for i in range(0, len(buf), chunk):
        sort = sorted(buf[i:i+chunk])
        for j in range(i, min(i + chunk, 200)):
            buf[j] = sort[j - i]
sort_chunk(16)

sort_chunk(32)
sort_chunk(64)
sort_chunk(128)
# sort_chunk(256)
for i, pair in enumerate(buf):
    print(f"{i}: {pair[0]}-{pair[1]}")
