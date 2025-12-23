f = open("input2.txt", "r")

def get_digs(n: int) -> list[int]:
    if n == 0:
        return 1
    
    i = 0
    while n > 0:
        i += 1
        n //= 10
    return i

pref_lookup = {}
def count_combs(n: int) -> int:
    n_digs = get_digs(n)

    seen = set()
    cum_sum = 0
    for n_group in range(2, n_digs + 1):
        if n_digs % n_group == 0:
            max_digs = n_digs // n_group

            base_max10 = 10 ** max_digs
            cur_base = (base_max10 ** n_group - 1) // (base_max10 - 1)

            lb = 10 ** (max_digs - 1) if max_digs != 1 else 1
            ub = min(10 ** (max_digs) - 1, n // cur_base)

            tmp_sum = 0
            for i in range(lb, ub + 1):
                next_calc = i * cur_base
                
                if next_calc not in seen:
                    tmp_sum += next_calc
                    seen.add(next_calc)
            cum_sum += tmp_sum

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