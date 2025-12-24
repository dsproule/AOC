CXXFLAGS = -std=c++17 -O2
VFLAGS = -g2012
TARGET := aoc

.PHONY: all clean

all: $(TARGET)

%_cpp: sw/%.cpp
	g++ $(CXXFLAGS) $^ -o $(TARGET) && ./aoc

%_py: sw/%.py
	python3 $^

aoc3_sv: rtl/src/aoc3_stack.sv

# Simulation
%_sv: rtl/src/%.sv rtl/tb/%_tb.sv
	iverilog $(VFLAGS) -I ./rtl $^ -o aoc && ./aoc

clean:
	rm -f aoc *.vcd *.gtkw
