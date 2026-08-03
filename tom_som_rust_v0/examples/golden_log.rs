// Cross-language golden-log generator for Rust (SOM §19).
//
// Mirror of tom_som_dart_v0/tool/golden_log.dart — see that file for the
// canonical format. Loads the shared sample and emits a byte-identical reading
// of essentially every section through both the generic string-path API and the
// typed facade, asserting typed == generic before writing.
//
// Run from the crate root:  cargo run --example golden_log [samplePath] [output]

use std::fs;
use std::path::Path;
use std::process::exit;

use tom_som_rust_runtime as som;
use tom_som_rust_v0::{meta, D00SolutionBlueprint};

fn esc(s: &str) -> String {
    s.replace('\\', "\\\\")
        .replace('\n', "\\n")
        .replace('\r', "\\r")
        .replace('\t', "\\t")
}

fn die(msg: &str) -> ! {
    eprintln!("{}", msg);
    exit(2);
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let sample = if args.len() > 1 {
        args[1].clone()
    } else {
        "../tom_som_conformance/samples/meridian_order_management.docspecs.yaml".to_string()
    };
    let output = if args.len() > 2 {
        args[2].clone()
    } else {
        "../tom_som_conformance/golden/rust.log".to_string()
    };

    // Hierarchical v2 decoding walks the root's generated metadata tree.
    let tree = meta::d00_solution_blueprint_meta_tree();
    let doc = match som::SpecDocument::from_file(&sample, &tree) {
        Ok(d) => d,
        Err(e) => die(&format!("load sample failed: {}", e)),
    };
    let sbp = match D00SolutionBlueprint::load_file(&sample) {
        Ok(s) => s,
        Err(e) => die(&format!("load typed root failed: {}", e)),
    };

    let mut out: Vec<String> = Vec::new();
    out.push("# TomSpecs SOM golden log — canonical cross-language reading.".to_string());
    out.push("# All nine per-language generators must emit byte-identical output.".to_string());
    out.push("FORMAT\t9".to_string());
    out.push(format!("MODELVERSION\t{}", esc(&doc.model_version)));

    // Generic: content leaves, sorted by path.
    out.push("SECTION\tgeneric-content".to_string());
    let mut content_paths = doc.content_paths();
    content_paths.sort();
    for p in &content_paths {
        out.push(format!("C\t{}\t{}", p, esc(&doc.content_or(p))));
    }

    // Generic: form sections + fields, sorted by path then field.
    out.push("SECTION\tgeneric-forms".to_string());
    let mut form_paths = doc.form_paths();
    form_paths.sort();
    for p in &form_paths {
        let mut fields = doc.form_field_names(p);
        fields.sort();
        for f in &fields {
            out.push(format!("F\t{}\t{}\t{}", p, f, esc(&doc.form_field_or(p, f))));
        }
    }

    // Generic: list containers + item paths (document order). FORMAT 3: each
    // item with a *stored* section id additionally emits an `ID` line (item
    // path + stored id); items without one emit no `ID` line.
    out.push("SECTION\tgeneric-lists".to_string());
    let mut list_paths = doc.list_paths();
    list_paths.sort();
    for p in &list_paths {
        let items = doc.list_items(p);
        out.push(format!("L\t{}\t{}", p, items.len()));
        for item in &items {
            out.push(format!("I\t{}", item));
            if let Some(id) = doc.item_section_id(item) {
                out.push(format!("ID\t{}\t{}", item, esc(id)));
            }
        }
    }

    // Generic: every stored headline, sorted by path (FORMAT 3, YRD3).
    out.push("SECTION\tgeneric-headlines".to_string());
    let mut headline_paths = doc.headline_paths();
    headline_paths.sort();
    for p in &headline_paths {
        out.push(format!("H\t{}\t{}", p, esc(&doc.headline_or(p))));
    }

    // Generic: every stored codeSpec, sorted by path (FORMAT 8, codespecs_mapping.md §9.2 mirror of headline).
    out.push("SECTION\tgeneric-codespecs".to_string());
    let mut code_spec_paths = doc.code_spec_paths();
    code_spec_paths.sort();
    for p in &code_spec_paths {
        out.push(format!("CS\t{}\t{}", p, esc(&doc.code_spec_or(p))));
    }

    // Typed cross-check of the same two mappings through the facade's structural
    // `code_spec` accessor (codespecs_mapping.md §9.2). Emits nothing: the values are already in the
    // `CS` lines above, so a duplicate line would add no information — what this
    // adds is the assertion that the typed accessor reads the same store the
    // generic API does. A divergence aborts the generator.
    let typed_code_spec = |node: &som::SomNode| {
        let typed = node.code_spec();
        let generic = doc.code_spec_or(node.path());
        if typed != generic {
            die(&format!(
                "CODESPEC MISMATCH at {}: typed=\"{}\" generic=\"{}\"",
                node.path(),
                typed,
                generic
            ));
        }
    };

    let typed_frs = sbp.introduction_and_scope().requirements().functional_requirements();
    typed_code_spec(&typed_frs.node);
    typed_code_spec(&typed_frs.requirements().at(0).node);

    // Typed: curated traversal that must agree with the generic reads.
    out.push("SECTION\ttyped".to_string());

    let mut typed_content = |node_path: &str, value: &str| {
        let leaf = format!("{}/content", node_path);
        let generic = doc.content_or(&leaf);
        if value != generic {
            die(&format!("TYPED MISMATCH at {}", leaf));
        }
        out.push(format!("T\t{}\t{}", leaf, esc(value)));
    };

    typed_content(sbp.node.path(), &sbp.content());
    let n = sbp.document_control();
    typed_content(n.node.path(), &n.content());
    let n = sbp.introduction_and_scope();
    typed_content(n.node.path(), &n.content());
    let n = sbp.glossary_and_abbreviations();
    typed_content(n.node.path(), &n.content());
    let n = sbp.stakeholders_and_governance();
    typed_content(n.node.path(), &n.content());
    let n = sbp.current_landscape();
    typed_content(n.node.path(), &n.content());
    let n = sbp.assumptions_constraints_dependencies();
    typed_content(n.node.path(), &n.content());
    let n = sbp.target_operating_model_concept();
    typed_content(n.node.path(), &n.content());
    let n = sbp.information_and_data_model();
    typed_content(n.node.path(), &n.content());
    let n = sbp.requirements();
    typed_content(n.node.path(), &n.content());
    let n = sbp.solution_architecture_and_technology();
    typed_content(n.node.path(), &n.content());
    let n = sbp.security_and_access_model();
    typed_content(n.node.path(), &n.content());
    let n = sbp.experience_and_interface_design();
    typed_content(n.node.path(), &n.content());
    let n = sbp.quality_and_acceptance_model();
    typed_content(n.node.path(), &n.content());
    let n = sbp.delivery_transition_and_rollout();
    typed_content(n.node.path(), &n.content());

    let intro = sbp.introduction_and_scope();
    let goals = intro.goals();
    typed_content(goals.node.path(), &goals.content());

    let cl = sbp.current_landscape();
    let metrics = cl.operational_metrics();
    let metric_item_paths = doc.list_items(metrics.list_path());
    if metrics.length() != metric_item_paths.len() {
        die(&format!("TYPED LIST LENGTH MISMATCH at {}", metrics.list_path()));
    }
    out.push(format!("TL\t{}\t{}", metrics.list_path(), metrics.length()));
    for i in 0..metrics.length() {
        let elem = metrics.at(i);
        let leaf = format!("{}/content", elem.node.path());
        let generic = doc.content_or(&leaf);
        if elem.content() != generic {
            die(&format!("TYPED LIST ITEM MISMATCH at {}", leaf));
        }
        out.push(format!("TI\t{}\t{}", leaf, esc(&elem.content())));
    }

    // --- Typed non-String form fields (FORMAT 7, YRD7): native int/bool/enum
    // members read through the typed facade and asserted against the generic
    // form store, canonicalised through the SAME boundary rules the facade
    // setters used to write them (int -> decimal, bool -> "true"/"false", enum
    // -> constant name). The emitted value is the raw stored string, so the
    // lines are byte-identical across languages regardless of native types. ---
    out.push("SECTION\ttyped-form".to_string());
    let som_format_int = |v: Option<i64>| -> String {
        v.map(|x| x.to_string()).unwrap_or_default()
    };
    let som_format_bool = |v: Option<bool>| -> String {
        v.map(|x| if x { "true" } else { "false" }.to_string())
            .unwrap_or_default()
    };
    let typed_form = |form_path: &str, field: &str, canonical: &str| -> String {
        let generic = doc.form_field_or(form_path, field);
        if canonical != generic {
            die(&format!(
                "TYPED FORM MISMATCH at {}.{}: typed=\"{}\" generic=\"{}\"",
                form_path, field, canonical, generic
            ));
        }
        format!("TF\t{}\t{}\t{}", form_path, field, esc(&generic))
    };

    let actor_overview = sbp
        .target_operating_model_concept()
        .process_steps_and_actor_interactions()
        .actor_overview()
        .overview();
    let ao_path = actor_overview.node.path().to_string();
    out.push(typed_form(&ao_path, "totalActorCount",
        &som_format_int(actor_overview.total_actor_count())));
    out.push(typed_form(&ao_path, "humanActorCount",
        &som_format_int(actor_overview.human_actor_count())));
    out.push(typed_form(&ao_path, "systemActorCount",
        &som_format_int(actor_overview.system_actor_count())));
    out.push(typed_form(&ao_path, "externalActorCount",
        &som_format_int(actor_overview.external_actor_count())));

    let accessibility_overview = sbp
        .experience_and_interface_design()
        .design_follow_up()
        .accessibility()
        .accessibility_overview_content();
    let acc_path = accessibility_overview.node.path().to_string();
    out.push(typed_form(&acc_path, "accessibilityStatement",
        &som_format_bool(accessibility_overview.accessibility_statement())));

    let coverage = sbp
        .quality_and_acceptance_model()
        .iso25010_coverage()
        .characteristics();
    out.push(format!("TL\t{}\t{}", coverage.list_path(), coverage.length()));
    for i in 0..coverage.length() {
        let cform = coverage.at(i).content();
        let cpath = cform.node.path().to_string();
        out.push(typed_form(&cpath, "characteristic", &cform.characteristic()));
    }

    // --- Meta (FORMAT 2): the generated metadata tree read three ways. Every
    // emitted path/field is model-derived so the lines match across languages.
    let dot = meta::d00_solution_blueprint_meta(&tree);
    let sbp_id = meta::SBP(&tree);

    // Map the native kind string to the canonical DART enum spelling.
    fn kind_name(kind: &str) -> &'static str {
        match kind {
            som::SOM_META_KIND_LIST => "list",
            som::SOM_META_KIND_FORM => "form",
            som::SOM_META_KIND_SECTION => "section",
            som::SOM_META_KIND_CONTENT => "content",
            som::SOM_META_KIND_ENUM_VALUE => "enumValue",
            som::SOM_META_KIND_COMPLEX => "complex",
            som::SOM_META_KIND_SCALAR => "scalar",
            other => die(&format!("UNKNOWN META KIND {}", other)),
        }
    }

    out.push("SECTION\tmeta".to_string());
    for path in [
        "SBP",
        "SBP/documentControl",
        "SBP/documentControl/RVENT-REVS-LST",
        "SBP/introductionAndScope",
        "SBP/introductionAndScope/goals",
        "SBP/introductionAndScope/goals/content",
        "SBP/currentLandscape",
        "SBP/currentLandscape/CUOPME-OPER-LST",
        "SBP/requirements",
        "SBP/requirements/content",
    ] {
        let n = match tree.by_path(path) {
            Some(n) => n,
            None => die(&format!("META MISSING at {}", path)),
        };
        out.push(format!(
            "M\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
            path,
            kind_name(&n.kind),
            esc(&n.section_id),
            esc(&n.content_help),
            esc(&n.comment),
            esc(&n.doc_comment),
            esc(&n.headline),
        ));
    }

    // --- Meta form fields (FORMAT 7, YRD7): the FRE list-element content form
    // read through the metadata tree — one MF line per field (declaration
    // order) with type/required plus the enumValues column. All values are
    // model-derived. ---
    out.push("SECTION\tmeta-form".to_string());
    // Generalized over any list path whose element content is a form: emit one
    // MF line per field (declaration order) with type/required and the
    // enumValues column (FORMAT 7, YRD7 — comma-joined constant names, empty
    // for non-enum fields) and the refersTo column (FORMAT 9, csrb3 —
    // comma-joined registry keys, empty for non-reference fields).
    let mut meta_form = |list_path: &str| {
        let element = tree
            .by_path(list_path)
            .and_then(|n| n.element_node.clone());
        let mut content_node: Option<std::rc::Rc<som::SomMetaNode>> = None;
        if let Some(element) = &element {
            for child in &element.children {
                if child.member_name == "content" {
                    content_node = Some(child.clone());
                }
            }
        }
        let form = match content_node.as_ref().and_then(|n| n.form.clone()) {
            Some(f) => f,
            None => {
                eprintln!("META FORM MISSING at {} element content", list_path);
                exit(3);
            }
        };
        // Element subtrees have no static document path; use an ASCII marker
        // segment so the log path stays ASCII (mirrored verbatim per language).
        let form_path = format!("{}/#element/content", list_path);
        for f in &form.fields {
            out.push(format!(
                "MF\t{}\t{}\t{}\t{}\t{}\t{}",
                form_path,
                esc(&f.name),
                esc(&f.type_name),
                if f.required { 1 } else { 0 },
                esc(&f.enum_values.join(",")),
                esc(&f.refers_to.join(",")),
            ));
        }
    };
    meta_form("SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST");
    meta_form("SBP/qualityAndAcceptanceModel/iso25010Coverage/I25CE-CHAR-LST");
    meta_form(
        "SBP/experienceAndInterfaceDesign/experienceCodeSpecs/screenFlow/screenRouteMap/SCTREN-TRAN-LST",
    );

    // Dot-notation navigation: the typed accessor must resolve to the same path
    // and the same node instance as by_path.
    out.push("SECTION\tmeta-nav".to_string());
    let mut meta_nav = |actual_path: &str, node: &std::rc::Rc<som::SomMetaNode>, expected: &str| {
        if actual_path != expected {
            die(&format!(
                "META NAV PATH at {} expected {}",
                actual_path, expected
            ));
        }
        let by_path = match tree.by_path(expected) {
            Some(n) => n,
            None => die(&format!("META NAV NODE mismatch at {}", expected)),
        };
        if !std::rc::Rc::ptr_eq(node, &by_path) {
            die(&format!("META NAV NODE mismatch at {}", expected));
        }
        out.push(format!("N\t{}", expected));
    };

    let intro = dot.introduction_and_scope();
    let goals = intro.goals();
    let goals_content = goals.content();
    let req = dot.requirements();
    let req_content = req.content();
    let doc_control = dot.document_control();
    let current = dot.current_landscape();
    meta_nav(dot.path(), &dot.meta().unwrap_or_else(|e| die(&e)), "SBP");
    meta_nav(
        doc_control.path(),
        &doc_control.meta().unwrap_or_else(|e| die(&e)),
        "SBP/documentControl",
    );
    meta_nav(
        intro.path(),
        &intro.meta().unwrap_or_else(|e| die(&e)),
        "SBP/introductionAndScope",
    );
    meta_nav(
        goals.path(),
        &goals.meta().unwrap_or_else(|e| die(&e)),
        "SBP/introductionAndScope/goals",
    );
    meta_nav(
        &goals_content.path,
        &goals_content.meta().unwrap_or_else(|e| die(&e)),
        "SBP/introductionAndScope/goals/content",
    );
    meta_nav(
        current.path(),
        &current.meta().unwrap_or_else(|e| die(&e)),
        "SBP/currentLandscape",
    );
    meta_nav(
        req.path(),
        &req.meta().unwrap_or_else(|e| die(&e)),
        "SBP/requirements",
    );
    meta_nav(
        &req_content.path,
        &req_content.meta().unwrap_or_else(|e| die(&e)),
        "SBP/requirements/content",
    );

    // ID-tree navigation: hoisted-id accessors agree with the dot position.
    out.push("SECTION\tmeta-id".to_string());
    let mut meta_id = |id_path: &str,
                       id_meta: &std::rc::Rc<som::SomMetaNode>,
                       nav_path: &str,
                       nav_meta: &std::rc::Rc<som::SomMetaNode>| {
        if id_path != nav_path || !std::rc::Rc::ptr_eq(id_meta, nav_meta) {
            die(&format!("META ID mismatch at {} vs {}", id_path, nav_path));
        }
        out.push(format!("D\t{}", id_path));
    };

    let revs = doc_control.revision_history();
    let hoisted = sbp_id.RVENT_REVS_LST();
    meta_id(
        sbp_id.path(),
        &sbp_id.meta().unwrap_or_else(|e| die(&e)),
        dot.path(),
        &dot.meta().unwrap_or_else(|e| die(&e)),
    );
    meta_id(
        &hoisted.meta_ref.path,
        &hoisted.meta_ref.meta().unwrap_or_else(|e| die(&e)),
        &revs.meta_ref.path,
        &revs.meta_ref.meta().unwrap_or_else(|e| die(&e)),
    );
    let hoisted_item = hoisted.item(0);
    let revs_item = revs.item(0);
    meta_id(
        hoisted_item.path(),
        &hoisted_item.meta().unwrap_or_else(|e| die(&e)),
        revs_item.path(),
        &revs_item.meta().unwrap_or_else(|e| die(&e)),
    );

    // DocSpecs validation of the shared markdown sample against the generated
    // Solution-Blueprint schema.
    out.push("SECTION\tdocspecs".to_string());
    let schema_path = "schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml";
    let schema_text =
        fs::read_to_string(schema_path).unwrap_or_else(|e| die(&format!("read schema: {}", e)));
    let schema = som::DocSpecsSchema::from_yaml_text(&schema_text)
        .unwrap_or_else(|e| die(&format!("from_yaml_text: {}", e)));
    let sample_md_path = "../tom_som_conformance/samples/meridian_order_management.md";
    let sample_md =
        fs::read_to_string(sample_md_path).unwrap_or_else(|e| die(&format!("read sample md: {}", e)));
    let root_id = schema.root_section_id();
    let warnings_len = schema.warnings.len();
    let violations = som::DocSpecsValidator::new(schema).validate_markdown(&sample_md);
    out.push(format!("DS\troot\t{}", esc(&root_id)));
    out.push(format!("DS\twarnings\t{}", warnings_len));
    out.push(format!("DS\tviolations\t{}", violations.len()));
    for v in &violations {
        out.push(format!("DV\t{}\t{}\t{}", v.rule, esc(&v.section_id), v.line));
    }

    if let Some(parent) = Path::new(&output).parent() {
        fs::create_dir_all(parent).unwrap_or_else(|e| die(&format!("mkdir failed: {}", e)));
    }
    let body = format!("{}\n", out.join("\n"));
    fs::write(&output, body).unwrap_or_else(|e| die(&format!("write failed: {}", e)));
    println!("wrote {} lines to {}", out.len(), output);
}
