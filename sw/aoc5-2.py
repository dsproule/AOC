f = open("input5.txt", "r")

merged_intvs, intvs = [], []

cum_sum = 0
i = 0
for line in f:
    if line == "\n":
        intvs.sort()
        for start, end in intvs:
            print(start, end)
            i += 1
            if merged_intvs and start <= merged_intvs[-1][1]:
                prev_start, prev_end = merged_intvs.pop()
                start = prev_start
                end = max(prev_end, end)
            merged_intvs.append([start, end])
        for start, end in merged_intvs:
            cum_sum += end - start + 1
        break

    start, end = map(int, line[:-1].split("-"))
    intvs.append([start, end])
print(i)
print(f"Result: {cum_sum}")
f.close()