/// The Phase-4 **specification extract generator** — the machine half of
/// CodeSpecs production (`codespecs_mapping.md` §1.1.1).
///
/// Phase 4 runs in two passes. This surface is the first: for each CodeSpecs
/// area it collects everything in a filled specification document that
/// `@CodeSpecKind` routes to that area, **verbatim and with provenance**, so
/// the second pass — an authoring agent, one prompt per authoring step — writes
/// against a bounded extract rather than against a 652-section document.
///
/// The boundary between the two passes is a rule, not a preference. This
/// generator may **copy and index**; it may not summarise, rephrase, compose a
/// sentence out of field values, or choose a name — the prohibitions of
/// `codespecs_derivation_contract.md` §2.8 **C1**, which bind the extract
/// generator word for word. The consequence is checkable rather than trusted:
/// every [CodeSpecsExtractEntry.value] is a string the document stores, byte
/// for byte, and the conformance corpus asserts it.
///
/// Three things follow from that and shape the API:
///
///   * **Routing is by the three verdicts** (`codespecs_mapping.md` §8.3) — a
///     class carries `@CodeSpecKind` (feeds code), sits under a
///     `@FollowUpKind` root (feeds a non-generation process), or carries
///     `@NoArtifact` (feeds nothing). The trio is exhaustive by construction,
///     so a class carrying none of them is not "skipped": it is a
///     [CodeSpecsExtractError], the `ROUTE-TOTAL` invariant
///     (`tom_specs_model_rules.md` §10.2) failing loudly at the one place that
///     depends on it.
///   * **`@CodeSpecKind` is list-valued** (`codespecs_mapping.md` §9.1), and extracts are **not**
///     deduplicated across areas: a section feeding three areas appears, whole,
///     in three extracts. Each area's prompt must be self-sufficient.
///   * **Every entry carries its provenance** — section id, class, field, the
///     routing marker that put it here and where that marker was declared — so
///     the `@DocSpec`/`DocRef` back-links (`codespecs_mapping.md` §9.3) can be written from the
///     extract alone.
///
/// The area catalogue ([CodeSpecsAreaCatalog]) is an **input**, not a table
/// baked into the runtime: it is the machine-readable form of
/// `codespecs_mapping.md` §4.1 (the parts catalogue), `codespecs_mapping.md` §4.4.3 (the emission
/// slices) and `codespecs_mapping.md` §4.4.6 (the authoring steps), authored once and read by all nine
/// runtimes. Carrying it beside the content is what stops an agent having to
/// open the mapping document to find out what `CE-FM` means.
library;

import 'spec_document.dart';
import 'spec_model.dart';
import 'spec_paths.dart';
import 'spec_reflection.dart';

/// The version of the emitted extract artifact's on-disk shape. Bumped when
/// the YAML or Markdown layout changes in a way a reader could notice.
///
/// 2: entries carry `headline` — the enclosing section instance's headline,
/// copy-only (stored headline, else the `@Headline` type default, else null).
///
/// 3: entries carry `instanceId` — the nearest enclosing list-item instance's
/// **stored** section id (the `<!--[…]-->` id the document serializes, AA1),
/// copy-only; null when no enclosing instance stores one. The render-time
/// positional default (`CARD-2`) is derived, never stored, so it is never
/// carried — that would be the composition C1 forbids.
const int kCodeSpecsExtractFormat = 3;

/// The annotation names of the three routing verdicts (`codespecs_mapping.md`
/// §8.3). All three ride the generic annotation bag in every SOM runtime
/// (`codespecs_mapping.md` §8.4), so they are read by name rather than through a meta slot.
const String kCodeSpecKindAnnotation = 'CodeSpecKind';

/// See [kCodeSpecKindAnnotation].
const String kFollowUpKindAnnotation = 'FollowUpKind';

/// See [kCodeSpecKindAnnotation].
const String kNoArtifactAnnotation = 'NoArtifact';

/// Which of the three `codespecs_mapping.md` §8.3 verdicts a class carries.
enum CodeSpecsRoutingVerdict {
  /// `@CodeSpecKind(List<CodeSpecPart>)` — the section's content is shown to
  /// every named area's extract.
  feedsCode,

  /// `@FollowUpKind(List<FollowUpProcess>)` — the section is delivered by a
  /// non-generation process. The whole subtree is excluded from every extract.
  feedsProcess,

  /// `@NoArtifact(NoArtifactReason)` — the section deliberately produces no
  /// downstream artifact. Its own leaves contribute nothing; its children are
  /// still routed individually (that is what `container` means).
  feedsNothing,

  /// A `@Document` root carrying no verdict. Structurally exempt from
  /// `ROUTE-TOTAL`: a root is the document, not a section of it.
  documentRoot,

  /// No verdict, and not a `@Document` root — a `ROUTE-TOTAL` violation, and
  /// the reason [CodeSpecsExtractor.extractAll] throws.
  unrouted,
}

/// The verdict recorded for one class node of the walked document, with the
/// provenance of the marker that decided it.
class CodeSpecsRouting {
  /// The document path of the node the verdict was computed for.
  final String path;

  /// The model class at [path].
  final String className;

  /// Which verdict the class carries.
  final CodeSpecsRoutingVerdict verdict;

  /// The verdict's payload, verbatim from the annotation: the `CodeSpecPart.*`
  /// values for [CodeSpecsRoutingVerdict.feedsCode], the `FollowUpProcess.*`
  /// values for [CodeSpecsRoutingVerdict.feedsProcess], the single
  /// `NoArtifactReason.*` for [CodeSpecsRoutingVerdict.feedsNothing], and empty
  /// for the two verdicts that have no marker.
  final List<String> values;

  /// The marker's optional `note`, verbatim; `null` when it carries none.
  final String? note;

  /// Where the marker was declared — the class name, or `Class.field` when a
  /// field-level `@CodeSpecKind` overrode its class. Empty when there is no
  /// marker.
  final String declaredAt;

  /// Records the verdict computed for one node. [path], [className] and
  /// [verdict] are required because a routing row exists precisely to say
  /// *which* node got *which* verdict. The three provenance fields default to
  /// empty because two of the five verdicts — `documentRoot` and `unrouted` —
  /// have no marker to take them from, and most markers carry no `note`.
  const CodeSpecsRouting({
    required this.path,
    required this.className,
    required this.verdict,
    this.values = const [],
    this.note,
    this.declaredAt = '',
  });

  @override
  String toString() => 'CodeSpecsRouting($path, $className, ${verdict.name})';
}

/// One extract entry: a single value the specification document stores, with
/// everything needed to trace it back (`codespecs_mapping.md` §1.1.1, "Entry").
class CodeSpecsExtractEntry {
  /// The `CE-*` code of the area this entry was collected for.
  final String areaCode;

  /// The section id of the leaf the value sits on (`@SectionId`, else the model
  /// field name).
  final String sectionId;

  /// The headline of the enclosing section instance the value belongs to —
  /// the document's stored headline at the class node's path (YRD3), else the
  /// class's `@Headline(text)` default (YRD4); `null` when neither exists.
  ///
  /// Copy-only, like [value]: both sources are source text, so carrying it is
  /// within C1 — and it is what gives naming rule N1
  /// (`codespecs_derivation_contract.md` §2.1) a real source for derived
  /// holders, instead of the PascalCase-of-sectionId fallback. The one thing
  /// this field is **never** is a name derivation: when neither source exists
  /// it stays `null` rather than being composed.
  final String? headline;

  /// The document instance id of the enclosing section instance — the
  /// **stored** section id (AA1, the `<!--[…]-->` id the document serializes)
  /// of the nearest enclosing list item that carries one, walking outward;
  /// `null` when none does.
  ///
  /// Copy-only, like [value] and [headline]: a stored id is a string the
  /// document holds, so carrying it is within C1. The render-time positional
  /// default (`CARD-2`) is derived rather than stored and is **never**
  /// carried. This field is auxiliary trace data — the back-link vocabulary of
  /// `codespecs_derivation_contract.md` §2.5 stays the extract token
  /// ([sectionId]); see `codespecs_mapping.md` §9.3.
  final String? instanceId;

  /// The document path of the leaf — the source location.
  final String path;

  /// The model class declaring the leaf.
  final String className;

  /// The model field name of the leaf.
  final String fieldName;

  /// The form-field name when the value is one field of a `@Form` section;
  /// `null` for a content, enum, scalar or scalar-list leaf.
  final String? formField;

  /// The `CodeSpecPart.*` value that routed this entry here, verbatim.
  final String routedBy;

  /// Where that `@CodeSpecKind` was declared — the class name, or
  /// `Class.field` for a field-level override.
  final String routedAt;

  /// The `@CodeSpecKind` `note`, verbatim; `null` when it carries none.
  final String? routingNote;

  /// The stored value, **verbatim**. Never assembled, reformatted or trimmed.
  final String value;

  /// The required arguments are what an entry cannot be traced or trusted
  /// without: the area it was collected for, the section id and path it came
  /// from, the declaring class and field, the `CodeSpecPart` that routed it
  /// plus where that marker was declared, and the verbatim [value].
  ///
  /// The four optional ones are absent-by-nature, not defaulted-away:
  /// [headline] and [instanceId] stay null when the document stores neither,
  /// [formField] exists only for a `@Form` field, [routingNote] only when the
  /// marker carries one. None is ever synthesised to fill the gap — composing
  /// a value is exactly what C1 (`codespecs_derivation_contract.md` §2.8)
  /// forbids the extract generator.
  const CodeSpecsExtractEntry({
    required this.areaCode,
    required this.sectionId,
    required this.path,
    required this.className,
    required this.fieldName,
    required this.routedBy,
    required this.routedAt,
    required this.value,
    this.headline,
    this.instanceId,
    this.formField,
    this.routingNote,
  });

  @override
  String toString() => 'CodeSpecsExtractEntry($areaCode, $path)';
}

/// One emission slice of `codespecs_mapping.md` §4.4.3.
class CodeSpecsSlice {
  /// The slice's number, 1–7.
  final int number;

  /// The slice's name as `codespecs_mapping.md` §4.4.3 gives it.
  final String title;

  /// The `codespecs_mapping.md` §4.2 project the slice emits into.
  final String project;

  /// The slices this one may cite — `codespecs_mapping.md` §4.4.3's across-slice edges. Transitively
  /// closed by [CodeSpecsAreaCatalog.citableAreaCodes].
  final List<int> cites;

  /// [number], [title] and [project] are required: a slice that did not name
  /// the `codespecs_mapping.md` §4.2 project it emits into would not say where
  /// its code lands, which is what the emission order exists to decide.
  /// [cites] defaults to empty for slice 1, which cites nothing — and holds
  /// only the *direct* edges. The transitive closure is computed by
  /// [CodeSpecsAreaCatalog.citableAreaCodes]; pre-expanding it here would make
  /// the authored graph disagree with the derived one.
  const CodeSpecsSlice({
    required this.number,
    required this.title,
    required this.project,
    this.cites = const [],
  });

  /// Reads one slice from the authored catalogue. `number` is the only key
  /// with no usable default — it throws when absent or non-numeric, because a
  /// slice without its ordinal cannot be placed in the emission order at all.
  /// `title`, `project` and `cites` fall back to empty, so a half-authored
  /// catalogue loads and fails later against the specific missing fact rather
  /// than refusing the whole file.
  factory CodeSpecsSlice.fromJson(Map<String, dynamic> j) => CodeSpecsSlice(
        number: (j['number'] as num).toInt(),
        title: j['title'] as String? ?? '',
        project: j['project'] as String? ?? '',
        cites: _intList(j['cites']),
      );
}

/// One row of the `codespecs_mapping.md` §4.1 parts catalogue, plus the `codespecs_mapping.md` §4.4.3
/// slice and `codespecs_mapping.md` §4.4.6 authoring steps that place it. This is the **per-area
/// context** an extract carries beside its content.
class CodeSpecsArea {
  /// The permanent registry key — `CE-FM`, `CE-API`. Never reused, never
  /// renamed, and the extract file's name.
  final String code;

  /// The `codespecs_mapping.md` §4.1 canonical id — the PascalCase noun (`Form`, `ServerApi`).
  final String canonicalId;

  /// The `CodeSpecPart` value, camelCase and **without** the enum prefix
  /// (`form`, `serverApi`).
  final String part;

  /// The `Cs*` annotation names of the `codespecs_mapping.md` §4.1 row.
  final List<String> annotations;

  /// The `codespecs_mapping.md` §4.1 "Built on" cell, verbatim.
  final String builtOn;

  /// Where the area's spec-authorable attribute surface is stated — a
  /// subsection of `codespecs_mapping.md` §5.
  final String attributeSurface;

  /// The `codespecs_mapping.md` §4.4.3 slice(s) the area's emission units sit in. More than one when
  /// the area is split by locus.
  final List<int> slices;

  /// The `codespecs_mapping.md` §4.4.6 authoring step(s) that write the area.
  final List<int> authoringSteps;

  /// Whether the part is active. A deferred part (`codespecs_mapping.md` §4.3) holds a reserved
  /// `CodeSpecPart` value but has no generated surface, so it gets no extract.
  final bool active;

  /// [code], [canonicalId] and [part] are required — they are the area's three
  /// identities (permanent registry key, PascalCase noun, `CodeSpecPart`
  /// value) and every consumer keys on one of them. The catalogue-row detail
  /// defaults to empty because a deferred area (`codespecs_mapping.md` §4.3)
  /// legitimately has no annotations, slice or authoring step yet. [active]
  /// defaults to `true`: an authored row gets an extract unless the catalogue
  /// explicitly says the part is not live.
  const CodeSpecsArea({
    required this.code,
    required this.canonicalId,
    required this.part,
    this.annotations = const [],
    this.builtOn = '',
    this.attributeSurface = '',
    this.slices = const [],
    this.authoringSteps = const [],
    this.active = true,
  });

  /// Reads one catalogue row. `code` and `part` are the only keys that throw
  /// when missing: the code names the extract file and the part is the string
  /// `@CodeSpecKind` values are matched against, so neither can be defaulted
  /// without silently producing an area nothing routes to. `active` defaults
  /// to `true`, matching the constructor — omission means live, not retired.
  factory CodeSpecsArea.fromJson(Map<String, dynamic> j) => CodeSpecsArea(
        code: j['code'] as String,
        canonicalId: j['canonicalId'] as String? ?? '',
        part: j['part'] as String,
        annotations: _stringList(j['annotations']),
        builtOn: j['builtOn'] as String? ?? '',
        attributeSurface: j['attributeSurface'] as String? ?? '',
        slices: _intList(j['slices']),
        authoringSteps: _intList(j['authoringSteps']),
        active: j['active'] as bool? ?? true,
      );

  /// The fully-qualified `@CodeSpecKind` value — `CodeSpecPart.form`.
  String get kindValue => 'CodeSpecPart.$part';

  @override
  String toString() => 'CodeSpecsArea($code)';
}

/// The machine-readable form of `codespecs_mapping.md` §4.1 + §4.4.3 + §4.4.6.
///
/// Authored once, read by all nine runtimes. It is an input rather than a baked
/// table because the catalogue is the mapping document's content: a copy per
/// runtime would be nine things to keep current, and the one thing this quest
/// has learned three times is that a vocabulary duplicated nine ways can be
/// wrong in agreement.
class CodeSpecsAreaCatalog {
  /// Where the catalogue was transcribed from, for the extract header.
  final String source;

  /// The `codespecs_mapping.md` §4.4.3 slices, in emission order.
  final List<CodeSpecsSlice> slices;

  /// The `codespecs_mapping.md` §4.1 areas, in catalogue order. Catalogue order is the tie-break
  /// `codespecs_mapping.md` §4.4.6 rule 2 uses, so it is load-bearing rather than cosmetic.
  final List<CodeSpecsArea> areas;

  /// Every argument defaults to empty, so an empty catalogue is a legal value
  /// rather than an error — a runtime can be constructed before its catalogue
  /// file has been read. The order of [areas] is load-bearing input, not
  /// presentation: catalogue order is the tie-break `codespecs_mapping.md`
  /// §4.4.6 rule 2 applies, so a caller must pass the authored sequence
  /// unsorted.
  const CodeSpecsAreaCatalog({
    this.source = '',
    this.slices = const [],
    this.areas = const [],
  });

  /// Loads the authored catalogue as transcribed from `codespecs_mapping.md`
  /// §4.1 / §4.4.3 / §4.4.6. Absent `slices` / `areas` keys yield empty lists,
  /// but a malformed row inside them propagates that row's own failure: the
  /// catalogue is authored input shared by all nine runtimes, and a row that
  /// half-parsed would put a silently incomplete vocabulary into every
  /// extract. Element order is preserved verbatim (see [areas]).
  factory CodeSpecsAreaCatalog.fromJson(Map<String, dynamic> j) =>
      CodeSpecsAreaCatalog(
        source: j['source'] as String? ?? '',
        slices: ((j['slices'] as List?) ?? const [])
            .map((e) => CodeSpecsSlice.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        areas: ((j['areas'] as List?) ?? const [])
            .map((e) => CodeSpecsArea.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  /// The active areas, in catalogue order — one extract each.
  List<CodeSpecsArea> get activeAreas =>
      areas.where((a) => a.active).toList(growable: false);

  /// The area with this `CE-*` code, or `null`.
  CodeSpecsArea? byCode(String code) {
    for (final a in areas) {
      if (a.code == code) return a;
    }
    return null;
  }

  /// The area a `@CodeSpecKind` value names, or `null`. Accepts both the bare
  /// value (`form`) and the qualified one (`CodeSpecPart.form`), because the
  /// meta carries the qualified spelling and callers reach for the bare one.
  CodeSpecsArea? byPart(String value) {
    final bare = value.startsWith('CodeSpecPart.')
        ? value.substring('CodeSpecPart.'.length)
        : value;
    for (final a in areas) {
      if (a.part == bare) return a;
    }
    return null;
  }

  /// The slice numbered [number], or `null`.
  CodeSpecsSlice? sliceNumbered(int number) {
    for (final s in slices) {
      if (s.number == number) return s;
    }
    return null;
  }

  /// The `codespecs_mapping.md` §4.2 projects [area]'s code lands in, in slice order.
  ///
  /// Derived from the area's slices rather than authored on the area: `codespecs_mapping.md` §4.4.3
  /// already fixes one project per slice, so a per-area project column would be
  /// a second place for the same fact to be stated — and the areas that would
  /// need it are exactly the locus-split ones, where getting it wrong is
  /// easiest.
  List<String> projectsFor(CodeSpecsArea area) {
    final out = <String>[];
    for (final n in area.slices) {
      final project = sliceNumbered(n)?.project;
      if (project == null || project.isEmpty || out.contains(project)) continue;
      out.add(project);
    }
    return out;
  }

  /// The area codes [area] may cite — every other active area whose emission
  /// units sit in a slice [area]'s slices reach, following `codespecs_mapping.md` §4.4.3's edges
  /// transitively. Within-slice citation is legal, so an area's own slices are
  /// part of the reachable set; the area itself is excluded.
  ///
  /// Derived rather than authored: a hand-kept per-area citation list is a
  /// second source of truth for something the slice graph already decides.
  List<String> citableAreaCodes(CodeSpecsArea area) {
    final reachable = <int>{};
    final stack = <int>[...area.slices];
    while (stack.isNotEmpty) {
      final n = stack.removeLast();
      if (!reachable.add(n)) continue;
      final slice = sliceNumbered(n);
      if (slice == null) continue;
      stack.addAll(slice.cites);
    }
    final out = <String>[];
    for (final a in areas) {
      if (!a.active || a.code == area.code) continue;
      for (final s in a.slices) {
        if (reachable.contains(s)) {
          out.add(a.code);
          break;
        }
      }
    }
    return out;
  }
}

/// One area's extract: the area's context plus every routed entry, in SOM
/// document order.
class CodeSpecsExtract {
  /// The area this extract is for.
  final CodeSpecsArea area;

  /// The `codespecs_mapping.md` §4.1/§4.4.3 source the catalogue names.
  final String catalogSource;

  /// The section segment of the document root the entries were collected from.
  final String documentRoot;

  /// The area codes this area may cite (`codespecs_mapping.md` §4.4.3), for the agent's prompt.
  final List<String> citableParts;

  /// The `codespecs_mapping.md` §4.2 projects the area's code lands in (`codespecs_mapping.md` §4.4.3, via the slices).
  final List<String> projects;

  /// The routed entries, in SOM document order.
  final List<CodeSpecsExtractEntry> entries;

  /// [area] and [documentRoot] are the two facts that make an extract
  /// identifiable — which area it serves, and which document root it was
  /// walked from — so neither has a default. Everything else defaults to empty
  /// so an area with no routed content still yields a well-formed, empty
  /// extract: an empty file honestly reports that the specification said
  /// nothing for that area, whereas a missing file is indistinguishable from a
  /// run that never covered it (`codespecs_prompt.md` §6.4).
  const CodeSpecsExtract({
    required this.area,
    required this.documentRoot,
    this.catalogSource = '',
    this.citableParts = const [],
    this.projects = const [],
    this.entries = const [],
  });

  /// The extract's file name stem — `CE-FM.extract`.
  String get fileStem => '${area.code}.extract';

  /// The artifact of record (`codespecs_mapping.md` §1.1.1). Scalars are
  /// emitted as JSON strings, which are valid YAML 1.2 double-quoted scalars —
  /// so one escaping rule, identical in all nine runtimes, covers every value
  /// a specification can hold.
  String toYaml() {
    final b = StringBuffer();
    b.writeln('# ${area.code}.extract.yaml — generated by '
        'spec_codespecs_extract. Do not edit.');
    b.writeln('extract:');
    b.writeln('  formatVersion: $kCodeSpecsExtractFormat');
    b.writeln('  catalogSource: ${_yamlString(catalogSource)}');
    b.writeln('  area:');
    b.writeln('    code: ${_yamlString(area.code)}');
    b.writeln('    canonicalId: ${_yamlString(area.canonicalId)}');
    b.writeln('    part: ${_yamlString(area.kindValue)}');
    b.writeln('    annotations: ${_yamlStringList(area.annotations)}');
    b.writeln('    builtOn: ${_yamlString(area.builtOn)}');
    b.writeln('    attributeSurface: ${_yamlString(area.attributeSurface)}');
    b.writeln('    slices: ${_yamlIntList(area.slices)}');
    b.writeln('    authoringSteps: ${_yamlIntList(area.authoringSteps)}');
    b.writeln('    projects: ${_yamlStringList(projects)}');
    b.writeln('    citableParts: ${_yamlStringList(citableParts)}');
    b.writeln('  document:');
    b.writeln('    root: ${_yamlString(documentRoot)}');
    b.writeln('    entryCount: ${entries.length}');
    if (entries.isEmpty) {
      b.writeln('  entries: []');
      return b.toString();
    }
    b.writeln('  entries:');
    for (final e in entries) {
      b.writeln('    - sectionId: ${_yamlString(e.sectionId)}');
      b.writeln('      headline: ${_yamlNullableString(e.headline)}');
      b.writeln('      instanceId: ${_yamlNullableString(e.instanceId)}');
      b.writeln('      path: ${_yamlString(e.path)}');
      b.writeln('      className: ${_yamlString(e.className)}');
      b.writeln('      fieldName: ${_yamlString(e.fieldName)}');
      b.writeln('      formField: ${_yamlNullableString(e.formField)}');
      b.writeln('      routedBy: ${_yamlString(e.routedBy)}');
      b.writeln('      routedAt: ${_yamlString(e.routedAt)}');
      b.writeln('      routingNote: ${_yamlNullableString(e.routingNote)}');
      b.writeln('      value: ${_yamlString(e.value)}');
    }
    return b.toString();
  }

  /// The rendered view. Regenerated from the YAML's own data — nothing reads
  /// the Markdown as input — and exists because the agent reads it far better
  /// than it reads YAML.
  String toMarkdown() {
    final b = StringBuffer();
    b.writeln('# ${area.code} — ${area.canonicalId}');
    b.writeln();
    b.writeln('Generated by `spec_codespecs_extract` from the specification '
        'document rooted at `$documentRoot`.');
    b.writeln('`${area.code}.extract.yaml` beside this file is the artifact of '
        'record; this is a view of it.');
    b.writeln();
    b.writeln('## Area');
    b.writeln();
    b.writeln('| | |');
    b.writeln('|---|---|');
    b.writeln('| CE code | `${area.code}` |');
    b.writeln('| Canonical id | `${area.canonicalId}` |');
    b.writeln('| `@CodeSpecKind` value | `${area.kindValue}` |');
    b.writeln('| `Cs*` annotations | ${_mdCodeList(area.annotations)} |');
    b.writeln('| Built on | ${_mdCell(area.builtOn)} |');
    b.writeln('| Attribute surface | ${_mdCell(area.attributeSurface)} |');
    b.writeln('| Slice(s) | ${_mdIntList(area.slices)} |');
    b.writeln('| Authoring step(s) | ${_mdIntList(area.authoringSteps)} |');
    b.writeln('| Project(s) | ${_mdCodeList(projects)} |');
    b.writeln('| May cite | ${_mdCodeList(citableParts)} |');
    b.writeln('| Catalogue source | ${_mdCell(catalogSource)} |');
    b.writeln();
    b.writeln('## Entries (${entries.length})');
    b.writeln();
    if (entries.isEmpty) {
      b.writeln('_No section of this document is routed to '
          '`${area.kindValue}`._');
      return b.toString();
    }
    var n = 0;
    for (final e in entries) {
      n++;
      final member =
          e.formField == null ? e.fieldName : '${e.fieldName}.${e.formField}';
      b.writeln('### $n. `${e.sectionId}` — `${e.className}.$member`');
      b.writeln();
      if (e.headline != null) {
        b.writeln('- headline: ${_mdCell(e.headline!)}');
      }
      if (e.instanceId != null) {
        b.writeln('- instanceId: `${e.instanceId}`');
      }
      b.writeln('- path: `${e.path}`');
      b.writeln('- routed by: `${e.routedBy}` declared on `${e.routedAt}`');
      if (e.routingNote != null) {
        b.writeln('- routing note: ${_mdCell(e.routingNote!)}');
      }
      b.writeln();
      final fence = _fenceFor(e.value);
      b.writeln('$fence text');
      b.writeln(e.value);
      b.writeln(fence);
      b.writeln();
    }
    return b.toString();
  }
}

/// Thrown when the document cannot be extracted from at all.
///
/// Two causes: a section routed nowhere — `ROUTE-TOTAL`
/// (`tom_specs_model_rules.md` §10.2) failing — and a walk root that cannot be
/// resolved to exactly one (`codespecs_prompt.md` §5). Both are errors rather
/// than skips: a section routed nowhere is a section the agent writing that
/// area never sees, and a walk over the wrong root is every area empty. A
/// silent omission at this boundary is indistinguishable from a specification
/// that genuinely said nothing.
class CodeSpecsExtractError implements Exception {
  /// What went wrong, in one sentence.
  final String message;

  /// The document path of the offending node.
  final String path;

  /// The model class at [path].
  final String className;

  /// All three fields are required, so there is deliberately no way to raise
  /// an extraction failure that does not say where it happened. For the
  /// `ROUTE-TOTAL` cause a real node is at fault and both location fields are
  /// filled; for a root that cannot be resolved to exactly one there is no
  /// such node, and callers pass an empty [path] with the requested root type
  /// (or empty again, when the ambiguity is that several roots are populated)
  /// as [className].
  const CodeSpecsExtractError({
    required this.message,
    required this.path,
    required this.className,
  });

  @override
  String toString() => 'CodeSpecsExtractError: $message ($path, $className)';
}

/// Produces one [CodeSpecsExtract] per active area from a filled specification
/// document.
///
/// A Phase-4 run extracts from **one** specification document, so the walk has
/// exactly one root ([root], `codespecs_prompt.md` §5). The two ways to get
/// that wrong are both closed here rather than left to the caller: the walk
/// cannot union every `@Document` root, because there is no way to ask for
/// that; and naming a root the document never populates — the
/// `D13CodeSpecsProjection` mistake, whose `CGP/…` path space misses a
/// blueprint's `SBP/…` values and yields every area silently empty — is a
/// [CodeSpecsExtractError] rather than an empty result.
class CodeSpecsExtractor {
  /// The model describing the document's structure and carrying the routing
  /// verdicts.
  final SpecModel model;

  /// The filled specification document.
  final SpecDocument document;

  /// The area catalogue — `codespecs_mapping.md` §4.1/§4.4.3/§4.4.6.
  final CodeSpecsAreaCatalog catalog;

  /// The one `@Document` root this extractor walks.
  ///
  /// Resolved once, in the constructor, so [routings] and [extractAll] cannot
  /// disagree about what was walked.
  final SpecRoot root;

  final SpecReflection _reflection;

  /// Binds an extractor to a model / document / catalogue triple.
  ///
  /// [rootType] names the specification document's own root, by type name or
  /// by section id. Omitted, it defaults to the document's single **populated**
  /// root — the root under which the document holds any value — falling back to
  /// the model's only root when the document is empty, so an unfilled
  /// single-root model still reaches the routing walk.
  ///
  /// Throws [CodeSpecsExtractError] when the root cannot be resolved to exactly
  /// one: an unknown [rootType], a [rootType] holding no value while another
  /// root does, more than one populated root, or an empty document over a
  /// multi-root model.
  CodeSpecsExtractor({
    required this.model,
    required this.document,
    required this.catalog,
    String? rootType,
  })  : root = _resolveRoot(model, document, rootType),
        _reflection = SpecReflection(model);

  static String _segment(SpecRoot r) => r.sectionId ?? r.type;

  static SpecRoot _resolveRoot(
      SpecModel model, SpecDocument document, String? rootType) {
    final populated = [
      for (final r in model.roots)
        if (document.hasValuesUnder(_segment(r))) r,
    ];
    final names = model.roots.map((r) => r.type).join(', ');
    if (rootType != null && rootType.isNotEmpty) {
      for (final r in model.roots) {
        if (r.type != rootType && _segment(r) != rootType) continue;
        if (populated.isNotEmpty && !populated.contains(r)) {
          throw CodeSpecsExtractError(
            message: 'root "$rootType" holds no value in this document, but '
                '${populated.map((p) => p.type).join(', ')} does — every '
                'extract would come out empty (codespecs_prompt.md §5)',
            path: _segment(r),
            className: r.type,
          );
        }
        return r;
      }
      throw CodeSpecsExtractError(
        message: 'no document root with type or section id "$rootType" '
            '(have: $names)',
        path: '',
        className: rootType,
      );
    }
    if (populated.length == 1) return populated.single;
    if (populated.isEmpty) {
      if (model.roots.length == 1) return model.roots.single;
      throw CodeSpecsExtractError(
        message: 'document has no populated root to extract from; pass '
            'rootType to choose one (have: $names)',
        path: '',
        className: '',
      );
    }
    throw CodeSpecsExtractError(
      message: 'document has ${populated.length} populated roots '
          '(${populated.map((r) => r.type).join(', ')}); pass rootType to '
          'choose one',
      path: '',
      className: '',
    );
  }

  /// The verdict of every class node the walk reaches, in document order.
  ///
  /// Computed by the same walk [extractAll] uses, so "what was routed where"
  /// and "what landed in which extract" cannot disagree. Unlike [extractAll]
  /// this does **not** throw on an unrouted class — it reports it, which is
  /// what a diagnostic is for.
  List<CodeSpecsRouting> routings() {
    final out = <CodeSpecsRouting>[];
    _walkAll(routings: out, entries: null, strict: false);
    return out;
  }

  /// One extract per active area, in catalogue order.
  ///
  /// Throws [CodeSpecsExtractError] on the first class the walk reaches that
  /// carries none of the three verdicts.
  List<CodeSpecsExtract> extractAll() {
    final entries = <CodeSpecsExtractEntry>[];
    _walkAll(routings: null, entries: entries, strict: true);
    final rootSegment = _reflection.rootSegment(root);
    final out = <CodeSpecsExtract>[];
    for (final area in catalog.activeAreas) {
      out.add(CodeSpecsExtract(
        area: area,
        catalogSource: catalog.source,
        documentRoot: rootSegment,
        citableParts: catalog.citableAreaCodes(area),
        projects: catalog.projectsFor(area),
        entries: entries
            .where((e) => e.areaCode == area.code)
            .toList(growable: false),
      ));
    }
    return out;
  }

  /// The single extract for [areaCode], or `null` when the catalogue holds no
  /// such active area.
  CodeSpecsExtract? extractFor(String areaCode) {
    for (final e in extractAll()) {
      if (e.area.code == areaCode) return e;
    }
    return null;
  }

  // --- the walk ------------------------------------------------------------

  void _walkAll({
    required List<CodeSpecsRouting>? routings,
    required List<CodeSpecsExtractEntry>? entries,
    required bool strict,
  }) {
    _walk(
      path: _reflection.rootSegment(root),
      cls: model.classNamed(root.type),
      ancestorTypes: {root.type},
      enclosingInstanceId: null,
      routings: routings,
      entries: entries,
      strict: strict,
    );
  }

  void _walk({
    required String path,
    required SpecClass? cls,
    required Set<String> ancestorTypes,
    required String? enclosingInstanceId,
    required List<CodeSpecsRouting>? routings,
    required List<CodeSpecsExtractEntry>? entries,
    required bool strict,
  }) {
    if (cls == null) return;
    final routing = _verdictOf(cls, path);
    routings?.add(routing);

    switch (routing.verdict) {
      case CodeSpecsRoutingVerdict.feedsProcess:
        return; // the whole subtree is delivered by a non-generation process
      case CodeSpecsRoutingVerdict.unrouted:
        if (strict) {
          throw CodeSpecsExtractError(
            message: 'section carries none of the three routing verdicts '
                '(@CodeSpecKind / @FollowUpKind / @NoArtifact) — '
                'tom_specs_model_rules.md §10.2 ROUTE-TOTAL',
            path: path,
            className: cls.name,
          );
        }
      case CodeSpecsRoutingVerdict.feedsCode:
      case CodeSpecsRoutingVerdict.feedsNothing:
      case CodeSpecsRoutingVerdict.documentRoot:
        break;
    }

    final classRouting = routing.verdict == CodeSpecsRoutingVerdict.feedsCode
        ? routing
        : null;

    // The enclosing instance's headline, resolved once per class node with the
    // model's own render precedence (stored YRD3 > `@Headline` default YRD4)
    // and copied onto every entry emitted below it. Copying is all this is —
    // when neither source exists the entries carry `null`, never a derivation.
    final headline = document.headline(path) ?? cls.headline;

    // The nearest enclosing list-item instance's **stored** section id (AA1),
    // resolved once per class node: the document's stored id when this node is
    // a list item carrying one, else whatever the walk inherited. Copy-only —
    // the positional render default (`CARD-2`) is derived, never stored, so an
    // id-less instance yields `null` rather than a composed id.
    final instanceId = document.itemSectionId(path) ?? enclosingInstanceId;

    for (final field in cls.fields) {
      final fieldPath = specPathJoin(path, _reflection.fieldSegment(field));
      final fieldRouting = _fieldRouting(cls, field) ?? classRouting;

      switch (field.kind) {
        case SpecFieldKind.content:
        case SpecFieldKind.enumValue:
        case SpecFieldKind.scalar:
          _emitValue(
            entries: entries,
            routing: fieldRouting,
            cls: cls,
            field: field,
            path: fieldPath,
            formField: null,
            headline: headline,
            instanceId: instanceId,
            value: document.content(fieldPath),
          );
        case SpecFieldKind.form:
          for (final ff in field.formFields) {
            _emitValue(
              entries: entries,
              routing: fieldRouting,
              cls: cls,
              field: field,
              path: fieldPath,
              formField: ff.name,
              headline: headline,
              instanceId: instanceId,
              value: document.formField(fieldPath, ff.name),
            );
          }
        case SpecFieldKind.list:
          for (final itemPath in document.listItems(fieldPath)) {
            if (field.elementIsComplex &&
                field.elementType != null &&
                !ancestorTypes.contains(field.elementType)) {
              _walk(
                path: itemPath,
                cls: model.classNamed(field.elementType),
                ancestorTypes: {...ancestorTypes, field.elementType!},
                enclosingInstanceId: instanceId,
                routings: routings,
                entries: entries,
                strict: strict,
              );
            } else {
              // A scalar item is itself an instance of the list: its own
              // stored id (when the document carries one) is the most precise
              // enclosing-instance id its entry can carry.
              _emitValue(
                entries: entries,
                routing: fieldRouting,
                cls: cls,
                field: field,
                path: itemPath,
                formField: null,
                headline: headline,
                instanceId: document.itemSectionId(itemPath) ?? instanceId,
                value: document.content(itemPath),
              );
            }
          }
        case SpecFieldKind.complex:
        case SpecFieldKind.section:
          if (field.type != null && !ancestorTypes.contains(field.type)) {
            _walk(
              path: fieldPath,
              cls: model.classNamed(field.type),
              ancestorTypes: {...ancestorTypes, field.type!},
              enclosingInstanceId: instanceId,
              routings: routings,
              entries: entries,
              strict: strict,
            );
          }
      }
    }
  }

  /// Appends one entry **per area the routing names** — never deduplicated,
  /// because each area's prompt must be self-sufficient (`codespecs_mapping.md` §1.1.1).
  void _emitValue({
    required List<CodeSpecsExtractEntry>? entries,
    required CodeSpecsRouting? routing,
    required SpecClass cls,
    required SpecField field,
    required String path,
    required String? formField,
    required String? headline,
    required String? instanceId,
    required String? value,
  }) {
    if (entries == null || routing == null) return;
    if (value == null || value.isEmpty) return;
    for (final kind in routing.values) {
      final area = catalog.byPart(kind);
      if (area == null || !area.active) continue;
      entries.add(CodeSpecsExtractEntry(
        areaCode: area.code,
        sectionId: _reflection.fieldSegment(field),
        path: path,
        className: cls.name,
        fieldName: field.name,
        formField: formField,
        headline: headline,
        instanceId: instanceId,
        routedBy: area.kindValue,
        routedAt: routing.declaredAt,
        routingNote: routing.note,
        value: value,
      ));
    }
  }

  // --- verdict resolution --------------------------------------------------

  /// The verdict [cls] carries. The three markers are mutually exclusive
  /// (`KIND-EXCLUSIVE`), so the order they are tested in is a readability
  /// choice rather than a precedence rule.
  ///
  /// Read through the model's own [AnnotatedSpecNode] accessors rather than off
  /// the raw annotation bag: they already know that `@CodeSpecKind`'s list
  /// argument is `kinds` while `@FollowUpKind`'s is `processes`, and they strip
  /// the enum prefix, so the codes here are bare whatever spelling the meta
  /// chose. Two readers of the same annotations would be two chances to
  /// disagree.
  CodeSpecsRouting _verdictOf(SpecClass cls, String path) {
    final code = cls.codeSpecKind;
    if (code != null) {
      return CodeSpecsRouting(
        path: path,
        className: cls.name,
        verdict: CodeSpecsRoutingVerdict.feedsCode,
        values: code.kinds,
        note: code.note,
        declaredAt: cls.name,
      );
    }
    final followUp = cls.followUpKind;
    if (followUp != null) {
      return CodeSpecsRouting(
        path: path,
        className: cls.name,
        verdict: CodeSpecsRoutingVerdict.feedsProcess,
        values: followUp.kinds,
        note: followUp.note,
        declaredAt: cls.name,
      );
    }
    final none = cls.noArtifact;
    if (none != null) {
      return CodeSpecsRouting(
        path: path,
        className: cls.name,
        verdict: CodeSpecsRoutingVerdict.feedsNothing,
        values: [none.reason],
        note: none.note,
        declaredAt: cls.name,
      );
    }
    if (cls.hasAnnotation('Document')) {
      return CodeSpecsRouting(
        path: path,
        className: cls.name,
        verdict: CodeSpecsRoutingVerdict.documentRoot,
      );
    }
    return CodeSpecsRouting(
      path: path,
      className: cls.name,
      verdict: CodeSpecsRoutingVerdict.unrouted,
    );
  }

  /// A field-level `@CodeSpecKind`, which overrides its class's routing for
  /// that field alone; `null` when the field carries none.
  CodeSpecsRouting? _fieldRouting(SpecClass cls, SpecField field) {
    final code = field.codeSpecKind;
    if (code == null) return null;
    return CodeSpecsRouting(
      path: '',
      className: cls.name,
      verdict: CodeSpecsRoutingVerdict.feedsCode,
      values: code.kinds,
      note: code.note,
      declaredAt: '${cls.name}.${field.name}',
    );
  }
}

// --- shared emission helpers ----------------------------------------------

List<String> _stringList(Object? raw) =>
    (raw as List?)?.map((e) => e.toString()).toList(growable: false) ??
    const <String>[];

List<int> _intList(Object? raw) =>
    (raw as List?)?.map((e) => (e as num).toInt()).toList(growable: false) ??
    const <int>[];

/// A JSON string literal, which is also a valid YAML 1.2 double-quoted scalar.
/// Hand-written rather than delegated to `dart:convert` so the eight ports have
/// one rule to transcribe rather than nine encoders to hope agree.
String _yamlString(String value) {
  final b = StringBuffer('"');
  for (final rune in value.runes) {
    switch (rune) {
      case 0x22:
        b.write(r'\"');
      case 0x5C:
        b.write(r'\\');
      case 0x08:
        b.write(r'\b');
      case 0x0C:
        b.write(r'\f');
      case 0x0A:
        b.write(r'\n');
      case 0x0D:
        b.write(r'\r');
      case 0x09:
        b.write(r'\t');
      default:
        if (rune < 0x20) {
          b.write('\\u${rune.toRadixString(16).padLeft(4, '0')}');
        } else {
          b.writeCharCode(rune);
        }
    }
  }
  b.write('"');
  return b.toString();
}

String _yamlNullableString(String? value) =>
    value == null ? 'null' : _yamlString(value);

String _yamlStringList(List<String> values) =>
    '[${values.map(_yamlString).join(', ')}]';

String _yamlIntList(List<int> values) => '[${values.join(', ')}]';

/// A markdown table cell: newlines folded to a space (a cell cannot hold one)
/// and `|` escaped. Applied only to catalogue prose, never to a stored value —
/// values go into fenced blocks, where they stay verbatim.
String _mdCell(String value) =>
    value.replaceAll('\n', ' ').replaceAll('|', r'\|');

String _mdCodeList(List<String> values) =>
    values.isEmpty ? '—' : values.map((v) => '`$v`').join(', ');

String _mdIntList(List<int> values) =>
    values.isEmpty ? '—' : values.join(', ');

/// The shortest backtick fence that cannot be closed by [value]'s own content.
String _fenceFor(String value) {
  var longest = 0;
  var run = 0;
  for (var i = 0; i < value.length; i++) {
    if (value.codeUnitAt(i) == 0x60) {
      run++;
      if (run > longest) longest = run;
    } else {
      run = 0;
    }
  }
  final width = longest >= 3 ? longest + 1 : 3;
  return '`' * width;
}
