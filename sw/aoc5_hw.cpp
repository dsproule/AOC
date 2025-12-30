#include <fstream>
#include <iostream>
#include <vector>
#include <span>
#include <cassert>
#include <algorithm>

const size_t MAX_WIDTH = 256;
constexpr size_t LEFT_REGS_END = 16;
constexpr size_t RIGHT_REGS_END = 32;
constexpr size_t REGS_SIZE = 16;
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
    std::array<std::array<tuple_pair_t, 2>, MAX_WIDTH * 2> bram_start_bank_;
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

    // Main algorithm
    Mem mem_inst = Mem();
    Sorter sort_inst = Sorter();

    // load stream into dual banks
    for (int i = 0; i < stream.size(); i++)
        mem_inst.store_mem(stream[i].first, stream[i].second, i);

    std::vector<std::vector<tuple_pair_t>> regs_in(2), regs_out(2);
    int mem_i = 0;
    // phase 1 ------- sorting in mem
    while (mem_i < stream.size()) {
        regs_in[0].clear();
        regs_in[1].clear();

        for (int j = mem_i; j < mem_i + REGS_SIZE; j++)
            regs_in[0].push_back(mem_inst.load_mem(j));
        for (int j = mem_i + REGS_SIZE; j < mem_i + 2 * REGS_SIZE; j++)
            regs_in[1].push_back(mem_inst.load_mem(j));

        // do two sorts
        sort_inst.bitonic_sort_16(std::span<tuple_pair_t, REGS_SIZE>(regs_in[0].data(), REGS_SIZE));
        sort_inst.bitonic_sort_16(std::span<tuple_pair_t, REGS_SIZE>(regs_in[1].data(), REGS_SIZE));
        
        // pipelining drives this
        regs_out[0].clear();
        regs_out[1].clear();
        for (int j = mem_i; j < mem_i + REGS_SIZE; j++) {
            regs_out[0].push_back(regs_in[0][j]);
            regs_out[1].push_back(regs_in[1][j]);
        }

        int left_regs_ptr, right_regs_ptr;
        left_regs_ptr = right_regs_ptr = 0;
        while (left_regs_ptr < REGS_SIZE && right_regs_ptr < REGS_SIZE) {
            if (regs_in[0][left_regs_ptr] < regs_in[1][right_regs_ptr]) {
                mem_inst.store_mem(regs_in[0][left_regs_ptr].first, regs_in[0][left_regs_ptr].second, mem_i);
                left_regs_ptr++;
            } else {
                mem_inst.store_mem(regs_in[1][right_regs_ptr].first, regs_in[1][right_regs_ptr].second, mem_i);
                right_regs_ptr++;
            }
            mem_i++;
        }

        while (left_regs_ptr < REGS_SIZE) {
            mem_inst.store_mem(regs_in[0][left_regs_ptr].first, regs_in[0][left_regs_ptr].second, mem_i++);
            left_regs_ptr++;
        }
        while (right_regs_ptr < REGS_SIZE) {
            mem_inst.store_mem(regs_in[1][right_regs_ptr].first, regs_in[1][right_regs_ptr].second, mem_i++);
            right_regs_ptr++;
        }
    }

    // phase 2 ----- merging streams
    int list_lens = 32;
    while (list_lens <= MAX_WIDTH) {
        int first_list_i = 0;
        
        auto list_end = [list_lens](int list_base_i) -> int {
            return list_base_i + list_lens - 1;
        };

        while (first_list_i + (list_lens * 2) <= MAX_WIDTH) { 
            // copy second sorted list to end
            for (int off = 0; off < list_lens; off++) {
                tuple_pair_t aux_list_pair = mem_inst.load_mem(list_end(first_list_i + list_lens) - off);
                mem_inst.store_mem(aux_list_pair.first, aux_list_pair.second, (MAX_WIDTH * 2) - 1 - off);
            }

            // place pointer at end of both lists
            int fl_ptr = list_end(first_list_i), sl_ptr = (MAX_WIDTH * 2) - 1;
            int sort_mem_i = list_end(first_list_i + list_lens);

            tuple_pair_t fl_reg, sl_reg;
            bool fl_valid = false, sl_valid = false;
            while (fl_ptr > first_list_i - 1 && sl_ptr > (MAX_WIDTH * 2) - list_lens - 1) {
                if (!fl_valid) fl_reg = mem_inst.load_mem(fl_ptr);
                if (!sl_valid) sl_reg = mem_inst.load_mem(sl_ptr);

                if (fl_reg.first > sl_reg.first) {
                    mem_inst.store_mem(fl_reg.first, fl_reg.second, sort_mem_i);
                    fl_valid = false;
                    fl_ptr--;
                } else {
                    mem_inst.store_mem(sl_reg.first, sl_reg.second, sort_mem_i);
                    sl_valid = false;
                    sl_ptr--;
                }
                sort_mem_i--;

            }

            // move rest of list into place
            while (sl_ptr > (MAX_WIDTH * 2) - list_lens - 1) {
                sl_reg = mem_inst.load_mem(sl_ptr);
                mem_inst.store_mem(sl_reg.first, sl_reg.second, sort_mem_i--);
                sl_ptr--;
            }

            first_list_i += list_lens * 2;
        }
        list_lens *= 2;
    }

    int padding = MAX_WIDTH - stream.size();
    // phase 3 --------------- merge intervals
    uint64_t cum_sum = 0;
    tuple_pair_t prev_intv{1, 0}, cur_intv;
    for (int j = padding; j < padding + stream.size(); j++) {
        cur_intv = mem_inst.load_mem(j);
        if (cur_intv.first <= prev_intv.second) {
            // merge
            prev_intv.second = std::max(cur_intv.second, prev_intv.second);
        } else {
            cum_sum += prev_intv.second - prev_intv.first + 1;
            prev_intv = cur_intv;
        }
    }
    cum_sum += prev_intv.second - prev_intv.first + 1;
    std::cout << "Answer: " << cum_sum << "\n";
    std::cout << "Correct: " << (343143696885053 == cum_sum) << "\n";
    
    infile.close();
    return 0;
}