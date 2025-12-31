#include <fstream>
#include <vector>
#include <iostream>
#include <array>
#include <cassert>

constexpr size_t MAX_ROWS = 139;
constexpr size_t MAX_COLS = MAX_ROWS;
constexpr size_t DATA_WIDTH = 64;

// row vector is ceil(MAX_COLS / 3) * 64
// using row_vec_t = std::array<bool, ((MAX_COLS + DATA_WIDTH - 1) / DATA_WIDTH) * 3>;
using partial_row_vec_t = std::array<bool, DATA_WIDTH>;

class Mem {
 public:
    using tile_map = std::array<std::array<bool, 3>, 3>;
    using bank_vec_t = std::array<bool, MAX_COLS + 2>;
    
    static constexpr size_t n_banks = 3;
    static constexpr bank_vec_t zero_row_{};

    void store_mem(size_t row_i, size_t col_i, const partial_row_vec_t& vec) {
        bank_vec_t bank_vec = load_vec(row_i);
        col_i++;

        dirty_list_[row_i] = true;
        // std::cout << ((MAX_COLS + 2) / col_i) * 64 << "\n";
        // col_i / DATA_WIDTH;
        // std::copy(vec.begin(), vec.end(), bank_vec.begin() + (col_i / DATA_WIDTH) * DATA_WIDTH);

        bram_banks_[row_i % n_banks][row_i / n_banks] = bank_vec;
    }

    void store_mem(size_t row_i, size_t col_i, bool value) {
        bank_vec_t bank_vec = (!dirty_list_[row_i]) ? zero_row_ : bram_banks_[row_i % n_banks][row_i / n_banks];
        col_i++;
        
        dirty_list_[row_i] = true;
        bank_vec[col_i] = value;

        bram_banks_[row_i % n_banks][row_i / n_banks] = bank_vec;
    }

    bank_vec_t load_vec(size_t row_i) {
        return (!dirty_list_[row_i]) ? zero_row_ : bram_banks_[row_i % n_banks][row_i / n_banks];
    }

    void print() {
        for (size_t col_i = 0; col_i < MAX_COLS + 2; col_i++)
            std::cout << 0;
        std::cout << "\n";
        for (size_t row_i = 0; row_i < MAX_ROWS; row_i++) {
            for (size_t col_i = 0; col_i < MAX_COLS + 2; col_i++) { 
                std::cout << bram_banks_[row_i % n_banks][row_i / n_banks][col_i];
            }
            std::cout << ": " << dirty_list_[row_i];
            std::cout << "\n";
        }
        for (size_t col_i = 0; col_i < MAX_COLS + 2; col_i++)
            std::cout << 0;
        std::cout << "\n";
    }

 private: 
    // looks much worse than it is. index by bram[bank][row][col]
    using bank = std::array<bank_vec_t, (MAX_ROWS + n_banks - 1) / n_banks>;

    std::array<bank, n_banks> bram_banks_;
    std::array<bool, MAX_ROWS> dirty_list_{};
};

class FreeMachine{
 public:
    bool changed_ = true;
    int updates_ = 0;

    void run() {
        changed_ = false;
        for (size_t row_i = start_row_; row_i < end_row_; row_i++) {
            for (size_t col_i = 0; col_i < MAX_COLS; col_i++) {
                Mem::tile_map map = load_tile(row_i, col_i);
                uint32_t degree =  map[0][0] + map[0][1] + map[0][2]
                            + map[1][0] +             map[1][2]
                            + map[2][0] + map[2][1] + map[2][2];
                
                if (map[1][1] && degree < 4) {
                    updates_++;
                    mem_inst_.store_mem(row_i, col_i, 0);
                    changed_ = true;
                }
            }
        }
    }

    FreeMachine(size_t start_row, size_t end_row, Mem& mem) 
        : start_row_(start_row), end_row_(end_row), mem_inst_(mem) {}
 private:
    Mem::tile_map load_tile(size_t row_i, size_t col_i) { 
        const Mem::bank_vec_t& top_regs = (row_i == 0) ? Mem::zero_row_ : mem_inst_.load_vec(row_i - 1);
        const Mem::bank_vec_t& bot_regs = (row_i == MAX_ROWS - 1) ? Mem::zero_row_ : mem_inst_.load_vec(row_i + 1);
        const Mem::bank_vec_t& mid_regs = mem_inst_.load_vec(row_i);

        col_i++;
        return {{ {top_regs[col_i - 1], top_regs[col_i], top_regs[col_i + 1]}, 
                 {mid_regs[col_i - 1], mid_regs[col_i], mid_regs[col_i + 1]}, 
                 {bot_regs[col_i - 1], bot_regs[col_i], bot_regs[col_i + 1]} }};
    }

    Mem& mem_inst_;
    const size_t start_row_;
    const size_t end_row_;
};

int main() {
    std::ifstream file("input4.txt");
    std::string line;

    Mem mem_inst;
    // Phase 1 ---------- initialize banks
    size_t row_i = 0;
    partial_row_vec_t vec;
    while (std::getline(file, line)) {
        vec = partial_row_vec_t();
        for (size_t col_i = 0; col_i < MAX_COLS; col_i++) {
            vec[col_i % 64] = (line[col_i] == '@');
            // if (col_i % 64 == 0 && col_i > 0)
            //     mem_inst.store_mem(row_i, col_i, vec);
            mem_inst.store_mem(row_i, col_i, (line[col_i] == '@'));
        }
        row_i++;
    }
    // Phase 2 ------------ the sweeps
    constexpr size_t MACH_N = 4;            // segments to break down (traversals take less time for grid)
    constexpr size_t MACH_DUPL = 2;         // increases throughput (lines resolved quicker)
    constexpr size_t MACH_ROWS = MAX_ROWS / MACH_N; 
    assert (MACH_ROWS > 3 * MACH_DUPL);     // make sure we have a gap for machines in same segments
    std::vector<FreeMachine> machs;

    for (size_t mach_i = 0; mach_i < MACH_N; mach_i++) {
        if (mach_i == MACH_N - 1)
            machs.push_back(FreeMachine(mach_i * MACH_ROWS, MAX_ROWS, mem_inst));
        else
            machs.push_back(FreeMachine(mach_i * MACH_ROWS, mach_i * MACH_ROWS + MACH_ROWS, mem_inst));
    }

    bool any_changed = true;
    int iters = 0;
    while (any_changed) {
        iters++;
        any_changed = false;
        for (FreeMachine& mach : machs) {
            for (int dupl = 0; dupl < MACH_DUPL; dupl++)
                mach.run();
            any_changed |= mach.changed_;
        }
    }
    mem_inst.print();
    // std::cout << "\n";
    int all_updates = 0;
    for (FreeMachine& mach : machs) {
        // std::cout << "(Mach): " << mach.updates_ << "\n";
        all_updates += mach.updates_;
    }

    // std::cout << "Took " << iters << " iters\n";
    std::cout << "Answer is: " << all_updates << "\n";
    std::cout << "Correct: " << (all_updates == 8484) << "\n";

}