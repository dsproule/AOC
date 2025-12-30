#include <fstream>
#include <vector>
#include <iostream>

const int LINE_LENGTH = 141;

int main() {
    std::ifstream file("input7.txt");
    std::string line;

    std::vector<long> splits(LINE_LENGTH, 0);
    splits[(LINE_LENGTH / 2)] = 1;
    
    long cur_sum = 0;
    while (std::getline(file, line)) {
        for (int i = 0; i < LINE_LENGTH; i++) {
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
    std::cout << "Correct: " << (cur_sum == 5921061943075) << "\n";
    return 0;
}