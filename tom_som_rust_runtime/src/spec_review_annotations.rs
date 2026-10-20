//! `spec_review_annotations` — review annotations in content values (SOM
//! §11.9): comment blocks, question blocks and CriticMarkup inline marks. A
//! port of the Dart reference `spec_review_annotations.dart`.
//!
//! An annotation is text inside a content value or a form-field value. This
//! module reads it out of that text and edits it in place, and every edit is
//! byte-stable outside the annotation it touches. The notation itself is
//! `som_multiplatform_spec_model.md` §11.9.
//!
//! Positions are **0-based line numbers within the value**, never character
//! offsets: the nine runtimes count characters in different units, and a line
//! number is the same in all of them. Internally this port works in UTF-8 byte
//! offsets, which are never exported.

use crate::json::Json;
use crate::spec_document::SpecDocument;
use crate::spec_validator::{
    SpecValidationError, SPEC_VALIDATION_CODE_ANNOTATION_MALFORMED,
    SPEC_VALIDATION_CODE_ANNOTATION_MISPLACED, SPEC_VALIDATION_CODE_DUPLICATE_ANNOTATION_ID,
};
use std::collections::{HashMap, HashSet};

/// The three kinds of annotation (SOM §11.9).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SpecReviewAnnotationKind {
    /// A reviewer's comment block, `> ⬆️ **C-12** (Alexis): …`.
    Comment,
    /// One question of a question block, `> **❓ BQ-81 — topic:** …`.
    Question,
    /// A CriticMarkup inline mark.
    Mark,
}

impl SpecReviewAnnotationKind {
    /// Every kind, in declaration order.
    pub const ALL: [SpecReviewAnnotationKind; 3] = [
        SpecReviewAnnotationKind::Comment,
        SpecReviewAnnotationKind::Question,
        SpecReviewAnnotationKind::Mark,
    ];

    /// The wire name (`comment`, `question`, `mark`).
    pub fn name(self) -> &'static str {
        match self {
            SpecReviewAnnotationKind::Comment => "comment",
            SpecReviewAnnotationKind::Question => "question",
            SpecReviewAnnotationKind::Mark => "mark",
        }
    }
}

/// The five CriticMarkup inline marks (SOM §11.9.3).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SpecMarkKind {
    /// `{>> comment <<}`.
    Comment,
    /// `{== text ==}`, optionally followed by `{>> comment <<}`.
    Highlight,
    /// `{++ added ++}`.
    Insertion,
    /// `{-- removed --}`.
    Deletion,
    /// `{~~ old ~> new ~~}`.
    Substitution,
}

impl SpecMarkKind {
    /// Every kind, in declaration order.
    pub const ALL: [SpecMarkKind; 5] = [
        SpecMarkKind::Comment,
        SpecMarkKind::Highlight,
        SpecMarkKind::Insertion,
        SpecMarkKind::Deletion,
        SpecMarkKind::Substitution,
    ];

    /// The wire name (`comment`, `highlight`, `insertion`, `deletion`,
    /// `substitution`).
    pub fn name(self) -> &'static str {
        match self {
            SpecMarkKind::Comment => "comment",
            SpecMarkKind::Highlight => "highlight",
            SpecMarkKind::Insertion => "insertion",
            SpecMarkKind::Deletion => "deletion",
            SpecMarkKind::Substitution => "substitution",
        }
    }
}

/// One annotation, located by the value that holds it.
#[derive(Debug, Clone, PartialEq)]
pub struct SpecReviewAnnotation {
    /// The kind.
    pub kind: SpecReviewAnnotationKind,
    /// The document path of the value: a content path, or a form path when
    /// [`field`](Self::field) is set.
    pub path: String,
    /// The form field whose value holds the annotation; `None` for content.
    pub field: Option<String>,
    /// The 0-based line within the value where the annotation starts (a
    /// question: its header line).
    pub line: usize,
    /// The comment id (`C-12`) or question id (`BQ-81`); `None` for a comment
    /// without an id and for a mark.
    pub id: Option<String>,
    /// A comment's id with the document qualifier in front (`SBP C-12`), when
    /// the listing was given a qualifier and the comment has an id.
    pub qualified_id: Option<String>,
    /// A comment's author; `None` when none is written.
    pub author: Option<String>,
    /// A comment's text, a question's text (options included), or a mark's
    /// text (the added, removed or highlighted text; a substitution's old
    /// text; empty for a comment mark).
    pub text: String,
    /// A comment's context: the paragraph before the block, verbatim (empty at
    /// the start of the value).
    pub context: String,
    /// A question's topic (in a combined block: the field it asks about).
    pub topic: Option<String>,
    /// Whether a question carries `★` before its topic.
    pub starred: bool,
    /// Whether a question is part of a combined block
    /// (`**❓ Open questions on these fields**`).
    pub combined: bool,
    /// A question's answer, trimmed; empty when open.
    pub answer: String,
    /// A mark's kind.
    pub mark_kind: Option<SpecMarkKind>,
    /// A substitution's new text.
    pub new_text: Option<String>,
    /// The comment of a comment mark, or of a highlight followed by one.
    pub comment: Option<String>,
}

impl SpecReviewAnnotation {
    fn base(kind: SpecReviewAnnotationKind, path: &str, field: Option<&str>, line: usize) -> Self {
        SpecReviewAnnotation {
            kind,
            path: path.to_string(),
            field: field.map(str::to_string),
            line,
            id: None,
            qualified_id: None,
            author: None,
            text: String::new(),
            context: String::new(),
            topic: None,
            starred: false,
            combined: false,
            answer: String::new(),
            mark_kind: None,
            new_text: None,
            comment: None,
        }
    }

    /// Whether a question is still open (no answer written).
    pub fn is_open(&self) -> bool {
        self.kind == SpecReviewAnnotationKind::Question && self.answer.is_empty()
    }

    /// The canonical JSON form the conformance corpus pins.
    pub fn to_json(&self) -> Json {
        fn s(v: &str) -> Json {
            Json::Str(v.to_string())
        }
        fn o(v: &Option<String>) -> Json {
            v.as_deref().map(s).unwrap_or(Json::Null)
        }
        let line = Json::Int(self.line as i64);
        let pairs: Vec<(&str, Json)> = match self.kind {
            SpecReviewAnnotationKind::Comment => vec![
                ("kind", s("comment")),
                ("path", s(&self.path)),
                ("field", o(&self.field)),
                ("line", line),
                ("id", o(&self.id)),
                ("qualifiedId", o(&self.qualified_id)),
                ("author", o(&self.author)),
                ("text", s(&self.text)),
                ("context", s(&self.context)),
            ],
            SpecReviewAnnotationKind::Question => vec![
                ("kind", s("question")),
                ("path", s(&self.path)),
                ("field", o(&self.field)),
                ("line", line),
                ("id", o(&self.id)),
                ("topic", o(&self.topic)),
                ("starred", Json::Bool(self.starred)),
                ("combined", Json::Bool(self.combined)),
                ("text", s(&self.text)),
                ("answer", s(&self.answer)),
                ("open", Json::Bool(self.is_open())),
            ],
            SpecReviewAnnotationKind::Mark => vec![
                ("kind", s("mark")),
                ("path", s(&self.path)),
                ("field", o(&self.field)),
                ("line", line),
                (
                    "markKind",
                    self.mark_kind.map(|k| s(k.name())).unwrap_or(Json::Null),
                ),
                ("text", s(&self.text)),
                ("newText", o(&self.new_text)),
                ("comment", o(&self.comment)),
            ],
        };
        Json::Object(pairs.into_iter().map(|(k, v)| (k.to_string(), v)).collect())
    }
}

/// The counts a report needs (SOM §11.9).
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct SpecReviewAnnotationCounts {
    /// Every question.
    pub questions: usize,
    /// Questions without an answer.
    pub open_questions: usize,
    /// Questions with an answer.
    pub answered_questions: usize,
    /// Comment blocks.
    pub comments: usize,
    /// Inline marks.
    pub marks: usize,
}

impl SpecReviewAnnotationCounts {
    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        let n = |v: usize| Json::Int(v as i64);
        Json::Object(vec![
            ("questions".to_string(), n(self.questions)),
            ("openQuestions".to_string(), n(self.open_questions)),
            ("answeredQuestions".to_string(), n(self.answered_questions)),
            ("comments".to_string(), n(self.comments)),
            ("marks".to_string(), n(self.marks)),
        ])
    }
}

/// A question to insert (SOM §11.9.2).
#[derive(Debug, Clone, Default, PartialEq)]
pub struct SpecQuestionDraft {
    /// The question id (`BQ-90`).
    pub id: String,
    /// The topic.
    pub topic: String,
    /// The question text; may span lines.
    pub text: String,
    /// Option lines, written as `- <option>` (e.g. `(a) lower only`).
    pub options: Vec<String>,
    /// The recommendation, or empty.
    pub recommendation: String,
    /// The working assumption, or empty.
    pub assumption: String,
    /// Whether the question carries `★`.
    pub starred: bool,
}

impl SpecQuestionDraft {
    /// A draft with id, topic and text; everything else empty.
    pub fn new(id: &str, topic: &str, text: &str) -> SpecQuestionDraft {
        SpecQuestionDraft {
            id: id.to_string(),
            topic: topic.to_string(),
            text: text.to_string(),
            ..SpecQuestionDraft::default()
        }
    }

    /// Reads a draft from its corpus JSON form.
    pub fn from_json(j: &Json) -> SpecQuestionDraft {
        let options = j
            .get("options")
            .and_then(|o| o.as_array())
            .map(|a| {
                a.iter()
                    .map(|o| match o {
                        Json::Str(s) => s.clone(),
                        Json::Int(n) => n.to_string(),
                        other => format!("{:?}", other),
                    })
                    .collect()
            })
            .unwrap_or_default();
        SpecQuestionDraft {
            id: j.str_or("id"),
            topic: j.str_or("topic"),
            text: j.str_or("text"),
            options,
            recommendation: j.str_or("recommendation"),
            assumption: j.str_or("assumption"),
            starred: j.bool_or("starred"),
        }
    }
}

/// Returned when an operation names an annotation, value or paragraph that
/// does not exist. Nothing has changed when it is returned.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecReviewAnnotationError {
    /// What went wrong.
    pub message: String,
}

impl SpecReviewAnnotationError {
    fn new(message: impl Into<String>) -> Self {
        SpecReviewAnnotationError {
            message: message.into(),
        }
    }
}

impl std::fmt::Display for SpecReviewAnnotationError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "SpecReviewAnnotationError: {}", self.message)
    }
}

impl std::error::Error for SpecReviewAnnotationError {}

/// What to do with one inline mark (SOM §11.9.3).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SpecMarkDecision {
    /// Take the change: an insertion's text, nothing for a deletion, a
    /// substitution's new text.
    Accept,
    /// Undo the change: nothing for an insertion, a deletion's text, a
    /// substitution's old text.
    Reject,
    /// Keep the mark as written.
    Leave,
}

impl SpecMarkDecision {
    /// Every decision, in declaration order.
    pub const ALL: [SpecMarkDecision; 3] = [
        SpecMarkDecision::Accept,
        SpecMarkDecision::Reject,
        SpecMarkDecision::Leave,
    ];

    /// The wire name (`accept`, `reject`, `leave`).
    pub fn name(self) -> &'static str {
        match self {
            SpecMarkDecision::Accept => "accept",
            SpecMarkDecision::Reject => "reject",
            SpecMarkDecision::Leave => "leave",
        }
    }

    /// The decision with wire name `name`, or `None`.
    pub fn from_name(name: &str) -> Option<SpecMarkDecision> {
        SpecMarkDecision::ALL.into_iter().find(|d| d.name() == name)
    }
}

fn json_obj(pairs: Vec<(&str, Json)>) -> Json {
    Json::Object(pairs.into_iter().map(|(k, v)| (k.to_string(), v)).collect())
}

fn json_str(v: &str) -> Json {
    Json::Str(v.to_string())
}

fn json_opt(v: &Option<String>) -> Json {
    v.as_deref().map(json_str).unwrap_or(Json::Null)
}

/// One inline mark as [`SpecReviewAnnotations::list_marks`] reports it.
#[derive(Debug, Clone, PartialEq)]
pub struct SpecMarkEntry {
    /// `M-<n>`: the mark's 1-based position among all marks of the document,
    /// in document order. Stable for one [`SpecReviewAnnotations::revision`].
    pub id: String,
    /// The value's path.
    pub path: String,
    /// The form field, or `None` for content.
    pub field: Option<String>,
    /// The 0-based line within the value where the mark opens.
    pub line: usize,
    /// The mark's kind.
    pub mark_kind: SpecMarkKind,
    /// The text after rejecting the mark.
    pub old_text: String,
    /// The text after accepting the mark.
    pub new_text: String,
    /// A comment mark's or a commented highlight's comment.
    pub comment: Option<String>,
    /// The mark as written.
    pub markup: String,
    /// The paragraph holding the mark, verbatim — for display.
    pub context: String,
}

impl SpecMarkEntry {
    /// The canonical JSON form the conformance corpus pins.
    pub fn to_json(&self) -> Json {
        json_obj(vec![
            ("id", json_str(&self.id)),
            ("path", json_str(&self.path)),
            ("field", json_opt(&self.field)),
            ("line", Json::Int(self.line as i64)),
            ("markKind", json_str(self.mark_kind.name())),
            ("oldText", json_str(&self.old_text)),
            ("newText", json_str(&self.new_text)),
            ("comment", json_opt(&self.comment)),
            ("markup", json_str(&self.markup)),
            ("context", json_str(&self.context)),
        ])
    }
}

/// What was done to one mark.
#[derive(Debug, Clone, PartialEq)]
pub struct SpecMarkOutcome {
    /// The mark's id at the revision the operation ran on.
    pub id: String,
    /// The value's path.
    pub path: String,
    /// The form field, or `None` for content.
    pub field: Option<String>,
    /// The 0-based line within the value where the mark opened.
    pub line: usize,
    /// The mark's kind.
    pub mark_kind: SpecMarkKind,
    /// Accepted or rejected.
    pub decision: SpecMarkDecision,
    /// The mark as written.
    pub markup: String,
    /// The text that replaced it.
    pub result: String,
}

impl SpecMarkOutcome {
    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        json_obj(vec![
            ("id", json_str(&self.id)),
            ("path", json_str(&self.path)),
            ("field", json_opt(&self.field)),
            ("line", Json::Int(self.line as i64)),
            ("markKind", json_str(self.mark_kind.name())),
            ("decision", json_str(self.decision.name())),
            ("markup", json_str(&self.markup)),
            ("result", json_str(&self.result)),
        ])
    }
}

/// A mark the scanner could not read; it is left as written.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecMarkIssue {
    /// The value's path.
    pub path: String,
    /// The form field, or `None` for content.
    pub field: Option<String>,
    /// The 0-based line within the value.
    pub line: usize,
    /// `unclosed`, `nested` or `noArrow`.
    pub issue: String,
}

impl SpecMarkIssue {
    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        json_obj(vec![
            ("path", json_str(&self.path)),
            ("field", json_opt(&self.field)),
            ("line", Json::Int(self.line as i64)),
            ("issue", json_str(&self.issue)),
        ])
    }
}

/// The report of a mark operation, for the decision log.
#[derive(Debug, Clone, Default, PartialEq)]
pub struct SpecMarkReport {
    /// What was done, in document order.
    pub applied: Vec<SpecMarkOutcome>,
    /// Malformed marks in scope, left as written.
    pub malformed: Vec<SpecMarkIssue>,
}

impl SpecMarkReport {
    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        json_obj(vec![
            (
                "applied",
                Json::Array(self.applied.iter().map(|a| a.to_json()).collect()),
            ),
            (
                "malformed",
                Json::Array(self.malformed.iter().map(|m| m.to_json()).collect()),
            ),
        ])
    }
}

// ---------------------------------------------------------------------------
// Text level: one value.
// ---------------------------------------------------------------------------

const ARROW: &str = "\u{2B06}";
const VS16: &str = "\u{FE0F}";
const QUESTION_OPEN: &str = "**\u{2753}";
const COMBINED_OPENER: &str = "**\u{2753} Open questions on these fields**";
const ANSWER_LABEL: &str = "**Answer:**";
const EM_DASH_SEP: &str = " \u{2014} ";
const STAR: &str = "\u{2605}";

/// One question region inside a question block.
#[derive(Debug, Clone)]
struct Question {
    header: usize,
    region_end: usize,
    answer_line: Option<usize>,
    id: String,
    topic: String,
    starred: bool,
    text: String,
    answer: String,
}

/// One parsed block of a value (lines [start, end] inclusive).
#[derive(Debug, Clone)]
struct Block {
    start: usize,
    end: usize,
    kind: SpecReviewAnnotationKind,
    /// A question block's questions, in header order.
    questions: Vec<Question>,
    /// Whether a question block is a combined block.
    combined: bool,
}

/// One parsed comment block.
#[derive(Debug, Clone)]
struct Comment {
    block_start: usize,
    block_end: usize,
    id: Option<String>,
    author: Option<String>,
    text: String,
    context: String,
    /// The first line up to where the text starts (kept by an edit).
    header_prefix: String,
    /// Where an id is inserted into the first line (a byte offset).
    marker_end: usize,
}

/// One parsed mark; `start`/`end` are byte offsets into the value.
#[derive(Debug, Clone)]
struct Mark {
    start: usize,
    end: usize,
    line: usize,
    kind: SpecMarkKind,
    text: String,
    new_text: Option<String>,
    comment: Option<String>,
}

/// Everything one value holds.
struct Parsed {
    lines: Vec<String>,
    code: Vec<bool>,
    blocks: Vec<Block>,
    comments: Vec<Comment>,
    marks: Vec<Mark>,
    malformed: Vec<String>,
    /// Malformed inline marks as (value line, issue code): `unclosed`,
    /// `nested`, `noArrow`.
    mark_issues: Vec<(usize, &'static str)>,
}

fn lstrip(s: &str) -> &str {
    s.trim_start_matches([' ', '\t'])
}

fn is_blank(s: &str) -> bool {
    s.trim().is_empty()
}

fn split_lines(value: &str) -> Vec<String> {
    value.split('\n').map(str::to_string).collect()
}

/// The fenced-code flag of every line.
fn code_lines(lines: &[String]) -> Vec<bool> {
    let mut code = vec![false; lines.len()];
    let mut fence: Option<u8> = None;
    let mut fence_len = 0;
    for (i, line) in lines.iter().enumerate() {
        let t = lstrip(line).as_bytes();
        match fence {
            None => {
                let c = t.first().copied().unwrap_or(0);
                if c == b'`' || c == b'~' {
                    let n = t.iter().take_while(|&&b| b == c).count();
                    if n >= 3 {
                        fence = Some(c);
                        fence_len = n;
                        code[i] = true;
                    }
                }
            }
            Some(fc) => {
                code[i] = true;
                let n = t.iter().take_while(|&&b| b == fc).count();
                let rest = &lstrip(line)[n..];
                if n >= fence_len && rest.trim().is_empty() {
                    fence = None;
                }
            }
        }
    }
    code
}

fn is_quote_line(line: &str) -> bool {
    lstrip(line).starts_with('>')
}

/// The line inside the quote: after `>` and one following space.
fn inner(line: &str) -> &str {
    let t = lstrip(line);
    let s = t.get(1..).unwrap_or("");
    s.strip_prefix(' ').unwrap_or(s)
}

fn parse(value: &str) -> Parsed {
    let lines = split_lines(value);
    let code = code_lines(&lines);
    let mut p = Parsed {
        lines,
        code,
        blocks: Vec::new(),
        comments: Vec::new(),
        marks: Vec::new(),
        malformed: Vec::new(),
        mark_issues: Vec::new(),
    };

    // Blocks.
    let n = p.lines.len();
    let mut i = 0;
    while i < n {
        if p.code[i] || !is_quote_line(&p.lines[i]) {
            i += 1;
            continue;
        }
        let s = i;
        while i + 1 < n && !p.code[i + 1] && is_quote_line(&p.lines[i + 1]) {
            i += 1;
        }
        let e = i;
        let first = inner(&p.lines[s]).to_string();
        if first.starts_with(ARROW) {
            p.blocks.push(Block {
                start: s,
                end: e,
                kind: SpecReviewAnnotationKind::Comment,
                questions: Vec::new(),
                combined: false,
            });
            let c = parse_comment(&mut p, s, e);
            p.comments.push(c);
        } else if first.starts_with(QUESTION_OPEN) {
            let (questions, combined) = parse_questions(&mut p, s, e);
            p.blocks.push(Block {
                start: s,
                end: e,
                kind: SpecReviewAnnotationKind::Question,
                questions,
                combined,
            });
        }
        i = e + 1;
    }

    parse_marks(&mut p);
    p
}

fn context_of(p: &Parsed, block_start: usize) -> String {
    let mut k = block_start as isize - 1;
    while k >= 0 && (is_blank(&p.lines[k as usize]) || is_quote_line(&p.lines[k as usize])) {
        k -= 1;
    }
    if k < 0 {
        return String::new();
    }
    let end = k as usize;
    let mut k = end;
    while k >= 1 && !is_blank(&p.lines[k - 1]) && !is_quote_line(&p.lines[k - 1]) {
        k -= 1;
    }
    p.lines[k..=end].join("\n")
}

fn is_comment_number(n: &str) -> bool {
    let b = n.as_bytes();
    !b.is_empty() && (b'1'..=b'9').contains(&b[0]) && b.iter().all(|c| c.is_ascii_digit())
}

fn parse_comment(p: &mut Parsed, start: usize, end: usize) -> Comment {
    let raw0 = p.lines[start].clone();
    let mut rest: &str = &inner(&raw0)[ARROW.len()..];
    if let Some(r) = rest.strip_prefix(VS16) {
        rest = r;
    }
    let marker_end = raw0.len() - rest.len();
    rest = lstrip(rest);
    let mut id = None;
    if rest.starts_with("**C-") {
        if let Some(rel) = rest[4..].find("**") {
            let close = 4 + rel;
            let n = &rest[4..close];
            if is_comment_number(n) {
                id = Some(format!("C-{}", n));
            } else {
                p.malformed.push(format!(
                    "line {}: comment id \"C-{}\" is not C-<number> (SOM §11.9.1)",
                    start, n
                ));
            }
            rest = lstrip(&rest[close + 2..]);
        }
    }
    let mut author = None;
    if rest.starts_with('(') {
        if let Some(close) = rest.find(')') {
            if close > 0 {
                author = Some(rest[1..close].to_string());
                rest = &rest[close + 1..];
                if let Some(r) = rest.strip_prefix(':') {
                    rest = r;
                }
                rest = lstrip(rest);
            }
        }
    } else if let Some(r) = rest.strip_prefix(':') {
        rest = lstrip(r);
    }
    let header_prefix = raw0[..raw0.len() - rest.len()].to_string();
    let mut text_lines: Vec<String> = vec![rest.to_string()];
    for k in start + 1..=end {
        let inn = inner(&p.lines[k]).to_string();
        let t = lstrip(&inn);
        if t.starts_with(QUESTION_OPEN) || t.starts_with(ANSWER_LABEL) {
            p.malformed.push(format!(
                "line {}: a comment block holds a question or an answer; the question \
                 goes into its own block after the comment (SOM §11.9.1)",
                k
            ));
        }
        text_lines.push(inn);
    }
    Comment {
        block_start: start,
        block_end: end,
        id,
        author,
        text: text_lines.join("\n").trim().to_string(),
        context: context_of(p, start),
        header_prefix,
        marker_end,
    }
}

struct Header {
    id: String,
    topic: String,
    starred: bool,
    rest: String,
}

fn is_question_id(id: &str) -> bool {
    let b = id.as_bytes();
    if b.is_empty() || !b[0].is_ascii_uppercase() {
        return false;
    }
    let Some(dash) = id.find('-') else {
        return false;
    };
    let (head, tail) = (&b[..dash], &b[dash + 1..]);
    head.iter()
        .all(|c| c.is_ascii_uppercase() || c.is_ascii_digit())
        && !tail.is_empty()
        && tail.iter().all(|c| c.is_ascii_digit())
}

/// Parses a question header's remainder after `**❓ `; `None` when malformed.
fn parse_header(inn: &str) -> Option<Header> {
    let h = &inn[QUESTION_OPEN.len() + 1..];
    let sep = h.find(EM_DASH_SEP)?;
    if sep == 0 {
        return None;
    }
    let id = &h[..sep];
    if !is_question_id(id) {
        return None;
    }
    let mut t = &h[sep + EM_DASH_SEP.len()..];
    let mut starred = false;
    let star_prefix = format!("{} ", STAR);
    if let Some(r) = t.strip_prefix(star_prefix.as_str()) {
        starred = true;
        t = r;
    }
    let close = t.find(":**")?;
    let topic = &t[..close];
    let rest = &t[close + 3..];
    let rest = rest.strip_prefix(' ').unwrap_or(rest);
    Some(Header {
        id: id.to_string(),
        topic: topic.to_string(),
        starred,
        rest: rest.to_string(),
    })
}

fn parse_questions(p: &mut Parsed, start: usize, end: usize) -> (Vec<Question>, bool) {
    let inn: Vec<String> = (start..=end).map(|k| inner(&p.lines[k]).to_string()).collect();
    let combined = inn[0].starts_with(COMBINED_OPENER);
    let header_prefix = format!("{} ", QUESTION_OPEN);
    let mut headers: Vec<(usize, Header)> = Vec::new();
    for (k, line) in inn.iter().enumerate() {
        if !line.starts_with(header_prefix.as_str()) || line.starts_with(COMBINED_OPENER) {
            continue;
        }
        match parse_header(line) {
            Some(h) => headers.push((k, h)),
            None => p.malformed.push(format!(
                "line {}: question header is not \"**\u{2753} <ID> \u{2014} <topic>:**\" \
                 (SOM §11.9.2)",
                start + k
            )),
        }
    }
    let mut list = Vec::new();
    for q in 0..headers.len() {
        let (k, h) = &headers[q];
        let k = *k;
        let region_end = if q + 1 < headers.len() {
            headers[q + 1].0 - 1
        } else {
            inn.len() - 1
        };
        let answer = (k + 1..=region_end).find(|&m| inn[m].starts_with(ANSWER_LABEL));
        let text_end = match answer {
            Some(a) => a - 1,
            None => region_end,
        };
        let mut parts: Vec<&str> = vec![h.rest.as_str()];
        parts.extend(inn[k + 1..=text_end].iter().map(String::as_str));
        let text = parts.join("\n").trim().to_string();
        let mut answer_text = String::new();
        if let Some(a) = answer {
            let mut parts: Vec<&str> = vec![&inn[a][ANSWER_LABEL.len()..]];
            parts.extend(inn[a + 1..=region_end].iter().map(String::as_str));
            answer_text = parts.join("\n").trim().to_string();
        }
        list.push(Question {
            header: start + k,
            region_end: start + region_end,
            answer_line: answer.map(|a| start + a),
            id: h.id.clone(),
            topic: h.topic.clone(),
            starred: h.starred,
            text,
            answer: answer_text,
        });
    }
    (list, combined)
}

const OPENERS: [&str; 5] = ["{>>", "{==", "{++", "{--", "{~~"];

fn closer_of(opener: &str) -> &'static str {
    match opener {
        "{>>" => "<<}",
        "{==" => "==}",
        "{++" => "++}",
        "{--" => "--}",
        _ => "~~}",
    }
}

fn has_opener(s: &str) -> bool {
    OPENERS.iter().any(|o| s.contains(o))
}

fn find_from(text: &str, pat: &str, from: usize) -> Option<usize> {
    if from > text.len() {
        return None;
    }
    text[from..].find(pat).map(|i| i + from)
}

/// The offset of the first blank line's start after `from` (the paragraph
/// end), or the text length.
fn paragraph_end(text: &str, from: usize) -> usize {
    let mut i = find_from(text, "\n", from);
    while let Some(at) = i {
        let next = find_from(text, "\n", at + 1);
        let line = &text[at + 1..next.unwrap_or(text.len())];
        if line.trim().is_empty() {
            return at;
        }
        i = next;
    }
    text.len()
}

fn parse_marks(p: &mut Parsed) {
    // Offsets of each line's start in the value.
    let mut line_start = Vec::with_capacity(p.lines.len());
    let mut off = 0;
    for l in &p.lines {
        line_start.push(off);
        off += l.len() + 1;
    }
    let value = p.lines.join("\n");
    let n = p.lines.len();
    let mut k = 0;
    while k < n {
        if p.code[k] {
            k += 1;
            continue;
        }
        // A run of non-code lines is scanned as one segment.
        let seg_start_line = k;
        while k < n && !p.code[k] {
            k += 1;
        }
        let seg_start = line_start[seg_start_line];
        let seg_end = line_start[k - 1] + p.lines[k - 1].len();
        let seg = value[seg_start..seg_end].to_string();
        scan_segment(p, &seg, seg_start, &line_start);
    }
}

fn line_of(line_start: &[usize], offset: usize) -> usize {
    let mut lo = 0;
    for (k, &s) in line_start.iter().enumerate() {
        if s <= offset {
            lo = k;
        }
    }
    lo
}

fn scan_segment(p: &mut Parsed, seg: &str, base: usize, line_start: &[usize]) {
    let b = seg.as_bytes();
    let mut i = 0;
    while i < b.len() {
        let c = b[i];
        if c == b'`' {
            let n = b[i..].iter().take_while(|&&x| x == b'`').count();
            // Find the next run of exactly n backticks.
            let mut j = i + n;
            let mut close_at = None;
            while j < b.len() {
                if b[j] == b'`' {
                    let m = b[j..].iter().take_while(|&&x| x == b'`').count();
                    if m == n {
                        close_at = Some(j);
                        break;
                    }
                    j += m;
                } else {
                    j += 1;
                }
            }
            i = match close_at {
                Some(at) => at + n,
                None => i + n,
            };
            continue;
        }
        if c != b'{' || i + 3 > b.len() {
            i += 1;
            continue;
        }
        let opener = &seg[i..i + 3];
        if !OPENERS.contains(&opener) {
            i += 1;
            continue;
        }
        let closer = closer_of(opener);
        let close = find_from(seg, closer, i + 3);
        let pend = paragraph_end(seg, i);
        let line = line_of(line_start, base + i);
        let close = match close {
            Some(cl) if cl <= pend => cl,
            _ => {
                p.malformed.push(format!(
                    "line {}: inline mark \"{}\" is not closed in its paragraph (SOM §11.9.3)",
                    line, opener
                ));
                p.mark_issues.push((line, "unclosed"));
                i += 3;
                continue;
            }
        };
        let inn = &seg[i + 3..close];
        if has_opener(inn) {
            p.malformed
                .push(format!("line {}: inline marks do not nest (SOM §11.9.3)", line));
            p.mark_issues.push((line, "nested"));
            i = close + 3;
            continue;
        }
        let mut end = close + 3;
        let mark = |kind, text: String, new_text, comment, end: usize| Mark {
            start: base + i,
            end: base + end,
            line,
            kind,
            text,
            new_text,
            comment,
        };
        match opener {
            "{>>" => {
                let m = mark(
                    SpecMarkKind::Comment,
                    String::new(),
                    None,
                    Some(inn.trim().to_string()),
                    end,
                );
                p.marks.push(m);
            }
            "{==" => {
                let mut comment = None;
                if seg[end..].starts_with("{>>") {
                    if let Some(c2) = find_from(seg, "<<}", end + 3) {
                        if c2 <= paragraph_end(seg, end) {
                            let ci = &seg[end + 3..c2];
                            if !has_opener(ci) {
                                comment = Some(ci.trim().to_string());
                                end = c2 + 3;
                            }
                        }
                    }
                }
                let m = mark(
                    SpecMarkKind::Highlight,
                    inn.trim().to_string(),
                    None,
                    comment,
                    end,
                );
                p.marks.push(m);
            }
            "{++" => {
                let m = mark(SpecMarkKind::Insertion, inn.trim().to_string(), None, None, end);
                p.marks.push(m);
            }
            "{--" => {
                let m = mark(SpecMarkKind::Deletion, inn.trim().to_string(), None, None, end);
                p.marks.push(m);
            }
            _ => {
                let Some(arrow) = inn.find("~>") else {
                    p.malformed.push(format!(
                        "line {}: a substitution has no \"~>\" (SOM §11.9.3)",
                        line
                    ));
                    p.mark_issues.push((line, "noArrow"));
                    i = end;
                    continue;
                };
                let m = mark(
                    SpecMarkKind::Substitution,
                    inn[..arrow].trim().to_string(),
                    Some(inn[arrow + 2..].trim().to_string()),
                    None,
                    end,
                );
                p.marks.push(m);
            }
        }
        i = end;
    }
}

/// The annotations of one value, in order: by line, blocks before marks, marks
/// in scan order.
fn annotations_of(
    p: &Parsed,
    path: &str,
    field: Option<&str>,
    qualifier: Option<&str>,
) -> Vec<SpecReviewAnnotation> {
    let mut out: Vec<(usize, u8, usize, SpecReviewAnnotation)> = Vec::new();
    let mut seq = 0;
    for b in &p.blocks {
        if b.kind == SpecReviewAnnotationKind::Comment {
            let c = p
                .comments
                .iter()
                .find(|c| c.block_start == b.start)
                .expect("comment of block");
            let mut a =
                SpecReviewAnnotation::base(SpecReviewAnnotationKind::Comment, path, field, b.start);
            a.id = c.id.clone();
            a.qualified_id = match (qualifier, &c.id) {
                (Some(q), Some(id)) => Some(format!("{} {}", q, id)),
                _ => None,
            };
            a.author = c.author.clone();
            a.text = c.text.clone();
            a.context = c.context.clone();
            out.push((b.start, 0, seq, a));
            seq += 1;
        } else {
            for q in &b.questions {
                let mut a = SpecReviewAnnotation::base(
                    SpecReviewAnnotationKind::Question,
                    path,
                    field,
                    q.header,
                );
                a.id = Some(q.id.clone());
                a.topic = Some(q.topic.clone());
                a.starred = q.starred;
                a.combined = b.combined;
                a.text = q.text.clone();
                a.answer = q.answer.clone();
                out.push((q.header, 0, seq, a));
                seq += 1;
            }
        }
    }
    for m in &p.marks {
        let mut a = SpecReviewAnnotation::base(SpecReviewAnnotationKind::Mark, path, field, m.line);
        a.mark_kind = Some(m.kind);
        a.text = m.text.clone();
        a.new_text = m.new_text.clone();
        a.comment = m.comment.clone();
        out.push((m.line, 1, seq, a));
        seq += 1;
    }
    out.sort_by_key(|e| (e.0, e.1, e.2));
    out.into_iter().map(|e| e.3).collect()
}

/// The paragraphs of a value as (first line, last line), blank-separated and
/// fence-aware (a blank line inside a fenced block does not split).
fn paragraphs(lines: &[String], code: &[bool]) -> Vec<(usize, usize)> {
    let mut out = Vec::new();
    let mut k = 0;
    while k < lines.len() {
        if is_blank(&lines[k]) && !code[k] {
            k += 1;
            continue;
        }
        let s = k;
        while k + 1 < lines.len() && (code[k + 1] || !is_blank(&lines[k + 1])) {
            k += 1;
        }
        out.push((s, k));
        k += 1;
    }
    out
}

/// Inserts `block` after value line `end` (`None`: at the start), one blank
/// line on each side.
fn insert_after_line(value: &str, end: Option<usize>, block: &[String]) -> String {
    if value.is_empty() {
        return block.join("\n");
    }
    let lines = split_lines(value);
    let cut = end.map(|e| e + 1).unwrap_or(0).min(lines.len());
    let (before, rest) = lines.split_at(cut);
    let mut out: Vec<String> = before.to_vec();
    if !before.is_empty() {
        out.push(String::new());
    }
    out.extend(block.iter().cloned());
    if !rest.is_empty() {
        if !is_blank(&rest[0]) {
            out.push(String::new());
        }
        out.extend(rest.iter().cloned());
    }
    out.join("\n")
}

/// Removes value lines [s, e] and one adjacent blank line.
fn remove_lines(value: &str, s: usize, e: usize) -> String {
    let mut lines = split_lines(value);
    let mut from = s;
    let mut to = e;
    if to + 1 < lines.len() && is_blank(&lines[to + 1]) {
        to += 1;
    } else if from >= 1 && is_blank(&lines[from - 1]) {
        from -= 1;
    }
    lines.drain(from..=to);
    let out = lines.join("\n");
    if out.trim().is_empty() {
        String::new()
    } else {
        out
    }
}

fn quoted(lines: &[&str]) -> Vec<String> {
    lines
        .iter()
        .map(|l| {
            if l.is_empty() {
                ">".to_string()
            } else {
                format!("> {}", l)
            }
        })
        .collect()
}

/// The lines of a comment block: `> ⬆️ **ID** (author): first line`, further
/// lines quoted.
pub fn format_comment_block(id: &str, text: &str, author: Option<&str>) -> Vec<String> {
    let t: Vec<&str> = text.split('\n').collect();
    let mut head = format!("> {}{} **{}**", ARROW, VS16, id);
    if let Some(a) = author {
        if !a.is_empty() {
            head.push_str(&format!(" ({}):", a));
        }
    }
    if !t[0].is_empty() {
        head.push(' ');
        head.push_str(t[0]);
    }
    let mut out = vec![head];
    out.extend(quoted(&t[1..]));
    out
}

/// The lines of a question block.
pub fn format_question_block(q: &SpecQuestionDraft) -> Vec<String> {
    let t: Vec<&str> = q.text.split('\n').collect();
    let star = if q.starred {
        format!("{} ", STAR)
    } else {
        String::new()
    };
    let mut lines = vec![format!(
        "> {} {}{}{}{}:** {}",
        QUESTION_OPEN, q.id, EM_DASH_SEP, star, q.topic, t[0]
    )];
    lines.extend(quoted(&t[1..]));
    for o in &q.options {
        lines.push(format!("> - {}", o));
    }
    if !q.recommendation.is_empty() || !q.assumption.is_empty() {
        lines.push(">".to_string());
        if !q.recommendation.is_empty() {
            lines.push(format!("> *Recommendation:* {}", q.recommendation));
        }
        if !q.assumption.is_empty() {
            lines.push(format!(
                "> *Working assumption until answered:* {}",
                q.assumption
            ));
        }
    }
    lines.push(">".to_string());
    lines.push(format!("> {}", ANSWER_LABEL));
    lines
}

/// Letters (lowercase ≠ uppercase, any script) and ASCII digits.
fn is_word_char(c: char) -> bool {
    c.is_ascii_digit() || c.to_lowercase().ne(c.to_uppercase())
}

/// Applies a mark's replacement with the whitespace rules of SOM §11.9.3:
/// never join two words, never leave a double space or a space before
/// punctuation, and a mark that was a whole line leaves no blank line.
fn replace_mark(value: &str, m: &Mark, replacement: &str) -> String {
    let mut replacement = replacement.to_string();
    let mut before = &value[..m.start];
    let mut after = &value[m.end..];
    let is_space = |c: char| c == ' ' || c == '\t';
    fn trim_end_spaces(s: &str) -> &str {
        s.trim_end_matches([' ', '\t'])
    }
    fn trim_start_spaces(s: &str) -> &str {
        s.trim_start_matches([' ', '\t'])
    }
    if replacement.is_empty() {
        let tb = trim_end_spaces(before);
        let ta = trim_start_spaces(after);
        let line_start = tb.is_empty() || tb.ends_with('\n');
        let line_end = ta.is_empty() || ta.starts_with('\n');
        if line_start && line_end {
            // The mark was the whole line: the line goes, and with it one of
            // the newlines around it; a blank line left doubled is merged.
            before = tb;
            after = ta;
            if let Some(rest) = after.strip_prefix('\n') {
                after = rest;
            } else if let Some(rest) = before.strip_suffix('\n') {
                before = rest;
            }
            if (before.is_empty() || before.ends_with("\n\n")) && after.starts_with('\n') {
                after = &after[1..];
            }
            if after.is_empty() {
                before = before.trim_end_matches('\n');
            }
            return format!("{}{}", before, after);
        }
        if before.chars().next_back().is_some_and(is_space) {
            if after.chars().next().is_some_and(is_space) {
                after = trim_start_spaces(after);
            } else if after.is_empty()
                || after.starts_with('\n')
                || after
                    .chars()
                    .next()
                    .is_some_and(|c| ".,;:!?)]}".contains(c))
            {
                before = trim_end_spaces(before);
            }
        } else if (before.is_empty() || before.ends_with('\n'))
            && after.chars().next().is_some_and(is_space)
        {
            after = trim_start_spaces(after);
        }
        return format!("{}{}", before, after);
    }
    // Never join two words: a mark written flush against a word keeps a space
    // on that side.
    let before_word = before.chars().next_back().is_some_and(is_word_char);
    if before_word && replacement.chars().next().is_some_and(is_word_char) {
        replacement.insert(0, ' ');
    }
    if replacement.chars().next_back().is_some_and(is_word_char)
        && after.chars().next().is_some_and(is_word_char)
    {
        replacement.push(' ');
    }
    format!("{}{}{}", before, replacement, after)
}

fn mark_replacement(m: &Mark, accept: bool) -> String {
    match m.kind {
        SpecMarkKind::Insertion => {
            if accept {
                m.text.clone()
            } else {
                String::new()
            }
        }
        SpecMarkKind::Deletion => {
            if accept {
                String::new()
            } else {
                m.text.clone()
            }
        }
        SpecMarkKind::Substitution => {
            if accept {
                m.new_text.clone().unwrap_or_default()
            } else {
                m.text.clone()
            }
        }
        SpecMarkKind::Highlight => m.text.clone(),
        SpecMarkKind::Comment => String::new(),
    }
}

/// `value` with every inline mark accepted (`accept`) or rejected, and every
/// highlight and comment mark removed, by the rules of SOM §11.9.3. Marks in
/// code and malformed marks stay as written.
pub fn apply_inline_marks_text(value: &str, accept: bool) -> String {
    let mut v = value.to_string();
    let marks = parse(&v).marks;
    for m in marks.iter().rev() {
        v = replace_mark(&v, m, &mark_replacement(m, accept));
    }
    v
}

/// `value` without any comment block, question block or inline mark (every
/// mark accepted). Plain quotes and code stay.
pub fn strip_annotations_text(value: &str) -> String {
    let mut v = value.to_string();
    // Blocks, from the last up, so earlier line numbers stay valid.
    loop {
        let p = parse(&v);
        let Some(b) = p.blocks.last() else { break };
        v = remove_lines(&v, b.start, b.end);
    }
    loop {
        let p = parse(&v);
        let Some(m) = p.marks.last() else { break };
        v = replace_mark(&v, m, &mark_replacement(m, true));
    }
    v
}

// ---------------------------------------------------------------------------
// Document level.
// ---------------------------------------------------------------------------

/// Every value as (path, field, text), in document order.
fn values_of(doc: &SpecDocument) -> Vec<(String, Option<String>, String)> {
    let mut out = Vec::new();
    // Both lists come back sorted (byte order) from the document's maps.
    for path in doc.content_paths() {
        let text = doc.content(&path).cloned().unwrap_or_default();
        out.push((path, None, text));
    }
    for path in doc.form_paths() {
        for f in doc.form_field_names(&path) {
            let text = doc.form_field(&path, &f).cloned().unwrap_or_default();
            out.push((path.clone(), Some(f), text));
        }
    }
    out
}

fn list_of(doc: &SpecDocument, qualifier: Option<&str>) -> Vec<SpecReviewAnnotation> {
    values_of(doc)
        .iter()
        .flat_map(|(path, field, text)| annotations_of(&parse(text), path, field.as_deref(), qualifier))
        .collect()
}

/// The instance-tier findings on annotations (SOM §11.9.5) of `doc`, ordered
/// by path. The read-only form of [`SpecReviewAnnotations::validate`];
/// [`validate_document`](crate::validate_document) reports them as its last
/// group.
pub fn validate_review_annotations(doc: &SpecDocument) -> Vec<SpecValidationError> {
    let mut errors = Vec::new();
    let mut seen: HashSet<String> = HashSet::new();
    for (path, field, text) in values_of(doc) {
        let p = parse(&text);
        let at = match &field {
            None => path.clone(),
            Some(f) => format!("{} / {}", path, f),
        };
        for m in &p.malformed {
            errors.push(SpecValidationError {
                path: path.clone(),
                code: SPEC_VALIDATION_CODE_ANNOTATION_MALFORMED.to_string(),
                message: format!("{}, {}", at, m),
            });
        }
        if field.is_some() {
            for b in &p.blocks {
                errors.push(SpecValidationError {
                    path: path.clone(),
                    code: SPEC_VALIDATION_CODE_ANNOTATION_MISPLACED.to_string(),
                    message: format!(
                        "{}, line {}: a {} block sits in a form field value; it belongs in \
                         the form's preamble, above the first field (SOM §11.9.4)",
                        at,
                        b.start,
                        b.kind.name()
                    ),
                });
            }
        }
        let ids: Vec<String> = p
            .comments
            .iter()
            .filter_map(|c| c.id.clone())
            .chain(
                p.blocks
                    .iter()
                    .flat_map(|b| b.questions.iter().map(|q| q.id.clone())),
            )
            .collect();
        for id in ids {
            if !seen.insert(id.clone()) {
                errors.push(SpecValidationError {
                    path: path.clone(),
                    code: SPEC_VALIDATION_CODE_DUPLICATE_ANNOTATION_ID.to_string(),
                    message: format!("{}: {} is used more than once in the document", at, id),
                });
            }
        }
    }
    // `sort_by` is stable: equal paths keep their discovery order.
    errors.sort_by(|a, b| a.path.cmp(&b.path));
    errors
}

/// The annotations of a document, and the operations that edit them
/// (SOM §11.9). Values are visited in a fixed order — content paths sorted,
/// then form paths sorted with their field names sorted — so "document order"
/// is the same in every runtime.
pub struct SpecReviewAnnotations<'a> {
    doc: &'a mut SpecDocument,
    /// The document's id or name, written in front of a comment id cited
    /// outside the document (`SBP` → `SBP C-12`); `None` for bare ids.
    pub qualifier: Option<String>,
}

type FoundQuestion = (String, Option<String>, String, Block, Question);
type FoundComment = (String, Option<String>, String, Comment);

impl<'a> SpecReviewAnnotations<'a> {
    /// Wraps `doc`, with bare comment ids.
    pub fn new(doc: &'a mut SpecDocument) -> SpecReviewAnnotations<'a> {
        SpecReviewAnnotations {
            doc,
            qualifier: None,
        }
    }

    /// Wraps `doc`, qualifying comment ids with `qualifier` (`None`: bare).
    pub fn with_qualifier(
        doc: &'a mut SpecDocument,
        qualifier: Option<&str>,
    ) -> SpecReviewAnnotations<'a> {
        SpecReviewAnnotations {
            doc,
            qualifier: qualifier.map(str::to_string),
        }
    }

    /// The document.
    pub fn doc(&self) -> &SpecDocument {
        self.doc
    }

    fn get(&self, path: &str, field: Option<&str>) -> String {
        match field {
            None => self.doc.content(path),
            Some(f) => self.doc.form_field(path, f),
        }
        .cloned()
        .unwrap_or_default()
    }

    fn set(&mut self, path: &str, field: Option<&str>, value: &str) {
        match field {
            None => self.doc.set_content(path, value),
            Some(f) => self.doc.set_form_field(path, f, value),
        }
    }

    /// Every annotation, in document order.
    pub fn list(&self) -> Vec<SpecReviewAnnotation> {
        list_of(self.doc, self.qualifier.as_deref())
    }

    /// The counts a report needs.
    pub fn counts(&self) -> SpecReviewAnnotationCounts {
        let mut out = SpecReviewAnnotationCounts::default();
        for a in self.list() {
            match a.kind {
                SpecReviewAnnotationKind::Question => {
                    out.questions += 1;
                    if a.is_open() {
                        out.open_questions += 1;
                    }
                }
                SpecReviewAnnotationKind::Comment => out.comments += 1,
                SpecReviewAnnotationKind::Mark => out.marks += 1,
            }
        }
        out.answered_questions = out.questions - out.open_questions;
        out
    }

    fn highest_comment_number(&self) -> u64 {
        self.list()
            .iter()
            .filter(|a| a.kind == SpecReviewAnnotationKind::Comment)
            .filter_map(|a| a.id.as_ref().and_then(|id| id[2..].parse::<u64>().ok()))
            .max()
            .unwrap_or(0)
    }

    /// The id the next comment gets: `C-<n>`, n = the highest number in the
    /// document (or `floor`, when higher) plus one. Writes nothing.
    pub fn next_comment_id(&self, floor: u64) -> String {
        format!("C-{}", self.highest_comment_number().max(floor) + 1)
    }

    /// Gives every comment without an id the next one, in document order, and
    /// returns the ids assigned. Nothing else changes.
    pub fn assign_comment_ids(&mut self, floor: u64) -> Vec<String> {
        let mut next = self.highest_comment_number().max(floor) + 1;
        let mut assigned = Vec::new();
        for (path, field, text) in values_of(self.doc) {
            let p = parse(&text);
            let bare: Vec<&Comment> = p.comments.iter().filter(|c| c.id.is_none()).collect();
            if bare.is_empty() {
                continue;
            }
            let mut lines = split_lines(&text);
            for c in bare {
                let id = format!("C-{}", next);
                next += 1;
                let raw = lines[c.block_start].clone();
                let at = c.marker_end;
                lines[c.block_start] = if at < raw.len() && raw.as_bytes()[at] == b' ' {
                    format!("{}**{}** {}", &raw[..at + 1], id, &raw[at + 1..])
                } else if at >= raw.len() {
                    format!("{} **{}**", raw, id)
                } else {
                    format!("{} **{}** {}", &raw[..at], id, &raw[at..])
                };
                assigned.push(id);
            }
            self.set(&path, field.as_deref(), &lines.join("\n"));
        }
        assigned
    }

    /// Inserts a comment block after paragraph `after_paragraph` (0-based;
    /// negative: at the start) of the value at `path` / `field`, and returns
    /// its id — `id` when given, else the next free one.
    pub fn insert_comment(
        &mut self,
        path: &str,
        field: Option<&str>,
        after_paragraph: i64,
        text: &str,
        author: Option<&str>,
        id: Option<&str>,
    ) -> Result<String, SpecReviewAnnotationError> {
        let cid = match id {
            Some(i) => i.to_string(),
            None => self.next_comment_id(0),
        };
        let value = self.get(path, field);
        let end = paragraph_last_line(&value, after_paragraph)?;
        let block = format_comment_block(&cid, text, author);
        self.set(path, field, &insert_after_line(&value, end, &block));
        Ok(cid)
    }

    /// Inserts a question block after paragraph `after_paragraph` (0-based;
    /// negative: at the start) of the value at `path` / `field`.
    pub fn insert_question(
        &mut self,
        path: &str,
        field: Option<&str>,
        after_paragraph: i64,
        question: &SpecQuestionDraft,
    ) -> Result<(), SpecReviewAnnotationError> {
        let value = self.get(path, field);
        let end = paragraph_last_line(&value, after_paragraph)?;
        let block = format_question_block(question);
        self.set(path, field, &insert_after_line(&value, end, &block));
        Ok(())
    }

    /// Inserts a question block directly after the comment `comment_id`.
    pub fn insert_question_after_comment(
        &mut self,
        comment_id: &str,
        question: &SpecQuestionDraft,
    ) -> Result<(), SpecReviewAnnotationError> {
        let (path, field, text, c) = self.find_comment(comment_id)?;
        let block = format_question_block(question);
        self.set(
            &path,
            field.as_deref(),
            &insert_after_line(&text, Some(c.block_end), &block),
        );
        Ok(())
    }

    /// Writes `answer` after the question's `**Answer:**` (empty: reopens it).
    pub fn set_answer(
        &mut self,
        question_id: &str,
        answer: &str,
    ) -> Result<(), SpecReviewAnnotationError> {
        let (path, field, text, _b, q) = self.find_question(question_id)?;
        let mut lines = split_lines(&text);
        let a: Vec<&str> = answer.split('\n').collect();
        let mut written = vec![if answer.is_empty() {
            format!("> {}", ANSWER_LABEL)
        } else {
            format!("> {} {}", ANSWER_LABEL, a[0])
        }];
        if !answer.is_empty() {
            written.extend(quoted(&a[1..]));
        }
        // The answer runs to the region's last non-empty line.
        let mut last = q.region_end;
        while last > q.header && inner(&lines[last]).trim().is_empty() {
            last -= 1;
        }
        match q.answer_line {
            Some(from) => {
                let to = last.max(from);
                lines.splice(from..=to, written);
            }
            None => {
                let mut ins = vec![">".to_string()];
                ins.extend(written);
                lines.splice(last + 1..last + 1, ins);
            }
        }
        self.set(&path, field.as_deref(), &lines.join("\n"));
        Ok(())
    }

    /// Replaces a comment's text; its marker, id and author stay as written.
    pub fn edit_comment(
        &mut self,
        comment_id: &str,
        text: &str,
    ) -> Result<(), SpecReviewAnnotationError> {
        let (path, field, value, c) = self.find_comment(comment_id)?;
        let mut lines = split_lines(&value);
        let t: Vec<&str> = text.split('\n').collect();
        let mut block = vec![format!("{}{}", c.header_prefix, t[0]).trim_end().to_string()];
        block.extend(quoted(&t[1..]));
        lines.splice(c.block_start..=c.block_end, block);
        self.set(&path, field.as_deref(), &lines.join("\n"));
        Ok(())
    }

    /// Removes one comment or question by id (a qualified comment id,
    /// `SBP C-12`, is accepted). A question of a combined block takes only its
    /// own lines; the block goes when its last question does.
    pub fn resolve(&mut self, id: &str) -> Result<(), SpecReviewAnnotationError> {
        let bare = id.rsplit(' ').next().unwrap_or(id);
        if bare.starts_with("C-") {
            let (path, field, value, c) = self.find_comment(bare)?;
            self.set(
                &path,
                field.as_deref(),
                &remove_lines(&value, c.block_start, c.block_end),
            );
            return Ok(());
        }
        let (path, field, value, b, q) = self.find_question(bare)?;
        if b.questions.len() == 1 {
            self.set(&path, field.as_deref(), &remove_lines(&value, b.start, b.end));
            return Ok(());
        }
        let mut lines = split_lines(&value);
        lines.drain(q.header..=q.region_end);
        // A last question leaves the separator `>` lines of the one before it.
        let mut end = b.end - (q.region_end - q.header + 1);
        while end > b.start && inner(&lines[end]).trim().is_empty() {
            lines.remove(end);
            end -= 1;
        }
        self.set(&path, field.as_deref(), &lines.join("\n"));
        Ok(())
    }

    /// Accepts (`accept`) or rejects the inline mark `index` (0-based among
    /// the marks of the value at `path` / `field`).
    pub fn apply_mark(
        &mut self,
        path: &str,
        field: Option<&str>,
        index: usize,
        accept: bool,
    ) -> Result<(), SpecReviewAnnotationError> {
        let value = self.get(path, field);
        let marks = parse(&value).marks;
        let Some(m) = marks.get(index) else {
            return Err(SpecReviewAnnotationError::new(format!(
                "no inline mark {} at {}{}",
                index,
                path,
                field.map(|f| format!(" / {}", f)).unwrap_or_default()
            )));
        };
        let out = replace_mark(&value, m, &mark_replacement(m, accept));
        self.set(path, field, &out);
        Ok(())
    }

    /// A copy of the document without any annotation, for reading. The
    /// document itself is unchanged.
    pub fn stripped(&self) -> SpecDocument {
        let mut copy = SpecDocument::new();
        copy.load_json(&self.doc.to_json());
        for (path, field, text) in values_of(self.doc) {
            let clean = strip_annotations_text(&text);
            if clean == text {
                continue;
            }
            match &field {
                None => copy.set_content(&path, &clean),
                Some(f) => copy.set_form_field(&path, f, &clean),
            }
        }
        copy
    }

    /// The instance-tier findings on annotations (SOM §11.9.5), ordered by
    /// path.
    pub fn validate(&self) -> Vec<SpecValidationError> {
        validate_review_annotations(self.doc)
    }

    fn find_comment(&self, id: &str) -> Result<FoundComment, SpecReviewAnnotationError> {
        for (path, field, text) in values_of(self.doc) {
            let p = parse(&text);
            if let Some(c) = p.comments.into_iter().find(|c| c.id.as_deref() == Some(id)) {
                return Ok((path, field, text, c));
            }
        }
        Err(SpecReviewAnnotationError::new(format!(
            "no comment {} in the document",
            id
        )))
    }

    fn find_question(&self, id: &str) -> Result<FoundQuestion, SpecReviewAnnotationError> {
        for (path, field, text) in values_of(self.doc) {
            let p = parse(&text);
            for b in &p.blocks {
                if let Some(q) = b.questions.iter().find(|q| q.id == id) {
                    let q = q.clone();
                    return Ok((path, field, text, b.clone(), q));
                }
            }
        }
        Err(SpecReviewAnnotationError::new(format!(
            "no question {} in the document",
            id
        )))
    }
}

/// The last line of paragraph `after_paragraph`; `None` for a negative index
/// (the start of the value).
fn paragraph_last_line(
    value: &str,
    after_paragraph: i64,
) -> Result<Option<usize>, SpecReviewAnnotationError> {
    if after_paragraph < 0 {
        return Ok(None);
    }
    let lines = split_lines(value);
    let paras = paragraphs(&lines, &code_lines(&lines));
    if value.is_empty() || after_paragraph as usize >= paras.len() {
        return Err(SpecReviewAnnotationError::new(format!(
            "the value has {} paragraph(s); there is no paragraph {}",
            if value.is_empty() { 0 } else { paras.len() },
            after_paragraph
        )));
    }
    Ok(Some(paras[after_paragraph as usize].1))
}

// ---------------------------------------------------------------------------
// Reviewing inline marks (SOM §11.9.3).
// ---------------------------------------------------------------------------

fn is_under(path: &str, under: Option<&str>) -> bool {
    match under {
        None => true,
        Some(u) => path == u || (path.starts_with(u) && path[u.len()..].starts_with('/')),
    }
}

impl<'a> SpecReviewAnnotations<'a> {
    /// The revision the mark ids are stable for: FNV-1a 64-bit over the UTF-8
    /// of every value in document order (path, NUL, field or empty, NUL, text,
    /// NUL), as 16 lower-case hex digits. Any change to a value changes it.
    pub fn revision(&self) -> String {
        const PRIME: u64 = 0x100000001b3;
        let mut h: u64 = 0xcbf29ce484222325;
        let mut add = |s: &str| {
            for &b in s.as_bytes() {
                h = (h ^ b as u64).wrapping_mul(PRIME);
            }
            h = h.wrapping_mul(PRIME); // the NUL byte: h ^ 0 == h
        };
        for (path, field, text) in values_of(self.doc) {
            add(&path);
            add(field.as_deref().unwrap_or(""));
            add(&text);
        }
        format!("{:016x}", h)
    }

    /// Every inline mark of the document, or of the subtree at `path`, in
    /// document order.
    pub fn list_marks(&self, path: Option<&str>) -> Vec<SpecMarkEntry> {
        let mut out = Vec::new();
        let mut n = 0;
        for (vpath, field, text) in values_of(self.doc) {
            let p = parse(&text);
            let paras = paragraphs(&p.lines, &p.code);
            for m in &p.marks {
                n += 1;
                let id = format!("M-{}", n);
                if !is_under(&vpath, path) {
                    continue;
                }
                let (s, e) = paras
                    .iter()
                    .copied()
                    .find(|&(s, e)| s <= m.line && m.line <= e)
                    .unwrap_or((m.line, m.line));
                out.push(SpecMarkEntry {
                    id,
                    path: vpath.clone(),
                    field: field.clone(),
                    line: m.line,
                    mark_kind: m.kind,
                    old_text: mark_replacement(m, false),
                    new_text: mark_replacement(m, true),
                    comment: m.comment.clone(),
                    markup: text[m.start..m.end].to_string(),
                    context: p.lines[s..=e].join("\n"),
                });
            }
        }
        out
    }

    /// Applies `decide` to every mark in the subtree `under` (`None`: the
    /// whole document), one write per value.
    fn apply_marks(
        &mut self,
        decide: impl Fn(&str) -> Option<SpecMarkDecision>,
        under: Option<&str>,
    ) -> SpecMarkReport {
        let mut report = SpecMarkReport::default();
        let mut n = 0;
        for (path, field, text) in values_of(self.doc) {
            let p = parse(&text);
            let ids: Vec<String> = p
                .marks
                .iter()
                .map(|_| {
                    n += 1;
                    format!("M-{}", n)
                })
                .collect();
            if !is_under(&path, under) {
                continue;
            }
            for &(line, issue) in &p.mark_issues {
                report.malformed.push(SpecMarkIssue {
                    path: path.clone(),
                    field: field.clone(),
                    line,
                    issue: issue.to_string(),
                });
            }
            let mut v = text.clone();
            let mut outcomes = Vec::new();
            for (k, m) in p.marks.iter().enumerate().rev() {
                let d = match decide(&ids[k]) {
                    None | Some(SpecMarkDecision::Leave) => continue,
                    Some(d) => d,
                };
                let repl = mark_replacement(m, d == SpecMarkDecision::Accept);
                outcomes.insert(
                    0,
                    SpecMarkOutcome {
                        id: ids[k].clone(),
                        path: path.clone(),
                        field: field.clone(),
                        line: m.line,
                        mark_kind: m.kind,
                        decision: d,
                        markup: text[m.start..m.end].to_string(),
                        result: repl.clone(),
                    },
                );
                v = replace_mark(&v, m, &repl);
            }
            if v != text {
                self.set(&path, field.as_deref(), &v);
            }
            report.applied.extend(outcomes);
        }
        report
    }

    /// Applies one decision per named mark in one write. Refused — nothing
    /// changes — when the document is no longer at `revision`, or when a
    /// decision names a mark that does not exist. Marks not named, and marks
    /// decided [`SpecMarkDecision::Leave`], stay.
    pub fn decide_marks(
        &mut self,
        decisions: &HashMap<String, SpecMarkDecision>,
        revision: &str,
    ) -> Result<SpecMarkReport, SpecReviewAnnotationError> {
        let current = self.revision();
        if revision != current {
            return Err(SpecReviewAnnotationError::new(format!(
                "the document changed since revision {} (now {}); list the marks again",
                revision, current
            )));
        }
        let known: HashSet<String> = self.list_marks(None).into_iter().map(|m| m.id).collect();
        for id in decisions.keys() {
            if !known.contains(id) {
                return Err(SpecReviewAnnotationError::new(format!(
                    "no inline mark {} in the document",
                    id
                )));
            }
        }
        Ok(self.apply_marks(|id| decisions.get(id).copied(), None))
    }

    /// Accepts every inline mark under `path` (`None`: the whole document).
    pub fn accept_all_marks(&mut self, path: Option<&str>) -> SpecMarkReport {
        self.apply_marks(|_| Some(SpecMarkDecision::Accept), path)
    }

    /// Rejects every inline mark under `path` (`None`: the whole document).
    pub fn reject_all_marks(&mut self, path: Option<&str>) -> SpecMarkReport {
        self.apply_marks(|_| Some(SpecMarkDecision::Reject), path)
    }

    /// Removes every annotation and writes the result back: every inline mark
    /// accepted, every comment and question block removed. Malformed marks
    /// stay and are reported.
    pub fn remove_all_annotations(&mut self) -> SpecMarkReport {
        let report = self.accept_all_marks(None);
        for (path, field, text) in values_of(self.doc) {
            let mut v = text.clone();
            loop {
                let p = parse(&v);
                let Some(b) = p.blocks.last() else { break };
                v = remove_lines(&v, b.start, b.end);
            }
            if v != text {
                self.set(&path, field.as_deref(), &v);
            }
        }
        report
    }
}
