package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * The Phase-4 <b>specification extract generator</b> — the machine half of
 * CodeSpecs production ({@code codespecs_mapping.md} §1.1.1). Produces one
 * {@link CodeSpecsExtract} per active area from a filled specification document.
 *
 * <p>Phase 4 runs in two passes. This surface is the first: for each CodeSpecs
 * area it collects everything in a filled specification document that
 * {@code @CodeSpecKind} routes to that area, <b>verbatim and with
 * provenance</b>, so the second pass — an authoring agent, one prompt per
 * authoring step — writes against a bounded extract rather than against a
 * 652-section document.
 *
 * <p>The boundary between the two passes is a rule, not a preference. This
 * generator may <b>copy and index</b>; it may not summarise, rephrase, compose a
 * sentence out of field values, or choose a name — the prohibitions of
 * {@code codespecs_derivation_contract.md} §2.8 <b>C1</b>, which bind the
 * extract generator word for word. The consequence is checkable rather than
 * trusted: every {@link CodeSpecsExtractEntry#value} is a string the document
 * stores, byte for byte, and the conformance corpus asserts it.
 *
 * <p>Three things follow from that and shape the API:
 *
 * <ul>
 *   <li><b>Routing is by the three verdicts</b> ({@code codespecs_mapping.md}
 *       §8.3) — a class carries {@code @CodeSpecKind} (feeds code), sits under a
 *       {@code @FollowUpKind} root (feeds a non-generation process), or carries
 *       {@code @NoArtifact} (feeds nothing). The trio is exhaustive by
 *       construction, so a class carrying none of them is not "skipped": it is a
 *       {@link CodeSpecsExtractError}, the {@code ROUTE-TOTAL} invariant
 *       ({@code tom_specs_model_rules.md} §10.2) failing loudly at the one place
 *       that depends on it.
 *   <li><b>{@code @CodeSpecKind} is list-valued</b> (§9.1), and extracts are
 *       <b>not</b> deduplicated across areas: a section feeding three areas
 *       appears, whole, in three extracts. Each area's prompt must be
 *       self-sufficient.
 *   <li><b>Every entry carries its provenance</b> — section id, class, field, the
 *       routing marker that put it here and where that marker was declared — so
 *       the {@code @DocSpec}/{@code DocRef} back-links (§9.3) can be written from
 *       the extract alone.
 * </ul>
 *
 * <p>The area catalogue ({@link CodeSpecsAreaCatalog}) is an <b>input</b>, not a
 * table baked into the runtime: it is the machine-readable form of
 * {@code codespecs_mapping.md} §4.1 (the parts catalogue), §4.4.3 (the emission
 * slices) and §4.4.6 (the authoring steps), authored once and read by all nine
 * runtimes. Carrying it beside the content is what stops an agent having to open
 * the mapping document to find out what {@code CE-FM} means.
 *
 * <p>A Phase-4 run extracts from <b>one</b> specification document, so the walk
 * has exactly one root ({@link #root}, {@code codespecs_prompt.md} §5). The two
 * ways to get that wrong are both closed here rather than left to the caller: the
 * walk cannot union every {@code @Document} root, because there is no way to ask
 * for that; and naming a root the document never populates — the
 * {@code D13CodeSpecsProjection} mistake, whose {@code CGP/…} path space misses a
 * blueprint's {@code SBP/…} values and yields every area silently empty — is a
 * {@link CodeSpecsExtractError} rather than an empty result.
 */
public final class CodeSpecsExtractor {
  /**
   * The annotation names of the three routing verdicts
   * ({@code codespecs_mapping.md} §8.3). All three ride the generic annotation
   * bag in every SOM runtime (§8.4), so they are read by name rather than through
   * a meta slot.
   */
  public static final String CODE_SPEC_KIND_ANNOTATION = "CodeSpecKind";

  /** See {@link #CODE_SPEC_KIND_ANNOTATION}. */
  public static final String FOLLOW_UP_KIND_ANNOTATION = "FollowUpKind";

  /** See {@link #CODE_SPEC_KIND_ANNOTATION}. */
  public static final String NO_ARTIFACT_ANNOTATION = "NoArtifact";

  /**
   * The model describing the document's structure and carrying the routing
   * verdicts.
   */
  public final SpecModel model;

  /** The filled specification document. */
  public final SpecDocument document;

  /** The area catalogue — {@code codespecs_mapping.md} §4.1/§4.4.3/§4.4.6. */
  public final CodeSpecsAreaCatalog catalog;

  /**
   * The one {@code @Document} root this extractor walks.
   *
   * <p>Resolved once, by the constructor, so {@link #routings} and
   * {@link #extractAll} cannot disagree about what was walked.
   */
  public final SpecRoot root;

  private final SpecReflection reflection;

  /** Binds an extractor to the document's single populated root. */
  public CodeSpecsExtractor(
      SpecModel model, SpecDocument document, CodeSpecsAreaCatalog catalog) {
    this(model, document, catalog, null);
  }

  /**
   * Binds an extractor to a model / document / catalogue triple.
   *
   * <p>{@code rootType} names the specification document's own root, by type name
   * or by section id. {@code null} (or {@code ""}) means "omitted": the document's
   * single <b>populated</b> root is used — the root under which the document holds
   * any value — falling back to the model's only root when the document is empty,
   * so an unfilled single-root model still reaches the routing walk.
   *
   * @throws CodeSpecsExtractError when the root cannot be resolved to exactly one:
   *     an unknown {@code rootType}, a {@code rootType} holding no value while
   *     another root does, more than one populated root, or an empty document over
   *     a multi-root model.
   */
  public CodeSpecsExtractor(
      SpecModel model, SpecDocument document, CodeSpecsAreaCatalog catalog, String rootType) {
    this.model = model;
    this.document = document;
    this.catalog = catalog;
    this.root = resolveRoot(model, document, rootType);
    this.reflection = new SpecReflection(model);
  }

  /** The document path segment a root's values live under. */
  private static String rootSegmentOf(SpecRoot r) {
    return r.sectionId != null && !r.sectionId.isEmpty() ? r.sectionId : r.type;
  }

  /** Implements the constructor's root rule. */
  private static SpecRoot resolveRoot(
      SpecModel model, SpecDocument document, String rootType) {
    List<SpecRoot> populated = new ArrayList<>();
    List<String> names = new ArrayList<>();
    for (SpecRoot r : model.roots) {
      names.add(r.type);
      if (document.hasValuesUnder(rootSegmentOf(r))) {
        populated.add(r);
      }
    }
    List<String> populatedTypes = new ArrayList<>();
    for (SpecRoot r : populated) {
      populatedTypes.add(r.type);
    }
    if (rootType != null && !rootType.isEmpty()) {
      for (SpecRoot r : model.roots) {
        if (!r.type.equals(rootType) && !rootSegmentOf(r).equals(rootType)) {
          continue;
        }
        if (!populated.isEmpty() && !populated.contains(r)) {
          throw new CodeSpecsExtractError(
              "root \""
                  + rootType
                  + "\" holds no value in this document, but "
                  + String.join(", ", populatedTypes)
                  + " does — every extract would come out empty"
                  + " (codespecs_prompt.md §5)",
              rootSegmentOf(r),
              r.type);
        }
        return r;
      }
      throw new CodeSpecsExtractError(
          "no document root with type or section id \""
              + rootType
              + "\" (have: "
              + String.join(", ", names)
              + ")",
          "",
          rootType);
    }
    if (populated.size() == 1) {
      return populated.get(0);
    }
    if (populated.isEmpty()) {
      if (model.roots.size() == 1) {
        return model.roots.get(0);
      }
      throw new CodeSpecsExtractError(
          "document has no populated root to extract from; pass rootType to choose one (have: "
              + String.join(", ", names)
              + ")",
          "",
          "");
    }
    throw new CodeSpecsExtractError(
        "document has "
            + populated.size()
            + " populated roots ("
            + String.join(", ", populatedTypes)
            + "); pass rootType to choose one",
        "",
        "");
  }

  /**
   * The verdict of every class node the walk reaches, in document order.
   *
   * <p>Computed by the same walk {@link #extractAll} uses, so "what was routed
   * where" and "what landed in which extract" cannot disagree. Unlike
   * {@link #extractAll} this does <b>not</b> throw on an unrouted class — it
   * reports it, which is what a diagnostic is for.
   */
  public List<CodeSpecsRouting> routings() {
    List<CodeSpecsRouting> out = new ArrayList<>();
    walkAll(out, null, false);
    return out;
  }

  /**
   * One extract per active area, in catalogue order.
   *
   * <p>Throws {@link CodeSpecsExtractError} on the first class the walk reaches
   * that carries none of the three verdicts.
   */
  public List<CodeSpecsExtract> extractAll() {
    List<CodeSpecsExtractEntry> entries = new ArrayList<>();
    walkAll(null, entries, true);
    String rootSegment = reflection.rootSegment(root);
    List<CodeSpecsExtract> out = new ArrayList<>();
    for (CodeSpecsArea area : catalog.activeAreas()) {
      List<CodeSpecsExtractEntry> mine = new ArrayList<>();
      for (CodeSpecsExtractEntry e : entries) {
        if (e.areaCode.equals(area.code)) {
          mine.add(e);
        }
      }
      out.add(
          new CodeSpecsExtract(
              area,
              catalog.source,
              rootSegment,
              catalog.citableAreaCodes(area),
              catalog.projectsFor(area),
              Collections.unmodifiableList(mine)));
    }
    return out;
  }

  /**
   * The single extract for {@code areaCode}, or {@code null} when the catalogue
   * holds no such active area.
   */
  public CodeSpecsExtract extractFor(String areaCode) {
    for (CodeSpecsExtract e : extractAll()) {
      if (e.area.code.equals(areaCode)) {
        return e;
      }
    }
    return null;
  }

  // --- the walk -------------------------------------------------------------

  private void walkAll(
      List<CodeSpecsRouting> routings, List<CodeSpecsExtractEntry> entries, boolean strict) {
    Set<String> ancestorTypes = new LinkedHashSet<>();
    ancestorTypes.add(root.type);
    walk(
        reflection.rootSegment(root),
        model.classNamed(root.type),
        ancestorTypes,
        routings,
        entries,
        strict);
  }

  private void walk(
      String path,
      SpecClass cls,
      Set<String> ancestorTypes,
      List<CodeSpecsRouting> routings,
      List<CodeSpecsExtractEntry> entries,
      boolean strict) {
    if (cls == null) {
      return;
    }
    CodeSpecsRouting routing = verdictOf(cls, path);
    if (routings != null) {
      routings.add(routing);
    }

    switch (routing.verdict) {
      case FEEDS_PROCESS:
        // the whole subtree is delivered by a non-generation process
        return;
      case UNROUTED:
        if (strict) {
          throw new CodeSpecsExtractError(
              "section carries none of the three routing verdicts "
                  + "(@CodeSpecKind / @FollowUpKind / @NoArtifact) — "
                  + "tom_specs_model_rules.md §10.2 ROUTE-TOTAL",
              path,
              cls.name);
        }
        break;
      case FEEDS_CODE:
      case FEEDS_NOTHING:
      case DOCUMENT_ROOT:
      default:
        break;
    }

    CodeSpecsRouting classRouting =
        routing.verdict == CodeSpecsRoutingVerdict.FEEDS_CODE ? routing : null;

    for (SpecField field : cls.fields) {
      String fieldPath = SpecPaths.join(path, reflection.fieldSegment(field));
      CodeSpecsRouting declared = fieldRouting(cls, field);
      CodeSpecsRouting fieldRouting = declared == null ? classRouting : declared;

      switch (field.kind) {
        case CONTENT:
        case ENUM:
        case SCALAR:
          emitValue(
              entries, fieldRouting, cls, field, fieldPath, null, document.content(fieldPath));
          break;
        case FORM:
          for (FormFieldSpec ff : field.formFields) {
            emitValue(
                entries,
                fieldRouting,
                cls,
                field,
                fieldPath,
                ff.name,
                document.formField(fieldPath, ff.name));
          }
          break;
        case LIST:
          for (String itemPath : document.listItems(fieldPath)) {
            if (field.elementIsComplex
                && field.elementType != null
                && !ancestorTypes.contains(field.elementType)) {
              Set<String> nested = new LinkedHashSet<>(ancestorTypes);
              nested.add(field.elementType);
              walk(
                  itemPath,
                  model.classNamed(field.elementType),
                  nested,
                  routings,
                  entries,
                  strict);
            } else {
              emitValue(
                  entries, fieldRouting, cls, field, itemPath, null, document.content(itemPath));
            }
          }
          break;
        case COMPLEX:
        case SECTION:
          if (field.type != null && !ancestorTypes.contains(field.type)) {
            Set<String> nested = new LinkedHashSet<>(ancestorTypes);
            nested.add(field.type);
            walk(fieldPath, model.classNamed(field.type), nested, routings, entries, strict);
          }
          break;
        default:
          break;
      }
    }
  }

  /**
   * Appends one entry <b>per area the routing names</b> — never deduplicated,
   * because each area's prompt must be self-sufficient (§1.1.1).
   */
  private void emitValue(
      List<CodeSpecsExtractEntry> entries,
      CodeSpecsRouting routing,
      SpecClass cls,
      SpecField field,
      String path,
      String formField,
      String value) {
    if (entries == null || routing == null) {
      return;
    }
    if (value == null || value.isEmpty()) {
      return;
    }
    for (String kind : routing.values) {
      CodeSpecsArea area = catalog.byPart(kind);
      if (area == null || !area.active) {
        continue;
      }
      entries.add(
          new CodeSpecsExtractEntry(
              area.code,
              reflection.fieldSegment(field),
              path,
              cls.name,
              field.name,
              formField,
              area.kindValue(),
              routing.declaredAt,
              routing.note,
              value));
    }
  }

  // --- verdict resolution ---------------------------------------------------

  /**
   * The verdict {@code cls} carries. The three markers are mutually exclusive
   * ({@code KIND-EXCLUSIVE}), so the order they are tested in is a readability
   * choice rather than a precedence rule.
   *
   * <p>Read through the model's own {@link SpecAnnotations} accessors rather than
   * off the raw annotation bag: they already know that {@code @CodeSpecKind}'s
   * list argument is {@code kinds} while {@code @FollowUpKind}'s is
   * {@code processes}, and they strip the enum prefix, so the codes here are bare
   * whatever spelling the meta chose. Two readers of the same annotations would
   * be two chances to disagree.
   */
  private CodeSpecsRouting verdictOf(SpecClass cls, String path) {
    KindLink code = cls.codeSpecKind();
    if (code != null) {
      return new CodeSpecsRouting(
          path,
          cls.name,
          CodeSpecsRoutingVerdict.FEEDS_CODE,
          code.kinds,
          code.note,
          cls.name);
    }
    KindLink followUp = cls.followUpKind();
    if (followUp != null) {
      return new CodeSpecsRouting(
          path,
          cls.name,
          CodeSpecsRoutingVerdict.FEEDS_PROCESS,
          followUp.kinds,
          followUp.note,
          cls.name);
    }
    NoArtifactLink none = cls.noArtifact();
    if (none != null) {
      return new CodeSpecsRouting(
          path,
          cls.name,
          CodeSpecsRoutingVerdict.FEEDS_NOTHING,
          Collections.singletonList(none.reason),
          none.note,
          cls.name);
    }
    if (cls.hasAnnotation("Document")) {
      return new CodeSpecsRouting(path, cls.name, CodeSpecsRoutingVerdict.DOCUMENT_ROOT);
    }
    return new CodeSpecsRouting(path, cls.name, CodeSpecsRoutingVerdict.UNROUTED);
  }

  /**
   * A field-level {@code @CodeSpecKind}, which overrides its class's routing for
   * that field alone; {@code null} when the field carries none.
   */
  private CodeSpecsRouting fieldRouting(SpecClass cls, SpecField field) {
    KindLink code = field.codeSpecKind();
    if (code == null) {
      return null;
    }
    return new CodeSpecsRouting(
        "",
        cls.name,
        CodeSpecsRoutingVerdict.FEEDS_CODE,
        code.kinds,
        code.note,
        cls.name + "." + field.name);
  }
}
