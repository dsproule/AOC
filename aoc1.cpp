#include <fstream>
#include <string>
#include <iostream>

int main(int argc, char* argv[]) {
    const int lock_max = 100; 
    std::string line;
    int cur_pos = 50, zeros = 0;
    if (argc != 2) {
        std::cout << "Expected ./aoc1 <input_file>\n";
        return 1;
    }
    std::ifstream file(argv[1]);

    while (std::getline(file, line)) {
        char dir = line[0];
        int rot = std::stoi(line.substr(1)) % lock_max;

        if (dir == 'L') {
            cur_pos -= rot;
            if (cur_pos < 0) cur_pos += lock_max;
        } else {
            cur_pos = (cur_pos + rot) % lock_max;
        }
        zeros += (cur_pos == 0);
    }
    std::cout << "Code is: " << zeros << "\n";

    return 0;
}