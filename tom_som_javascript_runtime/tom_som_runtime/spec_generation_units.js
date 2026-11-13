'use strict';

/**
 * The generation-unit register of a document (SOM §11.2): the units Phase 4
 * writes code into, each with the mapper of every area it holds. A faithful
 * port of `tom_som_dart_runtime/lib/src/spec_generation_units.dart`.
 *
 * The register is recognised by its annotations, never by class name, exactly
 * as validation phase 8 recognises it: a **unit** is a list item whose class
 * carries `@NoArtifact(generation)` and declares the form field `unitId`; a
 * **mapping** is such a list item declaring the form field `area`, and belongs
 * to the nearest unit whose path is a prefix of its own.
 */

const { SpecFieldKind } = require('./spec_model');
const { specPathJoin } = require('./spec_paths');
const { SpecReflection } = require('./spec_reflection');

/**
 * One mapping of a generation unit: the area it holds and the mapper that
 * writes that area's code for it.
 */
class SpecGenerationUnitMapping {
  /** @param {{area: string, mapping: string}} options */
  constructor({ area, mapping }) {
    /** The area code, `CE-…`, as stored (trimmed). */
    this.area = area;
    /** The mapper id, e.g. `dart-tom`, as stored (trimmed); empty when
     * unset. */
    this.mapping = mapping;
  }
}

/** One generation unit the document declares. */
class SpecGenerationUnit {
  /**
   * @param {{unitId: string, kind: string, path: string,
   *          mappings: SpecGenerationUnitMapping[]}} options
   */
  constructor({ unitId, kind, path, mappings }) {
    /** The unit's id — what a section's `units` names, usually the package
     * name. */
    this.unitId = unitId;
    /** `client`, `server`, `shared` or `other`, as stored; empty when unset. */
    this.kind = kind;
    /** The unit's list-item path in the document. */
    this.path = path;
    /** The unit's mappings, in stored order.
     * @type {SpecGenerationUnitMapping[]} */
    this.mappings = mappings;
  }

  /** Whether one of the unit's mappings holds `areaCode`. */
  maps(areaCode) {
    return this.mappings.some((m) => m.area === areaCode);
  }

  /**
   * The mapper of `areaCode` — the first mapping that holds it — or `null`.
   *
   * @returns {?string}
   */
  mappingFor(areaCode) {
    for (const m of this.mappings) {
      if (m.area === areaCode) return m.mapping;
    }
    return null;
  }
}

/**
 * The generation units `doc` declares, in register order: sorted list-path
 * order, each list's items in their stored order — the order validation phase
 * 8 visits them in. A unit without a `unitId` is left out; a second unit with
 * an id already seen is left out too (phase 8 reports it as
 * `duplicateUnitId`). A document without a register declares none.
 *
 * @param {import('./spec_model').SpecModel} model
 * @param {import('./spec_document').SpecDocument} doc
 * @returns {SpecGenerationUnit[]}
 */
function specGenerationUnits(model, doc) {
  const refl = new SpecReflection(model);
  const units = [];
  const mappings = [];
  const trimmed = (formPath, name) => {
    const v = doc.formField(formPath, name);
    return v === null || v === undefined ? '' : v.trim();
  };
  for (const listPath of Array.from(doc.listPaths).sort()) {
    for (const item of doc.listItems(listPath)) {
      const res = refl.resolve(item);
      const cls = res === null || res === undefined ? null : res.targetClass;
      if (cls === null || cls === undefined) continue;
      const noArtifact = cls.noArtifact;
      if (noArtifact === null || noArtifact === undefined) continue;
      if (noArtifact.reason !== 'generation') continue;
      const unitForm = _formDeclaring(cls, 'unitId');
      if (unitForm !== null) {
        const formPath = specPathJoin(item, refl.fieldSegment(unitForm));
        const id = trimmed(formPath, 'unitId');
        if (id !== '') {
          units.push({ id, kind: trimmed(formPath, 'kind'), path: item });
        }
      }
      const areaForm = _formDeclaring(cls, 'area');
      if (areaForm !== null) {
        const formPath = specPathJoin(item, refl.fieldSegment(areaForm));
        const area = trimmed(formPath, 'area');
        if (area !== '') {
          mappings.push({
            path: item,
            area,
            mapping: trimmed(formPath, 'mapping'),
          });
        }
      }
    }
  }

  const seen = new Set();
  const result = [];
  for (const u of units) {
    if (seen.has(u.id)) continue;
    seen.add(u.id);
    result.push(
      new SpecGenerationUnit({
        unitId: u.id,
        kind: u.kind,
        path: u.path,
        mappings: mappings
          .filter((m) => _owner(m.path, units) === u.path)
          .map(
            (m) =>
              new SpecGenerationUnitMapping({
                area: m.area,
                mapping: m.mapping,
              }),
          ),
      }),
    );
  }
  return result;
}

/**
 * The units of `units` whose mappings hold `areaCode`, in register order —
 * the default destination of a section routed to that area (SOM §11.2).
 *
 * @param {SpecGenerationUnit[]} units
 * @param {string} areaCode
 * @returns {string[]}
 */
function specDefaultUnits(units, areaCode) {
  return units.filter((u) => u.maps(areaCode)).map((u) => u.unitId);
}

/**
 * The path of the unit a mapping at `mappingPath` belongs to: the longest unit
 * path that is a proper prefix of it, or `null`.
 *
 * @returns {?string}
 */
function _owner(mappingPath, units) {
  let best = null;
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

/** The form field of `cls` that declares a form field named `name`, or `null`. */
function _formDeclaring(cls, name) {
  for (const f of cls.fields) {
    if (
      f.kind === SpecFieldKind.FORM &&
      (f.formFields || []).some((ff) => ff.name === name)
    ) {
      return f;
    }
  }
  return null;
}

module.exports = {
  SpecGenerationUnitMapping,
  SpecGenerationUnit,
  specGenerationUnits,
  specDefaultUnits,
};
