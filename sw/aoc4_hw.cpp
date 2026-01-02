#include <fstream>
#include <vector>
#include <iostream>
#include <array>
#include <cassert>

constexpr size_t MAX_ROWS = 139;
constexpr size_t MAX_COLS = MAX_ROWS;
constexpr size_t TX_DATA_WIDTH = 32;
constexpr size_t GRID_VEC_ALIGN_N = ((MAX_COLS + 2 + TX_DATA_WIDTH - 1) / TX_DATA_WIDTH) * TX_DATA_WIDTH;

constexpr size_t MACH_N = 4;                    // segments to break down (traversals take less time for grid)
constexpr size_t MACH_ROWS = MAX_ROWS / MACH_N; 

#define base2(n) (n != 0 && (n & (n - 1)) == 0)

using partial_row_vec_t = std::array<bool, TX_DATA_WIDTH>;

class Mem {
 public:
    using tile_map = std::array<std::array<bool, 3>, 3>;
    using bank_vec_t = std::array<bool, GRID_VEC_ALIGN_N>;
    
    static constexpr size_t n_banks = MACH_N;
    static constexpr bank_vec_t zero_row_{};
    static constexpr partial_row_vec_t partial_zero_row_{};

    void store_mem(size_t row_i, size_t col_i, const partial_row_vec_t& vec) {
        bank_vec_t bank_vec = load_bank_vec(row_i);
        col_i++;
        size_t end_bound = std::min(64ul, MAX_COLS + 2 - (col_i & ~(TX_DATA_WIDTH - 1)) - 2);

        dirty_list_[row_i] = true;
        std::copy(vec.begin(), vec.begin() + end_bound, bank_vec.begin() + (col_i & ~(TX_DATA_WIDTH - 1)) + 1);

        bram_banks_[row_i & (n_banks - 1)][row_i / n_banks] = bank_vec;
    }
    
    partial_row_vec_t partial_load_vecs(size_t mid_row_i, size_t col_i) {
        const Mem::bank_vec_t& regs = load_bank_vec(mid_row_i);
        
        col_i++;
        partial_row_vec_t parallel_bank;
        for (int load_batch_i = 0; load_batch_i < TX_DATA_WIDTH; load_batch_i++)
            parallel_bank[load_batch_i] = regs[(col_i & ~(TX_DATA_WIDTH - 1)) + load_batch_i];

        return parallel_bank;
    }

    void print() {
        for (size_t col_i = 0; col_i < MAX_COLS + 2; col_i++)
            std::cout << 0;
        std::cout << "\n";
        for (size_t row_i = 0; row_i < MAX_ROWS; row_i++) {
            for (size_t col_i = 0; col_i < MAX_COLS + 2; col_i++) { 
                std::cout << bram_banks_[row_i & (n_banks - 1)][row_i / n_banks][col_i];
            }
            std::cout << ": " << dirty_list_[row_i];
            std::cout << "\n";
        }
        for (size_t col_i = 0; col_i < MAX_COLS + 2; col_i++)
            std::cout << 0;
        std::cout << "\n";
    }

 private: 
    // from the bank itself
    bank_vec_t load_bank_vec(size_t row_i) {
        return (!dirty_list_[row_i]) ? zero_row_ : bram_banks_[row_i & (n_banks - 1)][row_i / n_banks];
    }
    // looks much worse than it is. index by bram[bank][row][col]
    static constexpr size_t bank_depth = (MAX_ROWS + n_banks - 1) / n_banks;
    using bank = std::array<bank_vec_t, bank_depth>;

    std::array<bank, n_banks> bram_banks_;
    std::array<bool, MAX_ROWS> dirty_list_{};
};

class FreeMachine{
 public:
    bool changed_ = false;
    int updates_ = 0;

    void run() {
        changed_ = false;
        regs_[0] = Mem::zero_row_;

        for (int batch_i = 0; batch_i < GRID_VEC_ALIGN_N; batch_i = batch_i + TX_DATA_WIDTH) {
            std::array<partial_row_vec_t, 3> partials;
            partials[0] = (start_row_ == 0) ? Mem::partial_zero_row_ : mem_inst_.partial_load_vecs(start_row_ - 1, batch_i);
            partials[1] = mem_inst_.partial_load_vecs(start_row_, batch_i);
            partials[2] = mem_inst_.partial_load_vecs(start_row_ + 1, batch_i);

            for (int partial_i = 0; partial_i < TX_DATA_WIDTH; partial_i++) {
                regs_[0][batch_i + partial_i] = partials[0][partial_i];
                regs_[1][batch_i + partial_i] = partials[1][partial_i];
                regs_[2][batch_i + partial_i] = partials[2][partial_i];
            }
        }
        regs_valid_ = true;

        for (size_t row_i = start_row_; row_i < end_row_; row_i++) {
            for (size_t col_i = 0; col_i < MAX_COLS; col_i++) {
                Mem::tile_map map = load_tile(row_i, col_i);
                uint32_t degree =  map[0][0] + map[0][1] + map[0][2]
                            + map[1][0] +             map[1][2]
                            + map[2][0] + map[2][1] + map[2][2];

                if (map[1][1] && degree < 4) {
                    updates_++;
                    regs_[1][col_i + 1] = 0;
                    changed_ = true;
                }
            }
            // move back to mem
            partial_row_vec_t vec;
            for (size_t col_i = 0; col_i < MAX_COLS; col_i++) {
                if (col_i % TX_DATA_WIDTH == 0 && col_i > 0)
                    mem_inst_.store_mem(row_i, col_i - TX_DATA_WIDTH, vec);
                vec[col_i % TX_DATA_WIDTH] = regs_[1][col_i + 1];
            }
            mem_inst_.store_mem(row_i, (MAX_COLS / TX_DATA_WIDTH) * TX_DATA_WIDTH, vec);
            regs_valid_ = false; 
        }

    }

    FreeMachine(size_t start_row, size_t end_row, Mem& mem) 
        : start_row_(start_row), end_row_(end_row), mem_inst_(mem) {}
 private:
    Mem::tile_map load_tile(size_t row_i, size_t col_i) { 
        // parallel load of cached regs 
        if (!regs_valid_) {
            regs_[0] = regs_[1];
            regs_[1] = regs_[2];

            for (int batch_i = 0; batch_i < GRID_VEC_ALIGN_N; batch_i = batch_i + TX_DATA_WIDTH) {
                partial_row_vec_t partial = (row_i == MAX_ROWS - 1) ? Mem::partial_zero_row_ : mem_inst_.partial_load_vecs(row_i + 1, batch_i);

                for (int partial_i = 0; partial_i < TX_DATA_WIDTH; partial_i++)
                    regs_[2][batch_i + partial_i] = partial[partial_i];
            }
            regs_valid_ = true;
        }
        col_i++;
        return {{ {regs_[0][col_i - 1], regs_[0][col_i], regs_[0][col_i + 1]}, 
                 {regs_[1][col_i - 1], regs_[1][col_i], regs_[1][col_i + 1]}, 
                 {regs_[2][col_i - 1], regs_[2][col_i], regs_[2][col_i + 1]} }};
    }

    Mem& mem_inst_;
    const size_t start_row_;
    const size_t end_row_;

    std::array<Mem::bank_vec_t, 3> regs_; 
    bool regs_valid_ = false; 
};

int main() {
    std::ifstream file("input4.txt");
    std::string line;

    assert (base2(MACH_N));

    Mem mem_inst;
    // Phase 1 ---------- initialize banks
    size_t row_i = 0;
    partial_row_vec_t vec;
    while (std::getline(file, line)) {
        vec = partial_row_vec_t();
        for (size_t col_i = 0; col_i < MAX_COLS; col_i++) {
            if (col_i % TX_DATA_WIDTH == 0 && col_i > 0)
                mem_inst.store_mem(row_i, col_i - TX_DATA_WIDTH, vec);
            vec[col_i % TX_DATA_WIDTH] = (line[col_i] == '@');
        }

        mem_inst.store_mem(row_i, (MAX_COLS / TX_DATA_WIDTH) * TX_DATA_WIDTH, vec);
        row_i++;
    }
    // Phase 2 ------------ the sweeps
    std::vector<FreeMachine> machs;

    for (size_t mach_i = 0; mach_i < MACH_N; mach_i++) {
        if (mach_i == MACH_N - 1)
            machs.push_back(FreeMachine(mach_i * MACH_ROWS, MAX_ROWS, mem_inst));
        else
            machs.push_back(FreeMachine(mach_i * MACH_ROWS, mach_i * MACH_ROWS + MACH_ROWS + 1, mem_inst));
    }

    std::cout << "\n";
    bool any_changed = true;
    int iters = 0;
    while (any_changed) {
        iters++;
        any_changed = false;
        for (FreeMachine& mach : machs) {
            mach.run();
            any_changed |= mach.changed_;
        }
    }
    mem_inst.print();
    int all_updates = 0;
    for (FreeMachine& mach : machs)
        all_updates += mach.updates_;

    // std::cout << "Took " << iters << " iters\n";
    std::cout << "Answer is: " << all_updates << "\n";
    std::cout << "Correct: " << (all_updates == 8484) << "\n";

}