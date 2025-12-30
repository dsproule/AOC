#include <fstream>
#include <stack>
#include <iostream>

int main() {
    std::ifstream file("input3.txt");
    std::string line;

    int all_max = 0;
    while (std::getline(file, line)) {
        // monotonically decreasing
        std::stack<int> stack;
        int bank_max = 0, top;

        for (size_t i = 0; i < line.length(); i++) {
            const int dig = line[i] - '0';

            while (!stack.empty() && dig > stack.top()) {
                bank_max = std::max(bank_max, stack.top() * 10 + dig);
                stack.pop();
            }
            stack.push(dig);
        }
        // drain the stack
        while (stack.size() >= 2) {
            top = stack.top(); stack.pop();
            bank_max = std::max(bank_max, stack.top() * 10 + top);
        }
        all_max += bank_max;
    }
    file.close();
    std::cout << all_max << "\n";
}