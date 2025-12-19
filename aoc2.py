f = open("input2.txt", "r")
def digs_n(n: int) -> int:
    i = 0
    while n > 0:
        i += 1
        n //= 10
    return i

id_sum = 0
for id_range in f.read().split(','):
    start, end = map(int, id_range.split('-'))
    
    for i in range(start, end + 1):
        if (digs := digs_n(i)) % 2 != 0:
            continue
        split_digs = 10**(digs // 2)
        if i // split_digs == i % split_digs:
            id_sum += i
print(f"Id sum is: {id_sum}")
f.close()