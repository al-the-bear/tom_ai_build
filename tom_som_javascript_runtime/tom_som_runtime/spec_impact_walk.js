'use strict';
/**
 * The impact walk — the starting table of a change's impact evaluation (the
 * change mode of the `tom_specs` process, Phase 0 step `impact`).
 *
 * For a specification it lists **every** section of **every** document root of
 * the model, filled or not, and roots the project never created as well: each
 * row with its section-id chain, its model class, whether it holds values, and
 * its CodeSpecs routing. The change analyst gives each row a verdict
 * (*affected*, *needed*, *unaffected*); a table built from the model rather
 * than from the document is what makes "nothing the SOM covers is missed"
 * checkable. Beside it, {@link specImpactLevel} records how far the project has
 * come (documents, extracts, IR, tests, code).
 *
 * Rows: one per class node (the root, each `complex` / `section` field, each
 * list item) and one per list (with its item count). An empty list of a class
 * element gets one **template** row `<list>/*` with the element's subtree
 * below it, so a section a new item would need shows its routing too. Value
 * leaves (content, form fields) are counted in their row, not rows of their
 * own. A class already on the branch is not entered again (the model is a
 * graph), exactly as the CodeSpecs routing walk cuts recursion. Below a
 * `@FollowUpKind` section every row carries that routing: the whole subtree is
 * delivered by the process, as the CodeSpecs extractor treats it.
 *
 * Pure: it reads a model and documents and writes nothing. Finding the files
 * and probing folders is the caller's (the clitool's `tomspecs :spec-impact-walk`,
 * the extension's `tomAi_specImpactWalk`). Port of `spec_impact_walk.ts` in
 * `tom_som_typescript_runtime` (and `spec_impact_walk.dart`), where the row and
 * level fields are documented one by one; pinned by `tom_som_conformance/corpus/impact_walk_cases.json`.
 */
const { CodeSpecsRoutingVerdict, codeSpecsClassRouting, codeSpecsFieldRouting } = require('./spec_codespecs_extract');
const { SpecDocument } = require('./spec_document');
const { SpecFieldKind } = require('./spec_model');
const { specPathJoin } = require('./spec_paths');
const { SpecReflection } = require('./spec_reflection');
/** What a row of the walk stands for. */
const SpecImpactRowKind = {
  /** The document root. */
  ROOT: 'root',
  /** A `complex` field's class node. */
  COMPLEX: 'complex',
  /** A `section` field's class node. */
  SECTION: 'section',
  /** A list field (its items are rows of their own). */
  LIST: 'list',
  /** One item of a list of class elements. */
  ITEM: 'item',
  /** The element class of an empty list, at `<list>/*`: what a new item holds. */
  TEMPLATE: 'template',
};
/** One row of the impact walk. */
class SpecImpactRow {
  constructor(props) {
    this.path = props.path;
    this.chain = props.chain;
    this.kind = props.kind;
    this.className = props.className;
    this.depth = props.depth;
    this.filled = props.filled;
    this.values = props.values;
    this.items = props.items;
    this.routing = props.routing.verdict;
    this.routingValues = props.routing.values;
    this.routingDeclaredAt = props.routing.declaredAt;
  }
  toJson() {
    return {
      path: this.path,
      chain: this.chain,
      kind: this.kind,
      className: this.className,
      depth: this.depth,
      filled: this.filled,
      values: this.values,
      items: this.items,
      routing: this.routing,
      routingValues: this.routingValues,
      routingDeclaredAt: this.routingDeclaredAt,
    };
  }
}
/** The walk of one document root. */
class SpecImpactRootWalk {
  constructor(type, sectionId, present, rows) {
    this.type = type;
    this.sectionId = sectionId;
    this.present = present;
    this.rows = rows;
  }
  toJson() {
    return {
      type: this.type,
      sectionId: this.sectionId,
      present: this.present,
      rows: this.rows.map((r) => r.toJson()),
    };
  }
}
/**
 * Walks every document root of `model`, in model order: a root present in
 * `documents` (keyed by root type) over its document, any other over an empty
 * one. A document keyed by a type the model has no root for is refused.
 */
function specImpactWalk(model, documents) {
  for (const type of documents.keys()) {
    if (model.roots.every((r) => r.type !== type)) {
      throw new Error(`spec_impact_walk: the model has no document root ${type}`);
    }
  }
  const reflection = new SpecReflection(model);
  return model.roots.map((root) => {
    const doc = documents.get(root.type);
    const walker = new ImpactWalker(model, reflection, doc !== undefined ? doc : new SpecDocument());
    return new SpecImpactRootWalk(root.type, reflection.rootSegment(root), doc !== undefined, walker.walkRoot(root));
  });
}
class ImpactWalker {
  constructor(model, reflection, doc) {
    this.model = model;
    this.reflection = reflection;
    this.doc = doc;
    this.rows = [];
    /** Stored values per path prefix (a value counts at its own path and every ancestor). */
    this.counts = new Map();
    for (const path of doc.contentPaths) {
      if (doc.content(path) !== null)
        this.count(path);
    }
    for (const path of doc.formPaths) {
      for (const field of doc.formFieldNames(path)) {
        if (doc.formField(path, field) !== null)
          this.count(path);
      }
    }
  }
  /** Adds one value at `path` to the path and each of its prefixes ending before `/` or `-`. */
  count(path) {
    const add = (p) => this.counts.set(p, (this.counts.get(p) || 0) + 1);
    add(path);
    for (let i = path.length - 1; i > 0; i--) {
      if (path[i] === '/' || path[i] === '-')
        add(path.substring(0, i));
    }
  }
  valuesAt(path) {
    return this.counts.get(path) || 0;
  }
  walkRoot(root) {
    const cls = this.model.classNamed(root.type);
    if (cls === null)
      return this.rows;
    const segment = this.reflection.rootSegment(root);
    this.classNode(SpecImpactRowKind.ROOT, segment, segment, cls, 0, new Set([cls.name]), null);
    return this.rows;
  }
  classNode(kind, path, chain, cls, depth, ancestors, process) {
    const template = path.includes('*');
    const own = codeSpecsClassRouting(cls, path);
    const routing = process !== null ? process : own;
    const below = routing.verdict === CodeSpecsRoutingVerdict.FEEDS_PROCESS ? routing : null;
    this.rows.push(new SpecImpactRow({
      path,
      chain,
      kind,
      className: cls.name,
      depth,
      filled: !template && this.doc.hasValuesUnder(path),
      values: template ? 0 : this.valuesAt(path),
      items: null,
      routing,
    }));
    for (const field of cls.fields) {
      const segment = this.reflection.fieldSegment(field);
      const fieldPath = specPathJoin(path, segment);
      const fieldChain = `${chain} > ${segment}`;
      switch (field.kind) {
        case SpecFieldKind.COMPLEX:
        case SpecFieldKind.SECTION: {
          const child = this.enter(field.type, ancestors);
          if (child !== null) {
            const childKind = field.kind === SpecFieldKind.COMPLEX ? SpecImpactRowKind.COMPLEX : SpecImpactRowKind.SECTION;
            this.classNode(childKind, fieldPath, fieldChain, child, depth + 1, new Set([...ancestors, child.name]), below);
          }
          break;
        }
        case SpecFieldKind.LIST:
          this.list(cls, field, fieldPath, fieldChain, depth + 1, ancestors, below);
          break;
        default:
          break; // a value leaf: counted in this row
      }
    }
  }
  list(owner, field, path, chain, depth, ancestors, process) {
    const template = path.includes('*');
    const items = template ? [] : this.doc.listItems(path);
    const element = field.elementIsComplex ? this.model.classNamed(field.elementType) : null;
    const routing = process !== null
      ? process
      : element !== null
        ? codeSpecsClassRouting(element, path)
        : codeSpecsFieldRouting(owner, field) || codeSpecsClassRouting(owner, path);
    this.rows.push(new SpecImpactRow({
      path,
      chain,
      kind: SpecImpactRowKind.LIST,
      className: element !== null ? element.name : '',
      depth,
      filled: !template && this.doc.hasValuesUnder(path),
      values: template ? 0 : this.valuesAt(path),
      items: items.length,
      routing,
    }));
    if (element === null || ancestors.has(element.name))
      return;
    const next = new Set([...ancestors, element.name]);
    if (items.length === 0) {
      this.classNode(SpecImpactRowKind.TEMPLATE, `${path}/*`, `${chain} > *`, element, depth + 1, next, process);
      return;
    }
    for (const itemPath of items) {
      const stored = this.doc.itemSectionId(itemPath);
      const id = stored !== null ? stored : itemPath.substring(itemPath.lastIndexOf('/') + 1);
      this.classNode(SpecImpactRowKind.ITEM, itemPath, `${chain} > ${id}`, element, depth + 1, next, process);
    }
  }
  enter(type, ancestors) {
    if (type === null || ancestors.has(type))
      return null;
    return this.model.classNamed(type);
  }
}
/** How far the project has come (impact_evaluation.md § Level). */
class SpecImpactLevel {
  constructor(props) {
    this.documents = props.documents;
    this.projectIdea = props.projectIdea;
    this.extracts = props.extracts;
    this.gateRecord = props.gateRecord;
    this.ir = props.ir;
    this.gates = props.gates;
    this.tests = props.tests;
    this.code = props.code;
    this.phasesReached = props.phasesReached;
    this.phasesLeftOut = props.phasesLeftOut;
  }
  toJson() {
    return {
      documents: this.documents,
      projectIdea: this.projectIdea,
      extracts: this.extracts,
      gateRecord: this.gateRecord,
      ir: this.ir,
      gates: this.gates,
      tests: this.tests,
      code: this.code,
      phasesReached: this.phasesReached,
      phasesLeftOut: this.phasesLeftOut,
    };
  }
}
/**
 * The project's level from the walk and a listing of the spec root (paths
 * relative to it, `/`-separated). Phase 2 is reached when the root with
 * section id `SBP` is present, Phase 3 when any other root is that is not a
 * generation input, Phase 4 when extracts or IR exist, Phases 5 and 6 when a
 * test or code folder the caller passed exists. Phases 7–8 (acceptance,
 * deployment) are not visible on disk and are not reported.
 */
function specImpactLevel(model, walk, listing, tests, code) {
  const files = listing.map((p) => p.replace(/\\/g, '/').replace(/^\.\//, ''));
  const documents = walk.map((r) => ({ type: r.type, sectionId: r.sectionId, present: r.present }));
  const projectIdea = files.some((f) => /^phase1_[^/]*\/[^/]+\.md$/.test(f));
  const extracts = files.filter((f) => /^generated-doc\/codespecs_extracts\/CE-[^/]+\.extract\.yaml$/.test(f)).length;
  const gateRecord = files.includes('generated-doc/codespecs_extracts/gate.verdicts.yaml');
  const ir = files.filter((f) => /^irspecs\/[^/]+\.ir\.yaml$/.test(f)).length;
  const gates = files
    .filter((f) => /^gates\/G[^/]*\.checklist\.yaml$/.test(f) || /^quality\/evidence\/gates\/[^/]+\.md$/.test(f))
    .sort();
  const present = (sectionTest) => walk.some((w) => {
    const root = model.roots.find((r) => r.type === w.type);
    return w.present && root !== undefined && sectionTest(root);
  });
  const reached = [];
  if (projectIdea)
    reached.push(1);
  if (present((r) => r.sectionId === 'SBP'))
    reached.push(2);
  if (present((r) => r.sectionId !== 'SBP' && !model.isGenerationInput(r)))
    reached.push(3);
  if (extracts > 0 || ir > 0)
    reached.push(4);
  if (tests !== null && tests.some((t) => t.present))
    reached.push(5);
  if (code !== null && code.some((c) => c.present))
    reached.push(6);
  return new SpecImpactLevel({
    documents,
    projectIdea,
    extracts,
    gateRecord,
    ir,
    gates,
    tests,
    code,
    phasesReached: reached,
    phasesLeftOut: [1, 2, 3, 4, 5, 6].filter((p) => !reached.includes(p)),
  });
}
/**
 * The specification's current documents in a listing of the spec root: the
 * `*.tomspecs.yaml` files directly in a `phase*` folder. The numbered step
 * folders below hold round copies and are not the specification.
 */
function specImpactDocumentFiles(listing) {
  return listing
    .map((p) => p.replace(/\\/g, '/').replace(/^\.\//, ''))
    .filter((f) => /^phase[^/]*\/[^/]+\.tomspecs\.yaml$/.test(f))
    .sort();
}
// --- the Markdown table ------------------------------------------------------
function cell(text) {
  return text.replace(/\|/g, '\\|');
}
/**
 * The walk as Markdown, for a round folder's `walk/` (one table per root, then
 * § Level): the table the change analyst gives verdicts to.
 */
function specImpactWalkMarkdown(walk, level) {
  const out = ['# Impact walk', ''];
  out.push('Every section of every document root, filled or not: the section-id chain, the model class, whether it holds values, and its CodeSpecs routing. ' +
    'A list counts its items; an empty list of sections shows what a new item holds at `<list>/*`.', '');
  for (const root of walk) {
    const filled = root.rows.filter((r) => r.filled).length;
    out.push(`## ${root.sectionId} — ${root.type}${root.present ? '' : ' (absent)'}`, '', `${root.rows.length} rows, ${filled} holding values.`, '', '| Section-id chain | Path | Kind | Class | Values | Items | Routing |', '| --- | --- | --- | --- | --- | --- | --- |');
    for (const r of root.rows) {
      const routing = r.routingValues.length > 0 ? `${r.routing}: ${r.routingValues.join(', ')}` : r.routing;
      out.push(`| ${cell(r.chain)} | \`${cell(r.path)}\` | ${r.kind} | ${cell(r.className)} | ` +
        `${r.filled ? r.values : '—'} | ${r.items !== null ? r.items : ''} | ${cell(routing)} |`);
    }
    out.push('');
  }
  if (level !== null) {
    const yes = (b) => (b ? 'yes' : 'no');
    const folders = (f) => f === null ? 'not given' : f.length === 0 ? 'none' : f.map((x) => `\`${x.path}\` (${x.present ? 'present' : 'absent'})`).join(', ');
    out.push('## Level', '');
    out.push(`- Documents present: ${level.documents.filter((d) => d.present).map((d) => d.sectionId).join(', ') || 'none'}`, `- Documents absent: ${level.documents.filter((d) => !d.present).map((d) => d.sectionId).join(', ') || 'none'}`, `- Project Idea: ${yes(level.projectIdea)}`, `- CodeSpecs extracts: ${level.extracts}; gate record: ${yes(level.gateRecord)}`, `- IR Specs: ${level.ir}`, `- Gates: ${level.gates.length > 0 ? level.gates.map((g) => `\`${g}\``).join(', ') : 'none'}`, `- Tests: ${folders(level.tests)}`, `- Code: ${folders(level.code)}`, `- Phases reached: ${level.phasesReached.join(', ') || 'none'}; left out by a change: ${level.phasesLeftOut.join(', ') || 'none'} (Phases 7–8 are not visible on disk)`, '');
  }
  return out.join('\n');
}

module.exports = {
 SpecImpactRowKind,
 SpecImpactRow,
 SpecImpactRootWalk,
 SpecImpactLevel,
 specImpactWalk,
 specImpactLevel,
 specImpactDocumentFiles,
 specImpactWalkMarkdown,
};
