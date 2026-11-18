# Shared build of the C++ ports of the TomSpecs samples: a vendored-source build.
#
# The C++ runtime and facade ship as source only (no package registry), so a
# sample compiles their sources itself: every `src/*.cpp` of tom_som_cpp_runtime and
# tom_som_cpp_v0 from the checkout, with the flags som_toolchains.md specifies
# (C++17, -Wall -Wextra). The objects go to one directory every C++ sample shares,
# <tom_specs_samples>/target/cpp (and target/cpp-asan for the sanitizer build), so
# the 22 MB generated facade is compiled once, not once per sample.
#
# A sample's Makefile sets nothing and includes this file:
#   include ../../tool/cpp_sample.mk
# Targets: `make` (build/sample), `make asan` (build/sample_asan: AddressSanitizer
# + UndefinedBehaviorSanitizer), `make clean`.

SAMPLES  := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
CHECKOUT := $(abspath $(SAMPLES)/..)
RUNTIME  := $(CHECKOUT)/tom_som_cpp_runtime
FACADE   := $(CHECKOUT)/tom_som_cpp_v0

CXX     ?= c++
CXXFLAGS ?= -std=c++17 -Wall -Wextra -O1 -g
ASANFLAGS := -fsanitize=address,undefined -fno-omit-frame-pointer
CPPFLAGS := -I$(FACADE)/include -I$(RUNTIME)/include -DTOMSPECS_CHECKOUT='"$(CHECKOUT)"'

RT_SRC := $(wildcard $(RUNTIME)/src/*.cpp)
FC_SRC := $(wildcard $(FACADE)/src/*.cpp)
OBJDIR      := $(SAMPLES)/target/cpp
ASAN_OBJDIR := $(SAMPLES)/target/cpp-asan
OBJ      := $(patsubst $(RUNTIME)/src/%.cpp,$(OBJDIR)/rt_%.o,$(RT_SRC)) \
            $(patsubst $(FACADE)/src/%.cpp,$(OBJDIR)/fc_%.o,$(FC_SRC))
ASAN_OBJ := $(patsubst $(OBJDIR)/%,$(ASAN_OBJDIR)/%,$(OBJ))
HEADERS  := $(wildcard $(RUNTIME)/include/*.hpp $(FACADE)/include/*.hpp)

.PHONY: all asan clean
all: build/sample
asan: build/sample_asan

build/sample: main.cpp $(OBJ) $(HEADERS) | build
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) main.cpp $(OBJ) -o $@

build/sample_asan: main.cpp $(ASAN_OBJ) $(HEADERS) | build
	$(CXX) $(CXXFLAGS) $(ASANFLAGS) $(CPPFLAGS) main.cpp $(ASAN_OBJ) -o $@

$(OBJDIR)/rt_%.o: $(RUNTIME)/src/%.cpp $(HEADERS) | $(OBJDIR)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -c $< -o $@
$(OBJDIR)/fc_%.o: $(FACADE)/src/%.cpp $(HEADERS) | $(OBJDIR)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -c $< -o $@
$(ASAN_OBJDIR)/rt_%.o: $(RUNTIME)/src/%.cpp $(HEADERS) | $(ASAN_OBJDIR)
	$(CXX) $(CXXFLAGS) $(ASANFLAGS) $(CPPFLAGS) -c $< -o $@
$(ASAN_OBJDIR)/fc_%.o: $(FACADE)/src/%.cpp $(HEADERS) | $(ASAN_OBJDIR)
	$(CXX) $(CXXFLAGS) $(ASANFLAGS) $(CPPFLAGS) -c $< -o $@

build $(OBJDIR) $(ASAN_OBJDIR):
	mkdir -p $@

clean:
	rm -rf build
