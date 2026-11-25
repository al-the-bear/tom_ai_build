'use strict';

/**
 * Places and filters of the link vocabulary (`tom_specs_model_rules.md` §9.7):
 * the grammar every link annotation names places in, parsed once and resolved
 * under an anchor through {@link SpecReflection} — a port of
 * `tom_som_dart_runtime/lib/src/spec_place.dart`.
 *
 * * A **place** names a section, a list, a form field, a heading, a content
 *   value or a registry id: `FRED.description`, `FRE.@headline`,
 *   `FRE-REQU-LST`, `./RQDEP`, `FRE/REQDEP/RQDEP.description`,
 *   `<SECTIONID>.@content`, `<SECTIONID>.@sectionId` ({@link SpecPlace}).
 * * A **filter** selects entries by one of their form values: `<SECTIONID>`,
 *   `./<SECTIONID>`, `<SECTIONID>.<field>=<value>` with `|` between
 *   alternatives (`FRE.priority=must|should`) ({@link SpecPlaceFilter}).
 *   `countOf` and every `where:` read it.
 *
 * Resolution is value-free, like {@link SpecReflection}: it says where in a
 * document the place is stored, with every list item below the anchor written
 * `<list>-*`, and never reads a value.
 */

const { SpecFieldKind } = require('./spec_model');
const { specPathSegments } = require('./spec_paths');
const { SpecNodeKind } = require('./spec_reflection');

/** What a resolved place is. */
const SpecPlaceKind = {
  /** A section (a class's own node or a complex member), whole. */
  SECTION: 'section',
  /** A `-LST` list container. */
  LIST: 'list',
  /** A form member, every field of it. */
  FORM: 'form',
  /** One field of a form. */
  FORM_FIELD: 'formField',
  /** The stored headline of a section (`.@headline`). */
  HEADLINE: 'headline',
  /** The content value of a section (`.@content`, or a content member). */
  CONTENT: 'content',
  /** The stored section id of a list element (`.@sectionId`). */
  SECTION_ID: 'sectionId',
};

/** Why a place or a filter does not parse or does not resolve. */
const SpecPlaceProblem = {
  /** The text is not a place (or not a filter) of the grammar. */
  MALFORMED: 'malformed',
  /** The anchor path resolves to no section of the model. */
  ANCHOR_UNRESOLVED: 'anchorUnresolved',
  /** The place is `./`-scoped, but no list element lies at or above the anchor. */
  NOT_SCOPED: 'notScoped',
  /** No section with the place's id (and `/` path) lies in the scope. */
  UNRESOLVED: 'unresolved',
  /** The place's id is reached at more than one position in the scope. */
  AMBIGUOUS: 'ambiguous',
  /** The named field is no form field of the section. */
  NO_SUCH_FIELD: 'noSuchField',
  /** `.@content` names a section that holds no content value. */
  NO_CONTENT: 'noContent',
  /** `.@sectionId` names a section that is no list element. */
  NOT_LIST_ELEMENT: 'notListElement',
  /** A slot starting with `@` other than `@headline`, `@content`, `@sectionId`. */
  RESERVED_SLOT: 'reservedSlot',
};

/** A place or filter that does not parse or resolve, with the reason. */
class SpecPlaceException extends Error {
  /** `message` is the prose for the reader, as the Dart field is. */
  constructor(problem, text, message) {
    super(message);
    this.name = 'SpecPlaceException';
    /** What went wrong; the corpus compares this, never the message. */
    this.problem = problem;
    /** The place or filter as written. */
    this.text = text;
  }

  toString() {
    return `SpecPlaceException(${this.problem}): "${this.text}" ${this.message}`;
  }
}

const _SEGMENT = /^[A-Za-z0-9][A-Za-z0-9-]*$/;
const _SLOT = /^@?[A-Za-z_][A-Za-z0-9_]*$/;
const _FIELD = /^[A-Za-z_][A-Za-z0-9_]*$/;

/** A place as written: `./` scope, `/` segments, section id and slot. */
class SpecPlace {
  constructor(props) {
    /** The text it was parsed from. */
    this.text = props.text;
    /**
     * Whether it is written `./…`: resolved beneath the nearest list element at
     * or above the anchor.
     */
    this.scoped = props.scoped;
    /**
     * The section ids written before the last `/`, which the path to the place
     * holds in this order.
     */
    this.prefix = props.prefix;
    /** The section id the place names. */
    this.sectionId = props.sectionId;
    /**
     * The part after the dot: a form field name, `@headline`, `@content`,
     * `@sectionId`; `null` for the section, list or form itself.
     */
    this.slot = props.slot != null ? props.slot : null;
  }

  /**
   * Parses `text`; throws a {@link SpecPlaceException} (`malformed`) when it is
   * not a place.
   */
  static parse(text) {
    const place = SpecPlace.tryParse(text);
    if (place === null) {
      throw new SpecPlaceException(
        SpecPlaceProblem.MALFORMED,
        text,
        'is not a place (`<SECTIONID>[.<field>|.@headline|.@content|' +
          '.@sectionId]`, optionally `./`-scoped or a `/` path)',
      );
    }
    return place;
  }

  /** Parses `text`, or returns `null` when it is not a place. */
  static tryParse(text) {
    const scoped = text.startsWith('./');
    const body = scoped ? text.substring(2) : text;
    if (body === '') {
      return null;
    }
    const segments = body.split('/');
    const last = segments.pop();
    const dot = last.indexOf('.');
    const id = dot < 0 ? last : last.substring(0, dot);
    const slot = dot < 0 ? null : last.substring(dot + 1);
    if (!_SEGMENT.test(id) || segments.some((s) => !_SEGMENT.test(s))) {
      return null;
    }
    if (slot !== null && !_SLOT.test(slot)) {
      return null;
    }
    return new SpecPlace({
      text,
      scoped,
      prefix: Object.freeze(segments),
      sectionId: id,
      slot,
    });
  }

  /** The parsed parts, for the corpus. */
  toJson() {
    return {
      scoped: this.scoped,
      prefix: [...this.prefix],
      sectionId: this.sectionId,
      ...(this.slot !== null ? { slot: this.slot } : {}),
    };
  }

  /**
   * Resolves the place under `anchor`, a document path of a section (a root, a
   * complex or section member, or a list item). Throws a
   * {@link SpecPlaceException} when it does not resolve.
   *
   * The place is looked for in the subtree of the anchor's class — beneath the
   * nearest list element at or above the anchor when it is `./`-scoped — among
   * the positions whose section id is {@link sectionId} and whose path holds
   * the {@link prefix} ids in order (only `-LST` containers and the scope's own
   * id may lie between them). More than one such position is `ambiguous`.
   */
  resolve(refl, anchor) {
    const scope = _scopeOf(refl, anchor, this.scoped, this.text);
    const candidates = _positions(refl, scope).filter(
      (p) =>
        p.node.id === this.sectionId &&
        _pathMatches(p.ids.slice(0, p.ids.length - 1), this.prefix),
    );
    if (candidates.length === 0) {
      throw new SpecPlaceException(
        SpecPlaceProblem.UNRESOLVED,
        this.text,
        `resolves to no section beneath ${scope.path}`,
      );
    }
    const byPath = new Map();
    for (const p of candidates) {
      byPath.set(p.node.path, p);
    }
    if (byPath.size > 1) {
      throw new SpecPlaceException(
        SpecPlaceProblem.AMBIGUOUS,
        this.text,
        `is ambiguous: ${this.sectionId} is reached at ` +
          `${[...byPath.keys()].sort().join(', ')} — write it as a \`/\` path`,
      );
    }
    return this._withSlot(byPath.values().next().value);
  }

  _withSlot(p) {
    const n = p.node;
    const result = (kind, path, field = null) =>
      new SpecPlaceResolution({
        place: this,
        kind,
        path,
        formField: field,
        className: n.className,
        sectionIds: p.ids,
      });

    const slot = this.slot;
    if (slot === null) {
      switch (n.shape) {
        case 'list':
          return result(SpecPlaceKind.LIST, n.path);
        case 'form':
          return result(SpecPlaceKind.FORM, n.path);
        case 'content':
          return result(SpecPlaceKind.CONTENT, n.path);
        default:
          return result(SpecPlaceKind.SECTION, n.path);
      }
    }
    if (slot === '@headline') {
      return result(SpecPlaceKind.HEADLINE, n.path);
    }
    if (slot === '@content') {
      if (n.contentPath === null) {
        throw new SpecPlaceException(
          SpecPlaceProblem.NO_CONTENT,
          this.text,
          `names @content of ${this.sectionId}, which holds no content value`,
        );
      }
      return result(SpecPlaceKind.CONTENT, n.contentPath);
    }
    if (slot === '@sectionId') {
      if (!n.isListElement) {
        throw new SpecPlaceException(
          SpecPlaceProblem.NOT_LIST_ELEMENT,
          this.text,
          `names @sectionId of ${this.sectionId}, which is no list element`,
        );
      }
      return result(SpecPlaceKind.SECTION_ID, n.path);
    }
    if (slot.startsWith('@')) {
      throw new SpecPlaceException(
        SpecPlaceProblem.RESERVED_SLOT,
        this.text,
        `names the slot ${slot} — "@" is reserved for @headline, @content and ` +
          '@sectionId',
      );
    }
    const field = n.formFields.find((f) => f.name === slot);
    if (field === undefined || n.formPath === null) {
      throw new SpecPlaceException(
        SpecPlaceProblem.NO_SUCH_FIELD,
        this.text,
        `names ${this.sectionId}.${slot}, which is no form field`,
      );
    }
    return result(SpecPlaceKind.FORM_FIELD, n.formPath, field);
  }

  toString() {
    return this.text;
  }
}

/** Where a place is stored in a document. */
class SpecPlaceResolution {
  constructor(props) {
    /** The place resolved. */
    this.place = props.place;
    /** What the place is. */
    this.kind = props.kind;
    /**
     * The document path the value lives at, with every list item beneath the
     * anchor written `<list>-*`: the section (or list item) for a section, a
     * headline or a section id; the list for a list; the form for a form or a
     * form field; the content leaf for a content value.
     */
    this.path = props.path;
    /** The class of the section the place sits on (for a member, its owner). */
    this.className = props.className;
    /**
     * The section ids on the way from the scope to the place, the place's own
     * last.
     */
    this.sectionIds = props.sectionIds;
    /** For {@link SpecPlaceKind.FORM_FIELD}, the field. */
    this.formField = props.formField != null ? props.formField : null;
  }

  /** The form field name for {@link SpecPlaceKind.FORM_FIELD}, else `null`. */
  get field() {
    return this.formField !== null ? this.formField.name : null;
  }

  /** The canonical JSON form the corpus compares. */
  toJson() {
    const field = this.field;
    return {
      kind: this.kind,
      path: this.path,
      ...(field !== null ? { field } : {}),
    };
  }
}

/**
 * An entry filter: `<SECTIONID>`, `./<SECTIONID>` or
 * `<SECTIONID>.<field>=<value>[|<value>…]`, optionally `./`-scoped.
 *
 * It selects the entries (list elements of the class with that section id)
 * one of whose own forms holds one of {@link values} in {@link field}; without
 * a field every entry. `countOf` counts the entries it selects, a `where:`
 * keeps the elements or rows it selects.
 */
class SpecPlaceFilter {
  constructor(props) {
    /** The text it was parsed from. */
    this.text = props.text;
    /**
     * Whether it is written `./…`: only the entries beneath the nearest list
     * element (for `countOf`: beneath the section holding the form).
     */
    this.scoped = props.scoped;
    /** The section id of the entries. */
    this.sectionId = props.sectionId;
    /** The form field compared, or `null` for every entry. */
    this.field = props.field != null ? props.field : null;
    /**
     * The values accepted, in written order; empty exactly when {@link field} is
     * `null`.
     */
    this.values = props.values || [];
  }

  /**
   * Parses `text`; throws a {@link SpecPlaceException} (`malformed`) when it is
   * not a filter.
   */
  static parse(text) {
    const filter = SpecPlaceFilter.tryParse(text);
    if (filter === null) {
      throw new SpecPlaceException(
        SpecPlaceProblem.MALFORMED,
        text,
        'is not a filter (`<SECTIONID>[.<field>=<value>[|<value>…]]`, ' +
          'optionally `./`-scoped)',
      );
    }
    return filter;
  }

  /** Parses `text`, or returns `null` when it is not a filter. */
  static tryParse(text) {
    const scoped = text.startsWith('./');
    const body = scoped ? text.substring(2) : text;
    const dot = body.indexOf('.');
    const id = dot < 0 ? body : body.substring(0, dot);
    if (!_SEGMENT.test(id)) {
      return null;
    }
    if (dot < 0) {
      return new SpecPlaceFilter({ text, scoped, sectionId: id });
    }
    const eq = body.indexOf('=', dot);
    if (eq < 0) {
      return null;
    }
    const field = body.substring(dot + 1, eq);
    if (!_FIELD.test(field)) {
      return null;
    }
    const values = body.substring(eq + 1).split('|');
    if (values.some((v) => v === '')) {
      return null;
    }
    return new SpecPlaceFilter({
      text,
      scoped,
      sectionId: id,
      field,
      values: Object.freeze(values),
    });
  }

  /**
   * Whether an entry whose {@link field} holds `stored` (trimmed values, as
   * many as its forms hold) is selected.
   */
  matches(stored) {
    if (this.field === null) {
      return true;
    }
    for (const v of stored) {
      if (this.values.includes(v.trim())) {
        return true;
      }
    }
    return false;
  }

  /** The place of the entries: {@link sectionId}, scoped as the filter is. */
  get place() {
    return new SpecPlace({
      text: this.scoped ? `./${this.sectionId}` : this.sectionId,
      scoped: this.scoped,
      prefix: [],
      sectionId: this.sectionId,
    });
  }

  /**
   * Resolves the entries under `anchor` as {@link SpecPlace.resolve} does, and
   * checks that {@link field} is a field of one of the entry's own forms (a
   * form member of the entry, or its content form). Throws a
   * {@link SpecPlaceException} when it does not resolve.
   */
  resolve(refl, anchor) {
    let r;
    try {
      r = this.place.resolve(refl, anchor);
    } catch (e) {
      if (e instanceof SpecPlaceException) {
        throw new SpecPlaceException(e.problem, this.text, e.message);
      }
      throw e;
    }
    const field = this.field;
    if (field !== null) {
      const cls = refl.classNamed(r.className);
      const own = [];
      if (r.kind === SpecPlaceKind.SECTION && cls !== null) {
        for (const f of cls.fields) {
          if (f.kind === SpecFieldKind.FORM) {
            own.push(...f.formFields);
          }
        }
      }
      if (!own.some((f) => f.name === field)) {
        throw new SpecPlaceException(
          SpecPlaceProblem.NO_SUCH_FIELD,
          this.text,
          `names ${this.sectionId}.${field}, which no form of ` +
            `${this.sectionId} holds`,
        );
      }
    }
    return r;
  }

  /** The parsed parts, for the corpus. */
  toJson() {
    return {
      scoped: this.scoped,
      sectionId: this.sectionId,
      ...(this.field !== null ? { field: this.field, values: [...this.values] } : {}),
    };
  }

  toString() {
    return this.text;
  }
}

/** A `@SameAs` copy at one position of a document root, with its holder. */
class SpecSameAsBinding {
  constructor(props) {
    /** The root the positions are in. */
    this.root = props.root;
    /** The class both positions hold. */
    this.className = props.className;
    /** The copy's document path (list items written `<list>-*`). */
    this.copyPath = props.copyPath;
    /** The copy's section-id path from the root. */
    this.copySectionIds = props.copySectionIds;
    /** The holder's document path, or `null` when {@link problem} is set. */
    this.holderPath = props.holderPath != null ? props.holderPath : null;
    /** The holder's section-id path from the root, or `null`. */
    this.holderSectionIds =
      props.holderSectionIds != null ? props.holderSectionIds : null;
    /**
     * Why no single holder was found: `unresolved` (no position fits) or
     * `ambiguous` (several do); `null` when {@link holderPath} is set.
     */
    this.problem = props.problem != null ? props.problem : null;
  }

  /** The canonical JSON form the corpus compares. */
  toJson() {
    return {
      root: this.root,
      className: this.className,
      copy: this.copyPath,
      ...(this.holderPath !== null ? { holder: this.holderPath } : {}),
      ...(this.problem !== null ? { problem: this.problem } : {}),
    };
  }
}

/**
 * Every `@SameAs` copy the document root `rootType` reaches, each with its
 * holder (`tom_specs_model_rules.md` §9.7, invariant `SAME-AS`): among the
 * positions of the copy's class in the root that are no copy themselves, the
 * one whose section-id path ends with `holder`, or — without `holder` — the
 * one there is. In position order.
 */
function specSameAsBindings(refl, rootType) {
  const root = refl.model.roots.find((r) => r.type === rootType);
  const cls = refl.classNamed(rootType);
  if (root === undefined || cls === null) {
    return [];
  }
  const scope = { path: refl.rootSegment(root), cls, isListElement: false };
  const sections = _positions(refl, scope).filter(
    (p) => p.node.shape === 'section' && p.node.ownNode,
  );
  const out = [];
  for (const copy of sections) {
    const sameAs = copy.member !== null ? copy.member.sameAs : null;
    if (sameAs === null) {
      continue;
    }
    const type = copy.node.className;
    const holderTail = sameAs.holder !== null ? sameAs.holder.split('/') : null;
    const holders = sections.filter(
      (p) =>
        p.node.className === type &&
        (p.member === null || p.member.sameAs === null) &&
        (holderTail === null || _endsWith(p.ids, holderTail)),
    );
    const single = holders.length === 1 ? holders[0] : null;
    out.push(
      new SpecSameAsBinding({
        root: rootType,
        className: type,
        copyPath: copy.node.path,
        copySectionIds: copy.ids,
        holderPath: single !== null ? single.node.path : null,
        holderSectionIds: single !== null ? single.ids : null,
        problem:
          holders.length === 0
            ? SpecPlaceProblem.UNRESOLVED
            : holders.length > 1
              ? SpecPlaceProblem.AMBIGUOUS
              : null,
      }),
    );
  }
  return out;
}

/**
 * One position of a section in a document root: a class reached there (its
 * own node), or a member of a class that carries a section id of its own.
 */
class SpecSectionPosition {
  constructor(props) {
    /** The document path, list items written `<list>-*`. */
    this.path = props.path;
    /** The class reached ({@link member} null), or the class the member belongs to. */
    this.className = props.className;
    /** The section ids from the root to here, this position's own last. */
    this.sectionIds = props.sectionIds;
    /**
     * Whether this is a member position (a form, list, content or section member
     * with its own section id) rather than a class reached.
     */
    this.isMember = props.isMember;
    /**
     * For a class position, the member it is reached through (null at the
     * root); for a member position, the member itself.
     */
    this.member = props.member != null ? props.member : null;
  }
}

/**
 * Every section position of the document root `rootType`, in walk order: a
 * class reached again on its own path is not descended into, and a
 * `@Reference` member's target is not walked.
 */
function specSectionPositions(refl, rootType) {
  const root = refl.model.roots.find((r) => r.type === rootType);
  const cls = refl.classNamed(rootType);
  if (root === undefined || cls === null) {
    return [];
  }
  return _positions(refl, {
    path: refl.rootSegment(root),
    cls,
    isListElement: false,
  }).map(
    (p) =>
      new SpecSectionPosition({
        path: p.node.path,
        className: p.node.className,
        sectionIds: p.ids,
        member: p.member,
        isMember: !p.node.ownNode,
      }),
  );
}

// ---------------------------------------------------------------------------
// The positions of a subtree
// ---------------------------------------------------------------------------

function _scopeOf(refl, anchor, scoped, text) {
  const segs = specPathSegments(anchor);
  for (let n = segs.length; n >= 1; n--) {
    const path = segs.slice(0, n).join('/');
    const r = refl.resolve(path);
    if (n === segs.length && (r === null || r.targetClass === null)) {
      throw new SpecPlaceException(
        SpecPlaceProblem.ANCHOR_UNRESOLVED,
        text,
        `has the anchor ${anchor}, which resolves to no section`,
      );
    }
    const isItem = r !== null && r.kind === SpecNodeKind.LIST_ITEM_COMPLEX;
    if (!scoped || isItem) {
      // As in Dart (`r!.targetClass!`): an ancestor that resolves to no class
      // cannot be a scope.
      if (r === null || r.targetClass === null) {
        throw new TypeError(`no class at ${path}`);
      }
      return { path, cls: r.targetClass, isListElement: isItem };
    }
  }
  throw new SpecPlaceException(
    SpecPlaceProblem.NOT_SCOPED,
    text,
    `is \`./\`-scoped, but no list element lies at or above ${anchor}`,
  );
}

/**
 * Every addressable position beneath (and including) `scope`, in model order.
 * A class reached again on its own path is not descended into, and a
 * `@Reference` member is a place whose target is not walked.
 */
function _positions(refl, scope) {
  const out = [];

  const walk = (cls, path, ids, isItem, via, onPath) => {
    if (onPath.has(cls.name)) {
      return;
    }
    onPath.add(cls.name);
    const content = cls.fields.find((f) => f.name === 'content') || null;
    let here = ids;
    const ownId = cls.sectionId;
    if (ownId != null && ownId !== '') {
      here = [...ids, ownId];
      const contentSeg = content === null ? null : refl.fieldSegment(content);
      const contentIsForm = content !== null && content.kind === SpecFieldKind.FORM;
      const contentIsContent =
        content !== null && content.kind === SpecFieldKind.CONTENT;
      out.push({
        node: {
          id: ownId,
          path,
          className: cls.name,
          shape: 'section',
          ownNode: true,
          formFields: contentIsForm ? content.formFields : [],
          formPath: contentIsForm ? `${path}/${contentSeg}` : null,
          contentPath: contentIsContent ? `${path}/${contentSeg}` : null,
          isListElement: isItem,
        },
        ids: here,
        member: via,
      });
    }
    for (const field of cls.fields) {
      const seg = refl.fieldSegment(field);
      const memberPath = `${path}/${seg}`;
      const sid = field.sectionId;
      let below = here;
      if (field.name !== 'content' && sid != null && sid !== '') {
        below = [...here, sid];
        let shape;
        switch (field.kind) {
          case SpecFieldKind.LIST:
            shape = 'list';
            break;
          case SpecFieldKind.FORM:
            shape = 'form';
            break;
          case SpecFieldKind.COMPLEX:
          case SpecFieldKind.SECTION:
            shape = 'section';
            break;
          default:
            shape = 'content';
        }
        out.push({
          node: {
            id: sid,
            path: memberPath,
            className: cls.name,
            shape,
            ownNode: false,
            formFields: field.kind === SpecFieldKind.FORM ? field.formFields : [],
            formPath: field.kind === SpecFieldKind.FORM ? memberPath : null,
            contentPath: shape === 'content' ? memberPath : null,
            isListElement: false,
          },
          ids: below,
          member: field,
        });
      }
      if (field.hasAnnotation('Reference')) {
        continue;
      }
      if (field.kind === SpecFieldKind.LIST && field.elementIsComplex) {
        const el = refl.classNamed(field.elementType);
        if (el !== null) {
          walk(el, `${memberPath}-*`, below, true, field, onPath);
        }
      } else if (
        field.kind === SpecFieldKind.COMPLEX ||
        field.kind === SpecFieldKind.SECTION
      ) {
        const child = refl.classNamed(
          field.type != null ? field.type.split('?').join('') : null,
        );
        if (child !== null) {
          walk(child, memberPath, below, false, field, onPath);
        }
      }
    }
    onPath.delete(cls.name);
  };

  walk(scope.cls, scope.path, [], scope.isListElement, null, new Set());
  return out;
}

/**
 * Whether the `/` `segments` lead to a position whose ancestors are `path`:
 * they name every section on the way, leaving out only `-LST` containers and
 * the scope's own id. No segments: any position.
 */
function _pathMatches(path, segments) {
  if (segments.length === 0) {
    return true;
  }
  const from = (start) => {
    let j = 0;
    for (let i = start; i < path.length; i++) {
      if (j < segments.length && path[i] === segments[j]) {
        j++;
      } else if (!path[i].endsWith('-LST')) {
        return false;
      }
    }
    return j === segments.length;
  };
  return from(0) || (path.length > 0 && from(1));
}

/**
 * Whether `path` ends with exactly the ids of `tail`, as the static validator's
 * `SAME-AS` reads a holder.
 */
function _endsWith(path, tail) {
  if (path.length < tail.length) {
    return false;
  }
  for (let i = 0; i < tail.length; i++) {
    if (path[path.length - tail.length + i] !== tail[i]) {
      return false;
    }
  }
  return true;
}

module.exports = {
  SpecPlaceKind,
  SpecPlaceProblem,
  SpecPlaceException,
  SpecPlace,
  SpecPlaceResolution,
  SpecPlaceFilter,
  SpecSameAsBinding,
  specSameAsBindings,
  SpecSectionPosition,
  specSectionPositions,
};
