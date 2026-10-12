/**
 * Assembling one spec document from fragments written in parallel — a port of
 * `tom_som_dart_runtime/lib/src/spec_document_assembly.dart`.
 *
 * A large document is often authored in parts — one group, or one agent, per
 * set of sections — each part a document of its own holding a subset of the
 * sections. References between parts can only be judged on the whole: the
 * instance tier resolves a `refersTo` against the document it is given, so a
 * part validated alone reports every reference into another part as
 * dangling. {@link SpecDocument.assemble} is the step that produces the whole.
 *
 * The merge is over the plain-data stores ({@link SpecDocument.toJson}), and it
 * is **refusing**: a value two fragments both write — a content path, a form
 * field, a list, a headline, a code-spec location — is an overlap, and an
 * assembly with any overlap yields no document. Choosing a winner would make
 * the result depend on fragment order, and two parts writing one place is an
 * authoring conflict the parts' authors have to settle.
 */

import { SpecDocument } from './spec_document';

/** One place two or more fragments both write. */
export class SpecAssemblyOverlap {
  /** The store: `content`, `forms`, `lists`, `headlines` or `codeSpecs`. */
  readonly store: string;

  /** The document path. */
  readonly path: string;

  /** The form field, for the `forms` store; `null` otherwise. */
  readonly field: string | null;

  /** The fragments that write it, in the order they were given. */
  readonly fragments: readonly string[];

  constructor(init: {
    store: string;
    path: string;
    fragments: readonly string[];
    field?: string | null;
  }) {
    this.store = init.store;
    this.path = init.path;
    this.field = init.field ?? null;
    this.fragments = Object.freeze(init.fragments.slice());
  }

  /** One sentence naming the place and every fragment that writes it. */
  get message(): string {
    const place =
      this.field === null ? this.path : `${this.path} field \`${this.field}\``;
    return (
      `${place} (${this.store}) is written by ` +
      `${this.fragments.join(' and ')} — a place two fragments both write is an ` +
      'authoring conflict, not something the assembly may resolve'
    );
  }

  toString(): string {
    return this.message;
  }
}

/** The result of {@link SpecDocument.assemble}. */
export class SpecDocumentAssembly {
  /** The assembled document; `null` when there is any overlap. */
  readonly document: SpecDocument | null;

  /** Every overlap, in store order and then path order. */
  readonly overlaps: readonly SpecAssemblyOverlap[];

  constructor(init: {
    document?: SpecDocument | null;
    overlaps?: readonly SpecAssemblyOverlap[];
  } = {}) {
    this.document = init.document ?? null;
    this.overlaps = Object.freeze((init.overlaps ?? []).slice());
  }

  /** Whether the fragments assembled. */
  get ok(): boolean {
    return this.overlaps.length === 0;
  }
}

/** The fragments to assemble: name → document, in order. */
export type SpecDocumentFragments = Iterable<readonly [string, SpecDocument]>;

/** The stores whose entries are a single value at a path. */
const _PATH_STORES = ['content', 'headlines', 'codeSpecs'] as const;

/** The fixed order overlaps are reported in. */
const _STORE_ORDER = [
  'content',
  'forms',
  'lists',
  'headlines',
  'codeSpecs',
] as const;

/** Code-unit order, as Dart's `String.compareTo`. */
function _compareCodeUnits(a: string, b: string): number {
  return a < b ? -1 : a > b ? 1 : 0;
}

/**
 * Merges `fragments` — name → document, in order (a `Map` or any iterable of
 * `[name, document]` pairs) — into one document. See the module comment for
 * the refusing rule.
 *
 * A fragment name given twice is an `Error`: Dart's `Map` argument cannot hold
 * one, and silently keeping either would drop a fragment.
 */
export function assembleSpecDocuments(
  fragments: SpecDocumentFragments,
): SpecDocumentAssembly {
  // store → key → writer fragments; key is the path, or `path\u0000field`.
  const writers = new Map<string, Map<string, string[]>>();
  const merged = new Map<string, Map<string, unknown>>();
  for (const s of _STORE_ORDER) {
    writers.set(s, new Map());
    merged.set(s, new Map());
  }
  const addWriter = (store: string, key: string, name: string): void => {
    const byKey = writers.get(store) as Map<string, string[]>;
    const who = byKey.get(key);
    if (who) {
      who.push(name);
    } else {
      byKey.set(key, [name]);
    }
  };

  const seen = new Set<string>();
  for (const [name, doc] of fragments) {
    if (seen.has(name)) {
      throw new Error(`fragment name "${name}" is given more than once`);
    }
    seen.add(name);
    const json = doc.toJson() as Record<string, any>;
    for (const store of _PATH_STORES) {
      const entries = (json[store] ?? {}) as Record<string, unknown>;
      const target = merged.get(store) as Map<string, unknown>;
      for (const [path, value] of Object.entries(entries)) {
        addWriter(store, path, name);
        if (!target.has(path)) {
          target.set(path, value);
        }
      }
    }
    const forms = (json.forms ?? {}) as Record<string, Record<string, unknown>>;
    const mergedForms = merged.get('forms') as Map<string, unknown>;
    for (const [path, fields] of Object.entries(forms)) {
      let target = mergedForms.get(path) as Record<string, unknown> | undefined;
      if (!target) {
        target = {};
        mergedForms.set(path, target);
      }
      for (const [field, value] of Object.entries(fields)) {
        addWriter('forms', `${path}\u0000${field}`, name);
        if (!Object.prototype.hasOwnProperty.call(target, field)) {
          target[field] = value;
        }
      }
    }
    const lists = (json.lists ?? {}) as Record<string, unknown>;
    const mergedLists = merged.get('lists') as Map<string, unknown>;
    for (const [path, spec] of Object.entries(lists)) {
      addWriter('lists', path, name);
      if (!mergedLists.has(path)) {
        mergedLists.set(path, spec);
      }
    }
  }

  const overlaps: SpecAssemblyOverlap[] = [];
  for (const store of _STORE_ORDER) {
    const byKey = writers.get(store) as Map<string, string[]>;
    const keys = Array.from(byKey.keys()).sort(_compareCodeUnits);
    for (const key of keys) {
      const who = byKey.get(key) as string[];
      if (who.length < 2) {
        continue;
      }
      const sep = key.indexOf('\u0000');
      overlaps.push(
        new SpecAssemblyOverlap({
          store,
          path: sep < 0 ? key : key.substring(0, sep),
          field: sep < 0 ? null : key.substring(sep + 1),
          fragments: who,
        }),
      );
    }
  }
  if (overlaps.length > 0) {
    return new SpecDocumentAssembly({ overlaps });
  }
  const state: Record<string, Record<string, unknown>> = {};
  for (const store of _STORE_ORDER) {
    const m = merged.get(store) as Map<string, unknown>;
    if (m.size > 0) {
      state[store] = Object.fromEntries(m);
    }
  }
  const document = new SpecDocument();
  document.loadJson(state);
  return new SpecDocumentAssembly({ document });
}
