// TomSpecs sample — building tooling ON a specification (Java).
//
// The Java port of `../bin/build_a_specification_tool.dart`: the same five
// steps over the same fixture. Its output differs from the Dart sample where
// the Dart text names a Dart-only surface, and where Java names an API
// differently; `expected_output.txt` here records the Java output, and
// README.md says where it differs.
//
// Run (from this folder; see README.md):  mvn -q compile exec:java
//
// For the reader who is not authoring specifications but writing programs
// that read them: an editor, a linter, a report, an importer, a migration.
// That reader needs four things, and this sample walks them in the order they
// are needed:
//
//   1. REFLECTION   — what the model CAN hold, read from the metadata tree
//   2. GENERIC      — what a document DOES hold, with no compile-time
//                     knowledge of its shape
//   3. SCHEMA       — the generated schema, where it comes from and what it is
//   4. VALIDATION   — the two runtime tiers, and the third that is not here
//   5. A TOOL       — a completeness report built on all four
//
// The individual APIs are demonstrated one at a time in the facade project's
// own examples (`tom_som_java_v0/examples/`): `BGenericDocument.java` and
// `CReflectionMetadata.java`.

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import tom_som_java_v0.TomSomV0;
import tom_som_java_v0.TomSomV0Meta;
import tom_som_runtime.DocSpecsSchema;
import tom_som_runtime.DocSpecsSectionType;
import tom_som_runtime.DocSpecsValidator;
import tom_som_runtime.DocSpecsViolation;
import tom_som_runtime.FormFieldSpec;
import tom_som_runtime.Json;
import tom_som_runtime.SomMetaNode;
import tom_som_runtime.SpecAnnotation;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecField;
import tom_som_runtime.SpecFieldKind;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecModelStampCheck;
import tom_som_runtime.SpecReflection;
import tom_som_runtime.SpecResolution;
import tom_som_runtime.SpecRoot;
import tom_som_runtime.SpecValidationCode;
import tom_som_runtime.SpecValidationError;
import tom_som_runtime.SpecValidator;

public final class Main {
  private Main() {}

  /** The document root this sample inspects. */
  private static final String K_ROOT = "D00SolutionBlueprint";

  /** That root's addressable segment — the first element of every path in it. */
  private static final String K_ROOT_SEGMENT = "SBP";

  /**
   * The creation date section-id generation is pinned to. {@code SomList.add}
   * derives an item's id from the current date, so an unpinned run would emit
   * different ids every day and `expected_output.txt` would record the day it
   * was taken rather than the pipeline.
   */
  private static final LocalDate K_AUTHORED_ON = LocalDate.of(2026, 1, 1);

  /**
   * The report's title column width. Titles are clipped to it rather than
   * wrapped: a completeness report is scanned down its numbers, and a wrapped
   * title puts a row's two halves on different lines.
   */
  private static final int K_TITLE_WIDTH = 38;

  public static void main(String[] args) throws IOException {
    Map<String, Object> meta = Json.parseObject(readCheckout("tom_som_java_v0/meta/spec_model.meta.json"));
    SpecModel model = SpecModel.fromJson(meta);
    DocSpecsSchema schema = DocSpecsSchema.fromYamlText(readCheckout(
        "tom_som_java_v0/schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml"));

    SpecDocument doc = new SpecDocument();
    authorFixture(new TomSomV0.D00SolutionBlueprint(doc));

    section(0, "The document this run inspects");
    print("A Solution Blueprint with a handful of sections written and the");
    print("rest left blank — small enough that every number below can be");
    print("checked by reading `authorFixture` in this file.");
    print("");
    print("  content leaves written : " + doc.contentPaths().size());
    print("  form sections written  : " + doc.formPaths().size());
    print("  lists with items       : " + doc.listPaths().size());

    reflectionStep(model, meta);
    genericAccess(model, doc);
    theSchema(schema);
    validation(model, schema, doc);
    theTool(model, schema, doc);
  }

  // =========================================================================
  // 1. Reflection — what the model CAN hold
  // =========================================================================

  private static void reflectionStep(SpecModel model, Map<String, Object> meta) {
    section(1, "Reflection — what the model CAN hold");
    print("`SpecModel` is the exported class graph; `SpecReflection` is the");
    print("value-free query surface over it. No document is involved here.");
    print("");

    print("THE TWO VERSION STAMPS. They answer different questions and a tool");
    print("that checks one for the other will accept a file it cannot read:");
    print("  modelVersion      = " + model.modelVersion + "  — WHICH MODEL this snapshot describes");
    print("  metaSchemaVersion = " + model.metaSchemaVersion
        + "  — the FILE FORMAT the snapshot itself is written in");
    print("  modelVersionLabel = " + model.modelVersionLabel);
    // The stamp is printed as the snapshot writes it, so it reads the same in
    // every port whatever precision its clock type keeps.
    print("  generatedAt       = " + meta.get("generatedAt"));
    print("");
    print("A tool reads `metaSchemaVersion` to decide whether it can parse the");
    print("file at all, and `modelVersion` to decide whether the documents it");
    print("holds are the ones this model describes. `modelVersionLabel` is a");
    print("build label for humans — never branch on it.");
    print("");

    // A snapshot is a photograph. `checkStamp` compares what the exporter
    // DECLARED against what survived to the reader, and ages the file out.
    // `now` is derived from the model's own stamp so the printed age stays at
    // exactly the offset this sample means to demonstrate; a null maxAge takes
    // the runtime's default.
    Instant exportedAt = model.generatedAt != null ? model.generatedAt : Instant.parse("2026-01-01T00:00:00Z");
    SpecModelStampCheck stamp = model.checkStamp(null, exportedAt.plus(Duration.ofDays(3)));
    print("SNAPSHOT CHECK (`checkStamp`), against a fixed clock:");
    String age = stamp.age == null ? "null" : String.valueOf(stamp.age.toDays());
    print("  age                 : " + age + " days (aged: " + stamp.isAged() + ")");
    print("  classes  declared/actual : " + stamp.declaredClassCount + "/" + stamp.actualClassCount
        + "  disagrees: " + stamp.classCountDisagrees());
    print("  roots    declared/actual : " + stamp.declaredRootCount + "/" + stamp.actualRootCount
        + "  disagrees: " + stamp.rootCountDisagrees());
    print("  Declared-vs-actual is not redundant: the declared value is what");
    print("  the exporter recorded, the actual value is what survived to the");
    print("  reader, and a truncated file is exactly where they part.");
    print("");

    SpecReflection reflection = new SpecReflection(model);
    print("SHAPE:");
    print("  document roots : " + reflection.roots().size());
    print("  classes        : " + reflection.classes().size());
    print("  container root : " + model.containerRoot
        + " — the one true tree root, which is not itself a document");
    print("");

    SpecRoot root = reflection.rootForSegment("SBP");
    List<SpecField> fields = reflection.fieldsOf(root.type);
    print("FIELDS of " + root.type + " (" + fields.size() + " total, first 4):");
    for (SpecField f : fields.subList(0, 4)) {
      print("  " + padRight(f.name, 24) + " kind=" + padRight(kindName(f.kind), 8) + " "
          + (f.type == null ? "" : f.type));
    }
    print("");

    // A form's slots are on the field itself, not on a separate class — the
    // shape a tool must handle to render or fill one.
    SpecField form = reflection.fieldsOf("DataEntityEntry").stream()
        .filter(f -> f.kind == SpecFieldKind.FORM).findFirst().orElseThrow();
    print("FORM SLOTS of DataEntityEntry." + form.name + " (section id " + form.sectionId + "):");
    for (FormFieldSpec slot : form.formFields) {
      print("  " + padRight(slot.name, 16) + " " + slot.label);
    }
    print("");

    print("ANNOTATIONS the meta carries — the model's own metadata, exported");
    print("into the snapshot and therefore visible in ALL NINE language");
    print("runtimes, not just Dart:");
    for (SpecAnnotation a : reflection.annotationsOf(root.type)) {
      String args = a.arguments == null ? "" : String.join(", ", a.arguments.keySet());
      print("  @" + a.name + (args.isEmpty() ? "" : "(" + args + ")"));
    }
    // The display semantics of these annotations (`kRenderedAnnotations`) are
    // in the Dart runtime only: they are what the two Flutter apps share.
    print("  How each is displayed is the Dart runtime's (`kRenderedAnnotations`,");
    print("  shared by the two Flutter apps); the annotations themselves are");
    print("  data every runtime reads.");
    print("");

    print("PATH RESOLUTION — a document path to the model node it lands on:");
    for (String p : List.of(
        "SBP",
        "SBP/content",
        "SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST",
        "SBP/informationAndDataModel/nosuchthing")) {
      SpecResolution r = reflection.resolve(p);
      print("  " + padRight(p, 50) + " "
          + (r == null ? "(unresolved)" : "kind=" + r.kind.value + "  leaf=" + r.isValueLeaf()));
    }
  }

  // =========================================================================
  // 2. Generic access — what a document DOES hold
  // =========================================================================

  private static void genericAccess(SpecModel model, SpecDocument doc) {
    section(2, "Generic access — what the document DOES hold");
    print("`SpecDocument` is a sparse, path-keyed store. A tool reads it");
    print("without knowing the document's shape, and asks the model what each");
    print("path means. That pairing is the whole of generic access.");
    print("");

    SpecReflection reflection = new SpecReflection(model);
    print("EVERY written content leaf, resolved against the model:");
    for (String p : sorted(doc.contentPaths())) {
      SpecResolution r = reflection.resolve(p);
      print("  " + padRight(p, 52) + " " + (r == null ? "?" : r.kind.value));
      print("      " + clip(orEmpty(doc.content(p)), 66));
    }
    print("");

    print("EVERY written form section, slot by slot:");
    for (String p : sorted(doc.formPaths())) {
      print("  " + p);
      for (String slot : sorted(doc.formFieldNames(p))) {
        print("      " + padRight(slot, 16) + " " + clip(orEmpty(doc.formField(p, slot)), 52));
      }
    }
    print("");

    print("EVERY list, with its items' section ids:");
    for (String p : sorted(doc.listPaths())) {
      print("  " + padRight(p, 52) + " " + doc.listItemCount(p) + " item(s)");
      for (String id : doc.listItemSectionIds(p)) {
        print("      " + id);
      }
    }
    print("");

    print("WHERE PATHS COME FROM. A tool must never hard-code a path literal —");
    print("a literal is undiscoverable and rots silently when the model moves.");
    print("Two safe sources, both from the generated metadata module:");
    print("");
    print("  1. the generated metadata refs —");
    print("     TomSomV0Meta.D00SolutionBlueprintMeta.informationAndDataModel().dataModel().path");
    print("       = " + TomSomV0Meta.D00SolutionBlueprintMeta.informationAndDataModel().dataModel().path);
    print("  2. the id-keyed metadata tree, for a path known only at runtime —");
    SomMetaNode node = TomSomV0Meta.D00SolutionBlueprintMetaTree.byId("DAENT-ENTI-LST");
    print("     TomSomV0Meta.D00SolutionBlueprintMetaTree.byId(\"DAENT-ENTI-LST\")");
    print("       = " + (node == null ? null : node.path()));
    print("");
    print("  The tree also goes the other way: byPath gives the node, and with");
    print("  it the class, kind and children a generic renderer needs.");
    SomMetaNode byPath = TomSomV0Meta.D00SolutionBlueprintMetaTree.byPath("SBP/informationAndDataModel/dataModel");
    print("     byPath(\"SBP/informationAndDataModel/dataModel\")");
    print("       class=" + byPath.className + " kind=" + byPath.kind + " children=" + byPath.children.size());
  }

  // =========================================================================
  // 3. The generated schema
  // =========================================================================

  private static void theSchema(DocSpecsSchema schema) {
    section(3, "The generated schema");
    print("Each of the 14 document roots has a schema GENERATED from the model");
    print("and SHIPPED as data inside the facade package, under");
    print("`schemas/<document>/<document>.1.0.docspecs-schema.yaml`. A tool");
    print("loads one; it never writes one, and never derives one itself.");
    print("");
    print("IT IS A DocSpecs SCHEMA, NOT JSON SCHEMA. It describes a *markdown*");
    print("document — headings, their ids, their formats, the form fields a");
    print("section carries and which of them are required. A tool reaching for");
    print("a JSON-Schema validator will not find one, because the artifact the");
    print("schema governs is not JSON.");
    print("");
    print("  root section id : " + schema.rootSectionId());
    print("  section types   : " + schema.sectionTypes.size());
    print("");
    print("  That count is large because a Solution Blueprint SEEDS the twelve");
    print("  Phase-3 documents: its own section classes ARE those documents'");
    print("  types, so its schema covers every section id they define. Step 5");
    print("  meets the same fact from the other side.");
    print("");
    print("  A section type resolves by ID PREFIX, which is how a generated id");
    print("  like `DAENT-ENTI-7` finds its type without the schema listing");
    print("  every instance:");
    for (String id : List.of("DAENT-IDEN", "DAENT-ENTI-7", "NOSUCH-1")) {
      DocSpecsSectionType t = schema.resolveSectionType(id);
      print("    " + padRight(id, 16) + " -> "
          + (t == null ? "(no type — a tool treats this as unknownSection)" : t.prefix));
    }
  }

  // =========================================================================
  // 4. Validation — the tiers
  // =========================================================================

  private static void validation(SpecModel model, DocSpecsSchema schema, SpecDocument doc) {
    section(4, "Validation — three tiers, two of them here");
    print("THIS IS THE DISTINCTION TOOLING AUTHORS MISS. A tool that wants one");
    print("tier and calls another gets nothing useful — not an error, just an");
    print("empty list that reads like a pass.");
    print("");
    print("  STATIC tier   — checks the MODEL'S OWN ANNOTATIONS: field-type");
    print("                  rules, @ContentType compatibility, cycles, the");
    print("                  §10.2 structural invariants. Runs ONCE at");
    print("                  generation time, in");
    print("                  `tom_specs_clitool/lib/src/validator.dart`, and is");
    print("                  deliberately NOT part of the nine-language runtime");
    print("                  surface. Not reachable from this sample, and that");
    print("                  is the point: by the time a document exists, this");
    print("                  tier has already run.");
    print("  INSTANCE tier — checks A DOCUMENT'S VALUES against the model:");
    print("                  `validateDocument` (SOM §9). In every runtime.");
    print("  DOCUMENT tier — checks a MARKDOWN RENDITION against the generated");
    print("                  schema: `DocSpecsValidator` (SOM §14).");
    print("");
    print("The two runtime tiers overlap and neither implies the other:");
    print("`validateDocument` reports a required field left empty in a form the");
    print("document holds, but not a required section that is absent; the");
    print("schema validator reports the absent section, but does not follow a");
    print("reference it sees filled. A tool that wants \"is this document good?\"");
    print("runs BOTH.");
    print("");

    List<SpecValidationError> instance = SpecValidator.validateDocument(model, doc);
    List<DocSpecsViolation> document =
        new DocSpecsValidator(schema).validateMarkdown(doc.toMarkdown(model, K_ROOT));
    print("THE FIXTURE, both tiers:");
    print("  instance tier : " + instance.size() + " error(s)");
    print("  document tier : " + document.size() + " violation(s)");
    for (DocSpecsViolation v : document.subList(0, Math.min(4, document.size()))) {
      print("    line " + v.line + ": " + v.rule + " [" + v.sectionId + "] " + clip(v.message, 54));
    }
    if (document.size() > 4) {
      print("    … and " + (document.size() - 4) + " more");
    }
    print("");

    // A document broken on purpose, to show the instance tier firing where the
    // document tier cannot see anything wrong.
    SpecDocument broken = new SpecDocument();
    authorFixture(new TomSomV0.D00SolutionBlueprint(broken));
    broken.setContent("SBP/informationAndDataModel/nosuchsection/content", "x");
    broken.setFormField("SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAENT-IDEN", "notAField", "x");
    print("A DELIBERATELY BROKEN COPY — one path the model does not have, one");
    print("form slot the form does not declare:");
    for (SpecValidationError e : SpecValidator.validateDocument(model, broken)) {
      print("  " + padRight(e.code.value, 20) + " " + clip(e.path, 50));
    }
    print("");

    print("THE CLOSED VERDICT SETS. One is an enum and the other a closed list");
    print("of string constants, so a tool switches over them exhaustively rather");
    print("than matching on message text:");
    List<String> codes = Arrays.stream(SpecValidationCode.values()).map(c -> c.value).toList();
    print("  SpecValidationCode  (" + codes.size() + "): " + String.join(", ", codes));
    List<String> rules = Arrays.asList(DocSpecsViolation.ALL_RULES);
    print("  DocSpecsViolation.ALL_RULES (" + rules.size() + "):");
    for (int i = 0; i < rules.size(); i += 4) {
      print("    " + String.join(", ", rules.subList(i, Math.min(i + 4, rules.size()))));
    }
  }

  // =========================================================================
  // 5. The tool
  // =========================================================================

  private record CoverageRow(String title, int offered, int written) {}

  private record CoverageReport(List<CoverageRow> rows, int offered, int written) {}

  private static final class Counter {
    int offered;
    int written;
  }

  private static void theTool(SpecModel model, DocSpecsSchema schema, SpecDocument doc) {
    section(5, "A tool: the completeness report");
    print("Built on all four surfaces above, and it reports something NEITHER");
    print("validator can. The schema names what is REQUIRED and missing; an");
    print("optional section left blank is perfectly valid and no validator will");
    print("ever mention it. But \"which parts of this specification has nobody");
    print("written yet?\" is the question a specification author actually has,");
    print("and answering it means walking the model and asking the document.");
    print("");

    CoverageReport report = specificationCoverage(model, doc, K_ROOT_SEGMENT);
    print("  " + padRight("SECTION", K_TITLE_WIDTH) + " WRITTEN / OFFERED");
    for (CoverageRow row : report.rows()) {
      String bar = row.offered() == 0 ? "" : padLeft(pct(row.written(), row.offered()) + "%", 6);
      print("  " + padRight(row.title(), K_TITLE_WIDTH) + " "
          + padLeft(String.valueOf(row.written()), 5) + " / " + padLeft(String.valueOf(row.offered()), 5) + bar);
    }
    print("  " + "-".repeat(K_TITLE_WIDTH) + " " + "-".repeat(19));
    print("  " + padRight("TOTAL", K_TITLE_WIDTH) + " "
        + padLeft(String.valueOf(report.written()), 5) + " / " + padLeft(String.valueOf(report.offered()), 5)
        + padLeft(pct(report.written(), report.offered()) + "%", 6));
    print("");
    CoverageRow largest = report.rows().get(0);
    for (CoverageRow row : report.rows()) {
      if (row.offered() > largest.offered()) largest = row;
    }
    print("  " + largest.title().split(" ")[0] + " offers " + largest.offered()
        + " positions because a Solution Blueprint SEEDS");
    print("  the twelve Phase-3 documents: its section classes ARE those");
    print("  documents' types, so the model surface under an SBP root includes");
    print("  everything it seeds. A tool that reports \"0 %\" against a number");
    print("  like that should say what the denominator is — which is why the");
    print("  report is per section and not one headline figure.");
    print("");
    print("  Required-and-missing, from the schema tier, for contrast:");
    long required = new DocSpecsValidator(schema).validateMarkdown(doc.toMarkdown(model, K_ROOT)).stream()
        .filter(v -> v.rule.equals(DocSpecsViolation.RULE_MISSING_REQUIRED_FIELD)).count();
    print("    " + required + " missing required field(s) — the only gaps a validator");
    print("    will name, out of " + (report.offered() - report.written()) + " unwritten positions.");
    print("");
    print("That gap between the two numbers is the tool's reason to exist.");
  }

  /**
   * Walks {@code model} from {@code rootSegment} and counts, per top-level
   * section, how many content positions the model offers and how many
   * {@code doc} has written.
   *
   * <p><b>Lists count as one position, not as their items.</b> A list the
   * author left empty offers exactly one thing to write — the first item — and
   * a list with forty items has not made the document forty times more
   * complete.
   *
   * <p>The walk is entirely generic: it knows no class or field name, so it
   * works unchanged against any of the fourteen document roots.
   */
  private static CoverageReport specificationCoverage(SpecModel model, SpecDocument doc, String rootSegment) {
    SpecReflection reflection = new SpecReflection(model);
    SpecRoot root = reflection.rootForSegment(rootSegment);
    List<CoverageRow> rows = new ArrayList<>();
    int offered = 0;
    int written = 0;
    for (SpecField field : reflection.fieldsOf(root.type)) {
      if (field.kind == SpecFieldKind.CONTENT) continue; // the root's own body
      Counter counter = new Counter();
      walk(reflection, doc, counter, field, rootSegment + "/" + reflection.fieldSegment(field), Set.of(root.type));
      if (counter.offered == 0) continue;
      rows.add(new CoverageRow(rowTitle(field), counter.offered, counter.written));
      offered += counter.offered;
      written += counter.written;
    }
    return new CoverageReport(rows, offered, written);
  }

  /**
   * Adds every content position under {@code field} at {@code path}.
   * {@code seen} carries the class names already on this branch; the model is
   * a graph, and a section type that can contain itself would otherwise
   * recurse forever.
   */
  private static void walk(SpecReflection reflection, SpecDocument doc, Counter counter,
      SpecField field, String path, Set<String> seen) {
    switch (field.kind) {
      case CONTENT, SCALAR, ENUM -> {
        counter.offered++;
        if (doc.hasContent(path)) counter.written++;
      }
      case FORM -> {
        for (FormFieldSpec slot : field.formFields) {
          counter.offered++;
          String value = doc.formField(path, slot.name);
          if (value != null && !value.isEmpty()) counter.written++;
        }
      }
      case LIST -> {
        counter.offered++;
        if (doc.listItemCount(path) > 0) counter.written++;
      }
      case SECTION, COMPLEX -> {
        String type = field.type;
        if (type == null || type.isEmpty() || seen.contains(type)) return;
        Set<String> next = new HashSet<>(seen);
        next.add(type);
        for (SpecField child : reflection.fieldsOf(type)) {
          walk(reflection, doc, counter, child, path + "/" + reflection.fieldSegment(child), next);
        }
      }
      default -> { }
    }
  }

  /**
   * A section's title for the report — its model doc comment's first
   * sentence, falling back to the field name where the model carries no doc.
   */
  private static String rowTitle(SpecField field) {
    String text = (field.doc == null ? "" : field.doc).split("\n", -1)[0].trim();
    int stop = text.indexOf(". ");
    if (stop >= 0) text = text.substring(0, stop);
    while (text.endsWith(".")) text = text.substring(0, text.length() - 1);
    text = text.trim();
    if (text.isEmpty()) return field.name;
    int[] cps = text.codePoints().toArray();
    return cps.length <= K_TITLE_WIDTH ? text : new String(cps, 0, K_TITLE_WIDTH - 1) + "…";
  }

  // =========================================================================
  // The fixture
  // =========================================================================

  /**
   * Writes the small, deliberately incomplete document this run inspects —
   * the same one the Dart sample writes.
   */
  private static void authorFixture(TomSomV0.D00SolutionBlueprint sbp) {
    sbp.content("A platform that unifies our fragmented order systems.");
    sbp.introductionAndScope().content("Replace three regional order desks with one intake service.");
    sbp.currentLandscape().content("Three legacy systems with no shared customer record.");

    var metrics = sbp.currentLandscape().operationalMetrics();
    metrics.addContent("Average order turnaround: 4.2 days.", null, K_AUTHORED_ON);
    metrics.addContent("Manual reconciliation: ~12 hours per week.", null, K_AUTHORED_ON);

    var customer = sbp.informationAndDataModel().dataModel().entities().add(null, K_AUTHORED_ON);
    customer.$headline("Customer");
    var identity = customer.identity();
    identity.entityName("Customer");
    identity.tableName("customers");
    identity.description("A party that places orders.");
    // `category` is written and `aggregateRoot` is not, and `aggregateRoot` is
    // REQUIRED — so the schema tier has one real violation to report in step 4.
    customer.classification().category("MasterData");
  }

  // =========================================================================
  // Small helpers
  // =========================================================================

  /**
   * Reads a file of the checkout, given relative to `tom_ai/ai_build` (the
   * `tomspecs.checkout` system property the pom sets). The Dart packages ship
   * the model and schemas with accessors; the Java artifacts ship neither, so
   * they are read as files.
   */
  private static String readCheckout(String relative) throws IOException {
    Path checkout = Path.of(System.getProperty("tomspecs.checkout", "../../..")).normalize();
    return Files.readString(checkout.resolve(relative));
  }

  private static void print(String line) {
    System.out.println(line);
  }

  private static void section(int n, String title) {
    print("");
    print("=".repeat(74));
    print(n + ". " + title);
    print("=".repeat(74));
  }

  private static String clip(String s, int width) {
    int[] cps = s.replace('\n', ' ').codePoints().toArray();
    return cps.length <= width ? new String(cps, 0, cps.length) : new String(cps, 0, width - 1) + "…";
  }

  private static String padRight(String s, int width) {
    int n = s.codePointCount(0, s.length());
    return n >= width ? s : s + " ".repeat(width - n);
  }

  private static String padLeft(String s, int width) {
    return s.length() >= width ? s : " ".repeat(width - s.length()) + s;
  }

  private static long pct(int written, int offered) {
    return Math.round(100.0 * written / offered);
  }

  private static List<String> sorted(Collection<String> values) {
    return values.stream().sorted().collect(Collectors.toList());
  }

  private static String orEmpty(String s) {
    return s == null ? "" : s;
  }

  /** A field kind by the name the Dart enum gives it (`enum` is `enumValue`). */
  private static String kindName(SpecFieldKind kind) {
    return kind == SpecFieldKind.ENUM ? "enumValue" : kind.raw;
  }
}
