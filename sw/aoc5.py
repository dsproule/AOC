from enum import Enum, auto

class IntvState(Enum):
    BUILD = auto()
    MATCH = auto()

f = open("input5.txt", "r")

intvs = []
cur_state: IntvState = IntvState.BUILD
for line in f:
    if cur_state == IntvState.BUILD:
        if line == "\n":
            cur_state = IntvState.MATCH
            continue

        print(line[:-1])
    elif cur_state == IntvState.MATCH:
        pass
f.close()