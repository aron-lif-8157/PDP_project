CXX      := mpicxx
CC       := gcc
CXXFLAGS := -std=c++11 -O3 -Wall -Wextra -pedantic
CFLAGS   := -std=c99  -O3 -Wall -Wextra -pedantic
LDFLAGS  :=
BUILD    := build
TARGET   := $(BUILD)/main

# FIX: Include ALL .cpp files, not just those without headers
SRC_CPP  := $(wildcard src/*.cpp)   # This now includes ssa.cpp
SRC_C    := $(wildcard src/*.c)
OBJ      := $(patsubst src/%.cpp,$(BUILD)/%.o,$(SRC_CPP)) \
            $(patsubst src/%.c,  $(BUILD)/%.o,$(SRC_C))

# Rest of the Makefile remains the same
all: $(TARGET)

$(TARGET): $(OBJ)
	$(CXX) $(CXXFLAGS) $(OBJ) $(LDFLAGS) -o $@

$(BUILD)/%.o: src/%.cpp | $(BUILD)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD)/%.o: src/%.c | $(BUILD)
	$(CC)  $(CFLAGS)   -c $< -o $@

$(BUILD):
	mkdir -p $(BUILD)

clean:
	rm -rf $(BUILD)

.PHONY: all clean