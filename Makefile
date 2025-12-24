CXXFLAGS = -std=c++17 -O2
VFLAGS = -g2012
TARGET := aoc

.PHONY: all clean

all: $(TARGET)

%_cpp: sw/%.cpp
	g++ $(CXXFLAGS) $^ -o $(TARGET)

%_py: sw/%.py
	python3 $^

%_sv: rtl/src/%.sv rtl/tb/%_tb.sv
	iverilog $(VFLAGS) $^ -o aoc -I./rtl

clean:
	rm -f aoc *.vcd
