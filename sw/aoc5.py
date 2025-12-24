from enum import Enum, auto

class IntvState(Enum):
    BUILD = auto()
    MATCH = auto()

f = open("input5.txt", "r")


merged_intvs, intvs = [], []

def in_interval(v: int) -> int:
    for start, end in merged_intvs:
        if start <= v <= end:
            return 1
    return 0

cum_sum = 0
cur_state: IntvState = IntvState.BUILD
for line in f:
    if cur_state == IntvState.BUILD:
        if line == "\n":
            cur_state = IntvState.MATCH
            intvs.sort()
            for start, end in intvs:
                if merged_intvs and start <= merged_intvs[-1][1]:
                    prev_start, prev_end = merged_intvs.pop()
                    start = prev_start
                    end = max(prev_end, end)
                merged_intvs.append([start, end])
            continue

        start, end = map(int, line[:-1].split("-"))
        intvs.append([start, end])
    elif cur_state == IntvState.MATCH:
        print(f"num: {int(line[:-1])} accepted: {in_interval(int(line[:-1]))}")
        cum_sum += in_interval(int(line[:-1]))

print(cum_sum)
f.close()