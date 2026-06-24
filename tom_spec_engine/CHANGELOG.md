# Changelog

## 0.0.1 (unreleased)

- Tom Brain memory façade (`d4rt_and_llm_tools_plan.md` step 2): `lib/src/memory/`
  wraps the embeddable, profile-isolated, in-process Tom Brain memory plane
  (`SqliteTomBrainMemory` + bundled sqlite-vec vec0). `MemoryScope`
  (application/session/document addressing — the document is the store
  partition) + `SpecMemory`/`SpecDocumentMemory` expose embed / remember /
  recall. The store takes an injected `SpecEmbedder`; the LLM substrate is not
  pulled in. Adds `tom_brain_memory` + `tom_brain_shared` (path) dependencies.

## 0.0.1

- Phase-A scaffold (`d4rt_and_llm_tools_plan.md` step 1): project skeleton with
  the D4rt interpreter (`tom_d4rt`), the dcli source for the file facade
  (`tom_d4rt_dcli`), and the SOM document API (`tom_som_dart_runtime`,
  `tom_som_dart_v0`) wired as dependencies. Package metadata + smoke tests only.
