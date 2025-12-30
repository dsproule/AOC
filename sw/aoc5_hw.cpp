#include <fstream>
#include <iostream>
#include <vector>
#include <span>
#include <cassert>

const size_t MAX_WIDTH = 256;

using tuple_pair_t = std::pair<uint64_t, uint64_t>;

class Sorter {
 private:
    template<size_t N>
    void bitonic_sort(std::span<tuple_pair_t, N> pairs) {
        // sorting network
        const unsigned int reach = N / 2;

        for (int i = 0; i < reach; i++) {
            if (pairs[i].first > pairs[i + reach].first) 
                std::swap(pairs[i], pairs[i + reach]);
        }
    }

    void sort_4(std::span<tuple_pair_t, 4> pairs, bool asc) {
        if ((pairs[0].first > pairs[2].first) == asc) std::swap(pairs[0], pairs[2]);
        if ((pairs[1].first > pairs[3].first) == asc) std::swap(pairs[1], pairs[3]);
        
        if ((pairs[0].first > pairs[1].first) == asc) std::swap(pairs[0], pairs[1]);
        if ((pairs[2].first > pairs[3].first) == asc) std::swap(pairs[2], pairs[3]);

        if ((pairs[1].first > pairs[2].first) == asc) std::swap(pairs[1], pairs[2]);
    }

 public:
    void merger_sort_8(std::span<tuple_pair_t, 8> pairs) {
        // sort first and second half indep
        sort_4(pairs.subspan<0, 4>(), 1);
        sort_4(pairs.subspan<4, 4>(), 0);

        // stage1        
        bitonic_sort(pairs.subspan<0, 8>());

        // stage2        
        bitonic_sort(pairs.subspan<0, 4>());
        bitonic_sort(pairs.subspan<4, 4>());

        // stage3        
        bitonic_sort(pairs.subspan<0, 2>());
        bitonic_sort(pairs.subspan<2, 2>());
        bitonic_sort(pairs.subspan<4, 2>());
        bitonic_sort(pairs.subspan<6, 2>());

    }
};

class Mem {
 public:
    void store_mem(uint64_t start, uint64_t end, int i) {
        bram_start_bank_[i] = start;
        bram_end_bank_[i] = end;
    }

    std::pair<uint64_t, uint64_t> load_mem(int i) {
        return { bram_start_bank_[i], bram_end_bank_[i] };
    }

 private: 
    uint64_t bram_start_bank_[MAX_WIDTH];
    uint64_t bram_end_bank_[MAX_WIDTH];
};

int main() {
    std::ifstream infile("input5.txt");
    std::string line;

    Mem mem_inst = Mem();
    Sorter sort_inst = Sorter();
    int i = 0;
    uint64_t start, end;    
    while (std::getline(infile, line)) {
        size_t dash_pos = line.find('-');
        if (dash_pos != std::string::npos) {
            std::string start_str = line.substr(0, dash_pos);
            std::string end_str = line.substr(dash_pos + 1);
            
            // load bounds into mem
            start = std::stoull(start_str);
            end = std::stoull(end_str);
            
            mem_inst.store_mem(start, end, i++);
        }
    }
    std::vector<tuple_pair_t> pairs;
    for (int i = 0; i < 8; i++)
        pairs.push_back(mem_inst.load_mem(i));
    sort_inst.merger_sort_8(std::span<tuple_pair_t, 8>(pairs.data(), 8));
    std::cout << pairs.size() << "\n";
    for (const auto& pair : pairs)
        std::cout << "(" << pair.first << ", " << pair.second << ")\n";
    
    infile.close();
    return 0;
}