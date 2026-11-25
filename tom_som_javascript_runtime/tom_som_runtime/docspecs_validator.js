'use strict';

/**
 * DocSpecs markdown validation — a faithful port of
 * `tom_som_python_runtime/tom_som_runtime/docspecs_validator.py` (itself a port
 * of the Dart `docspecs_validator.dart`, Dart / JavaScript parity).
 *
 * Three cooperating pieces:
 *
 * 1. {@link DocSpecsDocument} — a schema-free structural parse of a DocSpecs
 *    markdown document into a heading tree (fence-aware, never throws).
 * 2. {@link DocSpecsSchema} — loader for `*.docspecs-schema.yaml` files with
 *    SOM §14-style warnings for unsupported keys (never fails on extra keys).
 * 3. {@link DocSpecsValidator} — never-fail-fast validation of a parsed
 *    document against a schema, emitting {@link DocSpecsViolation}s whose
 *    messages are golden-identical to the Dart implementation.
 *
 * Plus {@link bindDocspecsMarkdown}, which lands a DocSpecs markdown text in a
 *    typed {@link SpecDocument} via the SOM markdown codec.
 */

const { MarkdownFenceTracker, SpecDocumentMarkdown } = require('./spec_document_markdown');
const { scanNotation } = require('./spec_notation');
const yaml = require('./yaml');

/** The vocabulary of validation violation rules (Dart-parity names). */
const DocSpecsViolationRule = Object.freeze({
  UNKNOWN_SECTION: 'unknownSection',
  MISSING_REQUIRED_SECTION: 'missingRequiredSection',
  ID_PATTERN_MISMATCH: 'idPatternMismatch',
  TOO_FEW_ITEMS: 'tooFewItems',
  TOO_MANY_ITEMS: 'tooManyItems',
  MISSING_REQUIRED_FIELD: 'missingRequiredField',
  FIELD_PATTERN_MISMATCH: 'fieldPatternMismatch',
  TEXT_REQUIRED: 'textRequired',
  TEXT_LENGTH_OUT: 'textLengthOut',
  FORMAT_MISMATCH: 'formatMismatch',
  MALFORMED_HEADING: 'malformedHeading',
  /** A root child stands before a `document: sections:` slot taken earlier. */
  SECTION_OUT_OF_ORDER: 'sectionOutOfOrder',
  /** A section's id repeats an earlier sibling's: its id path is not unique. */
  DUPLICATE_ID_PATH: 'duplicateIdPath',
  // The reading notation's findings (DocSpecs specification, RN-10), reported
  // by scanNotation per value: a section's own body, and in a TomSpecs
  // rendition each form field's value apart.
  UNCLOSED_DIV: 'unclosedDiv',
  STRAY_CLOSING_FENCE: 'strayClosingFence',
  UNCLOSED_SPAN: 'unclosedSpan',
  DIV_WITHOUT_KIND: 'divWithoutKind',
  UNKNOWN_KIND: 'unknownKind',
  MARK_ACROSS_NOTATION: 'markAcrossNotation',
  ANNOTATION_INSIDE_DIV: 'annotationInsideDiv',
  DIV_INSIDE_ANNOTATION: 'divInsideAnnotation',
  REJECTED_BLOCK: 'rejectedBlock',
  // The reading view's list bodies and tables (DocSpecs specification,
  // Findings in list bodies and tables): a form, section or record table
  // without a matching delimiter row, a row of another cell count, a field
  // given twice (the first kept), a refs / records div beside other text or
  // item headings, a records div holding no table or one whose first column
  // is not Id, an unclosed refs / records fence.
  MALFORMED_BLOCK: 'malformedBlock',
  // A form-table row or a record-table column naming no field of its form.
  UNKNOWN_FIELD: 'unknownField',
});

/** One validation finding. */
class DocSpecsViolation {
  constructor(rule, line, message, sectionId = null, path = null) {
    this.rule = rule;
    this.line = line;
    this.message = message;
    this.sectionId = sectionId;
    this.path = path;
  }

  toString() {
    const sid = this.sectionId ? ` [${this.sectionId}]` : '';
    const p = this.path ? ` (${this.path})` : '';
    return `line ${this.line}: ${this.rule}${sid}${p} — ${this.message}`;
  }
}

/** One heading-delimited section of a schema-free document parse. */
class DocSpecsSection {
  constructor(id, title, level, line) {
    this.id = id;
    this.title = title;
    this.level = level;
    this.line = line;
    /** @type {string[]} raw body lines between this heading and the next. */
    this.bodyLines = [];
    /** @type {DocSpecsSection[]} */
    this.children = [];
  }

  /** 1-based line number of the first body line. */
  get bodyStartLine() {
    return this.line + 1;
  }

  /** Body text with leading/trailing blank lines trimmed. */
  get text() {
    const lines = this.bodyLines.slice();
    while (lines.length > 0 && lines[0].trim() === '') {
      lines.shift();
    }
    while (lines.length > 0 && lines[lines.length - 1].trim() === '') {
      lines.pop();
    }
    return lines.join('\n');
  }
}

const _DOCSPEC_HEADER = /^<!--\s*docspec:\s*(\S+)\s*-->\s*$/;
const _STYLED_DIV = /^<div class="heading([0-9]+)"[^>]*>(.*)<\/div>$/;
const _ANCHOR = /^<a id="([^"]*)"><\/a>\s*/;

/**
 * A styled-div heading (the DocSpecs specification's *Styled-div headings*):
 * a whole line `<div class="heading<N>" …>…</div>` at column 0 with N ≥ 7
 * reads as a heading of level N whose text is the div's inner text with
 * `&amp;`, `&lt;`, `&gt;` decoded. Returns [level, text], or null for any
 * other line — a `heading<N>` div with N ≤ 6 is content.
 */
function _styledDivHeading(line) {
  const m = _STYLED_DIV.exec(line);
  if (m == null) return null;
  const level = parseInt(m[1], 10);
  if (level < 7) return null;
  const text = m[2]
    .split('&lt;').join('<')
    .split('&gt;').join('>')
    .split('&amp;').join('&');
  return [level, text];
}

/**
 * `text` with a leading anchor `<a id="ID"></a>` removed when it is the
 * section's own (Section Anchors): its id is `id`, or the qualified form
 * `<A>/…/<id>` a heading below a list item carries. Any other anchor is
 * ordinary text and stays.
 */
function stripOwnAnchor(text, id) {
  const m = _ANCHOR.exec(text);
  return m != null && _isOwnAnchor(m[1], id) ? text.substring(m[0].length) : text;
}

/**
 * Whether `anchor` is the own anchor of a section with `id`: `id` itself, or
 * a qualified form `<A>/…/<id>` whose segments are all non-empty (Section
 * Anchors).
 */
function _isOwnAnchor(anchor, id) {
  if (anchor === id) return true;
  if (!anchor.endsWith(`/${id}`)) return false;
  return !anchor.split('/').some((s) => s === '');
}

/**
 * The number of leading lines of a section's `lines` that the rendition
 * writes from the document and that hold no value: a paragraph that is one
 * `linked` span (SOM §11.11), then a `derived` block (SOM §11.12), with the
 * blank lines around them (DocSpecs RN-5, *Not text*).
 */
function _generatedLead(lines) {
  const skipBlank = (i) => {
    while (i < lines.length && lines[i].trim() === '') i++;
    return i;
  };
  let i = skipBlank(0);
  let end = i;
  while (end < lines.length && lines[end].trim() !== '') end++;
  const para = lines.slice(i, end).join(' ').trim();
  if (end > i && /^\[.*\]\{\.linked\}$/.test(para)) {
    i = skipBlank(end);
  }
  const open =
    i < lines.length ? /^ {0,3}(:{3,})[ \t]*\{\.derived(?=[\s}])/.exec(lines[i]) : null;
  if (open !== null) {
    const close = new RegExp(`^ {0,3}:{${open[1].length},}[ \\t]*$`);
    let k = i + 1;
    while (k < lines.length && !close.test(lines[k])) k++;
    if (k < lines.length) i = skipBlank(k + 1);
  }
  return i;
}

/** `text` without its {@link _generatedLead}: what the text rules read. */
function _withoutGeneratedText(text) {
  const lines = text.split('\n');
  return lines.slice(_generatedLead(lines)).join('\n').trim();
}

/** A schema-free structural parse of a DocSpecs markdown document. */
class DocSpecsDocument {
  constructor() {
    /** @type {?string} */
    this.declaredSchema = null;
    /** @type {DocSpecsSection[]} top-level (root) sections. */
    this.sections = [];
    /** @type {DocSpecsViolation[]} structural findings from the parse. */
    this.violations = [];
  }

  /**
   * Parses `text` into a heading tree. Never throws — structural problems are
   * recorded as violations.
   *
   * @param {string} text
   * @returns {DocSpecsDocument}
   */
  static parse(text) {
    const doc = new DocSpecsDocument();
    const fence = new MarkdownFenceTracker();
    /** @type {DocSpecsSection[]} */
    const stack = [];
    const lines = text.split('\n');
    for (let idx = 0; idx < lines.length; idx += 1) {
      const raw = lines[idx];
      const lineNo = idx + 1;
      const line = raw.replace(/\s+$/, '');
      if (!fence.inFence) {
        if (stack.length === 0 && doc.declaredSchema == null) {
          const h = _DOCSPEC_HEADER.exec(line);
          if (h) {
            doc.declaredSchema = h[1];
            fence.feed(raw);
            continue;
          }
        }
        const m = SpecDocumentMarkdown.headingLine.exec(line);
        const div = m == null ? _styledDivHeading(line) : null;
        if (m || div) {
          const level = m ? m[1].length : div[0];
          const rest = m ? m[2] : div[1].trim();
          const c = SpecDocumentMarkdown.headlineComment.exec(rest);
          let section;
          if (c) {
            // The title without the section's own anchor (Section Anchors);
            // the heading-comment regex is 3-group (id, meta region, title).
            section = new DocSpecsSection(
              c[1] || null,
              stripOwnAnchor((c[3] || '').trim(), c[1]) || rest,
              level,
              lineNo,
            );
          } else {
            doc.violations.push(new DocSpecsViolation(
              DocSpecsViolationRule.MALFORMED_HEADING,
              lineNo,
              `heading "${rest}" carries no <!--[SECTION-ID]--> headline comment`,
            ));
            section = new DocSpecsSection(null, rest, level, lineNo);
          }
          while (stack.length > 0 && stack[stack.length - 1].level >= level) {
            stack.pop();
          }
          if (stack.length > 0) {
            stack[stack.length - 1].children.push(section);
          } else {
            doc.sections.push(section);
          }
          stack.push(section);
          fence.feed(raw);
          continue;
        }
      }
      if (stack.length > 0) {
        stack[stack.length - 1].bodyLines.push(raw);
      }
      fence.feed(raw);
    }
    return doc;
  }

  /**
   * Every section of the document, depth-first in document order (each
   * section before its children).
   *
   * @returns {DocSpecsSection[]}
   */
  get allSections() {
    const out = [];
    const walk = (list) => {
      for (const s of list) {
        out.push(s);
        walk(s.children);
      }
    };
    walk(this.sections);
    return out;
  }

  /**
   * Returns `text` with the body of the section whose id is `sectionId`
   * replaced by `body`; every other byte is kept.
   *
   * The body is the section's **own** region: the lines after its heading up
   * to its first child heading, or the next heading of any level. The heading
   * line (with its `<!--[ID]-->` comment) and the subsections are untouched.
   * The region is found by the same fence-aware {@link DocSpecsDocument.parse},
   * so a `#` line inside a fenced block is never taken for a heading.
   *
   * The new region is a blank line, `body` with its leading and trailing
   * blank lines removed, and a blank line; an empty `body` leaves a single
   * blank line. Throws an `Error` when `sectionId` names no section or more
   * than one, and when `body` would change the document's structure: a
   * heading outside a fenced block, or a fence it opens and never closes.
   *
   * @param {string} text
   * @param {string} sectionId
   * @param {string} body
   * @returns {string}
   */
  static replaceSectionBody(text, sectionId, body) {
    const matches = DocSpecsDocument.parse(text).allSections
      .filter((s) => s.id === sectionId);
    if (matches.length === 0) {
      throw new Error(`sectionId "${sectionId}" names no section`);
    }
    if (matches.length > 1) {
      throw new Error(
        `sectionId "${sectionId}" names ${matches.length} sections ` +
        `(lines ${matches.map((s) => s.line).join(', ')})`,
      );
    }

    let bodyLines = body.split('\n');
    while (bodyLines.length > 0 && bodyLines[0].trim() === '') {
      bodyLines = bodyLines.slice(1);
    }
    while (bodyLines.length > 0 && bodyLines[bodyLines.length - 1].trim() === '') {
      bodyLines = bodyLines.slice(0, -1);
    }
    const fence = new MarkdownFenceTracker();
    for (const line of bodyLines) {
      if (!fence.inFence &&
          SpecDocumentMarkdown.headingLine.test(line.replace(/\s+$/, ''))) {
        throw new Error(`body contains a heading outside a fenced block: "${line}"`);
      }
      fence.feed(line);
    }
    if (fence.inFence) {
      throw new Error('body leaves a fenced block open');
    }

    const section = matches[0];
    const lines = text.split('\n');
    const start = section.line; // 0-based index of the first body line
    const end = start + section.bodyLines.length;
    const region = bodyLines.length === 0 ? [''] : ['', ...bodyLines, ''];
    return [
      ...lines.slice(0, start),
      ...region,
      ...lines.slice(end),
    ].join('\n');
  }
}

/**
 * The DocSpecs id transform: every run of non-alphanumeric/underscore
 * characters becomes a single `_`.
 *
 * @param {string} id
 * @returns {string}
 */
function docSpecsIdTransform(id) {
  return id.replace(/[^a-zA-Z0-9_]+/g, '_');
}

/** A regex pattern check with an optional custom error message. */
class DocSpecsPatternCheck {
  constructor(pattern, errorMessage = null) {
    this.pattern = pattern;
    this.errorMessage = errorMessage;
  }

  matches(value) {
    return new RegExp(this.pattern).test(value);
  }
}

/** Occurrence bounds for one subsection type. `maxCount === null` = infinite. */
class DocSpecsSubsectionRule {
  constructor(minCount, maxCount) {
    this.minCount = minCount;
    this.maxCount = maxCount;
  }
}

/** One `section-types` entry of a schema. */
class DocSpecsSectionType {
  constructor({
    name,
    prefix,
    patternCheck = null,
    subsectionTypes = {},
    format = null,
    textRequired = false,
    minTextLength = null,
    maxTextLength = null,
    description = null,
    validationPrompt = null,
  }) {
    this.name = name;
    this.prefix = prefix;
    this.patternCheck = patternCheck;
    /** @type {Object<string, DocSpecsSubsectionRule>} */
    this.subsectionTypes = subsectionTypes;
    this.format = format;
    this.textRequired = textRequired;
    this.minTextLength = minTextLength;
    this.maxTextLength = maxTextLength;
    this.description = description;
    this.validationPrompt = validationPrompt;
  }
}

/** One field of a `form-types` entry. */
class DocSpecsFormField {
  constructor({ name, required = false, description = null, patternCheck = null }) {
    this.name = name;
    this.required = required;
    this.description = description;
    this.patternCheck = patternCheck;
  }
}

/** One `form-types` entry of a schema. */
class DocSpecsFormType {
  constructor(name, fields) {
    this.name = name;
    /** @type {DocSpecsFormField[]} */
    this.fields = fields;
  }
}

/**
 * One `document.sections` slot of a schema: the backing section-type, whether
 * the slot is optional, and its `position` — `relative` (the default: in the
 * order of `document: sections:`) or `any` (anywhere among the root's
 * children; the order check leaves it out).
 */
class DocSpecsDocumentSection {
  constructor(sectionType, optional, position = 'relative') {
    this.sectionType = sectionType;
    this.optional = optional;
    this.position = position;
  }

  /** Whether the section may stand anywhere among the root's children. */
  get anyPosition() {
    return this.position === 'any';
  }
}

/** The `position` values a document section may take. */
DocSpecsDocumentSection.POSITIONS = Object.freeze(['relative', 'any']);

/** `true` for a real boolean or the plain-scalar string form. */
function _isTrue(v) {
  // The bundled yaml parser keeps plain `true`/`false` as strings; accept
  // both so schema flags behave like PyYAML/package:yaml booleans.
  return v === true || v === 'true';
}

/** `true` when `v` is an integer value. */
function _isInt(v) {
  return typeof v === 'number' && Number.isInteger(v);
}

function _isPlainObject(v) {
  return v != null && typeof v === 'object' && !Array.isArray(v);
}

const _SECTION_TYPE_KEYS = new Set([
  'prefix',
  'pattern-check-id',
  'subsection-types',
  'format',
  'text-required',
  'min-text-length',
  'max-text-length',
  'description',
  'validation-prompt',
]);

/** A loaded `*.docspecs-schema.yaml` schema. */
class DocSpecsSchema {
  constructor() {
    /** @type {?string} */
    this.titleFormat = null;
    /** @type {DocSpecsSectionType[]} in file order. */
    this.sectionTypes = [];
    /** @type {Object<string, DocSpecsSectionType>} */
    this.sectionTypesByName = {};
    /** @type {Object<string, DocSpecsFormType>} */
    this.formTypes = {};
    /** @type {Object<string, DocSpecsDocumentSection>} */
    this.documentSections = {};
    /** @type {string[]} SOM §14 warnings for unsupported keys. */
    this.warnings = [];
  }

  /** The section id embedded in `title-format`, or null. */
  get rootSectionId() {
    if (!this.titleFormat) {
      return null;
    }
    const m = /<!--\[([^\]]+)\]-->/.exec(this.titleFormat);
    return m ? m[1] : null;
  }

  /**
   * Loads a schema from YAML text. Unknown keys warn; a non-map root throws.
   *
   * @param {string} text
   * @returns {DocSpecsSchema}
   */
  static fromYamlText(text) {
    const data = yaml.parse(text);
    if (!_isPlainObject(data)) {
      throw new Error('docspecs schema must be a YAML map');
    }
    const schema = new DocSpecsSchema();
    for (const [k, v] of Object.entries(data)) {
      if (k === 'title-format') {
        schema.titleFormat = String(v);
      } else if (k === 'section-types') {
        schema._loadSectionTypes(v);
      } else if (k === 'form-types') {
        schema._loadFormTypes(v);
      } else if (k === 'document') {
        schema._loadDocument(v);
      } else if (k === 'schema' || k === 'version' || k === 'name' || k === 'description') {
        // informational keys — accepted, unused
      } else {
        schema.warnings.push(`unsupported top-level schema key "${k}" ignored`);
      }
    }
    return schema;
  }

  static _patternCheck(node) {
    if (node == null) {
      return null;
    }
    if (_isPlainObject(node)) {
      return new DocSpecsPatternCheck(
        String(node.pattern),
        node['error-message'] != null ? String(node['error-message']) : null,
      );
    }
    return new DocSpecsPatternCheck(String(node));
  }

  _loadSectionTypes(node) {
    if (!_isPlainObject(node)) {
      return;
    }
    for (const [name, raw] of Object.entries(node)) {
      if (!_isPlainObject(raw)) {
        continue;
      }
      /** @type {Object<string, DocSpecsSubsectionRule>} */
      const subs = {};
      const subNode = raw['subsection-types'];
      if (_isPlainObject(subNode)) {
        for (const [subName, subRaw] of Object.entries(subNode)) {
          let minCount = 0;
          let maxCount = null;
          if (_isPlainObject(subRaw)) {
            const minRaw = subRaw['min-count'];
            const maxRaw = subRaw['max-count'];
            if (_isInt(minRaw)) {
              minCount = minRaw;
            }
            if (_isInt(maxRaw)) {
              maxCount = maxRaw;
            }
          }
          subs[subName] = new DocSpecsSubsectionRule(minCount, maxCount);
        }
      }
      for (const key of Object.keys(raw)) {
        if (!_SECTION_TYPE_KEYS.has(key)) {
          this.warnings.push(
            `unsupported key "${key}" on section-type "${name}" ignored`,
          );
        }
      }
      const prefix = raw.prefix != null
        ? String(raw.prefix)
        : docSpecsIdTransform(name.toUpperCase());
      const type = new DocSpecsSectionType({
        name,
        prefix,
        patternCheck: DocSpecsSchema._patternCheck(raw['pattern-check-id']),
        subsectionTypes: subs,
        format: raw.format != null ? String(raw.format) : null,
        textRequired: _isTrue(raw['text-required']),
        minTextLength: _isInt(raw['min-text-length']) ? raw['min-text-length'] : null,
        maxTextLength: _isInt(raw['max-text-length']) ? raw['max-text-length'] : null,
        description: raw.description != null ? String(raw.description) : null,
        validationPrompt: raw['validation-prompt'] != null ? String(raw['validation-prompt']) : null,
      });
      this.sectionTypes.push(type);
      this.sectionTypesByName[name] = type;
    }
  }

  _loadFormTypes(node) {
    if (!_isPlainObject(node)) {
      return;
    }
    for (const [name, raw] of Object.entries(node)) {
      if (!_isPlainObject(raw)) {
        continue;
      }
      for (const key of Object.keys(raw)) {
        if (key !== 'fields') {
          this.warnings.push(
            `unsupported key "${key}" on form-type "${name}" ignored`,
          );
        }
      }
      /** @type {DocSpecsFormField[]} */
      const fields = [];
      const fieldsNode = raw.fields;
      if (Array.isArray(fieldsNode)) {
        for (const f of fieldsNode) {
          if (!_isPlainObject(f)) {
            continue;
          }
          fields.push(new DocSpecsFormField({
            name: String(f.fieldname),
            required: _isTrue(f.required),
            description: f.description != null ? String(f.description) : null,
            patternCheck: DocSpecsSchema._patternCheck(f['pattern-check']),
          }));
        }
      }
      this.formTypes[name] = new DocSpecsFormType(name, fields);
    }
  }

  _loadDocument(node) {
    if (!_isPlainObject(node)) {
      return;
    }
    for (const [k, v] of Object.entries(node)) {
      if (k === 'sections') {
        if (_isPlainObject(v)) {
          for (const [sKey, sRaw] of Object.entries(v)) {
            let sectionType;
            let optional;
            let position = 'relative';
            if (_isPlainObject(sRaw)) {
              sectionType = String(sRaw['section-type'] != null ? sRaw['section-type'] : sKey);
              optional = _isTrue(sRaw.optional);
              if (sRaw.position != null) {
                position = String(sRaw.position);
                if (!DocSpecsDocumentSection.POSITIONS.includes(position)) {
                  throw new Error(
                    `document section "${sKey}": position "${position}" is not one of relative, any`,
                  );
                }
              }
            } else {
              sectionType = String(sKey);
              optional = false;
            }
            this.documentSections[sKey] = new DocSpecsDocumentSection(sectionType, optional, position);
          }
        }
      } else if (k !== 'name' && k !== 'description') {
        this.warnings.push(`unsupported document key "${k}" ignored`);
      }
    }
  }

  /**
   * Resolves a section id to its section-type by first-startsWith prefix
   * match over {@link docSpecsIdTransform}'d ids.
   *
   * @param {string} id
   * @returns {?DocSpecsSectionType}
   */
  resolveSectionType(id) {
    const transformed = docSpecsIdTransform(id);
    for (const t of this.sectionTypes) {
      if (transformed.startsWith(t.prefix)) {
        return t;
      }
    }
    return null;
  }
}

const _FIELD_LABEL = /^([A-Za-z][A-Za-z0-9_]*): ?(.*)$/;

/** A line that starts a table row: `|` after up to three spaces. */
const _TABLE_LINE = /^ {0,3}\|/;
const _DELIMITER_CELL = /^:?-+:?$/;
const _LINK_CELL = /^\[[^\]]+\]\([^)]*\)(, \[[^\]]+\]\([^)]*\))*$/;
const _LINK_TEXT = /\[([^\]]+)\]\([^)]*\)/;
const _LINK_TEXT_ALL = /\[([^\]]+)\]\([^)]*\)/g;
const _CELL_ANCHOR = /<a id="([^"]*)"><\/a>\s*/g;
const _CELL_PART_SEPARATOR = /\s*\/\s*/;
const _CELL_LINK = /\[([^\]]+)\]\([^)\s]*\)/g;
const _LIST_DIV_OPEN = /^:{3,}\s*(?:\{\.(refs|records)\}|(refs|records))\s*$/;
const _DIV_CLOSE = /^:{3,}\s*$/;

/**
 * A section as the validator walks it: a parsed {@link DocSpecsSection}, or a
 * virtual one rebuilt from a list body or a section table (the DocSpecs
 * specification's *List Bodies*). The body is a copy, so blanking a table or
 * div never touches the parsed document.
 */
class _Node {
  constructor(id, line, body, type = null) {
    this.id = id;
    /** The heading's line, or the row's or div's line of a virtual section. */
    this.line = line;
    /** The own body lines; a list body or section table already read is blank. */
    this.body = body;
    /** The section-type of a virtual list item, given by the schema. */
    this.type = type;
    /** @type {_Node[]} */
    this.children = [];
    /** Form values given by a table row or a list body: [label, value, line]. */
    this.values = [];
  }

  /** The walk's view of a parsed section and its subtree. */
  static of(s) {
    const n = new _Node(s.id, s.line, s.bodyLines.slice());
    for (const c of s.children) n.children.push(_Node.of(c));
    return n;
  }

  /** A virtual section at `line`, with no body. */
  static virtual(id, line, type) {
    return new _Node(id, line, [], type);
  }

  get bodyStartLine() {
    return this.line + 1;
  }

  /**
   * The trimmed body text, after the virtual body lines of `values` — the
   * text the same section has in the fields layout, where a section without a
   * form in the schema carries its values as `FieldName:` lines.
   */
  get text() {
    const lines = [
      ...this.values.map(([label, value]) => (label === '' ? value : `${label}: ${value}`)),
      ...this.body,
    ];
    while (lines.length > 0 && lines[0].trim() === '') lines.shift();
    while (lines.length > 0 && lines[lines.length - 1].trim() === '') lines.pop();
    return lines.join('\n');
  }
}

/**
 * The cells of a table row: split on every `|` not preceded by a backslash,
 * the outer pipes dropped, each cell trimmed; `\|` stays in the cell.
 */
function _rowCells(line) {
  let t = line.trim();
  if (t.startsWith('|')) t = t.substring(1);
  if (t.endsWith('|') && !t.endsWith('\\|')) t = t.substring(0, t.length - 1);
  const cells = [];
  let b = '';
  for (let i = 0; i < t.length; i++) {
    const c = t[i];
    if (c === '\\' && i + 1 < t.length && t[i + 1] === '|') {
      b += '\\|';
      i++;
    } else if (c === '|') {
      cells.push(b.trim());
      b = '';
    } else {
      b += c;
    }
  }
  cells.push(b.trim());
  return cells;
}

/** A value cell's value: `\|` unescaped, a cell of links read as their texts. */
function _cellValue(cell) {
  const text = cell.split('\\|').join('|');
  if (_LINK_CELL.test(text)) {
    return Array.from(text.matchAll(_LINK_TEXT_ALL), (m) => m[1]).join(', ');
  }
  return text;
}

/**
 * An `Id` or `Section` cell with its own anchors (`<a id="X"></a>X`) removed
 * (Section Anchors): in a `<LIST> / <ITEM>` cell each part's anchor, and one
 * before the whole cell naming its item. Any other anchor stays.
 */
function _cellId(cell) {
  // A summary row's id written as a link is read as its text (SOM §11.5).
  cell = cell.replace(_CELL_LINK, (_m, t) => t);
  let out = '';
  let pos = 0;
  for (const m of cell.matchAll(_CELL_ANCHOR)) {
    const start = m.index ?? 0;
    const end = start + m[0].length;
    out += cell.substring(pos, start);
    const id = m[1];
    const rest = cell.substring(end).split(_CELL_PART_SEPARATOR);
    const own =
      _isOwnAnchor(id, rest[0].trim()) ||
      (start === 0 && _isOwnAnchor(id, rest[rest.length - 1].trim()));
    if (!own) out += m[0];
    pos = end;
  }
  return out + cell.substring(pos);
}

/** Never-fail-fast validator of a parsed document against a schema. */
class DocSpecsValidator {
  /**
   * @param {DocSpecsSchema} schema
   * @param {{tomSpecs?: boolean}} [options] `tomSpecs`: the documents are
   *   TomSpecs renditions — the reading notation is then scanned value by
   *   value (a form field's value apart from the next), and a div without a
   *   class and an unregistered kind are reported too.
   */
  constructor(schema, options = {}) {
    this.schema = schema;
    this.tomSpecs = options.tomSpecs === true;
  }

  /**
   * Convenience: parse + validate in one step.
   *
   * @param {string} markdown
   * @returns {DocSpecsViolation[]}
   */
  validateMarkdown(markdown) {
    return this.validate(DocSpecsDocument.parse(markdown));
  }

  /**
   * Validates a parsed document, returning ALL findings (never fail-fast).
   *
   * @param {DocSpecsDocument} doc
   * @returns {DocSpecsViolation[]}
   */
  validate(doc) {
    /** @type {DocSpecsViolation[]} */
    const v = doc.violations.slice();
    if (doc.sections.length === 0) {
      v.push(new DocSpecsViolation(
        DocSpecsViolationRule.FORMAT_MISMATCH,
        1,
        'document has no root heading',
      ));
      return v;
    }
    const root = doc.sections[0];
    const rootId = this.schema.rootSectionId;
    if (rootId != null && root.id !== rootId) {
      v.push(new DocSpecsViolation(
        DocSpecsViolationRule.FORMAT_MISMATCH,
        root.line,
        `root heading id "${root.id}" does not match the schema title-format id "${rootId}"`,
        root.id,
      ));
    }
    for (const extra of doc.sections.slice(1)) {
      v.push(new DocSpecsViolation(
        DocSpecsViolationRule.UNKNOWN_SECTION,
        extra.line,
        'unexpected additional top-level section',
        extra.id,
      ));
    }
    this._validateDocumentSections(_Node.of(root), v);
    this._validateNotation(doc, v);
    this._validateIdPaths(doc.sections, v);
    return v;
  }

  /**
   * The reading notation of every section's own body: one value per section,
   * and in a TomSpecs rendition one per form field of a form-formatted
   * section (its preamble included).
   */
  _validateNotation(doc, v) {
    for (const section of doc.allSections) {
      for (const [first, lines] of this._notationValues(section)) {
        const scan = scanNotation(lines.join('\n'), { tomSpecs: this.tomSpecs });
        for (const f of scan.findings) {
          v.push(new DocSpecsViolation(
            f.code,
            section.bodyStartLine + first + f.line - 1,
            f.message,
            section.id,
          ));
        }
      }
    }
  }

  /** The values of a section's own body as [index of the first line, lines]. */
  _notationValues(section) {
    const body = section.bodyLines;
    const type =
      this.tomSpecs && section.id != null
        ? this.schema.resolveSectionType(section.id)
        : null;
    const form =
      type != null && type.format != null ? this.schema.formTypes[type.format] : undefined;
    if (form === undefined) return [[0, body]];
    const labels = new Set(form.fields.map((f) => f.name.toLowerCase()));
    const values = [];
    const fence = new MarkdownFenceTracker();
    let first = 0;
    for (let i = 0; i < body.length; i++) {
      if (!fence.inFence && i > first) {
        const m = _FIELD_LABEL.exec(body[i]);
        if (m != null && labels.has(m[1].toLowerCase())) {
          values.push([first, body.slice(first, i)]);
          first = i;
        }
      }
      fence.feed(body[i]);
    }
    values.push([first, body.slice(first)]);
    return values;
  }

  /**
   * Every section's id path (the ids from the root down to it) is unique: a
   * section whose id repeats an earlier sibling's is a `duplicateIdPath`. Its
   * descendants repeat paths only through it and are not reported again.
   * Sections without an id are skipped (already `malformedHeading`).
   * Depth-first, source order.
   */
  _validateIdPaths(sections, v) {
    const seen = new Set();
    for (const s of sections) {
      if (s.id != null) {
        if (seen.has(s.id)) {
          v.push(new DocSpecsViolation(
            DocSpecsViolationRule.DUPLICATE_ID_PATH,
            s.line,
            `section id "${s.id}" repeats a sibling's id, so its id path is not unique`,
            s.id,
          ));
          continue;
        }
        seen.add(s.id);
      }
      this._validateIdPaths(s.children, v);
    }
  }

  /**
   * The order check of one root child: its slot is the first of its type at
   * or after the last slot taken, else the first of its type anywhere; a slot
   * before the last one taken is `sectionOutOfOrder`. Answers the last slot
   * taken afterwards.
   */
  static _checkOrder(child, typeName, order, lastIndex, v) {
    let index = -1;
    for (let i = Math.max(lastIndex, 0); i < order.length; i++) {
      if (order[i] === typeName) {
        index = i;
        break;
      }
    }
    if (index === -1) {
      index = order.indexOf(typeName);
    }
    if (index === -1) {
      return lastIndex;
    }
    if (index < lastIndex) {
      v.push(new DocSpecsViolation(
        DocSpecsViolationRule.SECTION_OUT_OF_ORDER,
        child.line,
        `section "${child.id}" (type "${typeName}") stands out of the order of the document sections`,
        child.id,
      ));
      return lastIndex;
    }
    return index;
  }

  _resolveChild(section, v) {
    if (section.type != null) {
      return section.type; // a virtual list item: the schema's type.
    }
    if (section.id == null) {
      return null; // already reported as MALFORMED_HEADING by the parse.
    }
    const type = this.schema.resolveSectionType(section.id);
    if (type == null) {
      v.push(new DocSpecsViolation(
        DocSpecsViolationRule.UNKNOWN_SECTION,
        section.line,
        `section id "${section.id}" resolves to no section-type of the schema`,
        section.id,
      ));
    }
    return type;
  }

  /**
   * Root children must occupy `document: sections:` slots, in their order (a
   * `position: any` slot's type stands anywhere); required slots must be
   * present. A section table in the root's body rebuilds root children as
   * virtual sections first.
   */
  _validateDocumentSections(root, v) {
    /** Occurrences per section-type name. */
    const counts = {};
    const slotTypes = new Set(
      Object.values(this.schema.documentSections).map((s) => s.sectionType),
    );
    this._expandSectionTables(root, (t) => slotTypes.has(t.name), v);
    const slots = Object.values(this.schema.documentSections);
    const anywhere = new Set(slots.filter((s) => s.anyPosition).map((s) => s.sectionType));
    const order = slots.map((s) => (s.anyPosition ? null : s.sectionType));
    let lastIndex = -1;
    for (const child of root.children) {
      const type = this._resolveChild(child, v);
      if (type == null) {
        continue;
      }
      if (!slotTypes.has(type.name)) {
        v.push(new DocSpecsViolation(
          DocSpecsViolationRule.UNKNOWN_SECTION,
          child.line,
          `section-type "${type.name}" is not a top-level document section`,
          child.id,
        ));
        continue;
      }
      if (!anywhere.has(type.name)) {
        lastIndex = DocSpecsValidator._checkOrder(child, type.name, order, lastIndex, v);
      }
      counts[type.name] = (counts[type.name] || 0) + 1;
      this._validateSection(child, type, v);
    }
    for (const [slotKey, slot] of Object.entries(this.schema.documentSections)) {
      const count = counts[slot.sectionType] || 0;
      if (!slot.optional && count === 0) {
        v.push(new DocSpecsViolation(
          DocSpecsViolationRule.MISSING_REQUIRED_SECTION,
          root.line,
          `required document section "${slotKey}" (type "${slot.sectionType}") is missing`,
          slotKey,
        ));
      }
    }
  }

  _validateSection(section, type, v) {
    const pc = type.patternCheck;
    if (pc != null && section.id != null && !pc.matches(section.id)) {
      v.push(new DocSpecsViolation(
        DocSpecsViolationRule.ID_PATTERN_MISMATCH,
        section.line,
        pc.errorMessage != null
          ? pc.errorMessage
          : `section id "${section.id}" does not match pattern "${pc.pattern}"`,
        section.id,
      ));
    }
    // List bodies and section tables become virtual sections before anything
    // is counted or checked (DocSpecs specification, List Bodies).
    this._expandSectionTables(section, (t) => t.name in type.subsectionTypes, v);
    this._expandListBody(section, type, v);
    this._validateText(section, type, v);
    this._validateFormat(section, type, v);
    /** Occurrences per subsection type name. */
    const counts = {};
    for (const child of section.children) {
      const childType = this._resolveChild(child, v);
      if (childType == null) {
        continue;
      }
      if (!(childType.name in type.subsectionTypes)) {
        v.push(new DocSpecsViolation(
          DocSpecsViolationRule.UNKNOWN_SECTION,
          child.line,
          `section-type "${childType.name}" is not an allowed subsection of "${type.name}"`,
          child.id,
        ));
        continue;
      }
      counts[childType.name] = (counts[childType.name] || 0) + 1;
      this._validateSection(child, childType, v);
    }
    // The offending section is the CONTAINER, not the absent child: a
    // cardinality breach has no child occurrence to point at, and `subKey` is
    // a schema type name, not a section id. Dart is the golden reference here.
    for (const [subKey, rule] of Object.entries(type.subsectionTypes)) {
      const count = counts[subKey] || 0;
      if (count < rule.minCount) {
        if (count === 0) {
          v.push(new DocSpecsViolation(
            DocSpecsViolationRule.MISSING_REQUIRED_SECTION,
            section.line,
            `required subsection "${subKey}" of "${type.name}" is missing`,
            section.id,
          ));
        } else {
          v.push(new DocSpecsViolation(
            DocSpecsViolationRule.TOO_FEW_ITEMS,
            section.line,
            `subsection "${subKey}" occurs ${count} time(s), minimum is ${rule.minCount}`,
            section.id,
          ));
        }
      }
      if (rule.maxCount != null && count > rule.maxCount) {
        v.push(new DocSpecsViolation(
          DocSpecsViolationRule.TOO_MANY_ITEMS,
          section.line,
          `subsection "${subKey}" occurs ${count} time(s), maximum is ${rule.maxCount}`,
          section.id,
        ));
      }
    }
  }

  _validateText(section, type, v) {
    if (type.format != null && type.format in this.schema.formTypes) {
      return; // form sections carry fields, not body text.
    }
    // A list body or section table already read is blanked in the body, so a
    // container written with one counts as empty (`max-text-length: 0`); the
    // rendition's marker and generated block are no text either.
    const text = _withoutGeneratedText(section.text);
    if (type.textRequired && text.length === 0) {
      v.push(new DocSpecsViolation(
        DocSpecsViolationRule.TEXT_REQUIRED,
        section.line,
        'section requires body text but has none',
        section.id,
      ));
      return;
    }
    if (text.length === 0) return;
    const len = text.length;
    const min = type.minTextLength;
    const max = type.maxTextLength;
    if ((min != null && len < min) || (max != null && len > max)) {
      v.push(new DocSpecsViolation(
        DocSpecsViolationRule.TEXT_LENGTH_OUT,
        section.line,
        `body text length ${len} is outside [${min != null ? min : 0}, ${max != null ? max : '∞'}]`,
        section.id,
      ));
    }
  }

  _validateFormat(section, type, v) {
    const format = type.format;
    // Values a section table or list body gave a section the schema declares
    // no form for are virtual body lines, counted in its text (_Node.text).
    if (format == null) {
      return;
    }
    const form = this.schema.formTypes[format];
    if (form != null) {
      this._validateForm(section, form, v);
      return;
    }
    const fence = new MarkdownFenceTracker();
    let sawFence = false;
    for (const raw of section.body) {
      fence.feed(raw);
      if (fence.inFence) {
        sawFence = true;
      }
    }
    if (!sawFence) {
      v.push(new DocSpecsViolation(
        DocSpecsViolationRule.FORMAT_MISMATCH,
        section.line,
        `section format "${format}" demands a fenced code block, but the body contains none`,
        section.id,
      ));
    }
  }

  /**
   * Parses the section body in the DocSpecs plain-text form format
   * (`FieldName: value`, case-insensitive labels, continuation lines) and its
   * form tables (`TomSpecField | Value`), takes the values a section table or
   * list body gave the section, and checks required fields + field
   * pattern-checks. A field given twice keeps its first occurrence and
   * reports the second (`malformedBlock`): a `Field:` label counts as given
   * even with an empty value, a row only with a value. A row naming no field
   * is `unknownField`.
   */
  _validateForm(section, form, v) {
    /** Lowered name → field. */
    const byLower = {};
    for (const f of form.fields) {
      byLower[f.name.toLowerCase()] = f;
    }
    /** Every occurrence as [label, value, line, from a `Field:` label]. */
    const occurrences = [];
    const fence = new MarkdownFenceTracker();
    const body = section.body;
    let current = null;
    let currentLine = 0;
    let currentLines = [];
    const flush = () => {
      if (current == null) return;
      occurrences.push([current, currentLines.join('\n').trim(), currentLine, true]);
      current = null;
      currentLines = [];
    };
    for (let i = 0; i < body.length; i += 1) {
      const raw = body[i];
      if (!fence.inFence) {
        const header = SpecDocumentMarkdown.layoutTableHeader.exec(raw);
        if (header != null && header[1] == null) {
          // A form table ends the open field; its rows are fields.
          flush();
          const table = this._readTable(body, i, (k) => section.bodyStartLine + k, section.id, v);
          for (const [k, cells] of table.rows) {
            occurrences.push([cells[0], _cellValue(cells[1]), section.bodyStartLine + k, false]);
          }
          i = table.end - 1;
          continue;
        }
        const m = _FIELD_LABEL.exec(raw);
        if (m) {
          const lowered = m[1].toLowerCase();
          if (lowered in byLower) {
            flush();
            current = byLower[lowered].name;
            currentLine = section.bodyStartLine + i;
            currentLines = [m[2]];
            fence.feed(raw);
            continue;
          }
        }
      }
      if (current != null) {
        currentLines.push(raw);
      }
      fence.feed(raw);
    }
    flush();
    for (const [label, value, line] of section.values) {
      occurrences.push([label, value, line, false]);
    }
    // Source order decides which occurrence is the first; values from a
    // parent's section table stand above the section's own body.
    const ordered = occurrences
      .map((o, k) => [k, o])
      .sort((a, b) => a[1][2] - b[1][2] || a[0] - b[0]);

    /** Field name → value. */
    const values = {};
    /** Field name → 1-based line of the occurrence kept. */
    const fieldLines = {};
    const given = new Set();
    for (const [, [label, value, line, fromLabel]] of ordered) {
      const field = byLower[label.toLowerCase()];
      if (field === undefined) {
        v.push(new DocSpecsViolation(
          DocSpecsViolationRule.UNKNOWN_FIELD,
          line,
          `row "${label}" names no field of "${form.name}"`,
          section.id,
        ));
        continue;
      }
      if (!fromLabel && value.length === 0) continue;
      if (given.has(field.name)) {
        v.push(new DocSpecsViolation(
          DocSpecsViolationRule.MALFORMED_BLOCK,
          line,
          `field "${field.name}" given twice`,
          section.id,
        ));
        continue;
      }
      given.add(field.name);
      fieldLines[field.name] = line;
      if (value.length > 0) values[field.name] = value;
    }
    for (const field of form.fields) {
      const value = values[field.name] ?? '';
      if (field.required && value.length === 0) {
        v.push(new DocSpecsViolation(
          DocSpecsViolationRule.MISSING_REQUIRED_FIELD,
          section.line,
          `required form field "${field.name}" of "${form.name}" is missing`,
          section.id,
        ));
        continue;
      }
      const pc = field.patternCheck;
      if (pc != null && value.length > 0 && !pc.matches(value)) {
        v.push(new DocSpecsViolation(
          DocSpecsViolationRule.FIELD_PATTERN_MISMATCH,
          fieldLines[field.name] != null ? fieldLines[field.name] : section.line,
          pc.errorMessage != null
            ? pc.errorMessage
            : `form field "${field.name}" does not match pattern "${pc.pattern}"`,
          section.id,
        ));
      }
    }
  }

  // --- Tables and list bodies (DocSpecs specification, List Bodies) --------

  /**
   * Reads the table whose header is `lines[start]`: the header cells, the
   * body rows with their line indexes, and the index after the table. A
   * missing or mismatched delimiter row is a `malformedBlock` at the header
   * and the table yields no rows; a row of another cell count is a
   * `malformedBlock` at that row and is left out.
   */
  _readTable(lines, start, lineOf, sectionId, v) {
    let end = start + 1;
    while (end < lines.length && _TABLE_LINE.test(lines[end])) end++;
    const header = _rowCells(lines[start]);
    const delimiter = start + 1 < end ? _rowCells(lines[start + 1]) : null;
    const delimiterOk = delimiter != null && delimiter.every((c) => _DELIMITER_CELL.test(c));
    if (!delimiterOk || delimiter.length !== header.length) {
      v.push(new DocSpecsViolation(
        DocSpecsViolationRule.MALFORMED_BLOCK,
        lineOf(start),
        delimiterOk
          ? 'table whose delimiter row does not match its header'
          : 'table without its delimiter row',
        sectionId,
      ));
      return { header, rows: [], end };
    }
    const rows = [];
    for (let i = start + 2; i < end; i++) {
      const cells = _rowCells(lines[i]);
      if (cells.length !== header.length) {
        v.push(new DocSpecsViolation(
          DocSpecsViolationRule.MALFORMED_BLOCK,
          lineOf(i),
          `table row with ${cells.length} cells, the header has ${header.length}`,
          sectionId,
        ));
        continue;
      }
      rows.push([i, cells]);
    }
    return { header, rows, end };
  }

  /**
   * Reads every section table of `node`'s body (header
   * `Section | TomSpecField | Value`): each row's `Section` cell names a child
   * — by its id relative to `node`, a list item as `<LIST> / <ITEM>`, an empty
   * cell the row above's — and its `TomSpecField` / `Value` cells become that
   * child's form values. A child without a heading becomes a virtual section;
   * one whose id resolves to no type `allowed` under `node` is
   * `unknownSection` at the row, and its rows are skipped. The table's lines
   * are blanked.
   */
  _expandSectionTables(node, allowed, v) {
    const body = node.body;
    const fence = new MarkdownFenceTracker();
    const lineOf = (k) => node.bodyStartLine + k;
    for (let i = 0; i < body.length; i++) {
      const line = body[i];
      const h = fence.inFence ? null : SpecDocumentMarkdown.layoutTableHeader.exec(line);
      if (h == null || h[1] == null) {
        fence.feed(line);
        continue;
      }
      const table = this._readTable(body, i, lineOf, node.id, v);
      let target = null;
      let skip = false;
      for (const [k, cells] of table.rows) {
        const cell = _cellId(cells[0]);
        if (cell.length > 0) {
          target = this._sectionTableTarget(node, cell, allowed, lineOf(k));
          skip = target == null;
          if (target == null) {
            v.push(new DocSpecsViolation(
              DocSpecsViolationRule.UNKNOWN_SECTION,
              lineOf(k),
              `section-table row names no child section of "${node.id}"`,
              cell,
            ));
            continue;
          }
        } else if (skip) {
          continue; // the rejected child's further rows
        } else if (target == null) {
          v.push(new DocSpecsViolation(
            DocSpecsViolationRule.UNKNOWN_SECTION,
            lineOf(k),
            'section-table row names no section',
            node.id,
          ));
          continue;
        }
        target.values.push([cells[1], _cellValue(cells[2]), lineOf(k)]);
      }
      for (let k = i; k < table.end; k++) body[k] = '';
      i = table.end - 1;
    }
  }

  /**
   * The child a section-table `Section` cell names under `node`: a child
   * section by its id, or `<LIST> / <ITEM>` — an item of a child list. A child
   * or item without a heading is created as a virtual section when its id
   * resolves to a type allowed where it stands; `null` otherwise.
   */
  _sectionTableTarget(node, cell, allowed, line) {
    const parts = cell.split(_CELL_PART_SEPARATOR);
    if (parts.length > 2) return null;
    const child = (parent, id, ok) => {
      for (const c of parent.children) {
        if (c.id === id) return c;
      }
      const t = this.schema.resolveSectionType(id);
      if (t == null || !ok(t)) return null;
      const created = _Node.virtual(id, line, null);
      parent.children.push(created);
      return created;
    };
    const first = child(node, parts[0], allowed);
    if (parts.length === 1 || first == null) return first;
    const listType = first.type ?? this.schema.resolveSectionType(parts[0]);
    if (listType == null) return null;
    return child(first, parts[1], (t) => t.name in listType.subsectionTypes);
  }

  /**
   * A list container's body: one `refs` div (a reference line) or one
   * `records` div (a record table) stands for its items when the container
   * has no item heading; the items become virtual sections of the container's
   * one subsection type, and the div's lines are blanked.
   */
  _expandListBody(node, type, v) {
    const body = node.body;
    const fence = new MarkdownFenceTracker();
    for (let i = 0; i < body.length; i++) {
      const line = body[i];
      const open = fence.inFence ? null : _LIST_DIV_OPEN.exec(line);
      if (open == null) {
        fence.feed(line);
        continue;
      }
      const kind = open[1] ?? open[2];
      const at = node.bodyStartLine + i;
      const reject = (message) => {
        v.push(new DocSpecsViolation(DocSpecsViolationRule.MALFORMED_BLOCK, at, message, node.id));
      };
      let close = -1;
      for (let k = i + 1; k < body.length; k++) {
        if (_DIV_CLOSE.test(body[k])) {
          close = k;
          break;
        }
      }
      if (close < 0) {
        reject(`unclosed ${kind} fence`); // its lines stay text
        return;
      }
      const lead = _generatedLead(body);
      const besideText = body.some(
        (l, k) => k >= lead && (k < i || k > close) && l.trim().length > 0,
      );
      const hasItems = node.children.length > 0;
      const inner = body.slice(i + 1, close);
      for (let k = i; k <= close; k++) body[k] = '';
      if (besideText || hasItems) {
        reject(
          `a ${kind} div beside ${hasItems ? 'item headings' : 'other text'} in a list container`,
        );
        return;
      }
      const subKeys = Object.keys(type.subsectionTypes);
      const itemType =
        subKeys.length === 1 ? this.schema.sectionTypesByName[subKeys[0]] ?? null : null;
      if (itemType == null) {
        reject(`a ${kind} div in a section that is not a list container`);
        return;
      }
      if (kind === 'refs') {
        this._refsItems(node, itemType, inner, at);
      } else {
        this._recordItems(node, itemType, inner, at, reject, v);
      }
      return;
    }
  }

  /**
   * The form a `refs` item of `itemType` holds its reference in: the type's
   * own form, else the form of its one subsection type that has one (the
   * item's virtual child then carries the value). With `oneField`, only forms
   * of exactly one field count. A record table reads the type's own form only
   * ({@link _recordItems}).
   */
  _itemForm(itemType, oneField = false) {
    const formOf = (t) =>
      t != null && t.format != null ? this.schema.formTypes[t.format] : undefined;
    const fits = (f) => f !== undefined && (!oneField || f.fields.length === 1);
    const own = formOf(itemType);
    if (fits(own)) return [own, null];
    const candidates = [];
    for (const name of Object.keys(itemType.subsectionTypes)) {
      const sub = this.schema.sectionTypesByName[name];
      const f = formOf(sub);
      if (fits(f)) candidates.push([f, sub]);
    }
    return candidates.length === 1 ? candidates[0] : null;
  }

  /**
   * A virtual item of `itemType` with id `id` at `line`, added to `list`;
   * returns the section its form values go to — the item itself, or its
   * virtual child of `childType` (id: the child type's name upper-cased).
   */
  _addItem(list, itemType, childType, id, line) {
    const item = _Node.virtual(id, line, itemType);
    list.children.push(item);
    if (childType == null) return item;
    const child = _Node.virtual(childType.name.toUpperCase(), line, childType);
    item.children.push(child);
    return child;
  }

  /**
   * A `refs` div: its text split on commas and whitespace into ids, a link
   * counting as its link text; item <n> gets the positional id (the
   * container's id with `-LST` replaced by `-<n>`, else `<id>-<n>`) and the
   * virtual body line `<Label>: <id>`.
   */
  _refsItems(node, itemType, inner, at) {
    // Without a one-field form in the schema the reference is the item's
    // virtual body line; nothing in the schema checks it further.
    const target = this._itemForm(itemType, true);
    const ids = inner
      .join(' ')
      .split(/[,\s]+/)
      .filter((t) => t.length > 0)
      .map((t) => {
        const m = _LINK_TEXT.exec(t);
        return m != null ? m[1] : t;
      });
    const container = node.id ?? '';
    const stem = container.endsWith('-LST')
      ? container.substring(0, container.length - 4)
      : container;
    for (let n = 1; n <= ids.length; n++) {
      const holder = this._addItem(
        node, itemType, target != null ? target[1] : null, `${stem}-${n}`, at,
      );
      holder.values.push([target != null ? target[0].fields[0].name : '', ids[n - 1], at]);
    }
  }

  /**
   * A `records` div: one table, `Id` first, `Title` optionally second, then
   * field names of the item's form; each row one virtual item in row order.
   */
  _recordItems(node, itemType, inner, at, reject, v) {
    const lineOf = (k) => at + 1 + k;
    const start = inner.findIndex((l) => l.trim().length > 0);
    if (start < 0 || !_TABLE_LINE.test(inner[start])) {
      reject('a records div holding no table');
      return;
    }
    const header = _rowCells(inner[start]);
    if (header[0] !== 'Id') {
      reject('a records table whose first column is not Id');
      return;
    }
    // The item type's own form decides the columns; an item type the schema
    // gives no form of its own takes its columns as virtual body lines
    // unchecked. A record's cells are the item's own body lines (DocSpecs
    // specification, *The record table*): unlike a `refs` reference they never
    // go to a child's form.
    const own = itemType.format != null ? this.schema.formTypes[itemType.format] : undefined;
    const target = own !== undefined ? [own, null] : null;
    const withTitle = header.length > 1 && header[1] === 'Title';
    const columns = [];
    for (const label of header.slice(withTitle ? 2 : 1)) {
      const lower = label.toLowerCase();
      let f;
      if (target == null) {
        f = label;
      } else {
        const hit = target[0].fields.find((x) => x.name.toLowerCase() === lower);
        f = hit !== undefined ? hit.name : undefined;
      }
      if (f === undefined) {
        v.push(new DocSpecsViolation(
          DocSpecsViolationRule.UNKNOWN_FIELD,
          lineOf(start),
          `records column "${label}" names no field of the items`,
          node.id,
        ));
        return;
      }
      columns.push(f);
    }
    const table = this._readTable(inner, start, lineOf, node.id, v);
    for (const [k, cells] of table.rows) {
      const holder = this._addItem(
        node, itemType, target != null ? target[1] : null, _cellId(cells[0]), lineOf(k),
      );
      for (let c = 0; c < columns.length; c++) {
        const value = _cellValue(cells[(withTitle ? 2 : 1) + c]);
        if (value.length === 0) continue;
        holder.values.push([columns[c], value, lineOf(k)]);
      }
    }
  }
}

/**
 * Lands a DocSpecs markdown text in a typed SpecDocument via the SOM markdown
 * codec — the "bind" entry point (SOM §14).
 *
 * @param {import('./spec_model').SpecModel} model
 * @param {import('./spec_document').SpecDocument} document
 * @param {string} text
 * @returns {import('./spec_document_markdown').SpecMarkdownResult}
 */
function bindDocspecsMarkdown(model, document, text) {
  return new SpecDocumentMarkdown(model, document).parse(text);
}

module.exports = {
  DocSpecsViolationRule,
  DocSpecsViolation,
  DocSpecsSection,
  DocSpecsDocument,
  docSpecsIdTransform,
  DocSpecsPatternCheck,
  DocSpecsSubsectionRule,
  DocSpecsSectionType,
  DocSpecsFormField,
  DocSpecsFormType,
  DocSpecsDocumentSection,
  DocSpecsSchema,
  DocSpecsValidator,
  bindDocspecsMarkdown,
  stripOwnAnchor,
};
