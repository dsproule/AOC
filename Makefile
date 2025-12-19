CXX = g++
CXXFLAGS = -std=c++17 -O2
TARGET := aoc

.PHONY: all clean

all: $(TARGET)

%: %.cpp
	$(CXX) $(CXXFLAGS) $^ -o $(TARGET)

clean:
	rm -f aoc
