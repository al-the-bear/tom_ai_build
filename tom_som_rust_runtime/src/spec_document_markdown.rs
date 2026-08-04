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
//! Escaping (SOM §11.3): a content line starting with `#` at column 0 is
//! emitted as `\#` (and a leading `\#`… run gains one more backslash), except
//! inside fenced code blocks, which shield their lines verbatim. Consecutive
//! blank lines are collapsed to one on emit; parse trims each value of
//! leading/trailing blank lines and does not re-collapse.
//!
//! The codec is free of any UI: it reads from / resolves against a
//! [`SpecModel`] (through the [`build_som_meta_tree`] metadata tree) and a
//! [`SpecDocument`]. Parse does **not** mutate the document — it returns
//! staged values keyed exactly like `SpecDocument::to_json` plus a rejection
//! report; the caller applies them. Anything that cannot be mapped — an
//! unknown section id, a child heading under a value leaf, orphaned text — is
//! collected into [`SpecMarkdownResult::rejections`] rather than dropped
//! (SOM §11.7).
//!
//! Rust conventions: where the other ports throw, `export_root` returns
//! `Err(String)` (the unterminated-fence case); the empty string stands in for
//! a null anchor. The Go regexes are hand-rolled here to keep the
//! zero-dependency promise; the message strings are byte-identical to Go.

use std::cell::RefCell;
use std::collections::{BTreeMap, BTreeSet, HashMap};
use std::rc::Rc;

use crate::spec_document::{DocumentJson, ListJson, SpecDocument};
use crate::spec_meta::{
    SomFormFieldMeta, SomMetaNode, SomMetaTree, SOM_META_KIND_COMPLEX, SOM_META_KIND_CONTENT,
    SOM_META_KIND_ENUM_VALUE, SOM_META_KIND_FORM, SOM_META_KIND_LIST, SOM_META_KIND_SCALAR,
    SOM_META_KIND_SECTION,
};
use crate::spec_meta_bridge::build_som_meta_tree;
use crate::spec_model::{SpecModel, SpecRoot};

// Why an imported Markdown block was rejected (SOM §11.7 rejection protocol).

/// The heading's section id does not resolve against the schema tree at its
/// nesting position.
pub const SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION: &str = "unknownSection";
/// A structurally impossible combination, e.g. a child heading nested under a
/// value-leaf (content/scalar/enum) section.
pub const SPEC_MARKDOWN_REJECT_KIND_MISMATCH: &str = "kindMismatch";
/// Body text with no owning value slot, e.g. prose inside a `@Form` section
/// before the first `FieldName:` line.
pub const SPEC_MARKDOWN_REJECT_ORPHAN_CONTENT: &str = "orphanContent";
/// A value-leaf section heading with an empty body.
pub const SPEC_MARKDOWN_REJECT_MISSING_VALUE: &str = "missingValue";
/// A heading line without a parseable `<!--[id]-->` headline comment.
pub const SPEC_MARKDOWN_REJECT_MALFORMED_HEADING: &str = "malformedHeading";

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
        }
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

/// Extracts the `codeSpec="…"` value from a heading-comment key=value region
/// (`mdCodeSpecRE`: `codeSpec=(?:"([^"]*)"|'([^']*)'|([^,\s>]+))`), the first
/// matching group trimmed; the empty string when the region carries no
/// `codeSpec` key (codespecs_mapping.md §9.2).
pub(crate) fn md_code_spec_of(region: &str) -> String {
    // Find `codeSpec=` then read a double-quoted, single-quoted, or bare value.
    let mut search = region;
    while let Some(pos) = search.find("codeSpec=") {
        let after = &search[pos + "codeSpec=".len()..];
        let b = after.as_bytes();
        if b.first() == Some(&b'"') {
            if let Some(end) = after[1..].find('"') {
                return after[1..1 + end].trim().to_string();
            }
        } else if b.first() == Some(&b'\'') {
            if let Some(end) = after[1..].find('\'') {
                return after[1..1 + end].trim().to_string();
            }
        } else {
            // Bare: `[^,\s>]+` — one or more chars that are not comma,
            // whitespace, or `>`.
            let mut i = 0;
            let ab = after.as_bytes();
            while i < ab.len() {
                let c = ab[i] as char;
                if c == ',' || c == '>' || is_go_space(c) {
                    break;
                }
                i += 1;
            }
            if i > 0 {
                return after[..i].trim().to_string();
            }
        }
        // No value matched at this occurrence; advance past it.
        search = after;
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

// --- Value normalisation helpers ----------------------------------------------

/// `mdBlankRunRE` (`\n{3,}` → `\n\n`), then `^\n+` / `\n+$` trims.
fn md_collapse_blank_runs(value: &str) -> String {
    let mut out = String::with_capacity(value.len());
    let mut run = 0;
    for ch in value.chars() {
        if ch == '\n' {
            run += 1;
            if run <= 2 {
                out.push('\n');
            }
        } else {
            run = 0;
            out.push(ch);
        }
    }
    let out = out.trim_start_matches('\n');
    let out = out.trim_end_matches('\n');
    out.to_string()
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
}

impl<'a> SpecDocumentMarkdown<'a> {
    /// Binds model and document to the codec.
    pub fn new(model: &'a SpecModel, document: &'a SpecDocument) -> SpecDocumentMarkdown<'a> {
        SpecDocumentMarkdown {
            model,
            document,
            trees: RefCell::new(HashMap::new()),
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
        if node.kind == SOM_META_KIND_SECTION || node.kind == SOM_META_KIND_COMPLEX {
            if let Some(cls) = self.model.class_named(&node.class_name) {
                if !cls.section_id.is_empty() {
                    return cls.section_id.clone();
                }
            }
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
        match self.model.class_named(&n.class_name) {
            Some(cls) => cls.section_id.is_empty(),
            None => true,
        }
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
    /// document. Returns an error when a content value contains an
    /// unterminated fenced code block (which would shield the remainder of the
    /// document from heading detection and break the round-trip) — the Rust
    /// analogue of the other ports' throw.
    pub fn export_root(&self, root: &SpecRoot) -> Result<String, String> {
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
        md_write_heading(
            &mut b,
            1,
            &root_seg,
            &root_title,
            &self.document.code_spec_or(&root_seg),
        );
        self.write_section_body(&mut b, &node, &root_seg)?;
        self.write_children(&mut b, &node, &root_seg, 2)?;
        Ok(b.out)
    }

    /// Writes the body region of a section heading: the section path's own
    /// content value plus every transparent body slot (id-less content text
    /// and form blocks, hoisted through transparent sections) in model order.
    fn write_section_body(
        &self,
        b: &mut MdBuffer,
        node: &SomMetaNode,
        path: &str,
    ) -> Result<(), String> {
        if let Some(value) = self.document.content(path) {
            self.write_body(b, value, path)?;
        }
        for slot in self.body_slots(node) {
            let slot_path = format!("{}/{}", path, slot.rel);
            if slot.node.kind == SOM_META_KIND_FORM {
                if self.form_has_values(&slot.node, &slot_path) {
                    self.write_form(b, &slot.node, &slot_path)?;
                }
            } else if let Some(value) = self.document.content(&slot_path) {
                self.write_body(b, value, &slot_path)?;
            }
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
                    md_write_heading(
                        b,
                        depth,
                        &self.heading_id_of(child),
                        &self.heading_title(&path, child),
                        &self.document.code_spec_or(&path),
                    );
                    self.write_body(b, &value, &path)?;
                }
                SOM_META_KIND_FORM => {
                    if !self.form_has_values(child, &path) {
                        continue;
                    }
                    md_write_heading(
                        b,
                        depth,
                        &self.heading_id_of(child),
                        &self.heading_title(&path, child),
                        &self.document.code_spec_or(&path),
                    );
                    self.write_form(b, child, &path)?;
                }
                SOM_META_KIND_SECTION | SOM_META_KIND_COMPLEX => {
                    md_write_heading(
                        b,
                        depth,
                        &self.heading_id_of(child),
                        &self.heading_title(&path, child),
                        &self.document.code_spec_or(&path),
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
        md_write_heading(
            b,
            depth,
            &self.heading_id_of(node),
            &self.heading_title(list_path, node),
            &self.document.code_spec_or(list_path),
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
            md_write_heading(
                b,
                depth + 1,
                &item_id,
                &item_title,
                &self.document.code_spec_or(item_path),
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

    fn form_has_values(&self, node: &SomMetaNode, path: &str) -> bool {
        match &node.form {
            None => false,
            Some(form) => form
                .fields
                .iter()
                .any(|f| self.document.form_field(path, &f.name).is_some()),
        }
    }

    fn write_form(&self, b: &mut MdBuffer, node: &SomMetaNode, path: &str) -> Result<(), String> {
        let empty: Vec<SomFormFieldMeta> = Vec::new();
        let fields = match &node.form {
            Some(form) => &form.fields,
            None => &empty,
        };
        for f in fields {
            let value = match self.document.form_field(path, &f.name) {
                Some(v) => v.clone(),
                None => continue,
            };
            let prepared = self.prepare_value(&value, path)?;
            let mut lines = prepared.split('\n');
            let first = lines.next().unwrap_or("");
            b.writeln(&format!("{}: {}", spec_markdown_form_label(&f.name), first));
            for line in lines {
                // SOM §11.4 generalised: any continuation line that could be
                // mistaken for a field-label line gains one leading space;
                // parse strips it.
                if md_label_shaped(line) {
                    b.writeln(&format!(" {}", line));
                } else {
                    b.writeln(line);
                }
            }
        }
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

    /// The emit-side value normalisation (SOM §11.3): collapse 2+ blank lines
    /// to one, trim leading/trailing blank lines, escape heading-like lines
    /// outside fences. Returns an error for an unterminated fence.
    fn prepare_value(&self, value: &str, path: &str) -> Result<String, String> {
        let collapsed = md_collapse_blank_runs(value);
        let mut fence = MarkdownFenceTracker::new();
        let mut out: Vec<String> = Vec::new();
        for line in collapsed.split('\n') {
            if fence.in_fence() {
                out.push(line.to_string()); // SOM §11.3: fences shield their lines.
            } else if md_escapable(line) {
                out.push(format!("\\{}", line));
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
    /// mutating the document. The caller applies the result as a full
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
fn md_write_heading(b: &mut MdBuffer, depth: usize, id: &str, title: &str, code_spec: &str) {
    // codespecs_mapping.md §9.2: when a codeSpec mapping is present it rides
    // inside the same headline comment as a `codeSpec="…"` key: `## <!--[ID]
    // codeSpec="A,B"--> Title`. Byte-identical to the id-only form when empty.
    let code = if code_spec.is_empty() {
        String::new()
    } else {
        format!(" codeSpec=\"{}\"", code_spec)
    };
    b.writeln(&format!(
        "{} <!--[{}]{}--> {}",
        "#".repeat(depth),
        id,
        code,
        title
    ));
    b.writeln("");
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
}

impl MdFrame {
    fn ignored(level: usize, line: usize) -> MdFrame {
        MdFrame {
            level,
            node: None,
            path: String::new(),
            line,
            ignored: true,
            body: Vec::new(),
        }
    }
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
    rejections: Vec<SpecMarkdownRejection>,
    root_prefixes: BTreeSet<String>,
    stack: Vec<MdFrame>,
    fence: MarkdownFenceTracker,
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
            rejections: Vec::new(),
            root_prefixes: BTreeSet::new(),
            stack: Vec::new(),
            fence: MarkdownFenceTracker::new(),
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
        let (id, code_spec, title) = match md_headline_comment(rest.trim()) {
            Some((id, region, title)) => {
                (id.to_string(), md_code_spec_of(region), title.to_string())
            }
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

        if self.stack.is_empty() {
            self.open_root(level, &id, &title, &code_spec, line_no);
            return;
        }

        let (parent_ignored, parent_node, parent_path) = {
            let parent = self.stack.last().unwrap();
            (parent.ignored, parent.node.clone(), parent.path.clone())
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
            self.open_item_heading(level, &parent_path, p_node, &id, &title, &code_spec, line_no);
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
                // Stage the heading title as a stored headline only when it
                // differs from the effective default (SOM §11.7).
                if !title.is_empty() && title != md_title_of(&entry.node) {
                    self.headlines.insert(path.clone(), title);
                }
                // codespecs_mapping.md §9.2: stage the codeSpec mapping
                // whenever present (no default).
                if !code_spec.is_empty() {
                    self.code_specs.insert(path.clone(), code_spec.clone());
                }
                self.stack.push(MdFrame {
                    level,
                    node: Some(entry.node.clone()),
                    path,
                    line: line_no,
                    ignored: false,
                    body: Vec::new(),
                });
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

    fn open_root(&mut self, level: usize, id: &str, title: &str, code_spec: &str, line_no: usize) {
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
                // whenever present.
                if !code_spec.is_empty() {
                    self.code_specs.insert(seg.to_string(), code_spec.to_string());
                }
                self.root_prefixes.insert(seg.to_string());
                self.stack.push(MdFrame {
                    level,
                    node: Some(tree.root.clone()),
                    path: seg.to_string(),
                    line: line_no,
                    ignored: false,
                    body: Vec::new(),
                });
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

    /// Opens a list-item frame under a `-LST` container frame (SOM §11.2). The
    /// heading `id` is matched positionally against the container's list: the
    /// `<member>-<n>` fallback id, the `@SectionIdPattern` resolved with a
    /// number (`GOAL-ITEM-3`, parses back as item `<n>`), a pattern-shaped
    /// stored id, or — for any other id — an anonymous next item carrying the
    /// stored id.
    #[allow(clippy::too_many_arguments)]
    fn open_item_heading(
        &mut self,
        level: usize,
        list_path: &str,
        list_node: Rc<SomMetaNode>,
        id: &str,
        title: &str,
        code_spec: &str,
        line_no: usize,
    ) {
        let member = if list_node.member_name.is_empty() {
            list_node.segment().to_string()
        } else {
            list_node.member_name.clone()
        };
        if let Some(n) = md_anon_item_number(&member, id) {
            self.open_item(level, list_path, list_node, n, "", true, title, code_spec, line_no);
            return;
        }
        let mut pattern = list_node.section_id_pattern.clone();
        if pattern.is_empty() {
            if let Some(e) = list_node.element_node.as_ref() {
                pattern = e.section_id_pattern.clone();
            }
        }
        if !pattern.is_empty() {
            // Canonical anonymous id: the pattern with `xxx` as a number —
            // parses back as item <n>, NOT as a stored id (SOM §11.2 round-trip).
            let parts: Vec<&str> = pattern.split("xxx").collect();
            if parts.len() == 2 {
                if let Some(n) = md_pattern_numbered(parts[0], parts[1], id) {
                    self.open_item(level, list_path, list_node, n, "", true, title, code_spec, line_no);
                    return;
                }
            }
            if md_pattern_matches(&pattern, id) {
                self.open_item(level, list_path, list_node, 0, id, false, title, code_spec, line_no);
                return;
            }
        }
        // Any other id under the container is a stored-id item: the id is kept
        // as the item's stored `@SectionId` and round-trips through md (YRD3).
        self.open_item(level, list_path, list_node, 0, id, false, title, code_spec, line_no);
    }

    /// Opens a list-item frame. `n` (with `has_n = true`) is the anonymous
    /// heading number (also the path number); a stored-id item gets the next
    /// free number instead.
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
        code_spec: &str,
        line_no: usize,
    ) {
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
        if !has_n {
            state.ids.insert(item_path.clone(), stored_id.to_string());
        }
        // Stage the heading title as a stored headline only when it differs
        // from the derived `<stem> <n>` default (SOM §11.7).
        let stem = md_item_stem_of(&list_node);
        if !title.is_empty() && title != format!("{} {}", stem, number) {
            self.headlines.insert(item_path.clone(), title.to_string());
        }
        // codespecs_mapping.md §9.2: stage the item codeSpec mapping whenever
        // present (no default).
        if !code_spec.is_empty() {
            self.code_specs.insert(item_path.clone(), code_spec.to_string());
        }
        self.stack.push(MdFrame {
            level,
            node: list_node.element_node.clone(),
            path: item_path,
            line: line_no,
            ignored: false,
            body: Vec::new(),
        });
    }

    // --- Body finalisation -----------------------------------------------------

    fn finalize(&mut self, frame: MdFrame) {
        if frame.ignored {
            return;
        }
        if let Some(node) = &frame.node {
            if node.kind == SOM_META_KIND_FORM {
                let node = node.clone();
                self.finalize_form(&frame, &node, &frame.path.clone());
                return;
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

    /// Binds a heading's body region against the owner's transparent body
    /// slots (SOM §11.2 transparency): `FieldName:` lines matching a
    /// transparent form's fields route to that form (nearest form in slot
    /// order, wrapping); all other text binds to the first non-form slot — or
    /// to the owner's own path when no such slot exists.
    fn finalize_body_slots(&mut self, frame: &MdFrame, slots: Vec<MdNodeRel>) {
        let mut form_slots: Vec<MdNodeRel> = Vec::new();
        let mut content_slots: Vec<MdNodeRel> = Vec::new();
        for s in slots {
            if s.node.kind == SOM_META_KIND_FORM {
                form_slots.push(s);
            } else {
                content_slots.push(s);
            }
        }
        let content_path = if content_slots.is_empty() {
            frame.path.clone()
        } else {
            format!("{}/{}", frame.path, content_slots[0].rel)
        };

        if form_slots.is_empty() {
            let value = md_restore_value(&frame.body);
            if !value.is_empty() {
                self.content.insert(content_path, value);
            }
            return;
        }

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
        let mut current_lines: Vec<String> = Vec::new();
        let mut content_lines: Vec<String> = Vec::new();

        for line in frame.body.iter() {
            if !fence.in_fence() {
                if let Some((label, first)) = md_field_label(line) {
                    if let Some((idx, field)) = find_field(current_form_idx, label) {
                        if have_field {
                            stage_form_value(
                                &mut self.forms,
                                &current_form_path,
                                &current_field,
                                &current_lines,
                            );
                        }
                        current_lines = Vec::new();
                        current_form_idx = idx;
                        have_field = true;
                        current_field = field.name;
                        current_form_path = format!("{}/{}", frame.path, form_slots[idx].rel);
                        current_lines.push(first.to_string());
                        fence.feed(line);
                        continue;
                    }
                }
            }
            // Continuation: strip the one escape space of a label-shaped line.
            let text = if !fence.in_fence() && have_field && md_continuation_label(line) {
                &line[1..]
            } else {
                line.as_str()
            };
            if have_field {
                current_lines.push(text.to_string());
            } else {
                content_lines.push(text.to_string());
            }
            fence.feed(line);
        }
        if have_field {
            stage_form_value(
                &mut self.forms,
                &current_form_path,
                &current_field,
                &current_lines,
            );
        }
        let value = md_restore_value(&content_lines);
        if !value.is_empty() {
            self.content.insert(content_path, value);
        }
    }

    fn finalize_form(&mut self, frame: &MdFrame, node: &SomMetaNode, path: &str) {
        let mut fields_by_lower: HashMap<String, String> = HashMap::new();
        if let Some(form) = &node.form {
            for f in &form.fields {
                fields_by_lower.insert(f.name.to_lowercase(), f.name.clone());
            }
        }
        let mut fence = MarkdownFenceTracker::new();
        let mut current_field = String::new();
        let mut have_field = false;
        let mut current_lines: Vec<String> = Vec::new();

        for (i, line) in frame.body.iter().enumerate() {
            if !fence.in_fence() {
                if let Some((label, first)) = md_field_label(line) {
                    if let Some(field_name) = fields_by_lower.get(&label.to_lowercase()) {
                        let field_name = field_name.clone();
                        self.flush_form_lines(
                            path,
                            have_field,
                            &current_field,
                            &current_lines,
                            frame.line + i,
                        );
                        current_lines = Vec::new();
                        have_field = true;
                        current_field = field_name;
                        current_lines.push(first.to_string());
                        fence.feed(line);
                        continue;
                    }
                }
            }
            // Continuation: strip the one escape space of a label-shaped line.
            if !fence.in_fence() && md_continuation_label(line) {
                current_lines.push(line[1..].to_string());
            } else {
                current_lines.push(line.clone());
            }
            fence.feed(line);
        }
        self.flush_form_lines(
            path,
            have_field,
            &current_field,
            &current_lines,
            frame.line + frame.body.len(),
        );
    }

    fn flush_form_lines(
        &mut self,
        path: &str,
        have_field: bool,
        current_field: &str,
        current_lines: &[String],
        line_no: usize,
    ) {
        if have_field {
            stage_form_value(&mut self.forms, path, current_field, current_lines);
        } else if current_lines.iter().any(|l| !l.trim().is_empty()) {
            self.rejections.push(SpecMarkdownRejection {
                line: line_no,
                reason: SPEC_MARKDOWN_REJECT_ORPHAN_CONTENT.to_string(),
                message: "text in a @Form section before the first field label".to_string(),
                anchor: path.to_string(),
            });
        }
    }
}

fn stage_form_value(
    forms: &mut BTreeMap<String, BTreeMap<String, String>>,
    path: &str,
    field: &str,
    lines: &[String],
) {
    let value = md_restore_value(lines);
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

/// `GOAL-ITEM-xxx` → `^GOAL-ITEM-.+$` — the `@SectionIdPattern` wildcard.
fn md_pattern_matches(pattern: &str, id: &str) -> bool {
    let parts: Vec<&str> = pattern.split("xxx").collect();
    md_match_dot_plus(&parts, id)
}

/// Matches `parts` joined by `.+` (one-or-more characters) against `s`.
fn md_match_dot_plus(parts: &[&str], s: &str) -> bool {
    let first = parts[0];
    if !s.starts_with(first) {
        return false;
    }
    let rest = &s[first.len()..];
    if parts.len() == 1 {
        return rest.is_empty();
    }
    let mut boundaries: Vec<usize> = rest.char_indices().map(|(i, _)| i).collect();
    boundaries.push(rest.len());
    for &k in boundaries.iter().skip(1) {
        if md_match_dot_plus(&parts[1..], &rest[k..]) {
            return true;
        }
    }
    false
}

fn md_is_value_leaf(kind: &str) -> bool {
    kind == SOM_META_KIND_CONTENT || kind == SOM_META_KIND_SCALAR || kind == SOM_META_KIND_ENUM_VALUE
}

/// The parse-side value restoration (SOM §11.3): trim leading/trailing blank
/// lines and unescape `\#`-escaped heading lines outside fences.
fn md_restore_value(body: &[String]) -> String {
    let mut fence = MarkdownFenceTracker::new();
    let mut out: Vec<&str> = Vec::with_capacity(body.len());
    for line in body {
        if !fence.in_fence() && md_escaped_heading(line) {
            out.push(&line[1..]);
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
