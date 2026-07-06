# SOM generator config — `tom-spec-object-model`

The SOM (specification object model) generator reads a single top-level
`tom-spec-object-model` block out of `tom_specs_clitool`'s YAML config. The
parser ([`SpecObjectModelConfig`](../lib/src/spec_object_model_config.dart))
turns that block into a typed config: which languages to generate, where each
generated `tom_som_<slug>_<label>` project lands, the version label, and which
document roots to generate.

## Block shape

```yaml
tom-spec-object-model:
  version-label: v0            # optional, default "v0" — suffix on tom_som_<slug>_<label>
  output-base: tom_ai/ai_build # optional, default "."  — base for default output roots
  document-roots:              # optional — absent/empty ⇒ generate ALL 13 document roots
    - ProjectDefinition
    - CsCurrentSituation
  languages:                   # required, non-empty
    - dart                     # short form: default output root
    - language: java           # map form: explicit output override
      output: custom/java/tom_som_java
    - c++                      # alias-aware; resolves to slug "cpp"
```

## Keys

| Key | Type | Default | Meaning |
| --- | --- | --- | --- |
| `version-label` | String | `v0` | Version suffix on generated project names (`_v0`, `_v1`, …). |
| `output-base` | String | `.` | Base dir for **default** per-language output roots. |
| `document-roots` | List\<String\> | *all 13 roots* | Document root type names to generate; empty/absent means every root. |
| `languages` | List | *(required)* | Generation targets, in order. Each entry is a **token string** or a `{language, output}` **map**. |

### Languages

Tokens are case-insensitive and alias-aware. Each language has a package-safe
**slug** used in the generated project name `tom_som_<slug>_<label>`:

| Language | Slug | Accepted tokens |
| --- | --- | --- |
| Dart | `dart` | `dart` |
| Java | `java` | `java` |
| JavaScript | `javascript` | `javascript`, `js` |
| TypeScript | `typescript` | `typescript`, `ts` |
| Go | `go` | `go`, `golang` |
| Rust | `rust` | `rust`, `rs` |
| C | `c` | `c` |
| C++ | `cpp` | `c++`, `cpp`, `cxx` |
| Python | `python` | `python`, `py` |

### Output roots

- **Override:** the map form's `output:` is used verbatim.
- **Default:** `<output-base>/tom_som_<slug>_<version-label>` (e.g. `c++` with
  `output-base: gen` and `version-label: v0` ⇒ `gen/tom_som_cpp_v0`).

## Rejections

The parser raises `SpecObjectModelConfigException` for: an empty/missing
`languages` list, an unknown language token, a duplicate language (including one
reached via an alias, e.g. `javascript` + `js`), a wrong-typed value, a
non-string `document-roots` entry, and (for `fromYaml`) a document that is not a
mapping or lacks the `tom-spec-object-model` block.

## API

- `SpecObjectModelConfig.fromMap(Map)` — pure parser over an already-decoded block.
- `SpecObjectModelConfig.fromYaml(String)` — loads a full YAML document and
  extracts the `tom-spec-object-model` block first.
- `config.targetFor(SomLanguage)` / `config.defaultOutputRootFor(SomLanguage)` /
  `config.generatesAllRoots`.
