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
        if (m) {
          const level = m[1].length;
          const rest = m[2];
          const c = SpecDocumentMarkdown.headlineComment.exec(rest);
          let section;
          if (c) {
            section = new DocSpecsSection(
              c[1] || null,
              // csmc8 (codespecs_mapping.md §9.2): the heading-comment regex is
              // now 3-group (id, meta region, title) — the title is group 3.
              (c[3] || '').trim() || rest,
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

/** One `document.sections` slot of a schema. */
class DocSpecsDocumentSection {
  constructor(sectionType, optional) {
    this.sectionType = sectionType;
    this.optional = optional;
  }
}

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
            if (_isPlainObject(sRaw)) {
              sectionType = String(sRaw['section-type'] != null ? sRaw['section-type'] : sKey);
              optional = _isTrue(sRaw.optional);
            } else {
              sectionType = String(sKey);
              optional = false;
            }
            this.documentSections[sKey] = new DocSpecsDocumentSection(sectionType, optional);
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

/** Never-fail-fast validator of a parsed document against a schema. */
class DocSpecsValidator {
  constructor(schema) {
    this.schema = schema;
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
    this._validateDocumentSections(root, v);
    return v;
  }

  _resolveChild(section, v) {
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

  _validateDocumentSections(root, v) {
    /** @type {Object<string, number>} occurrences per section-type name. */
    const counts = {};
    const slotTypes = new Set(
      Object.values(this.schema.documentSections).map((s) => s.sectionType),
    );
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
    this._validateText(section, type, v);
    this._validateFormat(section, type, v);
    /** @type {Object<string, number>} occurrences per subsection type name. */
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
    for (const [subKey, rule] of Object.entries(type.subsectionTypes)) {
      const count = counts[subKey] || 0;
      if (count < rule.minCount) {
        if (count === 0) {
          v.push(new DocSpecsViolation(
            DocSpecsViolationRule.MISSING_REQUIRED_SECTION,
            section.line,
            `required subsection "${subKey}" of "${type.name}" is missing`,
            subKey,
          ));
        } else {
          v.push(new DocSpecsViolation(
            DocSpecsViolationRule.TOO_FEW_ITEMS,
            section.line,
            `subsection "${subKey}" occurs ${count} time(s), minimum is ${rule.minCount}`,
            subKey,
          ));
        }
      }
      if (rule.maxCount != null && count > rule.maxCount) {
        v.push(new DocSpecsViolation(
          DocSpecsViolationRule.TOO_MANY_ITEMS,
          section.line,
          `subsection "${subKey}" occurs ${count} time(s), maximum is ${rule.maxCount}`,
          subKey,
        ));
      }
    }
  }

  _validateText(section, type, v) {
    if (type.format != null && type.format in this.schema.formTypes) {
      return; // form sections carry fields, not body text.
    }
    const text = section.text;
    if (type.textRequired && text.length === 0) {
      v.push(new DocSpecsViolation(
        DocSpecsViolationRule.TEXT_REQUIRED,
        section.line,
        'section requires body text but has none',
        section.id,
      ));
      return;
    }
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
    for (const raw of section.bodyLines) {
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

  _validateForm(section, form, v) {
    /** @type {Object<string, DocSpecsFormField>} lowered name → field. */
    const byLower = {};
    for (const f of form.fields) {
      byLower[f.name.toLowerCase()] = f;
    }
    /** @type {Object<string, string[]>} field name → collected value lines. */
    const values = {};
    /** @type {Object<string, number>} field name → 1-based label line. */
    const fieldLines = {};
    const fence = new MarkdownFenceTracker();
    let current = null;
    for (let i = 0; i < section.bodyLines.length; i += 1) {
      const raw = section.bodyLines[i];
      if (!fence.inFence) {
        const m = _FIELD_LABEL.exec(raw);
        if (m) {
          const lowered = m[1].toLowerCase();
          if (lowered in byLower) {
            const name = byLower[lowered].name;
            current = name;
            values[name] = [m[2]];
            fieldLines[name] = section.bodyStartLine + i;
            fence.feed(raw);
            continue;
          }
        }
      }
      if (current != null) {
        values[current].push(raw);
      }
      fence.feed(raw);
    }
    for (const field of form.fields) {
      const collected = values[field.name];
      const value = collected != null
        ? collected.join('\n').replace(/^\s+|\s+$/g, '')
        : '';
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
};
