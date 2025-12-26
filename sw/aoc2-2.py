f = open("input2.txt", "r")

def get_digs(n: int) -> list[int]:
    if n == 0:
        return 1
    
    i = 0
    while n > 0:
        i += 1
        n //= 10
    return i

seen = set()
pref_lookup = {}
def count_combs(n: int) -> int:
    n_digs = get_digs(n)

    cum_sum = 0
    for group_count in range(2, n_digs + 1):
        if n_digs % group_count == 0:
            block_size = n_digs // group_count

            # 10 ^ nk (this is used to create the num again)
            cur_base = sum(10 ** (k * block_size) for k in range(group_count))

            lb = 10 ** (block_size - 1) if block_size != 1 else 1
            ub = min(10 ** (block_size) - 1, n // cur_base)

            # series of all possible nums
            tmp_sum = ((cur_base) * ((lb + ub) * (ub - lb + 1))) // 2

            # subtract out non-primitives
            prim_sub = 0
            for r in range(1, 3):
                if block_size % r == 0 and r < block_size:
                    rep_base = sum(10 ** (r * k) for k in range(block_size // r))
                    
                    lb_r = 10 ** (r - 1) if r != 1 else 1
                    ub_r = ub // rep_base
                    
                    if ub_r >= lb_r:
                        cnt = ub_r - lb_r + 1
                        prim_sub += cur_base * rep_base * (((lb_r + ub_r) * cnt) // 2)

            cum_sum += tmp_sum - prim_sub

    return cum_sum + pref_lookup[n_digs - 1]

id_sum = 0
pref_lookup[0] = pref_lookup[1] = 0
for k in range(2, 11):
    pref_lookup[k] = count_combs(10 ** k - 1)

for id_range in f.read().split(','):
    start, end = map(int, id_range.split('-'))

    id_sum += count_combs(end) - count_combs(start - 1)
    
print(f"Id sum is: {id_sum}")
print(f"Correct: {49046150754 == id_sum}")
f.close()