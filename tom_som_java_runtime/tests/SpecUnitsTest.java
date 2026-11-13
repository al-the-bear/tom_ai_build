import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import tom_som_runtime.CodeSpecsAreaCatalog;
import tom_som_runtime.CodeSpecsExtract;
import tom_som_runtime.CodeSpecsExtractEntry;
import tom_som_runtime.CodeSpecsExtractor;
import tom_som_runtime.Json;
import tom_som_runtime.SomMetaBridge;
import tom_som_runtime.SomMetaTree;
import tom_som_runtime.SomNode;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentAssembly;
import tom_som_runtime.SpecDocumentMarkdown;
import tom_som_runtime.SpecDocumentYaml;
import tom_som_runtime.SpecGenerationUnit;
import tom_som_runtime.SpecGenerationUnitMapping;
import tom_som_runtime.SpecGenerationUnits;
import tom_som_runtime.SpecMarkdownResult;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecReviewMember;
import tom_som_runtime.SpecReviewMerge;
import tom_som_runtime.SpecReviewMergeOptions;
import tom_som_runtime.SpecReviewedCopy;
import tom_som_runtime.SpecValidationError;
import tom_som_runtime.SpecValidator;
import tom_som_runtime.SpecYamlFormatException;

/**
 * SOM §11.2 {@code units}: the generation units a section goes to. Kept exactly
 * as {@code codeSpec} is — a sparse store by section path, the Markdown heading
 * key {@code units="a,b"} after {@code codeSpec}, the YAML key {@code units}
 * after {@code codeSpec}, the facade's {@code $units}, the snapshot's
 * {@code units} map — and checked by the instance tier's phase 8. Mirrors the
 * Dart reference {@code spec_units_test.dart} (the cases this port has an API
 * for: it has no path normalizer and no captureState) plus the units cases of
 * {@code spec_codespecs_extract_test.dart}, over the shared corpus model and
 * catalogue. A plain {@code main()} that exits 0 on success and 1 on failure.
 */
public final class SpecUnitsTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static final Path CORPUS = Path.of("../tom_som_conformance/corpus");

  private static void check(String name, boolean condition, String detail) {
    if (condition) {
      passed++;
    } else {
      failed.add(name + (detail.isEmpty() ? "" : ": " + detail));
    }
  }

  private static void eq(String name, Object got, Object want) {
    check(name, java.util.Objects.equals(got, want), got + " != " + want);
  }

  private static void contains(String name, String haystack, String needle) {
    check(name, haystack.contains(needle), "missing:\n" + needle + "\nin:\n" + haystack);
  }

  private static Map<String, Object> readJson(String file) throws IOException {
    return Json.parseObject(Files.readString(CORPUS.resolve(file), StandardCharsets.UTF_8));
  }

  /** The shared corpus model: the demo root with the register {@code DEMO/DLV-LST}. */
  private static SpecModel corpusModel() throws IOException {
    return SpecModel.fromJson(readJson("model.meta.json"));
  }

  /** A register declaring {@code u_a} and {@code u_b}, both building something. */
  private static SpecDocument register() {
    SpecDocument d = new SpecDocument();
    String a = d.addListItem("DEMO/DLV-LST");
    d.setFormField(a + "/content", "unitId", "u_a");
    d.setFormField(a + "/content", "component", "ARCM-COMP-A");
    String b = d.addListItem("DEMO/DLV-LST");
    d.setFormField(b + "/content", "unitId", "u_b");
    d.setFormField(b + "/content", "deploymentTarget", "DEPTAR-DEPL-B");
    return d;
  }

  private static <T> List<T> list(Iterable<T> it) {
    List<T> out = new ArrayList<>();
    for (T t : it) {
      out.add(t);
    }
    return out;
  }

  public static void main(String[] args) throws IOException {
    SpecModel model = corpusModel();
    store(model);
    facade();
    markdown(model);
    yaml(model);
    applyMarkdown(model);
    assembly();
    reviewMerge(model);
    validation(model);
    extract(model);
    register(model);

    for (String f : failed) {
      System.out.println("  - " + f);
    }
    if (failed.isEmpty()) {
      System.out.println("OK: " + passed + " checks passed");
      System.exit(0);
    }
    System.out.println("FAIL: " + failed.size() + "/" + (passed + failed.size()) + " checks failed");
    System.exit(1);
  }

  // --- the store --------------------------------------------------------------

  private static void store(SpecModel model) {
    SpecDocument d = new SpecDocument();
    eq("store.absent", d.units("DEMO/TTL"), null);
    d.setUnits("DEMO/TTL", "u_a,u_b");
    eq("store.set", d.units("DEMO/TTL"), "u_a,u_b");
    eq("store.paths", list(d.unitsPaths()), List.of("DEMO/TTL"));
    eq("store.notEmpty", d.isEmpty(), false);
    eq("store.hasValuesUnder", d.hasValuesUnder("DEMO"), true);
    d.setUnits("DEMO/TTL", "");
    eq("store.cleared", d.units("DEMO/TTL"), null);
    eq("store.clearedPaths", list(d.unitsPaths()), List.of());
    eq("store.emptyAgain", d.isEmpty(), true);

    // The snapshot carries `units` beside `codeSpecs`, sorted.
    SpecDocument s = new SpecDocument();
    s.setCodeSpec("DEMO/TTL", "A");
    s.setUnits("DEMO/TTL", "u_b");
    s.setUnits("DEMO/SUM", "u_a");
    Map<String, Object> json = s.toJson();
    eq("snapshot.keys", list(json.keySet()), List.of("codeSpecs", "units"));
    @SuppressWarnings("unchecked")
    Map<String, Object> units = (Map<String, Object>) json.get("units");
    eq("snapshot.sorted", list(units.keySet()), List.of("DEMO/SUM", "DEMO/TTL"));
    SpecDocument back = new SpecDocument();
    back.loadJson(Json.parseObject(Json.write(json)));
    eq("snapshot.roundTrip", back.toJson(), json);
    eq("snapshot.noUnitsNoKey", new SpecDocument().toJson().containsKey("units"), false);

    // removeValuesUnder clears units under the prefix.
    SpecDocument r = new SpecDocument();
    r.setUnits("DEMO/notes", "u_a");
    r.setUnits("DEMO/notes/NOTE-BDY", "u_b");
    r.setUnits("DEMO/TTL", "u_a");
    r.removeValuesUnder("DEMO/notes");
    eq("purge", list(r.unitsPaths()), List.of("DEMO/TTL"));

    // Units move with their list item.
    SpecDocument m = new SpecDocument();
    String first = m.addListItem("DEMO/items");
    String second = m.addListItem("DEMO/items");
    m.setContent(first + "/label", "one");
    m.setContent(second + "/label", "two");
    m.setUnits(second, "u_a");
    m.moveListItem(model, second, 0);
    eq("move.newPosition", m.units("DEMO/items-1"), "u_a");
    eq("move.oldPosition", m.units("DEMO/items-2"), null);
  }

  // --- the facade -------------------------------------------------------------

  private static void facade() {
    SpecDocument d = new SpecDocument();
    SomNode node = new SomNode(d, "DEMO/TTL");
    eq("facade.absent", node.$units(), null);
    node.$units("u_a");
    eq("facade.writes", d.units("DEMO/TTL"), "u_a");
    eq("facade.reads", node.$units(), "u_a");
    node.$units(null);
    eq("facade.nullClears", node.$units(), null);
    node.$units("u_b");
    node.$units("");
    eq("facade.emptyClears", list(d.unitsPaths()), List.of());
    // The sibling setters clear on null the same way, as in every runtime.
    node.$codeSpec("CsTitle");
    node.$codeSpec(null);
    eq("facade.codeSpecNullClears", node.$codeSpec(), null);
    node.$headline("A title");
    node.$headline(null);
    eq("facade.headlineNullClears", node.$headline(), null);
  }

  // --- Markdown ---------------------------------------------------------------

  private static void markdown(SpecModel model) {
    SpecDocument d = new SpecDocument();
    d.setContent("DEMO/TTL", "Hello");
    d.setCodeSpec("DEMO/TTL", "DemoTitle");
    d.setUnits("DEMO/TTL", "u_a,u_b");
    d.setContent("DEMO/SUM", "Sum");
    d.setUnits("DEMO/SUM", "u_a");
    String md = d.toMarkdown(model);
    contains("md.emit.both", md,
        "## <!--[TTL] codeSpec=\"DemoTitle\" units=\"u_a,u_b\"--> Document Title\n");
    contains("md.emit.alone", md, "## <!--[SUM] units=\"u_a\"--> Summary\n");

    String text =
        "# <!--[DEMO] units=u_root--> Demo Document\n\n"
            + "## <!--[TTL] codeSpec=\"DemoTitle\" units=\"u_a,u_b\"--> Title\n\n"
            + "Hello\n\n"
            + "## <!--[SUM] units='u_c'--> Summary\n\n"
            + "Sum\n\n"
            + "## <!--[CNT] codeSpec=\"units=no\"--> Count\n\n"
            + "3\n";
    SpecMarkdownResult result = new SpecDocumentMarkdown(model, new SpecDocument()).parse(text);
    eq("md.parse.clean", result.rejections.size(), 0);
    Map<String, String> want = new LinkedHashMap<>();
    want.put("DEMO", "u_root");
    want.put("DEMO/TTL", "u_a,u_b");
    want.put("DEMO/SUM", "u_c");
    eq("md.parse.units", result.units, want);
    eq("md.parse.codeSpec", result.codeSpecs.get("DEMO/TTL"), "DemoTitle");
    // A `units=` inside a quoted codeSpec value is not the key.
    eq("md.parse.quotedNotKey", result.codeSpecs.get("DEMO/CNT"), "units=no");

    // Round-trips byte-stably through fromMarkdown.
    SpecDocument r = register();
    r.setContent("DEMO/TTL", "Hello");
    r.setCodeSpec("DEMO/TTL", "DemoTitle");
    r.setUnits("DEMO/TTL", "u_a");
    r.setContent("DEMO/notes/NOTE-BDY", "Body");
    r.setUnits("DEMO/notes", "u_a,u_b");
    String rmd = r.toMarkdown(model);
    SpecDocument back = SpecDocument.fromMarkdown(rmd, model).document;
    eq("md.roundTrip.ttl", back.units("DEMO/TTL"), "u_a");
    eq("md.roundTrip.notes", back.units("DEMO/notes"), "u_a,u_b");
    eq("md.roundTrip.bytes", back.toMarkdown(model), rmd);
  }

  // --- YAML -------------------------------------------------------------------

  private static void yaml(SpecModel model) throws IOException {
    SomMetaTree tree = SomMetaBridge.buildSomMetaTree(model, null);

    SpecDocument d = new SpecDocument();
    d.setContent("DEMO/TTL", "Hello");
    d.setHeadline("DEMO/TTL", "Title");
    d.setCodeSpec("DEMO/TTL", "DemoTitle");
    d.setUnits("DEMO/TTL", "u_a");
    d.setContent("DEMO/CNT", "3");
    d.setUnits("DEMO/CNT", "u_b");
    d.setContent("DEMO/notes/NOTE-BDY", "Body");
    d.setUnits("DEMO/notes", "u_a,u_b");
    String yaml = SpecDocumentYaml.encode(d, tree, "1.0");
    contains("yaml.promotion", yaml,
        "    TTL title:\n"
            + "      headline: |2-\n        Title\n"
            + "      codeSpec: |2-\n        DemoTitle\n"
            + "      units: |2-\n        u_a\n"
            + "      content: |2-\n        Hello\n");
    // A non-text scalar keeps its plain content inside the mapping.
    contains("yaml.nonText", yaml,
        "    CNT count:\n      units: |2-\n        u_b\n      content: 3\n");
    contains("yaml.section", yaml, "    NOTE notes:\n      units: |2-\n        u_a,u_b\n");
    SpecDocument back = SpecDocument.fromYaml(yaml, tree);
    eq("yaml.decode", back.toJson(), d.toJson());
    eq("yaml.reencode", SpecDocumentYaml.encode(back, tree, "1.0"), yaml);

    // Units on a form, a list container and a list item round-trip.
    SpecDocument f = register();
    f.setFormField("DEMO/DET", "owner", "Bob");
    f.setUnits("DEMO/DET", "u_a");
    f.setUnits("DEMO/DLV-LST", "u_b");
    f.setUnits("DEMO/DLV-LST-1", "u_a");
    String tagItem = f.addListItem("DEMO/META/tags");
    f.setContent(tagItem, "on");
    f.setUnits(tagItem, "u_b");
    String fyaml = SpecDocumentYaml.encode(f, tree, "1.0");
    SpecDocument fback = SpecDocument.fromYaml(fyaml, tree);
    eq("yaml.members.decode", fback.toJson(), f.toJson());
    eq("yaml.members.reencode", SpecDocumentYaml.encode(fback, tree, "1.0"), fyaml);

    // Refuses units where a child or a form field is named `units`.
    SpecModel clash = SpecModel.fromJson(Json.parseObject(
        "{\"modelVersion\":1,\"roots\":[{\"type\":\"R\",\"title\":\"R\",\"sectionId\":\"R\"}],"
            + "\"classes\":{\"R\":{\"name\":\"R\",\"sectionId\":\"R\",\"fields\":["
            + "{\"name\":\"units\",\"kind\":\"content\"},"
            + "{\"name\":\"shape\",\"kind\":\"form\",\"sectionId\":\"SHP\",\"formFields\":["
            + "{\"name\":\"units\",\"label\":\"Units\",\"type\":\"String\"}]}]}}}"));
    SomMetaTree clashTree = SomMetaBridge.buildSomMetaTree(clash, null);
    SpecDocument child = new SpecDocument();
    child.setUnits("R", "u_a");
    refuses("yaml.clash.child", child, clashTree, "also serializes as key `units`");
    SpecDocument form = new SpecDocument();
    form.setFormField("R/SHP", "units", "3");
    form.setUnits("R/SHP", "u_a");
    refuses("yaml.clash.form", form, clashTree, "field literally named `units`");

    // A list item may not be keyed `units`.
    SpecDocument keyed = new SpecDocument();
    keyed.addListItem("DEMO/DLV-LST", "units");
    refuses("yaml.itemKeyedUnits", keyed, tree, "");
  }

  private static void refuses(String name, SpecDocument d, SomMetaTree tree, String message) {
    try {
      SpecDocumentYaml.encode(d, tree, "1.0");
      check(name, false, "no SpecYamlFormatException");
    } catch (SpecYamlFormatException e) {
      contains(name, e.getMessage(), message);
    }
  }

  // --- apply, assembly, review merge ------------------------------------------

  private static void applyMarkdown(SpecModel model) {
    SpecDocument d = new SpecDocument();
    d.setUnits("DEMO/TTL", "stale");
    d.setUnits("DEMO/SUM", "stale");
    d.setUnits("OTHER/kept", "kept");
    String md =
        "# <!--[DEMO]--> Demo Document\n\n"
            + "## <!--[TTL] units=\"u_a\"--> Document Title\n\nHello\n";
    d.applyMarkdownResult(new SpecDocumentMarkdown(model, new SpecDocument()).parse(md));
    Map<String, Object> want = new LinkedHashMap<>();
    want.put("DEMO/TTL", "u_a");
    want.put("OTHER/kept", "kept");
    eq("apply.units", d.toJson().get("units"), want);
  }

  private static void assembly() {
    SpecDocument a = new SpecDocument();
    a.setUnits("DEMO/TTL", "u_a");
    SpecDocument b = new SpecDocument();
    b.setUnits("DEMO/SUM", "u_b");
    Map<String, SpecDocument> fragments = new LinkedHashMap<>();
    fragments.put("a", a);
    fragments.put("b", b);
    SpecDocumentAssembly ok = SpecDocument.assemble(fragments);
    eq("assembly.ok", ok.ok(), true);
    eq("assembly.merged", ok.document.units("DEMO/SUM"), "u_b");
    SpecDocument c = new SpecDocument();
    c.setUnits("DEMO/TTL", "u_b");
    Map<String, SpecDocument> clashing = new LinkedHashMap<>();
    clashing.put("a", a);
    clashing.put("c", c);
    SpecDocumentAssembly clash = SpecDocument.assemble(clashing);
    eq("assembly.refused", clash.ok(), false);
    eq("assembly.overlaps", clash.overlaps.size(), 1);
    eq("assembly.store", clash.overlaps.get(0).store, "units");
    eq("assembly.path", clash.overlaps.get(0).path, "DEMO/TTL");
  }

  private static void reviewMerge(SpecModel model) {
    SpecDocument base = new SpecDocument();
    String first = base.addListItem("DEMO/items");
    base.setContent(first + "/label", "one");
    SpecDocument copy = new SpecDocument();
    copy.loadJson(base.toJson());
    String added = copy.addListItem("DEMO/items");
    copy.setContent(added + "/label", "two");
    copy.setUnits(added, "u_a");
    SpecReviewMember member = new SpecReviewMember("alice", "Alice", "");
    List<SpecReviewedCopy<SpecDocument>> copies = new ArrayList<>();
    copies.add(new SpecReviewedCopy<>("alice", "Alice", "", copy));
    SpecDocument merged = SpecReviewMerge.mergeReviews(
        base,
        copies,
        new SpecReviewMergeOptions(List.of(member), "2026-11-12", "alice", null, model))
        .merged;
    List<String> items = merged.listItems("DEMO/items");
    eq("merge.items", items.size(), 2);
    eq("merge.units", merged.units(items.get(items.size() - 1)), "u_a");
  }

  // --- validation phase 8 -----------------------------------------------------

  private static List<String> findings(SpecModel model, SpecDocument d) {
    List<String> out = new ArrayList<>();
    for (SpecValidationError e : SpecValidator.validateDocument(model, d)) {
      out.add(e.path + "|" + e.code.value + "|" + e.message);
    }
    return out;
  }

  private static void validation(SpecModel model) {
    SpecDocument clean = register();
    clean.setUnits("DEMO/TTL", "u_a");
    clean.setUnits("DEMO/REG", "u_a,u_b");
    eq("phase8.clean", findings(model, clean), List.of());

    SpecDocument unknown = register();
    unknown.setUnits("DEMO/TTL", "u_x, u_a ,u_y");
    eq("phase8.unknownUnit", findings(model, unknown), List.of(
        "DEMO/TTL|unknownUnit|units names \"u_x\", which no generation unit declares",
        "DEMO/TTL|unknownUnit|units names \"u_y\", which no generation unit declares"));

    SpecDocument unrouted = register();
    unrouted.setUnits("DEMO/META", "u_a");
    unrouted.setUnits("DEMO/META/tags", "u_a");
    unrouted.setUnits("DEMO/control", "u_a");
    unrouted.setUnits("DEMO/DLV-LST-1", "u_a");
    // Routed: a field of a routed class, a list of a routed element.
    unrouted.setUnits("DEMO/PRI", "u_a");
    unrouted.setUnits("DEMO/CARD-LST", "u_a");
    String message = "units is set on a section that routes nothing to CodeSpecs";
    eq("phase8.unitsUnrouted", findings(model, unrouted), List.of(
        "DEMO/DLV-LST-1|unitsUnrouted|" + message,
        "DEMO/META|unitsUnrouted|" + message,
        "DEMO/META/tags|unitsUnrouted|" + message,
        "DEMO/control|unitsUnrouted|" + message));

    SpecDocument reg = register();
    String dup = reg.addListItem("DEMO/DLV-LST");
    reg.setFormField(dup + "/content", "unitId", "u_a");
    reg.setFormField(dup + "/content", "kind", "server");
    // An item with no value at all is absence, not a finding.
    reg.addListItem("DEMO/DLV-LST");
    for (String area : List.of("CE-DB", "ce-db", "CE-", "CE-D1")) {
      String route = reg.addListItem("DEMO/DLV-LST-1/DLR-LST");
      reg.setFormField(route + "/content", "area", area);
      reg.setFormField(route + "/content", "mapping", "dart-tom");
    }
    eq("phase8.register", findings(model, reg), List.of(
        "DEMO/DLV-LST-1/DLR-LST-2|unitAreaMalformed|"
            + "mapping area \"ce-db\" is not an area code (CE-…)",
        "DEMO/DLV-LST-1/DLR-LST-3|unitAreaMalformed|"
            + "mapping area \"CE-\" is not an area code (CE-…)",
        "DEMO/DLV-LST-1/DLR-LST-4|unitAreaMalformed|"
            + "mapping area \"CE-D1\" is not an area code (CE-…)",
        "DEMO/DLV-LST-3|duplicateUnitId|generation unit \"u_a\" is declared twice",
        "DEMO/DLV-LST-3|unitBuildsNothing|"
            + "generation unit \"u_a\" builds neither a deploymentTarget nor a component"));

    // Phase 8 follows the derived values and precedes annotations.
    SpecDocument order = register();
    order.setUnits("DEMO/TTL", "u_x");
    order.setContent("DEMO/SUM", "> ⬆️ **C-1** a\n\n> ⬆️ **C-1** b");
    List<String> codes = new ArrayList<>();
    for (SpecValidationError e : SpecValidator.validateDocument(model, order)) {
      codes.add(e.code.value);
    }
    eq("phase8.order", codes, List.of("unknownUnit", "duplicateAnnotationId"));
  }

  // --- extract ----------------------------------------------------------------

  @SuppressWarnings("unchecked")
  private static void extract(SpecModel model) throws IOException {
    CodeSpecsAreaCatalog catalog = CodeSpecsAreaCatalog.fromJson(
        (Map<String, Object>) readJson("codespecs_extract_cases.json").get("catalog"));
    SpecDocument plain = new SpecDocument();
    plain.loadJson(readJson("state.json"));

    // Inherited and own: the corpus document carries units on `TTL` (its own)
    // and on `notes` (handed down to every entry beneath it).
    Map<String, CodeSpecsExtractEntry> byPath = new LinkedHashMap<>();
    for (CodeSpecsExtract x : new CodeSpecsExtractor(model, plain, catalog).extractAll()) {
      for (CodeSpecsExtractEntry e : x.entries) {
        byPath.put(e.path, e);
      }
    }
    eq("extract.own", byPath.get("DEMO/TTL").units, List.of("demo_server"));
    eq("extract.inherited", byPath.get("DEMO/notes/NOTE-BDY").units,
        List.of("demo_client", "demo_server"));
    eq("extract.none", byPath.get("DEMO/SUM").units, List.of());
    // No section on the way stores units: the register's default, every unit
    // mapping the entry's area, in register order (both demo units map CE-NV).
    eq("extract.registerDefault", byPath.get("DEMO/PRI").units,
        List.of("demo_client", "demo_server"));

    // The nearest wins over every ancestor; values are split and trimmed.
    SpecDocument d = new SpecDocument();
    d.loadJson(readJson("state.json"));
    d.setUnits("DEMO", "app_client");
    d.setUnits("DEMO/notes", "app_server, app_shared");
    d.setUnits("DEMO/SUM", "");
    Map<String, CodeSpecsExtractEntry> near = new LinkedHashMap<>();
    CodeSpecsExtract fm = null;
    for (CodeSpecsExtract x : new CodeSpecsExtractor(model, d, catalog).extractAll()) {
      for (CodeSpecsExtractEntry e : x.entries) {
        near.put(e.path, e);
      }
      if (x.area.code.equals("CE-FM")) {
        fm = x;
      }
    }
    eq("extract.fromRoot", near.get("DEMO/SUM").units, List.of("app_client"));
    eq("extract.ownWins", near.get("DEMO/TTL").units, List.of("demo_server"));
    eq("extract.splitTrimmed", near.get("DEMO/notes/NOTE-BDY").units,
        List.of("app_server", "app_shared"));

    // Written only where set, and read back.
    String yaml = fm.toYaml();
    String md = fm.toMarkdown();
    check("extract.yaml.written", yaml.contains("      units: [\"app_client\"]\n"), yaml);
    check("extract.md.written", md.contains("- units: `app_client`\n"), md);
    CodeSpecsExtract back = CodeSpecsExtract.fromYaml(yaml);
    eq("extract.readBack", back.toYaml(), yaml);
    eq("extract.readBack.units", back.entries.get(0).units, fm.entries.get(0).units);

    SpecDocument none = new SpecDocument();
    none.loadJson(readJson("state.json"));
    for (String p : new ArrayList<>(none.unitsPaths())) {
      none.setUnits(p, "");
    }
    // Without a register there is no default either, so no entry names a unit.
    List<String> declared = new ArrayList<>(none.listItems("DEMO/DLV-LST"));
    Collections.reverse(declared);
    for (String item : declared) {
      none.removeListItem(item);
    }
    for (CodeSpecsExtract x : new CodeSpecsExtractor(model, none, catalog).extractAll()) {
      check("extract.absent.yaml[" + x.area.code + "]", !x.toYaml().contains("units:"), "");
      check("extract.absent.md[" + x.area.code + "]", !x.toMarkdown().contains("- units:"), "");
      for (CodeSpecsExtractEntry e : CodeSpecsExtract.fromYaml(x.toYaml()).entries) {
        check("extract.absent.read[" + e.path + "]", e.units.isEmpty(), e.units.toString());
      }
    }
  }

  // --- the register (specGenerationUnits) ----------------------------------

  private static void register(SpecModel model) {
    // Units in register order, each with its own mappings.
    SpecDocument d = register();
    d.setFormField("DEMO/DLV-LST-1/content", "kind", "client");
    String[][] routes = {
      {"DEMO/DLV-LST-1", "CE-NV", "dart-tom"},
      {"DEMO/DLV-LST-1", "CE-TX", " ts-react "},
      {"DEMO/DLV-LST-2", "CE-NV", "dart-tom"},
    };
    for (String[] route : routes) {
      String r = d.addListItem(route[0] + "/DLR-LST");
      d.setFormField(r + "/content", "area", route[1]);
      d.setFormField(r + "/content", "mapping", route[2]);
    }
    List<SpecGenerationUnit> units = SpecGenerationUnits.specGenerationUnits(model, d);
    List<String> ids = new ArrayList<>();
    for (SpecGenerationUnit u : units) {
      ids.add(u.unitId);
    }
    eq("register.order", ids, List.of("u_a", "u_b"));
    SpecGenerationUnit first = units.get(0);
    SpecGenerationUnit last = units.get(units.size() - 1);
    eq("register.kind", first.kind, "client");
    eq("register.path", first.path, "DEMO/DLV-LST-1");
    List<List<String>> firstMappings = new ArrayList<>();
    for (SpecGenerationUnitMapping m : first.mappings) {
      firstMappings.add(List.of(m.area, m.mapping));
    }
    eq("register.mappings", firstMappings,
        List.of(List.of("CE-NV", "dart-tom"), List.of("CE-TX", "ts-react")));
    eq("register.mappingFor", first.mappingFor("CE-TX"), "ts-react");
    eq("register.mappingFor.none", last.mappingFor("CE-TX"), null);
    eq("register.default.both", SpecGenerationUnits.specDefaultUnits(units, "CE-NV"),
        List.of("u_a", "u_b"));
    eq("register.default.one", SpecGenerationUnits.specDefaultUnits(units, "CE-TX"),
        List.of("u_a"));
    eq("register.default.none", SpecGenerationUnits.specDefaultUnits(units, "CE-DB"),
        List.of());

    // A unit without an id, and a second unit of one id, are left out.
    SpecDocument skip = register();
    skip.addListItem("DEMO/DLV-LST");
    String dup = skip.addListItem("DEMO/DLV-LST");
    skip.setFormField(dup + "/content", "unitId", "u_a");
    List<String> kept = new ArrayList<>();
    for (SpecGenerationUnit u : SpecGenerationUnits.specGenerationUnits(model, skip)) {
      kept.add(u.unitId);
    }
    eq("register.skipped", kept, List.of("u_a", "u_b"));

    // A document without a register declares none.
    check("register.none",
        SpecGenerationUnits.specGenerationUnits(model, new SpecDocument()).isEmpty(), "");
  }
}
