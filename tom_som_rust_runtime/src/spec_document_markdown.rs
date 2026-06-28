//! `spec_document_markdown` — generic, meta-data-driven Markdown codec for a
//! TomSpecs document, a faithful port of the Go `spec_document_markdown.go`.
//!
//! A `<!-- docspec: -->` header, then one heading per populated section (sparse,
//! in schema order), with each section's machine-readable section path as the
//! first token of its heading so import maps back unambiguously. Leaf values
//! live in fenced code blocks whose fence is widened past any backtick run in
//! the value, so embedded code bodies round-trip verbatim. Form fields are
//! introduced by a `<!-- field: name -->` anchor; list items appear as nested
//! `…-N` sections, so list membership is recovered from the paths alone on
//! import.
//!
//! [`SpecDocumentMarkdown::parse`] does not mutate the document — it returns
//! staged values keyed exactly like [`DocumentJson`] plus a rejection report;
//! the caller applies them. Regex matching from the Go port is hand-rolled here
//! to keep the zero-dependency promise.

use std::collections::{BTreeMap, BTreeSet, HashSet};

use crate::spec_document::{DocumentJson, ListJson, SpecDocument};
use crate::spec_model::{
    SpecClass, SpecField, SpecModel, SpecRoot, SPEC_FIELD_KIND_COMPLEX, SPEC_FIELD_KIND_CONTENT,
    SPEC_FIELD_KIND_ENUM, SPEC_FIELD_KIND_FORM, SPEC_FIELD_KIND_LIST, SPEC_FIELD_KIND_SCALAR,
    SPEC_FIELD_KIND_SECTION,
};
use crate::spec_reflection::{SpecReflection, SPEC_NODE_KIND_FORM, SPEC_NODE_KIND_LIST};

/// Why an imported Markdown block was rejected.
pub const SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION: &str = "unknownSection";
pub const SPEC_MARKDOWN_REJECT_KIND_MISMATCH: &str = "kindMismatch";
pub const SPEC_MARKDOWN_REJECT_ORPHAN_BLOCK: &str = "orphanBlock";
pub const SPEC_MARKDOWN_REJECT_MISSING_VALUE: &str = "missingValue";
pub const SPEC_MARKDOWN_REJECT_MALFORMED_HEADING: &str = "malformedHeading";

/// One rejected block in a Markdown import. Reported, never silently dropped.
#[derive(Debug, Clone)]
pub struct SpecMarkdownRejection {
    pub line: usize,
    pub reason: String,
    pub message: String,
    pub anchor: String,
}

impl SpecMarkdownRejection {
    /// Renders the rejection as `line N: reason (anchor) — message`.
    pub fn to_display(&self) -> String {
        let anchor = if self.anchor.is_empty() {
            String::new()
        } else {
            format!(" ({})", self.anchor)
        };
        format!("line {}: {}{} \u{2014} {}", self.line, self.reason, anchor, self.message)
    }
}

impl std::fmt::Display for SpecMarkdownRejection {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.to_display())
    }
}

/// The outcome of parsing a Markdown document: the staged values plus every
/// rejected block. The values are keyed exactly like [`DocumentJson`].
#[derive(Debug, Clone, Default)]
pub struct SpecMarkdownResult {
    pub content: BTreeMap<String, String>,
    pub forms: BTreeMap<String, BTreeMap<String, String>>,
    pub lists: BTreeMap<String, ListJson>,
    pub rejections: Vec<SpecMarkdownRejection>,
    pub root_prefixes: BTreeSet<String>,
}

impl SpecMarkdownResult {
    /// Reports whether no block was rejected.
    pub fn is_clean(&self) -> bool {
        self.rejections.is_empty()
    }

    /// Returns the number of content + form-field values staged.
    pub fn applied_count(&self) -> usize {
        self.content.len() + self.forms.values().map(|m| m.len()).sum::<usize>()
    }

    /// Converts the staged values into a [`DocumentJson`] for loading.
    pub fn to_document_json(&self) -> DocumentJson {
        DocumentJson {
            content: self.content.clone(),
            forms: self.forms.clone(),
            lists: self.lists.clone(),
        }
    }
}

/// A value target between a section/field anchor and its fenced block.
struct Pending {
    line: usize,
    path: String,
    field: String,
    has_fld: bool,
    filled: bool,
}

impl Pending {
    fn anchor(&self) -> String {
        if self.has_fld {
            format!("{} :: {}", self.path, self.field)
        } else {
            self.path.clone()
        }
    }
}

/// Renders a fenced code block holding `value` verbatim. The fence is one
/// backtick longer than the longest backtick run in `value` (min 3).
fn fence(value: &str, info: &str) -> String {
    let mut max_run = 0;
    let mut run = 0;
    for ch in value.chars() {
        if ch == '`' {
            run += 1;
            if run > max_run {
                max_run = run;
            }
        } else {
            run = 0;
        }
    }
    let n = std::cmp::max(3, max_run + 1);
    let f = "`".repeat(n);
    let mut out = String::new();
    out.push_str(&f);
    out.push_str(info);
    out.push('\n');
    for line in value.split('\n') {
        out.push_str(line);
        out.push('\n');
    }
    out.push_str(&f);
    out
}

struct MdBuffer {
    out: String,
}

impl MdBuffer {
    fn new() -> MdBuffer {
        MdBuffer { out: String::new() }
    }

    fn writeln(&mut self, text: &str) {
        self.out.push_str(text);
        self.out.push('\n');
    }
}

fn md_heading(b: &mut MdBuffer, depth: usize, path: &str, name: &str) {
    let d = std::cmp::min(depth, 6);
    b.writeln(&format!("{} {} \u{2014} {}", "#".repeat(d), path, name));
}

/// A codec binding a [`SpecModel`] and a concrete [`SpecDocument`] to the
/// Markdown import/export format.
pub struct SpecDocumentMarkdown<'a> {
    pub model: &'a SpecModel,
    pub document: &'a SpecDocument,
    reflection: SpecReflection<'a>,
}

impl<'a> SpecDocumentMarkdown<'a> {
    /// Binds a model and document to the Markdown codec.
    pub fn new(model: &'a SpecModel, document: &'a SpecDocument) -> SpecDocumentMarkdown<'a> {
        SpecDocumentMarkdown {
            model,
            document,
            reflection: SpecReflection::new(model),
        }
    }

    fn field_seg(&self, f: &SpecField) -> String {
        self.reflection.field_segment(f)
    }

    // --- Export ------------------------------------------------------------

    /// Renders the populated subtree of `root` as a schema-conformant Markdown
    /// document with a `<!-- docspec: -->` header.
    pub fn export_root(&self, root: &SpecRoot) -> String {
        let mut b = MdBuffer::new();
        let seg = self.reflection.root_segment(root);
        b.writeln(&format!("<!-- docspec: {}/1 -->", seg.to_lowercase()));
        b.writeln(&format!("# {} \u{2014} {}", seg, root.title));
        if !root.description.trim().is_empty() {
            b.writeln("");
            b.writeln(root.description.trim());
        }
        if let Some(cls) = self.model.class_named(&root.type_) {
            let mut seen = HashSet::new();
            seen.insert(root.type_.clone());
            self.export_class(&mut b, cls, &seg, 2, &seen);
        }
        b.out
    }

    fn export_class(
        &self,
        b: &mut MdBuffer,
        cls: &SpecClass,
        base_path: &str,
        depth: usize,
        seen_types: &HashSet<String>,
    ) {
        for field in &cls.fields {
            let path = format!("{}/{}", base_path, self.field_seg(field));
            if !self.document.has_values_under(&path) {
                continue;
            }
            match field.kind.as_str() {
                SPEC_FIELD_KIND_CONTENT | SPEC_FIELD_KIND_SCALAR | SPEC_FIELD_KIND_ENUM => {
                    let value = match self.document.content(&path) {
                        Some(v) => v.clone(),
                        None => continue,
                    };
                    md_heading(b, depth, &path, &field.name);
                    b.writeln(&fence(&value, &field.content_type));
                    b.writeln("");
                }
                SPEC_FIELD_KIND_FORM => {
                    md_heading(b, depth, &path, &field.name);
                    for ff in &field.form_fields {
                        let value = match self.document.form_field(&path, &ff.name) {
                            Some(v) => v.clone(),
                            None => continue,
                        };
                        b.writeln(&format!("<!-- field: {} -->", ff.name));
                        b.writeln(&fence(&value, ""));
                        b.writeln("");
                    }
                }
                SPEC_FIELD_KIND_LIST => {
                    let elem = self.model.class_named(&field.element_type);
                    let recursive =
                        !field.element_type.is_empty() && seen_types.contains(&field.element_type);
                    md_heading(b, depth, &path, &field.name);
                    b.writeln("");
                    let elem = match elem {
                        Some(e) if !recursive => e,
                        _ => continue,
                    };
                    let mut next_seen = seen_types.clone();
                    next_seen.insert(field.element_type.clone());
                    for item_path in self.document.list_items(&path) {
                        let label = if field.element_type.is_empty() {
                            "item".to_string()
                        } else {
                            field.element_type.clone()
                        };
                        md_heading(b, depth + 1, &item_path, &label);
                        b.writeln("");
                        self.export_class(b, elem, &item_path, depth + 2, &next_seen);
                    }
                }
                SPEC_FIELD_KIND_COMPLEX | SPEC_FIELD_KIND_SECTION => {
                    let nested = self.model.class_named(&field.type_);
                    let recursive = !field.type_.is_empty() && seen_types.contains(&field.type_);
                    let nested = match nested {
                        Some(n) if !recursive => n,
                        _ => continue,
                    };
                    md_heading(b, depth, &path, &field.name);
                    b.writeln("");
                    let mut next_seen = seen_types.clone();
                    next_seen.insert(field.type_.clone());
                    self.export_class(b, nested, &path, depth + 1, &next_seen);
                }
                _ => {}
            }
        }
    }

    // --- Import ------------------------------------------------------------

    /// Parses `text` into staged values + a rejection report, without mutating
    /// the document.
    pub fn parse(&self, text: &str) -> SpecMarkdownResult {
        let lines: Vec<&str> = text.split('\n').collect();
        let mut result = SpecMarkdownResult::default();

        let mut pend: Option<Pending> = None;
        let mut current_kind = String::new();
        let mut current_path = String::new();

        let mut i = 0;
        while i < lines.len() {
            let raw = lines[i];
            let line_no = i + 1;
            let trimmed = raw.trim_end_matches([' ', '\t', '\r', '\n', '\u{000C}', '\u{000B}']);

            // Heading.
            if let Some(path) = heading_path(trimmed) {
                flush_missing(&mut pend, &mut result);
                match self.reflection.resolve(&path) {
                    None => {
                        result.rejections.push(SpecMarkdownRejection {
                            line: line_no,
                            reason: SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION.to_string(),
                            message: "section path does not resolve against the model".to_string(),
                            anchor: path.clone(),
                        });
                        current_kind.clear();
                        current_path.clear();
                        i += 1;
                        continue;
                    }
                    Some(node) => {
                        current_kind = node.kind.clone();
                        current_path = path.clone();
                        if let Some(prefix) = path.split('/').next() {
                            result.root_prefixes.insert(prefix.to_string());
                        }
                        if node.is_value_leaf() {
                            pend = Some(Pending {
                                line: line_no,
                                path: path.clone(),
                                field: String::new(),
                                has_fld: false,
                                filled: false,
                            });
                        }
                    }
                }
                i += 1;
                continue;
            }

            // Form-field anchor.
            if let Some(field_name) = field_anchor(trimmed) {
                flush_missing(&mut pend, &mut result);
                if current_path.is_empty() || current_kind != SPEC_NODE_KIND_FORM {
                    result.rejections.push(SpecMarkdownRejection {
                        line: line_no,
                        reason: SPEC_MARKDOWN_REJECT_KIND_MISMATCH.to_string(),
                        message: "form-field anchor outside a `@Form` section".to_string(),
                        anchor: field_name,
                    });
                    i += 1;
                    continue;
                }
                pend = Some(Pending {
                    line: line_no,
                    path: current_path.clone(),
                    field: field_name,
                    has_fld: true,
                    filled: false,
                });
                i += 1;
                continue;
            }

            // Fence opener.
            if let Some(fence_len) = fence_open(trimmed) {
                let mut body = Vec::new();
                let mut j = i + 1;
                let closer = "`".repeat(fence_len);
                while j < lines.len()
                    && lines[j].trim_end_matches([' ', '\t', '\r', '\n', '\u{000C}', '\u{000B}'])
                        != closer
                {
                    body.push(lines[j]);
                    j += 1;
                }
                let value = body.join("\n");
                match pend.take() {
                    None => {
                        result.rejections.push(SpecMarkdownRejection {
                            line: line_no,
                            reason: SPEC_MARKDOWN_REJECT_ORPHAN_BLOCK.to_string(),
                            message: "fenced value with no owning section or field".to_string(),
                            anchor: String::new(),
                        });
                    }
                    Some(p) => {
                        if p.has_fld {
                            result
                                .forms
                                .entry(p.path.clone())
                                .or_default()
                                .insert(p.field.clone(), value);
                        } else {
                            result.content.insert(p.path.clone(), value);
                        }
                    }
                }
                i = if j < lines.len() { j + 1 } else { j };
                continue;
            }

            i += 1;
        }
        flush_missing(&mut pend, &mut result);

        result.lists = self.reconstruct_lists(&result.content, &result.forms);
        result
    }

    /// Recovers list membership from the leaf paths: any `<base>-<n>` segment
    /// whose `<base>` ancestor resolves to a list field denotes item `<n>` of
    /// that list.
    fn reconstruct_lists(
        &self,
        content: &BTreeMap<String, String>,
        forms: &BTreeMap<String, BTreeMap<String, String>>,
    ) -> BTreeMap<String, ListJson> {
        let mut items: BTreeMap<String, Vec<String>> = BTreeMap::new();
        let mut seq: BTreeMap<String, i64> = BTreeMap::new();

        let mut scan = |path: &str| {
            let segs: Vec<&str> = path.split('/').collect();
            let mut prefix = segs[0].to_string();
            for seg in &segs[1..] {
                if let Some((base, n)) = item_seg(seg) {
                    let list_path = format!("{}/{}", prefix, base);
                    let item_path = format!("{}/{}", prefix, seg);
                    if let Some(node) = self.reflection.resolve(&list_path) {
                        if node.kind == SPEC_NODE_KIND_LIST {
                            let bucket = items.entry(list_path.clone()).or_default();
                            if !bucket.iter().any(|it| it == &item_path) {
                                bucket.push(item_path);
                            }
                            let entry = seq.entry(list_path).or_insert(0);
                            if n > *entry {
                                *entry = n;
                            }
                        }
                    }
                }
                prefix = format!("{}/{}", prefix, seg);
            }
        };

        for p in content.keys() {
            scan(p);
        }
        for p in forms.keys() {
            scan(p);
        }

        let mut out = BTreeMap::new();
        for (key, value) in items {
            let s = seq.get(&key).copied().unwrap_or(value.len() as i64);
            out.insert(key, ListJson { seq: s, items: value });
        }
        out
    }
}

fn flush_missing(pend: &mut Option<Pending>, result: &mut SpecMarkdownResult) {
    if let Some(p) = pend.take() {
        if !p.filled {
            result.rejections.push(SpecMarkdownRejection {
                line: p.line,
                reason: SPEC_MARKDOWN_REJECT_MISSING_VALUE.to_string(),
                message: "no fenced value followed this anchor".to_string(),
                anchor: p.anchor(),
            });
        }
    }
}

/// Returns the section path of a heading line (`#{1,6} <path> …`).
fn heading_path(line: &str) -> Option<String> {
    let bytes = line.as_bytes();
    let mut hashes = 0;
    while hashes < bytes.len() && bytes[hashes] == b'#' {
        hashes += 1;
    }
    if hashes == 0 || hashes > 6 {
        return None;
    }
    let rest = &line[hashes..];
    // Require at least one whitespace character after the hashes.
    if rest.is_empty() || !rest.chars().next().unwrap().is_whitespace() {
        return None;
    }
    let token = rest.split_whitespace().next()?;
    if token.is_empty() {
        None
    } else {
        Some(token.to_string())
    }
}

/// Returns the field name of a `<!-- field: name -->` anchor line.
fn field_anchor(line: &str) -> Option<String> {
    let t = line.trim();
    let inner = t.strip_prefix("<!--")?.strip_suffix("-->")?.trim();
    let rest = inner.strip_prefix("field:")?.trim();
    let token = rest.split_whitespace().next()?;
    if token.is_empty() || rest.split_whitespace().count() != 1 {
        None
    } else {
        Some(token.to_string())
    }
}

/// Returns the fence length of a fence-opener line (3+ backticks).
fn fence_open(line: &str) -> Option<usize> {
    let bytes = line.as_bytes();
    let mut n = 0;
    while n < bytes.len() && bytes[n] == b'`' {
        n += 1;
    }
    if n >= 3 {
        Some(n)
    } else {
        None
    }
}

/// Splits a list-item segment `<base>-<digits>` into base and number.
fn item_seg(seg: &str) -> Option<(String, i64)> {
    let dash = seg.rfind('-')?;
    if dash == 0 || dash == seg.len() - 1 {
        return None;
    }
    let base = &seg[..dash];
    let tail = &seg[dash + 1..];
    if tail.is_empty() || !tail.bytes().all(|b| b.is_ascii_digit()) {
        return None;
    }
    Some((base.to_string(), tail.parse::<i64>().ok()?))
}
