# Shared build of the C ports of the TomSpecs samples: a vendored-source build.
#
# The C runtime and facade ship as source only (no package registry), so a
# sample compiles their sources itself: every `src/*.c` of tom_som_c_runtime and
# tom_som_c_v0 from the checkout, with the flags som_toolchains.md specifies
# (C11, -Wall -Wextra). The objects go to one directory every C sample shares,
# <tom_specs_samples>/target/c (and target/c-asan for the sanitizer build), so
# the 22 MB generated facade is compiled once, not once per sample.
#
# A sample's Makefile sets nothing and includes this file:
#   include ../../tool/c_sample.mk
# Targets: `make` (build/sample), `make asan` (build/sample_asan: AddressSanitizer
# + UndefinedBehaviorSanitizer), `make clean`.

SAMPLES  := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
CHECKOUT := $(abspath $(SAMPLES)/..)
RUNTIME  := $(CHECKOUT)/tom_som_c_runtime
FACADE   := $(CHECKOUT)/tom_som_c_v0

CC      ?= cc
CFLAGS  ?= -std=c11 -Wall -Wextra -O1 -g
ASANFLAGS := -fsanitize=address,undefined -fno-omit-frame-pointer
CPPFLAGS := -I$(FACADE)/include -I$(RUNTIME)/include -DTOMSPECS_CHECKOUT='"$(CHECKOUT)"'

RT_SRC := $(wildcard $(RUNTIME)/src/*.c)
FC_SRC := $(wildcard $(FACADE)/src/*.c)
OBJDIR      := $(SAMPLES)/target/c
ASAN_OBJDIR := $(SAMPLES)/target/c-asan
OBJ      := $(patsubst $(RUNTIME)/src/%.c,$(OBJDIR)/rt_%.o,$(RT_SRC)) \
            $(patsubst $(FACADE)/src/%.c,$(OBJDIR)/fc_%.o,$(FC_SRC))
ASAN_OBJ := $(patsubst $(OBJDIR)/%,$(ASAN_OBJDIR)/%,$(OBJ))
HEADERS  := $(wildcard $(RUNTIME)/include/*.h $(FACADE)/include/*.h)

.PHONY: all asan clean
all: build/sample
asan: build/sample_asan

build/sample: main.c $(OBJ) $(HEADERS) | build
	$(CC) $(CFLAGS) $(CPPFLAGS) main.c $(OBJ) -lm -o $@

build/sample_asan: main.c $(ASAN_OBJ) $(HEADERS) | build
	$(CC) $(CFLAGS) $(ASANFLAGS) $(CPPFLAGS) main.c $(ASAN_OBJ) -lm -o $@

$(OBJDIR)/rt_%.o: $(RUNTIME)/src/%.c $(HEADERS) | $(OBJDIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@
$(OBJDIR)/fc_%.o: $(FACADE)/src/%.c $(HEADERS) | $(OBJDIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@
$(ASAN_OBJDIR)/rt_%.o: $(RUNTIME)/src/%.c $(HEADERS) | $(ASAN_OBJDIR)
	$(CC) $(CFLAGS) $(ASANFLAGS) $(CPPFLAGS) -c $< -o $@
$(ASAN_OBJDIR)/fc_%.o: $(FACADE)/src/%.c $(HEADERS) | $(ASAN_OBJDIR)
	$(CC) $(CFLAGS) $(ASANFLAGS) $(CPPFLAGS) -c $< -o $@

build $(OBJDIR) $(ASAN_OBJDIR):
	mkdir -p $@

clean:
	rm -rf build
