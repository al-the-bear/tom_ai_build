'use strict';

/**
 * Generated parts of a rendition (SOM §11.12): tables the rendition derives
 * completely from the links of a document, written at the start of the
 * section they belong to as a `derived` block and read back as nothing — a
 * port of `tom_som_typescript_runtime/src/spec_document_markdown_generated.ts`
 * (itself a port of
 * `tom_som_dart_runtime/lib/src/spec_document_markdown_generated.dart`).
 *
 * Internal to {@link SpecDocumentMarkdown}.
 *
 * @internal
 */

const { specResolvePlaceAt } = require('./spec_links_validator');
const { SomMetaKind } = require('./spec_meta');

/**
 * Written by the emitter at a generated place without a table: replaced by
 * an empty `derived` block when the value written after it begins with a
 * `derived` block, else removed with its blank line (SOM §11.12).
 */
const _kDerivedPlaceholder = '\u0000derived\u0000';

/** The requirement classes whose elements are the rows of the requirement
 *  views: every element `INTR.relatedRequirements` may name. */
const _requirementClasses = ['FRE', 'TERQ', 'SECRQ', 'ORRQ'];

/** The generated tables (SOM §11.12): the requirement views of
 *  DP-part-model-links-5 / -11 (D1–D4) where the links hold a table. */
const _generatedTables = [
  {
    at: ['RSP-TRAC', 'RO-TRAC'],
    label: "Generated from each requirement's traceability; edit it there",
    rows: _requirementClasses,
    columns: [
      { header: 'Requirement' },
      { header: 'Use cases', place: 'RT-TRAC.relatedUseCases' },
      { header: 'Screens', place: 'RETRAR.relatedScreens' },
      { header: 'Data entities', place: 'RETRAR.relatedDataEntities' },
      { header: 'Tests', place: 'RETRAR.relatedTestCases' },
    ],
  },
  {
    at: ['REQCOV'],
    label: "Generated from each requirement's test cases; edit them there",
    rows: _requirementClasses,
    columns: [
      { header: 'Requirement' },
      { header: 'Covered', place: 'RETRAR.relatedTestCases', covered: true },
      { header: 'By', place: 'RETRAR.relatedTestCases' },
    ],
  },
  {
    at: ['RERE-REQU-LST'],
    label: "Generated from each requirement's dependencies; edit them there",
    rows: ['RQDEP'],
    owner: _requirementClasses,
    columns: [
      { header: 'Requirement' },
      { header: 'Dependency', place: 'RQDEP.dependencyType' },
      { header: 'Related requirement', place: 'RQDEP-RELA-REF.ref' },
    ],
  },
  {
    at: ['USCATR'],
    label: "Generated from each use case's traceability; edit it there",
    rows: ['INEN'],
    columns: [
      { header: 'Use case' },
      { header: 'Process', place: 'INTR.relatedProcess' },
      { header: 'Requirements', place: 'INTR.relatedRequirements' },
      { header: 'Tests', place: 'INTR.relatedTestCases' },
    ],
  },
];

/** The generated table opening a heading with section id `id`, if any. */
function _generatedTableAt(id) {
  for (const t of _generatedTables) {
    if (t.at.includes(id)) return t;
  }
  return null;
}

/** One root's generated parts. */
class _Generated {
  constructor(nav) {
    this.nav = nav;
  }

  get codec() {
    return this.nav.codec;
  }

  get doc() {
    return this.nav.doc;
  }

  /** Whether the heading at `path` is a generated place (structural: its
   *  section id opens a generated table). */
  isPlace(path) {
    const node = this.nav.tree.byPath(path);
    if (node === null || this.nav.walk(path, { d: this.doc }).headingPath !== path) {
      return false;
    }
    return _generatedTableAt(this.codec._headingIdOf(node)) !== null;
  }

  _blocks = null;

  /** The blocks of this document, by heading path: only the places whose
   *  table has rows. */
  get blocks() {
    if (this._blocks !== null) return this._blocks;
    const out = new Map();
    const cls = this.codec.constructor;
    for (const n of this.nav.tree.allNodes) {
      const path = n.path;
      if (path === null) continue;
      if (this.codec._isTransparentSection(n) || cls._isTransparentValue(n)) {
        continue;
      }
      const table = _generatedTableAt(this.codec._headingIdOf(n));
      if (table === null) continue;
      const block = this._block(table);
      if (block !== null) out.set(path, block);
    }
    this._blocks = out;
    return out;
  }

  /** Whether a generated block stands at or beneath `path`, so the heading
   *  is written even when the document holds no value there. */
  forces(path) {
    for (const p of this.blocks.keys()) {
      if (p === path || p.startsWith(`${path}/`)) return true;
    }
    return false;
  }

  _itemsCache = null;

  /** Every element of the document, in rendition order. */
  get _items() {
    if (this._itemsCache !== null) return this._itemsCache;
    const out = [];
    const doc = this.doc;
    const walk = (node, path) => {
      for (const [child, rel] of this.codec._effectiveChildren(node)) {
        const p = `${path}/${rel}`;
        if (!doc.hasValuesUnder(p)) continue;
        if (child.kind === SomMetaKind.LIST) {
          for (const item of doc.listItems(p)) {
            out.push(item);
            const element = child.elementNode;
            if (element !== null && element !== undefined && !element.recursive) {
              walk(element, item);
            }
          }
        } else if (child.kind === SomMetaKind.SECTION || child.kind === SomMetaKind.COMPLEX) {
          walk(child, p);
        }
      }
    };
    walk(this.nav.tree.root, this.nav.rootSeg);
    this._itemsCache = out;
    return out;
  }

  _classId(item) {
    return this.nav.refl.resolve(item)?.targetClass?.sectionId ?? null;
  }

  /** The block lines of `table`, or null when it has no row. */
  _block(table) {
    const rows = [];
    const doc = this.doc;
    for (const item of this._items) {
      const classId = this._classId(item);
      if (classId === null || !table.rows.includes(classId)) continue;
      const cells = [];
      for (const c of table.columns) {
        const place = c.place;
        if (place === undefined) {
          cells.push(this._idCell(this._rowOwner(item, table)));
          continue;
        }
        const r = specResolvePlaceAt(this.nav.refl, place, item);
        const field = r === null ? null : r.field;
        const raw =
          r === null || field === null ? null : (doc.formField(r.path, field)?.trim() ?? null);
        const value = raw === null || raw === '' ? null : raw;
        if (c.covered === true) {
          cells.push(value === null ? 'no' : 'yes');
          continue;
        }
        if (value === null) {
          cells.push('');
          continue;
        }
        const meta =
          this.nav.tree.byPath(r.path)?.form?.fields.find((f) => f.name === field) ?? null;
        cells.push(
          meta === null ? value.replace(/\|/g, '\\|') : this.codec._linkedCellText(meta, value),
        );
      }
      rows.push(cells);
    }
    if (rows.length === 0) return null;
    return [
      `::: {.derived label="${table.label}"}`,
      `| ${table.columns.map((c) => c.header).join(' | ')} |`,
      `| ${table.columns.map(() => '---').join(' | ')} |`,
      ...rows.map((r) => `| ${r.join(' | ')} |`),
      ':::',
    ];
  }

  /** The element a row names: itself, or its nearest owner of
   * the table's `owner`. */
  _rowOwner(item, table) {
    const owner = table.owner ?? [];
    if (owner.length === 0) return item;
    let p = item;
    while (p.includes('/')) {
      p = p.substring(0, p.lastIndexOf('/'));
      if (this.nav._itemParts(p) !== null) {
        const id = this._classId(p);
        if (id !== null && owner.includes(id)) return p;
      }
    }
    return null;
  }

  /** A link to the element at `item` by its id and anchor. */
  _idCell(item) {
    if (item === null) return '';
    const w = this.nav.walk(item, { d: this.doc });
    return `[${w.headingId}](#${w.anchor})`;
  }
}

/** Whether `line` opens a `derived` block. */
function _opensDerived(line) {
  return /^ {0,3}:{3,}[ \t]*\{\.derived(?=[\s}])/.test(line);
}

/**
 * `markdown` with every derived placeholder resolved: an empty `derived`
 * block where the block after it opens a `derived` block, else removed with
 * its blank line.
 */
function _resolveDerivedPlaceholders(markdown) {
  if (!markdown.includes(_kDerivedPlaceholder)) return markdown;
  const lines = markdown.split('\n');
  const out = [];
  for (let i = 0; i < lines.length; i++) {
    if (lines[i] !== _kDerivedPlaceholder) {
      out.push(lines[i]);
      continue;
    }
    let k = i + 1;
    while (k < lines.length && lines[k].trim() === '') k++;
    if (k < lines.length && _opensDerived(lines[k])) {
      out.push('::: {.derived}');
      out.push(':::');
    } else {
      i++; // the blank line after the placeholder goes with it
    }
  }
  return out.join('\n');
}

module.exports = {
  _kDerivedPlaceholder,
  _Generated,
  _opensDerived,
  _resolveDerivedPlaceholders,
};
