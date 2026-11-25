//! `spec_document_markdown` — DocSpecs-conform Markdown codec for a TomSpecs
//! document (SOM §11), a faithful port of the Go `spec_document_markdown.go`
//! (itself a port of `tom_som_dart_runtime/lib/src/spec_document_markdown.dart`
//! and the TypeScript `spec_document_markdown.ts`).
//!
//! The generated/authored `*.md` **is a genuine DocSpecs document**: line 1 is
//! the `<!-- docspec: <schema-id>/<version> -->` declaration, every populated
//! section is one markdown heading whose machine-readable identity is the
//! DocSpecs headline comment `<!--[SECTION-ID]-->` and whose text is the
//! human-readable Title-Case member name. Content values are **normal markdown
//! text** under their heading (no fences, no anchors); `@Form` sections use the
//! DocSpecs plain-text `FieldName: value` format; a list emits its `-LST`
//! container heading (id = the list's `@SectionId`, else the member segment)
//! at the owner's child level, wrapping the numbered item headings one level
//! deeper — each item carrying the `@SectionIdPattern` resolved with the
//! 1-based position (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`, else `<member>-<pos>`).
//! The container itself carries no body. Id-less members are **transparent** (mirroring
//! the schema generator , SOM §13): a transparent value member's text or form block
//! is the owner's body region, emitted without a heading and bound at its own
//! path; a transparent section/complex member never heads — its id-bearing
//! descendants hoist to the owner's child level (paths keep the transparent
//! segments). Section/complex headings without a field-level `@SectionId`
//! carry the target class's `@SectionId`.
//!
//! The parser also reads the reading view's table layout (SOM §11.4, §11.5):
//! form tables `| TomSpecField | Value |`, section tables
//! `| Section | TomSpecField | Value |`, record tables in a `::: {.records}`
//! div, reference lines in a `::: {.refs}` div and heading anchors
//! `<a id="ID">`; a block that breaks that grammar is rejected as
//! `unknownField` or `malformedBlock`. The emitter keeps writing `Field:`
//! lines, and escapes a value line shaped like a layout table header with one
//! space, which the parser removes.
//!
//! Escaping (SOM §11.3): a content line starting with `#` at column 0 is
//! emitted as `\#` (and a leading `\#`… run gains one more backslash), except
//! inside fenced code blocks, which shield their lines verbatim. Blank lines
//! inside a value are kept as written; parse trims each value of
//! leading/trailing blank lines only.
//!
//! The codec is free of any UI: it reads from / resolves against a
//! [`SpecModel`] (through the [`build_som_meta_tree`] metadata tree) and a
//! [`SpecDocument`]. Parse does **not** mutate the document — it returns
//! staged values keyed exactly like `SpecDocument::to_json` plus a rejection
//! report; [`SpecDocument::apply_markdown_result`] applies them. Anything that cannot be mapped — an
//! unknown section id, a child heading under a value leaf, orphaned text — is
//! collected into [`SpecMarkdownResult::rejections`] rather than dropped
//! (SOM §11.7).
//!
//! Rust conventions: where the other ports throw, `export_root` returns
//! `Err(String)` (the unterminated-fence case); the empty string stands in for
//! a null anchor. The Go regexes are hand-rolled here to keep the
//! zero-dependency promise; the message strings are byte-identical to Go.

use std::cell::RefCell;
use std::collections::{BTreeMap, BTreeSet, HashMap, HashSet};
use std::rc::Rc;

use crate::spec_document::{DocumentJson, ListJson, SpecDocument};
use crate::spec_meta::{
    SomFormFieldMeta, SomMetaNode, SomMetaTree, SOM_META_KIND_COMPLEX, SOM_META_KIND_CONTENT,
    SOM_META_KIND_ENUM_VALUE, SOM_META_KIND_FORM, SOM_META_KIND_LIST, SOM_META_KIND_SCALAR,
    SOM_META_KIND_SECTION,
};
use crate::spec_meta_bridge::build_som_meta_tree;
use crate::spec_model::{SpecModel, SpecRoot};
use crate::spec_section_id::effective_list_item_section_id;

// Why an imported Markdown block was rejected (SOM §11.7 rejection protocol).

/// The heading's section id does not resolve against the schema tree at its
/// nesting position.
pub const SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION: &str = "unknownSection";
/// A structurally impossible combination, e.g. a child heading nested under a
/// value-leaf (content/scalar/enum) section.
pub const SPEC_MARKDOWN_REJECT_KIND_MISMATCH: &str = "kindMismatch";
/// Body text with no owning value slot: text before the document root heading.
pub const SPEC_MARKDOWN_REJECT_ORPHAN_CONTENT: &str = "orphanContent";
/// A value-leaf section heading with an empty body.
pub const SPEC_MARKDOWN_REJECT_MISSING_VALUE: &str = "missingValue";
/// A heading line without a parseable `<!--[id]-->` headline comment.
pub const SPEC_MARKDOWN_REJECT_MALFORMED_HEADING: &str = "malformedHeading";
/// A form-table row, a section-table row or a records column names no field
/// the form declares.
pub const SPEC_MARKDOWN_REJECT_UNKNOWN_FIELD: &str = "unknownField";
/// A block that breaks the layout grammar (SOM §11.4, §11.5): a table without
/// its delimiter row or with a row of another cell count, a field given twice,
/// a `refs` / `records` div beside other text or item headings or not holding
/// what it should, an unclosed `refs` / `records` fence. The message says
/// which.
pub const SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK: &str = "malformedBlock";

/// One rejected block in a Markdown import (SOM §11.7). Reported, never
/// silently dropped: each carries the source `line`, the offending `anchor`
/// (section path or id, `""` when none), the `reason`, and a human-readable
/// `message`.
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
        format!(
            "line {}: {}{} \u{2014} {}",
            self.line, self.reason, anchor, self.message
        )
    }
}

impl std::fmt::Display for SpecMarkdownRejection {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.to_display())
    }
}

/// The outcome of parsing a Markdown document (SOM §11.7): the staged values
/// plus every rejected block. The values are keyed exactly like
/// `SpecDocument::to_json` so a caller can merge them into a live document as
/// a full overwrite of the covered scope.
#[derive(Debug, Clone, Default)]
pub struct SpecMarkdownResult {
    /// Content/scalar/enum leaf values (and section body text): path → value.
    pub content: BTreeMap<String, String>,
    /// Form values: form path → (field name → value).
    pub forms: BTreeMap<String, BTreeMap<String, String>>,
    /// List membership: list path → `{seq, items, ids?}` (the
    /// `SpecDocument::to_json` shape), recovered from the item headings.
    pub lists: BTreeMap<String, ListJson>,
    /// Every rejected block, in source order.
    pub rejections: Vec<SpecMarkdownRejection>,
    /// The root segment(s) the import covers (the first segment of each
    /// accepted path) — the scope a full-overwrite apply purges first.
    pub root_prefixes: BTreeSet<String>,
    /// Stored headlines staged from heading titles (SOM §11.7): path →
    /// headline, populated ONLY when the parsed heading text differs from the
    /// effective default derivation (byte-stability — a default title stages
    /// nothing).
    pub headlines: BTreeMap<String, String>,
    /// Stored codeSpec mappings staged from the `codeSpec="…"` key in the
    /// heading comment (codespecs_mapping.md §9.2): path → comma-joined code
    /// locations, populated whenever present (codeSpec has no effective
    /// default).
    pub code_specs: BTreeMap<String, String>,
    /// Stored generation units (SOM §11.2): path → the comma-joined list of
    /// generation-unit ids parsed from the `units="…"` key in the heading
    /// comment. Staged whenever present (absent means the default).
    pub units: BTreeMap<String, String>,
}

impl SpecMarkdownResult {
    /// Reports whether the parse was clean (no rejections).
    pub fn is_clean(&self) -> bool {
        self.rejections.is_empty()
    }

    /// Returns the number of leaf values successfully parsed (content + form
    /// fields).
    pub fn applied_count(&self) -> usize {
        self.content.len() + self.forms.values().map(|m| m.len()).sum::<usize>()
    }

    /// Converts the staged values into a [`DocumentJson`] for loading.
    pub fn to_document_json(&self) -> DocumentJson {
        DocumentJson {
            content: self.content.clone(),
            forms: self.forms.clone(),
            lists: self.lists.clone(),
            headlines: self.headlines.clone(),
            code_specs: self.code_specs.clone(),
            units: self.units.clone(),
        }
    }
}

/// The outcome of [`SpecDocument::from_markdown`]: the document holding every
/// value the parse accepted, together with the parse report.
///
/// Blocks the parser rejected are not in [`document`](Self::document); they
/// are kept here so a caller can show them or refuse to save — re-exporting a
/// document whose source had rejections drops those blocks for good.
#[derive(Debug, Clone)]
pub struct SpecMarkdownImport {
    /// The document holding every value the parse accepted.
    pub document: SpecDocument,
    /// The parse report, rejections included.
    pub result: SpecMarkdownResult,
}

impl SpecMarkdownImport {
    /// The blocks the parse rejected, in source order; they are not in
    /// [`document`](Self::document).
    pub fn rejections(&self) -> &[SpecMarkdownRejection] {
        &self.result.rejections
    }
}

/// A fence state machine (CommonMark-ish): a line whose first non-space run
/// (up to 3 spaces indent) is 3+ backticks or tildes opens a fence; a matching
/// same-character run at least as long closes it.
///
/// Public so other markdown-processing modules (the DocSpecs validator's
/// generic parser) share exactly the same fence semantics as this codec.
#[derive(Debug, Default)]
pub struct MarkdownFenceTracker {
    ch: u8,
    size: usize,
}

impl MarkdownFenceTracker {
    /// Returns a tracker outside any fence.
    pub fn new() -> MarkdownFenceTracker {
        MarkdownFenceTracker::default()
    }

    /// Reports whether the tracker is currently inside a fence.
    pub fn in_fence(&self) -> bool {
        self.ch != 0
    }

    /// Advances the state machine by one line.
    pub fn feed(&mut self, line: &str) {
        let (run_char, run_len) = match md_fence_open_run(line) {
            Some(r) => r,
            None => return,
        };
        if self.ch == 0 {
            self.ch = run_char;
            self.size = run_len;
            return;
        }
        let trimmed = line.trim();
        if run_char == self.ch
            && run_len >= self.size
            && !trimmed.is_empty()
            && trimmed.bytes().all(|b| b == self.ch)
        {
            self.ch = 0;
            self.size = 0;
        }
    }
}

/// `mdFenceOpenRE`: `^ {0,3}(`​`{3,}`​`|~{3,})` — up to 3 spaces indent, then a
/// run of 3+ backticks or tildes. Returns the run's character and length.
fn md_fence_open_run(line: &str) -> Option<(u8, usize)> {
    let b = line.as_bytes();
    let mut i = 0;
    while i < b.len() && i < 3 && b[i] == b' ' {
        i += 1;
    }
    if i >= b.len() || (b[i] != b'`' && b[i] != b'~') {
        return None;
    }
    let ch = b[i];
    let start = i;
    while i < b.len() && b[i] == ch {
        i += 1;
    }
    let len = i - start;
    if len >= 3 {
        Some((ch, len))
    } else {
        None
    }
}

/// mdBuffer — a tiny StringBuffer with Dart-style writeln semantics.
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

    /// Appends `text` verbatim — no trailing newline. Used to splice an
    /// already-terminated buffer (a form's field block) into its owner.
    fn write(&mut self, text: &str) {
        self.out.push_str(text);
    }
}

// --- Hand-rolled line matchers (shared with the DocSpecs validator) -----------

/// Go `\s` character class (`[\t\n\f\r ]`).
fn is_go_space(c: char) -> bool {
    matches!(c, ' ' | '\t' | '\n' | '\x0C' | '\r')
}

/// `mdHeadingLineRE`: `^(#+)\s+(.*)$` — returns (level, rest).
pub(crate) fn md_heading_line(line: &str) -> Option<(usize, &str)> {
    let b = line.as_bytes();
    let mut n = 0;
    while n < b.len() && b[n] == b'#' {
        n += 1;
    }
    if n == 0 {
        return None;
    }
    let rest = &line[n..];
    let stripped = rest.trim_start_matches(is_go_space);
    if stripped.len() == rest.len() {
        return None; // `\s+` needs at least one whitespace character.
    }
    Some((n, stripped))
}

/// `mdHeadlineCommentRE`: `^<!--\[([^\]]+)\]([^>]*)-->\s*(.*)$` — returns g1
/// the id, g2 the raw key=value region between the id bracket and the closing
/// `-->` (codespecs_mapping.md §9.2 `codeSpec`), and g3 the heading title text
/// after the comment (SOM §11.7). `[^>]*` means the region cannot itself
/// contain `>`.
pub(crate) fn md_headline_comment(rest: &str) -> Option<(&str, &str, &str)> {
    let r = rest.strip_prefix("<!--[")?;
    let close = r.find(']')?;
    if close == 0 {
        return None;
    }
    let id = &r[..close];
    let after = &r[close + 1..]; // skip the `]`.
    // g2 = `[^>]*` up to the closing `-->`. The region cannot contain `>`.
    let end = after.find("-->")?;
    let region = &after[..end];
    if region.contains('>') {
        return None;
    }
    let title = &after[end + 3..];
    Some((id, region, title.trim_start_matches(is_go_space)))
}

impl SpecDocumentMarkdown<'_> {
    /// The `codeSpec="…"` value of a heading-comment key=value region, trimmed;
    /// the empty string when the region has no `codeSpec` key (TS
    /// `SpecDocumentMarkdown.codeSpecOf`, codespecs_mapping.md §9.2).
    pub fn code_spec_of(region: &str) -> String {
        md_code_spec_of(region)
    }

    /// The `units="…"` value of a heading-comment key=value region, trimmed;
    /// the empty string when the region has no `units` key (TS
    /// `SpecDocumentMarkdown.unitsOf`, SOM §11.2).
    pub fn units_of(region: &str) -> String {
        md_units_of(region)
    }

    /// Whether `line` is the header of a reading-view layout table (SOM §11.4,
    /// §11.5): `Some(false)` for a form table's `| TomSpecField | Value |`,
    /// `Some(true)` for a section table's `| Section | TomSpecField | Value |`
    /// (at column 0, any case), `None` for any other line.
    pub fn layout_table_header(line: &str) -> Option<bool> {
        md_layout_table_header(line)
    }
}

/// Extracts the `codeSpec="…"` value from a heading-comment key=value region
/// (`mdCodeSpecRE`: `codeSpec=(?:"([^"]*)"|'([^']*)'|([^,\s>]+))`), the first
/// matching group trimmed; the empty string when the region carries no
/// `codeSpec` key (codespecs_mapping.md §9.2).
pub(crate) fn md_code_spec_of(region: &str) -> String {
    // Find `codeSpec=` then read a double-quoted, single-quoted, or bare value.
    let mut search = region;
    while let Some(pos) = search.find("codeSpec=") {
        let after = &search[pos + "codeSpec=".len()..];
        for quote in ['"', '\''] {
            if let Some(body) = after.strip_prefix(quote) {
                if let Some(end) = body.find(quote) {
                    return body[..end].trim().to_string();
                }
            }
        }
        // Bare: `[^,\s>]+` — one or more chars that are not comma,
        // whitespace, or `>`. An unclosed quote is read as a bare value too,
        // as the pattern's third alternative reads it.
        let end = after
            .find(|c: char| c == ',' || c == '>' || is_go_space(c))
            .unwrap_or(after.len());
        if end > 0 {
            return after[..end].trim().to_string();
        }
        // No value matched at this occurrence; advance past it.
        search = after;
    }
    String::new()
}

/// Extracts the `units="…"` value from a heading-comment key=value region
/// (SOM §11.2; `(?:^|\s)units=(?:"([^"]*)"|'([^']*)'|([^,\s>]+))`): the same
/// quoting rules as [`md_code_spec_of`] — double-quoted, single-quoted or bare
/// — the first matching group trimmed. The key must start the region or
/// follow whitespace, so a `units=` inside a quoted codeSpec value is not read
/// as the key. The empty string when the region carries no `units` key.
pub(crate) fn md_units_of(region: &str) -> String {
    const KEY: &str = "units=";
    let mut from = 0;
    while let Some(rel) = region[from..].find(KEY) {
        let pos = from + rel;
        from = pos + 1;
        let at_boundary = pos == 0 || region[..pos].chars().next_back().is_some_and(is_go_space);
        if !at_boundary {
            continue;
        }
        let after = &region[pos + KEY.len()..];
        for quote in ['"', '\''] {
            if let Some(body) = after.strip_prefix(quote) {
                if let Some(end) = body.find(quote) {
                    return body[..end].trim().to_string();
                }
            }
        }
        // Bare: `[^,\s>]+` — one or more chars that are not comma,
        // whitespace, or `>` (an unclosed quote is read as a bare value too).
        let end = after
            .find(|c: char| c == ',' || c == '>' || is_go_space(c))
            .unwrap_or(after.len());
        if end > 0 {
            return after[..end].trim().to_string();
        }
    }
    String::new()
}

/// `mdDocspecCommentRE`: `^<!--\s*docspec:.*-->\s*$` (on a right-trimmed line).
pub(crate) fn md_docspec_comment(line: &str) -> bool {
    let r = match line.strip_prefix("<!--") {
        Some(r) => r,
        None => return false,
    };
    let r = r.trim_start_matches(is_go_space);
    match r.strip_prefix("docspec:") {
        Some(r) => r.ends_with("-->"),
        None => false,
    }
}

/// `mdTrailingWSRE`: strips a trailing `\s+` run.
fn md_trim_trailing_ws(line: &str) -> &str {
    line.trim_end_matches(is_go_space)
}

/// `mdEscapableRE`: `^\\*#` — an optional run of backslashes followed by `#`
/// at column 0.
fn md_escapable(line: &str) -> bool {
    let b = line.as_bytes();
    let mut i = 0;
    while i < b.len() && b[i] == b'\\' {
        i += 1;
    }
    i < b.len() && b[i] == b'#'
}

/// `mdEscapedHeadingRE`: `^\\+#` — one-or-more backslashes then `#`.
fn md_escaped_heading(line: &str) -> bool {
    let b = line.as_bytes();
    let mut i = 0;
    while i < b.len() && b[i] == b'\\' {
        i += 1;
    }
    i > 0 && i < b.len() && b[i] == b'#'
}

/// Matches `[A-Za-z][A-Za-z0-9_]*:` at position `at`; returns the index just
/// past the colon, or `None`.
fn label_end(b: &[u8], at: usize) -> Option<usize> {
    if at >= b.len() || !b[at].is_ascii_alphabetic() {
        return None;
    }
    let mut i = at + 1;
    while i < b.len() && (b[i].is_ascii_alphanumeric() || b[i] == b'_') {
        i += 1;
    }
    if i < b.len() && b[i] == b':' {
        Some(i + 1)
    } else {
        None
    }
}

/// `mdLabelShapedRE`: `^ *[A-Za-z][A-Za-z0-9_]*:` — a line that would parse as
/// a form-field label (optionally already space-prefixed).
fn md_label_shaped(line: &str) -> bool {
    let b = line.as_bytes();
    let mut i = 0;
    while i < b.len() && b[i] == b' ' {
        i += 1;
    }
    label_end(b, i).is_some()
}

/// `mdContinuationLabelRE`: `^ +[A-Za-z][A-Za-z0-9_]*:`.
fn md_continuation_label(line: &str) -> bool {
    let b = line.as_bytes();
    let mut i = 0;
    while i < b.len() && b[i] == b' ' {
        i += 1;
    }
    i > 0 && label_end(b, i).is_some()
}

/// `mdFieldLabelRE`: `^([A-Za-z][A-Za-z0-9_]*): ?(.*)$` — returns
/// (label, first value line).
fn md_field_label(line: &str) -> Option<(&str, &str)> {
    let b = line.as_bytes();
    let colon_end = label_end(b, 0)?;
    let label = &line[..colon_end - 1];
    let mut rest = &line[colon_end..];
    if let Some(r) = rest.strip_prefix(' ') {
        rest = r; // `: ?` — at most one space consumed.
    }
    Some((label, rest))
}

// --- Reading-view layout lines (SOM §11.4, §11.5) ------------------------------

/// Whether `b` holds `word` at `*p`, any ASCII case; advances `*p` past it.
fn md_match_word_ci(b: &[u8], p: &mut usize, word: &str) -> bool {
    let w = word.as_bytes();
    if *p + w.len() > b.len() || !b[*p..*p + w.len()].eq_ignore_ascii_case(w) {
        return false;
    }
    *p += w.len();
    true
}

/// Advances `*p` over a `\s` run.
fn md_skip_ws(b: &[u8], p: &mut usize) {
    while *p < b.len() && is_go_space(b[*p] as char) {
        *p += 1;
    }
}

/// The rest of a layout header after its first `|` at `p`:
/// `\s*(?:(Section)\s*\|\s*)?TomSpecField\s*\|\s*Value\s*\|?\s*$`, any case.
/// Returns whether it is a section-table header, `None` when it is no header.
fn md_layout_header_rest(b: &[u8], mut p: usize) -> Option<bool> {
    md_skip_ws(b, &mut p);
    let mut section = false;
    let mut q = p;
    if md_match_word_ci(b, &mut q, "Section") {
        md_skip_ws(b, &mut q);
        if q < b.len() && b[q] == b'|' {
            q += 1;
            md_skip_ws(b, &mut q);
            section = true;
            p = q;
        }
    }
    if !md_match_word_ci(b, &mut p, "TomSpecField") {
        return None;
    }
    md_skip_ws(b, &mut p);
    if p >= b.len() || b[p] != b'|' {
        return None;
    }
    p += 1;
    md_skip_ws(b, &mut p);
    if !md_match_word_ci(b, &mut p, "Value") {
        return None;
    }
    md_skip_ws(b, &mut p);
    if p < b.len() && b[p] == b'|' {
        p += 1;
    }
    md_skip_ws(b, &mut p);
    if p != b.len() {
        return None;
    }
    Some(section)
}

/// A line that reads as the header of a form table or a section table:
/// `| TomSpecField | Value |` or `| Section | TomSpecField | Value |` at
/// column 0, any case. The header alone makes a table layout. Returns whether
/// it is a section table's, `None` for any other line.
fn md_layout_table_header(line: &str) -> Option<bool> {
    let b = line.as_bytes();
    if b.first() != Some(&b'|') {
        return None;
    }
    md_layout_header_rest(b, 1)
}

/// A value line shaped like a layout header after `min_spaces` or more spaces
/// (0: the emitter escapes it with one space; 1: the parse removes it).
fn md_header_shaped(line: &str, min_spaces: usize) -> bool {
    let b = line.as_bytes();
    let mut i = 0;
    while i < b.len() && b[i] == b' ' {
        i += 1;
    }
    i >= min_spaces && i < b.len() && b[i] == b'|' && md_layout_header_rest(b, i + 1).is_some()
}

/// `^ {0,3}\|`: a line that starts a table row.
fn md_table_line(line: &str) -> bool {
    let b = line.as_bytes();
    let mut i = 0;
    while i < 3 && i < b.len() && b[i] == b' ' {
        i += 1;
    }
    i < b.len() && b[i] == b'|'
}

/// `^:?-+:?$`: a cell of a table's delimiter row.
fn md_delimiter_cell(cell: &str) -> bool {
    let inner = cell.strip_prefix(':').unwrap_or(cell);
    let inner = inner.strip_suffix(':').unwrap_or(inner);
    !inner.is_empty() && inner.bytes().all(|c| c == b'-')
}

/// One `\[([^\]]+)\]\([^)]*\)` at byte `p`: its text and the index after it.
fn md_link_at(s: &str, p: usize) -> Option<(&str, usize)> {
    if s.as_bytes().get(p) != Some(&b'[') {
        return None;
    }
    let close = p + 1 + s[p + 1..].find(']')?;
    if close == p + 1 || s.as_bytes().get(close + 1) != Some(&b'(') {
        return None;
    }
    let paren = close + 2 + s[close + 2..].find(')')?;
    Some((&s[p + 1..close], paren + 1))
}

/// `^\[[^\]]+\]\([^)]*\)(, \[[^\]]+\]\([^)]*\))*$`: a cell of links only;
/// returns their texts.
fn md_link_cell(s: &str) -> Option<Vec<String>> {
    let mut p = 0;
    let mut out = Vec::new();
    loop {
        let (text, end) = md_link_at(s, p)?;
        out.push(text.to_string());
        if end == s.len() {
            return Some(out);
        }
        if !s[end..].starts_with(", ") {
            return None;
        }
        p = end + 2;
    }
}

/// The text of the first `\[([^\]]+)\]\([^)]*\)` anywhere in `s`.
fn md_find_link_text(s: &str) -> Option<&str> {
    s.match_indices('[').find_map(|(p, _)| md_link_at(s, p).map(|(t, _)| t))
}

/// `^:{3,}\s*(?:\{\.(refs|records)\}|(refs|records))\s*$`: the opening fence
/// of a list body's div; returns its kind.
fn md_list_div_open(line: &str) -> Option<&'static str> {
    let b = line.as_bytes();
    let mut p = 0;
    while p < b.len() && b[p] == b':' {
        p += 1;
    }
    if p < 3 {
        return None;
    }
    md_skip_ws(b, &mut p);
    let braces = b.get(p) == Some(&b'{');
    if braces {
        if b.get(p + 1) != Some(&b'.') {
            return None;
        }
        p += 2;
    }
    let kind = if line[p..].starts_with("refs") {
        "refs"
    } else if line[p..].starts_with("records") {
        "records"
    } else {
        return None;
    };
    p += kind.len();
    if braces {
        if b.get(p) != Some(&b'}') {
            return None;
        }
        p += 1;
    }
    md_skip_ws(b, &mut p);
    if p != b.len() {
        return None;
    }
    Some(kind)
}

/// `^:{3,}\s*$`: a closing fence.
fn md_div_close_line(line: &str) -> bool {
    let b = line.as_bytes();
    let mut p = 0;
    while p < b.len() && b[p] == b':' {
        p += 1;
    }
    if p < 3 {
        return false;
    }
    md_skip_ws(b, &mut p);
    p == b.len()
}

/// The cells of a table row: split on every `|` not preceded by a backslash,
/// the outer pipes dropped, each cell trimmed; `\|` stays in the cell.
fn md_row_cells(line: &str) -> Vec<String> {
    let mut t = line.trim();
    if let Some(r) = t.strip_prefix('|') {
        t = r;
    }
    if t.ends_with('|') && !t.ends_with("\\|") {
        t = &t[..t.len() - 1];
    }
    let mut cells = Vec::new();
    let mut cell = String::new();
    let mut chars = t.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '\\' && chars.peek() == Some(&'|') {
            cell.push_str("\\|");
            chars.next();
        } else if c == '|' {
            cells.push(cell.trim().to_string());
            cell.clear();
        } else {
            cell.push(c);
        }
    }
    cells.push(cell.trim().to_string());
    cells
}

/// A cell's value for field `f`: `\|` unescaped, a reference field's links
/// read as their link texts, a `code` field's code span decoded.
fn md_cell_value(cell: &str, f: &SomFormFieldMeta) -> String {
    let text = cell.replace("\\|", "|");
    if !f.refers_to.is_empty() && !f.code {
        if let Some(texts) = md_link_cell(&text) {
            return texts.join(", ");
        }
    }
    if f.code {
        md_decode_code_span(&text)
    } else {
        text
    }
}

/// A cell's id with the renderer's anchor (`<a id="X"></a>X`) removed, and a
/// link the cell is read as its text (`[X](<file>#X)`, SOM §11.5).
fn md_cell_id(cell: &str) -> String {
    let mut id = cell;
    if let Some(r) = id.strip_prefix("<a id=\"") {
        if let Some(q) = r.find('"') {
            if let Some(after) = r[q + 1..].strip_prefix("></a>") {
                id = after.trim_start_matches(is_go_space);
            }
        }
    }
    // `^\[([^\]]+)\]\([^)\s]*\)$`
    if id.starts_with('[') && id.ends_with(')') {
        if let Some(close) = id.find(']') {
            if close > 1
                && id.as_bytes().get(close + 1) == Some(&b'(')
                && close + 2 < id.len()
            {
                let target = &id[close + 2..id.len() - 1];
                if !target.contains(')') && !target.chars().any(is_go_space) {
                    return id[1..close].to_string();
                }
            }
        }
    }
    id.to_string()
}

/// The title with the renderer's anchor removed (DI-3): `<a id="X"></a>` at its
/// start, X the section id or its qualified anchor, then `<br>` as line
/// breaks (SOM §11.2).
fn md_title_without_anchor(raw: &str, id: &str, anchor: &str) -> String {
    let mut t = raw;
    for a in [id, anchor] {
        let tag = format!("<a id=\"{}\"></a>", a);
        if let Some(r) = t.strip_prefix(tag.as_str()) {
            t = r.trim_start_matches(is_go_space);
            break;
        }
    }
    t.replace("<br>", "\n")
}

/// How a heading's anchor is qualified (SOM §11.2).
#[derive(Clone, Copy, PartialEq)]
enum MdAnchorKind {
    Plain,
    Container,
    Item,
    Copy,
}

/// The qualified anchor of a heading `id` (SOM §11.2) and the scope its
/// descendants' anchors are qualified with: below a list item, or in a
/// `@SameAs` copy, an anchor is the ids from the scope's start joined by `/`;
/// elsewhere it is the id itself. `section` is the id of the nearest heading
/// above that is no list container.
fn md_qualify_anchor(
    scope: &Option<Vec<String>>,
    section: &Option<String>,
    id: &str,
    kind: MdAnchorKind,
) -> (String, Option<Vec<String>>) {
    let with_id = |parts: &[String]| -> Vec<String> {
        let mut v = parts.to_vec();
        v.push(id.to_string());
        v
    };
    let joined = match scope {
        Some(s) => with_id(s).join("/"),
        None => id.to_string(),
    };
    match kind {
        MdAnchorKind::Container => (joined, scope.clone()),
        MdAnchorKind::Item => (joined, Some(with_id(scope.as_deref().unwrap_or(&[])))),
        MdAnchorKind::Copy => {
            let base: Vec<String> = match (scope, section) {
                (Some(s), _) => s.clone(),
                (None, Some(sec)) => vec![sec.clone()],
                (None, None) => Vec::new(),
            };
            let sc = with_id(&base);
            (sc.join("/"), Some(sc))
        }
        MdAnchorKind::Plain => (joined, scope.as_ref().map(|s| with_id(s))),
    }
}

// --- Value normalisation helpers ----------------------------------------------

/// `^\n+` / `\n+$` trims; blank lines inside a value are kept as written.
fn md_trim_blank_ends(value: &str) -> &str {
    value.trim_start_matches('\n').trim_end_matches('\n')
}

/// `mdLeadingBlankLnRE`: strips `^([ \t]*\n)+`.
fn md_strip_leading_blank_lines(s: &str) -> &str {
    let b = s.as_bytes();
    let mut start = 0;
    loop {
        let mut i = start;
        while i < b.len() && (b[i] == b' ' || b[i] == b'\t') {
            i += 1;
        }
        if i < b.len() && b[i] == b'\n' {
            start = i + 1;
        } else {
            break;
        }
    }
    &s[start..]
}

/// `mdTrailingBlankLnRE`: strips `(\n[ \t]*)+$`.
fn md_strip_trailing_blank_lines(s: &str) -> &str {
    let b = s.as_bytes();
    let mut end = b.len();
    loop {
        let mut i = end;
        while i > 0 && (b[i - 1] == b' ' || b[i - 1] == b'\t') {
            i -= 1;
        }
        if i > 0 && b[i - 1] == b'\n' {
            end = i - 1;
        } else {
            break;
        }
    }
    &s[..end]
}

/// mdNodeRel — a body slot / effective child: the node plus its relative path.
struct MdNodeRel {
    node: Rc<SomMetaNode>,
    rel: String,
}

/// The body slot unmarked body text binds to on import (SOM §11.6): the first
/// non-form slot; with none, the form on the `content` member, else the first
/// form; with no slot at all the owner itself (`.`).
fn md_default_body_rel(slots: &[MdNodeRel]) -> String {
    if let Some(s) = slots.iter().find(|s| s.node.kind != SOM_META_KIND_FORM) {
        return s.rel.clone();
    }
    if slots.iter().any(|s| s.rel == "content") {
        return "content".to_string();
    }
    slots.first().map(|s| s.rel.clone()).unwrap_or_else(|| ".".to_string())
}

/// A slot marker line (SOM §11.6): `<!-- slot: <rel> -->`, `<rel>` a body
/// slot's path relative to its owner (no whitespace), or `.` for the owner
/// itself. Returns `<rel>`.
fn md_slot_marker(line: &str) -> Option<&str> {
    let rel = line.strip_prefix("<!-- slot: ")?.strip_suffix(" -->")?;
    if rel.is_empty() || rel.chars().any(char::is_whitespace) {
        return None;
    }
    Some(rel)
}

/// Reports a value member (content/scalar/enum/form) with no `@SectionId`:
/// emitted into the owner's body region instead of under an own heading.
fn md_is_transparent_value(n: &SomMetaNode) -> bool {
    n.section_id.is_empty()
        && (n.kind == SOM_META_KIND_CONTENT
            || n.kind == SOM_META_KIND_SCALAR
            || n.kind == SOM_META_KIND_ENUM_VALUE
            || n.kind == SOM_META_KIND_FORM)
}

/// SpecDocumentMarkdown is the codec binding a [`SpecModel`] and a concrete
/// [`SpecDocument`] to the DocSpecs Markdown import/export format (SOM §11).
pub struct SpecDocumentMarkdown<'a> {
    pub model: &'a SpecModel,
    pub document: &'a SpecDocument,
    // Metadata trees per root type, built lazily (the generated facades will
    // hand these in directly; until then the bridge derives them).
    trees: RefCell<HashMap<String, Rc<SomMetaTree>>>,
    // The paths of the headings written by the current export, in emission
    // order (`export_root_with_map`).
    heading_paths: RefCell<Vec<String>>,
}

impl<'a> SpecDocumentMarkdown<'a> {
    /// Binds model and document to the codec.
    pub fn new(model: &'a SpecModel, document: &'a SpecDocument) -> SpecDocumentMarkdown<'a> {
        SpecDocumentMarkdown {
            model,
            document,
            trees: RefCell::new(HashMap::new()),
            heading_paths: RefCell::new(Vec::new()),
        }
    }

    fn tree_for(&self, root_type: &str) -> Result<Rc<SomMetaTree>, String> {
        if let Some(tree) = self.trees.borrow().get(root_type) {
            return Ok(tree.clone());
        }
        let tree = Rc::new(build_som_meta_tree(self.model, root_type)?);
        self.trees
            .borrow_mut()
            .insert(root_type.to_string(), tree.clone());
        Ok(tree)
    }

    // --- Naming / heading helpers (SOM §11.2 / §11.8) ---------------------------

    /// The section id written into (and matched from) a heading for `node`
    /// (SOM §11.2/§11.8): the field-level `@SectionId` when present; for
    /// section/complex nodes whose field carries none, the target **class**'s
    /// `@SectionId` (the id the generated schema types are keyed by); else the path
    /// segment (the member name).
    fn heading_id_of(&self, node: &SomMetaNode) -> String {
        if !node.section_id.is_empty() {
            return node.section_id.clone();
        }
        // The class id is the node's class_section_id, as the YAML key uses —
        // never class_named(node.class_name): a wrapper section (TextSection,
        // ...) carries its OWNER's class name, and that lookup returned the
        // owner's id.
        if (node.kind == SOM_META_KIND_SECTION || node.kind == SOM_META_KIND_COMPLEX)
            && !node.class_section_id.is_empty()
        {
            return node.class_section_id.clone();
        }
        node.segment().to_string()
    }

    // --- Transparency (SOM §11.2, mirroring the schema generator , SOM §13) ----------
    //
    // The `docspecs-schema` generator (SOM §13) is normative: only **section-bearing**
    // nodes (those with a real `@SectionId`, field- or class-level) become
    // section types; id-less members are *transparent* — they are not sections
    // of their own. The markdown format mirrors that exactly:
    //
    //   - a transparent value member (content/scalar/enum/form without an id)
    //     is emitted headinglessly into its owner's *body region* (text, or a
    //     `FieldName: value` form block);
    //   - a transparent section/complex member gets no heading; its id-bearing
    //     descendants surface as the owner's direct child headings (the
    //     schema's "nearest section-bearing descendant" hoisting), with
    //     document paths still running through the transparent segments;
    //   - lists are never transparent — the `-LST` container always heads (SOM
    //     §11.2) at the owner's child level and the items sit one level below it
    //     (`@SectionIdPattern` / `<member>-<pos>`).
    //
    // Principled canonicalisation losses (documented, accepted): multiple
    // transparent content members of one owner merge into the first on parse,
    // and a form-field label colliding across an owner's transparent forms
    // binds to the nearest form in slot order.

    /// A section/complex member with no field- or class-level `@SectionId`:
    /// heading-less, its children hoist to the owner.
    fn is_transparent_section(&self, n: &SomMetaNode) -> bool {
        if n.kind != SOM_META_KIND_SECTION && n.kind != SOM_META_KIND_COMPLEX {
            return false;
        }
        if !n.section_id.is_empty() {
            return false;
        }
        // class_section_id, not class_named(n.class_name): see heading_id_of.
        // A wrapper section (TextSection, ...) has neither id, so it is
        // transparent (SOM §11.6).
        n.class_section_id.is_empty()
    }

    /// The ordered *body slots* of `node`: every transparent value member and
    /// every transparent section (whose own path may carry body text),
    /// collected depth-first through transparent sections. These are the value
    /// positions that share the owner's heading body.
    fn body_slots(&self, node: &SomMetaNode) -> Vec<MdNodeRel> {
        let mut out = Vec::new();
        self.collect_body_slots(node, "", &mut out);
        out
    }

    fn collect_body_slots(&self, n: &SomMetaNode, prefix: &str, out: &mut Vec<MdNodeRel>) {
        for child in &n.children {
            if child.recursive {
                continue;
            }
            let rel = if prefix.is_empty() {
                child.segment().to_string()
            } else {
                format!("{}/{}", prefix, child.segment())
            };
            if md_is_transparent_value(child) {
                out.push(MdNodeRel {
                    node: child.clone(),
                    rel,
                });
            } else if self.is_transparent_section(child) {
                out.push(MdNodeRel {
                    node: child.clone(),
                    rel: rel.clone(),
                });
                self.collect_body_slots(child, &rel, out);
            }
        }
    }

    /// The ordered *effective children* of `node`: every section-bearing child
    /// and every list, hoisted through transparent sections — exactly the
    /// headings (and item-heading owners) the generated schema knows at this
    /// position. Each entry carries the relative path from `node` (which runs
    /// through the transparent segments).
    fn effective_children(&self, node: &SomMetaNode) -> Vec<MdNodeRel> {
        let mut out = Vec::new();
        self.collect_effective_children(node, "", &mut out);
        out
    }

    fn collect_effective_children(&self, n: &SomMetaNode, prefix: &str, out: &mut Vec<MdNodeRel>) {
        for child in &n.children {
            if child.recursive {
                continue;
            }
            let rel = if prefix.is_empty() {
                child.segment().to_string()
            } else {
                format!("{}/{}", prefix, child.segment())
            };
            if md_is_transparent_value(child) {
                continue; // body region
            }
            if self.is_transparent_section(child) {
                self.collect_effective_children(child, &rel, out);
            } else {
                out.push(MdNodeRel {
                    node: child.clone(),
                    rel,
                });
            }
        }
    }

    // --- Export (SOM §11.1–§11.8) ------------------------------------------------

    /// Renders the populated subtree of `root` as a DocSpecs-conform Markdown
    /// document. Returns an error — the Rust analogue of the other ports'
    /// throw — on the two conditions this format cannot represent without
    /// losing the round-trip: a content value containing an unterminated fenced
    /// code block (which would shield the remainder of the document from
    /// heading detection), and a form holding a field the model does not
    /// declare (SOM §9, "Form-field order").
    pub fn export_root(&self, root: &SpecRoot) -> Result<String, String> {
        Ok(self.export_root_with_map(root)?.markdown)
    }

    /// [`export_root`](Self::export_root), plus the document path behind every
    /// heading it wrote — the one place that knows which node a heading came
    /// from.
    ///
    /// A caller holding a rendition line (a DocSpecs schema finding, an editor
    /// cursor) resolves it through [`SpecMarkdownRendition::path_at_line`]
    /// instead of re-deriving the renderer's layout. Section ids repeat across
    /// a document, so the id alone does not say which node a line belongs to.
    /// Errors are `export_root`'s.
    pub fn export_root_with_map(&self, root: &SpecRoot) -> Result<SpecMarkdownRendition, String> {
        self.heading_paths.borrow_mut().clear();
        let markdown = self.export_root_text(root)?;
        let recorded = self.heading_paths.borrow();
        let mut heading_paths = BTreeMap::new();
        let mut fence = MarkdownFenceTracker::new();
        let mut next = 0;
        for (i, line) in markdown.split('\n').enumerate() {
            if next >= recorded.len() {
                break;
            }
            if !fence.in_fence() && md_emitted_heading(line) {
                heading_paths.insert(i + 1, recorded[next].clone());
                next += 1;
            }
            fence.feed(line);
        }
        Ok(SpecMarkdownRendition {
            markdown,
            heading_paths,
        })
    }

    fn export_root_text(&self, root: &SpecRoot) -> Result<String, String> {
        let tree = self.tree_for(&root.type_)?;
        let node = tree.root.clone();
        let mut b = MdBuffer::new();
        b.writeln(&format!(
            "<!-- docspec: {}/{} -->",
            spec_markdown_kebab_case(&root.title),
            self.model.model_version_string()
        ));
        let root_seg = node.segment().to_string();
        // YRD3: a stored headline overrides the derived title at every heading.
        // YRD4: the `@Headline` default wins over the `@Document` title.
        let mut root_title = self.document.headline_or(&root_seg);
        if root_title.is_empty() {
            root_title = node.headline.clone();
        }
        if root_title.is_empty() {
            root_title = root.title.clone();
        }
        self.write_heading(
            &mut b,
            1,
            &root_seg,
            &root_title,
            &root_seg,
            &self.document.code_spec_or(&root_seg),
            &self.document.units_or(&root_seg),
        );
        self.write_section_body(&mut b, &node, &root_seg)?;
        self.write_children(&mut b, &node, &root_seg, 2)?;
        Ok(b.out)
    }

    /// Writes the body region of a section heading: the section path's own
    /// content value plus every transparent body slot (id-less content text
    /// and form blocks, hoisted through transparent sections) in model order.
    ///
    /// A slot whose text the parser would otherwise bind elsewhere is preceded
    /// by a slot marker (SOM §11.6): text after anything already written, a
    /// form preamble that is not the region's default target, and a form whose
    /// labels another form of the region shares. A body the parser reads
    /// correctly without markers gets none, so such documents render as
    /// before.
    fn write_section_body(
        &self,
        b: &mut MdBuffer,
        node: &SomMetaNode,
        path: &str,
    ) -> Result<(), String> {
        let slots = self.body_slots(node);
        if slots.is_empty() {
            if let Some(value) = self.document.content(path) {
                self.write_body(b, value, path)?;
            }
            return Ok(());
        }
        let form_slots: Vec<&MdNodeRel> = slots
            .iter()
            .filter(|s| s.node.kind == SOM_META_KIND_FORM)
            .collect();
        let has_forms = !form_slots.is_empty();
        let default_rel = md_default_body_rel(&slots);
        let mut written = false;

        fn marker(b: &mut MdBuffer, rel: &str) {
            b.writeln(&format!("<!-- slot: {} -->", rel));
            b.writeln("");
        }

        let text = |b: &mut MdBuffer,
                        written: &mut bool,
                        rel: &str,
                        value: Option<&String>,
                        value_path: &str|
         -> Result<(), String> {
            let value = match value {
                Some(v) => v,
                None => return Ok(()),
            };
            let prepared = self.prepare_value(value, value_path)?;
            if prepared.is_empty() {
                return Ok(());
            }
            if *written || rel != default_rel {
                marker(b, rel);
            }
            for line in prepared.split('\n') {
                if has_forms && md_label_shaped(line) {
                    b.writeln(&format!(" {}", line));
                } else {
                    b.writeln(line);
                }
            }
            b.writeln("");
            *written = true;
            Ok(())
        };

        text(b, &mut written, ".", self.document.content(path), path)?;
        for slot in &slots {
            let slot_path = format!("{}/{}", path, slot.rel);
            if slot.node.kind != SOM_META_KIND_FORM {
                text(
                    b,
                    &mut written,
                    &slot.rel,
                    self.document.content(&slot_path),
                    &slot_path,
                )?;
                continue;
            }
            if !self.form_has_values(&slot.node, &slot_path) {
                continue;
            }
            let has_preamble = match self.document.content(&slot_path) {
                Some(p) => !self.prepare_value(p, &slot_path)?.is_empty(),
                None => false,
            };
            let labels: Vec<String> = slot
                .node
                .form
                .as_ref()
                .map(|f| f.fields.iter().map(|x| x.name.to_lowercase()).collect())
                .unwrap_or_default();
            let collides = form_slots.iter().any(|o| {
                o.rel != slot.rel
                    && o.node.form.as_ref().is_some_and(|f| {
                        f.fields
                            .iter()
                            .any(|x| labels.contains(&x.name.to_lowercase()))
                    })
            });
            let needs_marker = if has_preamble {
                written || slot.rel != default_rel
            } else {
                collides && (written || form_slots[0].rel != slot.rel)
            };
            if needs_marker {
                marker(b, &slot.rel);
            }
            self.write_form(b, &slot.node, &slot_path)?;
            written = true;
        }
        Ok(())
    }

    fn write_children(
        &self,
        b: &mut MdBuffer,
        node: &SomMetaNode,
        base_path: &str,
        depth: usize,
    ) -> Result<(), String> {
        for entry in self.effective_children(node) {
            let child = &entry.node;
            let path = format!("{}/{}", base_path, entry.rel);
            if !self.document.has_values_under(&path) {
                continue;
            }
            match child.kind.as_str() {
                SOM_META_KIND_CONTENT | SOM_META_KIND_SCALAR | SOM_META_KIND_ENUM_VALUE => {
                    let value = match self.document.content(&path) {
                        Some(v) => v.clone(),
                        None => continue,
                    };
                    self.write_heading(
                        b,
                        depth,
                        &self.heading_id_of(child),
                        &self.heading_title(&path, child),
                        &path,
                        &self.document.code_spec_or(&path),
                        &self.document.units_or(&path),
                    );
                    self.write_body(b, &value, &path)?;
                }
                SOM_META_KIND_FORM => {
                    if !self.form_has_values(child, &path) {
                        continue;
                    }
                    self.write_heading(
                        b,
                        depth,
                        &self.heading_id_of(child),
                        &self.heading_title(&path, child),
                        &path,
                        &self.document.code_spec_or(&path),
                        &self.document.units_or(&path),
                    );
                    self.write_form(b, child, &path)?;
                }
                SOM_META_KIND_SECTION | SOM_META_KIND_COMPLEX => {
                    self.write_heading(
                        b,
                        depth,
                        &self.heading_id_of(child),
                        &self.heading_title(&path, child),
                        &path,
                        &self.document.code_spec_or(&path),
                        &self.document.units_or(&path),
                    );
                    self.write_section_body(b, child, &path)?;
                    self.write_children(b, child, &path, depth + 1)?;
                }
                SOM_META_KIND_LIST => {
                    self.write_list_items(b, child, &path, depth)?;
                }
                _ => {}
            }
        }
        Ok(())
    }

    /// Writes a heading ([`md_write_heading`]) and records `path`, the document
    /// path it renders, for [`export_root_with_map`](Self::export_root_with_map).
    #[allow(clippy::too_many_arguments)]
    fn write_heading(
        &self,
        b: &mut MdBuffer,
        depth: usize,
        id: &str,
        title: &str,
        path: &str,
        code_spec: &str,
        units: &str,
    ) {
        self.heading_paths.borrow_mut().push(path.to_string());
        md_write_heading(b, depth, id, title, code_spec, units);
    }

    /// Resolves the heading title for a node at `path`: the document's STORED
    /// headline when present, else the derived title (YRD3).
    fn heading_title(&self, path: &str, node: &SomMetaNode) -> String {
        let h = self.document.headline_or(path);
        if !h.is_empty() {
            return h;
        }
        md_title_of(node)
    }

    /// Emits list `node` as its `-LST` container heading (SOM §11.2/§11.5) at
    /// `depth`, wrapping the numbered item headings one level deeper. The
    /// container is a real section — the id the generated schema keys its container
    /// type by — but carries **no content of its own** (schema content
    /// min/max-text-length 0). Item identity is purely positional.
    fn write_list_items(
        &self,
        b: &mut MdBuffer,
        node: &SomMetaNode,
        list_path: &str,
        depth: usize,
    ) -> Result<(), String> {
        let items = self.document.list_items(list_path);
        if items.is_empty() {
            return Ok(());
        }
        // The container heading: its id is the list's `-LST` `@SectionId` (else
        // the member segment for a pattern-less list); its title is the member
        // name.
        self.write_heading(
            b,
            depth,
            &self.heading_id_of(node),
            &self.heading_title(list_path, node),
            list_path,
            &self.document.code_spec_or(list_path),
            &self.document.units_or(list_path),
        );
        // Item heading stem. Complex lists derive it from the element class
        // name (SOM §11.5, `Entry` dropped). A scalar list (shape 6) has no
        // element class - its element `type_name` is literally `String`, which
        // would render "String 1", "String 2". Derive the stem from the list
        // FIELD instead (its member name, Title-Cased like the container
        // heading) so a populated scalar list gets meaningful headings (YRC5).
        let element = node.element_node.as_ref();
        let stem = md_item_stem_of(node);
        let mut pattern = node.section_id_pattern.clone();
        if pattern.is_empty() {
            if let Some(e) = element {
                pattern = e.section_id_pattern.clone();
            }
        }
        let member_stem = if node.member_name.is_empty() {
            node.segment().to_string()
        } else {
            node.member_name.clone()
        };
        for (i, item_path) in items.iter().enumerate() {
            let pos = i + 1;
            // YRD3: the item's heading id is its STORED
            // `@SectionId` when present; otherwise the resolved
            // `@SectionIdPattern` id (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`);
            // pattern-less lists fall back to `<member>-<pos>`.
            let item_id = crate::spec_section_id::effective_list_item_section_id(
                self.document.item_section_id(item_path).map(|s| s.as_str()),
                &pattern,
                pos,
                &member_stem,
            );
            // Items sit one level below the container. Title: stored headline
            // when present, else the derived `<stem> <pos>` (YRD3).
            let mut item_title = self.document.headline_or(item_path);
            if item_title.is_empty() {
                item_title = format!("{} {}", stem, pos);
            }
            self.write_heading(
                b,
                depth + 1,
                &item_id,
                &item_title,
                item_path,
                &self.document.code_spec_or(item_path),
                &self.document.units_or(item_path),
            );
            match element {
                None => {
                    // Scalar list: the item's value is its body.
                    let value = self.document.content_or(item_path);
                    self.write_body(b, &value, item_path)?;
                }
                Some(e) => {
                    self.write_section_body(b, e, item_path)?;
                    if !e.recursive {
                        self.write_children(b, e, item_path, depth + 2)?;
                    }
                }
            }
        }
        Ok(())
    }

    /// The stored field names at form `path` that `node` does not declare,
    /// sorted (SOM §9, "Form-field order").
    ///
    /// The emit walk is meta-driven — it iterates the model's declared fields —
    /// so a stored field the model does not know is invisible to it and cannot
    /// be dropped *loudly*. Seeing it at all needs this deliberate reverse
    /// check: store keys minus meta keys, which is the check the yaml codec
    /// already has (SOM §12.8).
    fn undeclared_form_fields(&self, node: &SomMetaNode, path: &str) -> Vec<String> {
        let declared: std::collections::HashSet<&str> = match &node.form {
            Some(form) => form.fields.iter().map(|f| f.name.as_str()).collect(),
            None => std::collections::HashSet::new(),
        };
        let mut out: Vec<String> = self
            .document
            .form_field_names(path)
            .into_iter()
            .filter(|n| !declared.contains(n.as_str()))
            .collect();
        out.sort();
        out
    }

    /// Returns an error when the form at `path` holds a field the model does
    /// not declare (SOM §9, "Form-field order" — md refuses, matching yaml).
    ///
    /// Emitting it is impossible: the DocSpecs markdown grammar has no spelling
    /// for a field outside the model, and omitting it would lose a stored value
    /// in a file that looks complete. On import a partial document is normal
    /// and the codec reports-and-skips (SOM §11.7); on export the document is
    /// complete and a lossy rendering is a trap, so the codec refuses instead.
    fn check_form_declared(&self, node: &SomMetaNode, path: &str) -> Result<(), String> {
        match self.undeclared_form_fields(node, path).first() {
            None => Ok(()),
            Some(name) => Err(format!(
                "form at \"{}\" holds a field \"{}\" unknown to the model; it \
                 cannot be represented in the DocSpecs markdown format",
                path, name
            )),
        }
    }

    /// Whether the `@Form` node at `path` has anything to emit: its preamble
    /// content (SOM §11.4 rule 7 — the DocSpecs `${text[]}` region), or any
    /// populated field.
    ///
    /// An undeclared stored field counts too — not because it can be emitted,
    /// but so the section is still *visited* and [`Self::write_form`] refuses.
    /// Without it a form holding nothing but undeclared fields would vanish
    /// unseen, which is the silent drop this check exists to prevent.
    fn form_has_values(&self, node: &SomMetaNode, path: &str) -> bool {
        if self.document.has_content(path) {
            return true;
        }
        if let Some(form) = &node.form {
            if form
                .fields
                .iter()
                .any(|f| self.document.form_field(path, &f.name).is_some())
            {
                return true;
            }
        }
        !self.undeclared_form_fields(node, path).is_empty()
    }

    /// Writes a `@Form` section body: the preamble content (when set) followed
    /// by one `FieldName: value` group per populated field (SOM §11.4),
    /// consecutive groups separated by one blank line. Returns an error when
    /// the form holds a field the model does not declare.
    fn write_form(&self, b: &mut MdBuffer, node: &SomMetaNode, path: &str) -> Result<(), String> {
        self.check_form_declared(node, path)?;
        let empty: Vec<SomFormFieldMeta> = Vec::new();
        let fields = match &node.form {
            Some(form) => &form.fields,
            None => &empty,
        };
        let mut field_buf = MdBuffer::new();
        for f in fields {
            let value = match self.document.form_field(path, &f.name) {
                Some(v) => v.clone(),
                None => continue,
            };
            // SOM §11.4 rule 2: one blank line between consecutive field
            // groups, so a markdown viewer renders each field as its own
            // paragraph (and a list ending a value cannot swallow the next
            // label as a lazy continuation). Parse trims each value's trailing
            // blank lines, so it is lossless.
            if !field_buf.out.is_empty() {
                field_buf.writeln("");
            }
            // SOM §11.4 rule 8: a single-line code value is written as an
            // inline code span, so markdown leaves it literal (`](` is not a
            // link).
            let prepared = if f.code && md_is_inline_code(&value) {
                md_encode_code_span(&value)
            } else {
                self.prepare_value(&value, path)?
            };
            let mut lines = prepared.split('\n');
            let first = lines.next().unwrap_or("");
            field_buf.writeln(&format!("{}: {}", spec_markdown_form_label(&f.name), first));
            for line in lines {
                // SOM §11.4 generalised: any continuation line that could be
                // mistaken for a field-label line gains one leading space;
                // parse strips it.
                if md_label_shaped(line) {
                    field_buf.writeln(&format!(" {}", line));
                } else {
                    field_buf.writeln(line);
                }
            }
        }

        if let Some(preamble) = self.document.content(path) {
            let prepared = self.prepare_value(preamble, path)?;
            if !prepared.is_empty() {
                // Every preamble line gets the same label-shaped escape a
                // continuation line gets: the parser reaches a field label
                // before it knows which text is preamble, so a `Word:` line at
                // column 0 would mis-split.
                for line in prepared.split('\n') {
                    if md_label_shaped(line) {
                        b.writeln(&format!(" {}", line));
                    } else {
                        b.writeln(line);
                    }
                }
                if !field_buf.out.is_empty() {
                    b.writeln("");
                }
            }
        }
        b.write(&field_buf.out);
        b.writeln("");
        Ok(())
    }

    /// Writes `value` as a section body followed by a blank line; no-op for
    /// blank values.
    fn write_body(&self, b: &mut MdBuffer, value: &str, path: &str) -> Result<(), String> {
        let prepared = self.prepare_value(value, path)?;
        if prepared.is_empty() {
            return Ok(());
        }
        b.writeln(&prepared);
        b.writeln("");
        Ok(())
    }

    /// The emit-side value normalisation (SOM §11.3): trim leading/trailing
    /// blank lines, escape heading-like lines outside fences. Blank lines
    /// inside the value are kept. Returns an error for an unterminated fence.
    fn prepare_value(&self, value: &str, path: &str) -> Result<String, String> {
        let collapsed = md_trim_blank_ends(value);
        let mut fence = MarkdownFenceTracker::new();
        let mut out: Vec<String> = Vec::new();
        for line in collapsed.split('\n') {
            if fence.in_fence() {
                out.push(line.to_string()); // SOM §11.3: fences shield their lines.
            } else if md_escapable(line) {
                out.push(format!("\\{}", line));
            } else if md_header_shaped(line, 0) {
                out.push(format!(" {}", line)); // DI-2: a value line is never a layout table.
            } else {
                out.push(line.to_string());
            }
            fence.feed(line);
        }
        if fence.in_fence() {
            return Err(format!(
                "content at \"{}\" contains an unterminated fenced code block; \
it cannot be represented in the DocSpecs markdown format",
                path
            ));
        }
        Ok(out.join("\n"))
    }

    // --- Import (SOM §11.7) -------------------------------------------------------

    /// Parses `text` into staged values + a rejection report, **without**
    /// mutating the document. [`SpecDocument::apply_markdown_result`] applies the result as a full
    /// overwrite.
    pub fn parse(&self, text: &str) -> SpecMarkdownResult {
        let mut p = MdParser::new(self);
        p.run(text.split('\n'));
        SpecMarkdownResult {
            content: p.content,
            forms: p.forms,
            lists: md_lists_json(&p.list_order, &p.lists),
            headlines: p.headlines,
            code_specs: p.code_specs,
            units: p.units,
            rejections: p.rejections,
            root_prefixes: p.root_prefixes,
        }
    }
}

/// `## <!--[ID]--> Title` at `depth`. SOM §11.2 is normative — heading level =
/// 1 + section depth, **uncapped**: deep models (the Solution Blueprint nests
/// past markdown's native 6 levels) keep their structure; the parse grammar
/// accepts `#{7,}` accordingly. Capping would silently flatten distinct
/// nesting positions into siblings and break schema validation.
fn md_write_heading(
    b: &mut MdBuffer,
    depth: usize,
    id: &str,
    title: &str,
    code_spec: &str,
    units: &str,
) {
    // codespecs_mapping.md §9.2: when a codeSpec mapping is present it rides
    // inside the same headline comment as a `codeSpec="…"` key: `## <!--[ID]
    // codeSpec="A,B"--> Title`. Non-empty `units` follow as a second key,
    // `units="…"`, after `codeSpec` (SOM §11.2). Byte-identical to the id-only
    // form when both are empty.
    let mut code = String::new();
    if !code_spec.is_empty() {
        code.push_str(&format!(" codeSpec=\"{}\"", code_spec));
    }
    if !units.is_empty() {
        code.push_str(&format!(" units=\"{}\"", units));
    }
    b.writeln(&format!(
        "{} <!--[{}]{}--> {}",
        "#".repeat(depth),
        id,
        code,
        title.replace('\n', "<br>")
    ));
    b.writeln("");
}

/// The key=value pairs a heading comment carries: `codeSpec`
/// (codespecs_mapping.md §9.2) and `units` (SOM §11.2), each `""` when absent.
struct MdHeadingKeys {
    code_spec: String,
    units: String,
}

/// Whether `line` is a heading as [`md_write_heading`] writes it — `^#+ <!--\[`.
/// Body text never matches: heading-like body lines are escaped (SOM §11.3)
/// and fenced ones skipped.
fn md_emitted_heading(line: &str) -> bool {
    let rest = line.trim_start_matches('#');
    rest.len() < line.len() && rest.starts_with(" <!--[")
}

/// A Markdown rendition of a document and the document path behind each of
/// its headings ([`SpecDocumentMarkdown::export_root_with_map`]).
#[derive(Debug, Clone, PartialEq)]
pub struct SpecMarkdownRendition {
    /// The rendered Markdown, identical to [`SpecDocumentMarkdown::export_root`].
    pub markdown: String,
    /// Every heading line (1-based) and the document path it renders.
    pub heading_paths: BTreeMap<usize, String>,
}

impl SpecMarkdownRendition {
    /// The document path of the section `line` belongs to: the path of the
    /// heading on that line, else of the nearest heading above it. `None` for
    /// a line before the first heading.
    pub fn path_at_line(&self, line: usize) -> Option<&str> {
        self.heading_paths
            .range(..=line)
            .next_back()
            .map(|(_, p)| p.as_str())
    }
}

/// The effective DEFAULT title of `node` (YRD4): the `@Headline` default when
/// authored, else the name derivation. The stored headline (checked by
/// callers first) always wins over this.
fn md_title_of(node: &SomMetaNode) -> String {
    if !node.headline.is_empty() {
        return node.headline.clone();
    }
    let name = if node.member_name.is_empty() {
        &node.class_name
    } else {
        &node.member_name
    };
    spec_markdown_title_case(name)
}

/// The effective default item-title stem of list `node` (YRD4): the element
/// class's `@Headline` default when authored, else the SOM §11.5 derivation
/// (element class name with `Entry` dropped; member name for scalar lists).
fn md_item_stem_of(node: &SomMetaNode) -> String {
    match node.element_node.as_ref() {
        Some(e) => {
            if !e.headline.is_empty() {
                e.headline.clone()
            } else {
                spec_markdown_item_title_stem(&e.class_name)
            }
        }
        None => {
            let member = if node.member_name.is_empty() {
                node.segment().to_string()
            } else {
                node.member_name.clone()
            };
            spec_markdown_title_case(&member)
        }
    }
}

// --- Naming helpers (SOM §11.2 / §11.5) ------------------------------------------

/// Expands a camel/Pascal-case identifier into Title Case:
/// `introductionAndScope` / `DemoItem` → `Introduction And Scope` /
/// `Demo Item`.
pub fn spec_markdown_title_case(name: &str) -> String {
    let mut words: Vec<String> = Vec::new();
    let mut buf = String::new();
    for r in name.chars() {
        if r.is_uppercase() && !buf.is_empty() {
            words.push(std::mem::take(&mut buf));
        }
        buf.push(r);
    }
    if !buf.is_empty() {
        words.push(buf);
    }
    let out: Vec<String> = words
        .iter()
        .map(|w| {
            let mut cs = w.chars();
            match cs.next() {
                None => String::new(),
                Some(first) => first.to_uppercase().collect::<String>() + cs.as_str(),
            }
        })
        .collect();
    out.join(" ")
}

/// Derives the DocSpecs schema id of a `@Document` name (SOM §11.1):
/// `Demo Document` → `demo-document`.
pub fn spec_markdown_kebab_case(title: &str) -> String {
    let s = title.trim();
    // `[\s_]+` → `-`.
    let mut dashed = String::with_capacity(s.len());
    let mut in_run = false;
    for c in s.chars() {
        if c.is_whitespace() || c == '_' {
            if !in_run {
                dashed.push('-');
                in_run = true;
            }
        } else {
            dashed.push(c);
            in_run = false;
        }
    }
    // Drop `[^A-Za-z0-9-]`, then lower-case.
    dashed
        .chars()
        .filter(|c| c.is_ascii_alphanumeric() || *c == '-')
        .collect::<String>()
        .to_lowercase()
}

/// The item heading title stem: Title-Case element class name with a trailing
/// `Entry` dropped (SOM §11.5, normative).
pub fn spec_markdown_item_title_stem(element_class_name: &str) -> String {
    let mut stem = element_class_name;
    if stem.len() > 5 && stem.ends_with("Entry") {
        stem = &stem[..stem.len() - 5];
    }
    spec_markdown_title_case(stem)
}

/// The `FieldName` label written for a form field: the model field name with
/// the first letter upper-cased (SOM §11.4).
pub fn spec_markdown_form_label(field_name: &str) -> String {
    let mut cs = field_name.chars();
    match cs.next() {
        None => String::new(),
        Some(first) => first.to_uppercase().collect::<String>() + cs.as_str(),
    }
}

// --- Parser --------------------------------------------------------------------

/// One open section during the parse: its heading level, resolved node (`None`
/// for an unresolvable/ignored section), path, and accumulated body lines.
struct MdFrame {
    level: usize,
    node: Option<Rc<SomMetaNode>>,
    path: String,
    line: usize,
    ignored: bool,
    body: Vec<String>,
    /// The scope this heading's descendants' anchors are qualified with (SOM
    /// §11.2, [`md_qualify_anchor`]).
    anchor_scope: Option<Vec<String>>,
    /// The id of the nearest heading at or above this one that is no list
    /// container.
    anchor_section: Option<String>,
}

impl MdFrame {
    fn new(level: usize, node: Option<Rc<SomMetaNode>>, path: String, line: usize) -> MdFrame {
        MdFrame {
            level,
            node,
            path,
            line,
            ignored: false,
            body: Vec::new(),
            anchor_scope: None,
            anchor_section: None,
        }
    }

    fn ignored(level: usize, line: usize) -> MdFrame {
        MdFrame {
            ignored: true,
            ..MdFrame::new(level, None, String::new(), line)
        }
    }
}

/// The 1-based source line of body line `i` of the frame whose heading is on
/// `frame_line`.
fn md_body_line(frame_line: usize, i: usize) -> usize {
    frame_line + 1 + i
}

/// One table read off body lines: its header cells, the body rows with their
/// line indexes, and the index after it.
struct MdTable {
    rows: Vec<(usize, Vec<String>)>,
    end: usize,
}

/// Per-list bookkeeping while parsing: ordered item paths, stored ids, and the
/// highest item number handed out (drives both fresh numbers for stored-id
/// items and the resulting seq).
#[derive(Default)]
struct MdListState {
    items: Vec<String>,
    ids: BTreeMap<String, String>,
    max_n: i64,
}

struct MdParser<'c, 'a> {
    codec: &'c SpecDocumentMarkdown<'a>,
    content: BTreeMap<String, String>,
    forms: BTreeMap<String, BTreeMap<String, String>>,
    lists: HashMap<String, MdListState>,
    list_order: Vec<String>,
    /// Stored headlines staged from heading titles that differ from their
    /// effective default (SOM §11.7) — path → headline.
    headlines: BTreeMap<String, String>,
    /// Stored codeSpec mappings staged from the `codeSpec="…"` heading-comment
    /// key (codespecs_mapping.md §9.2) — path → comma-joined code locations,
    /// staged whenever present.
    code_specs: BTreeMap<String, String>,
    /// Stored generation units staged from the `units="…"` heading-comment key
    /// (SOM §11.2) — staged exactly like `code_specs`.
    units: BTreeMap<String, String>,
    rejections: Vec<SpecMarkdownRejection>,
    root_prefixes: BTreeSet<String>,
    stack: Vec<MdFrame>,
    fence: MarkdownFenceTracker,
    /// The fields given so far per form path, for the given-twice rule.
    given: HashMap<String, HashSet<String>>,
}

impl<'c, 'a> MdParser<'c, 'a> {
    fn new(codec: &'c SpecDocumentMarkdown<'a>) -> MdParser<'c, 'a> {
        MdParser {
            codec,
            content: BTreeMap::new(),
            forms: BTreeMap::new(),
            lists: HashMap::new(),
            list_order: Vec::new(),
            headlines: BTreeMap::new(),
            code_specs: BTreeMap::new(),
            units: BTreeMap::new(),
            rejections: Vec::new(),
            root_prefixes: BTreeSet::new(),
            stack: Vec::new(),
            fence: MarkdownFenceTracker::new(),
            given: HashMap::new(),
        }
    }

    fn run<'t>(&mut self, lines: impl Iterator<Item = &'t str>) {
        for (i, raw) in lines.enumerate() {
            let line_no = i + 1;
            let trimmed = md_trim_trailing_ws(raw);

            if !self.fence.in_fence() {
                if self.stack.is_empty() && md_docspec_comment(trimmed) {
                    continue; // SOM §11.1 header — informational.
                }
                if let Some((level, rest)) = md_heading_line(trimmed) {
                    self.close_to(level);
                    self.open_heading(level, rest, line_no);
                    continue;
                }
            }
            if let Some(top) = self.stack.last_mut() {
                top.body.push(raw.to_string());
            } else if !trimmed.is_empty() {
                self.rejections.push(SpecMarkdownRejection {
                    line: line_no,
                    reason: SPEC_MARKDOWN_REJECT_ORPHAN_CONTENT.to_string(),
                    message: "text before the document root heading".to_string(),
                    anchor: String::new(),
                });
            }
            self.fence.feed(raw);
        }
        self.close_to(1);
        while let Some(frame) = self.stack.pop() {
            self.finalize(frame);
        }
    }

    /// Pops (and finalizes) every frame at `level` or deeper.
    fn close_to(&mut self, level: usize) {
        while self.stack.last().is_some_and(|f| f.level >= level) {
            let frame = self.stack.pop().unwrap();
            self.finalize(frame);
        }
    }

    fn open_heading(&mut self, level: usize, rest: &str, line_no: usize) {
        let (id, keys, raw_title) = match md_headline_comment(rest.trim()) {
            Some((id, region, title)) => (
                id.to_string(),
                MdHeadingKeys {
                    code_spec: md_code_spec_of(region),
                    units: md_units_of(region),
                },
                title.to_string(),
            ),
            None => {
                self.rejections.push(SpecMarkdownRejection {
                    line: line_no,
                    reason: SPEC_MARKDOWN_REJECT_MALFORMED_HEADING.to_string(),
                    message: "heading carries no <!--[SECTION-ID]--> headline comment"
                        .to_string(),
                    anchor: rest.trim().to_string(),
                });
                self.stack.push(MdFrame::ignored(level, line_no));
                return;
            }
        };

        // Reading view (DI-3): an anchor equal to the section id after the id
        // comment, or to its qualified form (SOM §11.2), is the renderer's, not
        // part of the title; a `<br>` in a heading title is a stored line break.
        if self.stack.is_empty() {
            let title = md_title_without_anchor(&raw_title, &id, &id);
            self.open_root(level, &id, &title, &keys, line_no);
            return;
        }

        let (parent_ignored, parent_node, parent_path, parent_scope, parent_section) = {
            let parent = self.stack.last().unwrap();
            (
                parent.ignored,
                parent.node.clone(),
                parent.path.clone(),
                parent.anchor_scope.clone(),
                parent.anchor_section.clone(),
            )
        };
        if parent_ignored {
            self.rejections.push(SpecMarkdownRejection {
                line: line_no,
                reason: SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION.to_string(),
                message: "section nested under an unresolvable parent".to_string(),
                anchor: id,
            });
            self.stack.push(MdFrame::ignored(level, line_no));
            return;
        }
        let p_node = match &parent_node {
            Some(n) if !md_is_value_leaf(&n.kind) => n.clone(),
            _ => {
                self.rejections.push(SpecMarkdownRejection {
                    line: line_no,
                    reason: SPEC_MARKDOWN_REJECT_KIND_MISMATCH.to_string(),
                    message: "child heading under a value-leaf or form section".to_string(),
                    anchor: id,
                });
                self.stack.push(MdFrame::ignored(level, line_no));
                return;
            }
        };

        // 1. Under a `-LST` container frame (SOM §11.2), every child heading is
        //    one of that list's items — resolved positionally, not by the
        //    schema tree.
        if p_node.kind == SOM_META_KIND_LIST {
            let (anchor, scope) =
                md_qualify_anchor(&parent_scope, &parent_section, &id, MdAnchorKind::Item);
            let title = md_title_without_anchor(&raw_title, &id, &anchor);
            self.open_item_heading(level, &parent_path, p_node, &id, &title, &keys, line_no);
            let top = self.stack.last_mut().unwrap();
            top.anchor_scope = scope;
            top.anchor_section = Some(id);
            return;
        }

        // 2. A regular (non-list) or list-**container** *effective* child —
        //    section-bearing children hoisted through transparent sections —
        //    whose heading id matches. A list heads its `-LST` container here;
        //    its items are resolved above once the container frame is open.
        //    Transparent value members never head, so they never match; the
        //    bound path runs through the transparent segments.
        for entry in &self.codec.effective_children(&p_node) {
            if self.codec.heading_id_of(&entry.node) == id {
                let path = format!("{}/{}", parent_path, entry.rel);
                let container = entry.node.kind == SOM_META_KIND_LIST;
                let kind = if container {
                    MdAnchorKind::Container
                } else if self.is_copy_node(&entry.node) {
                    MdAnchorKind::Copy
                } else {
                    MdAnchorKind::Plain
                };
                let (anchor, scope) = md_qualify_anchor(&parent_scope, &parent_section, &id, kind);
                let title = md_title_without_anchor(&raw_title, &id, &anchor);
                // Stage the heading title as a stored headline only when it
                // differs from the effective default (SOM §11.7).
                if !title.is_empty() && title != md_title_of(&entry.node) {
                    self.headlines.insert(path.clone(), title);
                }
                // codespecs_mapping.md §9.2: stage the codeSpec mapping
                // whenever present (no default); SOM §11.2 `units` likewise.
                self.stage_keys(&path, &keys);
                let mut frame = MdFrame::new(level, Some(entry.node.clone()), path, line_no);
                frame.anchor_scope = scope;
                frame.anchor_section = if container {
                    parent_section.clone()
                } else {
                    Some(id.clone())
                };
                self.stack.push(frame);
                return;
            }
        }

        self.rejections.push(SpecMarkdownRejection {
            line: line_no,
            reason: SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION.to_string(),
            message: format!(
                "section id does not resolve against the schema tree at this \
position (under \"{}\")",
                parent_path
            ),
            anchor: id,
        });
        self.stack.push(MdFrame::ignored(level, line_no));
    }

    /// Stages a heading's `codeSpec` (codespecs_mapping.md §9.2) and `units`
    /// (SOM §11.2) keys at `path`, each whenever present (neither has a
    /// default).
    fn stage_keys(&mut self, path: &str, keys: &MdHeadingKeys) {
        if !keys.code_spec.is_empty() {
            self.code_specs.insert(path.to_string(), keys.code_spec.clone());
        }
        if !keys.units.is_empty() {
            self.units.insert(path.to_string(), keys.units.clone());
        }
    }

    fn open_root(&mut self, level: usize, id: &str, title: &str, keys: &MdHeadingKeys, line_no: usize) {
        for root in &self.codec.model.roots {
            let seg = if root.section_id.is_empty() {
                root.type_.as_str()
            } else {
                root.section_id.as_str()
            };
            if seg == id {
                let tree = match self.codec.tree_for(&root.type_) {
                    Ok(t) => t,
                    Err(_) => break,
                };
                // Stage a stored headline when the root title differs from
                // the effective default (SOM §11.7): the `@Headline` default
                // (YRD4), else the model's document title.
                let default_title = if tree.root.headline.is_empty() {
                    root.title.as_str()
                } else {
                    tree.root.headline.as_str()
                };
                if !title.is_empty() && title != default_title {
                    self.headlines.insert(seg.to_string(), title.to_string());
                }
                // codespecs_mapping.md §9.2: stage the root codeSpec mapping
                // whenever present; SOM §11.2 `units` likewise.
                self.stage_keys(seg, keys);
                self.root_prefixes.insert(seg.to_string());
                let mut frame =
                    MdFrame::new(level, Some(tree.root.clone()), seg.to_string(), line_no);
                frame.anchor_section = Some(seg.to_string());
                self.stack.push(frame);
                return;
            }
        }
        let known: Vec<&str> = self
            .codec
            .model
            .roots
            .iter()
            .map(|r| {
                if r.section_id.is_empty() {
                    r.type_.as_str()
                } else {
                    r.section_id.as_str()
                }
            })
            .collect();
        self.rejections.push(SpecMarkdownRejection {
            line: line_no,
            reason: SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION.to_string(),
            message: format!(
                "no document root with this section id (known: {})",
                known.join(", ")
            ),
            anchor: id.to_string(),
        });
        self.stack.push(MdFrame::ignored(level, line_no));
    }

    /// Opens a list-item frame under a `-LST` container frame (SOM §11.2): the
    /// heading `id` names the item as [`md_item_identity`] reads it.
    #[allow(clippy::too_many_arguments)]
    fn open_item_heading(
        &mut self,
        level: usize,
        list_path: &str,
        list_node: Rc<SomMetaNode>,
        id: &str,
        title: &str,
        keys: &MdHeadingKeys,
        line_no: usize,
    ) {
        let (n, stored_id, has_n) = md_item_identity(&list_node, id);
        self.open_item(level, list_path, list_node, n, &stored_id, has_n, title, keys, line_no, true);
    }

    /// Opens a list item and returns its path; with `push` its frame goes on
    /// the stack (an item heading), without it the item is only registered (a
    /// records row, a reference, a section-table row). `n` (with
    /// `has_n = true`) is the anonymous heading number (also the path number);
    /// a stored-id item gets the next free number instead.
    #[allow(clippy::too_many_arguments)]
    fn open_item(
        &mut self,
        level: usize,
        list_path: &str,
        list_node: Rc<SomMetaNode>,
        n: i64,
        stored_id: &str,
        has_n: bool,
        title: &str,
        keys: &MdHeadingKeys,
        line_no: usize,
        push: bool,
    ) -> String {
        if !self.lists.contains_key(list_path) {
            self.lists.insert(list_path.to_string(), MdListState::default());
            self.list_order.push(list_path.to_string());
        }
        let state = self.lists.get_mut(list_path).unwrap();
        let number = if has_n { n } else { state.max_n + 1 };
        if number > state.max_n {
            state.max_n = number;
        }
        let item_path = format!("{}-{}", list_path, number);
        state.items.push(item_path.clone());
        // A positional item (`has_n`) stores an id only when one is given —
        // the numbered `@SectionIdPattern` form; the `<member>-<n>` fallback
        // stores none.
        if !has_n || !stored_id.is_empty() {
            state.ids.insert(item_path.clone(), stored_id.to_string());
        }
        // Stage the heading title as a stored headline only when it differs
        // from the derived `<stem> <n>` default (SOM §11.7).
        let stem = md_item_stem_of(&list_node);
        if !title.is_empty() && title != format!("{} {}", stem, number) {
            self.headlines.insert(item_path.clone(), title.to_string());
        }
        // codespecs_mapping.md §9.2: stage the item codeSpec mapping whenever
        // present (no default); SOM §11.2 `units` likewise.
        self.stage_keys(&item_path, keys);
        if push {
            self.stack.push(MdFrame::new(
                level,
                list_node.element_node.clone(),
                item_path.clone(),
                line_no,
            ));
        }
        item_path
    }

    // --- Body finalisation -----------------------------------------------------

    fn finalize(&mut self, mut frame: MdFrame) {
        if frame.ignored {
            return;
        }
        let node = frame.node.clone();
        if let Some(node) = &node {
            if node.kind == SOM_META_KIND_FORM {
                let path = frame.path.clone();
                self.finalize_form(&frame, node, &path);
                return;
            }
            if node.kind == SOM_META_KIND_LIST {
                self.finalize_list_body(&mut frame, node);
            } else if node.kind == SOM_META_KIND_SECTION || node.kind == SOM_META_KIND_COMPLEX {
                self.extract_section_tables(&mut frame, node);
            }
        }
        let slots = match &frame.node {
            Some(node) => self.codec.body_slots(node),
            None => Vec::new(),
        };
        if slots.is_empty() {
            let value = md_restore_value(&frame.body);
            if !value.is_empty() {
                self.content.insert(frame.path.clone(), value);
            } else if frame.node.as_ref().is_some_and(|n| md_is_value_leaf(&n.kind)) {
                self.rejections.push(SpecMarkdownRejection {
                    line: frame.line,
                    reason: SPEC_MARKDOWN_REJECT_MISSING_VALUE.to_string(),
                    message: "no value text under this section heading".to_string(),
                    anchor: frame.path.clone(),
                });
            }
            return;
        }
        self.finalize_body_slots(&frame, slots);
    }

    fn reject(&mut self, line: usize, reason: &str, message: String, anchor: &str) {
        self.rejections.push(SpecMarkdownRejection {
            line,
            reason: reason.to_string(),
            message,
            anchor: anchor.to_string(),
        });
    }

    /// Binds a heading's body region against the owner's transparent body
    /// slots (SOM §11.6): `FieldName:` lines and form-table rows matching a
    /// transparent form's fields route to that form (nearest form in slot
    /// order, wrapping); a slot marker (`<!-- slot: <rel> -->`) sends the text
    /// after it to the named slot — a content slot, a form's preamble, or the
    /// owner itself (`.`) — and ends any open field. Unmarked text binds to the
    /// first content slot; with no content slot it is a form's preamble (SOM
    /// §11.4 rule 7) — the form slot named `content`, else the first form slot.
    /// Only an owner with no slot at all takes the text on its own path. In a
    /// region with forms every label-shaped text line carries one escape
    /// space, which is stripped.
    fn finalize_body_slots(&mut self, frame: &MdFrame, slots: Vec<MdNodeRel>) {
        let default_rel = md_default_body_rel(&slots);
        let path_of = |rel: &str| -> String {
            if rel == "." {
                frame.path.clone()
            } else {
                format!("{}/{}", frame.path, rel)
            }
        };
        let form_slots: Vec<&MdNodeRel> = slots
            .iter()
            .filter(|s| s.node.kind == SOM_META_KIND_FORM)
            .collect();
        let has_forms = !form_slots.is_empty();

        // Rolling pointer into the body region's transparent form slots —
        // labels bind to the nearest form at or after the last hit (wrapping),
        // so repeated field names across an owner's transparent forms follow
        // emit order.
        let mut current_form_idx: usize = 0;
        let find_field = |from_idx: usize, label: &str| -> Option<(usize, SomFormFieldMeta)> {
            let lower = label.to_lowercase();
            for k in 0..form_slots.len() {
                let idx = (from_idx + k) % form_slots.len();
                let form = match &form_slots[idx].node.form {
                    Some(f) => f,
                    None => continue,
                };
                for f in &form.fields {
                    if f.name.to_lowercase() == lower {
                        return Some((idx, f.clone()));
                    }
                }
            }
            None
        };

        let mut fence = MarkdownFenceTracker::new();
        let mut current_field = String::new();
        let mut current_form_path = String::new();
        let mut have_field = false;
        // The open field repeats one given before: its lines are read and
        // dropped (the first is kept).
        let mut discard = false;
        let mut current_code = false;
        let mut current_lines: Vec<String> = Vec::new();
        // Unlabelled text per target path, in the order the targets were
        // opened; a target opened twice gets its parts joined by a blank line.
        let mut text_parts: Vec<(String, Vec<Vec<String>>)> =
            vec![(path_of(&default_rel), vec![Vec::new()])];
        let mut target_idx: usize = 0;

        let mut i = 0;
        while i < frame.body.len() {
            let line = &frame.body[i];
            if !fence.in_fence() {
                if let Some(rel) = md_slot_marker(line) {
                    let slot = if rel == "." {
                        None
                    } else {
                        slots.iter().find(|s| s.rel == rel)
                    };
                    if rel == "." || slot.is_some() {
                        if have_field && !discard {
                            stage_form_value(
                                &mut self.forms,
                                &current_form_path,
                                &current_field,
                                current_code,
                                &current_lines,
                            );
                        }
                        have_field = false;
                        discard = false;
                        current_lines = Vec::new();
                        current_field = String::new();
                        current_form_path = String::new();
                        if let Some(slot) = slot {
                            if slot.node.kind == SOM_META_KIND_FORM {
                                if let Some(k) =
                                    form_slots.iter().position(|f| f.rel == slot.rel)
                                {
                                    current_form_idx = k;
                                }
                            }
                        }
                        let target = path_of(rel);
                        target_idx = match text_parts.iter().position(|(p, _)| *p == target) {
                            Some(k) => {
                                text_parts[k].1.push(Vec::new());
                                k
                            }
                            None => {
                                text_parts.push((target, vec![Vec::new()]));
                                text_parts.len() - 1
                            }
                        };
                        i += 1;
                        continue;
                    }
                }
                if has_forms && md_layout_table_header(line) == Some(false) {
                    // A form table ends the open field (SOM §11.4); its rows
                    // bind like `Field:` labels, each to the nearest form
                    // declaring it.
                    if have_field && !discard {
                        stage_form_value(
                            &mut self.forms,
                            &current_form_path,
                            &current_field,
                            current_code,
                            &current_lines,
                        );
                    }
                    have_field = false;
                    discard = false;
                    current_lines = Vec::new();
                    current_field = String::new();
                    current_form_path = String::new();
                    let frame_line = frame.line;
                    let table =
                        self.read_table(&frame.body, i, &|k| md_body_line(frame_line, k), &frame.path);
                    for (row, cells) in &table.rows {
                        let row_line = md_body_line(frame_line, *row);
                        match find_field(current_form_idx, &cells[0]) {
                            None => self.reject(
                                row_line,
                                SPEC_MARKDOWN_REJECT_UNKNOWN_FIELD,
                                format!("row \"{}\" names no field of this form", cells[0]),
                                &frame.path,
                            ),
                            Some((idx, field)) => {
                                current_form_idx = idx;
                                let form_path = format!("{}/{}", frame.path, form_slots[idx].rel);
                                self.stage_row(&form_path, &[field], &cells[0], &cells[1], row_line);
                            }
                        }
                    }
                    i = table.end;
                    continue;
                }
                if let Some((label, first)) = md_field_label(line) {
                    if let Some((idx, field)) = find_field(current_form_idx, label) {
                        if have_field && !discard {
                            stage_form_value(
                                &mut self.forms,
                                &current_form_path,
                                &current_field,
                                current_code,
                                &current_lines,
                            );
                        }
                        current_lines = Vec::new();
                        current_form_idx = idx;
                        have_field = true;
                        current_code = field.code;
                        current_field = field.name;
                        current_form_path = format!("{}/{}", frame.path, form_slots[idx].rel);
                        discard = self.given_twice(
                            &current_form_path,
                            &current_field,
                            md_body_line(frame.line, i),
                        );
                        current_lines.push(first.to_string());
                        fence.feed(line);
                        i += 1;
                        continue;
                    }
                }
            }
            // In a region with forms every label-shaped text line carries the
            // one escape space the emitter adds (SOM §11.4 rule 3); strip it.
            let text = if !fence.in_fence() && has_forms && md_continuation_label(line) {
                &line[1..]
            } else {
                line.as_str()
            };
            if have_field {
                current_lines.push(text.to_string());
            } else {
                text_parts[target_idx]
                    .1
                    .last_mut()
                    .unwrap()
                    .push(text.to_string());
            }
            fence.feed(line);
            i += 1;
        }
        if have_field && !discard {
            stage_form_value(
                &mut self.forms,
                &current_form_path,
                &current_field,
                current_code,
                &current_lines,
            );
        }
        for (target, parts) in text_parts {
            let value = parts
                .iter()
                .map(|part| md_restore_value(part))
                .filter(|v| !v.is_empty())
                .collect::<Vec<_>>()
                .join("\n\n");
            if !value.is_empty() {
                self.content.insert(target, value);
            }
        }
    }

    /// Parses an id-bearing `@Form` section's body: `FieldName:` paragraphs
    /// and form-table rows bind to the named fields wherever they stand (SOM
    /// §11.4); the text that belongs to no field — before the first field, or
    /// after a table — is the form's preamble, its own content (rule 7).
    fn finalize_form(&mut self, frame: &MdFrame, node: &SomMetaNode, path: &str) {
        let declared: Vec<SomFormFieldMeta> =
            node.form.as_ref().map(|f| f.fields.clone()).unwrap_or_default();
        let mut fence = MarkdownFenceTracker::new();
        let mut current_field: Option<SomFormFieldMeta> = None;
        let mut discard = false;
        let mut current_lines: Vec<String> = Vec::new();
        // The preamble's parts: the text before the first field, and text a
        // table interrupts; joined by one blank line.
        let mut preamble_parts: Vec<Vec<String>> = vec![Vec::new()];

        let mut i = 0;
        while i < frame.body.len() {
            let line = &frame.body[i];
            if !fence.in_fence() {
                if md_layout_table_header(line) == Some(false) {
                    self.flush_form_field(path, current_field.take(), discard, &current_lines);
                    current_lines.clear();
                    discard = false;
                    preamble_parts.push(Vec::new());
                    let frame_line = frame.line;
                    let table =
                        self.read_table(&frame.body, i, &|k| md_body_line(frame_line, k), path);
                    for (row, cells) in &table.rows {
                        self.stage_row(
                            path,
                            &declared,
                            &cells[0],
                            &cells[1],
                            md_body_line(frame_line, *row),
                        );
                    }
                    i = table.end;
                    continue;
                }
                if let Some((label, first)) = md_field_label(line) {
                    let lower = label.to_lowercase();
                    if let Some(field) = declared.iter().find(|f| f.name.to_lowercase() == lower) {
                        self.flush_form_field(path, current_field.take(), discard, &current_lines);
                        current_lines.clear();
                        discard = self.given_twice(path, &field.name, md_body_line(frame.line, i));
                        current_field = Some(field.clone());
                        current_lines.push(first.to_string());
                        fence.feed(line);
                        i += 1;
                        continue;
                    }
                }
            }
            // Continuation: strip the one escape space of a label-shaped line.
            let text = if !fence.in_fence() && md_continuation_label(line) {
                line[1..].to_string()
            } else {
                line.clone()
            };
            if current_field.is_some() {
                current_lines.push(text);
            } else {
                preamble_parts.last_mut().unwrap().push(text);
            }
            fence.feed(line);
            i += 1;
        }
        self.flush_form_field(path, current_field, discard, &current_lines);
        let preamble = preamble_parts
            .iter()
            .map(|part| md_restore_value(part))
            .filter(|v| !v.is_empty())
            .collect::<Vec<_>>()
            .join("\n\n");
        if !preamble.is_empty() {
            self.content.insert(path.to_string(), preamble);
        }
    }

    /// Stages the open `Field:` paragraph of an id-bearing form, unless it
    /// repeats a field given before.
    fn flush_form_field(
        &mut self,
        path: &str,
        field: Option<SomFormFieldMeta>,
        discard: bool,
        lines: &[String],
    ) {
        if let Some(field) = field {
            if !discard {
                stage_form_value(&mut self.forms, path, &field.name, field.code, lines);
            }
        }
    }

    // --- Layout tables (SOM §11.4, §11.5) --------------------------------------

    /// Reads the table whose header is `lines[start]`; a broken delimiter row
    /// or a row of another cell count is a malformedBlock.
    fn read_table(
        &mut self,
        lines: &[String],
        start: usize,
        line_of: &dyn Fn(usize) -> usize,
        anchor: &str,
    ) -> MdTable {
        let mut end = start + 1;
        while end < lines.len() && md_table_line(&lines[end]) {
            end += 1;
        }
        let mut table = MdTable {
            rows: Vec::new(),
            end,
        };
        let header = md_row_cells(&lines[start]);
        let delimiter = if start + 1 < end {
            let cells = md_row_cells(&lines[start + 1]);
            if cells.iter().all(|c| md_delimiter_cell(c)) {
                Some(cells)
            } else {
                None
            }
        } else {
            None
        };
        match &delimiter {
            Some(d) if d.len() == header.len() => {}
            _ => {
                let message = if delimiter.is_none() {
                    "table without its delimiter row"
                } else {
                    "table whose delimiter row does not match its header"
                };
                self.reject(
                    line_of(start),
                    SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK,
                    message.to_string(),
                    anchor,
                );
                return table;
            }
        }
        for (k, line) in lines.iter().enumerate().take(end).skip(start + 2) {
            let cells = md_row_cells(line);
            if cells.len() != header.len() {
                self.reject(
                    line_of(k),
                    SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK,
                    format!(
                        "table row with {} cells, the header has {}",
                        cells.len(),
                        header.len()
                    ),
                    anchor,
                );
                continue;
            }
            table.rows.push((k, cells));
        }
        table
    }

    /// Whether `field` of the form at `form_path` was given before; reports the
    /// repeat (malformedBlock, the first occurrence kept) when it was.
    fn given_twice(&mut self, form_path: &str, field: &str, line: usize) -> bool {
        if self
            .given
            .entry(form_path.to_string())
            .or_default()
            .insert(field.to_string())
        {
            return false;
        }
        self.reject(
            line,
            SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK,
            format!("field \"{}\" given twice", field),
            form_path,
        );
        true
    }

    /// Stages one row of a form table (or a section table).
    fn stage_row(
        &mut self,
        form_path: &str,
        fields: &[SomFormFieldMeta],
        label: &str,
        cell: &str,
        line: usize,
    ) {
        let lower = label.to_lowercase();
        let Some(field) = fields.iter().find(|f| f.name.to_lowercase() == lower) else {
            self.reject(
                line,
                SPEC_MARKDOWN_REJECT_UNKNOWN_FIELD,
                format!("row \"{}\" names no field of this form", label),
                form_path,
            );
            return;
        };
        let value = md_cell_value(cell, field);
        if value.is_empty() || self.given_twice(form_path, &field.name, line) {
            return;
        }
        self.forms
            .entry(form_path.to_string())
            .or_default()
            .insert(field.name.clone(), value);
    }

    /// Reads and removes every section table of `frame`'s body (SOM §11.5).
    fn extract_section_tables(&mut self, frame: &mut MdFrame, node: &SomMetaNode) {
        let mut fence = MarkdownFenceTracker::new();
        let mut i = 0;
        while i < frame.body.len() {
            if fence.in_fence() || md_layout_table_header(&frame.body[i]) != Some(true) {
                fence.feed(&frame.body[i]);
                i += 1;
                continue;
            }
            let frame_line = frame.line;
            let table = self.read_table(&frame.body, i, &|k| md_body_line(frame_line, k), &frame.path);
            let mut target: Option<(String, Vec<SomFormFieldMeta>)> = None;
            let mut skip = false;
            for (row, cells) in &table.rows {
                let line_no = md_body_line(frame_line, *row);
                let section = md_cell_id(&cells[0]);
                if section.is_empty() && skip {
                    continue;
                }
                if !section.is_empty() {
                    target = self.section_table_target(&frame.path, frame_line, node, &section);
                    skip = target.is_none();
                    if skip {
                        self.reject(
                            line_no,
                            SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION,
                            format!("section-table row names no child section of \"{}\"", frame.path),
                            &section,
                        );
                        continue;
                    }
                }
                let Some((form_path, fields)) = &target else {
                    self.reject(
                        line_no,
                        SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION,
                        "section-table row names no section".to_string(),
                        &frame.path,
                    );
                    continue;
                };
                let (form_path, fields) = (form_path.clone(), fields.clone());
                self.stage_row(&form_path, &fields, &cells[1], &cells[2], line_no);
            }
            for line in &mut frame.body[i..table.end] {
                line.clear();
            }
            i = table.end;
        }
    }

    /// The item class's own form (its class-level `@Form`, a transparent body
    /// slot), or `None` when the class carries none or more than one.
    fn item_form(&self, element: &SomMetaNode) -> Option<MdNodeRel> {
        let mut forms = self
            .codec
            .body_slots(element)
            .into_iter()
            .filter(|s| s.node.kind == SOM_META_KIND_FORM);
        let form = forms.next()?;
        if forms.next().is_some() {
            return None;
        }
        Some(form)
    }

    /// The form a section-table `Section` cell names under `node`: its path
    /// and fields. A `<LIST>/<item>` cell names an item's form, registering the
    /// item when no heading opened it.
    fn section_table_target(
        &mut self,
        frame_path: &str,
        frame_line: usize,
        node: &SomMetaNode,
        section: &str,
    ) -> Option<(String, Vec<SomFormFieldMeta>)> {
        let parts: Vec<&str> = section.split('/').map(str::trim).collect();
        for entry in self.codec.effective_children(node) {
            let child = &entry.node;
            let child_id = self.codec.heading_id_of(child);
            if parts.len() == 1 && child.kind == SOM_META_KIND_FORM && child_id == section {
                let fields = child.form.as_ref().map(|f| f.fields.clone()).unwrap_or_default();
                return Some((format!("{}/{}", frame_path, entry.rel), fields));
            }
            if parts.len() == 2 && child.kind == SOM_META_KIND_LIST && child_id == parts[0] {
                let form = child.element_node.as_ref().and_then(|e| self.item_form(e))?;
                let (n, stored_id, has_n) = md_item_identity(child, parts[1]);
                let list_path = format!("{}/{}", frame_path, entry.rel);
                let existing = self.lists.get(&list_path).and_then(|state| {
                    state
                        .items
                        .iter()
                        .find(|p| {
                            let key = state
                                .ids
                                .get(*p)
                                .map(String::as_str)
                                .unwrap_or(&p[list_path.len() + 1..]);
                            key == parts[1]
                        })
                        .cloned()
                });
                let item_path = match existing {
                    Some(p) => p,
                    None => self.open_item(
                        0,
                        &list_path,
                        child.clone(),
                        n,
                        &stored_id,
                        has_n,
                        "",
                        &MD_NO_KEYS,
                        frame_line,
                        false,
                    ),
                };
                let fields = form.node.form.as_ref().map(|f| f.fields.clone()).unwrap_or_default();
                return Some((format!("{}/{}", item_path, form.rel), fields));
            }
        }
        None
    }

    // --- List bodies: `refs` and `records` (SOM §11.5) -------------------------

    /// A list container's body: one `refs` or `records` div stands for its
    /// items.
    fn finalize_list_body(&mut self, frame: &mut MdFrame, list_node: &Rc<SomMetaNode>) {
        let mut fence = MarkdownFenceTracker::new();
        for i in 0..frame.body.len() {
            let kind = match md_list_div_open(&frame.body[i]) {
                Some(kind) if !fence.in_fence() => kind,
                _ => {
                    fence.feed(&frame.body[i]);
                    continue;
                }
            };
            let Some(close) = (i + 1..frame.body.len()).find(|&k| md_div_close_line(&frame.body[k]))
            else {
                // The fence's lines read as text.
                self.reject(
                    md_body_line(frame.line, i),
                    SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK,
                    format!("unclosed {} fence", kind),
                    &frame.path,
                );
                return;
            };
            let beside_text = frame
                .body
                .iter()
                .enumerate()
                .any(|(k, l)| (k < i || k > close) && !l.trim().is_empty());
            let has_items = self.lists.get(&frame.path).is_some_and(|s| !s.items.is_empty());
            if beside_text || has_items {
                self.reject(
                    md_body_line(frame.line, i),
                    SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK,
                    format!(
                        "a {} div beside {} in a list container",
                        kind,
                        if has_items { "item headings" } else { "other text" }
                    ),
                    &frame.path,
                );
            } else {
                let inner = frame.body[i + 1..close].to_vec();
                if kind == "refs" {
                    self.stage_reference_line(frame, list_node, &inner, i);
                } else {
                    self.stage_record_table(frame, list_node, &inner, i);
                }
            }
            for line in &mut frame.body[i..=close] {
                line.clear();
            }
            return;
        }
    }

    /// The reference field of `element`'s items, with the rel of its form.
    fn reference_field(&self, element: &SomMetaNode) -> Option<(String, SomFormFieldMeta)> {
        let is_ref = |n: &SomMetaNode| -> Option<SomFormFieldMeta> {
            let form = n.form.as_ref()?;
            if n.kind != SOM_META_KIND_FORM
                || form.fields.len() != 1
                || form.fields[0].refers_to.is_empty()
                || !n.extra.iter().any(|e| e.annotation == "Reference")
            {
                return None;
            }
            Some(form.fields[0].clone())
        };
        self.codec
            .body_slots(element)
            .into_iter()
            .chain(self.codec.effective_children(element))
            .find_map(|s| is_ref(&s.node).map(|f| (s.rel, f)))
    }

    /// A `refs` div: ids split on commas and whitespace, links read as their
    /// texts.
    fn stage_reference_line(
        &mut self,
        frame: &MdFrame,
        list_node: &Rc<SomMetaNode>,
        inner: &[String],
        at: usize,
    ) {
        let reference = list_node
            .element_node
            .as_ref()
            .and_then(|e| self.reference_field(e));
        let Some((rel, field)) = reference else {
            self.reject(
                md_body_line(frame.line, at),
                SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK,
                "a refs div in a list whose items are not references".to_string(),
                &frame.path,
            );
            return;
        };
        let joined = inner.join(" ");
        let ids: Vec<String> = joined
            .split(|c: char| c == ',' || is_go_space(c))
            .filter(|t| !t.is_empty())
            .map(|t| md_find_link_text(t).unwrap_or(t).to_string())
            .collect();
        if ids.is_empty() {
            self.reject(
                md_body_line(frame.line, at),
                SPEC_MARKDOWN_REJECT_MISSING_VALUE,
                "an empty refs div".to_string(),
                &frame.path,
            );
            return;
        }
        let pattern = md_item_pattern(list_node);
        let member = if list_node.member_name.is_empty() {
            list_node.segment().to_string()
        } else {
            list_node.member_name.clone()
        };
        for (k, id) in ids.iter().enumerate() {
            let positional = effective_list_item_section_id(None, &pattern, k + 1, &member);
            let (n, stored_id, has_n) = md_item_identity(list_node, &positional);
            let item_path = self.open_item(
                0,
                &frame.path,
                list_node.clone(),
                n,
                &stored_id,
                has_n,
                "",
                &MD_NO_KEYS,
                frame.line,
                false,
            );
            let form_path = if rel == "." {
                item_path
            } else {
                format!("{}/{}", item_path, rel)
            };
            self.forms
                .entry(form_path)
                .or_default()
                .insert(field.name.clone(), id.clone());
        }
    }

    /// A `records` div: one table, `Id` first, `Title` optionally second.
    fn stage_record_table(
        &mut self,
        frame: &MdFrame,
        list_node: &Rc<SomMetaNode>,
        inner: &[String],
        at: usize,
    ) {
        let frame_line = frame.line;
        let line_of = |k: usize| md_body_line(frame_line, at + 1 + k);
        let div_line = md_body_line(frame_line, at);
        let Some(start) = inner.iter().position(|l| !l.trim().is_empty()) else {
            self.reject(
                div_line,
                SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK,
                "a records div holding no table".to_string(),
                &frame.path,
            );
            return;
        };
        if !md_table_line(&inner[start]) {
            self.reject(
                div_line,
                SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK,
                "a records div holding no table".to_string(),
                &frame.path,
            );
            return;
        }
        let header = md_row_cells(&inner[start]);
        if header[0] != "Id" {
            self.reject(
                div_line,
                SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK,
                "a records table whose first column is not Id".to_string(),
                &frame.path,
            );
            return;
        }
        let Some(form) = list_node.element_node.as_ref().and_then(|e| self.item_form(e)) else {
            self.reject(
                div_line,
                SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK,
                "a records div in a list whose items have no single form".to_string(),
                &frame.path,
            );
            return;
        };
        let fields: Vec<SomFormFieldMeta> =
            form.node.form.as_ref().map(|f| f.fields.clone()).unwrap_or_default();
        let with_title = header.len() > 1 && header[1] == "Title";
        let first_column = if with_title { 2 } else { 1 };
        let mut columns: Vec<SomFormFieldMeta> = Vec::new();
        for name in &header[first_column..] {
            let lower = name.to_lowercase();
            let Some(field) = fields.iter().find(|f| f.name.to_lowercase() == lower) else {
                // The table is skipped whole.
                self.reject(
                    line_of(start),
                    SPEC_MARKDOWN_REJECT_UNKNOWN_FIELD,
                    format!("records column \"{}\" names no field of the items", name),
                    &frame.path,
                );
                return;
            };
            columns.push(field.clone());
        }
        let table = self.read_table(inner, start, &line_of, &frame.path);
        for (row, cells) in &table.rows {
            let (n, stored_id, has_n) = md_item_identity(list_node, &md_cell_id(&cells[0]));
            let title = if with_title {
                cells[1].replace("\\|", "|").replace("<br>", "\n")
            } else {
                String::new()
            };
            // open_item stages a title that differs from the `<stem> <n>`
            // default.
            let item_path = self.open_item(
                0,
                &frame.path,
                list_node.clone(),
                n,
                &stored_id,
                has_n,
                &title,
                &MD_NO_KEYS,
                line_of(*row),
                false,
            );
            let form_path = format!("{}/{}", item_path, form.rel);
            for (c, field) in columns.iter().enumerate() {
                let value = md_cell_value(&cells[first_column + c], field);
                if !value.is_empty() {
                    self.forms
                        .entry(form_path.clone())
                        .or_default()
                        .insert(field.name.clone(), value);
                }
            }
        }
    }

    /// Whether `n` is a `@SameAs` copy (SOM §11.2): its anchor and its
    /// descendants' are qualified with the section above it.
    fn is_copy_node(&self, n: &SomMetaNode) -> bool {
        if n.member_name.is_empty() {
            return false;
        }
        let Some(parent) = n.parent().ok().flatten() else {
            return false;
        };
        self.codec
            .model
            .class_named(&parent.class_name)
            .and_then(|c| c.field_named(&n.member_name))
            .is_some_and(|f| f.has_annotation("SameAs"))
    }
}

/// The heading keys of a list item the body registers (no heading comment).
const MD_NO_KEYS: MdHeadingKeys = MdHeadingKeys {
    code_spec: String::new(),
    units: String::new(),
};

fn stage_form_value(
    forms: &mut BTreeMap<String, BTreeMap<String, String>>,
    path: &str,
    field: &str,
    code: bool,
    lines: &[String],
) {
    let restored = md_restore_value(lines);
    let value = if code {
        md_decode_code_span(&restored)
    } else {
        restored
    };
    if !value.is_empty() {
        forms
            .entry(path.to_string())
            .or_default()
            .insert(field.to_string(), value);
    }
}

/// `^<member>-([0-9]+)$` — the anonymous `<member>-<n>` item id.
fn md_anon_item_number(member: &str, id: &str) -> Option<i64> {
    let rest = id.strip_prefix(member)?.strip_prefix('-')?;
    if rest.is_empty() || !rest.bytes().all(|b| b.is_ascii_digit()) {
        return None;
    }
    rest.parse::<i64>().ok()
}

/// `^<prefix>([0-9]+)<suffix>$` — the pattern with `xxx` as a number.
fn md_pattern_numbered(prefix: &str, suffix: &str, id: &str) -> Option<i64> {
    let mid = id.strip_prefix(prefix)?.strip_suffix(suffix)?;
    if mid.is_empty() || !mid.bytes().all(|b| b.is_ascii_digit()) {
        return None;
    }
    mid.parse::<i64>().ok()
}

/// How an item `id` of `list_node` is read, as a heading's, a records row's or
/// a section-table row's: `(n, stored_id, has_n)` — the item number it names
/// (`has_n`; else the next free one) and the id it stores (`""` for none). The
/// `<member>-<n>` fallback id is positional and stores nothing; the
/// `@SectionIdPattern` resolved with a number names item `<n>` and is stored,
/// the section id being the item's identity and the path only its position
/// (SOM §11.6); any other id is the next item, carrying it (YRD3).
fn md_item_identity(list_node: &SomMetaNode, id: &str) -> (i64, String, bool) {
    let member = if list_node.member_name.is_empty() {
        list_node.segment()
    } else {
        list_node.member_name.as_str()
    };
    if let Some(n) = md_anon_item_number(member, id) {
        return (n, String::new(), true);
    }
    let pattern = md_item_pattern(list_node);
    let parts: Vec<&str> = pattern.split("xxx").collect();
    if !pattern.is_empty() && parts.len() == 2 {
        if let Some(n) = md_pattern_numbered(parts[0], parts[1], id) {
            return (n, id.to_string(), true);
        }
    }
    (0, id.to_string(), false)
}

/// The `@SectionIdPattern` of a list's items: the list's own, else its element
/// class's.
fn md_item_pattern(list_node: &SomMetaNode) -> String {
    if !list_node.section_id_pattern.is_empty() {
        return list_node.section_id_pattern.clone();
    }
    list_node
        .element_node
        .as_ref()
        .map(|e| e.section_id_pattern.clone())
        .unwrap_or_default()
}

fn md_is_value_leaf(kind: &str) -> bool {
    kind == SOM_META_KIND_CONTENT || kind == SOM_META_KIND_SCALAR || kind == SOM_META_KIND_ENUM_VALUE
}

/// The parse-side value restoration (SOM §11.3): trim leading/trailing blank
/// lines and unescape `\#`-escaped heading lines outside fences.
/// Whether a code field's `value` is written as an inline code span (SOM §11.4
/// rule 8): it is non-empty and on one line. A multi-line value keeps the prose
/// rendering — a code span cannot cross a line break without markdown joining
/// the lines.
fn md_is_inline_code(value: &str) -> bool {
    !value.is_empty() && !value.contains('\n')
}

/// `value` as a CommonMark inline code span: delimited by one backtick more
/// than the longest backtick run inside it, and padded with one space on each
/// side when it begins or ends with a backtick or a space — the padding
/// CommonMark strips again, so the span's content is exactly `value`.
fn md_encode_code_span(value: &str) -> String {
    let mut longest = 0usize;
    let mut run = 0usize;
    for c in value.chars() {
        if c == '`' {
            run += 1;
            longest = longest.max(run);
        } else {
            run = 0;
        }
    }
    let fence = "`".repeat(longest + 1);
    let edge = |c: Option<char>| matches!(c, Some('`') | Some(' '));
    let pad = if edge(value.chars().next()) || edge(value.chars().last()) {
        " "
    } else {
        ""
    };
    format!("{}{}{}{}{}", fence, pad, value, pad, fence)
}

/// The inverse of the emitter's code span (SOM §11.4 rule 8): a single-line
/// `value` delimited by equal backtick runs loses them, and one padding space on
/// each side when both are present. Anything else — a value written by hand
/// without a span — is kept as written.
fn md_decode_code_span(value: &str) -> String {
    if value.contains('\n') {
        return value.to_string();
    }
    // `^(`+)([\s\S]*[^`])(`+)$`: the maximal leading and trailing backtick
    // runs around an inner part that holds at least one other character.
    let lead = value.len() - value.trim_start_matches('`').len();
    let trail = value.len() - value.trim_end_matches('`').len();
    if lead == 0 || trail == 0 || lead == value.len() || lead != trail {
        return value.to_string();
    }
    let inner = &value[lead..value.len() - trail];
    if inner.len() >= 2 && inner.starts_with(' ') && inner.ends_with(' ') && !inner.trim().is_empty() {
        return inner[1..inner.len() - 1].to_string();
    }
    inner.to_string()
}

fn md_restore_value(body: &[String]) -> String {
    let mut fence = MarkdownFenceTracker::new();
    let mut out: Vec<&str> = Vec::with_capacity(body.len());
    for line in body {
        if !fence.in_fence() && md_escaped_heading(line) {
            out.push(&line[1..]);
        } else if !fence.in_fence() && md_header_shaped(line, 1) {
            out.push(&line[1..]); // DI-2: the emitter's escape space.
        } else {
            out.push(line);
        }
        fence.feed(line);
    }
    let joined = out.join("\n");
    let stripped = md_strip_leading_blank_lines(&joined);
    md_strip_trailing_blank_lines(stripped).to_string()
}

fn md_lists_json(
    list_order: &[String],
    lists: &HashMap<String, MdListState>,
) -> BTreeMap<String, ListJson> {
    let mut out = BTreeMap::new();
    for key in list_order {
        let state = &lists[key];
        out.insert(
            key.clone(),
            ListJson {
                seq: state.max_n,
                items: state.items.clone(),
                ids: state.ids.clone(),
            },
        );
    }
    out
}

#[cfg(test)]
mod heading_key_tests {
    use super::{md_code_spec_of, md_units_of};

    // Both keys follow the pattern `"…"|'…'|[^,\s>]+`: an unclosed quote is
    // not a quoted value, so the third alternative reads it as a bare one.
    #[test]
    fn code_spec_and_units_read_quoted_bare_and_unclosed_alike() {
        assert_eq!(md_code_spec_of(r#" codeSpec="A,B""#), "A,B");
        assert_eq!(md_code_spec_of(" codeSpec='A'"), "A");
        assert_eq!(md_code_spec_of(" codeSpec=A,B"), "A");
        assert_eq!(md_code_spec_of(r#" codeSpec="A"#), r#""A"#);
        assert_eq!(md_units_of(r#" units="A"#), r#""A"#);
        assert_eq!(md_code_spec_of(" other=1"), "");
    }
}
