from functools import lru_cache

f = open("input2.txt", "r")

def get_digs(n: int) -> list[int]:
    i = 0
    while n > 0:
        i += 1
        n //= 10
    return i

@lru_cache
def count_combs(n: int) -> int:
    n_digs = get_digs(n)

    cum_sum = 0
    for j in range(2, n_digs + 1, 2):
        cur_base = 10 ** (j // 2)

        l = 10 ** (j // 2 - 1) - 1
        k = min(cur_base - 1, n // (cur_base + 1))

        tmp_sum = (k * k + k - l * l - l) // 2
        cum_sum += (cur_base + 1) * tmp_sum
    return cum_sum

id_sum = 0
for id_range in f.read().split(','):
    start, end = map(int, id_range.split('-'))

    id_sum += count_combs(end) - count_combs(start - 1)
    
print(f"Id sum is: {id_sum}")
print(f"Correct: {38437576669 == id_sum}")
f.close()