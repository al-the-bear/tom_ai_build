package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
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
      // A form node is the one non-leaf that legitimately carries content: it is
      // the form's preamble, the free text before the first field line (SOM
      // §11.4 rule 7), in the same slot a plain section's body uses.
      if (!res.isValueLeaf() && res.kind != SpecNodeKind.FORM) {
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

    // 4. @OneOf/@Case closed choice (csmb6).
    //
    // The static tier checks the group is well formed; only here can we see
    // which case a document actually chose and whether the subsections it
    // populated are the ones that choice selects.
    errors.addAll(validateOneOfInstances(refl, doc));

    // 5. Cross-registry references (csrb3).
    //
    // A reference form field holds an id that must already be declared by some
    // entry of a target registry. The static tier has checked the `refersTo`
    // targets are resolvable; only here can we see whether the id a document
    // actually wrote is one the document also declares.
    errors.addAll(validateReferenceInstances(refl, doc));

    return errors;
  }

  /**
   * The constant part of a qualified {@code EnumType.constant} {@code @Case}
   * token (or the whole string when it is not qualified).
   */
  private static String caseConstant(String token) {
    int dot = token.indexOf('.');
    return dot >= 0 ? token.substring(dot + 1) : token;
  }

  /**
   * Instance-tier {@code @OneOf}/{@code @Case} check (csmb6): for every
   * {@code @OneOf} container instance present in {@code doc}, verify the
   * populated case subsections match the chosen discriminator value.
   */
  private static List<SpecValidationError> validateOneOfInstances(
      SpecReflection refl, SpecDocument doc) {
    List<SpecValidationError> errors = new ArrayList<>();

    // Every section-instance path present in the document: each stored value
    // path plus all of its ancestor prefixes (a container's own discriminator
    // form lives at `<container>/content`, so the container path is always a
    // prefix of a populated path).
    Set<String> sectionPaths = new TreeSet<>();
    for (Set<String> group :
        List.of(doc.contentPaths(), doc.formPaths(), doc.listPaths(), doc.headlinePaths())) {
      for (String full : group) {
        String[] segs = full.split("/", -1);
        StringBuilder buf = new StringBuilder();
        for (int i = 0; i < segs.length; i++) {
          if (i > 0) {
            buf.append('/');
          }
          buf.append(segs[i]);
          sectionPaths.add(buf.toString());
        }
      }
    }

    for (String path : sectionPaths) {
      SpecResolution res = refl.resolve(path);
      SpecClass cls = res == null ? null : res.targetClass;
      if (cls == null) {
        continue;
      }
      SpecAnnotation oneOf = cls.annotation("OneOf");
      if (oneOf == null) {
        continue;
      }
      Object rawDiscriminator = oneOf.argument("discriminator");
      if (!(rawDiscriminator instanceof String)) {
        continue;
      }
      String discriminator = (String) rawDiscriminator;
      if (discriminator.isEmpty()) {
        continue;
      }

      // Read the chosen discriminator value from the container's own @Form.
      SpecField formHolder = null;
      for (SpecField f : cls.fields) {
        if (f.kind != SpecFieldKind.FORM) {
          continue;
        }
        for (FormFieldSpec ff : f.formFields) {
          if (ff.name.equals(discriminator)) {
            formHolder = f;
            break;
          }
        }
        if (formHolder != null) {
          break;
        }
      }
      if (formHolder == null) {
        continue; // static tier flagged the mismatch
      }
      String chosen = doc.formField(path + "/" + refl.fieldSegment(formHolder), discriminator);
      if (chosen == null || chosen.isEmpty()) {
        continue; // no case chosen yet
      }

      // Inspect each case-bound subsection: present + not-selected → mismatch.
      List<String> presentForChosen = new ArrayList<>();
      for (SpecField f : cls.fields) {
        Set<String> caseConstants = new TreeSet<>();
        for (SpecAnnotation a : f.annotations) {
          if (a.name.equals("Case") && a.argument("value") instanceof String) {
            caseConstants.add(caseConstant((String) a.argument("value")));
          }
        }
        if (caseConstants.isEmpty()) {
          continue; // common subsection — always allowed
        }
        String childPath = path + "/" + refl.fieldSegment(f);
        if (!doc.hasValuesUnder(childPath)) {
          continue;
        }
        if (caseConstants.contains(chosen)) {
          presentForChosen.add(f.name);
        } else {
          errors.add(
              new SpecValidationError(
                  childPath,
                  SpecValidationCode.ONE_OF_CASE_MISMATCH,
                  "subsection \""
                      + f.name
                      + "\" is present but the chosen "
                      + discriminator
                      + "=\""
                      + chosen
                      + "\" does not select it (cases: "
                      + String.join(", ", caseConstants)
                      + ")"));
        }
      }
      if (presentForChosen.size() > 1) {
        Collections.sort(presentForChosen);
        errors.add(
            new SpecValidationError(
                path,
                SpecValidationCode.ONE_OF_CASE_MISMATCH,
                "chosen "
                    + discriminator
                    + "=\""
                    + chosen
                    + "\" selects more than one populated subsection ("
                    + String.join(", ", presentForChosen)
                    + ") — at most one case subsection may be present"));
      }
    }

    return errors;
  }

  /** One resolved form section: its path, the class it sits on, and its field. */
  private static final class FormInstance {
    final String path;
    final SpecClass cls;
    final SpecField field;

    FormInstance(String path, SpecClass cls, SpecField field) {
      this.path = path;
      this.cls = cls;
      this.field = field;
    }
  }

  /**
   * Instance-tier cross-registry reference check (csrb3): every id written into a
   * {@code refersTo} form field must be declared by some entry of one of its
   * target registries <i>in this document</i>.
   *
   * <p>The pass is two sweeps over the document's form sections, so it costs one
   * extra walk rather than a resolve per reference:
   *
   * <ol>
   *   <li><b>Declare.</b> Every form instance whose class carries
   *       {@code @SectionId(X)} and declares form field {@code f} contributes its
   *       value of {@code f} to the registry key {@code X.f}. Every item of a list
   *       whose element class carries {@code @SectionId(X)} additionally
   *       contributes its <i>effective</i> section id — stored, else positional,
   *       see {@link SpecSectionId#effectiveListItemSectionId} — to the reserved
   *       key {@code X.@sectionId}. That second half is what makes a registry
   *       keeping its id nowhere but the section id (a functional requirement)
   *       referenceable at all.
   *   <li><b>Resolve.</b> Every form instance holding a {@code refersTo} field
   *       checks its value against those sets. A value naming several ids writes
   *       them comma-separated, so each segment resolves independently.
   * </ol>
   *
   * <p>A value is valid when it resolves in <b>any</b> listed registry: some
   * fields legitimately accept an id from more than one. An empty value is not a
   * dangling reference — it means "not filled in yet".
   *
   * <p><b>Cross-document references (csre2).</b> A reference whose target registry
   * the document's own root cannot reach is skipped rather than reported. Such a
   * reference is a <i>cross-document</i> one and the registry it names is absent
   * from the document by construction, not undeclared; see
   * {@link #registryScope}.
   */
  private static List<SpecValidationError> validateReferenceInstances(
      SpecReflection refl, SpecDocument doc) {
    List<SpecValidationError> errors = new ArrayList<>();
    Set<String> scope = registryScope(refl, doc);

    // Resolve every form path once; both sweeps read the same resolutions.
    //
    // A form resolution names the form *field*, not a class — the section id a
    // registry key is written against belongs to the class the form sits on, so
    // the owner is resolved from the parent path.
    List<FormInstance> forms = new ArrayList<>();
    for (String path : new TreeSet<>(doc.formPaths())) {
      SpecResolution res = refl.resolve(path);
      if (res == null || res.kind != SpecNodeKind.FORM || res.field == null) {
        continue;
      }
      int slash = path.lastIndexOf('/');
      if (slash <= 0) {
        continue;
      }
      SpecResolution owner = refl.resolve(path.substring(0, slash));
      SpecClass cls = owner == null ? null : owner.targetClass;
      if (cls == null) {
        continue;
      }
      forms.add(new FormInstance(path, cls, res.field));
    }

    // 1. Declare.
    Map<String, Set<String>> declared = new HashMap<>();
    for (FormInstance form : forms) {
      String sectionId = form.cls.sectionId;
      if (sectionId == null || sectionId.isEmpty()) {
        continue;
      }
      for (FormFieldSpec ff : form.field.formFields) {
        String value = doc.formField(form.path, ff.name);
        if (value == null || value.trim().isEmpty()) {
          continue;
        }
        declared
            .computeIfAbsent(sectionId + "." + ff.name, k -> new HashSet<>())
            .add(value.trim());
      }
    }

    // 1b. Declare the per-item section ids under the reserved `@sectionId` slot.
    // The key is the *element class's* section id, not the `-LST` container's:
    // a target names the entry, so `FRE.@sectionId` reads as "an id of some
    // functional-requirement entry".
    for (String listPath : new TreeSet<>(doc.listPaths())) {
      SpecResolution listRes = refl.resolve(listPath);
      SpecField listField = listRes == null ? null : listRes.field;
      String pattern = listField == null ? null : listField.sectionIdPattern;
      String stem = listField == null ? null : listField.name;
      if (stem == null) {
        String[] segs = listPath.split("/", -1);
        stem = segs[segs.length - 1];
      }
      List<String> items = doc.listItems(listPath);
      for (int i = 0; i < items.size(); i++) {
        SpecResolution itemRes = refl.resolve(items.get(i));
        SpecClass elementClass = itemRes == null ? null : itemRes.targetClass;
        String sectionId = elementClass == null ? null : elementClass.sectionId;
        if (sectionId == null || sectionId.isEmpty()) {
          continue;
        }
        declared
            .computeIfAbsent(sectionId + "." + SpecSectionId.K_SECTION_ID_SLOT,
                k -> new HashSet<>())
            .add(
                SpecSectionId.effectiveListItemSectionId(
                    doc.itemSectionId(items.get(i)), pattern, i + 1, stem));
      }
    }

    // 2. Resolve.
    for (FormInstance form : forms) {
      for (FormFieldSpec ff : form.field.formFields) {
        if (ff.refersTo.isEmpty()) {
          continue;
        }
        String value = doc.formField(form.path, ff.name);
        if (value == null || value.trim().isEmpty()) {
          continue;
        }

        // Every target must be in scope, not merely one of them: a disjunction
        // says the id may come from any of the listed registries, so one absent
        // registry is enough to make "no registry declares it" unsound.
        boolean allInScope = true;
        for (String target : ff.refersTo) {
          if (!scope.contains(registrySectionId(target))) {
            allInScope = false;
            break;
          }
        }
        if (!allInScope) {
          continue;
        }

        for (String segment : value.split(",", -1)) {
          String id = segment.trim();
          if (id.isEmpty()) {
            continue;
          }
          boolean resolves = false;
          for (String target : ff.refersTo) {
            Set<String> ids = declared.get(target);
            if (ids != null && ids.contains(id)) {
              resolves = true;
              break;
            }
          }
          if (resolves) {
            continue;
          }
          errors.add(
              new SpecValidationError(
                  form.path,
                  SpecValidationCode.DANGLING_REFERENCE,
                  "form field \""
                      + ff.name
                      + "\" references \""
                      + id
                      + "\", which no entry of "
                      + (ff.refersTo.size() == 1 ? "registry" : "registries")
                      + " "
                      + String.join(", ", ff.refersTo)
                      + " declares"));
        }
      }
    }

    return errors;
  }

  /**
   * The section id part of a registry key written {@code <SECTIONID>.<slot>}. A
   * key with no dot is malformed — the static tier reports it — and is treated
   * whole here so it simply fails to match any section id.
   */
  private static String registrySectionId(String target) {
    int dot = target.indexOf('.');
    return dot <= 0 ? target : target.substring(0, dot);
  }

  /**
   * The registry section ids that are <b>in scope</b> for {@code doc}: the
   * {@code @SectionId} of every class reachable from a document root the document
   * actually uses (csre2).
   *
   * <p>A {@code refersTo} target names its registry by section id, and a document
   * can only ever declare entries of registries its own root reaches. Anything
   * outside this set is absent from the document by construction — which is
   * precisely the case the dangling-reference check must not call an error.
   *
   * <p>The roots are read off the document rather than passed in: every path
   * begins with its root's segment, so the document already says which root(s) it
   * belongs to. A document spanning several roots contributes the union.
   */
  private static Set<String> registryScope(SpecReflection refl, SpecDocument doc) {
    Set<String> rootTypes = new LinkedHashSet<>();
    for (Set<String> group :
        List.of(doc.contentPaths(), doc.formPaths(), doc.listPaths(), doc.headlinePaths())) {
      for (String path : group) {
        int slash = path.indexOf('/');
        String segment = slash < 0 ? path : path.substring(0, slash);
        SpecRoot root = refl.rootForSegment(segment);
        if (root != null) {
          rootTypes.add(root.type);
        }
      }
    }

    Set<String> ids = new HashSet<>();
    for (String type : rootTypes) {
      for (String name : refl.reachableClassNames(type)) {
        SpecClass cls = refl.classNamed(name);
        String id = cls == null ? null : cls.sectionId;
        if (id != null && !id.isEmpty()) {
          ids.add(id);
        }
      }
    }
    return ids;
  }
}
