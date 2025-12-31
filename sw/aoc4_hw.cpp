#include <fstream>
#include <vector>
#include <iostream>
#include <array>
#include <cassert>
#include <ranges>
#include <algorithm>

constexpr size_t MAX_ROWS = 139;
constexpr size_t MAX_COLS = MAX_ROWS;

using row_vec_t = std::array<bool, MAX_COLS>;

class Mem {
 public:
    using tile_map = std::array<std::array<bool, 3>, 3>;
    static constexpr size_t n_banks = 3;

    void store_mem(size_t row_i, size_t col_i, bool value) {
        bank_vec_t bank_vec = (!dirty_list_[row_i]) ? zero_row_ : bram_banks_[row_i % n_banks][row_i / n_banks];
        col_i++;
        
        dirty_list_[row_i] = true;
        bank_vec[col_i] = value;

        bram_banks_[row_i % n_banks][row_i / n_banks] = bank_vec;
    }

    tile_map load_mem(size_t row_i, size_t col) {
        assert (row_i >= 0 && row_i < MAX_ROWS);
        assert (col >= 0 && col < MAX_COLS);
        assert (dirty_list_[row_i]);

        // parallel bank accesses
        const bank_vec_t& top = (row_i == 0) ? zero_row_ : bram_banks_[(row_i - 1) % n_banks][(row_i - 1)  / n_banks];
        const bank_vec_t& mid = bram_banks_[row_i % n_banks][row_i / n_banks];
        const bank_vec_t& bot = (row_i == MAX_ROWS - 1) ? zero_row_ : bram_banks_[(row_i + 1) % n_banks][(row_i + 1) / n_banks];

        col++;
        return {{ {top[col - 1], top[col], top[col + 1]}, 
                 {mid[col - 1], mid[col], mid[col + 1]}, 
                 {bot[col - 1], bot[col], bot[col + 1]} }};
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
    using bank_vec_t = std::array<bool, MAX_COLS + 2>;
    
    const bank_vec_t zero_row_{};
    // looks much worse than it is. index by bram[bank][row][col]
    std::array<std::array<std::array<bool, MAX_COLS + 2>, (MAX_ROWS + n_banks - 1) / n_banks>, n_banks> bram_banks_;
    std::array<bool, MAX_ROWS> dirty_list_{};
};

class FreeMachine{
 public:
    bool changed_ = true;
    int updates_ = 0;

    void run() {
        changed_ = false;
        for (size_t row_i = 0; row_i < MAX_ROWS; row_i++) {
            for (size_t col_i = 0; col_i < MAX_COLS; col_i++) {
                Mem::tile_map map = mem_inst_.load_mem(row_i, col_i);
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
    Mem& mem_inst_;
    const size_t start_row_;
    const size_t end_row_;
};

int main() {
    std::ifstream file("input4.txt");
    std::string line;

    Mem mem_inst;
    // Phase 1 ---------- initialize banks
    size_t row = 0;
    row_vec_t vec;
    while (std::getline(file, line)) {
        vec = row_vec_t();
        for (size_t col = 0; col < MAX_COLS; col++) {
            mem_inst.store_mem(row, col, (line[col] == '@'));
        }
        row++;
    }
    // Phase 2 ------------ the sweeps
    FreeMachine mach_0 = FreeMachine(0, MAX_ROWS, mem_inst);
    while (mach_0.changed_)
        mach_0.run();

    // mem_inst.print();
    std::cout << "Answer is: " << mach_0.updates_ << "\n";
    
}