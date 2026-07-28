# tom_som_cpp_runtime — generic TomSpecs SOM runtime in idiomatic C++ (C++17).
#
# `make`          builds the static + shared library and the pkg-config file
# `make test`     builds + runs the conformance harness against the shared corpus
# `make unittest` builds + runs the standalone runtime unit tests (no corpus)
# `make install`  installs headers, libraries, and the .pc file under PREFIX
# `make dist`     packages the source tree into a versioned tarball
# `make clean`    removes build artefacts

# VERSION is the TomSpecs model version. It is realigned by the packaging hook
# (tom_specs_clitool/bin/generate_som.dart) so the runtime, the generated facade,
# and the emitted pkg-config file all agree on one version.
VERSION := 1.0.0

CXX      ?= g++
AR       ?= ar
CXXFLAGS ?= -std=c++17 -Wall -Wextra -O2
PICFLAGS := -fPIC
INCLUDE  := -Iinclude
# -MMD -MP emit per-object .d files listing every header each .o depends on, so
# editing a header recompiles its dependents. Without this the build silently
# links objects compiled against different struct layouts (ABI mismatch).
DEPFLAGS := -MMD -MP

# Install layout (GNU-standard; DESTDIR-aware for staged / packaged installs).
PREFIX       ?= /usr/local
INCLUDEDIR   ?= $(PREFIX)/include
LIBDIR       ?= $(PREFIX)/lib
PKGCONFIGDIR ?= $(LIBDIR)/pkgconfig

NAME := tom_som_cpp_runtime

SRC := $(wildcard src/*.cpp)
OBJ := $(patsubst src/%.cpp,build/%.o,$(SRC))
# Position-independent objects for the shared library (separate suffix so the
# static and shared builds never share objects with different flags).
PICOBJ := $(patsubst src/%.cpp,build/%.pic.o,$(SRC))
DEP := $(OBJ:.o=.d) $(PICOBJ:.o=.d) build/conformance.d

STATIC := build/lib$(NAME).a
SHARED := build/lib$(NAME).so
# soname carries only the major version (ABI compatibility boundary).
SONAME := lib$(NAME).so.$(firstword $(subst ., ,$(VERSION)))
# Apple's ld spells the soname option -install_name; GNU ld uses -soname.
ifeq ($(shell uname -s),Darwin)
SONAME_FLAG := -Wl,-install_name,$(SONAME)
else
SONAME_FLAG := -Wl,-soname,$(SONAME)
endif
PC     := build/$(NAME).pc

HARNESS := build/conformance
CORPUS  ?= ../tom_som_conformance/corpus
HEADERS := $(wildcard include/*.hpp)

# Standalone unit-test binaries (each links the static lib; no corpus needed).
UNIT_SRC := tests/version_check_test.cpp tests/facade_editability_test.cpp \
            tests/list_add_content_test.cpp tests/can_have_content_test.cpp \
            tests/one_line_export_test.cpp tests/spec_meta_test.cpp \
            tests/spec_document_yaml_test.cpp \
            tests/spec_document_markdown_test.cpp \
            tests/docspecs_validator_test.cpp
UNIT_BIN := $(patsubst tests/%.cpp,build/%,$(UNIT_SRC))
DEP      += $(UNIT_BIN:=.d)

.PHONY: all test unittest clean install dist FORCE

all: $(STATIC) $(SHARED) $(PC)

FORCE:

build:
	mkdir -p build

build/%.o: src/%.cpp | build
	$(CXX) $(CXXFLAGS) $(DEPFLAGS) $(INCLUDE) -c $< -o $@

build/%.pic.o: src/%.cpp | build
	$(CXX) $(CXXFLAGS) $(PICFLAGS) $(DEPFLAGS) $(INCLUDE) -c $< -o $@

$(STATIC): $(OBJ)
	$(AR) rcs $@ $(OBJ)

$(SHARED): $(PICOBJ)
	$(CXX) -shared $(SONAME_FLAG) -o $@ $(PICOBJ)

# pkg-config metadata; Version tracks the TomSpecs model version. Regenerated on
# every build (FORCE) so an install-time PREFIX override is reflected in the .pc.
$(PC): FORCE | build
	@printf '%s\n' \
	  'prefix=$(PREFIX)' \
	  'exec_prefix=$${prefix}' \
	  'libdir=$(LIBDIR)' \
	  'includedir=$(INCLUDEDIR)' \
	  '' \
	  'Name: $(NAME)' \
	  'Description: Generic TomSpecs object-model runtime (C++).' \
	  'Version: $(VERSION)' \
	  'Libs: -L$${libdir} -l$(NAME)' \
	  'Cflags: -I$${includedir}' \
	  > $@

$(HARNESS): tests/conformance.cpp $(STATIC)
	$(CXX) $(CXXFLAGS) $(DEPFLAGS) -MF build/conformance.d $(INCLUDE) tests/conformance.cpp $(STATIC) -o $@

build/%: tests/%.cpp $(STATIC) | build
	$(CXX) $(CXXFLAGS) $(DEPFLAGS) -MF $@.d $(INCLUDE) $< $(STATIC) -o $@

test: $(HARNESS)
	$(HARNESS) $(CORPUS)

# Builds and runs every standalone unit-test binary; stops on the first failure.
unittest: $(UNIT_BIN)
	@for t in $(UNIT_BIN); do echo "== $$t =="; ./$$t || exit 1; done

# Install headers, the static + shared libraries (with the versioned soname
# symlinks), and the pkg-config file. Honours DESTDIR for staged packaging.
install: all
	install -d $(DESTDIR)$(INCLUDEDIR) $(DESTDIR)$(LIBDIR) $(DESTDIR)$(PKGCONFIGDIR)
	install -m 0644 $(HEADERS) $(DESTDIR)$(INCLUDEDIR)/
	install -m 0644 $(STATIC) $(DESTDIR)$(LIBDIR)/
	install -m 0755 $(SHARED) $(DESTDIR)$(LIBDIR)/lib$(NAME).so.$(VERSION)
	ln -sf lib$(NAME).so.$(VERSION) $(DESTDIR)$(LIBDIR)/$(SONAME)
	ln -sf $(SONAME) $(DESTDIR)$(LIBDIR)/lib$(NAME).so
	install -m 0644 $(PC) $(DESTDIR)$(PKGCONFIGDIR)/

# Source distribution tarball, versioned by the model version.
DIST := $(NAME)-$(VERSION)
DIST_FILES := Makefile run_conformance.sh \
  $(wildcard README.md LICENSE CHANGELOG.md readme_howtointegrate.md)
DIST_DIRS := src include tests
dist:
	rm -rf build/$(DIST) build/$(DIST).tar.gz
	mkdir -p build/$(DIST)
	cp -r $(DIST_DIRS) $(DIST_FILES) build/$(DIST)/
	tar -czf build/$(DIST).tar.gz -C build $(DIST)
	rm -rf build/$(DIST)

clean:
	rm -rf build

-include $(DEP)
