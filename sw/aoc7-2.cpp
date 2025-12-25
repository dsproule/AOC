#include <fstream>
#include <vector>
#include <iostream>

const int LINE_WIDTH = 141;

int main() {
    std::ifstream file("input7.txt");
    std::string line;

    std::vector<long> splits(LINE_WIDTH, 0);
    splits[(LINE_WIDTH / 2)] = 1;
    
    long cur_sum = 0;
    while (std::getline(file, line)) {
        for (int i = 0; i < LINE_WIDTH; i++) {
            if (line[i] == '^' && splits[i]) {
                splits[i - 1] += splits[i];
                splits[i + 1] += splits[i];
                splits[i] = 0; 
            }
        }
    }

    for (auto c : splits)
        cur_sum += c;

    std::cout << "Answer is: " << cur_sum << "\n";
    return 0;
}