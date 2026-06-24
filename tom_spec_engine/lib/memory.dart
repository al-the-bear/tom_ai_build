/// The **embeddable memory plane** of the engine (followup item 6, §9 / §10).
///
/// Where [`scripting.dart`](scripting.dart) re-exports the **memory-free**
/// scripting surface (so the editor links the engine without the memory plane),
/// this partial library re-exports the in-process Tom Brain memory surface the
/// editor needs to make the `memory` script scope and the **tier-2 vector**
/// recall live: the profile-isolated [SpecMemory] / [SpecDocumentMemory] over
/// the embeddable [SqliteTomBrainMemory] (with the bundled `vec0`), the
/// [MemoryScope] addressing, the tier-1 [StructuralLexicalIndex], the
/// [SpecRagGraph] section graph, the fused [SpecRecall], the read-only
/// `memory` script scope ([memoryScope] / [MemoryApi]), and the `mem_*`
/// [MemoryTools].
///
/// It deliberately does **not** re-export the **agent substrate** (`agent/` —
/// `BrainAgentSubstrate` / `BrainSessionEnvelope` / `AgentContext`): wiring the
/// live conversational substrate into the editor is a separate followup (items
/// 7–9). Keeping this façade to the memory plane lets the editor pull exactly
/// the in-process memory surface — and its `tom_brain_memory` (sqlite3 FFI /
/// `vec0`) dependency, which a Flutter **desktop** compile supports — without
/// dragging in the substrate.
///
/// [Vec] is re-exported (from `tom_brain_shared`) so a consumer can supply a
/// [SpecEmbedder] without importing the shared package directly.
library;

export 'package:tom_brain_shared/tom_brain_shared.dart' show Vec;

export 'src/index/structural_lexical_index.dart';
export 'src/memory/memory_scope.dart';
export 'src/memory/spec_memory.dart';
export 'src/memory/spec_rag_graph.dart';
export 'src/memory/spec_recall.dart';
export 'src/scope/memory_api.dart';
export 'src/scope/memory_scope.dart';
export 'src/tools/memory_tools.dart';
