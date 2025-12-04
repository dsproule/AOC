import math

f = open("input2.txt", "r")

def n_digs(n: int) -> int:
    return math.floor(math.log10(n)) + 1

id_sum = 0
for id_range in f.read().split(','):
    start, end = map(int, id_range.split('-'))
    
    for i in range(start, end + 1):
        if (digs := n_digs(i)) % 2 != 0:
            continue
        split_digs = 10**(digs // 2)
        if i // split_digs == i % split_digs:
            id_sum += i
print(f"Id sum is: {id_sum}")
f.close()