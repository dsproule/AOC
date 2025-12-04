#include <fstream>
#include <cmath> 
#include <string>
#include <iostream>

inline const int n_digs(int n) {
    return floor(log10(n)) + 1;
}

int main(int argc, char* argv[1]) {
    if (argc != 2) {
        std::cout << "Expected: ./aoc2 <input_file>\n";
        exit(1);
    }

    std::ifstream file(argv[1]);
    if (!file) {
        std::cout << argv[1] << " does not exist\n";
        exit(1);
    }
    std::string line;
    std::getline(file, line);
    
    int id_sum = 0;
    size_t prev = 0, next;
    while ((next = line.find(',', prev)) != std::string::npos) {
        std::cout << line.substr(prev, next - prev) << "\n";
        prev = next + 1;
    }
    std::cout << line.substr(prev, next - prev) << "\n";
    

    std::cout << "Id sum is: " << id_sum << "\n";
    return 0;
}