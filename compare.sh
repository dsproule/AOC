make aoc3-2_cpp && ./aoc | head -n -2 > cpp_out.txt
make aoc3_sv && ./aoc | head -n -2 > sv_out.txt

diff cpp_out.txt sv_out.txt