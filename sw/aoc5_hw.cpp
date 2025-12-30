#include <fstream>
#include <iostream>
#include <vector>
#include <span>
#include <cassert>
#include <algorithm>

const size_t MAX_WIDTH = 256;

using tuple_pair_t = std::pair<uint64_t, uint64_t>;

class Sorter {
 private:
    static inline void cmp_swp(tuple_pair_t& n1, tuple_pair_t& n2, bool asc) {
        if ((n1.first > n2.first) == asc) 
            std::swap(n1, n2);
    } 

    template<size_t N>
    constexpr void merger_N(std::span<tuple_pair_t, N> pairs) {
        if (N == 1) return;

        // sorting network
        const unsigned int reach = N / 2;

        for (int i = 0; i < reach; i++)
            cmp_swp(pairs[i], pairs[i + reach], true);
        
        merger_N(pairs.template subspan<0, reach>());
        merger_N(pairs.template subspan<reach, reach>());
    }

    void sort_8(std::span<tuple_pair_t, 8> pairs, bool asc) {
        // topologies 
        // https://bertdobbelaere.github.io/sorting_networks.html#N8L19D6

        // stage 1
        for (int i = 0; i < 6; i = i + 4) {
            cmp_swp(pairs[i], pairs[i + 2], asc);
            cmp_swp(pairs[i + 1], pairs[i + 3], asc);
        }
        
        // stage 2
        for (int i = 0; i < 4; i++)
            cmp_swp(pairs[i], pairs[i + 4], asc);
        
        // stage 3
        for (int i = 0; i < 8; i = i + 2)
            cmp_swp(pairs[i], pairs[i + 1], asc);
        
        // stage 4
        for (int i = 2; i < 4; i++)
            cmp_swp(pairs[i], pairs[i + 2], asc);
        
        // stage 5
        for (int i = 1; i < 4; i = i + 2)
            cmp_swp(pairs[i], pairs[i + 3], asc);
        
        // stage 6
        for (int i = 1; i < 7; i = i + 2)
            cmp_swp(pairs[i], pairs[i + 1], asc);
    }

 public:
    void bitonic_sort_16(std::span<tuple_pair_t, 16> pairs) {
        // sort first and second half indep
        sort_8(pairs.subspan<0, 8>(), true);
        sort_8(pairs.subspan<8, 8>(), false);

        // half cleaner
        const unsigned int reach = 16 / 2;
        for (int i = 0; i < reach; i++)
            cmp_swp(pairs[i], pairs[i + reach], true);

        // recursive_merge
        merger_N(pairs.subspan<0, 8>());
        merger_N(pairs.subspan<8, 8>());
    }
};

class Mem {
 public:
    void store_mem(uint64_t start, uint64_t end, int i) {
        assert (i < bram_start_bank_.size());
        bram_start_bank_[i][0] = { start, end };
    }

    tuple_pair_t load_mem(int i) {
        return { bram_start_bank_[i][0] };
    }

 private: 
    std::array<std::array<tuple_pair_t, 2>, 256> bram_start_bank_;
};

int main() {
    std::ifstream infile("input5.txt");
    std::string line;

    uint64_t start, end;    
    std::vector<tuple_pair_t> stream;
    while (std::getline(infile, line)) {
        size_t dash_pos = line.find('-');
        if (dash_pos != std::string::npos) {
            std::string start_str = line.substr(0, dash_pos);
            std::string end_str = line.substr(dash_pos + 1);
            
            // load bounds into mem
            start = std::stoull(start_str);
            end = std::stoull(end_str);
            
            stream.push_back({ start, end });
        }
    }
    
    constexpr int LEFT_REGS_END = 16;
    constexpr int RIGHT_REGS_END = 32;
    constexpr int MAX_VALUES = 16;

    // Main algorithm
    Mem mem_inst = Mem();
    Sorter sort_inst = Sorter();

    // load stream into dual banks
    for (int i = 0; i < stream.size(); i++)
        mem_inst.store_mem(stream[i].first, stream[i].second, i);

    std::vector<std::vector<tuple_pair_t>> pairs(2);
    // loop
    int mem_i = 0;
    while (mem_i < stream.size()) {
        pairs[0].clear();
        pairs[1].clear();

        std::cout << "mem_i: " << mem_i << "\n";
        for (int j = mem_i; j < mem_i + MAX_VALUES; j++)
            pairs[0].push_back(mem_inst.load_mem(j));
        for (int j = mem_i + MAX_VALUES; j < mem_i + 2 * MAX_VALUES; j++)
            pairs[1].push_back(mem_inst.load_mem(j));

        // do two sorts
        std::span<tuple_pair_t, 16> regs_0(pairs[0].data(), 16);
        std::span<tuple_pair_t, 16> regs_1(pairs[1].data(), 16);
        
        sort_inst.bitonic_sort_16(regs_0);
        sort_inst.bitonic_sort_16(regs_1);

        // load into [0:32]
        int left_regs_ptr = 0, right_regs_ptr = 0;
        while (left_regs_ptr < MAX_VALUES && right_regs_ptr < MAX_VALUES) {
            if (pairs[0][left_regs_ptr] < pairs[1][right_regs_ptr]) {
                mem_inst.store_mem(pairs[0][left_regs_ptr].first, pairs[0][left_regs_ptr].second, mem_i);
                left_regs_ptr++;
            } else {
                mem_inst.store_mem(pairs[1][right_regs_ptr].first, pairs[1][right_regs_ptr].second, mem_i);
                right_regs_ptr++;
            }
            mem_i++;
        }

        while (left_regs_ptr < MAX_VALUES) {
            mem_inst.store_mem(pairs[0][left_regs_ptr].first, pairs[0][left_regs_ptr].second, mem_i++);
            left_regs_ptr++;
        }
        while (right_regs_ptr < MAX_VALUES) {
            mem_inst.store_mem(pairs[1][right_regs_ptr].first, pairs[1][right_regs_ptr].second, mem_i++);
            right_regs_ptr++;
        }

        for (int j = mem_i - 32; j < mem_i; j++) {
            tuple_pair_t pair = mem_inst.load_mem(j);
            std::cout << "(" << pair.first << ", " << pair.second << ")\n";
        }
    }
    std::cout << mem_i << "\n";
    
    infile.close();
    return 0;
}