/**
 * Validates a concrete {@link SpecDocument}'s values against a {@link SpecModel}
 * via the {@link SpecReflection} resolver — a faithful port of
 * `tom_som_dart_runtime/lib/src/spec_validator.dart` (and the JavaScript
 * `spec_validator.js`).
 *
 * The check is over the values a document *holds*: every set path must resolve to
 * a node of a compatible kind, every form sub-key must name a real form field,
 * and every populated list must meet its `@Min` item count. Schema completeness
 * (mandatory-but-absent nodes) is a separate concern and is not reported here.
 */

import { SpecDocument } from './spec_document';
import { SpecModel } from './spec_model';
import { SpecNodeKind, SpecReflection } from './spec_reflection';

/** Why a single value in a document is invalid against the model. */
export const SpecValidationCode = {
  DANGLING_PATH: 'danglingPath',
  KIND_MISMATCH: 'kindMismatch',
  UNKNOWN_FORM_FIELD: 'unknownFormField',
  MIN_ITEMS: 'minItems',
} as const;

export type SpecValidationCodeValue =
  (typeof SpecValidationCode)[keyof typeof SpecValidationCode];

/** One problem found while validating a document. */
export class SpecValidationError {
  path: string;
  code: SpecValidationCodeValue;
  message: string;

  constructor(path: string, code: SpecValidationCodeValue, message: string) {
    this.path = path;
    this.code = code;
    this.message = message;
  }

  toString(): string {
    return `[${this.code}] ${this.path}: ${this.message}`;
  }
}

function _dangling(path: string): SpecValidationError {
  return new SpecValidationError(
    path,
    SpecValidationCode.DANGLING_PATH,
    'path does not resolve to any model node',
  );
}

function _sorted(iterable: Iterable<string>): string[] {
  return Array.from(iterable).sort();
}

/**
 * Validates `doc` against `model`. Returns an empty array when the document is
 * valid; otherwise one {@link SpecValidationError} per problem, in a stable order
 * (content paths, then forms, then lists; each group sorted by path).
 */
export function validateDocument(
  model: SpecModel,
  doc: SpecDocument,
): SpecValidationError[] {
  const refl = new SpecReflection(model);
  const errors: SpecValidationError[] = [];

  // 1. Content/scalar/enum leaves.
  for (const path of _sorted(doc.contentPaths)) {
    const res = refl.resolve(path);
    if (res === null) {
      errors.push(_dangling(path));
      continue;
    }
    if (!res.isValueLeaf) {
      errors.push(
        new SpecValidationError(
          path,
          SpecValidationCode.KIND_MISMATCH,
          `expected a value leaf but path resolves to ${res.kind}`,
        ),
      );
    }
  }

  // 2. Form sections.
  for (const path of _sorted(doc.formPaths)) {
    const res = refl.resolve(path);
    if (res === null) {
      errors.push(_dangling(path));
      continue;
    }
    if (res.kind !== SpecNodeKind.FORM || res.field === null) {
      errors.push(
        new SpecValidationError(
          path,
          SpecValidationCode.KIND_MISMATCH,
          `expected a form section but path resolves to ${res.kind}`,
        ),
      );
      continue;
    }
    const declared = new Set(res.field.formFields.map((ff) => ff.name));
    for (const name of _sorted(doc.formFieldNames(path))) {
      if (!declared.has(name)) {
        errors.push(
          new SpecValidationError(
            path,
            SpecValidationCode.UNKNOWN_FORM_FIELD,
            `form field "${name}" is not declared on ${res.field.name}`,
          ),
        );
      }
    }
  }

  // 3. Lists (container kind + `@Min` count on populated lists).
  for (const path of _sorted(doc.listPaths)) {
    const res = refl.resolve(path);
    if (res === null) {
      errors.push(_dangling(path));
      continue;
    }
    if (res.kind !== SpecNodeKind.LIST || res.field === null) {
      errors.push(
        new SpecValidationError(
          path,
          SpecValidationCode.KIND_MISMATCH,
          `expected a list but path resolves to ${res.kind}`,
        ),
      );
      continue;
    }
    const minimum = res.field.min;
    const count = doc.listItemCount(path);
    if (minimum !== null && minimum !== undefined && count < minimum) {
      errors.push(
        new SpecValidationError(
          path,
          SpecValidationCode.MIN_ITEMS,
          `list holds ${count} item(s) but requires at least ${minimum}`,
        ),
      );
    }
  }

  return errors;
}
