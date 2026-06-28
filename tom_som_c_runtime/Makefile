# tom_som_c_runtime — generic TomSpecs SOM runtime in C.
#
# `make`         builds the static library build/libtom_som_c_runtime.a
# `make test`    builds + runs the conformance harness against the shared corpus
# `make clean`   removes build artefacts

CC      ?= gcc
CFLAGS  ?= -std=c11 -Wall -Wextra -O2
INCLUDE := -Iinclude

SRC := $(wildcard src/*.c)
OBJ := $(patsubst src/%.c,build/%.o,$(SRC))

LIB    := build/libtom_som_c_runtime.a
HARNESS := build/conformance
CORPUS ?= ../tom_som_conformance/corpus

.PHONY: all test clean

all: $(LIB)

build:
	mkdir -p build

build/%.o: src/%.c | build
	$(CC) $(CFLAGS) $(INCLUDE) -c $< -o $@

$(LIB): $(OBJ)
	ar rcs $@ $(OBJ)

$(HARNESS): tests/conformance.c $(LIB)
	$(CC) $(CFLAGS) $(INCLUDE) tests/conformance.c $(LIB) -o $@

test: $(HARNESS)
	$(HARNESS) $(CORPUS)

clean:
	rm -rf build
