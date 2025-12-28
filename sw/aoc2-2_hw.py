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

def pow10(n: int) -> int:
    return 10 ** n

def prim_calc(cur_base: int, block_size: int, ub: int, r: int = -1) -> int:
    if r == -1:
        raise NotImplementedError()
    
    prim_sub = 0
    if block_size % r == 0 and r < block_size:

        rep_base = 0
        
        for k in range(block_size // r):
            rep_base += pow10(k * r)
        
        lb_r = pow10(r - 1) if r != 1 else 1
        ub_r = ub // rep_base

        S = lb_r + ub_r
        N = ub_r - lb_r + 1
        BM = cur_base * rep_base
        
        if ub_r >= lb_r:
            prim_sub = BM * ((S * N) >> 1)
    return prim_sub

def group_count(n: int, n_digs: int, group_count_n: int = -1) -> int:
    if group_count_n == -1:
        raise NotImplementedError()
    
    en = n_digs % group_count_n == 0
    
    verbose = True
    if verbose:
        print(f"\ngroup_count_n: {group_count_n}", "=" * 30)
        print(f"\ten: {int(en)}")
    if not en:
        return 0
    
    block_size = n_digs // group_count_n

    # 10 ^ nk (this is used to create the num again)
    cur_base = 0
    for k in range(group_count_n):
        cur_base += pow10(k * block_size)

    if verbose:
        print(f"\tblock_size: {block_size}\n\tcur_base: {cur_base}\t")

    lb = pow10(block_size - 1) if block_size != 1 else 1

    ub_cand0, ub_cand1 = pow10(block_size) - 1, n // cur_base
    ub = min(ub_cand0, ub_cand1)

    if verbose:
        print(f"\tlb: {lb}\n\tub: {ub}\t")
    # series of all possible nums
    S = lb + ub
    N = ub - lb + 1
    M = (S * N) >> 1
    tmp_sum = cur_base * M

    if verbose:
        print(f"\tS: {S}\n\tN: {N}\n\tM: {M}\n\ttmp_sum: {tmp_sum}")
    # subtract out non-primitives
    prim_sub = 0
    for r in range(1, 3):
        prim_sub += prim_calc(cur_base, block_size, ub, r=r)

    # prim_sub = prim_calc(cur_base, block_size, ub, r=1) + prim_calc(cur_base, block_size, ub, r=2)

    return tmp_sum - prim_sub

def count_combs(n: int) -> int:
    n_digs = get_digs(n)
    

    cum_sum = 0
    for group_count_n in range(2, n_digs + 1):
        cum_sum += group_count(n, n_digs, group_count_n=group_count_n)
        
    return cum_sum + pref_lookup[n_digs - 1]

n_in = 2843
group_count(n_in, get_digs(n_in), group_count_n=2)
# id_sum = 0
# pref_lookup[0] = pref_lookup[1] = 0
# for k in range(2, 11):
#     pref_lookup[k] = count_combs(10 ** k - 1)

# for id_range in f.read().split(','):
#     start, end = map(int, id_range.split('-'))

#     id_sum += count_combs(end) - count_combs(start - 1)
    
# print(f"Id sum is: {id_sum}")
# print(f"Correct: {49046150754 == id_sum}")
# f.close()