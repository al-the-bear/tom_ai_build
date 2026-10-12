'use strict';

/**
 * The Phase-4 mechanical gate — Stage A of `codespecs_prompt.md` §4, all five
 * checks run as one, over (model, document, catalogue, schema). A faithful
 * port of `tom_som_dart_runtime/lib/src/spec_codespecs_gate.dart`.
 *
 * Every check runs; none stops the others. A project fixing one wants to see
 * the rest, and a gate that stopped at the first failure would report a
 * different set of problems on every run (`codespecs_prompt.md` §4).
 *
 * A check that could not run is reported as **not run**, with its reason, and
 * the gate does not pass: a skipped check must never read as a passed one.
 */

const { DocSpecsValidator } = require('./docspecs_validator');
const {
  CodeSpecsExtractError,
  CodeSpecsExtractor,
  CodeSpecsRoutingVerdict,
} = require('./spec_codespecs_extract');
const { validateDocument } = require('./spec_validator');

/** The five Stage-A checks. */
class CodeSpecsGateCheck {
  /**
   * @param {string} name
   * @private
   */
  constructor(name) {
    /** The enum constant's name (`a1`). */
    this.name = name;
    Object.freeze(this);
  }

  /** `A1` … `A5`, as `codespecs_prompt.md` §4 names them. */
  get label() {
    return this.name.toUpperCase();
  }

  toString() {
    return `CodeSpecsGateCheck.${this.name}`;
  }
}

/** The document is complete against its DocSpecs schema. */
CodeSpecsGateCheck.a1 = new CodeSpecsGateCheck('a1');
/** The document's values are valid (`validateDocument`). */
CodeSpecsGateCheck.a2 = new CodeSpecsGateCheck('a2');
/** Every section the walk reaches carries a routing verdict (ROUTE-TOTAL). */
CodeSpecsGateCheck.a3 = new CodeSpecsGateCheck('a3');
/** Every required marker argument of a used area has a populated source. */
CodeSpecsGateCheck.a4 = new CodeSpecsGateCheck('a4');
/** The model still offers every structured carrier. */
CodeSpecsGateCheck.a5 = new CodeSpecsGateCheck('a5');
/** Every check, in check order. */
CodeSpecsGateCheck.values = Object.freeze([
  CodeSpecsGateCheck.a1,
  CodeSpecsGateCheck.a2,
  CodeSpecsGateCheck.a3,
  CodeSpecsGateCheck.a4,
  CodeSpecsGateCheck.a5,
]);

/** One thing a check found wrong. */
class CodeSpecsGateFinding {
  constructor({ check, code, location, message }) {
    /** The check that found it. @type {CodeSpecsGateCheck} */
    this.check = check;
    /** What kind of finding — the DocSpecs rule (A1), the validation code
     * (A2), `unrouted` / `root` (A3), `missingSource` / `unresolvedReference`
     * (A4), `missingCarrier` (A5). */
    this.code = code;
    /** Where: a section id or document path (A1–A4), or the carrier
     * `Class.member[.formField]` (A5). */
    this.location = location;
    /** One sentence a user acts on. */
    this.message = message;
  }

  toString() {
    return `${this.check.label} ${this.code} ${this.location}: ${this.message}`;
  }
}

/** One check's outcome. */
class CodeSpecsGateCheckResult {
  constructor({ check, ran = true, notRunReason = null, findings = [] }) {
    /** Which check. @type {CodeSpecsGateCheck} */
    this.check = check;
    /** Whether it ran. A check that did not run never passes. */
    this.ran = ran;
    /** Why it did not run; `null` when it ran. @type {?string} */
    this.notRunReason = notRunReason != null ? notRunReason : null;
    /** What it found, in the order found. @type {CodeSpecsGateFinding[]} */
    this.findings = findings;
  }

  /** Ran and found nothing. */
  get passed() {
    return this.ran && this.findings.length === 0;
  }
}

/** The gate's report: one result per check, A1 to A5. */
class CodeSpecsGateReport {
  /**
   * @param {CodeSpecsGateCheckResult[]} results
   * @param {?import('./spec_codespecs_extract').CodeSpecsExtract[]} extracts
   */
  constructor(results, extracts) {
    /** The five results, in check order. */
    this.results = results;
    /** The extraction run's extracts, when A3 passed (A4 reads them; Stage B
     * is handed them). `null` when the walk could not complete. */
    this.extracts = extracts;
  }

  /**
   * The result of `check` (Dart's `report[check]`).
   *
   * @param {CodeSpecsGateCheck} check
   * @returns {CodeSpecsGateCheckResult}
   */
  resultFor(check) {
    const r = this.results.find((x) => x.check === check);
    if (r === undefined) {
      throw new Error(`no result for ${check.label}`);
    }
    return r;
  }

  /** Every check ran and found nothing — the run may begin. */
  get passed() {
    return this.results.every((r) => r.passed);
  }

  /** Every finding, in check order. @returns {CodeSpecsGateFinding[]} */
  get findings() {
    const out = [];
    for (const r of this.results) {
      out.push(...r.findings);
    }
    return out;
  }
}

/** Stage A of `codespecs_prompt.md` §4. */
class CodeSpecsGate {
  /**
   * Holds the inputs; {@link CodeSpecsGate#run} does the work.
   *
   * `schema` is the DocSpecs schema of the document's root — A1 does not run
   * without it. `rootType` names the document root to walk (type name or
   * section id); omitted, the document's single populated root is used, as
   * the extractor does.
   */
  constructor({ model, document, catalog, schema = null, rootType = null }) {
    this.model = model;
    this.document = document;
    this.catalog = catalog;
    this.schema = schema != null ? schema : null;
    this.rootType = rootType != null ? rootType : null;
  }

  /** Runs all five checks. @returns {CodeSpecsGateReport} */
  run() {
    const a1 = this._a1();
    const a2 = this._a2();
    const [a3, extracts] = this._a3();
    let a4;
    if (!this.catalog.hasGateTables) {
      a4 = _noTables(CodeSpecsGateCheck.a4);
    } else if (extracts === null) {
      a4 = new CodeSpecsGateCheckResult({
        check: CodeSpecsGateCheck.a4,
        ran: false,
        notRunReason:
          'A3 did not complete, so there is no extraction run to read ' +
          'the used areas from',
      });
    } else {
      a4 = this._a4(extracts);
    }
    const a5 = this.catalog.hasGateTables ? this._a5() : _noTables(CodeSpecsGateCheck.a5);
    return new CodeSpecsGateReport([a1, a2, a3, a4, a5], extracts);
  }

  _a1() {
    const s = this.schema;
    if (s === null) {
      return new CodeSpecsGateCheckResult({
        check: CodeSpecsGateCheck.a1,
        ran: false,
        notRunReason: 'no DocSpecs schema was supplied',
      });
    }
    const markdown = this.document.toMarkdown(this.model, this.rootType);
    return new CodeSpecsGateCheckResult({
      check: CodeSpecsGateCheck.a1,
      findings: new DocSpecsValidator(s).validateMarkdown(markdown).map(
        (v) =>
          new CodeSpecsGateFinding({
            check: CodeSpecsGateCheck.a1,
            code: v.rule,
            location: v.sectionId != null ? v.sectionId : v.path != null ? v.path : `line ${v.line}`,
            message: `line ${v.line}: ${v.message}`,
          }),
      ),
    });
  }

  _a2() {
    return new CodeSpecsGateCheckResult({
      check: CodeSpecsGateCheck.a2,
      findings: validateDocument(this.model, this.document).map(
        (e) =>
          new CodeSpecsGateFinding({
            check: CodeSpecsGateCheck.a2,
            code: e.code,
            location: e.path,
            message: e.message,
          }),
      ),
    });
  }

  /**
   * A3 collects **every** unrouted class over the non-strict walk, rather than
   * the first one the strict walk throws on; only when there is none does it
   * run the extraction itself.
   */
  _a3() {
    let extractor;
    try {
      extractor = new CodeSpecsExtractor({
        model: this.model,
        document: this.document,
        catalog: this.catalog,
        rootType: this.rootType,
      });
    } catch (e) {
      if (!(e instanceof CodeSpecsExtractError)) {
        throw e;
      }
      return [
        new CodeSpecsGateCheckResult({
          check: CodeSpecsGateCheck.a3,
          findings: [
            new CodeSpecsGateFinding({
              check: CodeSpecsGateCheck.a3,
              code: 'root',
              location: e.path,
              message: e.message,
            }),
          ],
        }),
        null,
      ];
    }
    const unrouted = [];
    for (const r of extractor.routings()) {
      if (r.verdict === CodeSpecsRoutingVerdict.UNROUTED) {
        unrouted.push(
          new CodeSpecsGateFinding({
            check: CodeSpecsGateCheck.a3,
            code: 'unrouted',
            location: r.path,
            message:
              `${r.className} carries no @CodeSpecKind, @FollowUpKind or ` +
              '@NoArtifact — its content would reach no extract',
          }),
        );
      }
    }
    if (unrouted.length > 0) {
      return [new CodeSpecsGateCheckResult({ check: CodeSpecsGateCheck.a3, findings: unrouted }), null];
    }
    return [new CodeSpecsGateCheckResult({ check: CodeSpecsGateCheck.a3 }), extractor.extractAll()];
  }

  /**
   * A4 over the extraction run: for each obligation whose area's extract is
   * non-empty, every instance of the obligation's class that the extract
   * carries must carry the source value, populated (non-blank); a `resolvesTo`
   * obligation's value must also equal a value the run carries at the target.
   */
  _a4(extracts) {
    const findings = [];
    const all = [];
    for (const x of extracts) {
      all.push(...x.entries);
    }
    for (const o of this.catalog.requiredArguments) {
      const extract = extracts.find((x) => x.area.code === o.area);
      if (extract === undefined || extract.entries.length === 0) {
        continue;
      }
      // The instances the extract carries of the obligation's class, in
      // document order, each with the populated source value it holds.
      const instances = new Map();
      const applies = new Set();
      const when = o.when;
      for (const e of extract.entries) {
        if (e.className !== o.className) {
          continue;
        }
        const instance = _parentPath(e.path);
        if (!instances.has(instance)) {
          instances.set(instance, null);
        }
        if (
          when !== null &&
          e.fieldName === when.member &&
          e.formField === when.formField &&
          e.value === o.whenEquals
        ) {
          applies.add(instance);
        }
        if (e.fieldName === o.member && e.formField === o.formField && e.value.trim() !== '') {
          instances.set(instance, e.value);
        }
      }
      for (const [instance, value] of instances) {
        if (when !== null && !applies.has(instance)) {
          continue;
        }
        if (value === null) {
          findings.push(
            new CodeSpecsGateFinding({
              check: CodeSpecsGateCheck.a4,
              code: 'missingSource',
              location: instance,
              message:
                `${o.marker}.${o.argument} (${o.area}) is required, and ` +
                `its source ${o.source} is empty here`,
            }),
          );
          continue;
        }
        const target = o.resolvesTo;
        if (target === null) {
          continue;
        }
        const known = all.some(
          (e) =>
            e.className === target.className &&
            e.fieldName === target.member &&
            e.formField === target.formField &&
            e.value === value,
        );
        if (!known) {
          findings.push(
            new CodeSpecsGateFinding({
              check: CodeSpecsGateCheck.a4,
              code: 'unresolvedReference',
              location: instance,
              message:
                `${o.source} names \`${value}\`, which no ${target.source} ` +
                `in this document carries — ${o.marker}.${o.argument} ` +
                `(${o.area}) has nothing to resolve against`,
            }),
          );
        }
      }
    }
    return new CodeSpecsGateCheckResult({ check: CodeSpecsGateCheck.a4, findings });
  }

  /**
   * A5 against the model, not the document: each carrier's class, member and
   * form field must still exist.
   */
  _a5() {
    const findings = [];
    for (const c of this.catalog.carriers) {
      const cls = this.model.classNamed(c.className);
      const field = cls != null ? cls.fieldNamed(c.member) : null;
      const present =
        field != null &&
        (c.formField === null || field.formFields.some((f) => f.name === c.formField));
      if (!present) {
        findings.push(
          new CodeSpecsGateFinding({
            check: CodeSpecsGateCheck.a5,
            code: 'missingCarrier',
            location: c.source,
            message:
              `the model no longer offers ${c.source} ` +
              `(${c.introducedBy}) — a project with that structured fact ` +
              'would have to write prose again',
          }),
        );
      }
    }
    return new CodeSpecsGateCheckResult({ check: CodeSpecsGateCheck.a5, findings });
  }
}

function _noTables(check) {
  return new CodeSpecsGateCheckResult({
    check,
    ran: false,
    notRunReason:
      'the catalogue carries no gate tables (written before ' +
      '`codespecs_prompt.md` §4.4/§4.5 were transcribed)',
  });
}

function _parentPath(path) {
  const i = path.lastIndexOf('/');
  return i < 0 ? '' : path.substring(0, i);
}

module.exports = {
  CodeSpecsGate,
  CodeSpecsGateCheck,
  CodeSpecsGateFinding,
  CodeSpecsGateCheckResult,
  CodeSpecsGateReport,
};
