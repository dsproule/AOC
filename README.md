# Submission

### This submission includes the source code for 6 problems (Days 1-5, Day 7). Every solution is implemented in CPP/Python first (as I felt it was quicker to debug the algorithms). The software source is left to give an alternative view of the algorithms implemented.

I am using **Icarus Verilog version 11.0** to simulate the RTL. I do not have access to my University's Synopsys license so designs were not synthesized, however I was careful to only use constructs I knew worked from previous experience.

## Directory Structure
```
.
├── inputs
├── rtl
│   ├── src
│   └── tb
└── sw
```

- inputs: my AOC puzzle inputs, labelled for the day accordingly.
- rtl/src: all designs. For hierarchical designs, the top-level module is labelled by the day. (ex. aoc5.sv is top)
- rtl/tb: tb's for the designs. handles string parsing and deployment. Also written in systemVerilog.
- sw: cpp/python implementation of algorithms. the aocN_hw variants are closer but not always direct models of the hw version I later implemented.

All designs can be ran using the *Makefile* in the root. The pattern is "make aocN_ext" where **N** is the day and **ext** is sv/cpp/py.
```
make aoc1_sv
make aoc1_hw_cpp
```
There is a script called run_all.sh that can be used to automatically deploy all implemented designs using the RTL simulator. Just run **./run_all.sh**

# Algorithms

I will refer to the algorithms as if the problem statement is known (because all AOC problems are the same for everyone). If I were only allowed to select 3, I want to highlight solutions 5, 2, 4 in that order because these really pushed my math/hardware ability. However, 1, 3, 7 are good examples of extremely simple but optimized approaches to accelerating an algorithm.

## Day 1
Instead of simulating the turning of the counter I calculate endpoints pre-emptively and tally zeros accordingly. The implementation for this is relatively straightforward from the CPP version. We can make every calculation in a single-cycle so the algorithm is linear based on the inputs. I use division/mods by constants I also abstracted the calculation into a slightly different shift-multiply operation to reduce critical path delays where I felt was obvious and appropriate. 

## Day 2
At its core, the problem asked us to sum over special numbers. I will provide a high-level overview of the concept. The python code I believe is easiest to understand--  under aoc2.py, before looking at the hardware model of aoc2_hw.cpp and the verilog. This solution is very math-heavy and parallelized.

At a very high level, we were tasked with taking a number of N digits, that can be split into X groups evenly and summing all possible combinations that satisfy this with the bounds of the provided two endpoints. We then turn them into overlapping ranges and compute the series, then we subtract the two values and accumulate this. 

We will cover this for a singular set of endpoints "3737332285-3737422568". So first, we generate the base for each endpoint. In this case, the first endpoint *3737332285* has 10 digits. So we create valid splits of 2 and 5.

```
Ex.

Number of 10 digits with 2-split, 5-split.
         XXXXXYYYYY     XXYYZZWWPP
base:    0000100001     0101010101
```

Then we iterate over the valid range that fills a particular split, for the examples above. the 2-split goes from 10-99 and 5-split goes from 10000-99999. This all values in these ranges multiplied against the base creates a valid num. 

```
Ex.
0101010101 * 82    = 8282828282
0000100001 * 10032 = 1003210032

```

Observe that what we're actually doing is the series of **base * i** for bounds of 10^split to 10^(split + 1). Because we know the bounds and base is constant, we can pull this out and compute the series of i over the bounds. This sum is multiplied at the end and this is our accumulation range for N digits. Note here, that some values create duplicates. 

```
Ex.
0101010101 * 88    = 8888888888
0000100001 * 88888 = 8888888888
```

To remove these, we do a similar process to the above (prim_calc in the code) that repeats this work on a smaller scale to extract the duplicates. This is subtracted from the accumulations above. 

Note that these computations are parallelizable. We can create an instance that handles (group of X size) and accumulate these together after they've all been computed (this is what the hardware does). There are lookup tables for base10 that further accelerate this computation (because these are known constants). The last thing we do after accumulating is expand this calculation to all smaller values to create a prefix-range. This means we statically add all possible groupings of N! digits (9 digs, 8 digs, 7 digs ...), which is handled by a lookup table as well (these values are constants). The groupings are summed in a parallel structure.

One both bounds are computed, we subtract the front endpoint from the back (since they overlap this is now possible to get in-between values) and accumulate this into our final result. 

Each set of endpoint takes about 32 cycles to complete and the same block is used per endpoint to reduce area overhead. So this scales linearly with every endpoint. O(32 * n) = O(n) 

## Day 3
Conceptually we are trying to form the largest number possible given a set of digits in-order. It follows that we want the largest values as far towards the front as possible because these are likely to give us our maximal result. We can do this by greedily pushing numbers forward as long as there is enough input in the rest of the line to form a full value. 

Ex.
```
456]93245...
    ^ 
becomes where ] represents the top of the stack

9]3245...

```
This works because we know that for any 12 digit number, if it starts with a 9 that is greater than all values that may start with a 4,5,6.

In software, I did this with a while loop popping from the top of a stack before insertion. I wanted to maintain low-latency in hardware so I avoided the extra cost of poping for multiple cycles-- note, I didn't want to implement backpressure on the input as would be required as well. Instead, I created a "long-stack" that allows for extended pops as long as the top X values would all satisfy the poping condition. This is implemented with a few masks that get joined together to create a decision and then a single-cycle, multiple value pop/insertion is triggered. The masks decide "is this true for multiple values until this point".

## Day 4
Conceptually here we are pruning values based on empty neighbors in the grid. The simplest case for our problem is to simply perform a linear scan across the grid and mutate indices as we go. While this works, It has a very large latency as we would have to traverse the entire 139*139 grid X amount of times, where X is the number of iterations needed for nothing to change. Instead the design is parallelized to split the grid into regions owned by **workers** who free up their owned nodes asynchronously. This reduces our total latency to approximately (139*139) / N where N is the number of **workers**, in the code I called them "free-machines". The design is N machines connected up to a central memory controller (single-port BRAM template) with a basic arbiter to allow single access. The design is parameterized to accept 1, 2, 3, 6 machines. In theory we could scale this further but to reduce excessive area, I chose 6 as our maximal value. There are multiple sub-systems working together so I will describe them each.

- Memory: The memory controller acts similar to a write-through cache where the most recently requested line is saved for immediate access and new requests trigger a fetch loop. This is done by creating a wrapper around a single-port synchronous BRAM template. Like cache, the first request of the line takes 2 cycles and subsequent requests take only a single-cycle. In the memory module, I store the entire row as a single entry (but the lines are 139 + padding). They are padded because to reduce area, the memory module actually only outputs a small portion of the entire line at a time. This width is TX-width *"transfer width"*. There is an arbiter that acts similar to a spinlock to allocate memory access.

- Machines: As discussed, a machine is only responsible for updating it's region. Within each machine there are 3 vectors to load in the prev row, current row, next row. The algorithm begins by loading these in from memory and updating these registers locally. There is then a 3x3 window at the front of the regs so we can calculate the neighbors that are present for the target node location in a single step. The registers are actually circular shift registers, so they cycle their values through the window. We update only the central node of the window per step if required. As we pass TX-width steps, we writeback just a portion of the vector at a time. This is scatter memory access patterns and reduce memory contention amongst machines.

```
ex. regs_1[1] (assuming left is lsb) is the location under scope. we would update it to 0 and rotate left on the next cycle.

regs_0: |000|0100111011          regs_0: |000|1001110110
regs_1: |110|1001011101     ->   regs_1: |001|0010111010
regs_2: |000|1000101000          regs_2: |001|0001010001
```

- Parameters: I experimented with multiple hyperparameters to uncover the optimal setup. I found that with a single machine it took 814177 cycles to complete and 32-bits seemed to be the best bit-width. The cycles appeared to show logarithmic behavior as we increased the parallelization. This is likely due to memory contention. The module is currently configured to deploy with 6 machines at 32-bits. 

```
MACH_N: 1,TX_DATA_WIDTH: 32, Cycles: 814177
MACH_N: 1,TX_DATA_WIDTH: 64, Cycles: 920929
MACH_N: 2,TX_DATA_WIDTH: 32, Cycles: 419810
MACH_N: 2,TX_DATA_WIDTH: 64, Cycles: 468898
MACH_N: 2,TX_DATA_WIDTH: 16, Cycles: 431330
MACH_N: 3,TX_DATA_WIDTH: 32, Cycles: 282915
MACH_N: 6,TX_DATA_WIDTH: 32, Cycles: 181734
```

I considered making the memory a set of banks where each machine owns a location. I decided this was not worth the extra hardware cost because these cycle counts are relatively close to the minimum latency anyways. 

```
rough estimates:

minimum traversal cost per machine: (139 rows / 6 machines) * 160 padded row = 3840 cycles
fetch_latency: 1 cycle fetch + 5 TX cycles = 6 cycles
write_latency: (1 cycle fetch + 1 cycle write) * 5 writes = 11 cycles
rows: (139 rows / 6 machines) + 2 border rows = 26
iterations: 32

total cost: (minimum_traverse + (fetch_latency + write_latency + 4) * rows) * iterations = 140k
 
These are the larger costs but per iteration we lose cycles to contention, drainage, border regs and other sources. These countribute to the higher cycle count that gets amplified per iteration. 
```

## Day 5
Our goal is to get the total range of values spanned by the intervals. Traditionally, this would entail sorting the incoming intervals, merging the overlaps and taking the difference of the remaining spanned regions. To do this, I creates 3 separate stages that excecute sequentially, handling each of these responsibilities in isolation. I will describe the overall components/functions and then the internals of each. 

At a system level, we feature two ping-pong memory modules that are odd-evenk banked. This means we can fetch/write 2 values at a time from each memory instance. The top-level module keeps track of which stage is currently running, to mux control of the ping-pong memories to the executing submodule. Intermediate results are passed using the ping-pong mems until the final result is output. First, the incoming data stream is stored into the ping array. When the stream completes, we begin execution of stage 1.

### stage 1
The responsibility of this stage is to sort the initial values into chunks of 16. I do this using a bitonic-merge parallel sorting network. 

According to the algorithm, the bitonic network requires an initial sort for half of the values to create the bitonic pattern. I do this by building a single sort-8 network based on a schematic cited in the source code as being the most optimal network that could be constructed for 8 values. It allows configurability to sort in ascending/descending order based on the initial input and it is fully pipelined and supports multiple 8-segment chunks in flight at a time. Note here, multiple chunks in flight **DO NOT** need to be sorted in the same direction. When 16 values are produced, the streams are passed into paramterized, recursive-bitonic sorter I wrote. The final sorted chunks are pushed to the pong-memory and there is enough latency between incoming chunks to never require a stall. 

In the source, this is called the sort_phase_inst which at a top level is the sort_bitonic module. 

### stage 2
After stage 1 has completed, we begin stage 2 which is the merging phase. At the start, our pong memory is chunks of 16 sorted in ascending order, we begin the merging algorithm that unifies all chunks into a single sorted array. 

We do so by placing pointers at the front of two sequential streams and inserting them sorted into the opposing ping/pong array. At this point is where we exploit the two memories available, requesting from ping and inserting to pong on vice versa. This maintains high-memory throughput. 

Once we've merged the entire stream for a width, we double our reach and begin again. This turns chunks 16 into 32, 32 into 64, 64 into 128, 128 into 256 (our total is 186 values so at this point we stop). The pingpong pointer is alternated a final time and the corresponding read memory contains the entire sorted set of intervals.

### stage 3
Stage 3 now executes with read-only access from the sorted memory bank. We perform the classic interval merging pattern where we extend a locally saved interval until no overlap exists, at which point we accumulate the range. The final accumulation is the output and the accelerator has completed. 

In terms of area complexity, we require only a larger BRAM bank to encompass a longer stream, O(n), the rest of the hardware can remain the same. 

Stage 1 has a complexity of O(1), the sort is logarithmic but only 16 values are used at a time and streamed.
Stage 2 has a complexity of O(log(n)) because we increasingly merge N_prev / 2 values until we hit the full stream.
Stage 3 is O(N), we need to traverse the entire array once.

## Day 7
The hardware acceleration for this challenge is very simple. Our goal is to keep track of down-stream beams and split when there is a collision between the beam and a splitter. To do so, we process each row as a unit, and use a single circular shift register that maintains the current possible beam distributions. We rotate the array and evaluate only the front element, if there is a collision between a possible beam and splitter, we apply the updates into the register in place until we get to the final row where we sum up the values.

## About Me
I recently graduated from Columbia University with both a B.S. and M.S. in Computer Engineering. I have a strong hardware–software background and am particularly interested in algorithmic hardware development post-graduation.

I initially planned to pursue a HardCaml implementation of some of my simpler designs, given my prior exposure to Chisel and the conceptual similarities between the two, but was unable to do so due to graduation and travel timing being a busy time.

I’ve included my resume in the root directory in case the team is interested. Regardless, I hope you enjoy reviewing my solutions. I found the challenge of solving these problems algorithmically and translating them into hardware accelerators to be very enjoyable!