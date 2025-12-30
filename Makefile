CXXFLAGS = -std=c++20 -O2
VFLAGS = -g2012
TARGET := aoc

.PHONY: all clean

all: $(TARGET)

%_cpp: sw/%.cpp
	g++ $(CXXFLAGS) $^ -o $(TARGET) && ./aoc

%_py: sw/%.py
	python3 $^

aoc3_sv: rtl/src/aoc3_stack.sv
aoc2_sv: rtl/src/aoc2_utils.sv rtl/src/aoc2_groupcount.sv rtl/src/aoc2_primcalc.sv

# Simulation
%_sv: rtl/src/%.sv rtl/tb/%_tb.sv
	iverilog $(VFLAGS) -I ./rtl $^ -o aoc && ./aoc

clean:
	rm -f aoc *.vcd *.gtkw rtl/converted.v
