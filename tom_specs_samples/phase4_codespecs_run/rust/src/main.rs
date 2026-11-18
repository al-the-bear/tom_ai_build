//! TomSpecs sample — a Phase 4 CodeSpecs run, as far as the Rust runtime goes.
//!
//! The Rust port of `../bin/phase4_codespecs_run.dart`. Phase 4 has four
//! stages, and the Rust runtime carries the first two:
//!
//! ```text
//!   stage 1  the starting prompt's quality gate   [MECHANICAL]  here
//!   stage 2  the extract generator                [MECHANICAL]  here
//!   stage 3  the authoring agent                  [JUDGMENT]    the IR, Dart tools
//!   stage 4  validating the emitted trio          [MECHANICAL]  Dart tools
//! ```
//!
//! Stages 3 and 4 run on the Dart tools (`tomspecs :ir-map`,
//! `tomspecs :codespecs-validate`); the Dart sample shows them. This port runs
//! the same specification through the gate and the extract generator, and its
//! extracts are the ones the Dart sample writes (`CodeSpecsExtract` is in all
//! nine runtimes, byte for byte the same).
//!
//! Run (from this folder; see README.md):  `cargo run`

use std::fs;
use std::path::Path;
use std::process::exit;

use tom_som_rust_runtime as som;
use tom_som_rust_v0::D00SolutionBlueprint;

/// The one `@Document` root this run extracts from (codespecs_prompt.md §5).
const K_ROOT: &str = "D00SolutionBlueprint";

/// The creation date section-id generation is pinned to (1 January), so the
/// ids (and with them `expected_output.txt`) do not change with the calendar.
const K_AUTHORED_MONTH: i64 = 1;
const K_AUTHORED_DAY: i64 = 1;

/// What every gate run takes: the model, the schema and the area catalogue.
struct Inputs {
    model: som::SpecModel,
    schema: som::DocSpecsSchema,
    catalog: som::CodeSpecsAreaCatalog,
}

fn main() {
    let inputs = Inputs {
        model: som::SpecModel::from_json(&json(&read_checkout(
            "tom_som_rust_v0/meta/spec_model.meta.json",
        ))),
        schema: som::DocSpecsSchema::from_yaml_text(&read_checkout(
            "tom_som_rust_v0/schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml",
        ))
        .expect("schema"),
        catalog: som::CodeSpecsAreaCatalog::from_json(&json(&read_checkout(
            "tom_specs_model/generated-doc/codespecs/codespecs_areas.json",
        )))
        .expect("catalogue"),
    };

    rule("A Phase 4 CodeSpecs run, stage by stage");
    println!("Every step is marked [MECHANICAL] or [JUDGMENT].");
    println!();

    let extracts = variant_a(&inputs);
    variant_b(&inputs);

    println!();
    println!(
        "Extracts written to build/codespecs_extracts/ ({} files).",
        extracts.len() * 2
    );
}

// ---------------------------------------------------------------------------
// Variant A — a document that passes, taken as far as the extracts.
// ---------------------------------------------------------------------------

fn variant_a(inputs: &Inputs) -> Vec<som::CodeSpecsExtract> {
    let doc = som::doc_ref(som::SpecDocument::new());
    author_specification(&new_root(&doc), true);

    rule("Variant A — a sufficient specification");
    println!("0. The document under Phase 4                 [input]");
    println!("   a Solution Blueprint whose information model holds 2 entities");
    println!("   and 4 stored attributes; every other section is unwritten.");
    println!();

    let gate = run_gate(inputs, &doc.borrow());
    if !gate.passed() {
        eprintln!("variant A was supposed to pass the gate");
        for f in gate.findings() {
            eprintln!("  {}", f);
        }
        exit(1);
    }
    println!("   gate verdict             : PASS — the run may begin");
    println!();

    // A passed gate always carries its extracts.
    let extracts = gate.extracts.expect("extracts");
    stage2(&extracts);
    stages3and4();
    extracts
}

// ---------------------------------------------------------------------------
// Variant B — the same document with one required field cleared.
// ---------------------------------------------------------------------------

fn variant_b(inputs: &Inputs) {
    let doc = som::doc_ref(som::SpecDocument::new());
    author_specification(&new_root(&doc), false);

    rule("Variant B — the same document, one required field cleared");
    println!("Both entities keep their `DAENT-CLAS` section and its `category`, and");
    println!("both have `aggregateRoot` cleared. Nothing else changed.");
    println!();

    let gate = run_gate(inputs, &doc.borrow());
    if gate.passed() {
        eprintln!("variant B was supposed to be rejected");
        exit(1);
    }
    println!("   gate verdict             : REJECTED — the run may not begin");
    println!();
    println!("   What the gate names, per finding:");
    for f in gate.findings() {
        println!(
            "     {} {} [{}] {}",
            f.check.label(),
            f.code,
            f.location,
            f.message
        );
    }
    println!();
    let a2 = gate
        .get(som::CodeSpecsGateCheck::A2)
        .map_or(0, |r| r.findings.len());
    println!(
        "   A2 moved too: {} violations, against 0 for variant A. The",
        a2
    );
    println!("   classification form still holds other values, so its empty");
    println!("   required field is reported by both tiers. They part where a value");
    println!("   is absent rather than empty: a missing required section is seen by");
    println!("   A1 alone. That is why the gate runs both tiers and not either one");
    println!("   (codespecs_prompt.md §4.1/§4.2 and its §10.1/§10.2 fixtures).");
    println!();
}

// ---------------------------------------------------------------------------
// Stage 1 — the mechanical gate (codespecs_prompt.md §4).
// ---------------------------------------------------------------------------

fn title(check: som::CodeSpecsGateCheck) -> &'static str {
    match check {
        som::CodeSpecsGateCheck::A1 => "schema completeness  ",
        som::CodeSpecsGateCheck::A2 => "instance-tier values ",
        som::CodeSpecsGateCheck::A3 => "routing totality     ",
        som::CodeSpecsGateCheck::A4 => "required arguments   ",
        som::CodeSpecsGateCheck::A5 => "structured carriers  ",
    }
}

/// Runs the mechanical tier over `doc` and prints each check's verdict. All
/// five checks run as one gate and none stops the others; a check that could
/// not run says so, and the gate does not pass.
fn run_gate(inputs: &Inputs, doc: &som::SpecDocument) -> som::CodeSpecsGateReport {
    println!("1. The starting prompt's quality gate        [MECHANICAL]");
    let report = som::CodeSpecsGate::new(
        &inputs.model,
        doc,
        &inputs.catalog,
        Some(&inputs.schema),
        Some(K_ROOT),
    )
    .run();
    for r in &report.results {
        let verdict = if !r.ran {
            format!("NOT RUN — {}", r.not_run_reason.as_deref().unwrap_or(""))
        } else if r.findings.is_empty() {
            "pass — 0 findings".to_string()
        } else {
            format!("FAIL — {} findings", r.findings.len())
        };
        println!("   {} {}: {}", r.check.label(), title(r.check), verdict);
    }
    println!(
        "   (A4 held {} required-argument rows, A5 {} carriers, both from the catalogue's gate tables)",
        inputs.catalog.required_arguments.len(),
        inputs.catalog.carriers.len()
    );
    report
}

// ---------------------------------------------------------------------------
// Stage 2 — the extract generator.
// ---------------------------------------------------------------------------

fn stage2(extracts: &[som::CodeSpecsExtract]) {
    println!("2. The extract generator                      [MECHANICAL]");
    let populated: Vec<_> = extracts.iter().filter(|e| !e.entries.is_empty()).collect();
    println!("   areas in the catalogue   : {}", extracts.len());
    println!("   populated                : {}", populated.len());
    for e in &populated {
        println!(
            "     {:<6} {} entries  → {}",
            e.area.code,
            e.entries.len(),
            e.projects.join(", ")
        );
    }
    println!(
        "   empty                    : {}",
        extracts.len() - populated.len()
    );
    println!("   Most areas are empty because this document says nothing about");
    println!("   screens, jobs, reports or migrations. An empty extract is a");
    println!("   CANDIDATE for \"not applicable\" — never the verdict itself, which");
    println!("   is a judgment and belongs to stage B (codespecs_prompt.md §6.4).");

    let out = Path::new("build").join("codespecs_extracts");
    fs::create_dir_all(&out).expect("create build/codespecs_extracts");
    for e in extracts {
        fs::write(out.join(format!("{}.yaml", e.file_stem())), e.to_yaml()).expect("write yaml");
        fs::write(out.join(format!("{}.md", e.file_stem())), e.to_markdown()).expect("write md");
    }
    println!();

    let db = extracts
        .iter()
        .find(|e| e.area.code == "CE-DB")
        .expect("the CE-DB extract");
    println!(
        "   Area {} — {}, the extract the",
        db.area.code, db.area.canonical_id
    );
    println!("   authoring agent reads in stage 3:");
    println!("   built on   : {}", db.area.built_on);
    println!("   may cite   : {}", db.citable_parts.join(", "));
    println!("   entries carried to the agent ({}):", db.entries.len());
    for entry in &db.entries {
        println!(
            "     {:<11} {:<14} {}",
            entry.section_id,
            entry.field_name,
            short(&entry.value)
        );
    }
    println!();
}

fn stages3and4() {
    println!("3. The authoring agent                        [JUDGMENT]");
    println!("4. Validating the emitted trio                [MECHANICAL]");
    println!("   Not in the Rust runtime. The authoring agent writes the IR");
    println!("   from these extracts, and the Dart tools map and validate it");
    println!("   (`tomspecs :ir-map`, `tomspecs :codespecs-validate`); the Dart");
    println!("   sample in ../bin/ shows both stages on this same specification.");
    println!();
}

// ---------------------------------------------------------------------------
// The specification — the one the Dart sample authors.
// ---------------------------------------------------------------------------

/// Two entities, four attributes and their keys: one area populated and the
/// rest empty. `aggregate_roots` false clears the one required field variant B
/// removes — `DAENT-CLAS.aggregateRoot` — and nothing else.
fn author_specification(sbp: &D00SolutionBlueprint, aggregate_roots: bool) {
    sbp.set_content("Order intake for a single region.");

    // The bounded context CE-SU's required `boundedContext` argument resolves
    // against: an unauthored registry would make the reference dangle at A2.
    let ordering = sbp
        .solution_architecture_and_technology()
        .technical_framework()
        .software_design()
        .layering_and_module_structure()
        .bounded_contexts()
        .add_on(K_AUTHORED_MONTH, K_AUTHORED_DAY);
    ordering.node.set_headline("Ordering");
    ordering.content().set_context_name("Ordering");
    ordering.content().set_domain_area("Order management");

    let entities = sbp.information_and_data_model().data_model().entities();

    let customer = entities.add_on(K_AUTHORED_MONTH, K_AUTHORED_DAY);
    customer.node.set_headline("Customer");
    customer.set_content("A party that places orders.");
    customer.identity().set_entity_name("Customer");
    customer.identity().set_table_name("customers");
    customer.identity().set_entity_alias("CUST");
    customer
        .identity()
        .set_description("A person or organisation that places orders.");
    customer.classification().set_category("MasterData");
    customer.classification().set_bounded_context("Ordering");
    if aggregate_roots {
        customer.classification().set_aggregate_root("Customer");
    }

    let email = customer
        .attributes()
        .add_on(K_AUTHORED_MONTH, K_AUTHORED_DAY);
    email.node.set_headline("email");
    email.identity().set_column_name("email");
    email
        .identity()
        .set_description("The address order confirmations are sent to.");
    email.data_type_spec().set_physical_type("VARCHAR");

    let display_name = customer
        .attributes()
        .add_on(K_AUTHORED_MONTH, K_AUTHORED_DAY);
    display_name.node.set_headline("displayName");
    display_name.identity().set_column_name("display_name");
    display_name
        .identity()
        .set_description("The name the customer trades under.");
    display_name.data_type_spec().set_physical_type("VARCHAR");

    // A customer is identified by the address it trades under: a natural key.
    let customer_key = customer
        .key_attributes()
        .add_on(K_AUTHORED_MONTH, K_AUTHORED_DAY);
    customer_key.node.set_headline("pk_customers");
    customer_key.content().set_key_type("Natural");
    customer_key.content().set_key_columns("email");
    customer_key
        .content()
        .set_description("A customer is identified by its e-mail address.");

    let order = entities.add_on(K_AUTHORED_MONTH, K_AUTHORED_DAY);
    order.node.set_headline("Order");
    order.set_content("One accepted customer order.");
    order.identity().set_entity_name("Order");
    order.identity().set_table_name("orders");
    order.identity().set_entity_alias("ORD");
    order
        .identity()
        .set_description("A single order placed by a customer.");
    order.classification().set_category("TransactionData");
    order.classification().set_bounded_context("Ordering");
    if aggregate_roots {
        order.classification().set_aggregate_root("Order");
    }

    let order_id = order.attributes().add_on(K_AUTHORED_MONTH, K_AUTHORED_DAY);
    order_id.node.set_headline("orderId");
    order_id.identity().set_column_name("order_id");
    order_id
        .identity()
        .set_description("The identifier the order is filed under.");
    order_id.data_type_spec().set_physical_type("UUID");

    let order_key = order
        .key_attributes()
        .add_on(K_AUTHORED_MONTH, K_AUTHORED_DAY);
    order_key.node.set_headline("pk_orders");
    order_key.content().set_key_type("Primary");
    order_key.content().set_key_columns("order_id");
    order_key.content().set_description("The order identifier.");
    order_key.generation().set_generation_strategy("UUID");

    let placed_at = order.attributes().add_on(K_AUTHORED_MONTH, K_AUTHORED_DAY);
    placed_at.node.set_headline("placedAt");
    placed_at.identity().set_column_name("placed_at");
    placed_at
        .identity()
        .set_description("The moment the order was accepted.");
    placed_at.data_type_spec().set_physical_type("TIMESTAMP");
}

// ---------------------------------------------------------------------------
// Helpers.
// ---------------------------------------------------------------------------

fn new_root(doc: &som::DocRef) -> D00SolutionBlueprint {
    D00SolutionBlueprint::new(doc.clone(), "").expect("a typed root")
}

/// Reads a file of the checkout, given relative to `tom_ai/ai_build` (three
/// folders above this crate). The Dart packages ship the model, schema and
/// area catalogue with accessors; the Rust crates ship them as files.
fn read_checkout(relative: &str) -> String {
    let path = format!("{}/../../../{}", env!("CARGO_MANIFEST_DIR"), relative);
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("{}: {}", path, e))
}

fn json(text: &str) -> som::Json {
    som::Json::parse(text).expect("JSON")
}

fn short(value: &str) -> String {
    let chars: Vec<char> = value.chars().collect();
    if chars.len() <= 44 {
        value.to_string()
    } else {
        format!("{}...", chars[..41].iter().collect::<String>())
    }
}

fn rule(title: &str) {
    println!("{}", "=".repeat(72));
    println!("{}", title);
    println!("{}", "=".repeat(72));
}
