import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import tom_som_runtime.Json;
import tom_som_runtime.SpecAnnotation;
import tom_som_runtime.SpecClass;
import tom_som_runtime.SpecDerivation;
import tom_som_runtime.SpecExtractsLinks;
import tom_som_runtime.SpecInverseOf;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecPlace;
import tom_som_runtime.SpecPlaceException;
import tom_som_runtime.SpecPlaceFilter;
import tom_som_runtime.SpecPlaceKind;
import tom_som_runtime.SpecPlaceProblem;
import tom_som_runtime.SpecPlaceResolution;
import tom_som_runtime.SpecReflection;
import tom_som_runtime.SpecSameAs;
import tom_som_runtime.SpecSameAsBinding;
import tom_som_runtime.SpecSectionPosition;
import tom_som_runtime.SpecSummaryOf;
import tom_som_runtime.SpecSync;

/**
 * The places and filters of the link vocabulary ({@code SpecPlace},
 * {@code SpecPlaceFilter}, {@code tom_specs_model_rules.md} §9.7) and the typed
 * link readers of the model they are read from: the grammar, resolution under an
 * anchor over the corpus's {@code links.meta.json}, the filter's {@code |}
 * alternatives, the {@code @SameAs} holders and the readers' defaults for a key a
 * meta does not carry.
 *
 * <p>The shared corpus ({@code link_reader_cases.json}) pins the canonical JSON;
 * this test holds the Java surface around it — the exceptions, the defaults,
 * {@code toString()} and the section positions. Mirrors the Go runtime's
 * spec_place_test.go. A plain {@code main()} that exits 0 on success and 1 on
 * failure.
 */
public final class SpecPlaceTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static void check(String name, boolean ok, String detail) {
    if (ok) {
      passed++;
    } else {
      failed.add(name + (detail.isEmpty() ? "" : ": " + detail));
    }
  }

  static SpecModel linksModel() throws IOException {
    String text =
        new String(
            Files.readAllBytes(Paths.get("../tom_som_conformance/corpus/links.meta.json")),
            StandardCharsets.UTF_8);
    return SpecModel.fromJson(Json.parseObject(text));
  }

  private static SpecPlaceProblem problemOf(Runnable fn) {
    try {
      fn.run();
      return null;
    } catch (SpecPlaceException e) {
      return e.problem;
    }
  }

  private static void grammar() {
    SpecPlace p = SpecPlace.parse("./FRE/REQDEP/RQDEP.description");
    check(
        "grammar.parsed",
        p.scoped
            && p.prefix.equals(List.of("FRE", "REQDEP"))
            && p.sectionId.equals("RQDEP")
            && "description".equals(p.slot),
        Json.write(p.toJson()));
    check("grammar.toString", p.toString().equals("./FRE/REQDEP/RQDEP.description"), p.toString());
    check("grammar.headline", "@headline".equals(SpecPlace.parse("FRE.@headline").slot), "");
    String bare = Json.write(SpecPlace.parse("FRE-REQU-LST").toJson());
    check(
        "grammar.bare",
        Json.parseObject(bare)
            .equals(Json.parseObject("{\"prefix\":[],\"scoped\":false,\"sectionId\":\"FRE-REQU-LST\"}")),
        bare);
    for (String bad : List.of("", "./", "-X", "FRE.", "FRE.a-b", "FRE/.x", "FRE..x")) {
      check("grammar.bad[" + bad + "]", SpecPlace.tryParse(bad) == null, "parsed as a place");
    }
    check(
        "grammar.malformed",
        problemOf(() -> SpecPlace.parse("a b")) == SpecPlaceProblem.MALFORMED,
        "");
  }

  private static void filterGrammar() {
    SpecPlaceFilter f = SpecPlaceFilter.parse("./FRE.priority=must|should");
    check(
        "filter.parsed",
        f.scoped && "priority".equals(f.field) && f.values.equals(List.of("must", "should")),
        Json.write(f.toJson()));
    check("filter.matchesTrimmed", f.matches(List.of("could", " should ")), "");
    check("filter.noMatch", !f.matches(List.of("could")) && !f.matches(null), "");
    SpecPlaceFilter every = SpecPlaceFilter.parse("FRE");
    check("filter.every", every.matches(null), "");
    check(
        "filter.place",
        every.place().text.equals("FRE") && f.place().text.equals("./FRE"),
        every.place().text + ", " + f.place().text);
    check("filter.toString", f.toString().equals("./FRE.priority=must|should"), "");
    for (String bad :
        List.of("FRE.priority", "FRE.priority=", "FRE.priority=a||b", "FRE.9x=a", ".x=a")) {
      check("filter.bad[" + bad + "]", SpecPlaceFilter.tryParse(bad) == null, "parsed");
    }
  }

  private static void resolution(SpecReflection refl) {
    String item = "BLU/requirements/REQ-ITEM-LST-1";
    SpecPlaceResolution r = SpecPlace.parse("REQD.description").resolve(refl, item);
    check(
        "resolve.formField",
        r.kind == SpecPlaceKind.FORM_FIELD && "description".equals(r.field()) && r.formField != null,
        Json.write(r.toJson()));
    String[][] cases = {
      {"REQD", "BLU/nowhere", "anchorUnresolved"},
      {"./REQD", "BLU", "notScoped"},
      {"NOPE", "BLU", "unresolved"},
      {"REQD.@nope", item, "reservedSlot"},
      {"REQD.nope", item, "noSuchField"},
    };
    for (String[] c : cases) {
      SpecPlaceProblem got = problemOf(() -> SpecPlace.parse(c[0]).resolve(refl, c[1]));
      check(
          "resolve.problem[" + c[0] + " under " + c[1] + "]",
          got != null && got.value.equals(c[2]),
          String.valueOf(got));
    }
    // The filter reports with its own text.
    try {
      SpecPlaceFilter.parse("NOPE.x=1").resolve(refl, "BLU");
      check("resolve.filterText", false, "resolved");
    } catch (SpecPlaceException e) {
      check(
          "resolve.filterText",
          e.text.equals("NOPE.x=1") && e.getMessage().contains("NOPE.x=1"),
          e.getMessage());
    }
  }

  private static void positionsAndSameAs(SpecReflection refl) {
    List<SpecSectionPosition> positions = SpecPlace.sectionPositions(refl, "Blueprint");
    check(
        "positions.root",
        !positions.isEmpty() && positions.get(0).path.equals("BLU"),
        String.valueOf(positions.size()));
    check(
        "positions.rootNoMember",
        !positions.isEmpty() && !positions.get(0).isMember && positions.get(0).member == null,
        "");
    boolean items = false;
    for (SpecSectionPosition p : positions) {
      if (p.path.contains("-*")) {
        items = true;
      }
    }
    check("positions.items", items, "no list-item position");
    check("positions.unknown", SpecPlace.sectionPositions(refl, "Nope").isEmpty(), "");
    List<SpecSameAsBinding> bindings = SpecPlace.sameAsBindings(refl, "Blueprint");
    check(
        "sameAs.bindings",
        bindings.size() == 1 && bindings.get(0).holderPath != null,
        String.valueOf(bindings.size()));
    check("sameAs.unknown", SpecPlace.sameAsBindings(refl, "Nope").isEmpty(), "");
  }

  private static void readerDefaults() {
    Map<String, Object> args = new LinkedHashMap<>();
    args.put("source", "X");
    args.put("kind", "DerivationKind.rows");
    SpecDerivation d = SpecDerivation.fromArguments(args);
    check("defaults.kind", d.kind.equals("rows"), d.kind);
    check(
        "defaults.derivation",
        Json.parseObject(Json.write(d.toJson()))
            .equals(Json.parseObject("{\"kind\":\"rows\",\"map\":{},\"source\":\"X\",\"take\":[]}")),
        Json.write(d.toJson()));
    check("defaults.copy", SpecDerivation.fromArguments(new LinkedHashMap<>()).kind.equals("copy"), "");
    SpecSummaryOf s = SpecSummaryOf.fromArguments(Map.of("detail", "D-LST"));
    check(
        "defaults.summary",
        Json.parseObject(Json.write(s.toJson()))
            .equals(Json.parseObject("{\"detail\":\"D-LST\",\"relation\":\"subset\",\"repeats\":{}}")),
        Json.write(s.toJson()));
    check("defaults.symmetric", new SpecInverseOf(List.of("@self"), null).symmetric(), "");
    check(
        "defaults.notSymmetric",
        !new SpecInverseOf(List.of("@self", "X.y"), null).symmetric(),
        "");
    Map<String, Object> ex = new LinkedHashMap<>();
    ex.put("ref", "L.ref");
    List<Object> from = new ArrayList<>();
    from.add("A.b");
    from.add(null);
    ex.put("from", from);
    SpecExtractsLinks e = SpecExtractsLinks.fromAnnotation(new SpecAnnotation("ExtractsLinks", ex));
    check(
        "defaults.extracts",
        Json.parseObject(Json.write(e.toJson()))
            .equals(
                Json.parseObject(
                    "{\"from\":[\"A.b\"],\"mode\":\"generate\",\"ref\":\"L.ref\",\"set\":{}}")),
        Json.write(e.toJson()));
    Map<String, Object> sy = new LinkedHashMap<>();
    sy.put("document", "D");
    sy.put("relations", List.of(Map.of("place", "P"), "junk"));
    SpecSync sync = SpecSync.fromAnnotation(new SpecAnnotation("SyncedWith", sy));
    check(
        "defaults.syncRelations",
        sync.relations.size() == 1
            && Json.parseObject(Json.write(sync.relations.get(0).toJson()))
                .equals(Json.parseObject("{\"place\":\"P\",\"relation\":\"equal\"}")),
        "");
    check("defaults.sameAs", new SpecSameAs(null, null).toJson().isEmpty(), "");
  }

  /** A string → string argument keeps the order the meta writes it in. */
  private static void keepsMetaOrder() {
    Map<String, Object> ann =
        Json.parseObject(
            "{\"name\":\"SummaryOf\",\"arguments\":{\"detail\":\"D-LST\","
                + "\"repeats\":{\"Z.a\":\"1\",\"A.b\":\"2\",\"M.c\":\"3\"}}}");
    Map<String, Object> cls = new LinkedHashMap<>();
    cls.put("name", "C");
    cls.put("annotations", List.of(ann));
    SpecSummaryOf s = SpecClass.fromJson(cls).summaryOf();
    check(
        "order.repeats",
        new ArrayList<>(s.repeats.keySet()).equals(List.of("Z.a", "A.b", "M.c")),
        s.repeats.keySet().toString());
  }

  private static void accessors(SpecModel model) {
    SpecClass req = model.classes.get("Requirement");
    check(
        "accessors.extractsLinks",
        req.fieldNamed("links").annotationsNamed("ExtractsLinks").size() == 2,
        "");
    check("accessors.noSync", model.classes.get("Blueprint").syncedWith() == null, "");
    check(
        "accessors.notProjection",
        !model.classes.get("Blueprint").isCodeSpecsProjection(),
        "");
  }

  public static void main(String[] args) throws IOException {
    SpecModel model = linksModel();
    SpecReflection refl = new SpecReflection(model);
    grammar();
    filterGrammar();
    resolution(refl);
    positionsAndSameAs(refl);
    readerDefaults();
    keepsMetaOrder();
    accessors(model);
    if (failed.isEmpty()) {
      System.out.println("OK: " + passed + " checks passed");
      System.exit(0);
    }
    System.out.println("FAIL: " + failed.size() + "/" + (passed + failed.size()) + " checks failed");
    for (String f : failed) {
      System.out.println("  - " + f);
    }
    System.exit(1);
  }
}
