// TomSpecs sample — a Phase 4 CodeSpecs run, as far as the Java runtime goes.
//
// The Java port of `../bin/phase4_codespecs_run.dart`. Phase 4 has four
// stages, and the Java runtime carries the first two:
//
//   stage 1  the starting prompt's quality gate   [MECHANICAL]  here
//   stage 2  the extract generator                [MECHANICAL]  here
//   stage 3  the authoring agent                  [JUDGMENT]    the IR, Dart tools
//   stage 4  validating the emitted trio          [MECHANICAL]  Dart tools
//
// Stages 3 and 4 run on the Dart tools (`tomspecs :ir-map`,
// `tomspecs :codespecs-validate`); the Dart sample shows them. This port runs
// the same specification through the gate and the extract generator, and its
// extracts are the ones the Dart sample writes (`CodeSpecsExtract` is in all
// nine runtimes, byte for byte the same).
//
// Run (from this folder; see README.md):  mvn -q compile exec:java

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import tom_som_java_v0.TomSomV0;
import tom_som_runtime.CodeSpecsAreaCatalog;
import tom_som_runtime.CodeSpecsExtract;
import tom_som_runtime.CodeSpecsExtractEntry;
import tom_som_runtime.CodeSpecsGate;
import tom_som_runtime.CodeSpecsGateCheck;
import tom_som_runtime.CodeSpecsGateCheckResult;
import tom_som_runtime.CodeSpecsGateFinding;
import tom_som_runtime.CodeSpecsGateReport;
import tom_som_runtime.DocSpecsSchema;
import tom_som_runtime.Json;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecModel;

public final class Main {
  private Main() {}

  /** The one `@Document` root this run extracts from (codespecs_prompt.md §5). */
  private static final String K_ROOT = "D00SolutionBlueprint";

  /**
   * The creation date section-id generation is pinned to, so the ids (and with
   * them `expected_output.txt`) do not change with the calendar.
   */
  private static final LocalDate K_AUTHORED_ON = LocalDate.of(2026, 1, 1);

  /** What every gate run takes: the model, the schema and the area catalogue. */
  private record Inputs(SpecModel model, DocSpecsSchema schema, CodeSpecsAreaCatalog catalog) {}

  public static void main(String[] args) throws IOException {
    Inputs inputs = new Inputs(
        SpecModel.fromJson(Json.parseObject(readCheckout("tom_som_java_v0/meta/spec_model.meta.json"))),
        DocSpecsSchema.fromYamlText(readCheckout(
            "tom_som_java_v0/schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml")),
        CodeSpecsAreaCatalog.fromJson(Json.parseObject(readCheckout(
            "tom_specs_model/generated-doc/codespecs/codespecs_areas.json"))));

    rule("A Phase 4 CodeSpecs run, stage by stage");
    print("Every step is marked [MECHANICAL] or [JUDGMENT].");
    print("");

    List<CodeSpecsExtract> extracts = variantA(inputs);
    variantB(inputs);

    print("");
    print("Extracts written to build/codespecs_extracts/ (" + extracts.size() * 2 + " files).");
  }

  // -------------------------------------------------------------------------
  // Variant A — a document that passes, taken as far as the extracts.
  // -------------------------------------------------------------------------

  private static List<CodeSpecsExtract> variantA(Inputs inputs) throws IOException {
    SpecDocument doc = new SpecDocument();
    authorSpecification(new TomSomV0.D00SolutionBlueprint(doc), true);

    rule("Variant A — a sufficient specification");
    print("0. The document under Phase 4                 [input]");
    print("   a Solution Blueprint whose information model holds 2 entities");
    print("   and 4 stored attributes; every other section is unwritten.");
    print("");

    CodeSpecsGateReport gate = runGate(inputs, doc);
    if (!gate.passed()) {
      System.err.println("variant A was supposed to pass the gate");
      for (CodeSpecsGateFinding f : gate.findings()) {
        System.err.println("  " + f);
      }
      System.exit(1);
    }
    print("   gate verdict             : PASS — the run may begin");
    print("");

    List<CodeSpecsExtract> extracts = gate.extracts;
    stage2(extracts);
    stages3and4();
    return extracts;
  }

  // -------------------------------------------------------------------------
  // Variant B — the same document with one required field cleared.
  // -------------------------------------------------------------------------

  private static void variantB(Inputs inputs) {
    SpecDocument doc = new SpecDocument();
    authorSpecification(new TomSomV0.D00SolutionBlueprint(doc), false);

    rule("Variant B — the same document, one required field cleared");
    print("Both entities keep their `DAENT-CLAS` section and its `category`, and");
    print("both have `aggregateRoot` cleared. Nothing else changed.");
    print("");

    CodeSpecsGateReport gate = runGate(inputs, doc);
    if (gate.passed()) {
      System.err.println("variant B was supposed to be rejected");
      System.exit(1);
    }
    print("   gate verdict             : REJECTED — the run may not begin");
    print("");
    print("   What the gate names, per finding:");
    for (CodeSpecsGateFinding f : gate.findings()) {
      print("     " + f.check.label() + " " + f.code + " [" + f.location + "] " + f.message);
    }
    print("");
    int a2 = gate.get(CodeSpecsGateCheck.A2).findings.size();
    print("   A2 moved too: " + a2 + " violations, against 0 for variant A. The");
    print("   classification form still holds other values, so its empty");
    print("   required field is reported by both tiers. They part where a value");
    print("   is absent rather than empty: a missing required section is seen by");
    print("   A1 alone. That is why the gate runs both tiers and not either one");
    print("   (codespecs_prompt.md §4.1/§4.2 and its §10.1/§10.2 fixtures).");
    print("");
  }

  // -------------------------------------------------------------------------
  // Stage 1 — the mechanical gate (codespecs_prompt.md §4).
  // -------------------------------------------------------------------------

  private static final Map<CodeSpecsGateCheck, String> TITLES = Map.of(
      CodeSpecsGateCheck.A1, "schema completeness  ",
      CodeSpecsGateCheck.A2, "instance-tier values ",
      CodeSpecsGateCheck.A3, "routing totality     ",
      CodeSpecsGateCheck.A4, "required arguments   ",
      CodeSpecsGateCheck.A5, "structured carriers  ");

  /**
   * Runs the mechanical tier over {@code doc} and prints each check's verdict.
   * All five checks run as one gate and none stops the others; a check that
   * could not run says so, and the gate does not pass.
   */
  private static CodeSpecsGateReport runGate(Inputs inputs, SpecDocument doc) {
    print("1. The starting prompt's quality gate        [MECHANICAL]");
    CodeSpecsGateReport report =
        new CodeSpecsGate(inputs.model(), doc, inputs.catalog(), inputs.schema(), K_ROOT).run();
    for (CodeSpecsGateCheckResult r : report.results) {
      String verdict = !r.ran
          ? "NOT RUN — " + r.notRunReason
          : r.findings.isEmpty()
              ? "pass — 0 findings"
              : "FAIL — " + r.findings.size() + " findings";
      print("   " + r.check.label() + " " + TITLES.get(r.check) + ": " + verdict);
    }
    print("   (A4 held " + inputs.catalog().requiredArguments.size() + " required-argument rows, "
        + "A5 " + inputs.catalog().carriers.size()
        + " carriers, both from the catalogue's gate tables)");
    return report;
  }

  // -------------------------------------------------------------------------
  // Stage 2 — the extract generator.
  // -------------------------------------------------------------------------

  private static void stage2(List<CodeSpecsExtract> extracts) throws IOException {
    print("2. The extract generator                      [MECHANICAL]");
    List<CodeSpecsExtract> populated =
        extracts.stream().filter(e -> !e.entries.isEmpty()).toList();
    print("   areas in the catalogue   : " + extracts.size());
    print("   populated                : " + populated.size());
    for (CodeSpecsExtract e : populated) {
      print("     " + String.format("%-6s", e.area.code) + " " + e.entries.size()
          + " entries  → " + String.join(", ", e.projects));
    }
    print("   empty                    : " + (extracts.size() - populated.size()));
    print("   Most areas are empty because this document says nothing about");
    print("   screens, jobs, reports or migrations. An empty extract is a");
    print("   CANDIDATE for \"not applicable\" — never the verdict itself, which");
    print("   is a judgment and belongs to stage B (codespecs_prompt.md §6.4).");

    Path out = Path.of("build", "codespecs_extracts");
    Files.createDirectories(out);
    for (CodeSpecsExtract e : extracts) {
      Files.writeString(out.resolve(e.fileStem() + ".yaml"), e.toYaml());
      Files.writeString(out.resolve(e.fileStem() + ".md"), e.toMarkdown());
    }
    print("");

    CodeSpecsExtract db = extracts.stream()
        .filter(e -> e.area.code.equals("CE-DB")).findFirst().orElseThrow();
    print("   Area " + db.area.code + " — " + db.area.canonicalId + ", the extract the");
    print("   authoring agent reads in stage 3:");
    print("   built on   : " + db.area.builtOn);
    print("   may cite   : " + String.join(", ", db.citableParts));
    print("   entries carried to the agent (" + db.entries.size() + "):");
    for (CodeSpecsExtractEntry entry : db.entries) {
      print("     " + String.format("%-11s", entry.sectionId) + " "
          + String.format("%-14s", entry.fieldName) + " " + shorten(entry.value));
    }
    print("");
  }

  private static void stages3and4() {
    print("3. The authoring agent                        [JUDGMENT]");
    print("4. Validating the emitted trio                [MECHANICAL]");
    print("   Not in the Java runtime. The authoring agent writes the IR");
    print("   from these extracts, and the Dart tools map and validate it");
    print("   (`tomspecs :ir-map`, `tomspecs :codespecs-validate`); the Dart");
    print("   sample in ../bin/ shows both stages on this same specification.");
    print("");
  }

  // -------------------------------------------------------------------------
  // The specification — the one the Dart sample authors.
  // -------------------------------------------------------------------------

  /**
   * Two entities, four attributes and their keys: one area populated and the
   * rest empty. {@code aggregateRoots} false clears the one required field
   * variant B removes — {@code DAENT-CLAS.aggregateRoot} — and nothing else.
   */
  private static void authorSpecification(TomSomV0.D00SolutionBlueprint sbp, boolean aggregateRoots) {
    sbp.content("Order intake for a single region.");

    // The bounded context CE-SU's required `boundedContext` argument resolves
    // against: an unauthored registry would make the reference dangle at A2.
    var ordering = sbp.solutionArchitectureAndTechnology().technicalFramework().softwareDesign()
        .layeringAndModuleStructure().boundedContexts().add(null, K_AUTHORED_ON);
    ordering.$headline("Ordering");
    ordering.content().contextName("Ordering");
    ordering.content().domainArea("Order management");

    var entities = sbp.informationAndDataModel().dataModel().entities();

    var customer = entities.add(null, K_AUTHORED_ON);
    customer.$headline("Customer");
    customer.content("A party that places orders.");
    customer.identity().entityName("Customer");
    customer.identity().tableName("customers");
    customer.identity().entityAlias("CUST");
    customer.identity().description("A person or organisation that places orders.");
    customer.classification().category("MasterData");
    customer.classification().boundedContext("Ordering");
    if (aggregateRoots) customer.classification().aggregateRoot("Customer");

    var email = customer.attributes().add(null, K_AUTHORED_ON);
    email.$headline("email");
    email.identity().columnName("email");
    email.identity().description("The address order confirmations are sent to.");
    email.dataTypeSpec().physicalType("VARCHAR");

    var displayName = customer.attributes().add(null, K_AUTHORED_ON);
    displayName.$headline("displayName");
    displayName.identity().columnName("display_name");
    displayName.identity().description("The name the customer trades under.");
    displayName.dataTypeSpec().physicalType("VARCHAR");

    // A customer is identified by the address it trades under: a natural key.
    var customerKey = customer.keyAttributes().add(null, K_AUTHORED_ON);
    customerKey.$headline("pk_customers");
    customerKey.content().keyType("Natural");
    customerKey.content().keyColumns("email");
    customerKey.content().description("A customer is identified by its e-mail address.");

    var order = entities.add(null, K_AUTHORED_ON);
    order.$headline("Order");
    order.content("One accepted customer order.");
    order.identity().entityName("Order");
    order.identity().tableName("orders");
    order.identity().entityAlias("ORD");
    order.identity().description("A single order placed by a customer.");
    order.classification().category("TransactionData");
    order.classification().boundedContext("Ordering");
    if (aggregateRoots) order.classification().aggregateRoot("Order");

    var orderId = order.attributes().add(null, K_AUTHORED_ON);
    orderId.$headline("orderId");
    orderId.identity().columnName("order_id");
    orderId.identity().description("The identifier the order is filed under.");
    orderId.dataTypeSpec().physicalType("UUID");

    var orderKey = order.keyAttributes().add(null, K_AUTHORED_ON);
    orderKey.$headline("pk_orders");
    orderKey.content().keyType("Primary");
    orderKey.content().keyColumns("order_id");
    orderKey.content().description("The order identifier.");
    orderKey.generation().generationStrategy("UUID");

    var placedAt = order.attributes().add(null, K_AUTHORED_ON);
    placedAt.$headline("placedAt");
    placedAt.identity().columnName("placed_at");
    placedAt.identity().description("The moment the order was accepted.");
    placedAt.dataTypeSpec().physicalType("TIMESTAMP");
  }

  // -------------------------------------------------------------------------
  // Helpers.
  // -------------------------------------------------------------------------

  /**
   * Reads a file of the checkout, given relative to `tom_ai/ai_build` (the
   * `tomspecs.checkout` system property the pom sets). The Dart packages ship
   * the model, schema and area catalogue with accessors; the Java artifacts
   * ship none of them, so they are read as files.
   */
  private static String readCheckout(String relative) throws IOException {
    Path checkout = Path.of(System.getProperty("tomspecs.checkout", "../../..")).normalize();
    return Files.readString(checkout.resolve(relative));
  }

  private static void print(String line) {
    System.out.println(line);
  }

  private static String shorten(String value) {
    int[] cps = value.codePoints().toArray();
    return cps.length <= 44 ? value : new String(cps, 0, 41) + "...";
  }

  private static void rule(String title) {
    print("=".repeat(72));
    print(title);
    print("=".repeat(72));
  }
}
