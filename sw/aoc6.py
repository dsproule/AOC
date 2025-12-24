f = open("input6.txt", "r")

OP_ROW = -1
rows = [row[:-1].split() for row in f.readlines()]
cum_sum = 0
for i in range(len(rows[0])):
    is_add: bool = rows[OP_ROW][i] == '+'
    tmp_sum = 0 if is_add else 1
    
    for j in range(len(rows) - 1):
        if is_add:
            tmp_sum += int(rows[j][i])
        else:
            tmp_sum *= int(rows[j][i])
    cum_sum += tmp_sum
print(f"Answer is: {cum_sum}")
print(f"Correct: {cum_sum == 6209956042374}")
f.close()