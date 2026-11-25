/**
 * Generated parts of a rendition (SOM §11.12): tables the rendition derives
 * completely from the links of a document, written at the start of the
 * section they belong to as a `derived` block and read back as nothing — a
 * port of `tom_som_dart_runtime/lib/src/spec_document_markdown_generated.dart`.
 *
 * Internal to {@link SpecDocumentMarkdown}.
 *
 * @internal
 */

import type { SpecDocument } from './spec_document';
import type { SpecDocumentMarkdown } from './spec_document_markdown';
import type { _Navigation } from './spec_document_markdown_linked';
import { specResolvePlaceAt } from './spec_links_validator';
import { SomMetaKind, type SomMetaNode } from './spec_meta';

/**
 * Written by the emitter at a generated place without a table: replaced by
 * an empty `derived` block when the value written after it begins with a
 * `derived` block, else removed with its blank line (SOM §11.12).
 */
export const _kDerivedPlaceholder = '\u0000derived\u0000';

/** The requirement classes whose elements are the rows of the requirement
 *  views: every element `INTR.relatedRequirements` may name. */
const _requirementClasses = ['FRE', 'TERQ', 'SECRQ', 'ORRQ'];

/** One column of a generated table. */
interface _GeneratedColumn {
  /** The header cell. */
  header: string;
  /** The value's place under the row (`RETRAR.relatedScreens`); absent: the
   *  row's own id (or its owner's, see {@link _GeneratedTable.owner}). */
  place?: string;
  /** `yes` when `place` holds a value, else `no`. */
  covered?: boolean;
}

/** A generated table: where it stands, its rows, its columns. */
interface _GeneratedTable {
  /** The section ids of the headings it opens. */
  at: string[];
  /** The block's `label` (DocSpecs RN-6). */
  label: string;
  /** The class section ids whose elements are its rows, in document order. */
  rows: string[];
  /** When set, the first column names the nearest element above the row of
   *  one of these classes instead of the row itself. */
  owner?: string[];
  /** The columns. */
  columns: _GeneratedColumn[];
}

/** The generated tables (SOM §11.12): the requirement views of
 *  DP-part-model-links-5 / -11 (D1–D4) where the links hold a table. */
const _generatedTables: _GeneratedTable[] = [
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
function _generatedTableAt(id: string): _GeneratedTable | null {
  for (const t of _generatedTables) {
    if (t.at.includes(id)) return t;
  }
  return null;
}

/** One root's generated parts. */
export class _Generated {
  readonly nav: _Navigation;

  constructor(nav: _Navigation) {
    this.nav = nav;
  }

  get codec(): SpecDocumentMarkdown {
    return this.nav.codec;
  }

  get doc(): SpecDocument {
    return this.nav.doc;
  }

  /** Whether the heading at `path` is a generated place (structural: its
   *  section id opens a generated table). */
  isPlace(path: string): boolean {
    const node = this.nav.tree.byPath(path);
    if (node === null || this.nav.walk(path, { d: this.doc }).headingPath !== path) {
      return false;
    }
    return _generatedTableAt(this.codec._headingIdOf(node)) !== null;
  }

  private _blocks: Map<string, string[]> | null = null;

  /** The blocks of this document, by heading path: only the places whose
   *  table has rows. */
  get blocks(): Map<string, string[]> {
    if (this._blocks !== null) return this._blocks;
    const out = new Map<string, string[]>();
    const cls = this.codec.constructor as typeof SpecDocumentMarkdown;
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
  forces(path: string): boolean {
    for (const p of this.blocks.keys()) {
      if (p === path || p.startsWith(`${path}/`)) return true;
    }
    return false;
  }

  private _itemsCache: string[] | null = null;

  /** Every element of the document, in rendition order. */
  private get _items(): string[] {
    if (this._itemsCache !== null) return this._itemsCache;
    const out: string[] = [];
    const doc = this.doc;
    const walk = (node: SomMetaNode, path: string): void => {
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

  private _classId(item: string): string | null {
    return this.nav.refl.resolve(item)?.targetClass?.sectionId ?? null;
  }

  /** The block lines of `table`, or null when it has no row. */
  private _block(table: _GeneratedTable): string[] | null {
    const rows: string[][] = [];
    const doc = this.doc;
    for (const item of this._items) {
      const classId = this._classId(item);
      if (classId === null || !table.rows.includes(classId)) continue;
      const cells: string[] = [];
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
          this.nav.tree.byPath(r!.path)?.form?.fields.find((f) => f.name === field) ?? null;
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
   *  {@link _GeneratedTable.owner}. */
  private _rowOwner(item: string, table: _GeneratedTable): string | null {
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
  private _idCell(item: string | null): string {
    if (item === null) return '';
    const w = this.nav.walk(item, { d: this.doc });
    return `[${w.headingId}](#${w.anchor})`;
  }
}

/** Whether `line` opens a `derived` block. */
export function _opensDerived(line: string): boolean {
  return /^ {0,3}:{3,}[ \t]*\{\.derived(?=[\s}])/.test(line);
}

/**
 * `markdown` with every derived placeholder resolved: an empty `derived`
 * block where the block after it opens a `derived` block, else removed with
 * its blank line.
 */
export function _resolveDerivedPlaceholders(markdown: string): string {
  if (!markdown.includes(_kDerivedPlaceholder)) return markdown;
  const lines = markdown.split('\n');
  const out: string[] = [];
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
