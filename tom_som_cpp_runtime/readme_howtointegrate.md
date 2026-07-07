# Integrating tom_som_cpp_runtime

`tom_som_cpp_runtime` is the generic, value-free TomSpecs object-model runtime
for idiomatic C++ (C++17, RAII). It has **zero external dependencies** (C++
standard library only) and is versioned to the TomSpecs **model version** — the
same version the typed facade `tom_som_cpp_v0` reports. Pin both to that version
so your document reads and writes match the model the facade was generated from.

Most projects depend on the typed facade `tom_som_cpp_v0` (which finds this
runtime through its include path / link flags) rather than on the runtime
directly. Depend on the runtime alone only when you drive the generic API by
section path.

C++ has no universal package registry, so distribution is by **library + headers
+ pkg-config file** (installed system-wide or vendored) or by **source
tarball**.

## Quick start

Build and install the runtime, then compile against it with `pkg-config`:

```sh
make
sudo make install                       # → PREFIX/lib, PREFIX/include, .pc
c++ myapp.cpp $(pkg-config --cflags --libs tom_som_cpp_runtime) -o myapp
```

```cpp
#include "tom_som_cpp_runtime.hpp"

#include <iostream>

int main() {
  som::SpecDocument doc;
  doc.setContent("SBP/currentLandscape/content", "A unifying order platform.");
  std::cout << doc.content("SBP/currentLandscape/content") << "\n";
  return 0;
}
```

## Dependency routes

### pkg-config (installed)

Install the static + shared libraries, the headers, and the pkg-config file
under `PREFIX` (default `/usr/local`), then let `pkg-config` supply the compile
and link flags:

```sh
make
make install PREFIX=/usr/local          # DESTDIR is honoured for staged installs
c++ myapp.cpp $(pkg-config --cflags --libs tom_som_cpp_runtime) -o myapp
```

The emitted `tom_som_cpp_runtime.pc` carries `Version = <model version>`, so
`pkg-config --modversion tom_som_cpp_runtime` reports the model version.

### Source tarball (vendored)

Produce a versioned source tarball and vendor it into your build:

```sh
make dist                                # → build/tom_som_cpp_runtime-<version>.tar.gz
```

Unpack it alongside your project and add `-I<runtime>/include` plus the built
`libtom_som_cpp_runtime.a` (or `.so`) to your own build.

### In-tree (monorepo)

When the SOM projects sit alongside your code, build the static library in place
and point your compiler at the checkout:

```sh
make -C ../tom_som_cpp_runtime
c++ myapp.cpp -I../tom_som_cpp_runtime/include \
   ../tom_som_cpp_runtime/build/libtom_som_cpp_runtime.a -o myapp
```

This is exactly how `tom_som_cpp_v0` consumes the runtime — the generated facade
`Makefile` records a relative `RUNTIME_DIR` and builds the runtime on demand, so
the generated source stays path-free and golden-stable while still building
in-repo.

## Pinning the version

`tom_som_cpp_runtime` and `tom_som_cpp_v0` both carry the TomSpecs model version:
the runtime in its `Makefile` `VERSION` (and hence its `.pc` `Version`), the
facade in its generated `Makefile`. When you upgrade the model, regenerate the
facade and move both to the new matching version so the runtime, the facade, and
your stored documents stay in step. The runtime is hand-authored (never
regenerated); only its `VERSION` is realigned to the model version by
`generate_som.dart`.

## Building from source

The runtime builds with any C++17 compiler and has no external dependencies:

```sh
make                 # static + shared library + pkg-config file
make test            # conformance harness against the shared corpus
make unittest        # standalone unit tests
make dist            # produce the .tar.gz source distribution
```
