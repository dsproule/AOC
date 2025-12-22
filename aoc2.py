f = open("input2.txt", "r")

def get_digs(n: int) -> list[int]:
    i = 0
    while n > 0:
        i += 1
        n //= 10
    return i

def count_combs(n: int) -> int:
    n_digs = get_digs(n)

    cum_sum = 0
    cnt = 0
    for j in range(2, n_digs + 1, 2):
        l = 10 ** (j // 2 - 1)
        k = 10 ** (j // 2) - 1
        for i in range(l, k + 1):
            tmp_sum = i * (10 ** (j // 2) + 1)
            if tmp_sum <= n:
                cnt += 1
                cum_sum += tmp_sum
    return cum_sum

id_sum = 0
p = 0
for id_range in f.read().split(','):
    start, end = map(int, id_range.split('-'))

    id_sum += count_combs(end) - count_combs(start - 1)
    
print(f"Id sum is: {id_sum}")
f.close()