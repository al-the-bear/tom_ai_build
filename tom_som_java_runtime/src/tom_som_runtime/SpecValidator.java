package tom_som_runtime;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;

/**
 * Validates a concrete {@link SpecDocument}'s values against a {@link SpecModel}
 * via the {@link SpecReflection} resolver — a faithful port of
 * {@code spec_validator.dart} / {@code spec_validator.py}.
 *
 * <p>The check is over the values a document <i>holds</i>: every set path must
 * resolve to a node of a compatible kind, every form sub-key must name a real
 * form field, and every populated list must meet its {@code @Min} item count.
 */
public final class SpecValidator {
  private SpecValidator() {}

  private static SpecValidationError dangling(String path) {
    return new SpecValidationError(
        path, SpecValidationCode.DANGLING_PATH, "path does not resolve to any model node");
  }

  /**
   * Validates {@code doc} against {@code model}. Returns an empty list when the
   * document is valid; otherwise one error per problem, in a stable order
   * (content paths, then forms, then lists; each group sorted by path).
   */
  public static List<SpecValidationError> validateDocument(SpecModel model, SpecDocument doc) {
    SpecReflection refl = new SpecReflection(model);
    List<SpecValidationError> errors = new ArrayList<>();

    // 1. Content/scalar/enum leaves.
    for (String path : new TreeSet<>(doc.contentPaths())) {
      SpecResolution res = refl.resolve(path);
      if (res == null) {
        errors.add(dangling(path));
        continue;
      }
      if (!res.isValueLeaf()) {
        errors.add(
            new SpecValidationError(
                path,
                SpecValidationCode.KIND_MISMATCH,
                "expected a value leaf but path resolves to " + res.kind.value));
      }
    }

    // 2. Form sections.
    for (String path : new TreeSet<>(doc.formPaths())) {
      SpecResolution res = refl.resolve(path);
      if (res == null) {
        errors.add(dangling(path));
        continue;
      }
      if (res.kind != SpecNodeKind.FORM || res.field == null) {
        errors.add(
            new SpecValidationError(
                path,
                SpecValidationCode.KIND_MISMATCH,
                "expected a form section but path resolves to " + res.kind.value));
        continue;
      }
      Set<String> declared = new HashSet<>();
      for (FormFieldSpec ff : res.field.formFields) {
        declared.add(ff.name);
      }
      for (String name : new TreeSet<>(doc.formFieldNames(path))) {
        if (!declared.contains(name)) {
          errors.add(
              new SpecValidationError(
                  path,
                  SpecValidationCode.UNKNOWN_FORM_FIELD,
                  "form field \"" + name + "\" is not declared on " + res.field.name));
        }
      }
    }

    // 3. Lists (container kind + @Min count on populated lists).
    for (String path : new TreeSet<>(doc.listPaths())) {
      SpecResolution res = refl.resolve(path);
      if (res == null) {
        errors.add(dangling(path));
        continue;
      }
      if (res.kind != SpecNodeKind.LIST || res.field == null) {
        errors.add(
            new SpecValidationError(
                path,
                SpecValidationCode.KIND_MISMATCH,
                "expected a list but path resolves to " + res.kind.value));
        continue;
      }
      Integer minimum = res.field.min;
      int count = doc.listItemCount(path);
      if (minimum != null && count < minimum) {
        errors.add(
            new SpecValidationError(
                path,
                SpecValidationCode.MIN_ITEMS,
                "list holds " + count + " item(s) but requires at least " + minimum));
      }
    }

    return errors;
  }
}
