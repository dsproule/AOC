f = open("input4.txt", "r")

takes = 0
rows = ["", f.readline()[:-1], f.readline()[:-1]]
window = [[0 for __ in range(3)] for _ in range(3)]

def update_window(window: list[list[int]], top_c: str, mid_c: str, bot_c: str) -> int:
    insert_alias = [int(top_c == "."), int(mid_c == "."), int(bot_c == ".")]
    for row_i in range(3):
        window[row_i][0] = window[row_i][1]
        window[row_i][1] = window[row_i][2]
        window[row_i][2] = insert_alias[row_i]

    return sum(window[0]) + sum(window[1]) + sum(window[2]) - window[1][1]

def init_window(window: list[list[int]], top: str, mid: str, bot: str) -> None:
    window[0][1] = 1
    window[1][1] = 1
    window[2][1] = 1

    window[0][2] = int(top[0] == ".")
    window[1][2] = int(mid[0] == ".")
    window[2][2] = int(bot[0] == ".")

while rows[1]:
    for i in range(len(rows[1])):
        no_neighs_cnt = 0
        if i == 0:
            init_window(window, 
                        "." if not rows[0] else rows[0][0], 
                        rows[1][0], 
                        "." if not rows[2] else rows[2][0]
                )

            top = "." if not rows[0] else rows[0][1]
            mid = rows[1][1]
            bot = "." if not rows[2] else rows[2][1]
            
        else:
            top = "." if not rows[0] or (i == len(rows[0]) - 1) else rows[0][i + 1]
            mid = "." if (i == len(rows[1]) - 1) else rows[1][i + 1]
            bot = "." if not rows[2] or (i == len(rows[2]) - 1) else rows[2][i + 1]

        no_neighs_cnt = update_window(window, top, mid, bot)

        if rows[1][i] == "@" and no_neighs_cnt > 4:
            takes += 1

    rows[0] = rows[1]
    rows[1] = rows[2]
    rows[2] = f.readline()[:-1]

print(f"Answer is: {takes}")
f.close()