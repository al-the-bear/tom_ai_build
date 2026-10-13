//! `spec_codespecs_records` — reading back what a Phase-4 run wrote: the
//! per-area **extract** files and the Stage-B **gate record**
//! (`codespecs_mapping.md` §1.1.1, `codespecs_prompt.md` §6.3), a faithful port
//! of the Dart `spec_codespecs_records.dart`.
//!
//! The extractor ([`CodeSpecsExtractor`](crate::CodeSpecsExtractor)) writes
//! `<CE-CODE>.extract.yaml`; this module is the other half, so a consumer that
//! did not run the extractor — a validator, an editor tool, an agent asking
//! which areas are in scope — reads the files with the same rules everywhere
//! instead of re-deriving the shape. The gate record has a writer here too,
//! because it is otherwise written by hand and only checked when something
//! reads it.
//!
//! Both readers **refuse** an unknown `formatVersion`: a later format that
//! moved a key would otherwise read as an extract with no entries, or a scope
//! with no verdicts, and a check with no input passes.
//!
//! Rust has no exceptions, so where the Dart reference *throws*
//! `CodeSpecsRecordError` this port returns `Result<_, CodeSpecsRecordError>`.
//! The YAML is read by the crate's own dependency-free reader in raw-scalar
//! mode ([`yaml_parse_raw_scalars`]), and the scalars are typed here — that is
//! what lets `headline: null` and `headline: "null"` read differently. The
//! reader yields an empty mapping for a bare `key:`, so an empty mapping where
//! a scalar or a list is expected reads as absent.

use std::fmt;
use std::path::Path;

use crate::json::Json;
use crate::spec_codespecs_extract::{
    yaml_string, CodeSpecsArea, CodeSpecsAreaCatalog, CodeSpecsExtract, CodeSpecsExtractEntry,
    CODE_SPECS_EXTRACT_FORMAT,
};
use crate::yaml::{yaml_parse_raw_scalars, YamlValue};

/// The file name of the gate record, written beside the extracts.
///
/// Fixed so a partial pass cannot hide its record under a name no reader
/// looks for.
pub const CODE_SPECS_GATE_RECORD_FILE: &str = "gate.verdicts.yaml";

/// The gate record `formatVersion` this runtime reads and writes.
pub const CODE_SPECS_GATE_RECORD_FORMAT: i64 = 1;

/// The suffix every extract artifact of record carries.
pub const CODE_SPECS_EXTRACT_FILE_SUFFIX: &str = ".extract.yaml";

/// The one resolution a gate record may carry: an insufficient area the user
/// decided to leave out.
pub const CODE_SPECS_GATE_DESCOPED: &str = "descoped";

/// A malformed or unreadable extract file or gate record.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CodeSpecsRecordError {
    /// What is wrong, naming the file it was read from.
    pub message: String,
}

impl CodeSpecsRecordError {
    fn new(message: String) -> CodeSpecsRecordError {
        CodeSpecsRecordError { message }
    }
}

impl fmt::Display for CodeSpecsRecordError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "CodeSpecsRecordError: {}", self.message)
    }
}

impl std::error::Error for CodeSpecsRecordError {}

type RecordResult<T> = Result<T, CodeSpecsRecordError>;

fn err<T>(message: String) -> RecordResult<T> {
    Err(CodeSpecsRecordError::new(message))
}

// ---------------------------------------------------------------------------
// Extract files
// ---------------------------------------------------------------------------

/// Parses one `<CE-CODE>.extract.yaml`. `source` names the file in errors (an
/// empty `source` reads as "the extract").
///
/// Only `extract.formatVersion` and `extract.area.code` are required; any
/// other absent key reads as empty (a string as `""`, a list as empty, the
/// optional entry fields as `None`), so a hand-written fixture stays readable.
/// A key that is present with the wrong type is an error, and so is a
/// `document.entryCount` that disagrees with the entries — a truncated file
/// would otherwise read as a complete one.
///
/// The inverse of [`CodeSpecsExtract::to_yaml`]: for any extract the extractor
/// wrote, parsing `x.to_yaml()` and writing it again gives the same bytes.
pub fn parse_code_specs_extract_yaml(text: &str, source: &str) -> RecordResult<CodeSpecsExtract> {
    let name = if source.is_empty() {
        "the extract"
    } else {
        source
    };
    let root = root_mapping(text, name, "extract")?;
    let version = map_get(&root, "formatVersion");
    if !matches!(version, Some(RecVal::Int(n)) if *n == CODE_SPECS_EXTRACT_FORMAT) {
        return err(format!(
            "{} declares extract format {}; this reader understands {} only — reading it \
             would silently drop entries",
            name,
            display(version),
            CODE_SPECS_EXTRACT_FORMAT
        ));
    }
    let area = match map_get(&root, "area") {
        Some(RecVal::Map(m)) => m,
        _ => return err(format!("{} has no `area:` mapping", name)),
    };
    let code = req_str(map_get(area, "code"), name, "area.code")?;
    if code.is_empty() {
        return err(format!("{} names no area code", name));
    }
    let mut part = req_str(map_get(area, "part"), name, "area.part")?;
    if let Some(stripped) = part.strip_prefix("CodeSpecPart.") {
        part = stripped.to_string();
    }
    let document = match present(map_get(&root, "document")) {
        None => None,
        Some(RecVal::Map(m)) => Some(m),
        Some(_) => return err(format!("{}: `document` must be a mapping", name)),
    };
    let raw_entries: &[RecVal] = match present(map_get(&root, "entries")) {
        None => &[],
        Some(RecVal::List(items)) => items,
        Some(_) => return err(format!("{}: `entries` must be a list", name)),
    };
    let mut entries = Vec::with_capacity(raw_entries.len());
    for raw in raw_entries {
        let e = match raw {
            RecVal::Map(m) => m,
            _ => return err(format!("{} has an entry that is not a mapping", name)),
        };
        let req = |key: &str| req_str(map_get(e, key), name, &format!("entries[].{}", key));
        let opt = |key: &str| opt_str(map_get(e, key), name, &format!("entries[].{}", key));
        entries.push(CodeSpecsExtractEntry {
            area_code: code.clone(),
            section_id: req("sectionId")?,
            headline: opt("headline")?,
            instance_id: opt("instanceId")?,
            path: req("path")?,
            class_name: req("className")?,
            field_name: req("fieldName")?,
            form_field: opt("formField")?,
            routed_by: req("routedBy")?,
            routed_at: req("routedAt")?,
            routing_note: opt("routingNote")?,
            value: req("value")?,
        });
    }
    let declared = document.and_then(|d| map_get(d, "entryCount"));
    if let Some(declared) = declared {
        if !matches!(declared, RecVal::Int(n) if *n == entries.len() as i64) {
            return err(format!(
                "{} declares entryCount {} but carries {} entries — a truncated extract must \
                 not read as a complete one",
                name,
                display(Some(declared)),
                entries.len()
            ));
        }
    }
    Ok(CodeSpecsExtract {
        area: CodeSpecsArea {
            code,
            canonical_id: req_str(map_get(area, "canonicalId"), name, "area.canonicalId")?,
            part,
            annotations: str_list(map_get(area, "annotations"), name, "area.annotations")?,
            built_on: req_str(map_get(area, "builtOn"), name, "area.builtOn")?,
            attribute_surface: req_str(
                map_get(area, "attributeSurface"),
                name,
                "area.attributeSurface",
            )?,
            slices: int_list(map_get(area, "slices"), name, "area.slices")?,
            authoring_steps: int_list(
                map_get(area, "authoringSteps"),
                name,
                "area.authoringSteps",
            )?,
            active: true,
        },
        catalog_source: req_str(map_get(&root, "catalogSource"), name, "catalogSource")?,
        document_root: req_str(
            document.and_then(|d| map_get(d, "root")),
            name,
            "document.root",
        )?,
        citable_parts: str_list(map_get(area, "citableParts"), name, "area.citableParts")?,
        projects: str_list(map_get(area, "projects"), name, "area.projects")?,
        entries,
    })
}

impl CodeSpecsExtract {
    /// Reads an extract back from its artifact of record — the inverse of
    /// [`CodeSpecsExtract::to_yaml`]. `source` names the file in errors. Fails
    /// on an unknown `formatVersion` or a malformed file; see
    /// [`parse_code_specs_extract_yaml`].
    pub fn from_yaml(text: &str, source: &str) -> RecordResult<CodeSpecsExtract> {
        parse_code_specs_extract_yaml(text, source)
    }
}

// ---------------------------------------------------------------------------
// The gate record
// ---------------------------------------------------------------------------

/// One of `codespecs_prompt.md` §6.2's three per-area verdicts.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum CodeSpecsGateVerdict {
    /// The extract carries every input the derivation contract requires.
    Sufficient,

    /// The area does not apply — nothing was routed, with positive evidence of
    /// absence (`codespecs_prompt.md` §6.4).
    NotApplicable,

    /// The extract is missing required inputs; only a recorded descope lets a
    /// run continue without the area.
    Insufficient,
}

impl CodeSpecsGateVerdict {
    /// The verdict word exactly as `codespecs_prompt.md` §6.2 states it.
    pub fn word(&self) -> &'static str {
        match self {
            CodeSpecsGateVerdict::Sufficient => "sufficient",
            CodeSpecsGateVerdict::NotApplicable => "not applicable",
            CodeSpecsGateVerdict::Insufficient => "insufficient",
        }
    }

    /// The verdict for `word`, or `None` for a word §6.2 does not know.
    pub fn parse(word: &str) -> Option<CodeSpecsGateVerdict> {
        match word {
            "sufficient" => Some(CodeSpecsGateVerdict::Sufficient),
            "not applicable" => Some(CodeSpecsGateVerdict::NotApplicable),
            "insufficient" => Some(CodeSpecsGateVerdict::Insufficient),
            _ => None,
        }
    }
}

/// One area's recorded verdict.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CodeSpecsGateEntry {
    /// The area's `CE-*` code.
    pub area: String,

    /// The verdict.
    pub verdict: CodeSpecsGateVerdict,

    /// `descoped`, on an insufficient area only; otherwise `None`.
    pub resolution: Option<String>,

    /// A free-text note — why the verdict was taken. Never read as data.
    pub note: Option<String>,
}

impl CodeSpecsGateEntry {
    /// An entry with no resolution and no note. Shape is checked by
    /// [`CodeSpecsGateRecord`], which is the only thing that reads or writes
    /// entries.
    pub fn new(area: &str, verdict: CodeSpecsGateVerdict) -> CodeSpecsGateEntry {
        CodeSpecsGateEntry {
            area: area.to_string(),
            verdict,
            resolution: None,
            note: None,
        }
    }

    /// Whether this is an insufficient area resolved by descoping.
    pub fn descoped(&self) -> bool {
        self.resolution.as_deref() == Some(CODE_SPECS_GATE_DESCOPED)
    }
}

/// The Stage-B gate record, `gate.verdicts.yaml` (`codespecs_prompt.md` §6.3).
///
/// Constructing one checks it: every area is a `CE-*` code named once, and a
/// `resolution:` appears only as `descoped` on an insufficient area. So a
/// record that exists is a record of the checked shape, whether it was read
/// or built to be written — which is why the verdicts are read through
/// [`CodeSpecsGateRecord::verdicts`] rather than a public field.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CodeSpecsGateRecord {
    verdicts: Vec<CodeSpecsGateEntry>,
}

impl CodeSpecsGateRecord {
    /// Creates and checks a record; fails on a shape `codespecs_prompt.md` §6.3
    /// does not allow. Errors name the record `gate.verdicts.yaml`.
    pub fn new(verdicts: Vec<CodeSpecsGateEntry>) -> RecordResult<CodeSpecsGateRecord> {
        CodeSpecsGateRecord::new_with_source(verdicts, CODE_SPECS_GATE_RECORD_FILE)
    }

    /// As [`CodeSpecsGateRecord::new`]; `source` names the record in errors.
    pub fn new_with_source(
        verdicts: Vec<CodeSpecsGateEntry>,
        source: &str,
    ) -> RecordResult<CodeSpecsGateRecord> {
        let record = CodeSpecsGateRecord { verdicts };
        record.check(source)?;
        Ok(record)
    }

    /// Parses `gate.verdicts.yaml`. `source` names the file in errors; an empty
    /// `source` reads as `gate.verdicts.yaml`.
    pub fn from_yaml(text: &str, source: &str) -> RecordResult<CodeSpecsGateRecord> {
        let source = if source.is_empty() {
            CODE_SPECS_GATE_RECORD_FILE
        } else {
            source
        };
        let root = root_mapping(text, source, "gate")?;
        for (key, _) in &root {
            if key != "formatVersion" && key != "verdicts" {
                return err(format!(
                    "{} has an unknown key `gate.{}` — the record knows `formatVersion` and \
                     `verdicts` only",
                    source, key
                ));
            }
        }
        let version = map_get(&root, "formatVersion");
        if !matches!(version, Some(RecVal::Int(n)) if *n == CODE_SPECS_GATE_RECORD_FORMAT) {
            return err(format!(
                "{} declares gate record format {}; this reader understands {} only — reading \
                 it would silently change the scope",
                source,
                display(version),
                CODE_SPECS_GATE_RECORD_FORMAT
            ));
        }
        let list = match map_get(&root, "verdicts") {
            Some(RecVal::List(items)) => items,
            _ => return err(format!("{} has no `verdicts:` list", source)),
        };
        let mut entries = Vec::with_capacity(list.len());
        for raw in list {
            let raw = match raw {
                RecVal::Map(m) => m,
                _ => return err(format!("{} has a verdict that is not a mapping", source)),
            };
            for (key, _) in raw {
                if !["area", "verdict", "resolution", "note"].contains(&key.as_str()) {
                    return err(format!(
                        "{} has an unknown key `{}` in a verdict — an entry knows `area`, \
                         `verdict`, `resolution` and `note` only",
                        source, key
                    ));
                }
            }
            let area = req_str(map_get(raw, "area"), source, "verdicts[].area")?;
            let word = req_str(map_get(raw, "verdict"), source, "verdicts[].verdict")?;
            let verdict = match CodeSpecsGateVerdict::parse(&word) {
                Some(v) => v,
                None => {
                    return err(format!(
                        "{} gives {} the verdict `{}` — codespecs_prompt.md §6.2 knows \
                         `sufficient`, `not applicable` and `insufficient` only",
                        source, area, word
                    ))
                }
            };
            entries.push(CodeSpecsGateEntry {
                area,
                verdict,
                resolution: opt_str(map_get(raw, "resolution"), source, "verdicts[].resolution")?,
                note: opt_str(map_get(raw, "note"), source, "verdicts[].note")?,
            });
        }
        CodeSpecsGateRecord::new_with_source(entries, source)
    }

    fn check(&self, source: &str) -> RecordResult<()> {
        let mut seen: Vec<&str> = Vec::new();
        for e in &self.verdicts {
            if e.area.is_empty() {
                return err(format!("{} has a verdict that names no area", source));
            }
            if !is_area_code(&e.area) {
                return err(format!(
                    "{} names the area `{}`, which is not a CE-* code",
                    source, e.area
                ));
            }
            if seen.contains(&e.area.as_str()) {
                return err(format!(
                    "{} carries two verdicts for {} — a scope with two answers for one area \
                     is no scope",
                    source, e.area
                ));
            }
            seen.push(&e.area);
            let resolution = match &e.resolution {
                None => continue,
                Some(r) => r,
            };
            if e.verdict != CodeSpecsGateVerdict::Insufficient {
                return err(format!(
                    "{} gives {} a `resolution:` on verdict `{}` — only an insufficient area \
                     has an L0 decision to resolve",
                    source,
                    e.area,
                    e.verdict.word()
                ));
            }
            if resolution != CODE_SPECS_GATE_DESCOPED {
                return err(format!(
                    "{} gives {} the resolution `{}` — `descoped` is the one resolution that \
                     admits a partial pass; any other resolution means the area was completed \
                     and its verdict re-taken",
                    source, e.area, resolution
                ));
            }
        }
        Ok(())
    }

    /// The verdicts, in the order they were recorded.
    pub fn verdicts(&self) -> &[CodeSpecsGateEntry] {
        &self.verdicts
    }

    /// The entry for `area`, or `None` when the record says nothing about it.
    pub fn verdict_for(&self, area: &str) -> Option<&CodeSpecsGateEntry> {
        self.verdicts.iter().find(|e| e.area == area)
    }

    /// Fails when an area is not an active area of `catalog` — a verdict for an
    /// area that does not exist scopes nothing. Errors name the record
    /// `gate.verdicts.yaml`.
    pub fn check_against(&self, catalog: &CodeSpecsAreaCatalog) -> RecordResult<()> {
        self.check_against_with_source(catalog, CODE_SPECS_GATE_RECORD_FILE)
    }

    /// As [`CodeSpecsGateRecord::check_against`]; `source` names the record.
    pub fn check_against_with_source(
        &self,
        catalog: &CodeSpecsAreaCatalog,
        source: &str,
    ) -> RecordResult<()> {
        for e in &self.verdicts {
            match catalog.by_code(&e.area) {
                Some(area) if area.active => {}
                _ => {
                    return err(format!(
                        "{} gives a verdict for {}, which is not an active area of the \
                         catalogue",
                        source, e.area
                    ))
                }
            }
        }
        Ok(())
    }

    /// A copy with `entry` recorded — replacing the area's earlier verdict in
    /// place, or appended when the area had none. Fails when the result is not
    /// a record of the checked shape.
    pub fn with_verdict(&self, entry: CodeSpecsGateEntry) -> RecordResult<CodeSpecsGateRecord> {
        let mut out = Vec::with_capacity(self.verdicts.len() + 1);
        let mut entry = Some(entry);
        for e in &self.verdicts {
            match &entry {
                Some(new) if new.area == e.area => out.push(entry.take().unwrap()),
                _ => out.push(e.clone()),
            }
        }
        if let Some(new) = entry {
            out.push(new);
        }
        CodeSpecsGateRecord::new(out)
    }

    /// The record as `gate.verdicts.yaml`. Byte-stable: the same record always
    /// writes the same text, and reading it back and writing it again gives the
    /// same bytes.
    ///
    /// `area` and `verdict` are written plain, as `codespecs_prompt.md` §6.3
    /// shows them — both are from a closed vocabulary the constructor checked —
    /// and a note as a double-quoted scalar, the extract's one escaping rule.
    pub fn to_yaml(&self) -> String {
        let mut b = String::new();
        b.push_str("gate:\n");
        b.push_str(&format!(
            "  formatVersion: {}\n",
            CODE_SPECS_GATE_RECORD_FORMAT
        ));
        if self.verdicts.is_empty() {
            b.push_str("  verdicts: []\n");
            return b;
        }
        b.push_str("  verdicts:\n");
        for e in &self.verdicts {
            b.push_str(&format!("    - area: {}\n", e.area));
            b.push_str(&format!("      verdict: {}\n", e.verdict.word()));
            if let Some(r) = &e.resolution {
                b.push_str(&format!("      resolution: {}\n", r));
            }
            if let Some(n) = &e.note {
                b.push_str(&format!("      note: {}\n", yaml_string(n)));
            }
        }
        b
    }
}

/// `^CE-[A-Z]+$`.
fn is_area_code(s: &str) -> bool {
    match s.strip_prefix("CE-") {
        Some(rest) => !rest.is_empty() && rest.bytes().all(|b| b.is_ascii_uppercase()),
        None => false,
    }
}

// ---------------------------------------------------------------------------
// A tree of extracts, scoped by its gate record
// ---------------------------------------------------------------------------

/// One area the gate record left out of scope.
///
/// Kept visible rather than dropped, so a consumer can say so: a scoped-out
/// area must never read as a covered one.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CodeSpecsExcludedArea {
    /// The `CE-*` code.
    pub area: String,

    /// `NotApplicable`, or `Insufficient` with a recorded descope.
    pub verdict: CodeSpecsGateVerdict,

    /// Whether an insufficient verdict was resolved by descoping.
    pub descoped: bool,

    /// How many routed entries the excluded extract carried (0 with no file).
    pub entry_count: usize,

    /// The file the excluded extract was read from, or `""` when there was none.
    pub source: String,
}

/// Every extract one run produced, read back and scoped by its gate record.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CodeSpecsExtractSet {
    /// The in-scope extracts. With a gate record: the areas it marks
    /// `sufficient`, in the record's order. Without: every extract, in source
    /// order.
    pub extracts: Vec<CodeSpecsExtract>,

    /// The file each in-scope extract was read from, parallel to `extracts`.
    pub sources: Vec<String>,

    /// The areas the gate record excluded — empty without a record.
    pub excluded: Vec<CodeSpecsExcludedArea>,

    /// The gate record, when one was among the sources.
    pub gate: Option<CodeSpecsGateRecord>,
}

impl CodeSpecsExtractSet {
    /// Reads `files` — an ordered sequence of (file name, text) — into a scoped
    /// set.
    ///
    /// The file whose basename is [`CODE_SPECS_GATE_RECORD_FILE`] is the gate
    /// record; every other file is an extract. The area code comes from the
    /// file's content, never its name. With a record, an area is in scope
    /// **iff** its verdict is `sufficient`, and:
    ///
    /// * the record must carry a verdict for every extract supplied — a scope
    ///   silent about an area would let a skipped area read as a passed one;
    /// * a `not applicable` area whose extract has entries is an error — a
    ///   routed value is evidence the area applies (`codespecs_prompt.md` §6.4);
    /// * an `insufficient` area without `resolution: descoped` is an error —
    ///   the run may not have continued past it (`codespecs_prompt.md` §6.2).
    ///
    /// Two extracts for one area, or two gate records, are errors.
    pub fn from_files<I, N, T>(files: I) -> RecordResult<CodeSpecsExtractSet>
    where
        I: IntoIterator<Item = (N, T)>,
        N: AsRef<str>,
        T: AsRef<str>,
    {
        let mut gate_file: Option<(String, String)> = None;
        let mut extracts: Vec<CodeSpecsExtract> = Vec::new();
        let mut sources: Vec<String> = Vec::new();
        for (name, text) in files {
            let name = name.as_ref();
            let basename = name.rsplit('/').next().unwrap_or(name);
            if basename == CODE_SPECS_GATE_RECORD_FILE {
                if let Some((earlier, _)) = &gate_file {
                    return err(format!(
                        "both {} and {} are gate records — the scope must have one author",
                        earlier, name
                    ));
                }
                gate_file = Some((name.to_string(), text.as_ref().to_string()));
                continue;
            }
            let x = parse_code_specs_extract_yaml(text.as_ref(), name)?;
            if let Some(earlier) = extracts.iter().position(|e| e.area.code == x.area.code) {
                return err(format!(
                    "{} and {} are both extracts for {}",
                    sources[earlier], name, x.area.code
                ));
            }
            extracts.push(x);
            sources.push(name.to_string());
        }
        let (gate_name, gate_text) = match gate_file {
            None => {
                return Ok(CodeSpecsExtractSet {
                    extracts,
                    sources,
                    excluded: Vec::new(),
                    gate: None,
                })
            }
            Some(g) => g,
        };
        let gate = CodeSpecsGateRecord::from_yaml(&gate_text, &gate_name)?;
        for (x, src) in extracts.iter().zip(&sources) {
            if gate.verdict_for(&x.area.code).is_none() {
                return err(format!(
                    "{} carries no verdict for {} ({}) — the gate record must be total over \
                     the supplied extracts",
                    gate_name, x.area.code, src
                ));
            }
        }
        let mut in_scope = Vec::new();
        let mut in_scope_sources = Vec::new();
        let mut excluded = Vec::new();
        for v in gate.verdicts() {
            let i = extracts.iter().position(|e| e.area.code == v.area);
            let src = i.map(|i| sources[i].clone()).unwrap_or_default();
            let count = i.map(|i| extracts[i].entries.len()).unwrap_or(0);
            match v.verdict {
                CodeSpecsGateVerdict::Sufficient => {
                    if let Some(i) = i {
                        in_scope.push(extracts[i].clone());
                        in_scope_sources.push(src);
                    }
                }
                CodeSpecsGateVerdict::NotApplicable => {
                    if count > 0 {
                        return err(format!(
                            "{} marks {} `not applicable`, but {} carries {} routed entr{} — a \
                             routed value is evidence the area applies (codespecs_prompt.md \
                             §6.4)",
                            gate_name,
                            v.area,
                            src,
                            count,
                            if count == 1 { "y" } else { "ies" }
                        ));
                    }
                    excluded.push(CodeSpecsExcludedArea {
                        area: v.area.clone(),
                        verdict: v.verdict,
                        descoped: false,
                        entry_count: count,
                        source: src,
                    });
                }
                CodeSpecsGateVerdict::Insufficient => {
                    if !v.descoped() {
                        return err(format!(
                            "{} marks {} `insufficient` without `resolution: descoped` — \
                             codespecs_prompt.md §6.2 says the run does not continue past an \
                             unresolved insufficient area; recording the descope is what \
                             legitimizes a partial pass",
                            gate_name, v.area
                        ));
                    }
                    excluded.push(CodeSpecsExcludedArea {
                        area: v.area.clone(),
                        verdict: v.verdict,
                        descoped: true,
                        entry_count: count,
                        source: src,
                    });
                }
            }
        }
        Ok(CodeSpecsExtractSet {
            extracts: in_scope,
            sources: in_scope_sources,
            excluded,
            gate: Some(gate),
        })
    }

    /// Reads a directory of extracts — `<CE-CODE>.extract.yaml` plus an
    /// optional `gate.verdicts.yaml`; other files (the `.extract.md` views) are
    /// ignored. Files are read in name order, so the set is the same on every
    /// file system.
    pub fn from_directory<P: AsRef<Path>>(path: P) -> RecordResult<CodeSpecsExtractSet> {
        let dir = path.as_ref();
        if !dir.is_dir() {
            return err(format!("extract directory not found: {}", dir.display()));
        }
        let listing = std::fs::read_dir(dir).map_err(|e| {
            CodeSpecsRecordError::new(format!(
                "extract directory not readable: {}: {}",
                dir.display(),
                e
            ))
        })?;
        let mut names: Vec<String> = Vec::new();
        for entry in listing.flatten() {
            if !entry.path().is_file() {
                continue;
            }
            let n = entry.file_name().to_string_lossy().into_owned();
            if n.ends_with(CODE_SPECS_EXTRACT_FILE_SUFFIX) || n == CODE_SPECS_GATE_RECORD_FILE {
                names.push(n);
            }
        }
        names.sort();
        let mut files: Vec<(String, String)> = Vec::with_capacity(names.len());
        for n in names {
            let text = std::fs::read_to_string(dir.join(&n))
                .map_err(|e| CodeSpecsRecordError::new(format!("{} is not readable: {}", n, e)))?;
            files.push((n, text));
        }
        CodeSpecsExtractSet::from_files(files)
    }

    /// The in-scope extract for `area`, or `None`.
    pub fn by_area(&self, area: &str) -> Option<&CodeSpecsExtract> {
        self.extracts.iter().find(|x| x.area.code == area)
    }

    /// Every in-scope entry routed from `section_id` — the back-link token a
    /// `DocRef` names — across every area, in extract order.
    pub fn entries_for_section(&self, section_id: &str) -> Vec<&CodeSpecsExtractEntry> {
        self.extracts
            .iter()
            .flat_map(|x| x.entries.iter())
            .filter(|e| e.section_id == section_id)
            .collect()
    }

    /// Every in-scope entry read from document `path`, in extract order.
    pub fn entries_at_path(&self, path: &str) -> Vec<&CodeSpecsExtractEntry> {
        self.extracts
            .iter()
            .flat_map(|x| x.entries.iter())
            .filter(|e| e.path == path)
            .collect()
    }
}

// ---------------------------------------------------------------------------
// Helpers: the typed value model over the raw-scalar YAML read
// ---------------------------------------------------------------------------

/// A YAML value with its scalars typed (YAML 1.2 core schema, as far as the
/// two record formats need it).
#[derive(Debug, Clone, PartialEq)]
enum RecVal {
    Null,
    Bool(bool),
    Int(i64),
    Float(f64),
    Str(String),
    List(Vec<RecVal>),
    Map(Vec<(String, RecVal)>),
}

type RecMap = Vec<(String, RecVal)>;

fn map_get<'a>(m: &'a RecMap, key: &str) -> Option<&'a RecVal> {
    m.iter().find(|(k, _)| k == key).map(|(_, v)| v)
}

/// `v` unless it stands for an absent value: null, or the empty mapping the
/// reader yields for a bare `key:`.
fn present(v: Option<&RecVal>) -> Option<&RecVal> {
    match v {
        None | Some(RecVal::Null) => None,
        Some(RecVal::Map(m)) if m.is_empty() => None,
        other => other,
    }
}

/// How the Dart reference interpolates a value into a message.
fn display(v: Option<&RecVal>) -> String {
    match v {
        None | Some(RecVal::Null) => "null".to_string(),
        Some(RecVal::Bool(b)) => b.to_string(),
        Some(RecVal::Int(n)) => n.to_string(),
        Some(RecVal::Float(f)) => {
            if f.fract() == 0.0 && f.is_finite() {
                format!("{:.1}", f)
            } else {
                f.to_string()
            }
        }
        Some(RecVal::Str(s)) => s.clone(),
        Some(RecVal::List(items)) => {
            let parts: Vec<String> = items.iter().map(|i| display(Some(i))).collect();
            format!("[{}]", parts.join(", "))
        }
        Some(RecVal::Map(m)) => {
            let parts: Vec<String> = m
                .iter()
                .map(|(k, v)| format!("{}: {}", k, display(Some(v))))
                .collect();
            format!("{{{}}}", parts.join(", "))
        }
    }
}

fn root_mapping(text: &str, name: &str, key: &str) -> RecordResult<RecMap> {
    let has_content = text.split('\n').any(|l| {
        let t = l.trim();
        !t.is_empty() && !t.starts_with('#')
    });
    let document = match typed(yaml_parse_raw_scalars(text)) {
        Ok(v) => v,
        Err(message) => return err(format!("{} is not valid YAML: {}", name, message)),
    };
    let document = match document {
        RecVal::Map(m) if has_content => m,
        _ => return err(format!("{} does not hold a YAML mapping", name)),
    };
    match map_get(&document, key) {
        Some(RecVal::Map(m)) => Ok(m.clone()),
        _ => err(format!("{} has no top-level `{}:` mapping", name, key)),
    }
}

fn typed(v: YamlValue) -> Result<RecVal, String> {
    match v {
        YamlValue::Map(m) => {
            let mut out = Vec::with_capacity(m.len());
            for (k, v) in m.iter() {
                out.push((k.clone(), typed(v.clone())?));
            }
            Ok(RecVal::Map(out))
        }
        YamlValue::Seq(items) => Ok(RecVal::List(
            items
                .into_iter()
                .map(typed)
                .collect::<Result<Vec<_>, _>>()?,
        )),
        YamlValue::Int(n) => Ok(RecVal::Int(n)),
        YamlValue::Str(t) => typed_scalar(&t),
        // The raw-scalar reader never yields these; mapped for completeness.
        YamlValue::Null => Ok(RecVal::Null),
        YamlValue::Bool(b) => Ok(RecVal::Bool(b)),
        YamlValue::Float(f) => Ok(RecVal::Float(f)),
    }
}

/// Types one raw flow scalar: a JSON-quoted string, a null, a boolean, an
/// integer, a float, a JSON flow sequence, else a plain string.
fn typed_scalar(t: &str) -> Result<RecVal, String> {
    if t.starts_with('"') {
        return match Json::parse(t) {
            Ok(Json::Str(s)) => Ok(RecVal::Str(s)),
            Ok(_) => Err(format!("`{}` is not a quoted scalar", t)),
            Err(e) => Err(e),
        };
    }
    match t {
        "null" | "Null" | "NULL" | "~" => return Ok(RecVal::Null),
        "true" | "True" | "TRUE" => return Ok(RecVal::Bool(true)),
        "false" | "False" | "FALSE" => return Ok(RecVal::Bool(false)),
        _ => {}
    }
    if is_integer(t) {
        if let Ok(n) = t.parse::<i64>() {
            return Ok(RecVal::Int(n));
        }
    }
    if is_float(t) {
        if let Ok(f) = t.parse::<f64>() {
            return Ok(RecVal::Float(f));
        }
    }
    if t.starts_with('[') && t.ends_with(']') {
        if let Ok(j) = Json::parse(t) {
            return Ok(from_json(j));
        }
    }
    Ok(RecVal::Str(t.to_string()))
}

fn from_json(j: Json) -> RecVal {
    match j {
        Json::Null => RecVal::Null,
        Json::Bool(b) => RecVal::Bool(b),
        Json::Int(n) => RecVal::Int(n),
        Json::Float(f) => RecVal::Float(f),
        Json::Str(s) => RecVal::Str(s),
        Json::Array(items) => RecVal::List(items.into_iter().map(from_json).collect()),
        Json::Object(pairs) => {
            RecVal::Map(pairs.into_iter().map(|(k, v)| (k, from_json(v))).collect())
        }
    }
}

fn is_integer(s: &str) -> bool {
    let digits = s
        .strip_prefix('-')
        .or_else(|| s.strip_prefix('+'))
        .unwrap_or(s);
    !digits.is_empty() && digits.bytes().all(|b| b.is_ascii_digit())
}

/// `[-+]?(\.[0-9]+|[0-9]+(\.[0-9]*)?)([eE][-+]?[0-9]+)?`
fn is_float(s: &str) -> bool {
    let b = s.as_bytes();
    let mut i = 0;
    if i < b.len() && (b[i] == b'-' || b[i] == b'+') {
        i += 1;
    }
    let int_start = i;
    while i < b.len() && b[i].is_ascii_digit() {
        i += 1;
    }
    let int_digits = i - int_start;
    let mut frac_digits = 0;
    if i < b.len() && b[i] == b'.' {
        i += 1;
        let frac_start = i;
        while i < b.len() && b[i].is_ascii_digit() {
            i += 1;
        }
        frac_digits = i - frac_start;
    }
    if int_digits == 0 && frac_digits == 0 {
        return false;
    }
    if i < b.len() && (b[i] == b'e' || b[i] == b'E') {
        i += 1;
        if i < b.len() && (b[i] == b'-' || b[i] == b'+') {
            i += 1;
        }
        let exp_start = i;
        while i < b.len() && b[i].is_ascii_digit() {
            i += 1;
        }
        if i == exp_start {
            return false;
        }
    }
    i == b.len()
}

fn req_str(v: Option<&RecVal>, name: &str, key: &str) -> RecordResult<String> {
    match present(v) {
        None => Ok(String::new()),
        Some(RecVal::Str(s)) => Ok(s.clone()),
        Some(_) => err(format!("{}: `{}` must be a string", name, key)),
    }
}

fn opt_str(v: Option<&RecVal>, name: &str, key: &str) -> RecordResult<Option<String>> {
    match present(v) {
        None => Ok(None),
        Some(RecVal::Str(s)) => Ok(Some(s.clone())),
        Some(_) => err(format!("{}: `{}` must be a string or null", name, key)),
    }
}

fn str_list(v: Option<&RecVal>, name: &str, key: &str) -> RecordResult<Vec<String>> {
    match present(v) {
        None => Ok(Vec::new()),
        Some(RecVal::List(items)) => items.iter().map(|e| req_str(Some(e), name, key)).collect(),
        Some(_) => err(format!("{}: `{}` must be a list", name, key)),
    }
}

fn int_list(v: Option<&RecVal>, name: &str, key: &str) -> RecordResult<Vec<i64>> {
    match present(v) {
        None => Ok(Vec::new()),
        Some(RecVal::List(items)) => items
            .iter()
            .map(|e| match e {
                RecVal::Int(n) => Ok(*n),
                _ => err(format!("{}: `{}` must hold integers", name, key)),
            })
            .collect(),
        Some(_) => err(format!("{}: `{}` must be a list", name, key)),
    }
}
