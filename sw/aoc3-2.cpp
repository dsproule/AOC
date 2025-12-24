#include <fstream>
#include <vector>
#include <iostream>

int main() {

    const int MAX_CAP = 12;

    std::ifstream file("input3.txt");
    std::string line;

    uint64_t cum_sum = 0, tmp_sum;
    while (std::getline(file, line)) {
        std::vector<int> stack;
        int bank_max = 0, top;

        for (size_t i = 0; i < line.length(); i++) {
            const int dig = line[i] - '0';

            // while larger than prev and have enough to form new num -> pop
            while (!stack.empty() && dig > stack.back() && line.length() - i >= MAX_CAP - stack.size() + 1)
                stack.pop_back();

            if (stack.size() < MAX_CAP)
                stack.push_back(dig);

        }
        tmp_sum = 0;
        for (const int n : stack)
            tmp_sum = tmp_sum * 10 + n;

        cum_sum += tmp_sum;
    }
    std::cout << "Code: " << cum_sum << "\n";
    std::cout << "Correct: " << ((cum_sum == 167523425665348) ? "true" : "false") << "\n";
}