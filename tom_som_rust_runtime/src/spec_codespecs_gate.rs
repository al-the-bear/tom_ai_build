//! `spec_codespecs_gate` — the Phase-4 mechanical gate, Stage A of
//! `codespecs_prompt.md` §4: all five checks run as one, over (model, document,
//! catalogue, schema). A faithful port of the Dart `spec_codespecs_gate.dart`.
//!
//! Every check runs; none stops the others. A project fixing one wants to see
//! the rest, and a gate that stopped at the first failure would report a
//! different set of problems on every run. So [`CodeSpecsGate::run`] returns
//! the report rather than a `Result`: a failing check is a finding, never an
//! early return.
//!
//! A check that could not run is reported as **not run**, with its reason, and
//! the gate does not pass: a skipped check must never read as a passed one.

use std::collections::HashSet;
use std::fmt;

use crate::docspecs_validator::{DocSpecsSchema, DocSpecsValidator};
use crate::spec_codespecs_extract::{
    CodeSpecsAreaCatalog, CodeSpecsExtract, CodeSpecsExtractEntry, CodeSpecsExtractor,
    CodeSpecsRoutingVerdict,
};
use crate::spec_document::SpecDocument;
use crate::spec_model::SpecModel;
use crate::spec_validator::validate_document;

const NO_TABLES: &str = "the catalogue carries no gate tables (written before \
     `codespecs_prompt.md` §4.4/§4.5 were transcribed)";

/// The five Stage-A checks.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum CodeSpecsGateCheck {
    /// The document is complete against its DocSpecs schema.
    A1,

    /// The document's values are valid (`validate_document`).
    A2,

    /// Every section the walk reaches carries a routing verdict (ROUTE-TOTAL).
    A3,

    /// Every required marker argument of a used area has a populated source.
    A4,

    /// The model still offers every structured carrier.
    A5,
}

impl CodeSpecsGateCheck {
    /// `A1` … `A5`, as `codespecs_prompt.md` §4 names them.
    pub fn label(&self) -> &'static str {
        match self {
            CodeSpecsGateCheck::A1 => "A1",
            CodeSpecsGateCheck::A2 => "A2",
            CodeSpecsGateCheck::A3 => "A3",
            CodeSpecsGateCheck::A4 => "A4",
            CodeSpecsGateCheck::A5 => "A5",
        }
    }
}

impl fmt::Display for CodeSpecsGateCheck {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.label())
    }
}

/// One thing a check found wrong.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CodeSpecsGateFinding {
    /// The check that found it.
    pub check: CodeSpecsGateCheck,

    /// What kind of finding — the DocSpecs rule (A1), the validation code (A2),
    /// `unrouted` / `root` (A3), `missingSource` / `unresolvedReference` (A4),
    /// `missingCarrier` (A5).
    pub code: String,

    /// Where: a section id or document path (A1–A4), or the carrier
    /// `Class.member[.formField]` (A5).
    pub location: String,

    /// One sentence a user acts on.
    pub message: String,
}

impl CodeSpecsGateFinding {
    fn new(check: CodeSpecsGateCheck, code: &str, location: &str, message: String) -> Self {
        CodeSpecsGateFinding {
            check,
            code: code.to_string(),
            location: location.to_string(),
            message,
        }
    }
}

impl fmt::Display for CodeSpecsGateFinding {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "{} {} {}: {}",
            self.check.label(),
            self.code,
            self.location,
            self.message
        )
    }
}

/// One check's outcome.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CodeSpecsGateCheckResult {
    /// Which check.
    pub check: CodeSpecsGateCheck,

    /// Whether it ran. A check that did not run never passes.
    pub ran: bool,

    /// Why it did not run; `None` when it ran.
    pub not_run_reason: Option<String>,

    /// What it found, in the order found.
    pub findings: Vec<CodeSpecsGateFinding>,
}

impl CodeSpecsGateCheckResult {
    /// A check that ran, with what it found.
    pub fn ran(check: CodeSpecsGateCheck, findings: Vec<CodeSpecsGateFinding>) -> Self {
        CodeSpecsGateCheckResult {
            check,
            ran: true,
            not_run_reason: None,
            findings,
        }
    }

    /// A check that did not run, and why.
    pub fn not_run(check: CodeSpecsGateCheck, reason: &str) -> Self {
        CodeSpecsGateCheckResult {
            check,
            ran: false,
            not_run_reason: Some(reason.to_string()),
            findings: Vec::new(),
        }
    }

    /// Ran and found nothing.
    pub fn passed(&self) -> bool {
        self.ran && self.findings.is_empty()
    }
}

/// The gate's report: one result per check, A1 to A5.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CodeSpecsGateReport {
    /// The five results, in check order.
    pub results: Vec<CodeSpecsGateCheckResult>,

    /// The extraction run's extracts, when A3 passed (A4 reads them; Stage B
    /// is handed them). `None` when the walk could not complete.
    pub extracts: Option<Vec<CodeSpecsExtract>>,
}

impl CodeSpecsGateReport {
    /// The result of `check`, or `None` when the report carries none (a report
    /// [`CodeSpecsGate::run`] built always carries all five).
    pub fn get(&self, check: CodeSpecsGateCheck) -> Option<&CodeSpecsGateCheckResult> {
        self.results.iter().find(|r| r.check == check)
    }

    /// Every check ran and found nothing — the run may begin.
    pub fn passed(&self) -> bool {
        self.results.iter().all(|r| r.passed())
    }

    /// Every finding, in check order.
    pub fn findings(&self) -> Vec<&CodeSpecsGateFinding> {
        self.results.iter().flat_map(|r| r.findings.iter()).collect()
    }
}

/// Stage A of `codespecs_prompt.md` §4.
pub struct CodeSpecsGate<'a> {
    /// The resolved object model.
    pub model: &'a SpecModel,

    /// The document under Phase 4.
    pub document: &'a SpecDocument,

    /// The area catalogue — its `gate` tables drive A4 and A5.
    pub catalog: &'a CodeSpecsAreaCatalog,

    /// The DocSpecs schema of the document's root; A1 does not run without it.
    pub schema: Option<&'a DocSpecsSchema>,

    /// The document root to walk — type name or section id; `None` means the
    /// document's single populated root, as the extractor does.
    pub root_type: Option<&'a str>,
}

impl<'a> CodeSpecsGate<'a> {
    /// Holds the inputs; [`Self::run`] does the work.
    pub fn new(
        model: &'a SpecModel,
        document: &'a SpecDocument,
        catalog: &'a CodeSpecsAreaCatalog,
        schema: Option<&'a DocSpecsSchema>,
        root_type: Option<&'a str>,
    ) -> CodeSpecsGate<'a> {
        CodeSpecsGate {
            model,
            document,
            catalog,
            schema,
            root_type,
        }
    }

    /// Runs all five checks. Never fails: every problem is a finding or a
    /// not-run reason in the report.
    pub fn run(&self) -> CodeSpecsGateReport {
        let a1 = self.a1();
        let a2 = self.a2();
        let (a3, extracts) = self.a3();
        let a4 = if !self.catalog.has_gate_tables {
            CodeSpecsGateCheckResult::not_run(CodeSpecsGateCheck::A4, NO_TABLES)
        } else {
            match &extracts {
                None => CodeSpecsGateCheckResult::not_run(
                    CodeSpecsGateCheck::A4,
                    "A3 did not complete, so there is no extraction run to read \
                     the used areas from",
                ),
                Some(x) => self.a4(x),
            }
        };
        let a5 = if self.catalog.has_gate_tables {
            self.a5()
        } else {
            CodeSpecsGateCheckResult::not_run(CodeSpecsGateCheck::A5, NO_TABLES)
        };
        CodeSpecsGateReport {
            results: vec![a1, a2, a3, a4, a5],
            extracts,
        }
    }

    fn a1(&self) -> CodeSpecsGateCheckResult {
        let Some(schema) = self.schema else {
            return CodeSpecsGateCheckResult::not_run(
                CodeSpecsGateCheck::A1,
                "no DocSpecs schema was supplied",
            );
        };
        // Dart's `toMarkdown` throws when the root cannot be resolved; Rust's
        // returns `Err`. The gate never fails fast, so A1 reports it as not run.
        let markdown = match self.document.to_markdown(self.model, self.root_type) {
            Ok(m) => m,
            Err(e) => {
                return CodeSpecsGateCheckResult::not_run(
                    CodeSpecsGateCheck::A1,
                    &format!("the document could not be rendered to Markdown: {}", e),
                )
            }
        };
        let validator = DocSpecsValidator::new(schema.clone());
        let findings = validator
            .validate_markdown(&markdown)
            .into_iter()
            .map(|v| {
                let location = if !v.section_id.is_empty() {
                    v.section_id.clone()
                } else if !v.path.is_empty() {
                    v.path.clone()
                } else {
                    format!("line {}", v.line)
                };
                CodeSpecsGateFinding::new(
                    CodeSpecsGateCheck::A1,
                    &v.rule,
                    &location,
                    format!("line {}: {}", v.line, v.message),
                )
            })
            .collect();
        CodeSpecsGateCheckResult::ran(CodeSpecsGateCheck::A1, findings)
    }

    fn a2(&self) -> CodeSpecsGateCheckResult {
        let findings = validate_document(self.model, self.document)
            .into_iter()
            .map(|e| CodeSpecsGateFinding::new(CodeSpecsGateCheck::A2, &e.code, &e.path, e.message))
            .collect();
        CodeSpecsGateCheckResult::ran(CodeSpecsGateCheck::A2, findings)
    }

    /// A3 collects **every** unrouted class over the non-strict walk, rather
    /// than the first one the strict walk fails on; only when there is none
    /// does it run the extraction itself.
    fn a3(&self) -> (CodeSpecsGateCheckResult, Option<Vec<CodeSpecsExtract>>) {
        let extractor = match CodeSpecsExtractor::for_model(
            self.document,
            self.model,
            self.catalog.clone(),
            self.root_type,
        ) {
            Ok(x) => x,
            Err(e) => {
                let finding =
                    CodeSpecsGateFinding::new(CodeSpecsGateCheck::A3, "root", &e.path, e.message);
                return (
                    CodeSpecsGateCheckResult::ran(CodeSpecsGateCheck::A3, vec![finding]),
                    None,
                );
            }
        };
        let unrouted: Vec<CodeSpecsGateFinding> = extractor
            .routings()
            .into_iter()
            .filter(|r| r.verdict == CodeSpecsRoutingVerdict::Unrouted)
            .map(|r| {
                CodeSpecsGateFinding::new(
                    CodeSpecsGateCheck::A3,
                    "unrouted",
                    &r.path,
                    format!(
                        "{} carries no @CodeSpecKind, @FollowUpKind or \
                         @NoArtifact — its content would reach no extract",
                        r.class_name
                    ),
                )
            })
            .collect();
        if !unrouted.is_empty() {
            return (
                CodeSpecsGateCheckResult::ran(CodeSpecsGateCheck::A3, unrouted),
                None,
            );
        }
        match extractor.extract_all() {
            Ok(extracts) => (
                CodeSpecsGateCheckResult::ran(CodeSpecsGateCheck::A3, Vec::new()),
                Some(extracts),
            ),
            // Unreachable while `routings()` and `extract_all()` share one walk
            // (the unrouted verdict is the only error the strict walk raises);
            // reported rather than unwrapped so the gate still never fails fast.
            Err(e) => {
                let finding = CodeSpecsGateFinding::new(
                    CodeSpecsGateCheck::A3,
                    "unrouted",
                    &e.path,
                    e.message,
                );
                (
                    CodeSpecsGateCheckResult::ran(CodeSpecsGateCheck::A3, vec![finding]),
                    None,
                )
            }
        }
    }

    /// A4 over the extraction run: for each obligation whose area's extract is
    /// non-empty, every instance of the obligation's class that the extract
    /// carries must carry the source value, populated (non-blank); a
    /// `resolves_to` obligation's value must also equal a value the run carries
    /// at the target.
    fn a4(&self, extracts: &[CodeSpecsExtract]) -> CodeSpecsGateCheckResult {
        let mut findings = Vec::new();
        let all: Vec<&CodeSpecsExtractEntry> = extracts.iter().flat_map(|x| &x.entries).collect();
        for o in &self.catalog.required_arguments {
            let Some(extract) = extracts.iter().find(|x| x.area.code == o.area) else {
                continue;
            };
            if extract.entries.is_empty() {
                continue;
            }
            // The instances the extract carries of the obligation's class, in
            // document order, each with the populated source value it holds.
            let mut instances: Vec<(String, Option<String>)> = Vec::new();
            let mut applies: HashSet<String> = HashSet::new();
            let when = o.when.as_ref();
            for e in &extract.entries {
                if e.class_name != o.class_name() {
                    continue;
                }
                let instance = parent_path(&e.path);
                let slot = match instances.iter().position(|(k, _)| *k == instance) {
                    Some(i) => i,
                    None => {
                        instances.push((instance.clone(), None));
                        instances.len() - 1
                    }
                };
                if let Some(w) = when {
                    if e.field_name == w.member
                        && e.form_field == w.form_field
                        && Some(&e.value) == o.when_equals.as_ref()
                    {
                        applies.insert(instance.clone());
                    }
                }
                if e.field_name == o.member()
                    && e.form_field.as_deref() == o.form_field()
                    && !e.value.trim().is_empty()
                {
                    instances[slot].1 = Some(e.value.clone());
                }
            }
            for (instance, value) in &instances {
                if when.is_some() && !applies.contains(instance) {
                    continue;
                }
                let Some(value) = value else {
                    findings.push(CodeSpecsGateFinding::new(
                        CodeSpecsGateCheck::A4,
                        "missingSource",
                        instance,
                        format!(
                            "{}.{} ({}) is required, and its source {} is empty here",
                            o.marker,
                            o.argument,
                            o.area,
                            o.source()
                        ),
                    ));
                    continue;
                };
                let Some(target) = &o.resolves_to else {
                    continue;
                };
                let known = all.iter().any(|e| {
                    e.class_name == target.class_name
                        && e.field_name == target.member
                        && e.form_field == target.form_field
                        && e.value == *value
                });
                if !known {
                    findings.push(CodeSpecsGateFinding::new(
                        CodeSpecsGateCheck::A4,
                        "unresolvedReference",
                        instance,
                        format!(
                            "{} names `{}`, which no {} in this document carries — \
                             {}.{} ({}) has nothing to resolve against",
                            o.source(),
                            value,
                            target.source(),
                            o.marker,
                            o.argument,
                            o.area
                        ),
                    ));
                }
            }
        }
        CodeSpecsGateCheckResult::ran(CodeSpecsGateCheck::A4, findings)
    }

    /// A5 against the model, not the document: each carrier's class, member and
    /// form field must still exist.
    fn a5(&self) -> CodeSpecsGateCheckResult {
        let mut findings = Vec::new();
        for c in &self.catalog.carriers {
            let field = self
                .model
                .class_named(c.class_name())
                .and_then(|cls| cls.field_named(c.member()));
            let present = match field {
                None => false,
                Some(f) => match c.form_field() {
                    None => true,
                    Some(ff) => f.form_fields.iter().any(|x| x.name == ff),
                },
            };
            if !present {
                findings.push(CodeSpecsGateFinding::new(
                    CodeSpecsGateCheck::A5,
                    "missingCarrier",
                    &c.source(),
                    format!(
                        "the model no longer offers {} ({}) — a project with that \
                         structured fact would have to write prose again",
                        c.source(),
                        c.introduced_by
                    ),
                ));
            }
        }
        CodeSpecsGateCheckResult::ran(CodeSpecsGateCheck::A5, findings)
    }
}

fn parent_path(path: &str) -> String {
    match path.rfind('/') {
        Some(i) => path[..i].to_string(),
        None => String::new(),
    }
}
