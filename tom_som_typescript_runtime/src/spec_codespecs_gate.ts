/**
 * The Phase-4 mechanical gate — Stage A of `codespecs_prompt.md` §4, all five
 * checks run as one, over (model, document, catalogue, schema).
 *
 * Every check runs; none stops the others. A project fixing one wants to see
 * the rest, and a gate that stopped at the first failure would report a
 * different set of problems on every run (`codespecs_prompt.md` §4).
 *
 * A check that could not run is reported as **not run**, with its reason, and
 * the gate does not pass: a skipped check must never read as a passed one.
 *
 * Port of the Dart reference `spec_codespecs_gate.dart`.
 */

import { DocSpecsSchema, DocSpecsValidator } from './docspecs_validator';
import {
  CodeSpecsAreaCatalog,
  CodeSpecsExtract,
  CodeSpecsExtractEntry,
  CodeSpecsExtractError,
  CodeSpecsExtractor,
  CodeSpecsRoutingVerdict,
} from './spec_codespecs_extract';
import { SpecDocument } from './spec_document';
import { SpecModel } from './spec_model';
import { validateDocument } from './spec_validator';

/** The five Stage-A checks. */
export class CodeSpecsGateCheck {
  /** The document is complete against its DocSpecs schema. */
  static readonly a1 = new CodeSpecsGateCheck('a1');

  /** The document's values are valid (`validateDocument`). */
  static readonly a2 = new CodeSpecsGateCheck('a2');

  /** Every section the walk reaches carries a routing verdict (ROUTE-TOTAL). */
  static readonly a3 = new CodeSpecsGateCheck('a3');

  /** Every required marker argument of a used area has a populated source. */
  static readonly a4 = new CodeSpecsGateCheck('a4');

  /** The model still offers every structured carrier. */
  static readonly a5 = new CodeSpecsGateCheck('a5');

  /** Every check, in check order. */
  static readonly values: readonly CodeSpecsGateCheck[] = [
    CodeSpecsGateCheck.a1,
    CodeSpecsGateCheck.a2,
    CodeSpecsGateCheck.a3,
    CodeSpecsGateCheck.a4,
    CodeSpecsGateCheck.a5,
  ];

  /** The enum constant's name (`a1`). */
  readonly name: string;

  private constructor(name: string) {
    this.name = name;
  }

  /** `A1` … `A5`, as `codespecs_prompt.md` §4 names them. */
  get label(): string {
    return this.name.toUpperCase();
  }

  toString(): string {
    return `CodeSpecsGateCheck.${this.name}`;
  }
}

/** One thing a check found wrong. */
export class CodeSpecsGateFinding {
  /** The check that found it. */
  readonly check: CodeSpecsGateCheck;

  /**
   * What kind of finding — the DocSpecs rule (A1), the validation code (A2),
   * `unrouted` / `root` (A3), `missingSource` / `unresolvedReference` (A4),
   * `missingCarrier` (A5).
   */
  readonly code: string;

  /**
   * Where: a section id or document path (A1–A4), or the carrier
   * `Class.member[.formField]` (A5).
   */
  readonly location: string;

  /** One sentence a user acts on. */
  readonly message: string;

  constructor(props: {
    check: CodeSpecsGateCheck;
    code: string;
    location: string;
    message: string;
  }) {
    this.check = props.check;
    this.code = props.code;
    this.location = props.location;
    this.message = props.message;
  }

  toString(): string {
    return `${this.check.label} ${this.code} ${this.location}: ${this.message}`;
  }
}

/** One check's outcome. */
export class CodeSpecsGateCheckResult {
  /** Which check. */
  readonly check: CodeSpecsGateCheck;

  /** Whether it ran. A check that did not run never passes. */
  readonly ran: boolean;

  /** Why it did not run; `null` when it ran. */
  readonly notRunReason: string | null;

  /** What it found, in the order found. */
  readonly findings: CodeSpecsGateFinding[];

  constructor(props: {
    check: CodeSpecsGateCheck;
    ran?: boolean;
    notRunReason?: string | null;
    findings?: CodeSpecsGateFinding[];
  }) {
    this.check = props.check;
    this.ran = props.ran != null ? props.ran : true;
    this.notRunReason = props.notRunReason != null ? props.notRunReason : null;
    this.findings = props.findings || [];
  }

  /** Ran and found nothing. */
  get passed(): boolean {
    return this.ran && this.findings.length === 0;
  }
}

/** The gate's report: one result per check, A1 to A5. */
export class CodeSpecsGateReport {
  /** The five results, in check order. */
  readonly results: CodeSpecsGateCheckResult[];

  /**
   * The extraction run's extracts, when A3 passed (A4 reads them; Stage B is
   * handed them). `null` when the walk could not complete.
   */
  readonly extracts: CodeSpecsExtract[] | null;

  constructor(
    results: CodeSpecsGateCheckResult[],
    extracts: CodeSpecsExtract[] | null,
  ) {
    this.results = results;
    this.extracts = extracts;
  }

  /** The result of `check` (Dart's `report[check]`). */
  resultFor(check: CodeSpecsGateCheck): CodeSpecsGateCheckResult {
    const r = this.results.find((x) => x.check === check);
    if (r === undefined) {
      throw new Error(`no result for ${check.label}`);
    }
    return r;
  }

  /** Every check ran and found nothing — the run may begin. */
  get passed(): boolean {
    return this.results.every((r) => r.passed);
  }

  /** Every finding, in check order. */
  get findings(): CodeSpecsGateFinding[] {
    const out: CodeSpecsGateFinding[] = [];
    for (const r of this.results) {
      out.push(...r.findings);
    }
    return out;
  }
}

/** Stage A of `codespecs_prompt.md` §4. */
export class CodeSpecsGate {
  /** The resolved object model. */
  readonly model: SpecModel;

  /** The document under Phase 4. */
  readonly document: SpecDocument;

  /** The area catalogue — its `gate` tables drive A4 and A5. */
  readonly catalog: CodeSpecsAreaCatalog;

  /** The DocSpecs schema of the document's root; A1 does not run without it. */
  readonly schema: DocSpecsSchema | null;

  /**
   * The document root to walk — type name or section id; defaults to the
   * document's single populated root, as the extractor does.
   */
  readonly rootType: string | null;

  /** Holds the inputs; {@link run} does the work. */
  constructor(props: {
    model: SpecModel;
    document: SpecDocument;
    catalog: CodeSpecsAreaCatalog;
    schema?: DocSpecsSchema | null;
    rootType?: string | null;
  }) {
    this.model = props.model;
    this.document = props.document;
    this.catalog = props.catalog;
    this.schema = props.schema != null ? props.schema : null;
    this.rootType = props.rootType != null ? props.rootType : null;
  }

  /** Runs all five checks. */
  run(): CodeSpecsGateReport {
    const a1 = this._a1();
    const a2 = this._a2();
    const [a3, extracts] = this._a3();
    const a4 = !this.catalog.hasGateTables
      ? CodeSpecsGate._noTables(CodeSpecsGateCheck.a4)
      : extracts === null
        ? new CodeSpecsGateCheckResult({
            check: CodeSpecsGateCheck.a4,
            ran: false,
            notRunReason:
              'A3 did not complete, so there is no extraction run to read ' +
              'the used areas from',
          })
        : this._a4(extracts);
    const a5 = this.catalog.hasGateTables
      ? this._a5()
      : CodeSpecsGate._noTables(CodeSpecsGateCheck.a5);
    return new CodeSpecsGateReport([a1, a2, a3, a4, a5], extracts);
  }

  private static _noTables(check: CodeSpecsGateCheck): CodeSpecsGateCheckResult {
    return new CodeSpecsGateCheckResult({
      check,
      ran: false,
      notRunReason:
        'the catalogue carries no gate tables (written before ' +
        '`codespecs_prompt.md` §4.4/§4.5 were transcribed)',
    });
  }

  private _a1(): CodeSpecsGateCheckResult {
    const s = this.schema;
    if (s === null) {
      return new CodeSpecsGateCheckResult({
        check: CodeSpecsGateCheck.a1,
        ran: false,
        notRunReason: 'no DocSpecs schema was supplied',
      });
    }
    const markdown = this.document.toMarkdown(
      this.model,
      this.rootType !== null ? this.rootType : undefined,
    );
    return new CodeSpecsGateCheckResult({
      check: CodeSpecsGateCheck.a1,
      findings: new DocSpecsValidator(s).validateMarkdown(markdown).map(
        (v) =>
          new CodeSpecsGateFinding({
            check: CodeSpecsGateCheck.a1,
            code: v.rule,
            location: v.sectionId ?? v.path ?? `line ${v.line}`,
            message: `line ${v.line}: ${v.message}`,
          }),
      ),
    });
  }

  private _a2(): CodeSpecsGateCheckResult {
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
  private _a3(): [CodeSpecsGateCheckResult, CodeSpecsExtract[] | null] {
    let extractor: CodeSpecsExtractor;
    try {
      extractor = new CodeSpecsExtractor(
        this.model,
        this.document,
        this.catalog,
        this.rootType,
      );
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
    const unrouted: CodeSpecsGateFinding[] = [];
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
      return [
        new CodeSpecsGateCheckResult({
          check: CodeSpecsGateCheck.a3,
          findings: unrouted,
        }),
        null,
      ];
    }
    return [
      new CodeSpecsGateCheckResult({ check: CodeSpecsGateCheck.a3 }),
      extractor.extractAll(),
    ];
  }

  /**
   * A4 over the extraction run: for each obligation whose area's extract is
   * non-empty, every instance of the obligation's class that the extract
   * carries must carry the source value, populated (non-blank); a `resolvesTo`
   * obligation's value must also equal a value the run carries at the target.
   */
  private _a4(extracts: CodeSpecsExtract[]): CodeSpecsGateCheckResult {
    const findings: CodeSpecsGateFinding[] = [];
    const all: CodeSpecsExtractEntry[] = [];
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
      const instances = new Map<string, string | null>();
      const applies = new Set<string>();
      const when = o.when;
      for (const e of extract.entries) {
        if (e.className !== o.className) {
          continue;
        }
        const instance = parentPath(e.path);
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
        if (
          e.fieldName === o.member &&
          e.formField === o.formField &&
          e.value.trim() !== ''
        ) {
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
    return new CodeSpecsGateCheckResult({
      check: CodeSpecsGateCheck.a4,
      findings,
    });
  }

  /**
   * A5 against the model, not the document: each carrier's class, member and
   * form field must still exist.
   */
  private _a5(): CodeSpecsGateCheckResult {
    const findings: CodeSpecsGateFinding[] = [];
    for (const c of this.catalog.carriers) {
      const cls = this.model.classNamed(c.className);
      const field = cls !== null ? cls.fieldNamed(c.member) : null;
      const present =
        field !== null &&
        (c.formField === null ||
          field.formFields.some((f) => f.name === c.formField));
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
    return new CodeSpecsGateCheckResult({
      check: CodeSpecsGateCheck.a5,
      findings,
    });
  }
}

function parentPath(path: string): string {
  const i = path.lastIndexOf('/');
  return i < 0 ? '' : path.substring(0, i);
}
