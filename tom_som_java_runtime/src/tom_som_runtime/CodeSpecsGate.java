package tom_som_runtime;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * The Phase-4 mechanical gate — Stage A of {@code codespecs_prompt.md} §4, all
 * five checks run as one, over (model, document, catalogue, schema).
 *
 * <p>Every check runs; none stops the others. A project fixing one wants to see
 * the rest, and a gate that stopped at the first failure would report a
 * different set of problems on every run.
 *
 * <p>A check that could not run is reported as <b>not run</b>, with its reason,
 * and the gate does not pass: a skipped check must never read as a passed one.
 */
public final class CodeSpecsGate {
  private static final String NO_TABLES =
      "the catalogue carries no gate tables (written before "
          + "`codespecs_prompt.md` §4.4/§4.5 were transcribed)";

  /** The resolved object model. */
  public final SpecModel model;

  /** The document under Phase 4. */
  public final SpecDocument document;

  /** The area catalogue — its {@code gate} tables drive A4 and A5. */
  public final CodeSpecsAreaCatalog catalog;

  /** The DocSpecs schema of the document's root; A1 does not run without it. */
  public final DocSpecsSchema schema;

  /**
   * The document root to walk — type name or section id; {@code null} means the
   * document's single populated root, as the extractor does.
   */
  public final String rootType;

  /** Holds the inputs; {@link #run} does the work. */
  public CodeSpecsGate(
      SpecModel model,
      SpecDocument document,
      CodeSpecsAreaCatalog catalog,
      DocSpecsSchema schema,
      String rootType) {
    this.model = model;
    this.document = document;
    this.catalog = catalog;
    this.schema = schema;
    this.rootType = rootType;
  }

  public CodeSpecsGate(
      SpecModel model, SpecDocument document, CodeSpecsAreaCatalog catalog, DocSpecsSchema schema) {
    this(model, document, catalog, schema, null);
  }

  /** Runs all five checks. */
  public CodeSpecsGateReport run() {
    CodeSpecsGateCheckResult a1 = a1();
    CodeSpecsGateCheckResult a2 = a2();
    List<CodeSpecsExtract>[] extractsOut = newExtractsHolder();
    CodeSpecsGateCheckResult a3 = a3(extractsOut);
    List<CodeSpecsExtract> extracts = extractsOut[0];
    CodeSpecsGateCheckResult a4;
    if (!catalog.hasGateTables) {
      a4 = CodeSpecsGateCheckResult.notRun(CodeSpecsGateCheck.A4, NO_TABLES);
    } else if (extracts == null) {
      a4 =
          CodeSpecsGateCheckResult.notRun(
              CodeSpecsGateCheck.A4,
              "A3 did not complete, so there is no extraction run to read "
                  + "the used areas from");
    } else {
      a4 = a4(extracts);
    }
    CodeSpecsGateCheckResult a5 =
        catalog.hasGateTables
            ? a5()
            : CodeSpecsGateCheckResult.notRun(CodeSpecsGateCheck.A5, NO_TABLES);
    return new CodeSpecsGateReport(Arrays.asList(a1, a2, a3, a4, a5), extracts);
  }

  @SuppressWarnings("unchecked")
  private static List<CodeSpecsExtract>[] newExtractsHolder() {
    return (List<CodeSpecsExtract>[]) new List<?>[1];
  }

  private CodeSpecsGateCheckResult a1() {
    if (schema == null) {
      return CodeSpecsGateCheckResult.notRun(
          CodeSpecsGateCheck.A1, "no DocSpecs schema was supplied");
    }
    String markdown = document.toMarkdown(model, rootType);
    List<CodeSpecsGateFinding> findings = new ArrayList<>();
    for (DocSpecsViolation v : new DocSpecsValidator(schema).validateMarkdown(markdown)) {
      String location =
          v.sectionId != null ? v.sectionId : v.path != null ? v.path : "line " + v.line;
      findings.add(
          new CodeSpecsGateFinding(
              CodeSpecsGateCheck.A1, v.rule, location, "line " + v.line + ": " + v.message));
    }
    return CodeSpecsGateCheckResult.ran(CodeSpecsGateCheck.A1, findings);
  }

  private CodeSpecsGateCheckResult a2() {
    List<CodeSpecsGateFinding> findings = new ArrayList<>();
    for (SpecValidationError e : SpecValidator.validateDocument(model, document)) {
      findings.add(
          new CodeSpecsGateFinding(CodeSpecsGateCheck.A2, e.code.value, e.path, e.message));
    }
    return CodeSpecsGateCheckResult.ran(CodeSpecsGateCheck.A2, findings);
  }

  /**
   * A3 collects <b>every</b> unrouted class over the non-strict walk, rather than
   * the first one the strict walk throws on; only when there is none does it run
   * the extraction itself, handing the extracts back through {@code out[0]}.
   */
  private CodeSpecsGateCheckResult a3(List<CodeSpecsExtract>[] out) {
    CodeSpecsExtractor extractor;
    try {
      extractor = new CodeSpecsExtractor(model, document, catalog, rootType);
    } catch (CodeSpecsExtractError e) {
      List<CodeSpecsGateFinding> findings = new ArrayList<>();
      findings.add(new CodeSpecsGateFinding(CodeSpecsGateCheck.A3, "root", e.path, e.getMessage()));
      return CodeSpecsGateCheckResult.ran(CodeSpecsGateCheck.A3, findings);
    }
    List<CodeSpecsGateFinding> unrouted = new ArrayList<>();
    for (CodeSpecsRouting r : extractor.routings()) {
      if (r.verdict == CodeSpecsRoutingVerdict.UNROUTED) {
        unrouted.add(
            new CodeSpecsGateFinding(
                CodeSpecsGateCheck.A3,
                "unrouted",
                r.path,
                r.className
                    + " carries no @CodeSpecKind, @FollowUpKind or "
                    + "@NoArtifact — its content would reach no extract"));
      }
    }
    if (!unrouted.isEmpty()) {
      return CodeSpecsGateCheckResult.ran(CodeSpecsGateCheck.A3, unrouted);
    }
    out[0] = extractor.extractAll();
    return CodeSpecsGateCheckResult.ran(
        CodeSpecsGateCheck.A3, new ArrayList<CodeSpecsGateFinding>());
  }

  /**
   * A4 over the extraction run: for each obligation whose area's extract is
   * non-empty, every instance of the obligation's class that the extract carries
   * must carry the source value, populated (non-blank); a {@code resolvesTo}
   * obligation's value must also equal a value the run carries at the target.
   */
  private CodeSpecsGateCheckResult a4(List<CodeSpecsExtract> extracts) {
    List<CodeSpecsGateFinding> findings = new ArrayList<>();
    List<CodeSpecsExtractEntry> all = new ArrayList<>();
    for (CodeSpecsExtract x : extracts) {
      all.addAll(x.entries);
    }
    for (CodeSpecsRequiredArgument o : catalog.requiredArguments) {
      CodeSpecsExtract extract = null;
      for (CodeSpecsExtract x : extracts) {
        if (x.area.code.equals(o.area)) {
          extract = x;
          break;
        }
      }
      if (extract == null || extract.entries.isEmpty()) {
        continue;
      }
      // The instances the extract carries of the obligation's class, in
      // document order, each with the populated source value it holds.
      Map<String, String> instances = new LinkedHashMap<>();
      Set<String> applies = new LinkedHashSet<>();
      CodeSpecsFieldRef when = o.when;
      for (CodeSpecsExtractEntry e : extract.entries) {
        if (!e.className.equals(o.className())) {
          continue;
        }
        String instance = parentPath(e.path);
        if (!instances.containsKey(instance)) {
          instances.put(instance, null);
        }
        if (when != null
            && e.fieldName.equals(when.member)
            && eq(e.formField, when.formField)
            && e.value.equals(o.whenEquals)) {
          applies.add(instance);
        }
        if (e.fieldName.equals(o.member())
            && eq(e.formField, o.formField())
            && !e.value.trim().isEmpty()) {
          instances.put(instance, e.value);
        }
      }
      for (Map.Entry<String, String> me : instances.entrySet()) {
        String instance = me.getKey();
        String value = me.getValue();
        if (when != null && !applies.contains(instance)) {
          continue;
        }
        if (value == null) {
          findings.add(
              new CodeSpecsGateFinding(
                  CodeSpecsGateCheck.A4,
                  "missingSource",
                  instance,
                  o.marker + "." + o.argument + " (" + o.area + ") is required, and "
                      + "its source " + o.source() + " is empty here"));
          continue;
        }
        CodeSpecsFieldRef target = o.resolvesTo;
        if (target == null) {
          continue;
        }
        boolean known = false;
        for (CodeSpecsExtractEntry e : all) {
          if (e.className.equals(target.className)
              && e.fieldName.equals(target.member)
              && eq(e.formField, target.formField)
              && e.value.equals(value)) {
            known = true;
            break;
          }
        }
        if (!known) {
          findings.add(
              new CodeSpecsGateFinding(
                  CodeSpecsGateCheck.A4,
                  "unresolvedReference",
                  instance,
                  o.source() + " names `" + value + "`, which no " + target.source()
                      + " in this document carries — " + o.marker + "." + o.argument
                      + " (" + o.area + ") has nothing to resolve against"));
        }
      }
    }
    return CodeSpecsGateCheckResult.ran(CodeSpecsGateCheck.A4, findings);
  }

  /**
   * A5 against the model, not the document: each carrier's class, member and
   * form field must still exist.
   */
  private CodeSpecsGateCheckResult a5() {
    List<CodeSpecsGateFinding> findings = new ArrayList<>();
    for (CodeSpecsCarrier c : catalog.carriers) {
      SpecClass cls = model.classNamed(c.className());
      SpecField field = cls == null ? null : cls.fieldNamed(c.member());
      boolean present = false;
      if (field != null) {
        if (c.formField() == null) {
          present = true;
        } else {
          for (FormFieldSpec f : field.formFields) {
            if (f.name.equals(c.formField())) {
              present = true;
              break;
            }
          }
        }
      }
      if (!present) {
        findings.add(
            new CodeSpecsGateFinding(
                CodeSpecsGateCheck.A5,
                "missingCarrier",
                c.source(),
                "the model no longer offers " + c.source() + " (" + c.introducedBy
                    + ") — a project with that structured fact would have to write prose again"));
      }
    }
    return CodeSpecsGateCheckResult.ran(CodeSpecsGateCheck.A5, findings);
  }

  private static boolean eq(String a, String b) {
    return a == null ? b == null : a.equals(b);
  }

  private static String parentPath(String path) {
    int i = path.lastIndexOf('/');
    return i < 0 ? "" : path.substring(0, i);
  }
}
