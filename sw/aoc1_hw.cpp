#include <fstream>
#include <string>
#include <iostream>

const int lock_max = 100; 
int cur_pos = 50, zeros = 0;

int main() {
    std::ifstream file("input1.txt");
    std::string line;

    int next_pos, cnt = 0;
    while (std::getline(file, line)) {
        char dir = line[0];
        int rot = std::stoi(line.substr(1));
        zeros += (rot / lock_max);  // detects wraparound

        rot = rot % lock_max;
        if (dir == 'L') {
            next_pos = cur_pos - rot;

            if (next_pos < 0) {
                next_pos = lock_max + next_pos;
                zeros += cur_pos != 0;
            }
        } else {
            next_pos = (cur_pos + rot);
            if (next_pos > lock_max)
                zeros += 1;
            next_pos = next_pos % lock_max;
        }
        cur_pos = next_pos;
        zeros += (cur_pos == 0);
    }
    file.close();
    std::cout << "Code is: " << zeros << "\n";

    return 0;
}