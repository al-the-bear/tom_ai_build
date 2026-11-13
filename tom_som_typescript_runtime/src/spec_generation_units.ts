/**
 * The generation-unit register of a document (SOM §11.2): the units Phase 4
 * writes code into, each with the mapper of every area it holds — a faithful
 * port of `tom_som_dart_runtime/lib/src/spec_generation_units.dart`.
 *
 * The register is recognised by its annotations, never by class name, exactly
 * as validation phase 8 recognises it: a **unit** is a list item whose class
 * carries `@NoArtifact(generation)` and declares the form field `unitId`; a
 * **mapping** is such a list item declaring the form field `area`, and belongs
 * to the nearest unit whose path is a prefix of its own.
 */

import { SpecDocument } from './spec_document';
import { SpecClass, SpecField, SpecFieldKind, SpecModel } from './spec_model';
import { specPathJoin } from './spec_paths';
import { SpecReflection } from './spec_reflection';

/**
 * One mapping of a generation unit: the area it holds and the mapper that
 * writes that area's code for it.
 */
export class SpecGenerationUnitMapping {
  /** The area code, `CE-…`, as stored (trimmed). */
  readonly area: string;

  /** The mapper id, e.g. `dart-tom`, as stored (trimmed); empty when unset. */
  readonly mapping: string;

  /** Creates a mapping of `area` by `mapping`. */
  constructor(props: { area: string; mapping: string }) {
    this.area = props.area;
    this.mapping = props.mapping;
  }
}

/** One generation unit the document declares. */
export class SpecGenerationUnit {
  /** The unit's id — what a section's `units` names, usually the package name. */
  readonly unitId: string;

  /** `client`, `server`, `shared` or `other`, as stored; empty when unset. */
  readonly kind: string;

  /** The unit's list-item path in the document. */
  readonly path: string;

  /** The unit's mappings, in stored order. */
  readonly mappings: SpecGenerationUnitMapping[];

  /** Creates a unit. */
  constructor(props: {
    unitId: string;
    kind: string;
    path: string;
    mappings: SpecGenerationUnitMapping[];
  }) {
    this.unitId = props.unitId;
    this.kind = props.kind;
    this.path = props.path;
    this.mappings = props.mappings;
  }

  /** Whether one of the unit's mappings holds `areaCode`. */
  maps(areaCode: string): boolean {
    return this.mappings.some((m) => m.area === areaCode);
  }

  /** The mapper of `areaCode` — the first mapping that holds it — or `null`. */
  mappingFor(areaCode: string): string | null {
    for (const m of this.mappings) {
      if (m.area === areaCode) {
        return m.mapping;
      }
    }
    return null;
  }
}

interface _UnitRow {
  id: string;
  kind: string;
  path: string;
}

interface _MappingRow {
  path: string;
  area: string;
  mapping: string;
}

/**
 * The generation units `doc` declares, in register order: sorted list-path
 * order, each list's items in their stored order — the order validation phase
 * 8 visits them in. A unit without a `unitId` is left out; a second unit with
 * an id already seen is left out too (phase 8 reports it as
 * `duplicateUnitId`). A document without a register declares none.
 */
export function specGenerationUnits(
  model: SpecModel,
  doc: SpecDocument,
): SpecGenerationUnit[] {
  const refl = new SpecReflection(model);
  const units: _UnitRow[] = [];
  const mappings: _MappingRow[] = [];
  const value = (formPath: string, name: string): string => {
    const v = doc.formField(formPath, name);
    return v === null || v === undefined ? '' : v.trim();
  };
  for (const listPath of Array.from(doc.listPaths).sort()) {
    for (const item of doc.listItems(listPath)) {
      const res = refl.resolve(item);
      const cls = res === null ? null : res.targetClass;
      if (cls === null) {
        continue;
      }
      const noArtifact = cls.noArtifact;
      if (noArtifact === null || noArtifact.reason !== 'generation') {
        continue;
      }
      const unitForm = specFormDeclaring(cls, 'unitId');
      if (unitForm !== null) {
        const formPath = specPathJoin(item, refl.fieldSegment(unitForm));
        const id = value(formPath, 'unitId');
        if (id !== '') {
          units.push({ id, kind: value(formPath, 'kind'), path: item });
        }
      }
      const areaForm = specFormDeclaring(cls, 'area');
      if (areaForm !== null) {
        const formPath = specPathJoin(item, refl.fieldSegment(areaForm));
        const area = value(formPath, 'area');
        if (area !== '') {
          mappings.push({
            path: item,
            area,
            mapping: value(formPath, 'mapping'),
          });
        }
      }
    }
  }

  const seen = new Set<string>();
  const out: SpecGenerationUnit[] = [];
  for (const u of units) {
    if (seen.has(u.id)) {
      continue;
    }
    seen.add(u.id);
    out.push(
      new SpecGenerationUnit({
        unitId: u.id,
        kind: u.kind,
        path: u.path,
        mappings: mappings
          .filter((m) => _owner(m.path, units) === u.path)
          .map(
            (m) =>
              new SpecGenerationUnitMapping({ area: m.area, mapping: m.mapping }),
          ),
      }),
    );
  }
  return out;
}

/**
 * The units of `units` whose mappings hold `areaCode`, in register order —
 * the default destination of a section routed to that area (SOM §11.2).
 */
export function specDefaultUnits(
  units: SpecGenerationUnit[],
  areaCode: string,
): string[] {
  return units.filter((u) => u.maps(areaCode)).map((u) => u.unitId);
}

/**
 * The path of the unit a mapping at `mappingPath` belongs to: the longest unit
 * path that is a proper prefix of it, or `null`.
 */
function _owner(mappingPath: string, units: _UnitRow[]): string | null {
  let best: string | null = null;
  for (const u of units) {
    if (
      mappingPath.startsWith(`${u.path}/`) &&
      (best === null || u.path.length > best.length)
    ) {
      best = u.path;
    }
  }
  return best;
}

/**
 * The form field of `cls` that declares a form field named `name`, or `null`.
 * Shared with validation phase 8, which recognises the register the same way.
 */
export function specFormDeclaring(
  cls: SpecClass,
  name: string,
): SpecField | null {
  for (const f of cls.fields) {
    if (
      f.kind === SpecFieldKind.FORM &&
      f.formFields.some((ff) => ff.name === name)
    ) {
      return f;
    }
  }
  return null;
}
