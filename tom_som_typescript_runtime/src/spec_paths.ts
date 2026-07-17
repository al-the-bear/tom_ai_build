/**
 * The section-path grammar shared by the in-memory document and the meta-model
 * traversal — a faithful port of `tom_som_dart_runtime/lib/src/spec_paths.dart`
 * (and the JavaScript `spec_paths.js`).
 *
 * A path is the globally-unique address of a node in a concrete document:
 *
 *   * the **root** is the document root's section segment (its `@SectionId` when
 *     present, otherwise the root class name);
 *   * a **child field** appends `/<segment>`;
 *   * a **complex / section** field collapses into its target class (no extra
 *     segment — the class's children hang directly off the field's path);
 *   * a **list item** appends `-<seq>` to the list field's path (no `/`).
 *
 * Form-field values are *not* path segments: a `@Form` section is one path whose
 * individual fields are sub-keys inside the document's form store.
 */

/** The path separator between section segments. */
export const SPEC_PATH_SEPARATOR = '/';

/** Joins `parent` with a child `segment` using the path separator. */
export function specPathJoin(parent: string, segment: string): string {
  return `${parent}${SPEC_PATH_SEPARATOR}${segment}`;
}

/**
 * Splits `path` into its `/`-separated segments. A list-item sequence suffix
 * (`<segment>-3`) stays attached to its segment.
 */
export function specPathSegments(path: string): string[] {
  return path.split(SPEC_PATH_SEPARATOR);
}

/**
 * The parent path of `path` — everything before the final `/`-separated
 * segment — or `path` itself when it has no separator (a root path).
 *
 * Used by the generated facades' YRD6 role-field accessors: a transparent
 * class-level `@Form` member is hoisted into its parent section's body, so
 * its title/id role fields bind to the **parent** path's headline / stored
 * section id.
 */
export function specParentPath(path: string): string {
  const i = path.lastIndexOf(SPEC_PATH_SEPARATOR);
  return i < 0 ? path : path.slice(0, i);
}

/** The path of the `seq`-th item appended to the list at `listPath`. */
export function listItemPath(listPath: string, seq: number): string {
  return `${listPath}-${seq}`;
}

/** A list-item segment split into its base segment and sequence number. */
export interface ListItemSegment {
  base: string;
  seq: number;
}

/**
 * Splits a list-item `segment` into its base segment and sequence number when it
 * ends in `-<digits>`, or returns `null` otherwise.
 *
 * Only an all-digit tail counts, so a hyphenated `@SectionId` such as `CUOPME-OPER-LST`
 * is never mis-read as a list item.
 */
export function splitListItemSegment(segment: string): ListItemSegment | null {
  const dash = segment.lastIndexOf('-');
  if (dash <= 0 || dash === segment.length - 1) {
    return null;
  }
  const tail = segment.slice(dash + 1);
  if (!/^[0-9]+$/.test(tail)) {
    return null;
  }
  return { base: segment.slice(0, dash), seq: parseInt(tail, 10) };
}
