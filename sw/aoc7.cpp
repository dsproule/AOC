#include <fstream>
#include <vector>
#include <iostream>

const int LINE_WIDTH = 141;

int main() {
    std::ifstream file("input7.txt");
    std::string line;

    std::vector<bool> splits(LINE_WIDTH, false);
    splits[(LINE_WIDTH / 2)] = true;
    
    int cur_sum = 0;
    while (std::getline(file, line)) {
        for (int i = 0; i < LINE_WIDTH; i++) {
            if (line[i] == '^' && splits[i]) {
                splits[i - 1] = true;
                splits[i] = false;
                splits[i + 1] = true;
                cur_sum++;
            }
        }
    }

    std::cout << "Answer is: " << cur_sum << "\n";
    return 0;
}