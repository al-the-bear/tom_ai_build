//! Stripped renditions (SOM §11.10; the reading view's part *Stripped
//! renditions and the merge back*): a copy of a value with the secondary prose
//! of named kinds dropped, unmarked or moved to an appendix.
//!
//! The kinds are the four the reading notation registers as secondary
//! (`provenance`, `trace`, `editorial`, `aside`, DocSpecs RN-5), `linked`, the
//! navigation marker (SOM §11.11), and `derived`, the generated parts (SOM
//! §11.12) — both removed by `drop` and `unmark` alike —, and `comments`, the
//! review annotations (SOM §11.9). A citation shape counts as a span of its
//! kind. `refs`, `records` and `rejected` are never secondary: no name drops or
//! unmarks them (RN-11).
//!
//! The Rust port of `spec_document_strip.ts` / `spec_document_strip.dart`:
//! the strip of one value, [`strip_notation_text`] with [`SpecStripOptions`]
//! (and [`SpecStripOptions::from_names`], which refuses with
//! [`SpecStripUsageError`]), [`SpecStripTextResult`], [`SpecStripPiece`] and
//! [`SpecAppendixEntry`]; the strip of a whole document,
//! [`SpecDocumentStrip::strip`] with [`SpecStripResult`]; and the readable
//! header of a stripped rendition, [`SpecReadableHeader`].
//! `strip_cases.json` holds them to the same results.
//!
//! **Offsets are UTF-16 code units**, as in every other runtime: a piece's
//! `anchor` and `origin` count UTF-16 units. A Rust string is UTF-8, so the
//! plan works on the value as a vector of UTF-16 code units (a supplementary
//! character as its two surrogates) — the indexing the notation scanner's
//! offsets and the TypeScript reference use, so the edit scripts and every
//! "one character" step mean what they mean there — and turns every text it
//! hands out back into an ordinary string.

use std::collections::{BTreeMap, BTreeSet, HashMap};
use std::fmt;

use crate::docspecs_validator::{DocSpecsSchema, DocSpecsValidator, DocSpecsViolation};
use crate::json::Json;
use crate::spec_document::SpecDocument;
use crate::spec_document_markdown::{
    markdown_heading_title, MarkdownFenceTracker, SpecDocumentMarkdown, SpecMarkdownExportOptions,
    SpecMarkdownRendition, SPEC_MARKDOWN_APPENDIX_MARKER,
};
use crate::spec_model::{SpecModel, SpecRoot};
use crate::spec_notation::{scan_notation, NotationElement, NotationFinding, NotationFindingCode};
use crate::spec_review_annotations::{count_annotations_text, strip_annotations_text};
use crate::spec_schema_validation::validate_spec_document;
use crate::spec_validator::validate_document;

/// The kind names a strip takes, in report and header order.
pub const SPEC_STRIP_KIND_NAMES: [&str; 7] = [
    "provenance",
    "trace",
    "editorial",
    "aside",
    "linked",
    "derived",
    "comments",
];

/// The notation kinds a strip can drop, unmark or move to the appendix.
pub const SPEC_STRIP_NOTATION_KINDS: [&str; 4] = ["provenance", "trace", "editorial", "aside"];

/// The kind names a strip takes ([`SPEC_STRIP_KIND_NAMES`]).
pub fn spec_strip_kind_names() -> &'static [&'static str] {
    &SPEC_STRIP_KIND_NAMES
}

/// The notation kinds a strip can drop, unmark or move to the appendix
/// ([`SPEC_STRIP_NOTATION_KINDS`]).
pub fn spec_strip_notation_kinds() -> &'static [&'static str] {
    &SPEC_STRIP_NOTATION_KINDS
}

/// A strip asked for something it cannot do; the message says which.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecStripUsageError {
    pub message: String,
}

impl SpecStripUsageError {
    pub(crate) fn new(message: impl Into<String>) -> SpecStripUsageError {
        SpecStripUsageError {
            message: message.into(),
        }
    }
}

impl fmt::Display for SpecStripUsageError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.message)
    }
}

impl std::error::Error for SpecStripUsageError {}

/// What a strip does with each kind. [`SpecStripOptions::from_names`] is the
/// checked form; the fields take the sets as they are.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct SpecStripOptions {
    /// The kinds removed with their content.
    pub drop: BTreeSet<String>,
    /// The kinds whose markers go and whose content stays.
    pub unmark: BTreeSet<String>,
    /// The kinds moved, with their content, into the appendix *Notes*.
    pub appendix: BTreeSet<String>,
    /// Whether each moved element leaves a link `[n]` to its entry.
    pub appendix_references: bool,
    /// Whether sections deeper than level 6 are styled-div headings.
    pub heading_divs: bool,
}

impl SpecStripOptions {
    /// Whether the rendition leaves the `linked` markers out (SOM §11.11):
    /// `linked` dropped or unmarked.
    pub fn writes_no_linked_markers(&self) -> bool {
        self.drop.contains("linked") || self.unmark.contains("linked")
    }

    /// Whether the rendition leaves the generated parts out (SOM §11.12):
    /// `derived` dropped or unmarked.
    pub fn writes_no_generated_parts(&self) -> bool {
        self.drop.contains("derived") || self.unmark.contains("derived")
    }

    /// The options from the names a user gives, each item possibly
    /// comma-joined. `all` stands for every kind the list can hold that no
    /// other list names explicitly. Refused with [`SpecStripUsageError`]: an
    /// unknown name, a name in two lists, `comments` to unmark or move,
    /// `linked` / `derived` to move, and appendix references without an
    /// appendix.
    pub fn from_names<S: AsRef<str>>(
        drop: &[S],
        unmark: &[S],
        appendix: &[S],
        appendix_references: bool,
        heading_divs: bool,
    ) -> Result<SpecStripOptions, SpecStripUsageError> {
        fn names<S: AsRef<str>>(list: &[S]) -> Vec<String> {
            list.iter()
                .flat_map(|item| item.as_ref().split(','))
                .map(|n| n.trim_matches(is_ascii_trim))
                .filter(|n| !n.is_empty())
                .map(str::to_string)
                .collect()
        }
        let lists: [(&str, Vec<String>); 3] = [
            ("drop", names(drop)),
            ("unmark", names(unmark)),
            ("appendix", names(appendix)),
        ];
        let mut known: Vec<&str> = SPEC_STRIP_KIND_NAMES.to_vec();
        known.push("all");
        for (list, items) in &lists {
            if let Some(n) = items.iter().find(|n| !known.contains(&n.as_str())) {
                return Err(SpecStripUsageError::new(format!(
                    "unknown kind name \"{}\" in {}; known names: {}",
                    n,
                    list,
                    known.join(", ")
                )));
            }
        }
        for i in 0..3 {
            for j in i + 1..3 {
                if let Some(n) = lists[i].1.iter().find(|n| lists[j].1.contains(n)) {
                    return Err(SpecStripUsageError::new(format!(
                        "kind name \"{}\" is in both {} and {}",
                        n, lists[i].0, lists[j].0
                    )));
                }
            }
        }
        let has = |list: usize, n: &str| lists[list].1.iter().any(|x| x == n);
        if has(1, "comments") {
            return Err(SpecStripUsageError::new(
                "comments cannot be unmarked: a review annotation has no reading \
                 without its markers; drop it or leave it",
            ));
        }
        if has(2, "comments") {
            return Err(SpecStripUsageError::new(
                "comments cannot be moved to the appendix; drop them or leave them",
            ));
        }
        for k in ["linked", "derived"] {
            if has(2, k) {
                return Err(SpecStripUsageError::new(format!(
                    "{} cannot be moved to the appendix: the renderer writes it from \
                     the document; drop it or leave it",
                    k
                )));
            }
        }
        let explicit: BTreeSet<&str> = lists
            .iter()
            .flat_map(|(_, items)| items.iter().map(String::as_str))
            .filter(|n| *n != "all")
            .collect();
        let expand = |list: usize, all: &[&str]| -> BTreeSet<String> {
            let mut out = BTreeSet::new();
            for n in &lists[list].1 {
                if n == "all" {
                    for k in all {
                        if !explicit.contains(k) {
                            out.insert((*k).to_string());
                        }
                    }
                } else {
                    out.insert(n.clone());
                }
            }
            out
        };
        let appendix = expand(2, &SPEC_STRIP_NOTATION_KINDS);
        if appendix_references && appendix.is_empty() {
            return Err(SpecStripUsageError::new(
                "appendix references need an appendix: name its kinds",
            ));
        }
        let mut unmarkable: Vec<&str> = SPEC_STRIP_NOTATION_KINDS.to_vec();
        unmarkable.extend(["linked", "derived"]);
        Ok(SpecStripOptions {
            drop: expand(0, &SPEC_STRIP_KIND_NAMES),
            unmark: expand(1, &unmarkable),
            appendix,
            appendix_references,
            heading_divs,
        })
    }

    /// The options of the emptying rule: what would go is unmarked instead
    /// (comments still dropped).
    pub fn keeping(&self) -> SpecStripOptions {
        let mut o = SpecStripOptions {
            heading_divs: self.heading_divs,
            ..SpecStripOptions::default()
        };
        if self.drop.contains("comments") {
            o.drop.insert("comments".to_string());
        }
        o.unmark = self.unmark.clone();
        o.unmark.extend(self.appendix.iter().cloned());
        o.unmark
            .extend(self.drop.iter().filter(|k| *k != "comments").cloned());
        o
    }

    /// The options an appendix entry's own content is stripped with: the
    /// drops without comments, the appendix kinds unmarked.
    pub fn in_entry(&self) -> SpecStripOptions {
        let mut o = SpecStripOptions {
            drop: self.drop.clone(),
            unmark: self.unmark.clone(),
            ..SpecStripOptions::default()
        };
        o.drop.remove("comments");
        o.unmark.extend(self.appendix.iter().cloned());
        o
    }

    /// `names` in the canonical order of [`SPEC_STRIP_KIND_NAMES`].
    pub fn ordered<'a, I: IntoIterator<Item = &'a String>>(names: I) -> Vec<String> {
        let names: Vec<&String> = names.into_iter().collect();
        SPEC_STRIP_KIND_NAMES
            .iter()
            .filter(|k| names.iter().any(|n| n.as_str() == **k))
            .map(|k| (*k).to_string())
            .collect()
    }

    /// The options as the conformance corpus writes them.
    pub fn to_json(&self) -> Json {
        let kinds = |s: &BTreeSet<String>| {
            Json::Array(
                SpecStripOptions::ordered(s)
                    .into_iter()
                    .map(Json::Str)
                    .collect(),
            )
        };
        Json::Object(vec![
            ("drop".to_string(), kinds(&self.drop)),
            ("unmark".to_string(), kinds(&self.unmark)),
            ("appendix".to_string(), kinds(&self.appendix)),
            (
                "appendixReferences".to_string(),
                Json::Bool(self.appendix_references),
            ),
            ("headingDivs".to_string(), Json::Bool(self.heading_divs)),
        ])
    }
}

/// Dart's / JavaScript's `trim()` over the ASCII whitespace a kind name can
/// carry.
fn is_ascii_trim(c: char) -> bool {
    matches!(c, ' ' | '\t' | '\n' | '\r' | '\u{0B}' | '\u{0C}')
}

/// One piece a strip removed from a value, anchored in the stripped text.
/// Offsets are UTF-16 code units.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecStripPiece {
    /// The offset in the stripped text the piece stands at.
    pub anchor: usize,
    /// The offset in the original text the piece starts at.
    pub origin: usize,
    /// The original text the piece removed.
    pub removed: String,
    /// The text the stripped value holds in its place.
    pub inserted: String,
    /// What removed it, sorted.
    pub labels: Vec<String>,
}

impl SpecStripPiece {
    /// The piece as the conformance corpus writes it.
    pub fn to_json(&self) -> Json {
        Json::Object(vec![
            ("anchor".to_string(), Json::Int(self.anchor as i64)),
            ("origin".to_string(), Json::Int(self.origin as i64)),
            ("removed".to_string(), Json::Str(self.removed.clone())),
            ("inserted".to_string(), Json::Str(self.inserted.clone())),
            (
                "labels".to_string(),
                Json::Array(self.labels.iter().cloned().map(Json::Str).collect()),
            ),
        ])
    }
}

/// One entry of a stripped rendition's appendix *Notes*. `value` is the
/// value it came from when a document is stripped
/// ([`SpecDocumentStrip::strip`]); `None` for the strip of one value.
#[derive(Debug, Clone, PartialEq)]
pub struct SpecAppendixEntry {
    pub number: i64,
    pub kind: String,
    pub text: String,
    pub value: Option<SpecStripValueRef>,
}

impl SpecAppendixEntry {
    /// The entry as the conformance corpus writes it.
    pub fn to_json(&self) -> Json {
        let mut out = vec![
            ("number".to_string(), Json::Int(self.number)),
            ("kind".to_string(), Json::Str(self.kind.clone())),
            ("text".to_string(), Json::Str(self.text.clone())),
        ];
        if let Some(v) = &self.value {
            out.push(("value".to_string(), v.to_json()));
        }
        Json::Object(out)
    }
}

/// The result of stripping one value ([`strip_notation_text`]).
#[derive(Debug, Clone, PartialEq)]
pub struct SpecStripTextResult {
    pub text: String,
    pub pieces: Vec<SpecStripPiece>,
    /// kind → count, in the order the kinds were first counted.
    pub dropped: Vec<(String, i64)>,
    pub unmarked: Vec<(String, i64)>,
    pub appended: Vec<(String, i64)>,
    /// The review marks that went inside a dropped element.
    pub marks_dropped: i64,
    pub appendix: Vec<SpecAppendixEntry>,
    /// The error findings a refused value has.
    pub findings: Vec<NotationFinding>,
}

impl SpecStripTextResult {
    /// Whether the value was refused for its findings.
    pub fn refused(&self) -> bool {
        !self.findings.is_empty()
    }

    /// The result as the conformance corpus writes it.
    pub fn to_json(&self) -> Json {
        Json::Object(vec![
            ("text".to_string(), Json::Str(self.text.clone())),
            ("dropped".to_string(), counts_json(&self.dropped)),
            ("unmarked".to_string(), counts_json(&self.unmarked)),
            ("appended".to_string(), counts_json(&self.appended)),
            ("marksDropped".to_string(), Json::Int(self.marks_dropped)),
            (
                "appendix".to_string(),
                Json::Array(self.appendix.iter().map(SpecAppendixEntry::to_json).collect()),
            ),
            (
                "pieces".to_string(),
                Json::Array(self.pieces.iter().map(SpecStripPiece::to_json).collect()),
            ),
            (
                "refused".to_string(),
                Json::Array(
                    self.findings
                        .iter()
                        .map(|f| Json::Str(f.code.as_str().to_string()))
                        .collect(),
                ),
            ),
        ])
    }
}

fn counts_json(m: &[(String, i64)]) -> Json {
    Json::Object(m.iter().map(|(k, n)| (k.clone(), Json::Int(*n))).collect())
}

/// Strips one value with `options` (SOM §11.10): comments first, then the
/// notation from the outside in, then the whitespace the removals leave.
/// Appendix entries are numbered from 1. A value whose notation has an error
/// finding (other than `rejectedBlock`) is refused and returned unchanged.
pub fn strip_notation_text(value: &str, options: &SpecStripOptions) -> SpecStripTextResult {
    Plan::new(value, options).finish(&|i| i as i64 + 1)
}

// ---------------------------------------------------------------------------
// UTF-16 code units.

pub(crate) type U16 = Vec<u16>;

pub(crate) fn units(s: &str) -> U16 {
    s.encode_utf16().collect()
}

/// The ordinary string of UTF-16 code units: surrogate pairs joined, a lone
/// surrogate as U+FFFD.
pub(crate) fn from_units(u: &[u16]) -> String {
    String::from_utf16_lossy(u)
}

/// JavaScript's `\s` / what `trim()` removes, for one code unit.
pub(crate) fn js_space(c: u16) -> bool {
    matches!(
        c,
        0x09..=0x0D
            | 0x20
            | 0xA0
            | 0x1680
            | 0x2000..=0x200A
            | 0x2028
            | 0x2029
            | 0x202F
            | 0x205F
            | 0x3000
            | 0xFEFF
    )
}

/// `s.substring(from, to).trim() !== ''`.
fn has_text(s: &[u16], from: usize, to: usize) -> bool {
    s.iter()
        .take(to.min(s.len()))
        .skip(from)
        .any(|&c| !js_space(c))
}

fn space(c: u16) -> bool {
    c == b' ' as u16 || c == b'\t' as u16
}

pub(crate) const NL: u16 = b'\n' as u16;

/// The first index of `needle` in `hay` at or after `from`.
fn find(hay: &[u16], needle: &[u16], from: usize) -> Option<usize> {
    if needle.is_empty() || from > hay.len() || hay.len() - from < needle.len() {
        return None;
    }
    (from..=hay.len() - needle.len()).find(|&i| hay[i..i + needle.len()] == *needle)
}

fn find_unit(hay: &[u16], c: u16, from: usize) -> Option<usize> {
    hay.iter()
        .skip(from)
        .position(|&x| x == c)
        .map(|p| p + from)
}

fn count(m: &mut Vec<(String, i64)>, k: &str) {
    match m.iter_mut().find(|(n, _)| n == k) {
        Some(e) => e.1 += 1,
        None => m.push((k.to_string(), 1)),
    }
}

// ---------------------------------------------------------------------------
// Edit scripts.

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum OpType {
    Keep,
    Del,
    Ins,
}

/// One step of an edit script over UTF-16 code units.
#[derive(Debug, Clone)]
pub(crate) struct Op {
    pub(crate) type_: OpType,
    pub(crate) ch: u16,
    /// `None` for a keep.
    pub(crate) label: Option<String>,
}

/// Composes the scripts original → middle (`s1`) and middle → result (`s2`).
fn compose(s1: &[Op], s2: &[Op]) -> Vec<Op> {
    let mut out = Vec::new();
    let mut j = 0;
    fn flush_inserts(s2: &[Op], j: &mut usize, out: &mut Vec<Op>) {
        while *j < s2.len() && s2[*j].type_ == OpType::Ins {
            out.push(s2[*j].clone());
            *j += 1;
        }
    }
    for a in s1 {
        if a.type_ == OpType::Del {
            out.push(a.clone());
            continue;
        }
        flush_inserts(s2, &mut j, &mut out);
        let b = &s2[j];
        j += 1;
        if a.type_ == OpType::Keep {
            out.push(if b.type_ == OpType::Keep {
                a.clone()
            } else {
                Op {
                    type_: OpType::Del,
                    ch: a.ch,
                    label: b.label.clone(),
                }
            });
        } else if b.type_ == OpType::Keep {
            out.push(a.clone());
        }
    }
    flush_inserts(s2, &mut j, &mut out);
    out
}

/// `s` split after every line break.
pub(crate) fn lines(s: &[u16]) -> Vec<U16> {
    s.split_inclusive(|&c| c == NL).map(<[u16]>::to_vec).collect()
}

fn token_kind(c: u16) -> u8 {
    match c {
        0x20 | 0x09 | 0x0A | 0x0D => 2,
        0x30..=0x39 | 0x41..=0x5A | 0x61..=0x7A | 0x5F => 1,
        c if c >= 0x80 => 1,
        _ => 0,
    }
}

/// `s` as word, space and single-punctuation tokens.
fn tokens(s: &[u16]) -> Vec<U16> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < s.len() {
        let k = token_kind(s[i]);
        let mut j = i + 1;
        if k != 0 {
            while j < s.len() && token_kind(s[j]) == k {
                j += 1;
            }
        }
        out.push(s[i..j].to_vec());
        i = j;
    }
    out
}

/// Myers' diff of two token lists; past 2000 edits, everything deleted and
/// inserted.
pub(crate) fn myers(a: &[U16], b: &[U16]) -> Vec<(OpType, U16)> {
    let n = a.len() as i64;
    let m = b.len() as i64;
    let max = n + m;
    let mut rev: Vec<(OpType, U16)> = Vec::new();
    if max == 0 {
        return rev;
    }
    const CAP: i64 = 2000;
    let off = max + 1;
    let mut v = vec![0i64; (2 * max + 3) as usize];
    let mut trace: Vec<Vec<i64>> = Vec::new();
    let mut found: i64 = -1;
    let mut d = 0;
    while d <= max && d <= CAP {
        if d > 0 {
            let snap: Vec<i64> = (-(d - 1)..=d - 1).map(|k| v[(k + off) as usize]).collect();
            trace.push(snap);
        }
        let mut k = -d;
        while k <= d {
            let mut x = if k == -d || (k != d && v[(k - 1 + off) as usize] < v[(k + 1 + off) as usize])
            {
                v[(k + 1 + off) as usize]
            } else {
                v[(k - 1 + off) as usize] + 1
            };
            let mut y = x - k;
            while x < n && y < m && a[x as usize] == b[y as usize] {
                x += 1;
                y += 1;
            }
            v[(k + off) as usize] = x;
            if x >= n && y >= m {
                found = d;
                break;
            }
            k += 2;
        }
        if found >= 0 {
            break;
        }
        d += 1;
    }
    if found < 0 {
        rev.extend(a.iter().map(|t| (OpType::Del, t.clone())));
        rev.extend(b.iter().map(|t| (OpType::Ins, t.clone())));
        return rev;
    }
    let (mut x, mut y) = (n, m);
    let mut d = found;
    while d > 0 {
        let snap = &trace[(d - 1) as usize];
        let at = |k: i64| snap[(k + d - 1) as usize];
        let k = x - y;
        let prev_k = if k == -d || (k != d && at(k - 1) < at(k + 1)) {
            k + 1
        } else {
            k - 1
        };
        let prev_x = at(prev_k);
        let prev_y = prev_x - prev_k;
        while x > prev_x && y > prev_y {
            rev.push((OpType::Keep, a[(x - 1) as usize].clone()));
            x -= 1;
            y -= 1;
        }
        if x == prev_x {
            rev.push((OpType::Ins, b[(y - 1) as usize].clone()));
        } else {
            rev.push((OpType::Del, a[(x - 1) as usize].clone()));
        }
        x = prev_x;
        y = prev_y;
        d -= 1;
    }
    while x > 0 && y > 0 {
        rev.push((OpType::Keep, a[(x - 1) as usize].clone()));
        x -= 1;
        y -= 1;
    }
    rev.reverse();
    rev
}

/// An edit script from `a` to `b`: Myers by line, then by word token.
pub(crate) fn diff(a: &[u16], b: &[u16], label: &str) -> Vec<Op> {
    let mut out: Vec<Op> = Vec::new();
    fn chars(out: &mut Vec<Op>, type_: OpType, s: &[u16], label: &str) {
        out.extend(s.iter().map(|&ch| Op {
            type_,
            ch,
            label: (type_ != OpType::Keep).then(|| label.to_string()),
        }));
    }
    let mut deleted: U16 = Vec::new();
    let mut inserted: U16 = Vec::new();
    fn flush(out: &mut Vec<Op>, deleted: &mut U16, inserted: &mut U16, label: &str) {
        if deleted.is_empty() && inserted.is_empty() {
            return;
        }
        for (t, s) in myers(&tokens(deleted), &tokens(inserted)) {
            chars(out, t, &s, label);
        }
        deleted.clear();
        inserted.clear();
    }
    for (t, s) in myers(&lines(a), &lines(b)) {
        match t {
            OpType::Keep => {
                flush(&mut out, &mut deleted, &mut inserted, label);
                chars(&mut out, OpType::Keep, &s, label);
            }
            OpType::Del => deleted.extend(s),
            OpType::Ins => inserted.extend(s),
        }
    }
    flush(&mut out, &mut deleted, &mut inserted, label);
    out
}

// ---------------------------------------------------------------------------
// Inline review marks.

/// An inline review mark of the text the notation strip works on (UTF-16
/// offsets).
#[derive(Debug, Clone, Copy)]
pub(crate) struct MarkAt {
    pub(crate) start: usize,
    pub(crate) end: usize,
    pub(crate) body_start: usize,
    pub(crate) body_end: usize,
    /// The `~>` of a substitution.
    pub(crate) sep: Option<usize>,
}

/// The inline review marks of `t`, outside code, each inside one paragraph.
pub(crate) fn find_marks(t: &[u16]) -> Vec<MarkAt> {
    let mut code = vec![false; t.len()];
    let mut fence = MarkdownFenceTracker::new();
    let mut s = 0;
    for line in t.split(|&c| c == NL) {
        let in_fence = fence.in_fence();
        fence.feed(&from_units(line));
        if in_fence || fence.in_fence() {
            code[s..s + line.len()].iter_mut().for_each(|c| *c = true);
        } else {
            let tick = b'`' as u16;
            let mut i = 0;
            while i < line.len() {
                if line[i] != tick {
                    i += 1;
                    continue;
                }
                let mut j = i;
                while j < line.len() && line[j] == tick {
                    j += 1;
                }
                let ticks = &line[i..j];
                match find(line, ticks, j) {
                    None => i = j,
                    Some(close) => {
                        code[s + i..s + close + ticks.len()]
                            .iter_mut()
                            .for_each(|c| *c = true);
                        i = close + ticks.len();
                    }
                }
            }
        }
        s += line.len() + 1;
    }
    let marks: [(U16, U16); 5] = [
        (units("{++"), units("++}")),
        (units("{--"), units("--}")),
        (units("{~~"), units("~~}")),
        (units("{=="), units("==}")),
        (units("{>>"), units("<<}")),
    ];
    let arrow = units("~>");
    let mut out = Vec::new();
    let mut i = 0;
    while i + 3 <= t.len() {
        let opener = &t[i..i + 3];
        let closer = marks.iter().find(|(o, _)| o == opener).map(|(_, c)| c);
        let Some(closer) = closer.filter(|_| !code[i]) else {
            i += 1;
            continue;
        };
        // `/\n[ \t]*\n/` from i: the paragraph's end.
        let mut limit = t.len();
        let mut p = find_unit(t, NL, i);
        while let Some(at) = p {
            let mut q = at + 1;
            while q < t.len() && space(t[q]) {
                q += 1;
            }
            if q < t.len() && t[q] == NL {
                limit = at;
                break;
            }
            p = find_unit(t, NL, at + 1);
        }
        let close = match find(t, closer, i + 3) {
            Some(c) if c + 3 <= limit => c,
            _ => {
                i += 1;
                continue;
            }
        };
        let mut sep = None;
        if opener == units("{~~").as_slice() {
            match find(t, &arrow, i + 3) {
                Some(sp) if sp < close => sep = Some(sp),
                _ => {
                    i += 1;
                    continue;
                }
            }
        }
        out.push(MarkAt {
            start: i,
            end: close + 3,
            body_start: i + 3,
            body_end: close,
            sep,
        });
        i = close + 3;
    }
    out
}

// ---------------------------------------------------------------------------
// One value's strip.

/// A text the stripped value holds where nothing stood: a review mark's new
/// delimiter (`text`) or an appendix reference (`entry`).
#[derive(Debug, Clone)]
struct Insert {
    label: String,
    text: Option<U16>,
    entry: Option<usize>,
}

/// An appendix entry before it is numbered.
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Entry {
    pub(crate) kind: String,
    pub(crate) text: String,
}

/// The strip of one value, planned once and finished for any numbering.
///
/// `o` is the value as given; `t` the value the notation strip works on (`o`
/// without its comments when they are dropped) as UTF-16 code units, the
/// indexing of `del` / `ins` and the scanner's offsets.
pub(crate) struct Plan {
    pub(crate) o: String,
    pub(crate) t: U16,
    options: SpecStripOptions,
    o16: U16,
    script1: Option<Vec<Op>>,
    del: Vec<Option<String>>,
    block_del: Vec<bool>,
    ins: BTreeMap<usize, Vec<Insert>>,
    dropped: Vec<(String, i64)>,
    unmarked: Vec<(String, i64)>,
    appended: Vec<(String, i64)>,
    marks_dropped: i64,
    pub(crate) entries: Vec<Entry>,
    pub(crate) findings: Vec<NotationFinding>,
}

impl Plan {
    pub(crate) fn new(o: &str, options: &SpecStripOptions) -> Plan {
        let o16 = units(o);
        let mut p = Plan {
            o: o.to_string(),
            t: Vec::new(),
            options: options.clone(),
            o16,
            script1: None,
            del: Vec::new(),
            block_del: Vec::new(),
            ins: BTreeMap::new(),
            dropped: Vec::new(),
            unmarked: Vec::new(),
            appended: Vec::new(),
            marks_dropped: 0,
            entries: Vec::new(),
            findings: scan_notation(o, true)
                .findings
                .into_iter()
                .filter(|f| {
                    f.severity() == "error" && f.code != NotationFindingCode::RejectedBlock
                })
                .collect(),
        };
        if !p.findings.is_empty() {
            p.t = p.o16.clone();
            p.del = vec![None; p.t.len()];
            p.block_del = vec![false; p.t.len()];
            return p;
        }
        let stripped = if options.drop.contains("comments") {
            let stripped = strip_annotations_text(o);
            p.t = units(&stripped);
            if stripped != o {
                p.dropped
                    .push(("comments".to_string(), count_annotations_text(o) as i64));
                p.script1 = Some(diff(&p.o16, &p.t, "comments"));
            }
            stripped
        } else {
            p.t = p.o16.clone();
            o.to_string()
        };
        p.del = vec![None; p.t.len()];
        p.block_del = vec![false; p.t.len()];
        p.process(&scan_notation(&stripped, true).elements);
        if !options.drop.contains("comments") {
            p.marks();
        }
        if p.del.iter().any(Option::is_some) {
            p.normalise();
        }
        p
    }

    /// Whether the strip changes the value (what the strip of a whole
    /// document asks of each value).
    pub(crate) fn changes(&self) -> bool {
        self.findings.is_empty()
            && (self.script1.is_some() || self.del.iter().any(Option::is_some) || !self.ins.is_empty())
    }

    fn mark(&mut self, s: usize, e: usize, label: &str, block: bool) {
        let e = e.min(self.t.len());
        for i in s..e {
            if self.del[i].is_none() {
                self.del[i] = Some(label.to_string());
            }
            if block {
                self.block_del[i] = true;
            }
        }
    }

    fn mark_one(&mut self, i: usize, label: &str) {
        if self.del[i].is_none() {
            self.del[i] = Some(label.to_string());
        }
    }

    fn insert(&mut self, at: usize, x: Insert) {
        self.ins.entry(at).or_default().push(x);
    }

    fn process(&mut self, elements: &[NotationElement]) {
        for e in elements {
            let k = e.kind.clone().unwrap_or_default();
            // A `linked` span (SOM §11.11) or a `derived` block (SOM §11.12)
            // is removed by `-drop:` and `-unmark:` alike: its text without its
            // markers would read back as content.
            if e.is_registered()
                && (k == "linked" || k == "derived")
                && (self.options.drop.contains(&k) || self.options.unmark.contains(&k))
            {
                self.remove(e, &format!("{}:drop", k), None);
                count(&mut self.dropped, &k);
                continue;
            }
            let secondary = e.is_registered() && SPEC_STRIP_NOTATION_KINDS.contains(&k.as_str());
            if !secondary {
                self.process(&e.children);
                continue;
            }
            if self.options.drop.contains(&k) {
                self.remove(e, &format!("{}:drop", k), None);
                count(&mut self.dropped, &k);
                continue;
            }
            if self.options.appendix.contains(&k) {
                let content: &[u16] = if e.type_ == "citation" {
                    &self.t[e.start..e.end]
                } else {
                    let mut c = &self.t[e.content_start..e.content_end];
                    while let Some((&NL, rest)) = c.split_last() {
                        c = rest;
                    }
                    c
                };
                let text =
                    strip_notation_text(&from_units(content), &self.options.in_entry()).text;
                self.entries.push(Entry { kind: k.clone(), text });
                let entry = self.entries.len() - 1;
                self.remove(e, &format!("{}:appendix", k), Some(entry));
                count(&mut self.appended, &k);
                continue;
            }
            if self.options.unmark.contains(&k) {
                self.unmark(e, &format!("{}:unmark", k));
                count(&mut self.unmarked, &k);
            }
            self.process(&e.children);
        }
    }

    fn remove(&mut self, e: &NotationElement, label: &str, entry: Option<usize>) {
        let reference = entry.is_some() && self.options.appendix_references;
        let (s, en) = (e.start, e.end);
        let reference_insert = |label: &str| Insert {
            label: label.to_string(),
            text: None,
            entry,
        };
        if e.type_ == "div" {
            self.mark(s, en, label, true);
            if reference {
                self.insert(s, reference_insert(label));
            }
            return;
        }
        if s > 0 && space(self.t[s - 1]) && self.del[s - 1].is_none() {
            self.del[s - 1] = Some(label.to_string());
        } else if !reference
            && (s == 0 || self.t[s - 1] == NL)
            && en < self.t.len()
            && space(self.t[en])
        {
            self.mark_one(en, label);
        }
        self.mark(s, en, label, false);
        if reference {
            self.insert(s, reference_insert(label));
        }
    }

    fn unmark(&mut self, e: &NotationElement, label: &str) {
        let (s, en, cs, ce) = (e.start, e.end, e.content_start, e.content_end);
        if e.type_ == "div" {
            if cs >= ce {
                self.mark(s, en, label, true);
            } else {
                self.mark(s, cs, label, true);
                self.mark(ce - 1, en, label, true);
            }
        } else if e.type_ == "span" {
            self.mark(s, s + 1, label, false);
            self.mark(ce, en, label, false);
        } else {
            self.mark(s + 1, cs, label, false);
        }
    }

    fn marks(&mut self) {
        for m in find_marks(&self.t) {
            if self.all_deleted(m.start, m.end) {
                self.marks_dropped += 1;
                continue;
            }
            let Some(sep) = m.sep else {
                if has_text(&self.t, m.body_start, m.body_end)
                    && !self.survives(m.body_start, m.body_end)
                {
                    self.remove_mark(&m);
                }
                continue;
            };
            let old_had = has_text(&self.t, m.body_start, sep);
            let new_had = has_text(&self.t, sep + 2, m.body_end);
            let old_left = self.survives(m.body_start, sep);
            let new_left = self.survives(sep + 2, m.body_end);
            if !old_left && !new_left && (old_had || new_had) {
                self.remove_mark(&m);
            } else if old_had && !old_left {
                self.convert(&m, "++", m.body_start, sep + 2);
            } else if new_had && !new_left {
                self.convert(&m, "--", sep, m.body_end);
            }
        }
    }

    fn remove_mark(&mut self, m: &MarkAt) {
        let s = m.start;
        if s > 0 && space(self.t[s - 1]) && self.del[s - 1].is_none() {
            self.del[s - 1] = Some("mark".to_string());
        } else if (s == 0 || self.t[s - 1] == NL) && m.end < self.t.len() && space(self.t[m.end]) {
            self.mark_one(m.end, "mark");
        }
        self.mark(m.start, m.end, "mark", false);
    }

    fn convert(&mut self, m: &MarkAt, delimiter: &str, s: usize, e: usize) {
        let insert = || Insert {
            label: "mark".to_string(),
            text: Some(units(delimiter)),
            entry: None,
        };
        self.mark(m.start + 1, m.start + 3, "mark", false);
        self.insert(m.start + 3, insert());
        self.mark(s, e, "mark", false);
        self.mark(m.end - 3, m.end - 1, "mark", false);
        self.insert(m.end - 1, insert());
    }

    fn all_deleted(&self, s: usize, e: usize) -> bool {
        self.del[s..e].iter().all(Option::is_some)
    }

    fn survives(&self, s: usize, e: usize) -> bool {
        (s..e).any(|i| self.del[i].is_none() && !js_space(self.t[i]))
    }

    fn wipe(&mut self, idx: Option<usize>) {
        if let Some(i) = idx {
            self.mark_one(i, "whitespace");
        }
    }

    /// The whitespace the removals leave: a line left with only spaces goes
    /// with its break, then leading and trailing blank lines and blank-line
    /// runs beside a removal collapse to one blank line.
    fn normalise(&mut self) {
        let t = self.t.clone();
        let mut starts = vec![0usize];
        starts.extend(
            t.iter()
                .enumerate()
                .filter(|(_, &c)| c == NL)
                .map(|(i, _)| i + 1),
        );
        for l in 0..starts.len() {
            let s = starts[l];
            let e = if l + 1 < starts.len() {
                starts[l + 1] - 1
            } else {
                t.len()
            };
            if !has_text(&t, s, e) {
                continue;
            }
            let mut touched = false;
            let mut surv = false;
            let mut all_block = true;
            for ((c, d), block) in t[s..e].iter().zip(&self.del[s..e]).zip(&self.block_del[s..e]) {
                if d.is_some() {
                    touched = true;
                } else if !js_space(*c) {
                    surv = true;
                }
                if !block {
                    all_block = false;
                }
            }
            if (s..=e).any(|i| self.ins.contains_key(&i)) {
                surv = true;
            }
            if !touched || surv || all_block {
                continue;
            }
            self.mark(s, e, "whitespace", false);
            if e < t.len() {
                self.mark_one(e, "whitespace");
            } else if s > 0 {
                self.mark_one(s - 1, "whitespace");
            }
        }
        // Blank-line runs, read on the text as it now stands.
        let mut kept: Vec<Option<usize>> = Vec::new();
        let mut b: U16 = Vec::new();
        for i in 0..=t.len() {
            if let Some(list) = self.ins.get(&i) {
                for x in list {
                    let s = x.text.clone().unwrap_or_else(|| units("x"));
                    kept.extend(std::iter::repeat_n(None, s.len()));
                    b.extend(s);
                }
            }
            if i < t.len() && self.del[i].is_none() {
                kept.push(Some(i));
                b.push(t[i]);
            }
        }
        let solid = |c: u16| !js_space(c);
        let Some(first_solid) = b.iter().position(|&c| solid(c)) else {
            for i in kept {
                self.wipe(i);
            }
            return;
        };
        let last_solid = b.iter().rposition(|&c| solid(c)).unwrap_or(first_solid);
        // `b.lastIndexOf('\n', firstSolid)`
        if let Some(lead) = b[..=first_solid].iter().rposition(|&c| c == NL) {
            for &k in &kept[..=lead] {
                self.wipe(k);
            }
        }
        if let Some(trail) = find_unit(&b, NL, last_solid) {
            for &k in &kept[trail..] {
                self.wipe(k);
            }
        }
        let mut k = first_solid;
        while k < last_solid {
            if solid(b[k]) {
                k += 1;
                continue;
            }
            let run_start = k;
            while !solid(b[k]) {
                k += 1;
            }
            let run_end = k;
            let breaks: Vec<usize> = (run_start..run_end).filter(|&j| b[j] == NL).collect();
            if breaks.len() <= 2 {
                continue;
            }
            let at_removal = match (kept[run_start - 1], kept[run_end]) {
                (Some(from), Some(to)) => self.del[from + 1..to]
                    .iter()
                    .any(|d| d.as_deref().is_some_and(|d| d != "whitespace")),
                _ => true,
            };
            if !at_removal {
                continue;
            }
            let last = *breaks.last().unwrap_or(&0);
            for &k in &kept[breaks[0] + 1..last] {
                self.wipe(k);
            }
        }
    }

    /// The result, the appendix entries numbered by `number` (entry index →
    /// number).
    pub(crate) fn finish(&self, number: &dyn Fn(usize) -> i64) -> SpecStripTextResult {
        if !self.findings.is_empty() {
            return SpecStripTextResult {
                text: self.o.clone(),
                pieces: Vec::new(),
                dropped: Vec::new(),
                unmarked: Vec::new(),
                appended: Vec::new(),
                marks_dropped: 0,
                appendix: Vec::new(),
                findings: self.findings.clone(),
            };
        }
        let t = &self.t;
        let insert_text = |x: &Insert| -> U16 {
            if let Some(text) = &x.text {
                return text.clone();
            }
            let n = number(x.entry.unwrap_or(0));
            units(&format!(
                "<a id=\"note-{n}-ref\"></a>[\\[{n}\\]](#note-{n})"
            ))
        };
        let mut script2: Vec<Op> = Vec::new();
        for i in 0..=t.len() {
            if let Some(list) = self.ins.get(&i) {
                for x in list {
                    script2.extend(insert_text(x).into_iter().map(|ch| Op {
                        type_: OpType::Ins,
                        ch,
                        label: Some(x.label.clone()),
                    }));
                }
            }
            if i < t.len() {
                script2.push(match &self.del[i] {
                    None => Op {
                        type_: OpType::Keep,
                        ch: t[i],
                        label: None,
                    },
                    Some(d) => Op {
                        type_: OpType::Del,
                        ch: t[i],
                        label: Some(d.clone()),
                    },
                });
            }
        }
        let ops = match &self.script1 {
            Some(s1) => compose(s1, &script2),
            None => script2,
        };
        let mut out: U16 = Vec::new();
        let mut pieces = Vec::new();
        let (mut o_pos, mut b_pos) = (0usize, 0usize);
        let mut i = 0;
        while i < ops.len() {
            if ops[i].type_ == OpType::Keep {
                out.push(ops[i].ch);
                o_pos += 1;
                b_pos += 1;
                i += 1;
                continue;
            }
            let (anchor, origin) = (b_pos, o_pos);
            let mut removed: U16 = Vec::new();
            let mut inserted: U16 = Vec::new();
            let mut labels: BTreeSet<String> = BTreeSet::new();
            while i < ops.len() && ops[i].type_ != OpType::Keep {
                let op = &ops[i];
                if let Some(l) = &op.label {
                    labels.insert(l.clone());
                }
                if op.type_ == OpType::Del {
                    removed.push(op.ch);
                    o_pos += 1;
                } else {
                    inserted.push(op.ch);
                    out.push(op.ch);
                    b_pos += 1;
                }
                i += 1;
            }
            pieces.push(SpecStripPiece {
                anchor,
                origin,
                removed: from_units(&removed),
                inserted: from_units(&inserted),
                labels: labels.into_iter().collect(),
            });
        }
        SpecStripTextResult {
            text: from_units(&out),
            pieces,
            dropped: self.dropped.clone(),
            unmarked: self.unmarked.clone(),
            appended: self.appended.clone(),
            marks_dropped: self.marks_dropped,
            appendix: self
                .entries
                .iter()
                .enumerate()
                .map(|(k, e)| SpecAppendixEntry {
                    number: number(k),
                    kind: e.kind.clone(),
                    text: e.text.clone(),
                    value: None,
                })
                .collect(),
            findings: Vec::new(),
        }
    }
}

// ---------------------------------------------------------------------------
// The readable header (SOM §11.1) and value references.

/// The source a readable rendition was made from, named in its header.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct SpecReadableSource {
    /// The document file.
    pub file: String,
    /// Its revision; `None` when not known.
    pub revision: Option<String>,
    /// The commit it was read at; `None` when not known.
    pub commit: Option<String>,
    /// Whether the working tree differed from that commit.
    pub dirty: bool,
}

/// The readable header line of a stripped rendition (SOM §11.1): `<!--
/// readable: drop=…; unmark=…; appendix=…; appendix-references;
/// headings=divs; of=<file>@<revision>; commit=<sha>[+dirty] -->`. Parts that
/// do not apply are left out; [`format`](Self::format) and
/// [`parse`](Self::parse) are inverse.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct SpecReadableHeader {
    /// The switches the rendition was stripped with.
    pub options: SpecStripOptions,
    /// The source it names; `None` when it names none.
    pub source: Option<SpecReadableSource>,
}

impl SpecReadableHeader {
    /// The header line for `options` and `source`.
    pub fn format(options: &SpecStripOptions, source: Option<&SpecReadableSource>) -> String {
        let joined = |s: &BTreeSet<String>| SpecStripOptions::ordered(s).join(",");
        let mut parts: Vec<String> = Vec::new();
        if !options.drop.is_empty() {
            parts.push(format!("drop={}", joined(&options.drop)));
        }
        if !options.unmark.is_empty() {
            parts.push(format!("unmark={}", joined(&options.unmark)));
        }
        if !options.appendix.is_empty() {
            parts.push(format!("appendix={}", joined(&options.appendix)));
        }
        if options.appendix_references {
            parts.push("appendix-references".to_string());
        }
        if options.heading_divs {
            parts.push("headings=divs".to_string());
        }
        if let Some(source) = source {
            let mut of = format!("of={}", source.file);
            if let Some(revision) = &source.revision {
                of.push('@');
                of.push_str(revision);
            }
            parts.push(of);
            if let Some(commit) = &source.commit {
                parts.push(format!(
                    "commit={}{}",
                    commit,
                    if source.dirty { "+dirty" } else { "" }
                ));
            }
        }
        if parts.is_empty() {
            return "<!-- readable: -->".to_string();
        }
        format!("<!-- readable: {} -->", parts.join("; "))
    }

    /// `line` read as a readable header; `None` for a line that is none — an
    /// unknown part, an unknown kind, a usage error, a commit without a file.
    pub fn parse(line: &str) -> Option<SpecReadableHeader> {
        let t = line.trim_matches(is_ascii_trim);
        // `^<!--\s*readable:(.*)-->$`
        let r = t.strip_prefix("<!--")?.trim_start_matches(is_ascii_trim);
        let body = r.strip_prefix("readable:")?.strip_suffix("-->")?;
        let mut lists: [Vec<String>; 3] = [Vec::new(), Vec::new(), Vec::new()];
        let (mut refs, mut divs, mut dirty) = (false, false, false);
        let (mut file, mut revision, mut commit): (Option<String>, Option<String>, Option<String>) =
            (None, None, None);
        for part in body.split(';') {
            let part = part.trim_matches(is_ascii_trim);
            if part.is_empty() {
                continue;
            }
            let (key, value) = match part.find('=') {
                Some(eq) => (&part[..eq], Some(&part[eq + 1..])),
                None => (part, None),
            };
            let v = value.unwrap_or("");
            match key {
                "drop" => lists[0].push(v.to_string()),
                "unmark" => lists[1].push(v.to_string()),
                "appendix" => lists[2].push(v.to_string()),
                "appendix-references" if value.is_none() => refs = true,
                "headings" if v == "divs" => divs = true,
                "of" => match v.rfind('@') {
                    Some(at) => {
                        file = Some(v[..at].to_string());
                        revision = Some(v[at + 1..].to_string());
                    }
                    None => {
                        file = Some(v.to_string());
                        revision = None;
                    }
                },
                "commit" => {
                    dirty = v.ends_with("+dirty");
                    commit = Some(v.strip_suffix("+dirty").unwrap_or(v).to_string());
                }
                _ => return None,
            }
        }
        if file.is_none() && commit.is_some() {
            return None;
        }
        let options = SpecStripOptions::from_names(&lists[0], &lists[1], &lists[2], refs, divs).ok()?;
        Some(SpecReadableHeader {
            options,
            source: file.map(|file| SpecReadableSource {
                file,
                revision,
                commit,
                dirty,
            }),
        })
    }
}

/// A value of a document: a stored headline, a content value, or a form
/// field's value.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct SpecStripValueRef {
    pub path: String,
    /// The form field; `None` for content and headlines.
    pub field: Option<String>,
    /// Whether it is the stored headline at `path`.
    pub headline: bool,
}

impl SpecStripValueRef {
    /// The value in `doc` (`""` when unset).
    pub fn read(&self, doc: &SpecDocument) -> String {
        if self.headline {
            return doc.headline_or(&self.path);
        }
        match &self.field {
            Some(f) => doc.form_field_or(&self.path, f),
            None => doc.content_or(&self.path),
        }
    }

    /// Writes `value` to the value it names (`""` clears it).
    pub fn write(&self, doc: &mut SpecDocument, value: &str) {
        if self.headline {
            doc.set_headline(&self.path, value);
        } else if let Some(f) = &self.field {
            doc.set_form_field(&self.path, f, value);
        } else {
            doc.set_content(&self.path, value);
        }
    }

    /// `<path> (headline)`, `<path>/<field>` or `<path>`.
    pub fn label(&self) -> String {
        if self.headline {
            return format!("{} (headline)", self.path);
        }
        match &self.field {
            Some(f) => format!("{}/{}", self.path, f),
            None => self.path.clone(),
        }
    }

    /// `{path, field?, headline?}`, as the conformance corpus writes it.
    pub fn to_json(&self) -> Json {
        let mut out = vec![("path".to_string(), Json::Str(self.path.clone()))];
        if let Some(f) = &self.field {
            out.push(("field".to_string(), Json::Str(f.clone())));
        }
        if self.headline {
            out.push(("headline".to_string(), Json::Bool(true)));
        }
        Json::Object(out)
    }
}

// ---------------------------------------------------------------------------
// The strip of a document (SOM §11.10).

/// One value a strip changed, with what went.
#[derive(Debug, Clone, PartialEq)]
pub struct SpecStrippedValue {
    pub value: SpecStripValueRef,
    pub original: String,
    pub stripped: String,
    pub pieces: Vec<SpecStripPiece>,
}

/// A value the emptying rule kept: stripping it would have added `finding`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecStripKept {
    pub value: SpecStripValueRef,
    pub finding: String,
}

/// A reason a stripped document is not valid.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecStripFinding {
    /// `notation`, `instance`, `schema` or `parse`.
    pub kind: String,
    pub message: String,
    /// The value it is about; `None` when about no one value.
    pub value: Option<SpecStripValueRef>,
}

impl fmt::Display for SpecStripFinding {
    /// `<kind>: [<value>: ]<message>`.
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match &self.value {
            Some(v) => write!(f, "{}: {}: {}", self.kind, v.label(), self.message),
            None => write!(f, "{}: {}", self.kind, self.message),
        }
    }
}

/// The result of [`SpecDocumentStrip::strip`].
#[derive(Debug, Clone)]
pub struct SpecStripResult {
    /// The stripped copy.
    pub document: SpecDocument,
    pub values: Vec<SpecStrippedValue>,
    pub kept: Vec<SpecStripKept>,
    /// The list items left empty and removed.
    pub removed_items: Vec<String>,
    /// The appendix, numbered through the rendition.
    pub appendix: Vec<SpecAppendixEntry>,
    /// kind → count, in the order the kinds were first counted.
    pub dropped: Vec<(String, i64)>,
    pub unmarked: Vec<(String, i64)>,
    pub appended: Vec<(String, i64)>,
    pub marks_dropped: i64,
    pub readable_header: String,
    /// The readable rendition; `None` without a model.
    pub readable: Option<String>,
    pub findings: Vec<SpecStripFinding>,
}

impl SpecStripResult {
    /// Whether the stripped document is valid and may be written.
    pub fn ok(&self) -> bool {
        self.findings.is_empty()
    }

    /// The report: what was dropped, unmarked, moved and kept per kind.
    pub fn report(&self) -> Vec<String> {
        let get = |m: &[(String, i64)], k: &str| {
            m.iter().find(|(n, _)| n == k).map(|(_, c)| *c).unwrap_or(0)
        };
        let mut out = Vec::new();
        for k in SPEC_STRIP_KIND_NAMES {
            let (d, u, a) = (get(&self.dropped, k), get(&self.unmarked, k), get(&self.appended, k));
            if d + u + a <= 0 {
                continue;
            }
            out.push(format!("{}: {} dropped, {} unmarked, {} moved", k, d, u, a));
        }
        if self.marks_dropped > 0 {
            out.push(format!(
                "review marks inside dropped elements: {}",
                self.marks_dropped
            ));
        }
        for k in &self.kept {
            out.push(format!(
                "KEPT (would empty a required value): {} \u{2014} {}",
                k.value.label(),
                k.finding
            ));
        }
        out
    }

    /// The result as the conformance corpus writes it (`document` as
    /// canonical document JSON, `kept`, `removedItems`, `appendix`, `dropped`,
    /// `unmarked`, `appended`, `marksDropped`, `readableHeader`, `readable`,
    /// `findings` by kind).
    pub fn to_json(&self) -> Json {
        let document = Json::parse(&self.document.to_json().to_canonical_json()).unwrap_or(Json::Null);
        Json::Object(vec![
            ("document".to_string(), document),
            (
                "kept".to_string(),
                Json::Array(self.kept.iter().map(|k| k.value.to_json()).collect()),
            ),
            (
                "removedItems".to_string(),
                Json::Array(self.removed_items.iter().cloned().map(Json::Str).collect()),
            ),
            (
                "appendix".to_string(),
                Json::Array(self.appendix.iter().map(SpecAppendixEntry::to_json).collect()),
            ),
            ("dropped".to_string(), counts_json(&self.dropped)),
            ("unmarked".to_string(), counts_json(&self.unmarked)),
            ("appended".to_string(), counts_json(&self.appended)),
            ("marksDropped".to_string(), Json::Int(self.marks_dropped)),
            (
                "readableHeader".to_string(),
                Json::Str(self.readable_header.clone()),
            ),
            (
                "readable".to_string(),
                self.readable.clone().map(Json::Str).unwrap_or(Json::Null),
            ),
            (
                "findings".to_string(),
                Json::Array(self.findings.iter().map(|f| Json::Str(f.kind.clone())).collect()),
            ),
        ])
    }
}

/// What [`SpecDocumentStrip::strip`] takes beyond the switches.
#[derive(Debug, Clone, Copy, Default)]
pub struct SpecDocumentStripOptions<'a> {
    /// The model: the emptying rule, the rendition and its checks.
    pub model: Option<&'a SpecModel>,
    /// The schema tier of both checks.
    pub schema: Option<&'a DocSpecsSchema>,
    /// The root rendered; `None` for the single populated one.
    pub root_type: Option<&'a str>,
    /// The source named in the readable header.
    pub source: Option<&'a SpecReadableSource>,
    /// The codec's file stem ([`SpecDocumentMarkdown::file_stem`]): the files
    /// a reference to another document root links to.
    pub file_stem: Option<&'a str>,
    /// The codec's document files ([`SpecDocumentMarkdown::document_files`]).
    pub document_files: Option<&'a HashMap<String, String>>,
}

impl<'a> SpecDocumentStripOptions<'a> {
    /// The codec over `doc` with the file stem and document files given.
    pub(crate) fn codec<'d>(&self, model: &'d SpecModel, doc: &'d SpecDocument) -> SpecDocumentMarkdown<'d> {
        let mut c = SpecDocumentMarkdown::new(model, doc);
        if let Some(stem) = self.file_stem {
            c.file_stem = stem.to_string();
        }
        if let Some(files) = self.document_files {
            c.document_files = files.clone();
        }
        c
    }
}

/// The strip of a whole document (SOM §11.10).
pub struct SpecDocumentStrip;

impl SpecDocumentStrip {
    /// Strips every value of `document` — content, form-field values and
    /// stored headlines — into a copy. Given a model it also applies the
    /// emptying rule (a value whose strip would add an instance or schema
    /// finding is stripped with the keeping options instead, or left as it
    /// was), removes list items left with nothing, numbers the appendix
    /// through the rendition, renders the readable rendition and checks that
    /// it reads back and validates.
    pub fn strip(
        document: &SpecDocument,
        options: &SpecStripOptions,
        extra: &SpecDocumentStripOptions<'_>,
    ) -> SpecStripResult {
        let mut out = SpecStripResult {
            document: SpecDocument::new(),
            values: Vec::new(),
            kept: Vec::new(),
            removed_items: Vec::new(),
            appendix: Vec::new(),
            dropped: Vec::new(),
            unmarked: Vec::new(),
            appended: Vec::new(),
            marks_dropped: 0,
            readable_header: String::new(),
            readable: None,
            findings: Vec::new(),
        };
        let refs = value_refs(document);
        let mut s = Strip {
            document,
            copy: document.clone(),
            options,
            originals: vec![String::new(); refs.len()],
            plans: (0..refs.len()).map(|_| None).collect(),
            numbers: vec![Vec::new(); refs.len()],
            refs,
        };
        for i in 0..s.refs.len() {
            let text = s.refs[i].read(document);
            if text.is_empty() {
                continue;
            }
            let plan = Plan::new(&text, options);
            s.originals[i] = text;
            if !plan.findings.is_empty() {
                for f in &plan.findings {
                    push_finding(
                        &mut out,
                        "notation",
                        format!("{} (line {}): {}", f.code.as_str(), f.line, f.message),
                        Some(&s.refs[i]),
                    );
                }
                continue;
            }
            if plan.changes() {
                s.plans[i] = Some(plan);
            }
        }

        let mut next = 1;
        for i in 0..s.refs.len() {
            if s.plans[i].is_none() {
                continue;
            }
            s.set_numbers(i);
            for n in s.numbers[i].iter_mut() {
                *n = next;
                next += 1;
            }
        }
        s.apply();
        let model = extra.model;
        let schema = extra.schema;
        let root_type = extra.root_type;
        let mut base: KeyPaths = Vec::new();
        if let Some(model) = model {
            base = tier_findings(model, schema, root_type, document);
            s.emptying_rule(model, schema, root_type, &base, &mut out.kept, &mut out.removed_items);
        }

        // The appendix, numbered through the rendition: (ref, entry, line).
        let mut entries: Vec<(usize, usize, usize)> = Vec::new();
        for (i, plan) in s.plans.iter().enumerate() {
            if let Some(plan) = plan {
                entries.extend((0..plan.entries.len()).map(|k| (i, k, 0)));
            }
        }
        let mut root = None;
        if let Some(model) = model {
            match s.copy.root_to_export(model, root_type) {
                Ok(r) => root = Some(r),
                Err(e) => push_finding(&mut out, "parse", e, None),
            }
        }
        let mut titles = Headings::default();
        if let (Some(model), Some(root), false) = (model, root, entries.is_empty()) {
            match extra.codec(model, &s.copy).export_root_with_map(root) {
                Ok(r) => {
                    titles = Headings::from(&r);
                    for e in entries.iter_mut() {
                        e.2 = titles
                            .section(&s.refs[e.0].path)
                            .map(|k| titles.lines[k])
                            .unwrap_or(0);
                    }
                    entries.sort_by_key(|&(index, entry, line)| (line, index, entry));
                }
                Err(e) => push_finding(&mut out, "parse", e, None),
            }
        }
        for (k, &(index, entry, _)) in entries.iter().enumerate() {
            s.numbers[index][entry] = k as i64 + 1;
        }
        s.apply();

        for i in 0..s.refs.len() {
            let Some(plan) = &s.plans[i] else {
                continue;
            };
            let numbers = &s.numbers[i];
            let r = plan.finish(&|k| numbers[k]);
            add_counts(&mut out.dropped, &r.dropped);
            add_counts(&mut out.unmarked, &r.unmarked);
            add_counts(&mut out.appended, &r.appended);
            out.marks_dropped += r.marks_dropped;
            for mut a in r.appendix {
                a.value = Some(s.refs[i].clone());
                out.appendix.push(a);
            }
            out.values.push(SpecStrippedValue {
                value: s.refs[i].clone(),
                original: s.originals[i].clone(),
                stripped: r.text,
                pieces: r.pieces,
            });
        }
        out.appendix.sort_by_key(|a| a.number);

        out.readable_header = SpecReadableHeader::format(options, extra.source);
        if let (Some(model), Some(root)) = (model, root) {
            let export = SpecMarkdownExportOptions {
                heading_divs: options.heading_divs,
                readable_header: Some(out.readable_header.clone()),
            };
            let codec = extra.codec(model, &s.copy).with_navigation(
                !options.writes_no_linked_markers(),
                !options.writes_no_generated_parts(),
            );
            match codec.export_root_with_options(root, &export) {
                Ok(rendition) => {
                    if titles.paths.is_empty() && !out.appendix.is_empty() {
                        titles = Headings::from(&rendition);
                    }
                    out.readable = Some(if out.appendix.is_empty() {
                        rendition.markdown
                    } else {
                        with_appendix(
                            &rendition.markdown,
                            &out.appendix,
                            &titles,
                            options.appendix_references,
                        )
                    });
                }
                Err(e) => push_finding(&mut out, "parse", e, None),
            }
            if let Some(readable) = out.readable.clone() {
                check_output(
                    model, schema, root, root_type, &base, document, &s.copy, &readable, extra, &mut out,
                );
            }
        }
        out.document = s.copy;
        out
    }
}

/// An ordered map of finding keys to the paths they concern: a key set
/// again keeps its place and takes the new path.
pub(crate) type KeyPaths = Vec<(String, String)>;

fn key_set(m: &mut KeyPaths, key: String, path: String) {
    match m.iter_mut().find(|(k, _)| *k == key) {
        Some(e) => e.1 = path,
        None => m.push((key, path)),
    }
}

pub(crate) fn key_has(m: &KeyPaths, key: &str) -> bool {
    m.iter().any(|(k, _)| k == key)
}

fn blank(s: &str) -> bool {
    s.chars().all(is_ascii_trim)
}

fn starts_with_sep(s: &str, prefix: &str, sep: char) -> bool {
    s.len() > prefix.len() && s.starts_with(prefix) && s[prefix.len()..].starts_with(sep)
}

/// Whether a finding at `finding_path` concerns `path`.
fn concerns(finding_path: &str, path: &str) -> bool {
    finding_path.is_empty()
        || path == finding_path
        || starts_with_sep(path, finding_path, '/')
        || starts_with_sep(path, finding_path, '-')
        || starts_with_sep(finding_path, path, '/')
}

fn add_counts(into: &mut Vec<(String, i64)>, from: &[(String, i64)]) {
    for (k, n) in from {
        match into.iter_mut().find(|(e, _)| e == k) {
            Some(e) => e.1 += n,
            None => into.push((k.clone(), *n)),
        }
    }
}

fn push_finding(
    out: &mut SpecStripResult,
    kind: &str,
    message: String,
    value: Option<&SpecStripValueRef>,
) {
    out.findings.push(SpecStripFinding {
        kind: kind.to_string(),
        message,
        value: value.cloned(),
    });
}

/// The instance tier's and (given a schema) the schema tier's findings of
/// `doc`, keyed as `instance <code> <path>: <message>` / `schema <rule>
/// <section id>: <message>`, each with the path it concerns.
pub(crate) fn tier_findings(
    model: &SpecModel,
    schema: Option<&DocSpecsSchema>,
    root_type: Option<&str>,
    doc: &SpecDocument,
) -> KeyPaths {
    let mut out = Vec::new();
    for e in validate_document(model, doc) {
        key_set(
            &mut out,
            format!("instance {} {}: {}", e.code, e.path, e.message),
            e.path,
        );
    }
    let Some(schema) = schema else {
        return out;
    };
    // No single root to render: the schema tier cannot judge it.
    if let Ok(found) = validate_spec_document(model, doc, schema, root_type) {
        for v in found {
            key_set(
                &mut out,
                format!("schema {} {}: {}", v.rule, v.section_id, v.message),
                v.path,
            );
        }
    }
    out
}

/// Every value of `doc`: stored headlines, content, form fields, each group
/// sorted.
pub(crate) fn value_refs(doc: &SpecDocument) -> Vec<SpecStripValueRef> {
    let mut refs: Vec<SpecStripValueRef> = doc
        .headline_paths()
        .into_iter()
        .map(|path| SpecStripValueRef {
            path,
            field: None,
            headline: true,
        })
        .collect();
    refs.extend(doc.content_paths().into_iter().map(|path| SpecStripValueRef {
        path,
        field: None,
        headline: false,
    }));
    for path in doc.form_paths() {
        for f in doc.form_field_names(&path) {
            refs.push(SpecStripValueRef {
                path: path.clone(),
                field: Some(f),
                headline: false,
            });
        }
    }
    refs
}

/// The state of one strip of a document.
struct Strip<'d> {
    document: &'d SpecDocument,
    copy: SpecDocument,
    options: &'d SpecStripOptions,
    refs: Vec<SpecStripValueRef>,
    /// Per ref: the value as it was.
    originals: Vec<String>,
    /// Per ref: the plan, where the value changes.
    plans: Vec<Option<Plan>>,
    /// Per planned ref: the number of each appendix entry.
    numbers: Vec<Vec<i64>>,
}

impl Strip<'_> {
    fn set_numbers(&mut self, i: usize) {
        let n = self.plans[i].as_ref().map_or(0, |p| p.entries.len());
        self.numbers[i] = vec![0; n];
    }

    fn apply(&mut self) {
        for i in 0..self.refs.len() {
            if let Some(plan) = &self.plans[i] {
                let numbers = &self.numbers[i];
                let text = plan.finish(&|k| numbers[k]).text;
                self.refs[i].write(&mut self.copy, &text);
            }
        }
    }

    /// The list items that are, or hold, a planned value. Sorted.
    fn items_above(&self) -> Vec<String> {
        let mut items: BTreeSet<String> = BTreeSet::new();
        for list in self.copy.list_paths() {
            items.extend(self.copy.list_items(&list));
        }
        let mut out: BTreeSet<String> = BTreeSet::new();
        for (r, plan) in self.refs.iter().zip(&self.plans) {
            if plan.is_none() {
                continue;
            }
            let p = &r.path;
            if items.contains(p) {
                out.insert(p.clone());
            }
            for (i, _) in p.match_indices('/') {
                if items.contains(&p[..i]) {
                    out.insert(p[..i].to_string());
                }
            }
        }
        out.into_iter().collect()
    }

    fn emptied_items(&self, candidates: &[String], keep: &[String]) -> Vec<String> {
        candidates
            .iter()
            .filter(|item| {
                !keep.contains(item)
                    && self.document.has_values_under(item)
                    && !self.copy.has_values_under(item)
            })
            .cloned()
            .collect()
    }

    /// The emptying rule: a value whose strip adds an instance or schema
    /// finding is stripped with the keeping options instead (or keeps its
    /// original when even that empties it), and a list item it would empty
    /// stays; then the list items left with nothing are removed and written
    /// into `removed`.
    fn emptying_rule(
        &mut self,
        model: &SpecModel,
        schema: Option<&DocSpecsSchema>,
        root_type: Option<&str>,
        base: &KeyPaths,
        kept: &mut Vec<SpecStripKept>,
        removed: &mut Vec<String>,
    ) {
        let mut kept_refs = vec![false; self.refs.len()];
        let mut keep_items: Vec<String> = Vec::new();
        let candidates = self.items_above();
        let keeping = self.options.keeping();
        for _round in 0..8 {
            let items = self.emptied_items(&candidates, &keep_items);
            let now = if items.is_empty() {
                tier_findings(model, schema, root_type, &self.copy)
            } else {
                let mut scratch = self.copy.clone();
                for it in &items {
                    scratch.remove_list_item(it);
                }
                tier_findings(model, schema, root_type, &scratch)
            };
            let added: KeyPaths = now.into_iter().filter(|(k, _)| !key_has(base, k)).collect();
            if added.is_empty() {
                break;
            }
            let emptied: Vec<usize> = (0..self.refs.len())
                .filter(|&i| {
                    self.plans[i].is_some() && !kept_refs[i] && blank(&self.refs[i].read(&self.copy))
                })
                .collect();
            let mut changed = false;
            for (key, finding_path) in &added {
                for it in &items {
                    if concerns(finding_path, it) && !keep_items.contains(it) {
                        keep_items.push(it.clone());
                        changed = true;
                    }
                }
                for &index in &emptied {
                    if kept_refs[index] || !concerns(finding_path, &self.refs[index].path) {
                        continue;
                    }
                    kept_refs[index] = true;
                    kept.push(SpecStripKept {
                        value: self.refs[index].clone(),
                        finding: key.clone(),
                    });
                    let k = Plan::new(&self.originals[index], &keeping);
                    let text = k.finish(&|e| e as i64 + 1).text;
                    if blank(&text) {
                        self.plans[index] = None;
                        self.refs[index].write(&mut self.copy, &self.originals[index]);
                    } else {
                        self.plans[index] = Some(k);
                        self.set_numbers(index);
                        self.refs[index].write(&mut self.copy, &text);
                    }
                    changed = true;
                }
            }
            if !changed {
                break;
            }
        }
        for it in self.emptied_items(&candidates, &keep_items) {
            self.copy.remove_list_item(&it);
            removed.push(it);
        }
    }
}

/// The headings of a rendition: the title of each heading path and its line,
/// in rendition order (a path written twice keeps its first place).
#[derive(Default)]
struct Headings {
    paths: Vec<String>,
    titles: Vec<String>,
    lines: Vec<usize>,
}

impl Headings {
    fn from(r: &SpecMarkdownRendition) -> Headings {
        let mut h = Headings::default();
        let text: Vec<&str> = r.markdown.split('\n').collect();
        for (&line, path) in &r.heading_paths {
            let title = markdown_heading_title(
                if line >= 1 && line <= text.len() { text[line - 1] } else { "" },
            );
            match h.paths.iter().position(|p| p == path) {
                Some(at) => {
                    h.titles[at] = title;
                    h.lines[at] = line;
                }
                None => {
                    h.paths.push(path.clone());
                    h.titles.push(title);
                    h.lines.push(line);
                }
            }
        }
        h
    }

    /// The index of the longest heading path that is `path` or above it.
    fn section(&self, path: &str) -> Option<usize> {
        let mut best: Option<usize> = None;
        for (k, p) in self.paths.iter().enumerate() {
            if (path == p || starts_with_sep(path, p, '/'))
                && best.is_none_or(|b| p.len() > self.paths[b].len())
            {
                best = Some(k);
            }
        }
        best
    }
}

/// The rendition with the appendix *Notes* after its marker.
fn with_appendix(
    markdown: &str,
    entries: &[SpecAppendixEntry],
    titles: &Headings,
    references: bool,
) -> String {
    let mut b = markdown.trim_end_matches('\n').to_string();
    b.push_str("\n\n");
    b.push_str(SPEC_MARKDOWN_APPENDIX_MARKER);
    b.push_str("\n\n## Notes\n");
    let mut section: Option<String> = None;
    for e in entries {
        let (mut path, mut title) = (String::new(), String::new());
        if let Some(v) = &e.value {
            match titles.section(&v.path) {
                Some(k) => {
                    path = titles.paths[k].clone();
                    title = titles.titles[k].clone();
                }
                None => {
                    path = v.path.clone();
                    title = v.path.clone();
                }
            }
        }
        if section.as_deref() != Some(path.as_str()) {
            b.push_str(&format!("\n### {}\n", title));
            section = Some(path);
        }
        // A line of the entry that begins with `#` is escaped: it is no
        // heading of the appendix.
        let text: Vec<String> = e
            .text
            .split('\n')
            .map(|l| if l.starts_with('#') { format!("\\{}", l) } else { l.to_string() })
            .collect();
        let text = text.join("\n");
        let n = e.number;
        if references {
            b.push_str(&format!(
                "\n<a id=\"note-{n}\"></a>**[{n}]** {text} [\u{21a9}](#note-{n}-ref)\n"
            ));
        } else {
            b.push_str(&format!("\n**[{n}]** {text}\n"));
        }
    }
    b
}

fn in_root(prefix: &str, p: &str) -> bool {
    p == prefix || starts_with_sep(p, prefix, '/')
}

/// Compares what the rendition reads back as (`got`) with what the stripped
/// document holds (`want`), both keyed by path, under the root.
fn compare_read_back(
    what: &str,
    prefix: &str,
    want: &BTreeMap<String, String>,
    got: &BTreeMap<String, String>,
    out: &mut SpecStripResult,
) {
    let keys: BTreeSet<&String> = want.keys().chain(got.keys()).collect();
    for k in keys {
        if !in_root(prefix, k) {
            continue;
        }
        let (w, g) = (want.get(k), got.get(k));
        if let (Some(w), Some(g)) = (w, g) {
            // A wrapped paragraph written in a table cell reads back on one
            // line (SOM §11.4).
            if w == g || SpecDocumentMarkdown::wrapped_paragraph_joined(w).as_ref() == Some(g) {
                continue;
            }
        }
        let quoted = |v: Option<&String>| v.map_or("nothing".to_string(), |v| format!("\"{}\"", v));
        push_finding(
            out,
            "parse",
            format!(
                "{} at {} reads back as {} instead of {}",
                what,
                k,
                quoted(g),
                quoted(w)
            ),
            None,
        );
    }
}

/// The readable rendition reads back as the stripped document, and neither
/// it nor the stripped document adds a finding.
#[allow(clippy::too_many_arguments)]
fn check_output(
    model: &SpecModel,
    schema: Option<&DocSpecsSchema>,
    root: &SpecRoot,
    root_type: Option<&str>,
    before: &KeyPaths,
    document: &SpecDocument,
    copy: &SpecDocument,
    readable: &str,
    extra: &SpecDocumentStripOptions<'_>,
    out: &mut SpecStripResult,
) {
    let empty = SpecDocument::new();
    let parsed = extra.codec(model, &empty).parse(readable);
    for r in &parsed.rejections {
        push_finding(out, "parse", format!("the rendition rejects: {}", r.to_display()), None);
    }
    let prefix = if root.section_id.is_empty() {
        root.type_.as_str()
    } else {
        root.section_id.as_str()
    };
    let want: BTreeMap<String, String> = copy
        .content_paths()
        .into_iter()
        .map(|p| {
            let v = copy.content_or(&p);
            (p, v)
        })
        .collect();
    compare_read_back("content", prefix, &want, &parsed.content, out);
    let mut want = BTreeMap::new();
    for p in copy.form_paths() {
        for f in copy.form_field_names(&p) {
            want.insert(format!("{}/{}", p, f), copy.form_field_or(&p, &f));
        }
    }
    let mut got = BTreeMap::new();
    for (form, fields) in &parsed.forms {
        for (f, v) in fields {
            got.insert(format!("{}/{}", form, f), v.clone());
        }
    }
    compare_read_back("the form field", prefix, &want, &got, out);

    for (key, _) in tier_findings(model, schema, root_type, copy) {
        if key_has(before, &key) {
            continue;
        }
        let kind = if key.starts_with("schema") { "schema" } else { "instance" };
        push_finding(out, kind, key, None);
    }
    let Some(schema) = schema else {
        return;
    };
    let Ok(original) = extra.codec(model, document).export_root(root) else {
        return;
    };
    let val = DocSpecsValidator::with_tom_specs(schema.clone(), true);
    let key = |v: &DocSpecsViolation| format!("{} {}: {}", v.rule, v.section_id, v.message);
    let had: BTreeSet<String> = val.validate_markdown(&original).iter().map(key).collect();
    for v in val.validate_markdown(readable) {
        let k = key(&v);
        if !had.contains(&k) {
            push_finding(out, "schema", format!("the rendition: line {}: {}", v.line, k), None);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn all(list: &[&str]) -> Vec<U16> {
        list.iter().map(|s| units(s)).collect()
    }

    #[test]
    fn lines_and_tokens() {
        assert_eq!(lines(&units("a\nb\n\nc")), all(&["a\n", "b\n", "\n", "c"]));
        assert_eq!(
            tokens(&units("ab, c_d  \u{e9}!")),
            all(&["ab", ",", " ", "c_d", "  ", "\u{e9}", "!"])
        );
    }

    #[test]
    fn myers_of_tokens() {
        assert_eq!(
            myers(&all(&["a", "b", "c"]), &all(&["a", "x", "c"])),
            vec![
                (OpType::Keep, units("a")),
                (OpType::Del, units("b")),
                (OpType::Ins, units("x")),
                (OpType::Keep, units("c")),
            ]
        );
        assert!(myers(&[], &[]).is_empty());
    }
}
