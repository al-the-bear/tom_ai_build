//! Rejected blocks kept for review (SOM §11.7, DocSpecs RN-11): an import
//! accepting rejections keeps each rejected block as a `rejected` div in the
//! text of the section it stood in (else its parent), at its place. The kept
//! document re-exports and re-imports without a rejection and to the same
//! document, and the validator reports each div as `rejectedBlock`. A port of
//! `tom_som_python_runtime/tests/spec_document_markdown_rejected_kept_test.py`
//! (itself a port of the TypeScript suite); the single cases are pinned in the
//! conformance corpus (`markdown_apply_cases.json`).

use std::path::PathBuf;

use tom_som_rust_runtime::{
    validate_spec_document, DocSpecsSchema, SpecDocument, SpecDocumentMarkdown,
    SpecMarkdownResult, SpecModel, DOCSPECS_RULE_REJECTED_BLOCK,
};

struct Checker {
    passed: usize,
    failed: Vec<String>,
}

impl Checker {
    fn check(&mut self, name: &str, cond: bool, detail: &str) {
        if cond {
            self.passed += 1;
        } else if detail.is_empty() {
            self.failed.push(name.to_string());
        } else {
            self.failed.push(format!("{}: {}", name, detail));
        }
    }
}

struct Fixture {
    model: SpecModel,
    golden: String,
}

impl Fixture {
    fn load() -> Fixture {
        let corpus = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("..")
            .join("tom_som_conformance")
            .join("corpus");
        let read = |name: &str| {
            std::fs::read_to_string(corpus.join(name)).unwrap_or_else(|e| panic!("read {}: {}", name, e))
        };
        Fixture {
            model: SpecModel::from_json_str(&read("model.meta.json")).expect("the corpus model"),
            golden: read("expected.tables.md"),
        }
    }

    /// The golden with `source` (which it must hold) replaced by `target`.
    fn sub(&self, source: &str, target: &str) -> String {
        let at = self
            .golden
            .find(source)
            .unwrap_or_else(|| panic!("the golden has no {:?}", source));
        format!("{}{}{}", &self.golden[..at], target, &self.golden[at + source.len()..])
    }

    fn parse(&self, markdown: &str) -> SpecMarkdownResult {
        SpecDocumentMarkdown::new(&self.model, &SpecDocument::new()).parse(markdown)
    }

    fn kept(&self, markdown: &str) -> SpecDocument {
        let mut doc = SpecDocument::new();
        doc.apply_markdown_result(&self.parse(markdown), true)
            .expect("rejections are allowed");
        doc
    }

    fn variants(&self) -> Vec<(&'static str, String)> {
        vec![
            (
                "unknown section",
                format!("{}\n## <!--[NOPE]--> Not A Section\n\nText with no home.\n", self.golden),
            ),
            ("near-miss row", self.sub("| Owner | Bob |", "| Owner | Bob |\n| Ownr | Carol |")),
            ("row given twice", self.sub("| Estimate | 8 |", "| Estimate | 8 |\n| Owner | Carol |")),
            (
                "paragraph given twice",
                self.sub(
                    "- backup: alice@example.com\n",
                    "- backup: alice@example.com\nContact: carol@example.com\n- line\n",
                ),
            ),
            (
                "table without delimiter",
                self.sub(
                    "| TomSpecField | Value |\n| --- | --- |\n| Owner | Bob |",
                    "| TomSpecField | Value |\n| Owner | Bob |",
                ),
            ),
            ("records column", self.sub("| Id | Title | Note |", "| Id | Title | Nte |")),
            (
                "records row",
                self.sub(
                    "| <a id=\"CARD-2\"></a>CARD-2 |  | second card |",
                    "| <a id=\"CARD-2\"></a>CARD-2 | second card |",
                ),
            ),
            ("unclosed records fence", self.sub("| second card |\n:::\n", "| second card |\n")),
            (
                "section-table row",
                self.sub(
                    "| <a id=\"DLV-1/DLR-1\"></a>DLR-LST / DLR-1 | Area | CE-NV |\n\
                     |  | Mapping | dart-tom |\n\n### <!--[DLV-2]",
                    "| <a id=\"DLV-1/DLR-1\"></a>DLR-LS / DLR-1 | Area | CE-NV |\n\
                     |  | Mapping | dart-tom |\n\n### <!--[DLV-2]",
                ),
            ),
            ("orphan text", format!("Stray text.\n\n{}", self.golden)),
            (
                "child under a value leaf",
                self.sub(
                    "high\n\n## <!--[CNT]-->",
                    "high\n\n### <!--[X]--> Child\n\nchild text\n\n## <!--[CNT]-->",
                ),
            ),
            (
                "nested unknown sections",
                format!(
                    "{}\n## <!--[NOPE]--> A\n\nA text\n\n### <!--[NOPE2]--> B\n\nB\n",
                    self.golden
                ),
            ),
        ]
    }
}

/// `reason@line` of every `rejected` div opening a line of `text`
/// (`^:{3,} {.rejected reason="R" line="N"`).
fn rejected_divs(text: &str) -> Vec<String> {
    let mut out = Vec::new();
    for line in text.lines() {
        let colons = line.bytes().take_while(|&c| c == b':').count();
        if colons < 3 {
            continue;
        }
        let Some(rest) = line[colons..].strip_prefix(" {.rejected reason=\"") else {
            continue;
        };
        let Some((reason, rest)) = rest.split_once('"') else {
            continue;
        };
        let Some(rest) = rest.strip_prefix(" line=\"") else {
            continue;
        };
        let digits: String = rest.chars().take_while(|c| c.is_ascii_digit()).collect();
        if !digits.is_empty() && rest[digits.len()..].starts_with('"') {
            out.push(format!("{}@{}", reason, digits));
        }
    }
    out
}

fn canonical(doc: &SpecDocument) -> String {
    doc.to_json().to_canonical_json()
}

fn test_every_variant(c: &mut Checker, f: &Fixture) {
    c.check(
        "a clean parse keeps nothing",
        f.parse(&f.golden).kept_content.is_empty(),
        "",
    );
    let schema =
        DocSpecsSchema::from_yaml_text("title-format: \"# <!--[DEMO]--> Demo\"\n").expect("the schema");
    for (name, markdown) in f.variants() {
        let result = f.parse(&markdown);
        c.check(&format!("{}: rejected", name), !result.rejections.is_empty(), "");
        let doc = f.kept(&markdown);
        let values: Vec<String> = doc.to_json().content.into_values().collect();
        let divs = rejected_divs(&values.join("\n"));
        let want: Vec<String> = result
            .rejections
            .iter()
            .map(|r| format!("{}@{}", r.reason, r.line))
            .collect();
        c.check(
            &format!("{}: every rejection kept", name),
            divs == want,
            &format!("{:?} != {:?}", divs, want),
        );

        let rendition = doc.to_markdown(&f.model, Some("Demo")).expect("the kept document exports");
        let again = f.parse(&rendition);
        let messages: Vec<&str> = again.rejections.iter().map(|r| r.message.as_str()).collect();
        c.check(
            &format!("{}: re-imports clean", name),
            again.rejections.is_empty(),
            &messages.join("; "),
        );
        let mut reloaded = SpecDocument::new();
        reloaded
            .apply_markdown_result(&again, true)
            .expect("rejections are allowed");
        c.check(
            &format!("{}: re-imports the same document", name),
            canonical(&reloaded) == canonical(&doc),
            "",
        );

        let reported = validate_spec_document(&f.model, &doc, &schema, Some("Demo"))
            .expect("the kept document validates")
            .iter()
            .filter(|v| v.rule == DOCSPECS_RULE_REJECTED_BLOCK)
            .count();
        c.check(
            &format!("{}: reported", name),
            reported == result.rejections.len(),
            &format!("{} != {}", reported, result.rejections.len()),
        );
    }
}

fn test_refused(c: &mut Checker, f: &Fixture) {
    let mut doc = SpecDocument::new();
    doc.set_content("DEMO/TTL", "base");
    let before = canonical(&doc);
    let unknown = format!("{}\n## <!--[NOPE]--> Not A Section\n\nText with no home.\n", f.golden);
    let refused = doc.apply_markdown_result(&f.parse(&unknown), false).is_err();
    c.check("a refused import refuses", refused, "");
    c.check(
        "a refused import never reads the kept blocks",
        canonical(&doc) == before,
        &canonical(&doc),
    );
}

fn content_of(doc: &SpecDocument, path: &str) -> String {
    doc.content(path).cloned().unwrap_or_default()
}

fn test_attributes(c: &mut Checker, f: &Fixture) {
    let variants = f.variants();
    let of = |name: &str| -> &str {
        &variants.iter().find(|(n, _)| *n == name).expect("a variant").1
    };
    let row = content_of(&f.kept(of("near-miss row")), "DEMO/DET");
    c.check(
        "near-miss row names the field",
        row.contains("reason=\"unknownField\" line=\"31\" field=\"owner\" "),
        &row,
    );
    let twice = content_of(&f.kept(of("row given twice")), "DEMO/DET");
    c.check(
        "a field given twice names the kept form",
        twice.contains("field=\"owner\" kept=\"DEMO/DET\" "),
        &twice,
    );
    let cell = content_of(&f.kept(of("section-table row")), "DEMO/DLV-LST-1/content");
    c.check(
        "a near-miss cell names the section",
        cell.contains("section=\"DLR-LST / DLR-1\" "),
        &cell,
    );
    c.check(
        "the skipped continuation row is in the block",
        cell.contains("|  | Mapping | dart-tom |"),
        &cell,
    );
}

fn test_parents(c: &mut Checker, f: &Fixture) {
    let variants = f.variants();
    let of = |name: &str| -> &str {
        &variants.iter().find(|(n, _)| *n == name).expect("a variant").1
    };
    let doc = f.kept(of("unclosed records fence"));
    c.check(
        "the list container keeps no text",
        doc.content("DEMO/CARD-LST").is_none(),
        &format!("{:?}", doc.content("DEMO/CARD-LST")),
    );
    let root = content_of(&doc, "DEMO");
    c.check("the unclosed fence is escaped", root.contains("\n\\::: {.records}\n"), &root);
    c.check("the div closes", root.trim_end().ends_with("\n:::"), &root);
    let records = content_of(&f.kept(of("records column")), "DEMO");
    c.check(
        "a records div is kept in the parent",
        records.starts_with(":::: {.rejected reason=\"unknownField\""),
        &records,
    );
    c.check("its own div stays inside", records.contains("\n::: {.records}\n"), &records);
}

fn test_place(c: &mut Checker, f: &Fixture) {
    let variants = f.variants();
    let of = |name: &str| -> &str {
        &variants.iter().find(|(n, _)| *n == name).expect("a variant").1
    };
    let doc = f.kept(of("paragraph given twice"));
    c.check(
        "the first value is kept",
        doc.form_field("DEMO/DET", "contact")
            .is_some_and(|v| v.starts_with("bob@example.com")),
        "",
    );
    let want = "Captured during the November review.\n\
                Owner: this line is prose, not the field.\n\n\
                ::: {.rejected reason=\"malformedBlock\" line=\"35\" field=\"contact\" \
                kept=\"DEMO/DET\" label=\"field 'contact' given twice\"}\n\
                Contact: carol@example.com\n- line\n:::";
    let got = content_of(&doc, "DEMO/DET");
    c.check(
        "a paragraph given twice is kept at its place",
        got == want,
        &format!("\n--- got\n{}\n--- want\n{}", got, want),
    );
    let orphan = content_of(&f.kept(of("orphan text")), "DEMO");
    c.check(
        "orphan text starts the root",
        orphan.starts_with("::: {.rejected reason=\"orphanContent\" line=\"1\""),
        &orphan,
    );
}

#[test]
fn rejected_blocks_kept_for_review() {
    let f = Fixture::load();
    let mut c = Checker {
        passed: 0,
        failed: Vec::new(),
    };
    test_every_variant(&mut c, &f);
    test_refused(&mut c, &f);
    test_attributes(&mut c, &f);
    test_parents(&mut c, &f);
    test_place(&mut c, &f);
    let total = c.passed + c.failed.len();
    for failure in &c.failed {
        eprintln!("  - {}", failure);
    }
    assert!(c.failed.is_empty(), "{}/{} checks failed", c.failed.len(), total);
    println!("OK: {} checks passed", total);
}
