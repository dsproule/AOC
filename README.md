## Submission

### This submission includes the source code for 6 problems (Days 1-5, Day 7). Every solution is implemented in CPP first (as I felt it was quicker to debug the algorithms).

## Directory Structure
```
.
|- rtl/
    |- src/
    |- tb/
|- sw/
|- inputs/
```

- The SW contains the CPP/Python code. The inputs are my generated AOC puzzle inputs and the rtl directory contains all the SystemVerilog.
- The Makefile automates all deployment. "make aocN_ext" can be used to automatically run any of the scripts or eleborate and simulate the rtl. 

For example. day 1 sv and cpp can be used via
```
make aoc1_sv
make aoc1_hw_cpp
```

## 1
Instead of simulating the turning of the counter I calculate endpoints pre-emptively and tally zeros accordingly. The implementation for this is relatively straightforward from the CPP version because the algorithm is simple. Because I use division/mods by constants I also abstracted the calculation into a slightly different shift-multiply operation to reduce critical path delays. 

## 2
At its core, the problem asked us to sum over a range of special numbers. I will provide a high-level overview of the concept. The python code I believe is easiest to understand under aoc2.py before looking at the hardware model of aoc2_hw.cpp and the verilog, but this solution is very math-heavy.

At a very high level, we were tasked with taking a number and finding combinations where X digits repeat. We do this by first generating the base of the range given by the endpoints of the puzzle input and then iterating up to the max, multiplying against the base as we go. 

```
Ex.

Number of 9 digits with 3-split.
         XXXYYYZZZ
base:    100100100
n_range: 100-999

we sum (base * n) for n in n_range

(100100100, 10110101, 102102102, ... 997997997, 998998998, 999999999)

```

These numbers form a nice series equation: *sum(base * n)* so I simply use the closed-form formulas to compute the results instead of actually performing the addition. I do this for every grouping that a number is evenly divisible, (if its a 10-digit number we calculate 2 digs, 5 digs). There is a pruning step, some groupings form duplicates **(*55 55 55 55 55* and *55555 55555* would result in the same numebr)** So i calculate collisions and subtract those as well. For both endpoints, this summation is calculated. In order to turn it into an overlapping intervals (so we can subtract endpoint computations and get a range) I also include *all* the possible groupings into the per-endpoint calculation. Then I perform a simple subtraction. 

In hardware, some values are repeatedly used (like base10 values and the prefix) so I use shared lookup tables to accelerate computation. The groups can also be calculated in parallel based on digit length so we generate instances for each possible length (64-bits has max 10 digits so I only need 10 splitters). 

## 3
The hardware also very closely resembles the software implementation for this problem. Conceptually we are trying to form the largest number. It follows that we want the largest values as far towards the front as possible. We can do this by greedily pushing numbers forward as long as there is enough input in the rest of the line to form a full value. In software, I did this with a while loop but I wanted to maintain low-latency in hardware. I created a "long-stack" that allows for extended pops as long as the top X values would all satisfy the poping condition. This is implemented with a few maks that get joined together to create a decision. 

Ex.
```
456]93245...
    ^ 

Assume the ] is the top of our current stack. The 9 is larger than all values and because there are more digits following it, we perform the single-cycle long pop.

9]3245...

```

## 4
This design is more complex because it is parameterizable and parallelized. Conceptually here we are pruning values based on empty neighbors in the grid. The simplest case for our problem is to simply perform a linear scan across the grid and mutate indices as we go. While this works, It has a very large latency as we would have to traverse the entire 139*139 grid X amount of times, where X is the number of iterations needed for nothing to change. Instead the design is fully parallelized to split the grid into regions owned by **workers** who free up their owned nodes asynchronously. This reduces our total latency to approximately (139*139) / N where N is the number of **workers**, in the code I called them "free-machines". The design is N machines connected up to a central memory controller (single-port BRAM template) with a basic arbiter to allow single access. 

- Memory: The memory controller acts similar to a write-through cache where the most recently requested line ia saved for immediate access and new requests trigger a fetch loop. In the memory module, I store the entire row as a single entry (but the lines are 139 + padding). They are padded because to reduce area, the memory module actually only outputs a TX-width of data at a time at a time. This could have been banked but I felt it unnecessary since functionality would remain the same (wrt splitting the long padded vector into smaller ones to fit into sub-brams)

- Machines: As discussed, a machine is only responsible for updating it's region. Within each machine there are 3 vectors to load in the prev row, current row, next row. The algorithm begins by loading these in from memory and updating these registers. There is then a 3x3 window at the front of the regs so we can calculate the neighbors that are present in a single step. The registers are actually circular shift registers, so they cycle their values through the window. We update only the central node of the window per step if required. As we pass TX widths, we writeback just a portion of the vector at a time. This is scatter memory access patterns and reduce memory pressure.

- Parameters: I experimented with multiple hyperparameters to uncover the optimal discovery. I found that with a single machine it took 814177 cycles to complete and 32-bits seemed to be the best bit-width. The cycles appeared to show logarithmic behavior as we increased the parallelization. This is likely due to memory contention. The module is currently configured to deploy with 6 machines at 32-bits. 

```
MACH_N: 1,TX_DATA_WIDTH: 32, Cycles: 814177
MACH_N: 1,TX_DATA_WIDTH: 64, Cycles: 920929
MACH_N: 2,TX_DATA_WIDTH: 32, Cycles: 419810
MACH_N: 2,TX_DATA_WIDTH: 64, Cycles: 468898
MACH_N: 2,TX_DATA_WIDTH: 16, Cycles: 431330
MACH_N: 3,TX_DATA_WIDTH: 32, Cycles: 282915
MACH_N: 6,TX_DATA_WIDTH: 32, Cycles: 181734
```

## 5
## 7
The hardware acceleration for this challenge is also very simple. We use a single circular shift register to that represents the current downward splits. We let this cycle and apply the updates as needed in place until we get to teh final result where we sum the values.

I recently graduated with an MS and BS in Computer Engineering from Columbia University. I have a very heavy hardware/software background and am extremely interested in pursuing this style of algorithmic, hardware development post-grad. I hope you enjoyed my solutions, I enjoyed the challenge of solving these with software and creating hardware accelerators.