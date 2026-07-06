# tom_som_c_runtime — generic TomSpecs SOM runtime in C.
#
# `make`         builds the static library build/libtom_som_c_runtime.a
# `make test`    builds + runs the conformance harness against the shared corpus
# `make clean`   removes build artefacts

CC      ?= gcc
CFLAGS  ?= -std=c11 -Wall -Wextra -O2
INCLUDE := -Iinclude
# -MMD -MP emit per-object .d files listing every header each .o depends on, so
# editing a header recompiles its dependents. Without this the build silently
# links objects compiled against different struct layouts (ABI mismatch).
DEPFLAGS := -MMD -MP

SRC := $(wildcard src/*.c)
OBJ := $(patsubst src/%.c,build/%.o,$(SRC))
DEP := $(OBJ:.o=.d) build/conformance.d

LIB    := build/libtom_som_c_runtime.a
HARNESS := build/conformance
CORPUS ?= ../tom_som_conformance/corpus

.PHONY: all test clean

all: $(LIB)

build:
	mkdir -p build

build/%.o: src/%.c | build
	$(CC) $(CFLAGS) $(DEPFLAGS) $(INCLUDE) -c $< -o $@

$(LIB): $(OBJ)
	ar rcs $@ $(OBJ)

$(HARNESS): tests/conformance.c $(LIB)
	$(CC) $(CFLAGS) $(DEPFLAGS) -MF build/conformance.d $(INCLUDE) tests/conformance.c $(LIB) -o $@

test: $(HARNESS)
	$(HARNESS) $(CORPUS)

clean:
	rm -rf build

-include $(DEP)
