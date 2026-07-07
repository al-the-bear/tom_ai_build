# Integrating tom_som_java_runtime

`tom_som_java_runtime` is the generic Java runtime for the TomSpecs object model.
The typed facade `tom_som_java_v0` depends on it; depend on the runtime directly
only when you want the generic `SpecDocument` / meta-model API. The Java package
is **`tom_som_runtime`** (the Maven artifact is `tom_som_java_runtime`). Both
artifacts are versioned to the TomSpecs **model version** — pin to that version
so your document reads and writes match the model.

## Quick start

Add `tom_som_java_runtime` (group `com.altbear.tomsom`) to your Maven `pom.xml`,
then:

```java
import tom_som_runtime.SpecDocument;

SpecDocument doc = new SpecDocument();
doc.setContent("PD/content", "A platform that unifies our order systems.");
System.out.println(doc.content("PD/content"));
```

## Dependency routes

### From a Maven repository

```xml
<dependency>
  <groupId>com.altbear.tomsom</groupId>
  <artifactId>tom_som_java_runtime</artifactId>
  <version>1.0.0</version>
</dependency>
```

### Local install (mvn install)

When the SOM projects sit alongside your build, install the runtime into your
local `~/.m2` repository:

```bash
cd ../tom_som_java_runtime && mvn install
```

### JAR fallback (no Maven)

On a JDK-only host, build the JAR with the bundled script and put it on your
classpath:

```bash
cd ../tom_som_java_runtime && ./build_jar.sh
# → build/tom_som_java_runtime-<version>.jar
```

## Pinning the version

The runtime carries a version taken from the TomSpecs model version, and the
typed `tom_som_java_v0` facade carries the same version. When you upgrade the
model, move both to the new matching version so the facade and your stored
documents stay in step.

## Building from source

```bash
cd tom_som_java_runtime
mvn package          # if Maven is available
./build_jar.sh       # JDK-only fallback (javac + jar)
```

Either writes `build/tom_som_java_runtime-<version>.jar`.
