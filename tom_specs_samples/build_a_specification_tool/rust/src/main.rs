//! TomSpecs sample — building tooling ON a specification (Rust).
//!
//! The Rust port of `../bin/build_a_specification_tool.dart`: the same five
//! steps over the same fixture. Its output differs from the Dart sample where
//! the Dart text names a Dart-only surface, and where Rust names an API
//! differently; `expected_output.txt` here records the Rust output, and
//! README.md says where it differs.
//!
//! Run (from this folder; see README.md):  `cargo run`
//!
//! For the reader who is not authoring specifications but writing programs
//! that read them: an editor, a linter, a report, an importer, a migration.
//! That reader needs four things, and this sample walks them in the order they
//! are needed:
//!
//!  1. REFLECTION   — what the model CAN hold, read from the metadata tree
//!  2. GENERIC      — what a document DOES hold, with no compile-time
//!     knowledge of its shape
//!  3. SCHEMA       — the generated schema, where it comes from and what it is
//!  4. VALIDATION   — the two runtime tiers, and the third that is not here
//!  5. A TOOL       — a completeness report built on all four
//!
//! The individual APIs are demonstrated one at a time in the facade crate's
//! own examples (`tom_som_rust_v0/examples/`): `b_generic_document.rs` and
//! `c_reflection_metadata.rs`.

use std::collections::BTreeSet;
use std::fs;

use tom_som_rust_runtime as som;
use tom_som_rust_v0::{meta, D00SolutionBlueprint};

/// The document root this sample inspects.
const K_ROOT: &str = "D00SolutionBlueprint";

/// That root's addressable segment — the first element of every path in it.
const K_ROOT_SEGMENT: &str = "SBP";

/// The creation date section-id generation is pinned to (1 January).
/// `SomList::add` derives an item's id from the current date, so an unpinned
/// run would emit different ids every day and `expected_output.txt` would
/// record the day it was taken rather than the pipeline.
const K_AUTHORED_MONTH: i64 = 1;
const K_AUTHORED_DAY: i64 = 1;

/// The report's title column width. Titles are clipped to it rather than
/// wrapped: a completeness report is scanned down its numbers, and a wrapped
/// title puts a row's two halves on different lines.
const K_TITLE_WIDTH: usize = 38;

const DAY_SECONDS: i64 = 24 * 3600;

fn main() {
    let meta_text = read_checkout("tom_som_rust_v0/meta/spec_model.meta.json");
    let meta_json = som::Json::parse(&meta_text).expect("model JSON");
    let model = som::SpecModel::from_json(&meta_json);
    let schema = som::DocSpecsSchema::from_yaml_text(&read_checkout(
        "tom_som_rust_v0/schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml",
    ))
    .expect("schema");

    let doc = som::doc_ref(som::SpecDocument::new());
    author_fixture(&new_root(&doc));

    section(0, "The document this run inspects");
    println!("A Solution Blueprint with a handful of sections written and the");
    println!("rest left blank — small enough that every number below can be");
    println!("checked by reading `authorFixture` in this file.");
    println!();
    println!(
        "  content leaves written : {}",
        doc.borrow().content_paths().len()
    );
    println!(
        "  form sections written  : {}",
        doc.borrow().form_paths().len()
    );
    println!(
        "  lists with items       : {}",
        doc.borrow().list_paths().len()
    );

    reflection_step(&model, &meta_json);
    generic_access(&model, &doc.borrow());
    the_schema(&schema);
    validation(&model, &schema, &doc.borrow());
    the_tool(&model, schema, &doc.borrow());
}

// ===========================================================================
// 1. Reflection — what the model CAN hold
// ===========================================================================

fn reflection_step(model: &som::SpecModel, meta_json: &som::Json) {
    section(1, "Reflection — what the model CAN hold");
    println!("`SpecModel` is the exported class graph; `SpecReflection` is the");
    println!("value-free query surface over it. No document is involved here.");
    println!();

    println!("THE TWO VERSION STAMPS. They answer different questions and a tool");
    println!("that checks one for the other will accept a file it cannot read:");
    println!(
        "  modelVersion      = {}  — WHICH MODEL this snapshot describes",
        model.model_version
    );
    println!(
        "  metaSchemaVersion = {}  — the FILE FORMAT the snapshot itself is written in",
        opt(model.meta_schema_version)
    );
    println!("  modelVersionLabel = {}", model.model_version_label);
    // `SpecModel::generated_at` holds epoch seconds (std has no date type); the
    // stamp is printed as the snapshot writes it.
    println!(
        "  generatedAt       = {}",
        meta_json
            .get("generatedAt")
            .and_then(|v| v.as_str())
            .unwrap_or("null")
    );
    println!();
    println!("A tool reads `metaSchemaVersion` to decide whether it can parse the");
    println!("file at all, and `modelVersion` to decide whether the documents it");
    println!("holds are the ones this model describes. `modelVersionLabel` is a");
    println!("build label for humans — never branch on it.");
    println!();

    // A snapshot is a photograph. `check_stamp` compares what the exporter
    // DECLARED against what survived to the reader, and ages the file out.
    // `now` is derived from the model's own stamp so the printed age stays at
    // exactly the offset this sample means to demonstrate. Rust has no default
    // arguments: the 30-day threshold is the other runtimes' default.
    let exported_at = model.generated_at.unwrap_or(1_767_225_600); // 2026-01-01
    let stamp = model.check_stamp(30 * DAY_SECONDS, exported_at + 3 * DAY_SECONDS);
    println!("SNAPSHOT CHECK (`check_stamp`), against a fixed clock:");
    let age = stamp
        .age_seconds
        .map_or("null".to_string(), |s| (s / DAY_SECONDS).to_string());
    println!(
        "  age                 : {} days (aged: {})",
        age,
        stamp.is_aged()
    );
    println!(
        "  classes  declared/actual : {}/{}  disagrees: {}",
        opt(stamp.declared_class_count),
        stamp.actual_class_count,
        stamp.class_count_disagrees()
    );
    println!(
        "  roots    declared/actual : {}/{}  disagrees: {}",
        opt(stamp.declared_root_count),
        stamp.actual_root_count,
        stamp.root_count_disagrees()
    );
    println!("  Declared-vs-actual is not redundant: the declared value is what");
    println!("  the exporter recorded, the actual value is what survived to the");
    println!("  reader, and a truncated file is exactly where they part.");
    println!();

    let reflection = som::SpecReflection::new(model);
    println!("SHAPE:");
    println!("  document roots : {}", reflection.roots().len());
    println!("  classes        : {}", reflection.classes().len());
    println!(
        "  container root : {} — the one true tree root, which is not itself a document",
        model.container_root
    );
    println!();

    let root = reflection.root_for_segment("SBP").expect("the SBP root");
    let fields = reflection.fields_of(&root.type_);
    println!(
        "FIELDS of {} ({} total, first 4):",
        root.type_,
        fields.len()
    );
    for f in &fields[..4] {
        println!(
            "  {:<24} kind={:<8} {}",
            f.name,
            kind_name(&f.kind),
            f.type_
        );
    }
    println!();

    // A form's slots are on the field itself, not on a separate class — the
    // shape a tool must handle to render or fill one.
    let form = reflection
        .fields_of("DataEntityEntry")
        .iter()
        .find(|f| f.kind == som::SPEC_FIELD_KIND_FORM)
        .expect("a form field");
    println!(
        "FORM SLOTS of DataEntityEntry.{} (section id {}):",
        form.name, form.section_id
    );
    for slot in &form.form_fields {
        println!("  {:<16} {}", slot.name, slot.label);
    }
    println!();

    println!("ANNOTATIONS the meta carries — the model's own metadata, exported");
    println!("into the snapshot and therefore visible in ALL NINE language");
    println!("runtimes, not just Dart:");
    for a in reflection.annotations_of(&root.type_) {
        let args: Vec<&str> = a.arguments.iter().map(|(k, _)| k.as_str()).collect();
        if args.is_empty() {
            println!("  @{}", a.name);
        } else {
            println!("  @{}({})", a.name, args.join(", "));
        }
    }
    // The display semantics of these annotations (`kRenderedAnnotations`) are
    // in the Dart runtime only: they are what the two Flutter apps share.
    println!("  How each is displayed is the Dart runtime's (`kRenderedAnnotations`,");
    println!("  shared by the two Flutter apps); the annotations themselves are");
    println!("  data every runtime reads.");
    println!();

    println!("PATH RESOLUTION — a document path to the model node it lands on:");
    for p in [
        "SBP",
        "SBP/content",
        "SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST",
        "SBP/informationAndDataModel/nosuchthing",
    ] {
        match reflection.resolve(p) {
            None => println!("  {:<50} (unresolved)", p),
            Some(r) => println!("  {:<50} kind={}  leaf={}", p, r.kind, r.is_value_leaf()),
        }
    }
}

// ===========================================================================
// 2. Generic access — what a document DOES hold
// ===========================================================================

fn generic_access(model: &som::SpecModel, doc: &som::SpecDocument) {
    section(2, "Generic access — what the document DOES hold");
    println!("`SpecDocument` is a sparse, path-keyed store. A tool reads it");
    println!("without knowing the document's shape, and asks the model what each");
    println!("path means. That pairing is the whole of generic access.");
    println!();

    let reflection = som::SpecReflection::new(model);
    println!("EVERY written content leaf, resolved against the model:");
    for p in sorted(doc.content_paths()) {
        let kind = reflection.resolve(&p).map_or("?".to_string(), |r| r.kind);
        println!("  {:<52} {}", p, kind);
        println!("      {}", clip(&doc.content_or(&p), 66));
    }
    println!();

    println!("EVERY written form section, slot by slot:");
    for p in sorted(doc.form_paths()) {
        println!("  {}", p);
        for slot in sorted(doc.form_field_names(&p)) {
            println!(
                "      {:<16} {}",
                slot,
                clip(&doc.form_field_or(&p, &slot), 52)
            );
        }
    }
    println!();

    println!("EVERY list, with its items' section ids:");
    for p in sorted(doc.list_paths()) {
        println!("  {:<52} {} item(s)", p, doc.list_item_count(&p));
        for id in doc.list_item_section_ids(&p) {
            println!("      {}", id);
        }
    }
    println!();

    let tree = meta::d00_solution_blueprint_meta_tree();
    println!("WHERE PATHS COME FROM. A tool must never hard-code a path literal —");
    println!("a literal is undiscoverable and rots silently when the model moves.");
    println!("Two safe sources, both from the generated metadata module:");
    println!();
    println!("  1. the generated metadata refs —");
    println!(
        "     d00_solution_blueprint_meta(&tree).information_and_data_model().data_model().path()"
    );
    println!(
        "       = {}",
        meta::d00_solution_blueprint_meta(&tree)
            .information_and_data_model()
            .data_model()
            .path()
    );
    println!("  2. the id-keyed metadata tree, for a path known only at runtime —");
    println!("     tree.by_id(\"DAENT-ENTI-LST\")");
    let node_path = tree
        .by_id("DAENT-ENTI-LST")
        .map_or("None".to_string(), |n| n.path().expect("node path"));
    println!("       = {}", node_path);
    println!();
    println!("  The tree also goes the other way: by_path gives the node, and with");
    println!("  it the class, kind and children a generic renderer needs.");
    let by_path = tree
        .by_path("SBP/informationAndDataModel/dataModel")
        .expect("the data model node");
    println!("     by_path(\"SBP/informationAndDataModel/dataModel\")");
    println!(
        "       class={} kind={} children={}",
        by_path.class_name,
        by_path.kind,
        by_path.children.len()
    );
}

// ===========================================================================
// 3. The generated schema
// ===========================================================================

fn the_schema(schema: &som::DocSpecsSchema) {
    section(3, "The generated schema");
    println!("Each of the 14 document roots has a schema GENERATED from the model");
    println!("and SHIPPED as data inside the facade package, under");
    println!("`schemas/<document>/<document>.1.0.docspecs-schema.yaml`. A tool");
    println!("loads one; it never writes one, and never derives one itself.");
    println!();
    println!("IT IS A DocSpecs SCHEMA, NOT JSON SCHEMA. It describes a *markdown*");
    println!("document — headings, their ids, their formats, the form fields a");
    println!("section carries and which of them are required. A tool reaching for");
    println!("a JSON-Schema validator will not find one, because the artifact the");
    println!("schema governs is not JSON.");
    println!();
    println!("  root section id : {}", schema.root_section_id());
    println!("  section types   : {}", schema.section_types.len());
    println!();
    println!("  That count is large because a Solution Blueprint SEEDS the twelve");
    println!("  Phase-3 documents: its own section classes ARE those documents'");
    println!("  types, so its schema covers every section id they define. Step 5");
    println!("  meets the same fact from the other side.");
    println!();
    println!("  A section type resolves by ID PREFIX, which is how a generated id");
    println!("  like `DAENT-ENTI-7` finds its type without the schema listing");
    println!("  every instance:");
    for id in ["DAENT-IDEN", "DAENT-ENTI-7", "NOSUCH-1"] {
        match schema.resolve_section_type(id) {
            None => println!(
                "    {:<16} -> (no type — a tool treats this as unknownSection)",
                id
            ),
            Some(t) => println!("    {:<16} -> {}", id, t.prefix),
        }
    }
}

// ===========================================================================
// 4. Validation — the tiers
// ===========================================================================

fn validation(model: &som::SpecModel, schema: &som::DocSpecsSchema, doc: &som::SpecDocument) {
    section(4, "Validation — three tiers, two of them here");
    println!("THIS IS THE DISTINCTION TOOLING AUTHORS MISS. A tool that wants one");
    println!("tier and calls another gets nothing useful — not an error, just an");
    println!("empty list that reads like a pass.");
    println!();
    println!("  STATIC tier   — checks the MODEL'S OWN ANNOTATIONS: field-type");
    println!("                  rules, @ContentType compatibility, cycles, the");
    println!("                  §10.2 structural invariants. Runs ONCE at");
    println!("                  generation time, in");
    println!("                  `tom_specs_clitool/lib/src/validator.dart`, and is");
    println!("                  deliberately NOT part of the nine-language runtime");
    println!("                  surface. Not reachable from this sample, and that");
    println!("                  is the point: by the time a document exists, this");
    println!("                  tier has already run.");
    println!("  INSTANCE tier — checks A DOCUMENT'S VALUES against the model:");
    println!("                  `validate_document` (SOM §9). In every runtime.");
    println!("  DOCUMENT tier — checks a MARKDOWN RENDITION against the generated");
    println!("                  schema: `DocSpecsValidator` (SOM §14).");
    println!();
    println!("The two runtime tiers overlap and neither implies the other:");
    println!("`validate_document` reports a required field left empty in a form the");
    println!("document holds, but not a required section that is absent; the");
    println!("schema validator reports the absent section, but does not follow a");
    println!("reference it sees filled. A tool that wants \"is this document good?\"");
    println!("runs BOTH.");
    println!();

    let instance = som::validate_document(model, doc);
    let document = som::DocSpecsValidator::new(schema.clone())
        .validate_markdown(&doc.to_markdown(model, Some(K_ROOT)).expect("markdown"));
    println!("THE FIXTURE, both tiers:");
    println!("  instance tier : {} error(s)", instance.len());
    println!("  document tier : {} violation(s)", document.len());
    for v in document.iter().take(4) {
        println!(
            "    line {}: {} [{}] {}",
            v.line,
            v.rule,
            v.section_id,
            clip(&v.message, 54)
        );
    }
    if document.len() > 4 {
        println!("    … and {} more", document.len() - 4);
    }
    println!();

    // A document broken on purpose, to show the instance tier firing where the
    // document tier cannot see anything wrong.
    let broken = som::doc_ref(som::SpecDocument::new());
    author_fixture(&new_root(&broken));
    broken
        .borrow_mut()
        .set_content("SBP/informationAndDataModel/nosuchsection/content", "x");
    broken.borrow_mut().set_form_field(
        "SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAENT-IDEN",
        "notAField",
        "x",
    );
    println!("A DELIBERATELY BROKEN COPY — one path the model does not have, one");
    println!("form slot the form does not declare:");
    for e in som::validate_document(model, &broken.borrow()) {
        println!("  {:<20} {}", e.code, clip(&e.path, 50));
    }
    println!();

    println!("THE CLOSED VERDICT SETS. Rust has them as closed lists of string");
    println!("constants, so a tool switches over them exhaustively rather than");
    println!("matching on message text:");
    let codes = som::SPEC_VALIDATION_ALL_CODES;
    println!(
        "  SPEC_VALIDATION_ALL_CODES ({}): {}",
        codes.len(),
        codes.join(", ")
    );
    let rules = som::DOCSPECS_ALL_RULES;
    println!("  DOCSPECS_ALL_RULES ({}):", rules.len());
    for chunk in rules.chunks(4) {
        println!("    {}", chunk.join(", "));
    }
}

// ===========================================================================
// 5. The tool
// ===========================================================================

fn the_tool(model: &som::SpecModel, schema: som::DocSpecsSchema, doc: &som::SpecDocument) {
    section(5, "A tool: the completeness report");
    println!("Built on all four surfaces above, and it reports something NEITHER");
    println!("validator can. The schema names what is REQUIRED and missing; an");
    println!("optional section left blank is perfectly valid and no validator will");
    println!("ever mention it. But \"which parts of this specification has nobody");
    println!("written yet?\" is the question a specification author actually has,");
    println!("and answering it means walking the model and asking the document.");
    println!();

    let report = specification_coverage(model, doc, K_ROOT_SEGMENT);
    println!(
        "  {} WRITTEN / OFFERED",
        pad_right("SECTION", K_TITLE_WIDTH)
    );
    for row in &report.rows {
        let bar = if row.offered == 0 {
            String::new()
        } else {
            format!("{:>6}", format!("{}%", pct(row.written, row.offered)))
        };
        println!(
            "  {} {:>5} / {:>5}{}",
            pad_right(&row.title, K_TITLE_WIDTH),
            row.written,
            row.offered,
            bar
        );
    }
    println!("  {} {}", "-".repeat(K_TITLE_WIDTH), "-".repeat(19));
    println!(
        "  {} {:>5} / {:>5}{:>6}",
        pad_right("TOTAL", K_TITLE_WIDTH),
        report.written,
        report.offered,
        format!("{}%", pct(report.written, report.offered))
    );
    println!();
    let mut largest = &report.rows[0];
    for row in &report.rows[1..] {
        if row.offered > largest.offered {
            largest = row;
        }
    }
    println!(
        "  {} offers {} positions because a Solution Blueprint SEEDS",
        largest.title.split(' ').next().unwrap_or(""),
        largest.offered
    );
    println!("  the twelve Phase-3 documents: its section classes ARE those");
    println!("  documents' types, so the model surface under an SBP root includes");
    println!("  everything it seeds. A tool that reports \"0 %\" against a number");
    println!("  like that should say what the denominator is — which is why the");
    println!("  report is per section and not one headline figure.");
    println!();
    println!("  Required-and-missing, from the schema tier, for contrast:");
    let required = som::DocSpecsValidator::new(schema)
        .validate_markdown(&doc.to_markdown(model, Some(K_ROOT)).expect("markdown"))
        .iter()
        .filter(|v| v.rule == som::DOCSPECS_RULE_MISSING_REQUIRED_FIELD)
        .count();
    println!(
        "    {} missing required field(s) — the only gaps a validator",
        required
    );
    println!(
        "    will name, out of {} unwritten positions.",
        report.offered - report.written
    );
    println!();
    println!("That gap between the two numbers is the tool's reason to exist.");
}

struct CoverageRow {
    title: String,
    offered: usize,
    written: usize,
}

struct CoverageReport {
    rows: Vec<CoverageRow>,
    offered: usize,
    written: usize,
}

#[derive(Default)]
struct Counter {
    offered: usize,
    written: usize,
}

/// Walks `model` from `root_segment` and counts, per top-level section, how
/// many content positions the model offers and how many `doc` has written.
///
/// **Lists count as one position, not as their items.** A list the author
/// left empty offers exactly one thing to write — the first item — and a list
/// with forty items has not made the document forty times more complete.
///
/// The walk is entirely generic: it knows no class or field name, so it works
/// unchanged against any of the fourteen document roots.
fn specification_coverage(
    model: &som::SpecModel,
    doc: &som::SpecDocument,
    root_segment: &str,
) -> CoverageReport {
    let reflection = som::SpecReflection::new(model);
    let root = reflection
        .root_for_segment(root_segment)
        .expect("the document root");
    let mut report = CoverageReport {
        rows: Vec::new(),
        offered: 0,
        written: 0,
    };
    for field in reflection.fields_of(&root.type_) {
        if field.kind == som::SPEC_FIELD_KIND_CONTENT {
            continue; // the root's own body
        }
        let mut counter = Counter::default();
        let path = format!("{}/{}", root_segment, reflection.field_segment(field));
        let seen = BTreeSet::from([root.type_.clone()]);
        walk(&reflection, doc, &mut counter, field, &path, &seen);
        if counter.offered == 0 {
            continue;
        }
        report.offered += counter.offered;
        report.written += counter.written;
        report.rows.push(CoverageRow {
            title: row_title(field),
            offered: counter.offered,
            written: counter.written,
        });
    }
    report
}

/// Adds every content position under `field` at `path`. `seen` carries the
/// class names already on this branch; the model is a graph, and a section
/// type that can contain itself would otherwise recurse forever.
fn walk(
    reflection: &som::SpecReflection,
    doc: &som::SpecDocument,
    counter: &mut Counter,
    field: &som::SpecField,
    path: &str,
    seen: &BTreeSet<String>,
) {
    match field.kind.as_str() {
        som::SPEC_FIELD_KIND_CONTENT | som::SPEC_FIELD_KIND_SCALAR | som::SPEC_FIELD_KIND_ENUM => {
            counter.offered += 1;
            if doc.has_content(path) {
                counter.written += 1;
            }
        }
        som::SPEC_FIELD_KIND_FORM => {
            for slot in &field.form_fields {
                counter.offered += 1;
                if !doc.form_field_or(path, &slot.name).is_empty() {
                    counter.written += 1;
                }
            }
        }
        som::SPEC_FIELD_KIND_LIST => {
            counter.offered += 1;
            if doc.list_item_count(path) > 0 {
                counter.written += 1;
            }
        }
        som::SPEC_FIELD_KIND_SECTION | som::SPEC_FIELD_KIND_COMPLEX => {
            let ty = &field.type_;
            if ty.is_empty() || seen.contains(ty) {
                return;
            }
            let mut next = seen.clone();
            next.insert(ty.clone());
            for child in reflection.fields_of(ty) {
                let child_path = format!("{}/{}", path, reflection.field_segment(child));
                walk(reflection, doc, counter, child, &child_path, &next);
            }
        }
        _ => {}
    }
}

/// A section's title for the report — its model doc comment's first sentence,
/// falling back to the field name where the model carries no doc.
fn row_title(field: &som::SpecField) -> String {
    let mut text = field
        .doc
        .split('\n')
        .next()
        .unwrap_or("")
        .trim()
        .to_string();
    if let Some(stop) = text.find(". ") {
        text.truncate(stop);
    }
    let text = text.trim_end_matches('.').trim().to_string();
    if text.is_empty() {
        return field.name.clone();
    }
    let chars: Vec<char> = text.chars().collect();
    if chars.len() <= K_TITLE_WIDTH {
        text
    } else {
        format!("{}…", chars[..K_TITLE_WIDTH - 1].iter().collect::<String>())
    }
}

// ===========================================================================
// The fixture
// ===========================================================================

/// Writes the small, deliberately incomplete document this run inspects — the
/// same one the Dart sample writes.
fn author_fixture(sbp: &D00SolutionBlueprint) {
    sbp.set_content("A platform that unifies our fragmented order systems.");
    sbp.introduction_and_scope()
        .set_content("Replace three regional order desks with one intake service.");
    sbp.current_landscape()
        .set_content("Three legacy systems with no shared customer record.");

    let metrics = sbp.current_landscape().operational_metrics();
    metrics.add_content_on(
        "Average order turnaround: 4.2 days.",
        K_AUTHORED_MONTH,
        K_AUTHORED_DAY,
    );
    metrics.add_content_on(
        "Manual reconciliation: ~12 hours per week.",
        K_AUTHORED_MONTH,
        K_AUTHORED_DAY,
    );

    let customer = sbp
        .information_and_data_model()
        .data_model()
        .entities()
        .add_on(K_AUTHORED_MONTH, K_AUTHORED_DAY);
    customer.node.set_headline("Customer");
    let identity = customer.identity();
    identity.set_entity_name("Customer");
    identity.set_table_name("customers");
    identity.set_description("A party that places orders.");
    // `category` is written and `aggregateRoot` is not, and `aggregateRoot` is
    // REQUIRED — so the schema tier has one real violation to report in step 4.
    customer.classification().set_category("MasterData");
}

// ===========================================================================
// Small helpers
// ===========================================================================

fn new_root(doc: &som::DocRef) -> D00SolutionBlueprint {
    D00SolutionBlueprint::new(doc.clone(), "").expect("a typed root")
}

/// Reads a file of the checkout, given relative to `tom_ai/ai_build` (three
/// folders above this crate). The Dart packages ship the model and the
/// schemas with accessors; the Rust crates ship them as files.
fn read_checkout(relative: &str) -> String {
    let path = format!("{}/../../../{}", env!("CARGO_MANIFEST_DIR"), relative);
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("{}: {}", path, e))
}

fn section(n: usize, title: &str) {
    println!();
    println!("{}", "=".repeat(74));
    println!("{}. {}", n, title);
    println!("{}", "=".repeat(74));
}

fn clip(s: &str, width: usize) -> String {
    let chars: Vec<char> = s.replace('\n', " ").chars().collect();
    if chars.len() <= width {
        chars.into_iter().collect()
    } else {
        format!("{}…", chars[..width - 1].iter().collect::<String>())
    }
}

/// Pads to `width` characters (`{:<n}` pads by characters too, but a title is
/// built here, so the helper states it).
fn pad_right(s: &str, width: usize) -> String {
    format!("{:<width$}", s, width = width)
}

fn pct(written: usize, offered: usize) -> i64 {
    (100.0 * written as f64 / offered as f64).round() as i64
}

fn sorted(mut values: Vec<String>) -> Vec<String> {
    values.sort();
    values
}

fn opt(value: Option<i64>) -> String {
    value.map_or("null".to_string(), |v| v.to_string())
}

/// A field kind by the name the Dart enum gives it (`enum` is `enumValue`).
fn kind_name(kind: &str) -> &str {
    if kind == som::SPEC_FIELD_KIND_ENUM {
        "enumValue"
    } else {
        kind
    }
}
