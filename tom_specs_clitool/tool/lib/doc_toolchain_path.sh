# Shared PATH resolution for the documentation toolchains. Sourced by
# regenerate_api_references.sh (which runs the generators) and by
# provision_doc_generators.sh (which reports on and installs them) — they must
# agree about what counts as installed, or the provisioner certifies a host the
# driver then skips.
#
# Every rule here exists because a toolchain the host HAS was invisible to a
# non-interactive run, which reads as a missing generator rather than as the
# PATH quirk it is.

# rustup and the Go tarball wire themselves into the *interactive* shell profile
# only. Same prepend as run_all_suites.sh and regenerate_golden.sh.
for extra in "$HOME/.cargo/bin" "/usr/local/go/bin" "$HOME/.local/go/bin" "/opt/homebrew/bin"; do
  case ":$PATH:" in *":$extra:"*) ;; *) [ -d "$extra" ] && PATH="$PATH:$extra" ;; esac
done

# Dart: on a host whose Dart comes bundled with Flutter, the SDK is a checkout
# wired into the interactive profile only — so `dart` is absent here while the
# host documents Dart perfectly well. DART_SDK and FLUTTER_ROOT name it
# explicitly; otherwise look beside a `flutter` on PATH, then in the usual
# checkout locations.
if ! command -v dart > /dev/null 2>&1; then
  dart_dirs=""
  [ -n "${DART_SDK:-}" ] && dart_dirs="$dart_dirs $DART_SDK/bin"
  [ -n "${FLUTTER_ROOT:-}" ] && dart_dirs="$dart_dirs $FLUTTER_ROOT/bin"
  flutter_on_path="$(command -v flutter 2> /dev/null || true)"
  [ -n "$flutter_on_path" ] && dart_dirs="$dart_dirs $(dirname "$flutter_on_path")"
  dart_dirs="$dart_dirs $HOME/development/flutter/bin $HOME/Desktop/development/flutter/bin"
  dart_dirs="$dart_dirs $HOME/flutter/bin /opt/flutter/bin /usr/lib/dart/bin"
  for d in $dart_dirs; do
    if [ -x "$d/dart" ]; then PATH="$PATH:$d"; break; fi
  done
fi

# Java: prefer a JDK 21 javadoc, because 21 is what the SOM build matrix pins —
# a reference rendered by a different major than the one that compiles the code
# is a reference for a different language level. Homebrew's openjdk@21 is
# keg-only, so it is NOT on PATH even when installed, and a platform-default
# javadoc (macOS ships a /usr/bin shim for whatever JDK is registered) hides it:
# the check therefore cannot be "is javadoc absent".
javadoc_21=""
for cand in /opt/homebrew/opt/openjdk@21/bin /usr/lib/jvm/java-21-openjdk-amd64/bin \
            /usr/lib/jvm/java-21-openjdk/bin; do
  [ -x "$cand/javadoc" ] && { javadoc_21="$cand"; break; }
done
if [ -z "$javadoc_21" ] && [ -x /usr/libexec/java_home ]; then
  JH21="$(/usr/libexec/java_home -v 21 2> /dev/null || true)"
  [ -n "$JH21" ] && [ -x "$JH21/bin/javadoc" ] && javadoc_21="$JH21/bin"
fi
if [ -n "$javadoc_21" ]; then
  PATH="$javadoc_21:$PATH"
elif ! command -v javadoc > /dev/null 2>&1 && [ -x /usr/libexec/java_home ]; then
  # No 21 anywhere: any JDK beats no reference at all.
  JH="$(/usr/libexec/java_home 2> /dev/null || true)"
  [ -n "$JH" ] && [ -x "$JH/bin/javadoc" ] && PATH="$JH/bin:$PATH"
fi

export PATH
