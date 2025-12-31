f = open("input9.txt", "r")

# (abusive python notation)
# for line in f:
#     print(line[:-1])
nodes = set(tuple(map(int, line[:-1].split(','))) for line in f)
max_area = 0
for node in nodes:
    for o_node in nodes:
        max_area = max(max_area, abs(node[0] - o_node[0] + 1) * abs(node[1] - o_node[1] + 1))
print(f"Max area: {max_area}")
f.close()