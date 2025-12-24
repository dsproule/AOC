#include <fstream>
#include <vector>
#include <iostream>
#include <algorithm>

const int MAX_ROWS = 139;
const int MAX_COLS = 139;
const int MIN_NEIGHS = 4;
const int MAX_STACK_CAP = 128;

const std::vector<std::pair<int, int>> NEIGH_OFFS {
    { -1, -1 }, { -1, 0 }, { -1, 1 }, { 0, -1 },
    { 0, 1 }, { 1, -1 }, { 1, 0 }, { 1, 1 }
}; 

class DegreeGraph {
 private: 
    std::vector<std::vector<bool>> nodes_empty_;
    
    // padded signatures
    inline int getDegree_(int row, int col) { return getDegree(row - 1, col - 1); }
    void markNode_(int row, int col) { markNode_(row - 1, col - 1); } 
    bool marked_(int row, int col) { return marked(row - 1, col - 1); } 

 public:
    int removed_ = 0;
    int max_stack_ = 0;

    DegreeGraph(int rows, int cols) : nodes_empty_(cols + 2, std::vector<bool>(rows + 2, true)) {} 
    
    void markNode(int row, int col) { nodes_empty_[row + 1][col + 1] = false; } 
    bool marked(int row, int col) { return !nodes_empty_[row + 1][col + 1]; } 
    
    inline int getDegree(int row, int col) {
        row++; col++;
        return nodes_empty_[row + 1][col] + nodes_empty_[row - 1][col] + nodes_empty_[row][col + 1] + nodes_empty_[row][col - 1] + 
            nodes_empty_[row + 1][col + 1] + nodes_empty_[row - 1][col - 1] + nodes_empty_[row - 1][col + 1] + nodes_empty_[row + 1][col - 1];
    }

    void removeNode(int init_row, int init_col) {
        std::vector<std::pair<int, int>> stack{ {init_row + 1, init_col + 1} };

        while (!stack.empty()) {
            max_stack_ = std::max(static_cast<int>(stack.size()), max_stack_);
            auto [row, col] = stack.back(); stack.pop_back();

            if (!marked_(row, col))
                continue;

            removed_++;
            nodes_empty_[row][col] = true;

            for (auto [row_off, col_off] : NEIGH_OFFS) {
                int n_row = row_off + row;
                int n_col = col_off + col;

                if (marked_(n_row, n_col) && getDegree_(n_row, n_col) > MIN_NEIGHS && stack.size() < MAX_STACK_CAP)
                    stack.push_back({ n_row, n_col });
            }
        }

    }
};

int main() {
    std::ifstream file("input4.txt");
    std::string line;
    DegreeGraph dg = DegreeGraph(MAX_ROWS, MAX_COLS);

    // Initialize the graph (load the mem)
    int row = 0, col;
    while (std::getline(file, line)) {
        for (int col = 0; col < MAX_COLS; col++) {
            if (line[col] == '@')
                dg.markNode(row, col);
        }
        row++;
    }

    int iters = 0;
    bool rerun = true;
    while (rerun) {
        rerun = false;
        iters++;
        for (row = 0; row < MAX_ROWS; row++) {
            for (col = 0; col < MAX_COLS; col++) {
                if (dg.marked(row, col) && dg.getDegree(row, col) > MIN_NEIGHS) {
                    dg.removeNode(row, col);
                    rerun = true;
                }
            }
        }
    }
    std::cout << "Rolls removed: " << dg.removed_ << "\n";
    std::cout << "Completed in " << iters << " iterations\n";
    return 0;
}