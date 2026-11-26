//! The merge back (SOM §11.10; the reading view's part *Stripped renditions
//! and the merge back*): an edited readable rendition merged onto the
//! document of record, every piece the strip removed put back.
//!
//! The Rust port of `spec_document_merge.ts` / `spec_document_merge.dart`,
//! following the C++ and Python ports: [`merge_stripped_value`] merges one
//! value ([`SpecStripValueMerge`], [`SpecStripMergePlaced`],
//! [`SpecStripMergeConflict`]); [`SpecStripMerge::merge`] merges a whole
//! rendition onto its document ([`SpecStripMergeResult`],
//! [`SpecStripMergedValue`], [`SpecStripMergeRefusal`]), and
//! [`SpecStripMerge::git_show_file`] reads the base of a stale original from
//! git. `strip_merge_cases.json` holds them to the same results.
//!
//! **Offsets are UTF-16 code units**, as in every other runtime: the merge
//! works on the values as vectors of UTF-16 code units — the form the strip's
//! plan, its edit scripts and its mark finder use — and hands out ordinary
//! strings again; a placed piece's `at` counts UTF-16 units of the merged
//! value, and an excerpt is thirty units either side.

use std::collections::{BTreeMap, BTreeSet, HashMap};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use crate::docspecs_validator::{parse_docspecs_document, DocSpecsSchema, DocSpecsSection};
use crate::json::Json;
use crate::spec_document::SpecDocument;
use crate::spec_document_markdown::SpecDocumentMarkdown;
use crate::spec_document_strip::{
    diff, find_marks, from_units, js_space, key_has, lines, myers, tier_findings, units,
    value_refs, Op, OpType, SpecDocumentStrip, SpecDocumentStripOptions, SpecReadableHeader,
    SpecReadableSource, SpecStripOptions, SpecStripPiece, SpecStripUsageError, SpecStripValueRef,
    NL, U16,
};
use crate::spec_model::SpecModel;
use crate::spec_notation::{scan_notation, NotationElement, NotationFindingCode};
use crate::spec_review_annotations::annotation_issues_text;

// ---------------------------------------------------------------------------
// The result types.

/// A piece put back after an edited run rather than between unchanged
/// neighbours: an author confirms or moves it (`PLACED <value> — check`).
#[derive(Debug, Clone, PartialEq)]
pub struct SpecStripMergePlaced {
    pub piece: SpecStripPiece,
    /// The UTF-16 offset in the merged value the piece's text starts at.
    pub at: usize,
}

impl SpecStripMergePlaced {
    /// `{at, removed}`, as the conformance corpus writes it.
    pub fn to_json(&self) -> Json {
        Json::Object(vec![
            ("at".to_string(), Json::Int(self.at as i64)),
            ("removed".to_string(), Json::Str(self.piece.removed.clone())),
        ])
    }
}

/// Why a value, or the whole merge, cannot be merged. The codes:
/// `crossesBoundary`, `sentenceRemoved`, `stripTextEdited`, `unplaceable`,
/// `notation`, `annotations`, `changedBothSides`, `notStrippedBack` and
/// `newFinding`.
#[derive(Debug, Clone, Default, PartialEq)]
pub struct SpecStripMergeConflict {
    pub code: String,
    pub message: String,
    /// The value it is about; `None` when about no one value.
    pub value: Option<SpecStripValueRef>,
    /// The piece it is about; `None` when about no one piece.
    pub piece: Option<SpecStripPiece>,
    /// The original around it.
    pub excerpt_o: String,
    /// The stripped text around it.
    pub excerpt_b: String,
    /// The edited text around it.
    pub excerpt_e: String,
}

impl SpecStripMergeConflict {
    fn new(code: &str, message: &str) -> SpecStripMergeConflict {
        SpecStripMergeConflict {
            code: code.to_string(),
            message: message.to_string(),
            ..SpecStripMergeConflict::default()
        }
    }

    /// The conflict about value `value`.
    pub fn about(&self, value: &SpecStripValueRef) -> SpecStripMergeConflict {
        SpecStripMergeConflict {
            value: Some(value.clone()),
            ..self.clone()
        }
    }

    /// `CONFLICT <value> — <reason>`, then the three excerpts and the piece.
    pub fn report_lines(&self) -> Vec<String> {
        let label = self
            .value
            .as_ref()
            .map_or_else(|| "(document)".to_string(), spec_strip_merge_label);
        let mut out = vec![format!("CONFLICT {} \u{2014} {}", label, self.message)];
        if self.piece.is_some() || !self.excerpt_b.is_empty() {
            out.push(format!("  O: {}", self.excerpt_o));
            out.push(format!("  B: {}", self.excerpt_b));
            out.push(format!("  E: {}", self.excerpt_e));
        }
        if let Some(p) = &self.piece {
            out.push(format!("  piece: {}", visible(&units(&p.removed))));
        }
        out
    }

    /// `{code, value?, removed?}`, as the conformance corpus writes it.
    pub fn to_json(&self) -> Json {
        let mut out = vec![("code".to_string(), Json::Str(self.code.clone()))];
        if let Some(v) = &self.value {
            out.push(("value".to_string(), v.to_json()));
        }
        if let Some(p) = &self.piece {
            out.push(("removed".to_string(), Json::Str(p.removed.clone())));
        }
        Json::Object(out)
    }
}

/// The result of [`merge_stripped_value`].
#[derive(Debug, Clone, Default, PartialEq)]
pub struct SpecStripValueMerge {
    /// The merged value; `None` on conflicts.
    pub text: Option<String>,
    /// How many pieces were put back.
    pub restored: usize,
    pub placed: Vec<SpecStripMergePlaced>,
    pub conflicts: Vec<SpecStripMergeConflict>,
}

impl SpecStripValueMerge {
    /// Whether the value merged: no conflict.
    pub fn ok(&self) -> bool {
        self.conflicts.is_empty()
    }

    /// `{text, restored, placed, conflicts}`, as the conformance corpus
    /// writes it.
    pub fn to_json(&self) -> Json {
        Json::Object(vec![
            (
                "text".to_string(),
                self.text.clone().map(Json::Str).unwrap_or(Json::Null),
            ),
            ("restored".to_string(), Json::Int(self.restored as i64)),
            (
                "placed".to_string(),
                Json::Array(
                    self.placed
                        .iter()
                        .map(SpecStripMergePlaced::to_json)
                        .collect(),
                ),
            ),
            (
                "conflicts".to_string(),
                Json::Array(
                    self.conflicts
                        .iter()
                        .map(SpecStripMergeConflict::to_json)
                        .collect(),
                ),
            ),
        ])
    }
}

/// The name of a value in a merge report: `<path> (headline)`,
/// `<path> / <field>` or `<path>`.
pub fn spec_strip_merge_label(value: &SpecStripValueRef) -> String {
    if value.headline {
        return format!("{} (headline)", value.path);
    }
    match &value.field {
        Some(f) => format!("{} / {}", value.path, f),
        None => value.path.clone(),
    }
}

/// One value a document merge changed.
#[derive(Debug, Clone, PartialEq)]
pub struct SpecStripMergedValue {
    pub value: SpecStripValueRef,
    /// The merged value written into the document of record.
    pub text: String,
    pub restored: usize,
    pub placed: Vec<SpecStripMergePlaced>,
}

/// An edit a merge refuses. The codes: `sectionAdded`, `sectionRemoved`,
/// `sectionMoved`, `listItems`, `codeSpec`, `units`, `rejected`, `stale` and
/// `strip`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecStripMergeRefusal {
    pub code: String,
    /// `""` for the whole document.
    pub path: String,
    pub message: String,
}

impl SpecStripMergeRefusal {
    fn new(code: &str, path: &str, message: impl Into<String>) -> SpecStripMergeRefusal {
        SpecStripMergeRefusal {
            code: code.to_string(),
            path: path.to_string(),
            message: message.into(),
        }
    }

    /// `REFUSED <path> — <message>`.
    pub fn report_line(&self) -> String {
        let path = if self.path.is_empty() {
            "(document)"
        } else {
            self.path.as_str()
        };
        format!("REFUSED {} \u{2014} {}", path, self.message)
    }

    /// `{code, path}`.
    pub fn to_json(&self) -> Json {
        Json::Object(vec![
            ("code".to_string(), Json::Str(self.code.clone())),
            ("path".to_string(), Json::Str(self.path.clone())),
        ])
    }
}

/// The result of [`SpecStripMerge::merge`].
#[derive(Debug, Clone)]
pub struct SpecStripMergeResult {
    /// The merged document; `None` when nothing may be written.
    pub document: Option<SpecDocument>,
    /// The switches the rendition was stripped with.
    pub options: SpecStripOptions,
    /// Whether the merge was three-way, from the original at the export.
    pub stale: bool,
    pub merged: Vec<SpecStripMergedValue>,
    pub conflicts: Vec<SpecStripMergeConflict>,
    pub refusals: Vec<SpecStripMergeRefusal>,
}

impl SpecStripMergeResult {
    fn refused(
        options: &SpecStripOptions,
        refusals: Vec<SpecStripMergeRefusal>,
        stale: bool,
    ) -> Self {
        SpecStripMergeResult {
            document: None,
            options: options.clone(),
            stale,
            merged: Vec::new(),
            conflicts: Vec::new(),
            refusals,
        }
    }

    /// Whether the merge went through: no conflict and no refusal.
    pub fn ok(&self) -> bool {
        self.conflicts.is_empty() && self.refusals.is_empty()
    }

    /// `0` merged or nothing to merge, `1` conflicts or refusals.
    pub fn exit_code(&self) -> i32 {
        if self.ok() {
            0
        } else {
            1
        }
    }

    /// The `MERGED` / `PLACED` lines, then the conflicts' and the refusals'.
    pub fn report(&self) -> Vec<String> {
        let mut out = Vec::new();
        for m in &self.merged {
            let label = spec_strip_merge_label(&m.value);
            out.push(format!(
                "MERGED {} \u{2014} {} pieces put back",
                label, m.restored
            ));
            for _ in &m.placed {
                out.push(format!("PLACED {} \u{2014} check", label));
            }
        }
        for c in &self.conflicts {
            out.extend(c.report_lines());
        }
        out.extend(self.refusals.iter().map(SpecStripMergeRefusal::report_line));
        out
    }

    /// The report as one text, a line each.
    pub fn report_lines(&self) -> String {
        self.report().join("\n")
    }
}

/// What loads the base of a stale original for the readable header's source.
pub type SpecStripBaseLoader<'a> = dyn Fn(&SpecReadableSource) -> Option<SpecDocument> + 'a;

/// What [`SpecStripMerge::merge`] takes beyond the original and the edited
/// text.
#[derive(Clone, Copy, Default)]
pub struct SpecStripMergeOptions<'a> {
    /// The model (required).
    pub model: Option<&'a SpecModel>,
    /// The schema tier of the checks.
    pub schema: Option<&'a DocSpecsSchema>,
    /// The root; `None` for the single populated one.
    pub root_type: Option<&'a str>,
    /// Switches given beside the readable header; they must agree with it.
    pub options: Option<&'a SpecStripOptions>,
    /// The revision the original has now; a header naming another is stale.
    pub current_revision: Option<&'a str>,
    /// The original as it was at the export, given by hand.
    pub base: Option<&'a SpecDocument>,
    /// The base of a stale original from the header's source (its commit);
    /// `None` when it cannot be read.
    pub load_base: Option<&'a SpecStripBaseLoader<'a>>,
    /// The codec's file stem ([`SpecDocumentMarkdown::file_stem`]).
    pub file_stem: Option<&'a str>,
    /// The codec's document files ([`SpecDocumentMarkdown::document_files`]).
    pub document_files: Option<&'a HashMap<String, String>>,
}

// ---------------------------------------------------------------------------
// Text helpers (UTF-16 code units).

fn blank_units(s: &[u16]) -> bool {
    s.iter().all(|&c| js_space(c))
}

/// `s` in guillemets, its line breaks shown.
fn visible(s: &[u16]) -> String {
    format!("\u{ab}{}\u{bb}", from_units(s).replace('\n', "\u{23ce}"))
}

/// Thirty UTF-16 units of `s` either side of `at`, made visible.
fn excerpt(s: &[u16], at: usize) -> String {
    let a = at.min(s.len()).saturating_sub(30);
    let z = s.len().min(at + 30).max(a);
    visible(&s[a..z])
}

fn first_difference(a: &[u16], b: &[u16]) -> usize {
    a.iter()
        .zip(b)
        .position(|(x, y)| x != y)
        .unwrap_or(a.len().min(b.len()))
}

fn trailing_breaks(s: &[u16]) -> usize {
    s.iter().rev().take_while(|&&c| c == NL).count()
}

fn leading_breaks(s: &[u16]) -> usize {
    s.iter().take_while(|&&c| c == NL).count()
}

// ---------------------------------------------------------------------------
// Edit maps.

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Role {
    Whole,
    Opener,
    Closer,
    Both,
}

/// Where a gap of the baseline lies in the edited text.
#[derive(Debug, Clone, Copy)]
struct Gap {
    left_edited: bool,
    right_edited: bool,
    start: usize,
    end: usize,
}

impl Gap {
    fn unchanged_at(at: usize) -> Gap {
        Gap {
            left_edited: false,
            right_edited: false,
            start: at,
            end: at,
        }
    }

    fn unchanged(&self) -> bool {
        !self.left_edited && !self.right_edited && self.start == self.end
    }
}

/// The gap before baseline unit (or line) `p` of a script given by its op
/// types and the edited-text offsets before each op.
fn gap_at(p: usize, first: bool, types: &[OpType], e_before: &[usize]) -> Gap {
    let left_edited = !first && types[p - 1] == OpType::Del;
    let mut r = p;
    while r < types.len() && types[r] == OpType::Ins {
        r += 1;
    }
    let right_edited = r < types.len() && types[r] == OpType::Del;
    if !left_edited && r == p && !right_edited {
        return Gap::unchanged_at(e_before[p]);
    }
    let mut s = p;
    while s > 0 && types[s - 1] != OpType::Keep {
        s -= 1;
    }
    let mut t = p;
    while t < types.len() && types[t] != OpType::Keep {
        t += 1;
    }
    Gap {
        left_edited,
        right_edited,
        start: e_before[s],
        end: e_before[t],
    }
}

/// An edit script from a baseline to an edited text, indexed by baseline
/// offset.
struct EditMap {
    types: Vec<OpType>,
    after: Vec<usize>,
    e_before: Vec<usize>,
    deleted: Vec<bool>,
}

impl EditMap {
    fn new(ops: &[Op], b_length: usize) -> EditMap {
        let mut after = vec![0; b_length + 1];
        let mut e_before = vec![0; ops.len() + 1];
        let mut deleted = vec![false; b_length];
        let mut g = 0;
        for (i, op) in ops.iter().enumerate() {
            e_before[i + 1] = e_before[i] + usize::from(op.type_ != OpType::Del);
            if op.type_ != OpType::Ins {
                if op.type_ == OpType::Del {
                    deleted[g] = true;
                }
                g += 1;
                after[g] = i + 1;
            }
        }
        EditMap {
            types: ops.iter().map(|o| o.type_).collect(),
            after,
            e_before,
            deleted,
        }
    }

    fn gap(&self, g: usize) -> Gap {
        gap_at(self.after[g], g == 0, &self.types, &self.e_before)
    }

    /// The edited-text offset of baseline range `[a, z)` kept whole.
    fn kept_range(&self, a: usize, z: usize) -> Option<usize> {
        let first = self.after[a + 1] - 1;
        for k in a..z {
            let i = self.after[k + 1] - 1;
            if self.types[i] != OpType::Keep || i != first + (k - a) {
                return None;
            }
        }
        Some(self.e_before[first])
    }
}

/// A line edit script from a baseline to an edited text.
struct LineEditMap {
    ops: Vec<(OpType, U16)>,
    types: Vec<OpType>,
    after: Vec<usize>,
    e_before: Vec<usize>,
}

impl LineEditMap {
    fn new(b: &[u16], e: &[u16]) -> LineEditMap {
        let bl = lines(b);
        let el = lines(e);
        let ops = myers(&bl, &el);
        let mut after = vec![0; bl.len() + 1];
        let mut e_before = vec![0; ops.len() + 1];
        let mut k = 0;
        for (i, (t, s)) in ops.iter().enumerate() {
            e_before[i + 1] = e_before[i] + if *t == OpType::Del { 0 } else { s.len() };
            if *t != OpType::Ins {
                k += 1;
                after[k] = i + 1;
            }
        }
        LineEditMap {
            types: ops.iter().map(|(t, _)| *t).collect(),
            ops,
            after,
            e_before,
        }
    }

    fn gap(&self, k: usize) -> Gap {
        gap_at(self.after[k], k == 0, &self.types, &self.e_before)
    }

    /// Where a block goes back in a gap edited on both sides: before the
    /// paragraph the edited text holds where the baseline had as many
    /// paragraphs before the block as it removed.
    fn paragraph_place(&self, gap: &Gap, k: usize) -> usize {
        let p = self.after[k];
        let mut s = p;
        while s > 0 && self.types[s - 1] != OpType::Keep {
            s -= 1;
        }
        let mut before = 0;
        let mut blank = true;
        for (t, line) in &self.ops[s..p] {
            if *t != OpType::Del {
                continue;
            }
            let is_blank = blank_units(line);
            if !is_blank && blank {
                before += 1;
            }
            blank = is_blank;
        }
        if before == 0 {
            return gap.start;
        }
        let mut count = 0;
        blank = true;
        for i in s..self.ops.len() {
            let (t, line) = &self.ops[i];
            if *t == OpType::Keep {
                break;
            }
            if *t != OpType::Ins {
                continue;
            }
            let is_blank = blank_units(line);
            if !is_blank && blank {
                if count == before {
                    return self.e_before[i];
                }
                count += 1;
            }
            blank = is_blank;
        }
        gap.end
    }
}

/// The script with each run of whitespace edits slid to lead (`leading`) or
/// trail its unchanged neighbours, where the same whitespace stands there.
fn slide(ops: &[Op], leading: bool) -> Vec<Op> {
    let mut out = ops.to_vec();
    let keep = |ch: u16| Op {
        type_: OpType::Keep,
        ch,
        label: None,
    };
    let edit = |type_: OpType, ch: u16| Op {
        type_,
        ch,
        label: Some("edit".to_string()),
    };
    let mut s = 0;
    while s < out.len() {
        if out[s].type_ == OpType::Keep {
            s += 1;
            continue;
        }
        let mut t = s;
        while t < out.len() && out[t].type_ == out[s].type_ {
            t += 1;
        }
        if t < out.len() && out[t].type_ != OpType::Keep {
            while t < out.len() && out[t].type_ != OpType::Keep {
                t += 1;
            }
            s = t;
            continue;
        }
        let type_ = out[s].type_;
        if leading {
            while s > 0
                && out[s - 1].type_ == OpType::Keep
                && js_space(out[t - 1].ch)
                && out[s - 1].ch == out[t - 1].ch
            {
                out[t - 1] = keep(out[t - 1].ch);
                out[s - 1] = edit(type_, out[s - 1].ch);
                s -= 1;
                t -= 1;
            }
        } else {
            while t < out.len()
                && out[t].type_ == OpType::Keep
                && js_space(out[s].ch)
                && out[s].ch == out[t].ch
            {
                out[s] = keep(out[s].ch);
                out[t] = edit(type_, out[t].ch);
                s += 1;
                t += 1;
            }
        }
        s = t;
    }
    out
}

fn line_index(b: &[u16], g: usize) -> usize {
    let mut k = b[..g].iter().filter(|&&c| c == NL).count();
    if g == b.len() && b.last().is_some_and(|&c| c != NL) {
        k += 1;
    }
    k
}

/// Whether the edit removed the whole sentence of `b` holding offset `g`.
fn sentence_removed(b: &[u16], g: usize, map: &EditMap) -> bool {
    let ends =
        |i: usize| matches!(b[i], 0x2E | 0x21 | 0x3F) && (i + 1 >= b.len() || js_space(b[i + 1]));
    let mut s = g;
    while s > 0 && b[s - 1] != NL && !(s < g && ends(s - 1)) {
        s -= 1;
    }
    let mut e = g;
    while e < b.len() && b[e] != NL {
        if ends(e) {
            e += 1;
            break;
        }
        e += 1;
    }
    let mut any = false;
    for (&c, &deleted) in b[s..e].iter().zip(&map.deleted[s..e]) {
        if js_space(c) {
            continue;
        }
        any = true;
        if !deleted {
            return false;
        }
    }
    any
}

/// Marks the opener and the closer piece of an element's markers.
type PairFn<'a> = dyn Fn(&mut [bool], &mut [bool], usize, usize, usize, usize) + 'a;

/// What each piece is, read from the original `o`: a whole element, the
/// opening or the closing marker of an unmarked element, or both (the closer
/// of one and the opener of the next).
fn piece_roles(o: &[u16], o8: &str, pieces: &[SpecStripPiece], removed: &[U16]) -> Vec<Role> {
    let mut at: Vec<Option<usize>> = vec![None; o.len()];
    for (i, p) in pieces.iter().enumerate() {
        for slot in at.iter_mut().skip(p.origin).take(removed[i].len()) {
            *slot = Some(i);
        }
    }
    let mut opener = vec![false; pieces.len()];
    let mut closer = vec![false; pieces.len()];
    let first = |s: usize, e: usize| -> Option<usize> {
        (s..e.min(o.len()))
            .find(|&k| !js_space(o[k]))
            .and_then(|k| at[k])
    };
    let whole = |start: usize, end: usize| -> bool {
        if !(start < end && start < o.len() && at[start].is_some()) {
            return false;
        }
        (start..end).all(|k| k < o.len() && at[k] == at[start])
    };
    let pair = |opener: &mut [bool],
                closer: &mut [bool],
                start: usize,
                open_end: usize,
                close_start: usize,
                end: usize| {
        if whole(start, end) {
            return;
        }
        let po = first(start, open_end);
        let pc = first(close_start, end);
        if let Some(po) = po.filter(|&x| Some(x) != pc) {
            opener[po] = true;
        }
        if let Some(pc) = pc.filter(|&x| Some(x) != po) {
            closer[pc] = true;
        }
    };
    fn walk(
        list: &[NotationElement],
        opener: &mut [bool],
        closer: &mut [bool],
        whole: &dyn Fn(usize, usize) -> bool,
        first: &dyn Fn(usize, usize) -> Option<usize>,
        pair: &PairFn<'_>,
    ) {
        for e in list {
            if e.type_ == "citation" {
                if whole(e.start, e.end) {
                    continue;
                }
                if let Some(po) = first(e.start + 1, e.content_start) {
                    opener[po] = true;
                }
            } else {
                pair(
                    opener,
                    closer,
                    e.start,
                    e.content_start,
                    e.content_end,
                    e.end,
                );
            }
            walk(&e.children, opener, closer, whole, first, pair);
        }
    }
    walk(
        &scan_notation(o8, true).elements,
        &mut opener,
        &mut closer,
        &whole,
        &first,
        &pair,
    );
    for m in find_marks(o) {
        let open_end = m.sep.map_or(m.body_start, |sp| sp + 2);
        pair(
            &mut opener,
            &mut closer,
            m.start,
            open_end,
            m.body_end,
            m.end,
        );
    }
    (0..pieces.len())
        .map(|i| match (opener[i], closer[i]) {
            (true, true) => Role::Both,
            (true, false) => Role::Opener,
            (false, true) => Role::Closer,
            (false, false) => Role::Whole,
        })
        .collect()
}

/// Text to write into the edited value at `at`.
struct Put {
    at: usize,
    order: usize,
    text: U16,
    replace: usize,
    normalize: bool,
    before: usize,
    after: usize,
}

impl Put {
    fn at(at: usize, order: usize, text: U16) -> Put {
        Put {
            at,
            order,
            text,
            replace: 0,
            normalize: false,
            before: 2,
            after: 2,
        }
    }
}

fn notation_errors(s: &str) -> usize {
    scan_notation(s, true)
        .findings
        .iter()
        .filter(|f| f.severity() == "error" && f.code != NotationFindingCode::RejectedBlock)
        .count()
}

/// The blank lines a block keeps from the text beside it: a blank line, or
/// none when it stood right against a line; at an edge a blank line.
fn distance(breaks: usize, edge: bool) -> usize {
    if edge {
        2
    } else {
        breaks.clamp(1, 2)
    }
}

// ---------------------------------------------------------------------------
// One value.

/// Merges the edited text `edited` of one value back onto its `original`
/// (SOM §11.10): `stripped` is the original stripped and `pieces` what the
/// strip removed, anchored in it. A piece goes back between its unchanged
/// neighbours; next to an edit it is placed after the edited run (reported as
/// placed) or, where that would be a guess — an edit across the boundary of an
/// unmarked element (`crossesBoundary`), the whole sentence holding the piece
/// removed (`sentenceRemoved`), the text the strip wrote edited
/// (`stripTextEdited`), a block without a line to go back to (`unplaceable`)
/// — it is a conflict, and so is a merged value with a notation error or a
/// malformed annotation neither side had.
pub fn merge_stripped_value(
    original: &str,
    stripped: &str,
    edited: &str,
    pieces: &[SpecStripPiece],
) -> SpecStripValueMerge {
    if edited == stripped {
        return SpecStripValueMerge {
            text: Some(original.to_string()),
            restored: pieces.len(),
            ..SpecStripValueMerge::default()
        };
    }
    let (o, b, e) = (units(original), units(stripped), units(edited));
    let removed_of: Vec<U16> = pieces.iter().map(|p| units(&p.removed)).collect();
    let inserted_of: Vec<U16> = pieces.iter().map(|p| units(&p.inserted)).collect();
    let roles = piece_roles(&o, original, pieces, &removed_of);
    let ops = diff(&b, &e, "edit");
    let map = EditMap::new(&ops, b.len());
    // An opening marker is judged on the script whose whitespace edits trail
    // their run, a closing one on the script whose whitespace edits lead it.
    let trailing = EditMap::new(&slide(&ops, false), b.len());
    let leading = EditMap::new(&slide(&ops, true), b.len());
    let mut line_map: Option<LineEditMap> = None;
    let mut puts: Vec<Put> = Vec::new();
    let mut placed_at: BTreeSet<usize> = BTreeSet::new();
    let mut conflicts: Vec<SpecStripMergeConflict> = Vec::new();
    let mut restored = 0;
    for (i, p) in pieces.iter().enumerate() {
        let anchor = p.anchor;
        let conflict = |code: &str, message: &str, e_at: usize| SpecStripMergeConflict {
            code: code.to_string(),
            message: message.to_string(),
            value: None,
            piece: Some(p.clone()),
            excerpt_o: excerpt(&o, p.origin),
            excerpt_b: excerpt(&b, anchor),
            excerpt_e: excerpt(&e, e_at),
        };

        if !inserted_of[i].is_empty() {
            match map.kept_range(anchor, anchor + inserted_of[i].len()) {
                None => conflicts.push(conflict(
                    "stripTextEdited",
                    "the text the strip wrote in place of a piece was edited",
                    map.gap(anchor).start,
                )),
                Some(at) => {
                    let mut put = Put::at(at, i, removed_of[i].clone());
                    put.replace = inserted_of[i].len();
                    puts.push(put);
                    restored += 1;
                }
            }
            continue;
        }

        let role = roles[i];
        let mut g = anchor;
        let mut text = removed_of[i].clone();
        if role == Role::Whole && text.contains(&NL) {
            while g > 0 && b[g - 1] != NL && g < b.len() && text[0] == b[g] {
                text.rotate_left(1);
                g += 1;
            }
            if g == 0 || b[g - 1] == NL || g == b.len() {
                let lm = line_map.get_or_insert_with(|| LineEditMap::new(&b, &e));
                let k = line_index(&b, g);
                let gap = lm.gap(k);
                if gap.unchanged() {
                    puts.push(Put::at(gap.start, i, text));
                    restored += 1;
                    continue;
                }
                let at = if !gap.left_edited {
                    gap.start
                } else if !gap.right_edited {
                    gap.end
                } else {
                    lm.paragraph_place(&gap, k)
                };
                if at > 0 && at < e.len() && e[at - 1] != NL {
                    conflicts.push(conflict(
                        "unplaceable",
                        "the block has no line boundary to go back to",
                        at,
                    ));
                    continue;
                }
                // The block keeps the distance it had from the text around it
                // in the original: a blank line, or none when it stood right
                // against a line.
                let rem = &removed_of[i];
                let core = p.origin + leading_breaks(rem);
                let core_end = p.origin + rem.len() - trailing_breaks(rem);
                let mut put = Put::at(at, i, text);
                put.normalize = true;
                put.before = distance(trailing_breaks(&o[..core.min(o.len())]), core == 0);
                put.after = distance(
                    leading_breaks(if core_end < o.len() {
                        &o[core_end..]
                    } else {
                        &[]
                    }),
                    core_end >= o.len(),
                );
                puts.push(put);
                restored += 1;
                continue;
            }
            g = anchor;
            text = removed_of[i].clone();
        }

        let m = match role {
            Role::Opener => &trailing,
            Role::Closer => &leading,
            _ => &map,
        };
        let gap = m.gap(g);
        if gap.unchanged() {
            puts.push(Put::at(gap.start, i, text));
            restored += 1;
            continue;
        }
        if blank_units(&text) {
            continue; // normalised whitespace at an edit
        }
        match role {
            Role::Opener | Role::Closer => {
                if gap.left_edited && gap.right_edited {
                    conflicts.push(conflict(
                        "crossesBoundary",
                        "an edit crosses the boundary of an unmarked element",
                        gap.start,
                    ));
                    continue;
                }
                // The edit on the inner side of the marker goes inside the
                // element.
                let at = if role == Role::Opener {
                    if gap.left_edited {
                        gap.end
                    } else {
                        gap.start
                    }
                } else if gap.right_edited {
                    gap.start
                } else {
                    gap.end
                };
                puts.push(Put::at(at, i, text));
                restored += 1;
            }
            Role::Both => conflicts.push(conflict(
                "crossesBoundary",
                "an edit touches the boundary between two unmarked elements",
                gap.start,
            )),
            Role::Whole => {
                if sentence_removed(&b, g, &map) {
                    conflicts.push(conflict(
                        "sentenceRemoved",
                        "the edit removed the whole sentence holding the piece",
                        gap.start,
                    ));
                    continue;
                }
                puts.push(Put::at(gap.end, i, text));
                placed_at.insert(i);
                restored += 1;
            }
        }
    }
    if !conflicts.is_empty() {
        return SpecStripValueMerge {
            conflicts,
            ..SpecStripValueMerge::default()
        };
    }

    puts.sort_by_key(|p| (p.at, p.order));
    let mut out: U16 = Vec::new();
    let mut placed: Vec<SpecStripMergePlaced> = Vec::new();
    let mut pos = 0;
    for put in &puts {
        if put.at < pos {
            let mut c =
                SpecStripMergeConflict::new("stripTextEdited", "two pieces claim the same text");
            c.piece = Some(pieces[put.order].clone());
            conflicts.push(c);
            continue;
        }
        out.extend_from_slice(&e[pos..put.at]);
        pos = put.at;
        let mut place = |out: &U16| {
            if placed_at.contains(&put.order) {
                placed.push(SpecStripMergePlaced {
                    piece: pieces[put.order].clone(),
                    at: out.len(),
                });
            }
        };
        if put.normalize {
            let a = leading_breaks(&put.text);
            let z = (put.text.len() - trailing_breaks(&put.text)).max(a);
            if !out.is_empty() {
                let have = trailing_breaks(&out);
                out.extend(std::iter::repeat_n(NL, put.before.saturating_sub(have)));
            }
            place(&out);
            out.extend_from_slice(&put.text[a..z]);
            let right = &e[pos.min(e.len())..];
            if !right.is_empty() {
                let have = leading_breaks(right);
                out.extend(std::iter::repeat_n(NL, put.after.saturating_sub(have)));
            }
        } else {
            place(&out);
            out.extend_from_slice(&put.text);
        }
        pos += put.replace;
    }
    if pos < e.len() {
        out.extend_from_slice(&e[pos..]);
    }
    let merged = from_units(&out);

    if notation_errors(&merged) > notation_errors(edited) + notation_errors(original) {
        conflicts.push(SpecStripMergeConflict::new(
            "notation",
            "the merged value has a notation error neither the original nor the edited text has",
        ));
    }
    if annotation_issues_text(&merged).len()
        > annotation_issues_text(edited).len() + annotation_issues_text(original).len()
    {
        conflicts.push(SpecStripMergeConflict::new(
            "annotations",
            "the merged value has a malformed review annotation neither the original nor the \
             edited text has",
        ));
    }
    if !conflicts.is_empty() {
        return SpecStripValueMerge {
            conflicts,
            ..SpecStripValueMerge::default()
        };
    }
    SpecStripValueMerge {
        text: Some(merged),
        restored,
        placed,
        conflicts: Vec::new(),
    }
}

// ---------------------------------------------------------------------------
// A document.

fn options_text(o: &SpecStripOptions) -> String {
    let s = SpecReadableHeader::format(o, None);
    let inner = &s["<!-- readable:".len()..s.len() - 3];
    inner.trim_matches(|c| c == ' ' || c == '\t').to_string()
}

fn ref_key(r: &SpecStripValueRef) -> String {
    let kind = if r.headline {
        "h"
    } else if r.field.is_some() {
        "f"
    } else {
        "c"
    };
    format!("{}\0{}\0{}", kind, r.path, r.field.as_deref().unwrap_or(""))
}

/// The section-id paths of `markdown`'s headings, in order.
fn heading_paths(markdown: &str) -> Vec<String> {
    fn walk(list: &[DocSpecsSection], prefix: &str, out: &mut Vec<String>) {
        for s in list {
            let id = if s.id.is_empty() { "?" } else { s.id.as_str() };
            let p = if prefix.is_empty() {
                id.to_string()
            } else {
                format!("{}/{}", prefix, id)
            };
            out.push(p.clone());
            walk(&s.children, &p, out);
        }
    }
    let mut out = Vec::new();
    walk(&parse_docspecs_document(markdown).sections, "", &mut out);
    out
}

type ListShape = (Vec<String>, BTreeMap<String, String>);

/// The lists of `doc` under the roots, each as its items and their ids.
fn lists_under(doc: &SpecDocument, in_root: &dyn Fn(&str) -> bool) -> BTreeMap<String, ListShape> {
    doc.to_json()
        .lists
        .into_iter()
        .filter(|(k, _)| in_root(k))
        .map(|(k, v)| (k, (v.items, v.ids)))
        .collect()
}

/// Merging an edited readable rendition back onto its document (SOM §11.10).
pub struct SpecStripMerge;

impl SpecStripMerge {
    /// Merges `edited`, a `.readable.md` made from `original` and changed by
    /// a reader, back onto `original` (SOM §11.10).
    ///
    /// The switches come from the rendition's readable header, or from
    /// `extra.options` (which must agree with a header); with neither, or
    /// without a model, the merge is a [`SpecStripUsageError`]. The original
    /// is stale when a `base` is given or the header's revision differs from
    /// `current_revision`: the merge is then three-way, from the base given
    /// or from the header's commit through `load_base`, and refused (`stale`)
    /// without one. Structural edits — sections or list items added, removed
    /// or moved, a changed codeSpec or units — and a rendition with rejected
    /// blocks are refused; every other changed value is merged with
    /// [`merge_stripped_value`]. A value whose only change is a wrapped
    /// paragraph read back on one line (SOM §11.4 rule 13) is no edit. The
    /// merged document is checked to change only the merged values, to strip
    /// back to the edited text and to add no finding;
    /// [`SpecStripMergeResult::document`] is `None` unless all of that holds.
    /// `original` is never changed.
    pub fn merge(
        original: &SpecDocument,
        edited: &str,
        extra: &SpecStripMergeOptions<'_>,
    ) -> Result<SpecStripMergeResult, SpecStripUsageError> {
        let model = extra
            .model
            .ok_or_else(|| SpecStripUsageError::new("a merge needs the model"))?;
        let (schema, root_type) = (extra.schema, extra.root_type);
        let codec_options = SpecDocumentStripOptions {
            file_stem: extra.file_stem,
            document_files: extra.document_files,
            ..SpecDocumentStripOptions::default()
        };
        let empty = SpecDocument::new();
        let parsed = codec_options.codec(model, &empty).parse(edited);
        let header = match &parsed.readable_header {
            None => None,
            Some(line) => Some(SpecReadableHeader::parse(line).ok_or_else(|| {
                SpecStripUsageError::new(format!("the readable header cannot be read: {}", line))
            })?),
        };
        let opts = match (extra.options, &header) {
            (Some(given), Some(h)) if options_text(&h.options) != options_text(given) => {
                return Err(SpecStripUsageError::new(format!(
                    "the switches given ({}) disagree with the readable header ({})",
                    options_text(given),
                    options_text(&h.options)
                )));
            }
            (Some(given), _) => given.clone(),
            (None, Some(h)) => h.options.clone(),
            (None, None) => {
                return Err(SpecStripUsageError::new(
                    "the rendition has no readable header: name the switches it was stripped with",
                ));
            }
        };

        if !parsed.rejections.is_empty() {
            let r = parsed
                .rejections
                .iter()
                .map(|x| {
                    SpecStripMergeRefusal::new(
                        "rejected",
                        "",
                        format!("line {}: {}", x.line, x.message),
                    )
                })
                .collect();
            return Ok(SpecStripMergeResult::refused(&opts, r, false));
        }

        let source = header.as_ref().and_then(|h| h.source.as_ref());
        let current_revision = extra.current_revision;
        let stale = extra.base.is_some()
            || source.is_some_and(|s| {
                s.revision.is_some()
                    && current_revision.is_some()
                    && s.revision.as_deref() != current_revision
            });
        let mut loaded: Option<SpecDocument> = None;
        let mut origin = original;
        if stale {
            if let Some(base) = extra.base {
                origin = base;
            } else {
                if let (Some(s), Some(load)) = (source, extra.load_base) {
                    if s.commit.is_some() && !s.dirty {
                        loaded = load(s);
                    }
                }
                match &loaded {
                    Some(l) => origin = l,
                    None => {
                        let why = match source {
                            Some(s) if s.commit.is_some() => {
                                if s.dirty {
                                    "names a dirty commit"
                                } else {
                                    "names a commit that could not be read"
                                }
                            }
                            _ => "names no commit",
                        };
                        let then = source.and_then(|s| s.revision.as_deref()).unwrap_or("null");
                        let r = SpecStripMergeRefusal::new(
                            "stale",
                            "",
                            format!(
                                "the original moved since the export (revision {} then, {} now) and \
                                 there is no base: the header {}; give the original as it was at the \
                                 export",
                                then,
                                current_revision.unwrap_or("null"),
                                why
                            ),
                        );
                        return Ok(SpecStripMergeResult::refused(&opts, vec![r], true));
                    }
                }
            }
        }

        let strip_extra = SpecDocumentStripOptions {
            model: Some(model),
            schema,
            root_type,
            source: None,
            file_stem: extra.file_stem,
            document_files: extra.document_files,
        };
        let strip = SpecDocumentStrip::strip(origin, &opts, &strip_extra);
        let Some(readable) = strip.readable.as_ref().filter(|_| strip.ok()) else {
            let mut r: Vec<SpecStripMergeRefusal> = strip
                .findings
                .iter()
                .map(|f| {
                    SpecStripMergeRefusal::new(
                        "strip",
                        &f.value
                            .as_ref()
                            .map(SpecStripValueRef::label)
                            .unwrap_or_default(),
                        f.to_string(),
                    )
                })
                .collect();
            if r.is_empty() {
                r.push(SpecStripMergeRefusal::new(
                    "strip",
                    "",
                    "the base renders no rendition",
                ));
            }
            return Ok(SpecStripMergeResult::refused(&opts, r, stale));
        };
        let b_doc = &strip.document;
        let mut e_doc = SpecDocument::new();
        // The rejections were refused above: nothing is left to refuse here.
        let _ = e_doc.apply_markdown_result(&parsed, true);
        let roots: Vec<&String> = parsed.root_prefixes.iter().collect();
        let in_root = |p: &str| {
            roots.iter().any(|r| {
                p == r.as_str()
                    || (p.len() > r.len()
                        && p.starts_with(r.as_str())
                        && matches!(p.as_bytes()[r.len()], b'/' | b'-'))
            })
        };

        // Structural edits.
        let mut refusals: Vec<SpecStripMergeRefusal> = Vec::new();
        let b_headings = heading_paths(readable);
        let e_headings = heading_paths(edited);
        if b_headings != e_headings {
            let b_set: BTreeSet<&String> = b_headings.iter().collect();
            let e_set: BTreeSet<&String> = e_headings.iter().collect();
            for p in e_headings.iter().filter(|p| !b_set.contains(p)) {
                refusals.push(SpecStripMergeRefusal::new(
                    "sectionAdded",
                    p,
                    "a section added",
                ));
            }
            for p in b_headings.iter().filter(|p| !e_set.contains(p)) {
                refusals.push(SpecStripMergeRefusal::new(
                    "sectionRemoved",
                    p,
                    "a section removed",
                ));
            }
            if refusals.is_empty() {
                let common: Vec<&String> =
                    e_headings.iter().filter(|p| b_set.contains(p)).collect();
                let want: Vec<&String> = b_headings.iter().filter(|p| e_set.contains(p)).collect();
                if let Some((p, _)) = common.iter().zip(&want).find(|(c, w)| c != w) {
                    refusals.push(SpecStripMergeRefusal::new(
                        "sectionMoved",
                        p,
                        "a section moved",
                    ));
                }
            }
        }
        let b_lists = lists_under(b_doc, &in_root);
        let e_lists = lists_under(&e_doc, &in_root);
        let list_keys: BTreeSet<&String> = b_lists.keys().chain(e_lists.keys()).collect();
        for l in list_keys {
            if b_lists.get(l) != e_lists.get(l) {
                refusals.push(SpecStripMergeRefusal::new(
                    "listItems",
                    l,
                    "list items added, removed, moved or renamed",
                ));
            }
        }
        for code in ["codeSpec", "units"] {
            let is_code = code == "codeSpec";
            let read = |d: &SpecDocument, p: &str| -> Option<String> {
                if is_code {
                    d.code_spec(p).cloned()
                } else {
                    d.units(p).cloned()
                }
            };
            let mut all: BTreeSet<String> = BTreeSet::new();
            for d in [b_doc, &e_doc] {
                let paths = if is_code {
                    d.code_spec_paths()
                } else {
                    d.units_paths()
                };
                all.extend(paths.into_iter().filter(|p| in_root(p)));
            }
            for p in &all {
                if read(b_doc, p) != read(&e_doc, p) {
                    refusals.push(SpecStripMergeRefusal::new(
                        code,
                        p,
                        format!("a changed {}", code),
                    ));
                }
            }
        }
        let mut by_key: BTreeMap<String, SpecStripValueRef> = BTreeMap::new();
        for d in [b_doc, &e_doc] {
            for r in value_refs(d) {
                if in_root(&r.path) {
                    by_key.insert(ref_key(&r), r);
                }
            }
        }
        let mut refs: Vec<SpecStripValueRef> = by_key.into_values().collect();
        refs.sort_by(|x, y| {
            x.path
                .cmp(&y.path)
                .then_with(|| y.headline.cmp(&x.headline))
                .then_with(|| {
                    x.field
                        .as_deref()
                        .unwrap_or("")
                        .cmp(y.field.as_deref().unwrap_or(""))
                })
        });
        let refused_at = |refusals: &[SpecStripMergeRefusal], path: &str| {
            refusals.iter().any(|r| r.path == path)
        };
        for r in &refs {
            if r.read(b_doc).is_empty()
                && !r.read(&e_doc).is_empty()
                && !b_doc.has_values_under(&r.path)
                && !refused_at(&refusals, &r.path)
            {
                refusals.push(SpecStripMergeRefusal::new(
                    "sectionAdded",
                    &r.path,
                    "a value in a section the rendition does not show",
                ));
            }
        }

        // The values.
        let pieces: BTreeMap<String, &Vec<SpecStripPiece>> = strip
            .values
            .iter()
            .map(|v| (ref_key(&v.value), &v.pieces))
            .collect();
        let mut res = SpecStripMergeResult::refused(&opts, Vec::new(), stale);
        for r in &refs {
            let b_text = r.read(b_doc);
            let e_text = r.read(&e_doc);
            // A wrapped paragraph written in a table cell reads back on one
            // line (SOM §11.4 rule 13): that alone is no edit.
            if b_text == e_text
                || SpecDocumentMarkdown::wrapped_paragraph_joined(&b_text).as_deref()
                    == Some(e_text.as_str())
            {
                continue;
            }
            if refused_at(&refusals, &r.path) {
                continue;
            }
            // A value whose section came or went with a refused edit is that
            // edit.
            if !refusals.is_empty()
                && (!b_doc.has_values_under(&r.path) || !e_doc.has_values_under(&r.path))
            {
                continue;
            }
            let o = r.read(origin);
            let these: &[SpecStripPiece] = pieces.get(&ref_key(r)).map_or(&[], |p| p.as_slice());
            let m = merge_stripped_value(&o, &b_text, &e_text, these);
            let now = r.read(original);
            if stale && now != o {
                // The edit is already in the moved original (the same
                // rendition merged before): nothing to do for this value.
                if m.ok() && m.text.as_deref() == Some(now.as_str()) {
                    continue;
                }
                let (b16, e16, o16, now16) =
                    (units(&b_text), units(&e_text), units(&o), units(&now));
                let at = first_difference(&b16, &e16);
                res.conflicts.push(SpecStripMergeConflict {
                    code: "changedBothSides".to_string(),
                    message:
                        "the value changed in the original since the export, and in the rendition"
                            .to_string(),
                    value: Some(r.clone()),
                    piece: None,
                    excerpt_o: excerpt(&now16, first_difference(&o16, &now16)),
                    excerpt_b: excerpt(&b16, at),
                    excerpt_e: excerpt(&e16, at),
                });
                continue;
            }
            if !m.ok() {
                res.conflicts.extend(m.conflicts.iter().map(|c| c.about(r)));
                continue;
            }
            res.merged.push(SpecStripMergedValue {
                value: r.clone(),
                text: m.text.unwrap_or_default(),
                restored: m.restored,
                placed: m.placed,
            });
        }
        if !res.conflicts.is_empty() || !refusals.is_empty() {
            res.refusals = refusals;
            return Ok(res);
        }

        // Write and verify.
        let mut out = original.clone();
        let mut expected: BTreeSet<String> = BTreeSet::new();
        for m in &res.merged {
            if m.text != m.value.read(original) {
                expected.insert(ref_key(&m.value));
            }
            m.value.write(&mut out, &m.text);
        }
        let mut changed: BTreeSet<String> = BTreeSet::new();
        for d in [original, &out] {
            for r in value_refs(d) {
                if r.read(original) != r.read(&out) {
                    changed.insert(ref_key(&r));
                }
            }
        }
        if changed != expected {
            res.conflicts.push(SpecStripMergeConflict::new(
                "newFinding",
                "the merged document changes other values than the merged ones",
            ));
        }
        let again = SpecDocumentStrip::strip(&out, &opts, &strip_extra);
        for m in &res.merged {
            let back = m.value.read(&again.document);
            let want = m.value.read(&e_doc);
            if back != want {
                res.conflicts.push(SpecStripMergeConflict {
                    code: "notStrippedBack".to_string(),
                    message: "the merged value does not strip back to the edited text".to_string(),
                    value: Some(m.value.clone()),
                    piece: None,
                    excerpt_o: excerpt(&units(&m.text), 0),
                    excerpt_b: excerpt(&units(&back), 0),
                    excerpt_e: excerpt(&units(&want), 0),
                });
            }
        }
        let before = tier_findings(model, schema, root_type, original);
        for (k, _) in tier_findings(model, schema, root_type, &out) {
            if !key_has(&before, &k) {
                res.conflicts.push(SpecStripMergeConflict::new(
                    "newFinding",
                    &format!("the merged document has a new finding: {}", k),
                ));
            }
        }
        if res.conflicts.is_empty() {
            res.document = Some(out);
        }
        Ok(res)
    }

    /// The file at `file_path` as it was at `commit` (`git show
    /// <commit>:./<name>`, run in the file's folder); `None` when git cannot
    /// give it. What a `load_base` reads the base of a stale original with.
    /// No commit, or one starting with `-`, gives `None`: it is never an
    /// option to git.
    pub fn git_show_file(commit: Option<&str>, file_path: &str) -> Option<String> {
        let commit = commit.filter(|c| !c.is_empty() && !c.starts_with('-'))?;
        let path = Path::new(file_path);
        let path: PathBuf = if path.is_absolute() {
            path.to_path_buf()
        } else {
            std::env::current_dir().ok()?.join(path)
        };
        let folder = path.parent()?;
        let name = path.file_name()?.to_str()?;
        if !folder.is_dir() {
            return None;
        }
        let done = Command::new("git")
            .arg("show")
            .arg(format!("{}:./{}", commit, name))
            .current_dir(folder)
            .stdin(Stdio::null())
            .stdout(Stdio::piped())
            .stderr(Stdio::null())
            .output()
            .ok()?;
        if !done.status.success() {
            return None;
        }
        Some(String::from_utf8_lossy(&done.stdout).into_owned())
    }
}
