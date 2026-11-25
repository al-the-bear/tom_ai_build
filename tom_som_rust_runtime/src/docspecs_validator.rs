//! `docspecs_validator` — DocSpecs markdown validation, a faithful port of the
//! Go `docspecs_validator.go` (itself a port of the
//! TypeScript/JavaScript / Python / Dart parity chain).
//!
//! Three cooperating pieces:
//!
//!  1. [`DocSpecsDocument`] — a schema-free structural parse of a DocSpecs
//!     markdown document into a heading tree (fence-aware, never fails).
//!  2. [`DocSpecsSchema`] — loader for `*.docspecs-schema.yaml` files with
//!     SOM §14-style warnings for unsupported keys (never fails on extra keys).
//!  3. [`DocSpecsValidator`] — never-fail-fast validation of a parsed document
//!     against a schema, emitting [`DocSpecsViolation`]s whose messages are
//!     golden-identical to the Dart implementation.
//!
//! Plus [`bind_docspecs_markdown`], which lands a DocSpecs markdown text in a
//! typed [`SpecDocument`] via the SOM markdown codec.
//!
//! Rust conventions: `""` stands in for the other ports' null
//! strings (`DocSpecsViolation::section_id`/`path`, `DocSpecsSection::id`, …);
//! optional ints are `Option<i64>`; the one throwing entry point
//! (`from_yaml_text`'s "must be a YAML map") returns `Err(String)`. The Go
//! stdlib `regexp` engine behind the schema pattern checks is replaced by a
//! small hand-rolled backtracking matcher ([`dv_regex_match`]) covering the
//! RE2 subset the schemas use — keeping the crate's zero-dependency promise.

use std::collections::{HashMap, HashSet};

use crate::spec_document::SpecDocument;
use crate::spec_document_markdown::{
    md_delimiter_cell, md_div_close_line, md_find_link_text, md_heading_line, md_layout_table_header,
    md_link_cell, md_list_div_open, md_row_cells, md_table_line, MarkdownFenceTracker,
    SpecDocumentMarkdown, SpecMarkdownResult,
};
use crate::spec_model::SpecModel;
use crate::spec_notation::scan_notation;
use crate::yaml::{yaml_parse, YamlValue};

// The vocabulary of validation violation rules (Dart-parity names).

/// A section id that resolves to no section-type / a disallowed position.
pub const DOCSPECS_RULE_UNKNOWN_SECTION: &str = "unknownSection";
/// A required document section or subsection is missing.
pub const DOCSPECS_RULE_MISSING_REQUIRED_SECTION: &str = "missingRequiredSection";
/// A section id fails its section-type's `pattern-check-id`.
pub const DOCSPECS_RULE_ID_PATTERN_MISMATCH: &str = "idPatternMismatch";
/// A subsection occurs fewer times than `min-count`.
pub const DOCSPECS_RULE_TOO_FEW_ITEMS: &str = "tooFewItems";
/// A subsection occurs more often than `max-count`.
pub const DOCSPECS_RULE_TOO_MANY_ITEMS: &str = "tooManyItems";
/// A required form field is absent.
pub const DOCSPECS_RULE_MISSING_REQUIRED_FIELD: &str = "missingRequiredField";
/// A form field value fails its `pattern-check`.
pub const DOCSPECS_RULE_FIELD_PATTERN_MISMATCH: &str = "fieldPatternMismatch";
/// A section demanding body text has none.
pub const DOCSPECS_RULE_TEXT_REQUIRED: &str = "textRequired";
/// A section's body text length is outside `[min, max]`.
pub const DOCSPECS_RULE_TEXT_LENGTH_OUT: &str = "textLengthOut";
/// A structural format mismatch (root id, fenced-block format, …).
pub const DOCSPECS_RULE_FORMAT_MISMATCH: &str = "formatMismatch";
/// A heading without a `<!--[SECTION-ID]-->` headline comment.
pub const DOCSPECS_RULE_MALFORMED_HEADING: &str = "malformedHeading";
/// A root child stands before a `document: sections:` slot taken earlier (the
/// slots' order; a `position: any` slot's type stands anywhere).
pub const DOCSPECS_RULE_SECTION_OUT_OF_ORDER: &str = "sectionOutOfOrder";
/// A section's id repeats an earlier sibling's, so its id path (the ids from
/// the root down to it) is not unique.
pub const DOCSPECS_RULE_DUPLICATE_ID_PATH: &str = "duplicateIdPath";

// The reading notation's findings (DocSpecs specification, RN-10), reported
// by [`scan_notation`](crate::spec_notation::scan_notation) per value: a section's own body, and in a TomSpecs
// rendition each form field's value apart. Each is the
// [`NotationFindingCode::as_str`](crate::spec_notation::NotationFindingCode::as_str)
// of its code.

/// An opening fence without its closing fence.
pub const DOCSPECS_RULE_UNCLOSED_DIV: &str = "unclosedDiv";
/// A closing fence without an open div.
pub const DOCSPECS_RULE_STRAY_CLOSING_FENCE: &str = "strayClosingFence";
/// A span's attribute braces do not close on the paragraph.
pub const DOCSPECS_RULE_UNCLOSED_SPAN: &str = "unclosedSpan";
/// A div whose attributes hold no class (TomSpecs renditions only).
pub const DOCSPECS_RULE_DIV_WITHOUT_KIND: &str = "divWithoutKind";
/// An unregistered kind (TomSpecs renditions only; a warning).
pub const DOCSPECS_RULE_UNKNOWN_KIND: &str = "unknownKind";
/// An inline review mark crosses the boundary of a span or citation.
pub const DOCSPECS_RULE_MARK_ACROSS_NOTATION: &str = "markAcrossNotation";
/// A comment or question block stands inside a div.
pub const DOCSPECS_RULE_ANNOTATION_INSIDE_DIV: &str = "annotationInsideDiv";
/// A div stands inside a comment or question block.
pub const DOCSPECS_RULE_DIV_INSIDE_ANNOTATION: &str = "divInsideAnnotation";
/// A `rejected` block waits for its resolution.
pub const DOCSPECS_RULE_REJECTED_BLOCK: &str = "rejectedBlock";

// The reading view's list bodies and tables (DocSpecs specification, Findings
// in list bodies and tables).

/// A form, section or record table without a matching delimiter row, a row of
/// another cell count, a field given twice (the first kept), a refs / records
/// div beside other text or item headings, a records div holding no table or
/// one whose first column is not `Id`, an unclosed refs / records fence.
pub const DOCSPECS_RULE_MALFORMED_BLOCK: &str = "malformedBlock";
/// A form-table row or a record-table column naming no field of its form.
pub const DOCSPECS_RULE_UNKNOWN_FIELD: &str = "unknownField";

/// The complete §14 vocabulary, in declaration order — the enumerable form of
/// what Dart gets for free from its enum. The conformance runner diffs it
/// against the rules the shared corpus exercises, so a rule added here without
/// a corpus case fails the suite instead of going unnoticed.
pub const DOCSPECS_ALL_RULES: [&str; 24] = [
    DOCSPECS_RULE_UNKNOWN_SECTION,
    DOCSPECS_RULE_MISSING_REQUIRED_SECTION,
    DOCSPECS_RULE_ID_PATTERN_MISMATCH,
    DOCSPECS_RULE_TOO_FEW_ITEMS,
    DOCSPECS_RULE_TOO_MANY_ITEMS,
    DOCSPECS_RULE_MISSING_REQUIRED_FIELD,
    DOCSPECS_RULE_FIELD_PATTERN_MISMATCH,
    DOCSPECS_RULE_TEXT_REQUIRED,
    DOCSPECS_RULE_TEXT_LENGTH_OUT,
    DOCSPECS_RULE_FORMAT_MISMATCH,
    DOCSPECS_RULE_MALFORMED_HEADING,
    DOCSPECS_RULE_SECTION_OUT_OF_ORDER,
    DOCSPECS_RULE_DUPLICATE_ID_PATH,
    DOCSPECS_RULE_UNCLOSED_DIV,
    DOCSPECS_RULE_STRAY_CLOSING_FENCE,
    DOCSPECS_RULE_UNCLOSED_SPAN,
    DOCSPECS_RULE_DIV_WITHOUT_KIND,
    DOCSPECS_RULE_UNKNOWN_KIND,
    DOCSPECS_RULE_MARK_ACROSS_NOTATION,
    DOCSPECS_RULE_ANNOTATION_INSIDE_DIV,
    DOCSPECS_RULE_DIV_INSIDE_ANNOTATION,
    DOCSPECS_RULE_REJECTED_BLOCK,
    DOCSPECS_RULE_MALFORMED_BLOCK,
    DOCSPECS_RULE_UNKNOWN_FIELD,
];

/// One validation finding.
#[derive(Debug, Clone)]
pub struct DocSpecsViolation {
    pub rule: String,
    pub line: usize,
    pub message: String,
    pub section_id: String,
    pub path: String,
}

impl DocSpecsViolation {
    /// Renders the violation as `line N: rule [sid] (path) — message`.
    pub fn to_display(&self) -> String {
        let sid = if self.section_id.is_empty() {
            String::new()
        } else {
            format!(" [{}]", self.section_id)
        };
        let p = if self.path.is_empty() {
            String::new()
        } else {
            format!(" ({})", self.path)
        };
        format!(
            "line {}: {}{}{} \u{2014} {}",
            self.line, self.rule, sid, p, self.message
        )
    }
}

impl std::fmt::Display for DocSpecsViolation {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.to_display())
    }
}

/// One heading-delimited section of a schema-free document parse.
#[derive(Debug, Clone, Default)]
pub struct DocSpecsSection {
    /// The headline-comment section id, `""` for a malformed heading.
    pub id: String,
    pub title: String,
    pub level: usize,
    pub line: usize,
    /// The raw body lines between this heading and the next.
    pub body_lines: Vec<String>,
    pub children: Vec<DocSpecsSection>,
}

impl DocSpecsSection {
    /// The 1-based line number of the first body line.
    pub fn body_start_line(&self) -> usize {
        self.line + 1
    }

    /// The body text with leading/trailing blank lines trimmed.
    pub fn text(&self) -> String {
        let lines = &self.body_lines;
        let mut start = 0;
        let mut end = lines.len();
        while start < end && lines[start].trim().is_empty() {
            start += 1;
        }
        while end > start && lines[end - 1].trim().is_empty() {
            end -= 1;
        }
        lines[start..end].join("\n")
    }
}

/// Go `\s` character class (`[\t\n\f\r ]`).
fn is_go_space(c: char) -> bool {
    matches!(c, ' ' | '\t' | '\n' | '\x0C' | '\r')
}

/// `mdTrailingWSRE`: strips a trailing `\s+` run.
fn dv_trim_trailing_ws(line: &str) -> &str {
    line.trim_end_matches(is_go_space)
}

/// `docspecHeaderRE`: `^<!--\s*docspec:\s*(\S+)\s*-->\s*$` — returns the
/// declared schema token (applied to a right-trimmed line).
fn dv_docspec_header(line: &str) -> Option<&str> {
    let r = line.strip_prefix("<!--")?;
    let r = r.trim_start_matches(is_go_space);
    let r = r.strip_prefix("docspec:")?;
    let r = r.trim_start_matches(is_go_space);
    let token = r.strip_suffix("-->")?;
    let token = token.trim_end_matches(is_go_space);
    if token.is_empty() || token.chars().any(is_go_space) {
        return None;
    }
    Some(token)
}

/// `mdHeadlineCommentRE`: `^<!--\[([^\]]+)\]([^>]*)-->\s*(.*)$` — returns g1
/// the id, g2 the optional key=value region (codespecs_mapping.md §9.2
/// `codeSpec`), and g3 the title text after the comment. The validator only
/// needs the id and title; g2 is discarded here (the codec stages the
/// codeSpec).
fn dv_headline_comment(rest: &str) -> Option<(&str, &str)> {
    let r = rest.strip_prefix("<!--[")?;
    let close = r.find(']')?;
    if close == 0 {
        return None;
    }
    let id = &r[..close];
    let after = &r[close + 1..]; // skip the `]`.
    let end = after.find("-->")?; // g2 = `[^>]*` up to the closing `-->`.
    if after[..end].contains('>') {
        return None;
    }
    let title = &after[end + 3..];
    Some((id, title.trim_start_matches(is_go_space)))
}

/// `mdFieldLabelRE`: `^([A-Za-z][A-Za-z0-9_]*): ?(.*)$` — returns
/// `(label, first value line)`.
fn dv_field_label(line: &str) -> Option<(&str, &str)> {
    let b = line.as_bytes();
    if b.is_empty() || !b[0].is_ascii_alphabetic() {
        return None;
    }
    let mut i = 1;
    while i < b.len() && (b[i].is_ascii_alphanumeric() || b[i] == b'_') {
        i += 1;
    }
    if i >= b.len() || b[i] != b':' {
        return None;
    }
    let label = &line[..i];
    let mut rest = &line[i + 1..];
    if let Some(r) = rest.strip_prefix(' ') {
        rest = r; // `: ?` — at most one space consumed.
    }
    Some((label, rest))
}

/// A styled-div heading line (the DocSpecs specification's *Styled-div
/// headings*): `^<div class="heading([0-9]+)"[^>]*>(.*)</div>$` — returns
/// the level and the inner text. The caller takes a level of 7 or more as a
/// heading; a `heading<N>` div with N ≤ 6 is content.
fn dv_styled_div_heading(line: &str) -> Option<(usize, &str)> {
    let r = line.strip_prefix("<div class=\"heading")?;
    let digits = r.bytes().take_while(|b| b.is_ascii_digit()).count();
    if digits == 0 {
        return None;
    }
    let level = r[..digits].parse::<usize>().unwrap_or(usize::MAX);
    let r = r[digits..].strip_prefix('"')?;
    let gt = r.find('>')?;
    let inner = r[gt + 1..].strip_suffix("</div>")?;
    Some((level, inner))
}

/// A styled-div heading's inner text with its three entities decoded.
fn dv_decode_entities(text: &str) -> String {
    text.replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&amp;", "&")
}

/// `^<a id="([^"]*)"></a>\s*` at the start of `text`: the anchor and the
/// rest after it.
fn dv_leading_anchor(text: &str) -> Option<(&str, &str)> {
    let r = text.strip_prefix("<a id=\"")?;
    let q = r.find('"')?;
    let rest = r[q + 1..].strip_prefix("></a>")?;
    Some((&r[..q], rest.trim_start()))
}

/// Whether `anchor` is the own anchor of a section with `id`: `id` itself, or
/// a qualified form `<A>/…/<id>` whose segments are all non-empty (Section
/// Anchors).
fn dv_is_own_anchor(anchor: &str, id: &str) -> bool {
    if anchor == id {
        return true;
    }
    if id.is_empty() || !anchor.ends_with(&format!("/{}", id)) {
        return false;
    }
    anchor.split('/').all(|segment| !segment.is_empty())
}

/// `text` with a leading anchor `<a id="ID"></a>` removed when it is the
/// section's own (Section Anchors): its id is `id`, or the qualified form
/// `<A>/…/<id>` a heading below a list item carries. Any other anchor is
/// ordinary text and stays.
fn dv_strip_own_anchor<'a>(text: &'a str, id: &str) -> &'a str {
    match dv_leading_anchor(text) {
        Some((anchor, rest)) if dv_is_own_anchor(anchor, id) => rest,
        _ => text,
    }
}

/// A schema-free structural parse of a DocSpecs markdown document. A
/// styled-div heading `<div class="heading<N>">` with N ≥ 7 is a heading of
/// level N; a `heading<N>` div with N ≤ 6 is content.
#[derive(Debug, Clone, Default)]
pub struct DocSpecsDocument {
    /// The `<!-- docspec: … -->` declaration, `""` when absent.
    pub declared_schema: String,
    /// The top-level (root) sections.
    pub sections: Vec<DocSpecsSection>,
    /// Structural findings from the parse.
    pub violations: Vec<DocSpecsViolation>,
}

/// Pops (and attaches) every open frame at `level` or deeper.
fn dv_close_to(stack: &mut Vec<DocSpecsSection>, sections: &mut Vec<DocSpecsSection>, level: usize) {
    while stack.last().is_some_and(|t| t.level >= level) {
        let done = stack.pop().unwrap();
        match stack.last_mut() {
            Some(parent) => parent.children.push(done),
            None => sections.push(done),
        }
    }
}

/// Parses `text` into a heading tree. It never fails — structural problems are
/// recorded as violations.
pub fn parse_docspecs_document(text: &str) -> DocSpecsDocument {
    let mut doc = DocSpecsDocument::default();
    let mut fence = MarkdownFenceTracker::new();
    let mut stack: Vec<DocSpecsSection> = Vec::new();
    for (idx, raw) in text.split('\n').enumerate() {
        let line_no = idx + 1;
        let line = dv_trim_trailing_ws(raw);
        if !fence.in_fence() {
            if stack.is_empty() && doc.declared_schema.is_empty() {
                if let Some(token) = dv_docspec_header(line) {
                    doc.declared_schema = token.to_string();
                    fence.feed(raw);
                    continue;
                }
            }
            let heading = match md_heading_line(line) {
                Some((level, rest)) => Some((level, rest.to_string())),
                None => dv_styled_div_heading(line)
                    .filter(|(level, _)| *level >= 7)
                    .map(|(level, inner)| (level, dv_decode_entities(inner).trim().to_string())),
            };
            if let Some((level, rest)) = heading {
                let rest = rest.as_str();
                let section = match dv_headline_comment(rest) {
                    Some((id, after)) => {
                        // The title without the section's own anchor
                        // (Section Anchors).
                        let mut title = dv_strip_own_anchor(after.trim(), id).to_string();
                        if title.is_empty() {
                            title = rest.to_string();
                        }
                        DocSpecsSection {
                            id: id.to_string(),
                            title,
                            level,
                            line: line_no,
                            ..DocSpecsSection::default()
                        }
                    }
                    None => {
                        doc.violations.push(DocSpecsViolation {
                            rule: DOCSPECS_RULE_MALFORMED_HEADING.to_string(),
                            line: line_no,
                            message: format!(
                                "heading \"{}\" carries no <!--[SECTION-ID]--> headline comment",
                                rest
                            ),
                            section_id: String::new(),
                            path: String::new(),
                        });
                        DocSpecsSection {
                            title: rest.to_string(),
                            level,
                            line: line_no,
                            ..DocSpecsSection::default()
                        }
                    }
                };
                dv_close_to(&mut stack, &mut doc.sections, level);
                stack.push(section);
                fence.feed(raw);
                continue;
            }
        }
        if let Some(top) = stack.last_mut() {
            top.body_lines.push(raw.to_string());
        }
        fence.feed(raw);
    }
    dv_close_to(&mut stack, &mut doc.sections, 0);
    doc
}

impl DocSpecsDocument {
    /// `text` with a leading anchor `<a id="ID"></a>` removed when it is the
    /// section's own (Section Anchors): its id is `id`, or the qualified form
    /// `<A>/…/<id>` a heading below a list item carries. Any other anchor is
    /// ordinary text and stays.
    pub fn strip_own_anchor<'a>(text: &'a str, id: &str) -> &'a str {
        dv_strip_own_anchor(text, id)
    }

    /// Every section of the tree, depth-first (each section before its
    /// children), at all levels.
    pub fn all_sections(&self) -> Vec<&DocSpecsSection> {
        fn walk<'a>(list: &'a [DocSpecsSection], out: &mut Vec<&'a DocSpecsSection>) {
            for s in list {
                out.push(s);
                walk(&s.children, out);
            }
        }
        let mut out = Vec::new();
        walk(&self.sections, &mut out);
        out
    }

    /// Returns `text` with the body of the section whose id is `section_id`
    /// replaced by `body`; every other byte is kept.
    ///
    /// The body is the section's **own** region: the lines after its heading
    /// up to its first child heading, or the next heading of any level. The
    /// heading line (with its `<!--[ID]-->` comment) and the subsections are
    /// untouched. The region is found by the same fence-aware
    /// [`parse_docspecs_document`], so a `#` line inside a fenced block is
    /// never taken for a heading.
    ///
    /// The new region is a blank line, `body` with its leading and trailing
    /// blank lines removed, and a blank line; an empty `body` leaves a single
    /// blank line. Returns `Err` when `section_id` names no section or more
    /// than one, and when `body` would change the document's structure: a
    /// heading outside a fenced block, or a fence it opens and never closes.
    pub fn replace_section_body(text: &str, section_id: &str, body: &str) -> Result<String, String> {
        let doc = parse_docspecs_document(text);
        let matches: Vec<&DocSpecsSection> =
            doc.all_sections().into_iter().filter(|s| s.id == section_id).collect();
        if matches.is_empty() {
            return Err(format!("sectionId \"{}\" names no section", section_id));
        }
        if matches.len() > 1 {
            let lines: Vec<String> = matches.iter().map(|s| s.line.to_string()).collect();
            return Err(format!(
                "sectionId \"{}\" names {} sections (lines {})",
                section_id,
                matches.len(),
                lines.join(", ")
            ));
        }

        let mut body_lines: Vec<&str> = body.split('\n').collect();
        while body_lines.first().is_some_and(|l| l.trim().is_empty()) {
            body_lines.remove(0);
        }
        while body_lines.last().is_some_and(|l| l.trim().is_empty()) {
            body_lines.pop();
        }
        let mut fence = MarkdownFenceTracker::new();
        for line in &body_lines {
            if !fence.in_fence() && md_heading_line(line.trim_end()).is_some() {
                return Err(format!(
                    "body contains a heading outside a fenced block: \"{}\"",
                    line
                ));
            }
            fence.feed(line);
        }
        if fence.in_fence() {
            return Err("body leaves a fenced block open".to_string());
        }

        let section = matches[0];
        let lines: Vec<&str> = text.split('\n').collect();
        let start = section.line; // 0-based index of the first body line
        let end = start + section.body_lines.len();
        let mut out: Vec<&str> = Vec::with_capacity(lines.len() + body_lines.len() + 2);
        out.extend_from_slice(&lines[..start]);
        if body_lines.is_empty() {
            out.push("");
        } else {
            out.push("");
            out.extend_from_slice(&body_lines);
            out.push("");
        }
        out.extend_from_slice(&lines[end..]);
        Ok(out.join("\n"))
    }
}

/// The DocSpecs id transform: every run of non-alphanumeric/underscore
/// characters becomes a single `_`.
pub fn docspecs_id_transform(id: &str) -> String {
    let mut out = String::with_capacity(id.len());
    let mut in_run = false;
    for c in id.chars() {
        if c.is_ascii_alphanumeric() || c == '_' {
            out.push(c);
            in_run = false;
        } else if !in_run {
            out.push('_');
            in_run = true;
        }
    }
    out
}

/// A regex pattern check with an optional custom error message (`""` when
/// none).
#[derive(Debug, Clone, Default)]
pub struct DocSpecsPatternCheck {
    pub pattern: String,
    pub error_message: String,
}

impl DocSpecsPatternCheck {
    /// Reports whether `value` matches the check's pattern (`false` when the
    /// pattern does not compile).
    pub fn matches(&self, value: &str) -> bool {
        match DvRegex::compile(&self.pattern) {
            Some(re) => re.is_match(value),
            None => false,
        }
    }
}

/// Occurrence bounds for one subsection type. `max_count == None` means
/// infinite.
#[derive(Debug, Clone, Default)]
pub struct DocSpecsSubsectionRule {
    pub min_count: i64,
    pub max_count: Option<i64>,
}

/// One `section-types` entry of a schema.
#[derive(Debug, Clone, Default)]
pub struct DocSpecsSectionType {
    pub name: String,
    pub prefix: String,
    pub pattern_check: Option<DocSpecsPatternCheck>,
    /// The subsection rules in file order (the other ports iterate insertion
    /// order).
    pub subsection_types: Vec<(String, DocSpecsSubsectionRule)>,
    pub format: String,
    pub text_required: bool,
    pub min_text_length: Option<i64>,
    pub max_text_length: Option<i64>,
    pub description: String,
    pub validation_prompt: String,
}

impl DocSpecsSectionType {
    /// The rule for subsection type `name`, or `None`.
    pub fn subsection_rule(&self, name: &str) -> Option<&DocSpecsSubsectionRule> {
        self.subsection_types
            .iter()
            .find(|(k, _)| k == name)
            .map(|(_, r)| r)
    }
}

/// One field of a `form-types` entry.
#[derive(Debug, Clone, Default)]
pub struct DocSpecsFormField {
    pub name: String,
    pub required: bool,
    pub description: String,
    pub pattern_check: Option<DocSpecsPatternCheck>,
}

/// One `form-types` entry of a schema.
#[derive(Debug, Clone, Default)]
pub struct DocSpecsFormType {
    pub name: String,
    pub fields: Vec<DocSpecsFormField>,
}

/// One `document.sections` slot of a schema.
#[derive(Debug, Clone)]
pub struct DocSpecsDocumentSection {
    pub section_type: String,
    pub optional: bool,
    /// `relative` (the default: in the order of `document: sections:`) or
    /// `any` (anywhere among the root's children; the order check leaves it
    /// out).
    pub position: String,
}

impl Default for DocSpecsDocumentSection {
    fn default() -> Self {
        DocSpecsDocumentSection {
            section_type: String::new(),
            optional: false,
            position: "relative".to_string(),
        }
    }
}

impl DocSpecsDocumentSection {
    /// The [`position`](Self::position) values a document section may take.
    pub const POSITIONS: [&'static str; 2] = ["relative", "any"];

    /// Whether the section may stand anywhere among the root's children.
    pub fn any_position(&self) -> bool {
        self.position == "any"
    }
}

/// Accepts a plain-scalar `"true"` string — the bundled yaml parser keeps
/// plain booleans as strings, matching the other ports' behaviour.
fn dv_is_true(v: Option<&YamlValue>) -> bool {
    matches!(v, Some(YamlValue::Str(s)) if s == "true")
}

/// Coerces a parsed yaml scalar to its string form (`""` for absent/non-scalar).
fn dv_str(v: Option<&YamlValue>) -> String {
    match v {
        Some(YamlValue::Str(s)) => s.clone(),
        Some(YamlValue::Int(n)) => n.to_string(),
        _ => String::new(),
    }
}

/// Returns the value as an int when it is one.
fn dv_int(v: Option<&YamlValue>) -> Option<i64> {
    match v {
        Some(YamlValue::Int(n)) => Some(*n),
        _ => None,
    }
}

const DOCSPECS_SECTION_TYPE_KEYS: [&str; 9] = [
    "prefix",
    "pattern-check-id",
    "subsection-types",
    "format",
    "text-required",
    "min-text-length",
    "max-text-length",
    "description",
    "validation-prompt",
];

/// A loaded `*.docspecs-schema.yaml` schema.
#[derive(Debug, Clone, Default)]
pub struct DocSpecsSchema {
    /// The schema's `title-format`, `""` when absent.
    pub title_format: String,
    /// The section types in file order.
    pub section_types: Vec<DocSpecsSectionType>,
    pub form_types: HashMap<String, DocSpecsFormType>,
    /// The `document.sections` slots in file order.
    pub document_sections: Vec<(String, DocSpecsDocumentSection)>,
    /// SOM §14 warnings for unsupported keys.
    pub warnings: Vec<String>,
}

impl DocSpecsSchema {
    /// The section id embedded in `title_format`, `""` when none
    /// (`docspecsRootIDRE`: `<!--\[([^\]]+)\]-->`, first occurrence anywhere).
    pub fn root_section_id(&self) -> String {
        let s = &self.title_format;
        let mut from = 0;
        while let Some(rel) = s[from..].find("<!--[") {
            let start = from + rel + 5;
            if let Some(close_rel) = s[start..].find(']') {
                let close = start + close_rel;
                if close > start && s[close..].starts_with("]-->") {
                    return s[start..close].to_string();
                }
            }
            from = from + rel + 1;
        }
        String::new()
    }

    /// The section type named `name`, or `None`.
    pub fn section_type_named(&self, name: &str) -> Option<&DocSpecsSectionType> {
        self.section_types.iter().find(|t| t.name == name)
    }

    /// The `document.sections` slot keyed `key`, or `None`.
    pub fn document_section(&self, key: &str) -> Option<&DocSpecsDocumentSection> {
        self.document_sections
            .iter()
            .find(|(k, _)| k == key)
            .map(|(_, s)| s)
    }

    /// Loads a schema from YAML text. Unknown keys warn; a non-map root
    /// returns an error (the other ports' throw).
    pub fn from_yaml_text(text: &str) -> Result<DocSpecsSchema, String> {
        let parsed = yaml_parse(text);
        let data = match &parsed {
            YamlValue::Map(m) => m,
            _ => return Err("docspecs schema must be a YAML map".to_string()),
        };
        if data.is_empty() && !text.trim().is_empty() && !text.contains(':') {
            return Err("docspecs schema must be a YAML map".to_string());
        }
        let mut schema = DocSpecsSchema::default();
        for (k, v) in data.iter() {
            match k.as_str() {
                "title-format" => schema.title_format = dv_str(Some(v)),
                "section-types" => schema.load_section_types(v),
                "form-types" => schema.load_form_types(v),
                "document" => schema.load_document(v)?,
                "schema" | "version" | "name" | "description" => {
                    // informational keys — accepted, unused
                }
                _ => schema
                    .warnings
                    .push(format!("unsupported top-level schema key \"{}\" ignored", k)),
            }
        }
        Ok(schema)
    }

    fn load_section_types(&mut self, node: &YamlValue) {
        let m = match node.as_map() {
            Some(m) => m,
            None => return,
        };
        for (name, raw_v) in m.iter() {
            let raw = match raw_v.as_map() {
                Some(r) => r,
                None => continue,
            };
            let mut subs: Vec<(String, DocSpecsSubsectionRule)> = Vec::new();
            if let Some(sub_node) = raw.get("subsection-types").and_then(|v| v.as_map()) {
                for (sub_name, sub_v) in sub_node.iter() {
                    let mut min_count = 0;
                    let mut max_count = None;
                    if let Some(sub_raw) = sub_v.as_map() {
                        if let Some(n) = dv_int(sub_raw.get("min-count")) {
                            min_count = n;
                        }
                        if let Some(n) = dv_int(sub_raw.get("max-count")) {
                            max_count = Some(n);
                        }
                    }
                    subs.push((
                        sub_name.clone(),
                        DocSpecsSubsectionRule {
                            min_count,
                            max_count,
                        },
                    ));
                }
            }
            for key in raw.keys() {
                if !DOCSPECS_SECTION_TYPE_KEYS.contains(&key) {
                    self.warnings.push(format!(
                        "unsupported key \"{}\" on section-type \"{}\" ignored",
                        key, name
                    ));
                }
            }
            let prefix = if raw.has("prefix") {
                dv_str(raw.get("prefix"))
            } else {
                docspecs_id_transform(&name.to_uppercase())
            };
            self.section_types.push(DocSpecsSectionType {
                name: name.clone(),
                prefix,
                pattern_check: docspecs_pattern_check(raw.get("pattern-check-id")),
                subsection_types: subs,
                format: dv_str(raw.get("format")),
                text_required: dv_is_true(raw.get("text-required")),
                min_text_length: dv_int(raw.get("min-text-length")),
                max_text_length: dv_int(raw.get("max-text-length")),
                description: dv_str(raw.get("description")),
                validation_prompt: dv_str(raw.get("validation-prompt")),
            });
        }
    }

    fn load_form_types(&mut self, node: &YamlValue) {
        let m = match node.as_map() {
            Some(m) => m,
            None => return,
        };
        for (name, raw_v) in m.iter() {
            let raw = match raw_v.as_map() {
                Some(r) => r,
                None => continue,
            };
            for key in raw.keys() {
                if key != "fields" {
                    self.warnings.push(format!(
                        "unsupported key \"{}\" on form-type \"{}\" ignored",
                        key, name
                    ));
                }
            }
            let mut fields: Vec<DocSpecsFormField> = Vec::new();
            if let Some(fields_node) = raw.get("fields").and_then(|v| v.as_seq()) {
                for f in fields_node {
                    let fm = match f.as_map() {
                        Some(fm) => fm,
                        None => continue,
                    };
                    fields.push(DocSpecsFormField {
                        name: dv_str(fm.get("fieldname")),
                        required: dv_is_true(fm.get("required")),
                        description: dv_str(fm.get("description")),
                        pattern_check: docspecs_pattern_check(fm.get("pattern-check")),
                    });
                }
            }
            self.form_types.insert(
                name.clone(),
                DocSpecsFormType {
                    name: name.clone(),
                    fields,
                },
            );
        }
    }

    /// Loads `document:`; a slot `position` other than `relative` / `any` is
    /// an error (the other ports' throw).
    fn load_document(&mut self, node: &YamlValue) -> Result<(), String> {
        let m = match node.as_map() {
            Some(m) => m,
            None => return Ok(()),
        };
        for (k, v) in m.iter() {
            if k == "sections" {
                let sections = match v.as_map() {
                    Some(s) => s,
                    None => continue,
                };
                for (s_key, s_v) in sections.iter() {
                    let mut section_type = s_key.clone();
                    let mut optional = false;
                    let mut position = "relative".to_string();
                    if let Some(s_raw) = s_v.as_map() {
                        if s_raw.has("section-type") {
                            section_type = dv_str(s_raw.get("section-type"));
                        }
                        optional = dv_is_true(s_raw.get("optional"));
                        if s_raw.has("position") {
                            position = dv_str(s_raw.get("position"));
                            if !DocSpecsDocumentSection::POSITIONS.contains(&position.as_str()) {
                                return Err(format!(
                                    "document section \"{}\": position \"{}\" is not one of \
                                     relative, any",
                                    s_key, position
                                ));
                            }
                        }
                    }
                    self.document_sections.push((
                        s_key.clone(),
                        DocSpecsDocumentSection {
                            section_type,
                            optional,
                            position,
                        },
                    ));
                }
            } else if k != "name" && k != "description" {
                self.warnings
                    .push(format!("unsupported document key \"{}\" ignored", k));
            }
        }
        Ok(())
    }

    /// Resolves a section id to its section-type by first-startsWith prefix
    /// match over [`docspecs_id_transform`]'d ids.
    pub fn resolve_section_type(&self, id: &str) -> Option<&DocSpecsSectionType> {
        let transformed = docspecs_id_transform(id);
        self.section_types
            .iter()
            .find(|t| transformed.starts_with(&t.prefix))
    }
}

fn docspecs_pattern_check(node: Option<&YamlValue>) -> Option<DocSpecsPatternCheck> {
    let node = node?;
    if let Some(m) = node.as_map() {
        return Some(DocSpecsPatternCheck {
            pattern: dv_str(m.get("pattern")),
            error_message: dv_str(m.get("error-message")),
        });
    }
    Some(DocSpecsPatternCheck {
        pattern: dv_str(Some(node)),
        error_message: String::new(),
    })
}

/// A never-fail-fast validator of a parsed document against a schema.
///
/// It reads the reading view beside the `Field:` layout (DocSpecs
/// specification, List Bodies): form tables, `refs` lines and `records`
/// tables as a list's virtual items, section tables at their rows, and the
/// styled-div headings [`parse_docspecs_document`] parses.
pub struct DocSpecsValidator {
    pub schema: DocSpecsSchema,
    /// The documents are TomSpecs renditions: the reading notation is then
    /// scanned value by value (a form field's value apart from the next), and
    /// a div without a class and an unregistered kind are reported too.
    pub tom_specs: bool,
}

impl DocSpecsValidator {
    /// Binds a schema to the validator.
    pub fn new(schema: DocSpecsSchema) -> DocSpecsValidator {
        DocSpecsValidator {
            schema,
            tom_specs: false,
        }
    }

    /// Binds a schema to a validator of TomSpecs renditions (`tom_specs`
    /// true) or of plain DocSpecs documents (false, as [`Self::new`]).
    pub fn with_tom_specs(schema: DocSpecsSchema, tom_specs: bool) -> DocSpecsValidator {
        DocSpecsValidator { schema, tom_specs }
    }

    /// Parses + validates in one step.
    pub fn validate_markdown(&self, markdown: &str) -> Vec<DocSpecsViolation> {
        self.validate(&parse_docspecs_document(markdown))
    }

    /// Validates a parsed document, returning ALL findings (never fail-fast).
    pub fn validate(&self, doc: &DocSpecsDocument) -> Vec<DocSpecsViolation> {
        let mut v = doc.violations.clone();
        if doc.sections.is_empty() {
            v.push(DocSpecsViolation {
                rule: DOCSPECS_RULE_FORMAT_MISMATCH.to_string(),
                line: 1,
                message: "document has no root heading".to_string(),
                section_id: String::new(),
                path: String::new(),
            });
            return v;
        }
        let root = &doc.sections[0];
        let root_id = self.schema.root_section_id();
        if !root_id.is_empty() && root.id != root_id {
            v.push(DocSpecsViolation {
                rule: DOCSPECS_RULE_FORMAT_MISMATCH.to_string(),
                line: root.line,
                message: format!(
                    "root heading id \"{}\" does not match the schema title-format id \"{}\"",
                    root.id, root_id
                ),
                section_id: root.id.clone(),
                path: String::new(),
            });
        }
        for extra in &doc.sections[1..] {
            v.push(DocSpecsViolation {
                rule: DOCSPECS_RULE_UNKNOWN_SECTION.to_string(),
                line: extra.line,
                message: "unexpected additional top-level section".to_string(),
                section_id: extra.id.clone(),
                path: String::new(),
            });
        }
        let mut root_node = DvNode::of(root);
        self.validate_document_sections(&mut root_node, &mut v);
        self.validate_notation(doc, &mut v);
        Self::validate_id_paths(&doc.sections, &mut v);
        v
    }

    /// The reading notation of every section's own body: one value per
    /// section, and in a TomSpecs rendition one per form field of a
    /// form-formatted section (its preamble included).
    fn validate_notation(&self, doc: &DocSpecsDocument, v: &mut Vec<DocSpecsViolation>) {
        for section in doc.all_sections() {
            for (first, lines) in self.notation_values(section) {
                let scan = scan_notation(&lines.join("\n"), self.tom_specs);
                for f in &scan.findings {
                    v.push(DocSpecsViolation {
                        rule: f.code.as_str().to_string(),
                        line: section.body_start_line() + first + f.line - 1,
                        message: f.message.clone(),
                        section_id: section.id.clone(),
                        path: String::new(),
                    });
                }
            }
        }
    }

    /// The values of `section`'s own body as (index of the first line,
    /// lines).
    fn notation_values<'a>(&self, section: &'a DocSpecsSection) -> Vec<(usize, &'a [String])> {
        let body = &section.body_lines[..];
        let form = if self.tom_specs && !section.id.is_empty() {
            self.schema
                .resolve_section_type(&section.id)
                .filter(|t| !t.format.is_empty())
                .and_then(|t| self.schema.form_types.get(&t.format))
        } else {
            None
        };
        let Some(form) = form else {
            return vec![(0, body)];
        };
        let labels: Vec<String> = form.fields.iter().map(|f| f.name.to_lowercase()).collect();
        let mut values = Vec::new();
        let mut fence = MarkdownFenceTracker::new();
        let mut first = 0;
        for (i, line) in body.iter().enumerate() {
            if !fence.in_fence() && i > first {
                if let Some((label, _)) = dv_field_label(line) {
                    if labels.contains(&label.to_lowercase()) {
                        values.push((first, &body[first..i]));
                        first = i;
                    }
                }
            }
            fence.feed(line);
        }
        values.push((first, &body[first..]));
        values
    }

    /// Every section's id path (the ids from the root down to it) is unique:
    /// a section whose id repeats an earlier sibling's is a
    /// [`DOCSPECS_RULE_DUPLICATE_ID_PATH`]. Its descendants repeat paths only
    /// through it and are not reported again. Sections without an id are
    /// skipped (already [`DOCSPECS_RULE_MALFORMED_HEADING`]); their children
    /// are walked. Depth-first, source order.
    fn validate_id_paths(sections: &[DocSpecsSection], v: &mut Vec<DocSpecsViolation>) {
        let mut seen: HashSet<&str> = HashSet::new();
        for s in sections {
            if !s.id.is_empty() && !seen.insert(s.id.as_str()) {
                v.push(DocSpecsViolation {
                    rule: DOCSPECS_RULE_DUPLICATE_ID_PATH.to_string(),
                    line: s.line,
                    message: format!(
                        "section id \"{}\" repeats a sibling's id, so its id path is not unique",
                        s.id
                    ),
                    section_id: s.id.clone(),
                    path: String::new(),
                });
                continue;
            }
            Self::validate_id_paths(&s.children, v);
        }
    }

    /// The order check of one root child: its slot is the first of its type
    /// at or after the last slot taken, else the first of its type anywhere;
    /// a slot before the last one taken is
    /// [`DOCSPECS_RULE_SECTION_OUT_OF_ORDER`]. Answers the last slot taken
    /// afterwards (`-1` before any).
    fn check_order(
        child: &DvNode<'_>,
        type_name: &str,
        order: &[Option<&str>],
        last_index: i64,
        v: &mut Vec<DocSpecsViolation>,
    ) -> i64 {
        let start = last_index.max(0) as usize;
        let index = (start..order.len())
            .find(|&i| order[i] == Some(type_name))
            .or_else(|| order.iter().position(|t| *t == Some(type_name)));
        let index = match index {
            Some(i) => i as i64,
            None => return last_index,
        };
        if index < last_index {
            v.push(DocSpecsViolation {
                rule: DOCSPECS_RULE_SECTION_OUT_OF_ORDER.to_string(),
                line: child.line,
                message: format!(
                    "section \"{}\" (type \"{}\") stands out of the order of the document sections",
                    child.id, type_name
                ),
                section_id: child.id.clone(),
                path: String::new(),
            });
            return last_index;
        }
        index
    }

    fn resolve_child<'s>(
        &'s self,
        section: &DvNode<'s>,
        v: &mut Vec<DocSpecsViolation>,
    ) -> Option<&'s DocSpecsSectionType> {
        if section.ty.is_some() {
            return section.ty; // a virtual list item: the schema's type.
        }
        if section.id.is_empty() {
            return None; // already reported as MALFORMED_HEADING by the parse.
        }
        let t = self.schema.resolve_section_type(&section.id);
        if t.is_none() {
            v.push(DocSpecsViolation {
                rule: DOCSPECS_RULE_UNKNOWN_SECTION.to_string(),
                line: section.line,
                message: format!(
                    "section id \"{}\" resolves to no section-type of the schema",
                    section.id
                ),
                section_id: section.id.clone(),
                path: String::new(),
            });
        }
        t
    }

    /// Root children must occupy `document: sections:` slots, in their order
    /// (a `position: any` slot's type stands anywhere); required slots must be
    /// present. A section table in the root's body rebuilds root children as
    /// virtual sections first.
    fn validate_document_sections<'s>(
        &'s self,
        root: &mut DvNode<'s>,
        v: &mut Vec<DocSpecsViolation>,
    ) {
        // Occurrences per section-type name.
        let mut counts: HashMap<&str, i64> = HashMap::new();
        let slot_types: HashSet<&str> = self
            .schema
            .document_sections
            .iter()
            .map(|(_, slot)| slot.section_type.as_str())
            .collect();
        // The slots' order (a `position: any` slot as `None`) and the types
        // that may stand anywhere.
        let anywhere: HashSet<&str> = self
            .schema
            .document_sections
            .iter()
            .filter(|(_, slot)| slot.any_position())
            .map(|(_, slot)| slot.section_type.as_str())
            .collect();
        let order: Vec<Option<&str>> = self
            .schema
            .document_sections
            .iter()
            .map(|(_, slot)| {
                if slot.any_position() {
                    None
                } else {
                    Some(slot.section_type.as_str())
                }
            })
            .collect();
        self.expand_section_tables(root, &|t| slot_types.contains(t.name.as_str()), v);
        let mut last_index: i64 = -1;
        for child in root.children.iter_mut() {
            let t = match self.resolve_child(child, v) {
                Some(t) => t,
                None => continue,
            };
            if !slot_types.contains(t.name.as_str()) {
                v.push(DocSpecsViolation {
                    rule: DOCSPECS_RULE_UNKNOWN_SECTION.to_string(),
                    line: child.line,
                    message: format!(
                        "section-type \"{}\" is not a top-level document section",
                        t.name
                    ),
                    section_id: child.id.clone(),
                    path: String::new(),
                });
                continue;
            }
            if !anywhere.contains(t.name.as_str()) {
                last_index = Self::check_order(child, t.name.as_str(), &order, last_index, v);
            }
            *counts.entry(t.name.as_str()).or_insert(0) += 1;
            self.validate_section(child, t, v);
        }
        for (slot_key, slot) in &self.schema.document_sections {
            if !slot.optional && counts.get(slot.section_type.as_str()).copied().unwrap_or(0) == 0
            {
                v.push(DocSpecsViolation {
                    rule: DOCSPECS_RULE_MISSING_REQUIRED_SECTION.to_string(),
                    line: root.line,
                    message: format!(
                        "required document section \"{}\" (type \"{}\") is missing",
                        slot_key, slot.section_type
                    ),
                    section_id: slot_key.clone(),
                    path: String::new(),
                });
            }
        }
    }

    fn validate_section<'s>(
        &'s self,
        section: &mut DvNode<'s>,
        t: &'s DocSpecsSectionType,
        v: &mut Vec<DocSpecsViolation>,
    ) {
        if let Some(pc) = &t.pattern_check {
            if !section.id.is_empty() && !pc.matches(&section.id) {
                let message = if pc.error_message.is_empty() {
                    format!(
                        "section id \"{}\" does not match pattern \"{}\"",
                        section.id, pc.pattern
                    )
                } else {
                    pc.error_message.clone()
                };
                v.push(DocSpecsViolation {
                    rule: DOCSPECS_RULE_ID_PATTERN_MISMATCH.to_string(),
                    line: section.line,
                    message,
                    section_id: section.id.clone(),
                    path: String::new(),
                });
            }
        }
        // List bodies and section tables become virtual sections before
        // anything is counted or checked (DocSpecs specification, List Bodies).
        self.expand_section_tables(section, &|ct| t.subsection_rule(&ct.name).is_some(), v);
        self.expand_list_body(section, t, v);
        self.validate_text(section, t, v);
        self.validate_format(section, t, v);
        // Occurrences per subsection type name.
        let mut counts: HashMap<String, i64> = HashMap::new();
        for child in section.children.iter_mut() {
            let child_type = match self.resolve_child(child, v) {
                Some(ct) => ct,
                None => continue,
            };
            if t.subsection_rule(&child_type.name).is_none() {
                v.push(DocSpecsViolation {
                    rule: DOCSPECS_RULE_UNKNOWN_SECTION.to_string(),
                    line: child.line,
                    message: format!(
                        "section-type \"{}\" is not an allowed subsection of \"{}\"",
                        child_type.name, t.name
                    ),
                    section_id: child.id.clone(),
                    path: String::new(),
                });
                continue;
            }
            *counts.entry(child_type.name.clone()).or_insert(0) += 1;
            self.validate_section(child, child_type, v);
        }
        // The offending section is the CONTAINER, not the absent child: a
        // cardinality breach has no child occurrence to point at, and `sub_key`
        // is a schema type name, not a section id. Dart is the golden reference.
        for (sub_key, rule) in &t.subsection_types {
            let count = counts.get(sub_key).copied().unwrap_or(0);
            if count < rule.min_count {
                if count == 0 {
                    v.push(DocSpecsViolation {
                        rule: DOCSPECS_RULE_MISSING_REQUIRED_SECTION.to_string(),
                        line: section.line,
                        message: format!(
                            "required subsection \"{}\" of \"{}\" is missing",
                            sub_key, t.name
                        ),
                        section_id: section.id.clone(),
                        path: String::new(),
                    });
                } else {
                    v.push(DocSpecsViolation {
                        rule: DOCSPECS_RULE_TOO_FEW_ITEMS.to_string(),
                        line: section.line,
                        message: format!(
                            "subsection \"{}\" occurs {} time(s), minimum is {}",
                            sub_key, count, rule.min_count
                        ),
                        section_id: section.id.clone(),
                        path: String::new(),
                    });
                }
            }
            if let Some(max) = rule.max_count {
                if count > max {
                    v.push(DocSpecsViolation {
                        rule: DOCSPECS_RULE_TOO_MANY_ITEMS.to_string(),
                        line: section.line,
                        message: format!(
                            "subsection \"{}\" occurs {} time(s), maximum is {}",
                            sub_key, count, max
                        ),
                        section_id: section.id.clone(),
                        path: String::new(),
                    });
                }
            }
        }
    }

    fn validate_text(
        &self,
        section: &DvNode<'_>,
        t: &DocSpecsSectionType,
        v: &mut Vec<DocSpecsViolation>,
    ) {
        if !t.format.is_empty() && self.schema.form_types.contains_key(&t.format) {
            return; // form sections carry fields, not body text.
        }
        // A list body or section table already read is blanked in the body,
        // so a container written with one counts as empty
        // (`max-text-length: 0`); the rendition's marker and generated block
        // are no text either. An empty body passes the length bounds: only
        // `text-required` asks for text.
        let text = dv_without_generated_text(&section.text());
        if t.text_required && text.is_empty() {
            v.push(DocSpecsViolation {
                rule: DOCSPECS_RULE_TEXT_REQUIRED.to_string(),
                line: section.line,
                message: "section requires body text but has none".to_string(),
                section_id: section.id.clone(),
                path: String::new(),
            });
            return;
        }
        if text.is_empty() {
            return;
        }
        let length = text.chars().count() as i64;
        let min_len = t.min_text_length;
        let max_len = t.max_text_length;
        if min_len.is_some_and(|m| length < m) || max_len.is_some_and(|m| length > m) {
            let min_str = match min_len {
                Some(m) => m.to_string(),
                None => "0".to_string(),
            };
            let max_str = match max_len {
                Some(m) => m.to_string(),
                None => "\u{221E}".to_string(),
            };
            v.push(DocSpecsViolation {
                rule: DOCSPECS_RULE_TEXT_LENGTH_OUT.to_string(),
                line: section.line,
                message: format!(
                    "body text length {} is outside [{}, {}]",
                    length, min_str, max_str
                ),
                section_id: section.id.clone(),
                path: String::new(),
            });
        }
    }

    fn validate_format(
        &self,
        section: &DvNode<'_>,
        t: &DocSpecsSectionType,
        v: &mut Vec<DocSpecsViolation>,
    ) {
        // Values a section table or list body gave a section the schema
        // declares no form for are virtual body lines, counted in its text
        // (`DvNode::text`).
        let format = &t.format;
        if format.is_empty() {
            return;
        }
        if let Some(form) = self.schema.form_types.get(format) {
            self.validate_form(section, form, v);
            return;
        }
        let mut fence = MarkdownFenceTracker::new();
        let mut saw_fence = false;
        for raw in &section.body {
            fence.feed(raw);
            if fence.in_fence() {
                saw_fence = true;
            }
        }
        if !saw_fence {
            v.push(DocSpecsViolation {
                rule: DOCSPECS_RULE_FORMAT_MISMATCH.to_string(),
                line: section.line,
                message: format!(
                    "section format \"{}\" demands a fenced code block, but the body contains none",
                    format
                ),
                section_id: section.id.clone(),
                path: String::new(),
            });
        }
    }

    /// Reads the section body in the DocSpecs plain-text form format
    /// (`FieldName: value`, case-insensitive labels, continuation lines) and
    /// its form tables (`TomSpecField | Value`), takes the values a section
    /// table or list body gave the section, and checks required fields and
    /// field pattern-checks. A field given twice keeps its first occurrence
    /// and reports the second ([`DOCSPECS_RULE_MALFORMED_BLOCK`]): a `Field:`
    /// label counts as given even with an empty value, a row only with a
    /// value. A row naming no field is [`DOCSPECS_RULE_UNKNOWN_FIELD`]. Text
    /// before the first recognised label is tolerated here (the binding parse
    /// reports it).
    fn validate_form(
        &self,
        section: &DvNode<'_>,
        form: &DocSpecsFormType,
        v: &mut Vec<DocSpecsViolation>,
    ) {
        // Lowered name → field.
        let mut by_lower: HashMap<String, &DocSpecsFormField> = HashMap::new();
        for f in &form.fields {
            by_lower.insert(f.name.to_lowercase(), f);
        }
        // Every occurrence of a field, from a `Field:` label or a row.
        let mut occurrences: Vec<DvFieldValue> = Vec::new();
        // The open `Field:` label: its field, line and value lines.
        let mut current: Option<(String, usize, Vec<String>)> = None;
        fn flush(current: &mut Option<(String, usize, Vec<String>)>, out: &mut Vec<DvFieldValue>) {
            if let Some((label, line, lines)) = current.take() {
                out.push(DvFieldValue {
                    label,
                    value: lines.join("\n").trim().to_string(),
                    line,
                    from_label: true,
                });
            }
        }
        let body = &section.body;
        let start_line = section.body_start_line();
        let mut fence = MarkdownFenceTracker::new();
        let mut i = 0;
        while i < body.len() {
            let line = &body[i];
            if !fence.in_fence() {
                if md_layout_table_header(line) == Some(false) {
                    // A form table ends the open field; its rows are fields.
                    flush(&mut current, &mut occurrences);
                    let table = dv_read_table(body, i, start_line, &section.id, v);
                    for (index, cells) in &table.rows {
                        occurrences.push(DvFieldValue {
                            label: cells[0].clone(),
                            value: dv_cell_value(&cells[1]),
                            line: start_line + index,
                            from_label: false,
                        });
                    }
                    i = table.end;
                    continue;
                }
                if let Some((label, first)) = dv_field_label(line) {
                    if let Some(field) = by_lower.get(&label.to_lowercase()) {
                        flush(&mut current, &mut occurrences);
                        current = Some((field.name.clone(), start_line + i, vec![first.to_string()]));
                        fence.feed(line);
                        i += 1;
                        continue;
                    }
                }
            }
            if let Some((_, _, lines)) = current.as_mut() {
                lines.push(line.clone());
            }
            fence.feed(line);
            i += 1;
        }
        flush(&mut current, &mut occurrences);
        occurrences.extend(section.values.iter().cloned());
        // Source order decides which occurrence is the first; values from a
        // parent's section table stand above the section's own body. The sort
        // is stable, so occurrences of one line keep their order.
        occurrences.sort_by_key(|o| o.line);

        // Field name → value; field name → 1-based line of its occurrence.
        let mut values: HashMap<String, String> = HashMap::new();
        let mut field_lines: HashMap<String, usize> = HashMap::new();
        let mut given: HashSet<String> = HashSet::new();
        for o in &occurrences {
            let Some(field) = by_lower.get(&o.label.to_lowercase()) else {
                v.push(DocSpecsViolation {
                    rule: DOCSPECS_RULE_UNKNOWN_FIELD.to_string(),
                    line: o.line,
                    message: format!("row \"{}\" names no field of \"{}\"", o.label, form.name),
                    section_id: section.id.clone(),
                    path: String::new(),
                });
                continue;
            };
            if !o.from_label && o.value.is_empty() {
                continue;
            }
            if given.contains(&field.name) {
                v.push(DocSpecsViolation {
                    rule: DOCSPECS_RULE_MALFORMED_BLOCK.to_string(),
                    line: o.line,
                    message: format!("field \"{}\" given twice", field.name),
                    section_id: section.id.clone(),
                    path: String::new(),
                });
                continue;
            }
            given.insert(field.name.clone());
            field_lines.insert(field.name.clone(), o.line);
            if !o.value.is_empty() {
                values.insert(field.name.clone(), o.value.clone());
            }
        }

        for field in &form.fields {
            let value = values.get(&field.name).map(String::as_str).unwrap_or("");
            if field.required && value.is_empty() {
                v.push(DocSpecsViolation {
                    rule: DOCSPECS_RULE_MISSING_REQUIRED_FIELD.to_string(),
                    line: section.line,
                    message: format!(
                        "required form field \"{}\" of \"{}\" is missing",
                        field.name, form.name
                    ),
                    section_id: section.id.clone(),
                    path: String::new(),
                });
                continue;
            }
            if let Some(pc) = &field.pattern_check {
                if !value.is_empty() && !pc.matches(value) {
                    let line = field_lines.get(&field.name).copied().unwrap_or(section.line);
                    let message = if pc.error_message.is_empty() {
                        format!(
                            "form field \"{}\" does not match pattern \"{}\"",
                            field.name, pc.pattern
                        )
                    } else {
                        pc.error_message.clone()
                    };
                    v.push(DocSpecsViolation {
                        rule: DOCSPECS_RULE_FIELD_PATTERN_MISMATCH.to_string(),
                        line,
                        message,
                        section_id: section.id.clone(),
                        path: String::new(),
                    });
                }
            }
        }
    }

    // --- Tables and list bodies (DocSpecs specification, List Bodies) -------

    /// Reads every section table of `node`'s body (header
    /// `Section | TomSpecField | Value`): each row's `Section` cell names a
    /// child — by its id relative to `node`, a list item as
    /// `<LIST> / <ITEM>`, an empty cell the row above's — and its
    /// `TomSpecField` / `Value` cells become that child's form values. A child
    /// without a heading becomes a virtual section; one whose id resolves to
    /// no type `allowed` under `node` is [`DOCSPECS_RULE_UNKNOWN_SECTION`] at
    /// the row, and its rows are skipped. The table's lines are blanked.
    fn expand_section_tables<'s>(
        &'s self,
        node: &mut DvNode<'s>,
        allowed: &dyn Fn(&DocSpecsSectionType) -> bool,
        v: &mut Vec<DocSpecsViolation>,
    ) {
        let first_line = node.body_start_line();
        let mut fence = MarkdownFenceTracker::new();
        let mut i = 0;
        while i < node.body.len() {
            if fence.in_fence() || md_layout_table_header(&node.body[i]) != Some(true) {
                fence.feed(&node.body[i]);
                i += 1;
                continue;
            }
            let table = dv_read_table(&node.body, i, first_line, &node.id, v);
            // The row's child: its index under `node`, and an item's index
            // under that child.
            let mut target: Option<(usize, Option<usize>)> = None;
            let mut skip = false;
            for (index, cells) in &table.rows {
                let at = first_line + index;
                let cell = dv_cell_id(&cells[0]);
                if !cell.is_empty() {
                    target = self.section_table_target(node, &cell, allowed, at);
                    skip = target.is_none();
                    if target.is_none() {
                        v.push(DocSpecsViolation {
                            rule: DOCSPECS_RULE_UNKNOWN_SECTION.to_string(),
                            line: at,
                            message: format!(
                                "section-table row names no child section of \"{}\"",
                                node.id
                            ),
                            section_id: cell,
                            path: String::new(),
                        });
                        continue;
                    }
                } else if skip {
                    continue; // the rejected child's further rows
                }
                let Some((a, b)) = target else {
                    v.push(DocSpecsViolation {
                        rule: DOCSPECS_RULE_UNKNOWN_SECTION.to_string(),
                        line: at,
                        message: "section-table row names no section".to_string(),
                        section_id: node.id.clone(),
                        path: String::new(),
                    });
                    continue;
                };
                let holder = match b {
                    None => &mut node.children[a],
                    Some(b) => &mut node.children[a].children[b],
                };
                holder.values.push(DvFieldValue {
                    label: cells[1].clone(),
                    value: dv_cell_value(&cells[2]),
                    line: at,
                    from_label: false,
                });
            }
            for line in &mut node.body[i..table.end] {
                line.clear();
            }
            i = table.end;
        }
    }

    /// The child a section-table `Section` cell names under `node`: a child
    /// section by its id, or `<LIST> / <ITEM>` — an item of a child list. A
    /// child or item without a heading is created as a virtual section when
    /// its id resolves to a type allowed where it stands; `None` otherwise.
    fn section_table_target<'s>(
        &'s self,
        node: &mut DvNode<'s>,
        cell: &str,
        allowed: &dyn Fn(&DocSpecsSectionType) -> bool,
        line: usize,
    ) -> Option<(usize, Option<usize>)> {
        let parts = dv_split_cell_parts(cell);
        if parts.len() > 2 {
            return None;
        }
        let first = self.table_child(node, &parts[0], allowed, line)?;
        if parts.len() == 1 {
            return Some((first, None));
        }
        let list_type = node.children[first]
            .ty
            .or_else(|| self.schema.resolve_section_type(&parts[0]))?;
        let second = self.table_child(
            &mut node.children[first],
            &parts[1],
            &|t| list_type.subsection_rule(&t.name).is_some(),
            line,
        )?;
        Some((first, Some(second)))
    }

    /// The index of `parent`'s child with `id`, created virtual when `ok`
    /// allows its type.
    fn table_child<'s>(
        &'s self,
        parent: &mut DvNode<'s>,
        id: &str,
        ok: &dyn Fn(&DocSpecsSectionType) -> bool,
        line: usize,
    ) -> Option<usize> {
        if let Some(i) = parent.children.iter().position(|c| c.id == id) {
            return Some(i);
        }
        let t = self.schema.resolve_section_type(id)?;
        if !ok(t) {
            return None;
        }
        parent.children.push(DvNode::new(id.to_string(), line, None));
        Some(parent.children.len() - 1)
    }

    /// A list container's body: one `refs` div (a reference line) or one
    /// `records` div (a record table) stands for its items when the container
    /// has no item heading; the items become virtual sections of the
    /// container's one subsection type, and the div's lines are blanked.
    fn expand_list_body<'s>(
        &'s self,
        node: &mut DvNode<'s>,
        t: &'s DocSpecsSectionType,
        v: &mut Vec<DocSpecsViolation>,
    ) {
        let mut fence = MarkdownFenceTracker::new();
        for i in 0..node.body.len() {
            let kind = if fence.in_fence() {
                None
            } else {
                md_list_div_open(&node.body[i])
            };
            let Some(kind) = kind else {
                fence.feed(&node.body[i]);
                continue;
            };
            let at = node.body_start_line() + i;
            let Some(close) = (i + 1..node.body.len()).find(|&k| md_div_close_line(&node.body[k]))
            else {
                // Its lines stay text.
                dv_malformed(&node.id, at, format!("unclosed {} fence", kind), v);
                return;
            };
            let lead = dv_generated_lead(&node.body);
            let beside_text = (lead..node.body.len())
                .any(|k| (k < i || k > close) && !node.body[k].trim().is_empty());
            let has_items = !node.children.is_empty();
            let inner: Vec<String> = node.body[i + 1..close].to_vec();
            for line in &mut node.body[i..=close] {
                line.clear();
            }
            if beside_text || has_items {
                let what = if has_items { "item headings" } else { "other text" };
                dv_malformed(
                    &node.id,
                    at,
                    format!("a {} div beside {} in a list container", kind, what),
                    v,
                );
                return;
            }
            let item_type = if t.subsection_types.len() == 1 {
                self.schema.section_type_named(&t.subsection_types[0].0)
            } else {
                None
            };
            let Some(item_type) = item_type else {
                dv_malformed(
                    &node.id,
                    at,
                    format!("a {} div in a section that is not a list container", kind),
                    v,
                );
                return;
            };
            if kind == "refs" {
                self.refs_items(node, item_type, &inner, at);
            } else {
                self.record_items(node, item_type, &inner, at, v);
            }
            return;
        }
    }

    fn form_of(&self, t: Option<&DocSpecsSectionType>) -> Option<&DocSpecsFormType> {
        let t = t?;
        if t.format.is_empty() {
            return None;
        }
        self.schema.form_types.get(&t.format)
    }

    /// The one-field form a `refs` item of `item_type` holds its reference
    /// in, with the virtual child type holding it: the type's own form, else
    /// the form of its one subsection type that has one (the item's virtual
    /// child then carries the value); `None` when the schema gives none. A
    /// record table reads the type's own form only ([`Self::record_items`]).
    fn refs_form<'s>(
        &'s self,
        item_type: &'s DocSpecsSectionType,
    ) -> Option<(&'s DocSpecsFormType, Option<&'s DocSpecsSectionType>)> {
        if let Some(own) = self.form_of(Some(item_type)) {
            if own.fields.len() == 1 {
                return Some((own, None));
            }
        }
        let mut found = None;
        for (name, _) in &item_type.subsection_types {
            let sub = self.schema.section_type_named(name);
            if let Some(f) = self.form_of(sub) {
                if f.fields.len() == 1 {
                    if found.is_some() {
                        return None; // more than one candidate
                    }
                    found = Some((f, sub));
                }
            }
        }
        found
    }

    /// A `refs` div: its text split on commas and whitespace into ids, a link
    /// counting as its link text; item `<n>` gets the positional id (the
    /// container's id with `-LST` replaced by `-<n>`, else `<id>-<n>`) and
    /// the virtual body line `<Label>: <id>`. Without a one-field form in the
    /// schema the reference is the item's virtual body line; nothing in the
    /// schema checks it further.
    fn refs_items<'s>(
        &'s self,
        node: &mut DvNode<'s>,
        item_type: &'s DocSpecsSectionType,
        inner: &[String],
        at: usize,
    ) {
        let target = self.refs_form(item_type);
        let stem = node.id.strip_suffix("-LST").unwrap_or(&node.id).to_string();
        let label = target
            .map(|(form, _)| form.fields[0].name.clone())
            .unwrap_or_default();
        let joined = inner.join(" ");
        let mut n = 0;
        for token in joined.split(|c: char| c == ',' || c.is_whitespace()) {
            if token.is_empty() {
                continue;
            }
            n += 1;
            let id = md_find_link_text(token).unwrap_or(token).to_string();
            let holder = dv_add_item(
                node,
                item_type,
                target.and_then(|(_, child)| child),
                format!("{}-{}", stem, n),
                at,
            );
            holder.values.push(DvFieldValue {
                label: label.clone(),
                value: id,
                line: at,
                from_label: false,
            });
        }
    }

    /// A `records` div: one table, `Id` first, `Title` optionally second,
    /// then field names of the item's form; each row one virtual item in row
    /// order.
    fn record_items<'s>(
        &'s self,
        node: &mut DvNode<'s>,
        item_type: &'s DocSpecsSectionType,
        inner: &[String],
        at: usize,
        v: &mut Vec<DocSpecsViolation>,
    ) {
        let start = match inner.iter().position(|l| !l.trim().is_empty()) {
            Some(s) if md_table_line(&inner[s]) => s,
            _ => {
                dv_malformed(&node.id, at, "a records div holding no table".to_string(), v);
                return;
            }
        };
        let header = md_row_cells(&inner[start]);
        if header[0] != "Id" {
            dv_malformed(
                &node.id,
                at,
                "a records table whose first column is not Id".to_string(),
                v,
            );
            return;
        }
        // The item type's own form decides the columns; an item type the
        // schema gives no form of its own takes its columns as virtual body
        // lines unchecked. A record's cells are the item's own body lines
        // (DocSpecs specification, The record table): unlike a `refs`
        // reference they never go to a child's form.
        let own = self.form_of(Some(item_type));
        let first_column = if header.len() > 1 && header[1] == "Title" { 2 } else { 1 };
        let mut columns: Vec<String> = Vec::new();
        for label in &header[first_column..] {
            let name = match own {
                None => Some(label.clone()),
                Some(form) => form
                    .fields
                    .iter()
                    .find(|f| f.name.to_lowercase() == label.to_lowercase())
                    .map(|f| f.name.clone()),
            };
            let Some(name) = name else {
                v.push(DocSpecsViolation {
                    rule: DOCSPECS_RULE_UNKNOWN_FIELD.to_string(),
                    line: at + 1 + start,
                    message: format!("records column \"{}\" names no field of the items", label),
                    section_id: node.id.clone(),
                    path: String::new(),
                });
                return;
            };
            columns.push(name);
        }
        let table = dv_read_table(inner, start, at + 1, &node.id, v);
        for (index, cells) in &table.rows {
            let line = at + 1 + index;
            let holder = dv_add_item(node, item_type, None, dv_cell_id(&cells[0]), line);
            for (c, column) in columns.iter().enumerate() {
                let value = dv_cell_value(&cells[first_column + c]);
                if !value.is_empty() {
                    holder.values.push(DvFieldValue {
                        label: column.clone(),
                        value,
                        line,
                        from_label: false,
                    });
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// The reading view's tables and list bodies (DocSpecs specification, List
// Bodies): lines, cells and the walk's sections.
// ---------------------------------------------------------------------------

/// One value of a form field: from a `Field:` label, a table row or a list
/// body.
#[derive(Debug, Clone)]
struct DvFieldValue {
    /// The field's label as written; empty for a reference no form names.
    label: String,
    value: String,
    line: usize,
    /// Whether a `Field:` label gave it (given even when empty).
    from_label: bool,
}

/// A table as read: its well-formed body rows (index in the lines read, and
/// the cells) and the index after it.
struct DvTable {
    rows: Vec<(usize, Vec<String>)>,
    end: usize,
}

/// A section as the validator walks it: a parsed [`DocSpecsSection`], or a
/// virtual one rebuilt from a list body or a section table (the DocSpecs
/// specification's List Bodies). The body is a copy, so blanking a table or
/// div never touches the parsed document.
#[derive(Debug, Clone)]
struct DvNode<'s> {
    id: String,
    /// The heading's line, or the row's or div's line of a virtual section.
    line: usize,
    /// The own body lines; a list body or section table already read is
    /// blank.
    body: Vec<String>,
    /// The section-type of a virtual list item, given by the schema.
    ty: Option<&'s DocSpecsSectionType>,
    children: Vec<DvNode<'s>>,
    /// Form values given by a table row or a list body.
    values: Vec<DvFieldValue>,
}

impl<'s> DvNode<'s> {
    fn new(id: String, line: usize, ty: Option<&'s DocSpecsSectionType>) -> DvNode<'s> {
        DvNode {
            id,
            line,
            body: Vec::new(),
            ty,
            children: Vec::new(),
            values: Vec::new(),
        }
    }

    /// The walk's view of a parsed section and its subtree.
    fn of(s: &DocSpecsSection) -> DvNode<'s> {
        DvNode {
            id: s.id.clone(),
            line: s.line,
            body: s.body_lines.clone(),
            ty: None,
            children: s.children.iter().map(DvNode::of).collect(),
            values: Vec::new(),
        }
    }

    fn body_start_line(&self) -> usize {
        self.line + 1
    }

    /// The trimmed body text, after the virtual body lines of
    /// [`Self::values`] — the text the same section has in the fields layout,
    /// where a section without a form in the schema carries its values as
    /// `FieldName:` lines.
    fn text(&self) -> String {
        let mut lines: Vec<String> = self
            .values
            .iter()
            .map(|fv| {
                if fv.label.is_empty() {
                    fv.value.clone()
                } else {
                    format!("{}: {}", fv.label, fv.value)
                }
            })
            .collect();
        lines.extend(self.body.iter().cloned());
        let mut start = 0;
        let mut end = lines.len();
        while start < end && lines[start].trim().is_empty() {
            start += 1;
        }
        while end > start && lines[end - 1].trim().is_empty() {
            end -= 1;
        }
        lines[start..end].join("\n")
    }
}

fn dv_malformed(section_id: &str, line: usize, message: String, v: &mut Vec<DocSpecsViolation>) {
    v.push(DocSpecsViolation {
        rule: DOCSPECS_RULE_MALFORMED_BLOCK.to_string(),
        line,
        message,
        section_id: section_id.to_string(),
        path: String::new(),
    });
}

/// A virtual item of `item_type` with `id` at `line`, added to `list`;
/// returns the section its form values go to — the item itself, or its
/// virtual child of `child_type` (id: the child type's name upper-cased).
fn dv_add_item<'n, 's>(
    list: &'n mut DvNode<'s>,
    item_type: &'s DocSpecsSectionType,
    child_type: Option<&'s DocSpecsSectionType>,
    id: String,
    line: usize,
) -> &'n mut DvNode<'s> {
    list.children.push(DvNode::new(id, line, Some(item_type)));
    let item = list.children.last_mut().expect("just pushed");
    match child_type {
        None => item,
        Some(ct) => {
            item.children
                .push(DvNode::new(ct.name.to_uppercase(), line, Some(ct)));
            item.children.last_mut().expect("just pushed")
        }
    }
}

/// Reads the table whose header is `lines[start]`: the body rows with their
/// line indexes, and the index after the table; `first_line` is the 1-based
/// document line of `lines[0]`. A missing or mismatched delimiter row is a
/// [`DOCSPECS_RULE_MALFORMED_BLOCK`] at the header and the table yields no
/// rows; a row of another cell count is one at that row and is left out.
fn dv_read_table(
    lines: &[String],
    start: usize,
    first_line: usize,
    section_id: &str,
    v: &mut Vec<DocSpecsViolation>,
) -> DvTable {
    let mut end = start + 1;
    while end < lines.len() && md_table_line(&lines[end]) {
        end += 1;
    }
    let header = md_row_cells(&lines[start]);
    let delimiter = if start + 1 < end {
        Some(md_row_cells(&lines[start + 1]))
    } else {
        None
    };
    let delimiter_ok = delimiter
        .as_ref()
        .is_some_and(|d| d.iter().all(|c| md_delimiter_cell(c)));
    let mut table = DvTable {
        rows: Vec::new(),
        end,
    };
    if !delimiter_ok || delimiter.as_ref().is_none_or(|d| d.len() != header.len()) {
        let message = if delimiter_ok {
            "table whose delimiter row does not match its header"
        } else {
            "table without its delimiter row"
        };
        dv_malformed(section_id, first_line + start, message.to_string(), v);
        return table;
    }
    for (i, line) in lines.iter().enumerate().take(end).skip(start + 2) {
        let cells = md_row_cells(line);
        if cells.len() != header.len() {
            dv_malformed(
                section_id,
                first_line + i,
                format!(
                    "table row with {} cells, the header has {}",
                    cells.len(),
                    header.len()
                ),
                v,
            );
            continue;
        }
        table.rows.push((i, cells));
    }
    table
}

fn dv_skip_blank<S: AsRef<str>>(lines: &[S], mut i: usize) -> usize {
    while i < lines.len() && lines[i].as_ref().trim().is_empty() {
        i += 1;
    }
    i
}

/// `^\[.*\]\{\.linked\}$`: a paragraph that is one `linked` span.
fn dv_linked_paragraph(para: &str) -> bool {
    para.len() >= 11
        && para.starts_with('[')
        && para.ends_with("]{.linked}")
        && !para.contains('\n')
}

/// `^ {0,3}(:{3,})[ \t]*\{\.derived(?=[\s}])`: the opening fence of a
/// `derived` block; returns its colon count.
fn dv_derived_open(line: &str) -> Option<usize> {
    let b = line.as_bytes();
    let mut p = 0;
    while p < 3 && p < b.len() && b[p] == b' ' {
        p += 1;
    }
    let colons = b[p..].iter().take_while(|&&c| c == b':').count();
    if colons < 3 {
        return None;
    }
    p += colons;
    while p < b.len() && (b[p] == b' ' || b[p] == b'\t') {
        p += 1;
    }
    let rest = line[p..].strip_prefix("{.derived")?;
    match rest.chars().next() {
        Some(c) if c == '}' || c.is_whitespace() => Some(colons),
        _ => None,
    }
}

/// `^ {0,3}:{n,}[ \t]*$`: the closing fence of a block opened with `n`
/// colons.
fn dv_fence_close(line: &str, n: usize) -> bool {
    let b = line.as_bytes();
    let mut p = 0;
    while p < 3 && p < b.len() && b[p] == b' ' {
        p += 1;
    }
    let colons = b[p..].iter().take_while(|&&c| c == b':').count();
    if colons < n {
        return false;
    }
    b[p + colons..].iter().all(|&c| c == b' ' || c == b'\t')
}

/// The number of leading lines of a section's `lines` that the rendition
/// writes from the document and that hold no value: a paragraph that is one
/// `linked` span (SOM §11.11), then a `derived` block (SOM §11.12), with the
/// blank lines around them (DocSpecs RN-5, Not text).
fn dv_generated_lead<S: AsRef<str>>(lines: &[S]) -> usize {
    let mut i = dv_skip_blank(lines, 0);
    let mut end = i;
    while end < lines.len() && !lines[end].as_ref().trim().is_empty() {
        end += 1;
    }
    if end > i {
        let para: Vec<&str> = lines[i..end].iter().map(|l| l.as_ref()).collect();
        if dv_linked_paragraph(para.join(" ").trim()) {
            i = dv_skip_blank(lines, end);
        }
    }
    if let Some(n) = lines.get(i).and_then(|l| dv_derived_open(l.as_ref())) {
        let mut k = i + 1;
        while k < lines.len() && !dv_fence_close(lines[k].as_ref(), n) {
            k += 1;
        }
        if k < lines.len() {
            i = dv_skip_blank(lines, k + 1);
        }
    }
    i
}

/// `text` without its [`dv_generated_lead`]: what the text rules read.
fn dv_without_generated_text(text: &str) -> String {
    let lines: Vec<&str> = text.split('\n').collect();
    lines[dv_generated_lead(&lines)..].join("\n").trim().to_string()
}

/// A value cell's value: `\|` unescaped, a cell of links read as their
/// texts.
fn dv_cell_value(cell: &str) -> String {
    let text = cell.replace("\\|", "|");
    match md_link_cell(&text) {
        Some(texts) => texts.join(", "),
        None => text,
    }
}

/// `re.split(r"\s*/\s*", s)`: the parts of a `<LIST> / <ITEM>` cell.
fn dv_split_cell_parts(s: &str) -> Vec<String> {
    let pieces: Vec<&str> = s.split('/').collect();
    let n = pieces.len();
    pieces
        .iter()
        .enumerate()
        .map(|(i, p)| {
            let mut x = *p;
            if i > 0 {
                x = x.trim_start();
            }
            if i + 1 < n {
                x = x.trim_end();
            }
            x.to_string()
        })
        .collect()
}

/// `\[([^\]]+)\]\([^)\s]*\)` at byte `p`: its text and the index after it.
fn dv_bare_link_at(s: &str, p: usize) -> Option<(&str, usize)> {
    let close = p + 1 + s[p + 1..].find(']')?;
    if close == p + 1 || s.as_bytes().get(close + 1) != Some(&b'(') {
        return None;
    }
    for (off, c) in s[close + 2..].char_indices() {
        if c == ')' {
            return Some((&s[p + 1..close], close + 2 + off + 1));
        }
        if c.is_whitespace() {
            return None;
        }
    }
    None
}

/// An `Id` or `Section` cell with its own anchors (`<a id="X"></a>X`)
/// removed (Section Anchors): in a `<LIST> / <ITEM>` cell each part's anchor,
/// and one before the whole cell naming its item. Any other anchor stays. An
/// id written as a link is read as its text (SOM §11.5).
fn dv_cell_id(cell: &str) -> String {
    // Every link `[X](target)` (a target without whitespace) as its text.
    let mut text = String::with_capacity(cell.len());
    let mut p = 0;
    while let Some(rel) = cell[p..].find('[') {
        let b = p + rel;
        text.push_str(&cell[p..b]);
        match dv_bare_link_at(cell, b) {
            Some((t, end)) => {
                text.push_str(t);
                p = end;
            }
            None => {
                text.push('[');
                p = b + 1;
            }
        }
    }
    text.push_str(&cell[p..]);

    // Every anchor `<a id="X"></a>\s*`, kept unless it is a part's own.
    let mut out = String::with_capacity(text.len());
    let mut pos = 0;
    let mut search = 0;
    while let Some(rel) = text[search..].find("<a id=\"") {
        let start = search + rel;
        let Some((anchor, rest)) = dv_leading_anchor(&text[start..]) else {
            search = start + 1;
            continue;
        };
        let end = text.len() - rest.len();
        out.push_str(&text[pos..start]);
        let parts = dv_split_cell_parts(rest);
        let own = dv_is_own_anchor(anchor, parts[0].trim())
            || (start == 0 && dv_is_own_anchor(anchor, parts[parts.len() - 1].trim()));
        if !own {
            out.push_str(&text[start..end]);
        }
        pos = end;
        search = end;
    }
    out.push_str(&text[pos..]);
    out
}

/// Lands a DocSpecs markdown text in a typed [`SpecDocument`] via the SOM
/// markdown codec — the "bind" entry point (SOM §14).
pub fn bind_docspecs_markdown(
    model: &SpecModel,
    document: &SpecDocument,
    text: &str,
) -> SpecMarkdownResult {
    SpecDocumentMarkdown::new(model, document).parse(text)
}

// ---------------------------------------------------------------------------
// DvRegex — a minimal backtracking regex matcher.
//
// The other ports lean on their stdlib regex engines for the schema pattern
// checks; Rust's std has none and the crate is zero-dependency, so this small
// engine covers the RE2 subset the DocSpecs schemas use: literals, `.`,
// character classes (`[A-Z0-9_]`, negation, ranges, `\d\w\s` inside),
// escapes, anchors `^`/`$` (whole-text), greedy `*`/`+`/`?`/`{n,m}`,
// grouping `(…)`/`(?:…)`, and alternation `|`. Matching is Go
// `Regexp.MatchString` semantics: an unanchored search over the value. A
// pattern outside the subset fails to compile — and, exactly like the Go
// port's non-compiling pattern, the check then reports "no match".
// ---------------------------------------------------------------------------

#[derive(Debug, Clone)]
struct DvClass {
    negated: bool,
    ranges: Vec<(char, char)>,
}

impl DvClass {
    fn matches(&self, c: char) -> bool {
        let hit = self.ranges.iter().any(|&(lo, hi)| c >= lo && c <= hi);
        hit != self.negated
    }
}

#[derive(Debug, Clone)]
enum DvInst {
    Char(char),
    Class(DvClass),
    Any,
    Start,
    End,
    /// Try `0` first, then `1` on backtrack.
    Split(usize, usize),
    Jump(usize),
    Match,
}

struct DvRegex {
    prog: Vec<DvInst>,
}

impl DvRegex {
    /// Compiles `pattern`, or `None` when it is invalid / outside the subset.
    fn compile(pattern: &str) -> Option<DvRegex> {
        let chars: Vec<char> = pattern.chars().collect();
        let mut p = DvParser { chars, pos: 0 };
        let prog = p.parse_alt()?;
        if p.pos != p.chars.len() {
            return None; // trailing garbage, e.g. an unmatched `)`.
        }
        let mut prog = prog;
        prog.push(DvInst::Match);
        Some(DvRegex { prog })
    }

    /// Unanchored search (Go `MatchString`).
    fn is_match(&self, text: &str) -> bool {
        let chars: Vec<char> = text.chars().collect();
        for start in 0..=chars.len() {
            if self.run(&chars, start) {
                return true;
            }
        }
        false
    }

    fn run(&self, chars: &[char], start: usize) -> bool {
        // Explicit backtracking stack of (pc, sp), with a step budget so a
        // pathological pattern cannot loop forever.
        let mut stack: Vec<(usize, usize)> = vec![(0, start)];
        let mut steps: usize = 0;
        while let Some((mut pc, mut sp)) = stack.pop() {
            loop {
                steps += 1;
                if steps > 1_000_000 {
                    return false;
                }
                match &self.prog[pc] {
                    DvInst::Char(c) => {
                        if sp < chars.len() && chars[sp] == *c {
                            pc += 1;
                            sp += 1;
                        } else {
                            break;
                        }
                    }
                    DvInst::Class(cl) => {
                        if sp < chars.len() && cl.matches(chars[sp]) {
                            pc += 1;
                            sp += 1;
                        } else {
                            break;
                        }
                    }
                    DvInst::Any => {
                        if sp < chars.len() && chars[sp] != '\n' {
                            pc += 1;
                            sp += 1;
                        } else {
                            break;
                        }
                    }
                    DvInst::Start => {
                        if sp == 0 {
                            pc += 1;
                        } else {
                            break;
                        }
                    }
                    DvInst::End => {
                        if sp == chars.len() {
                            pc += 1;
                        } else {
                            break;
                        }
                    }
                    DvInst::Split(a, b) => {
                        stack.push((*b, sp));
                        pc = *a;
                    }
                    DvInst::Jump(t) => pc = *t,
                    DvInst::Match => return true,
                }
            }
        }
        false
    }
}

struct DvParser {
    chars: Vec<char>,
    pos: usize,
}

impl DvParser {
    fn peek(&self) -> Option<char> {
        self.chars.get(self.pos).copied()
    }

    fn bump(&mut self) -> Option<char> {
        let c = self.peek()?;
        self.pos += 1;
        Some(c)
    }

    /// `alt: concat ('|' concat)*`
    fn parse_alt(&mut self) -> Option<Vec<DvInst>> {
        let mut branches = vec![self.parse_concat()?];
        while self.peek() == Some('|') {
            self.pos += 1;
            branches.push(self.parse_concat()?);
        }
        if branches.len() == 1 {
            return branches.pop();
        }
        // branch1 | branch2 | … : chained Splits with Jumps to the common end.
        let mut out: Vec<DvInst> = Vec::new();
        let mut jump_slots: Vec<usize> = Vec::new();
        for (i, br) in branches.iter().enumerate() {
            let last = i == branches.len() - 1;
            if !last {
                let split_at = out.len();
                out.push(DvInst::Jump(0)); // placeholder → Split
                out.extend(br.iter().cloned().map(|inst| shift(inst, split_at + 1)));
                jump_slots.push(out.len());
                out.push(DvInst::Jump(0)); // placeholder → end
                let next = out.len();
                out[split_at] = DvInst::Split(split_at + 1, next);
            } else {
                let base = out.len();
                out.extend(br.iter().cloned().map(|inst| shift(inst, base)));
            }
        }
        let end = out.len();
        for slot in jump_slots {
            out[slot] = DvInst::Jump(end);
        }
        Some(out)
    }

    /// `concat: repeat*` (stops at `|`, `)` or end)
    fn parse_concat(&mut self) -> Option<Vec<DvInst>> {
        let mut out: Vec<DvInst> = Vec::new();
        while let Some(c) = self.peek() {
            if c == '|' || c == ')' {
                break;
            }
            let base = out.len();
            let piece = self.parse_repeat()?;
            out.extend(piece.into_iter().map(|inst| shift(inst, base)));
        }
        Some(out)
    }

    /// `repeat: atom ('*'|'+'|'?'|'{n,m}')?`
    fn parse_repeat(&mut self) -> Option<Vec<DvInst>> {
        let atom = self.parse_atom()?;
        let (min, max) = match self.peek() {
            Some('*') => {
                self.pos += 1;
                (0usize, None)
            }
            Some('+') => {
                self.pos += 1;
                (1, None)
            }
            Some('?') => {
                self.pos += 1;
                (0, Some(1))
            }
            Some('{') => match self.try_parse_bounds() {
                Some(b) => b,
                None => return Some(atom), // literal `{` already consumed by atom? no — see below
            },
            _ => return Some(atom),
        };
        Some(repeat_prog(&atom, min, max))
    }

    /// Parses `{n}`, `{n,}` or `{n,m}` at the current position; leaves the
    /// position untouched (and returns `None`) when it is not a repetition.
    fn try_parse_bounds(&mut self) -> Option<(usize, Option<usize>)> {
        let save = self.pos;
        self.pos += 1; // '{'
        let n = self.parse_number()?;
        let out = match self.peek() {
            Some('}') => {
                self.pos += 1;
                Some((n, Some(n)))
            }
            Some(',') => {
                self.pos += 1;
                if self.peek() == Some('}') {
                    self.pos += 1;
                    Some((n, None))
                } else {
                    let m = self.parse_number()?;
                    if self.peek() == Some('}') {
                        self.pos += 1;
                        Some((n, Some(m)))
                    } else {
                        None
                    }
                }
            }
            _ => None,
        };
        match out {
            Some((n, m)) if m.is_none_or(|m| m >= n && m <= 1000) && n <= 1000 => Some((n, m)),
            _ => {
                self.pos = save;
                None
            }
        }
    }

    fn parse_number(&mut self) -> Option<usize> {
        let start = self.pos;
        while self.peek().is_some_and(|c| c.is_ascii_digit()) {
            self.pos += 1;
        }
        if self.pos == start {
            return None;
        }
        self.chars[start..self.pos]
            .iter()
            .collect::<String>()
            .parse()
            .ok()
    }

    fn parse_atom(&mut self) -> Option<Vec<DvInst>> {
        match self.bump()? {
            '(' => {
                // `(?:` — non-capturing; other `(?…` flags are unsupported.
                if self.peek() == Some('?') {
                    self.pos += 1;
                    if self.bump()? != ':' {
                        return None;
                    }
                }
                let inner = self.parse_alt()?;
                if self.bump()? != ')' {
                    return None;
                }
                Some(inner)
            }
            '[' => {
                let cl = self.parse_class()?;
                Some(vec![DvInst::Class(cl)])
            }
            '\\' => {
                let c = self.bump()?;
                match dv_escape_class(c) {
                    Some(cl) => Some(vec![DvInst::Class(cl)]),
                    None => dv_escape_literal(c).map(|lit| vec![DvInst::Char(lit)]),
                }
            }
            '.' => Some(vec![DvInst::Any]),
            '^' => Some(vec![DvInst::Start]),
            '$' => Some(vec![DvInst::End]),
            '*' | '+' | '?' | ')' => None, // dangling operator / paren
            c => Some(vec![DvInst::Char(c)]),
        }
    }

    fn parse_class(&mut self) -> Option<DvClass> {
        let mut negated = false;
        if self.peek() == Some('^') {
            negated = true;
            self.pos += 1;
        }
        let mut ranges: Vec<(char, char)> = Vec::new();
        let mut first = true;
        loop {
            let c = self.bump()?;
            if c == ']' && !first {
                break;
            }
            first = false;
            let lo = if c == '\\' {
                let e = self.bump()?;
                match dv_escape_class(e) {
                    Some(cl) => {
                        if cl.negated {
                            // `\D` etc. inside a class is out of subset.
                            return None;
                        }
                        ranges.extend(cl.ranges);
                        continue;
                    }
                    None => dv_escape_literal(e)?,
                }
            } else {
                c
            };
            if self.peek() == Some('-') && self.chars.get(self.pos + 1) != Some(&']') {
                self.pos += 1; // '-'
                let hc = self.bump()?;
                let hi = if hc == '\\' {
                    dv_escape_literal(self.bump()?)?
                } else {
                    hc
                };
                if hi < lo {
                    return None;
                }
                ranges.push((lo, hi));
            } else {
                ranges.push((lo, lo));
            }
        }
        Some(DvClass { negated, ranges })
    }
}

/// `\d` / `\w` / `\s` (and their negations) as character classes.
fn dv_escape_class(c: char) -> Option<DvClass> {
    let (negated, base) = match c {
        'd' | 'w' | 's' => (false, c),
        'D' => (true, 'd'),
        'W' => (true, 'w'),
        'S' => (true, 's'),
        _ => return None,
    };
    let ranges = match base {
        'd' => vec![('0', '9')],
        'w' => vec![('0', '9'), ('A', 'Z'), ('_', '_'), ('a', 'z')],
        's' => vec![
            ('\t', '\t'),
            ('\n', '\n'),
            ('\x0B', '\x0B'),
            ('\x0C', '\x0C'),
            ('\r', '\r'),
            (' ', ' '),
        ],
        _ => unreachable!(),
    };
    Some(DvClass { negated, ranges })
}

/// An escaped literal: `\n`/`\t`/`\r` controls, or an escaped punctuation
/// character. An escaped letter/digit outside the known set is invalid.
fn dv_escape_literal(c: char) -> Option<char> {
    match c {
        'n' => Some('\n'),
        't' => Some('\t'),
        'r' => Some('\r'),
        'f' => Some('\x0C'),
        'v' => Some('\x0B'),
        c if !c.is_ascii_alphanumeric() => Some(c),
        _ => None,
    }
}

/// Rebases the jump targets of `inst` by `base` (program concatenation).
fn shift(inst: DvInst, base: usize) -> DvInst {
    match inst {
        DvInst::Split(a, b) => DvInst::Split(a + base, b + base),
        DvInst::Jump(t) => DvInst::Jump(t + base),
        other => other,
    }
}

/// Builds the greedy repetition program for `atom{min,max}` (max `None` =
/// unbounded): `min` mandatory copies, then either `(atom)*` or `max-min`
/// optional copies.
fn repeat_prog(atom: &[DvInst], min: usize, max: Option<usize>) -> Vec<DvInst> {
    let mut out: Vec<DvInst> = Vec::new();
    for _ in 0..min {
        let base = out.len();
        out.extend(atom.iter().cloned().map(|i| shift(i, base)));
    }
    match max {
        None => {
            // L1: Split(L2, L3); L2: atom; Jump L1; L3:
            let l1 = out.len();
            out.push(DvInst::Jump(0)); // placeholder → Split
            let l2 = out.len();
            out.extend(atom.iter().cloned().map(|i| shift(i, l2)));
            out.push(DvInst::Jump(l1));
            let l3 = out.len();
            out[l1] = DvInst::Split(l2, l3);
        }
        Some(max) => {
            // max-min optional copies, each with a Split to the common end.
            let mut split_slots: Vec<usize> = Vec::new();
            for _ in min..max {
                let s = out.len();
                out.push(DvInst::Jump(0)); // placeholder → Split
                split_slots.push(s);
                let base = out.len();
                out.extend(atom.iter().cloned().map(|i| shift(i, base)));
            }
            let end = out.len();
            for s in split_slots {
                out[s] = DvInst::Split(s + 1, end);
            }
        }
    }
    out
}
