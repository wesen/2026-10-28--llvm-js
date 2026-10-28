CXX ?= g++
CXXFLAGS := -std=c++17 -O2 -Wall -Wextra -Wpedantic -Iinclude
.PHONY: build test demo clean
build: build/pico-sim
build/pico-sim: kernel/pico_sim.cpp include/pico_abi.h
	@mkdir -p build
	$(CXX) $(CXXFLAGS) kernel/pico_sim.cpp -o $@
test: build
	python3 -m unittest discover -s tests -v
demo: build
	python3 scripts/demo.py
clean:
	rm -rf build/*.elf build/*.meta.json build/*.generated.c build/*.generated.ll build/pico-sim
