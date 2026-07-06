# tom_som_cpp_runtime — generic TomSpecs SOM runtime in idiomatic C++ (C++17).
#
# `make`          builds the static library build/libtom_som_cpp_runtime.a
# `make test`     builds + runs the conformance harness against the shared corpus
# `make unittest` builds + runs the standalone runtime unit tests
# `make clean`    removes build artefacts

CXX      ?= g++
CXXFLAGS ?= -std=c++17 -Wall -Wextra -O2
INCLUDE  := -Iinclude
# -MMD -MP emit per-object .d files listing every header each .o depends on, so
# editing a header recompiles its dependents. Without this the build silently
# links objects compiled against different struct layouts (ABI mismatch).
DEPFLAGS := -MMD -MP

SRC := $(wildcard src/*.cpp)
OBJ := $(patsubst src/%.cpp,build/%.o,$(SRC))
DEP := $(OBJ:.o=.d) build/conformance.d

LIB     := build/libtom_som_cpp_runtime.a
HARNESS := build/conformance
CORPUS  ?= ../tom_som_conformance/corpus

# Standalone unit-test binaries (each has its own main(); exit 0 == green).
UNIT_SRC := tests/version_check_test.cpp tests/facade_editability_test.cpp \
            tests/list_add_content_test.cpp tests/can_have_content_test.cpp
UNIT_BIN := $(patsubst tests/%.cpp,build/%,$(UNIT_SRC))
DEP      += $(patsubst tests/%.cpp,build/%.d,$(UNIT_SRC))

.PHONY: all test unittest clean

all: $(LIB)

build:
	mkdir -p build

build/%.o: src/%.cpp | build
	$(CXX) $(CXXFLAGS) $(DEPFLAGS) $(INCLUDE) -c $< -o $@

$(LIB): $(OBJ)
	ar rcs $@ $(OBJ)

$(HARNESS): tests/conformance.cpp $(LIB)
	$(CXX) $(CXXFLAGS) $(DEPFLAGS) -MF build/conformance.d $(INCLUDE) tests/conformance.cpp $(LIB) -o $@

build/%: tests/%.cpp $(LIB) | build
	$(CXX) $(CXXFLAGS) $(DEPFLAGS) -MF build/$*.d $(INCLUDE) $< $(LIB) -o $@

test: $(HARNESS)
	$(HARNESS) $(CORPUS)

# Builds and runs every standalone unit-test binary; stops on the first failure.
unittest: $(UNIT_BIN)
	@for t in $(UNIT_BIN); do echo "== $$t =="; ./$$t || exit 1; done

clean:
	rm -rf build

-include $(DEP)
