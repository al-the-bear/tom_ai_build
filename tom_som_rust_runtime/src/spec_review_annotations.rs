//! `spec_review_annotations` — review annotations in content values (SOM
//! §11.9): comment blocks, question blocks and CriticMarkup inline marks, and
//! the team-review notation of §11.9.8 on top of them (attribution tokens,
//! individual answers, conflict blocks, `open:` answers). A port of the Dart
//! reference `spec_review_annotations.dart`; the team-review parts follow the
//! TypeScript runtime, which implements them first.
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

/// The kinds of annotation (SOM §11.9): the three of §11.9.1–11.9.3 and the
/// conflict block a team review adds (§11.9.8).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SpecReviewAnnotationKind {
    /// A reviewer's comment block, `> ⬆️ **C-12** (Alexis): …`.
    Comment,
    /// One question of a question block, `> **❓ BQ-81 — topic:** …`.
    Question,
    /// A CriticMarkup inline mark.
    Mark,
    /// A conflict block, `> ⚖️ **X-3 — Conflicting changes:** …` (SOM §11.9.8).
    Conflict,
}

impl SpecReviewAnnotationKind {
    /// Every kind, in declaration order.
    pub const ALL: [SpecReviewAnnotationKind; 4] = [
        SpecReviewAnnotationKind::Comment,
        SpecReviewAnnotationKind::Question,
        SpecReviewAnnotationKind::Mark,
        SpecReviewAnnotationKind::Conflict,
    ];

    /// The wire name (`comment`, `question`, `mark`, `conflict`).
    pub fn name(self) -> &'static str {
        match self {
            SpecReviewAnnotationKind::Comment => "comment",
            SpecReviewAnnotationKind::Question => "question",
            SpecReviewAnnotationKind::Mark => "mark",
            SpecReviewAnnotationKind::Conflict => "conflict",
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
    /// A question's options, in order (empty when it states none).
    pub options: Vec<SpecQuestionOption>,
    /// A question's recommended letter: the bold option, else the option that
    /// says "recommended", else the letter of a `*Recommendation:*` line.
    pub recommended: Option<String>,
    /// A mark's kind.
    pub mark_kind: Option<SpecMarkKind>,
    /// A substitution's new text.
    pub new_text: Option<String>,
    /// The comment of a comment mark, or of a highlight followed by one.
    pub comment: Option<String>,
    /// A mark's authors from its attribution token (SOM §11.9.8); empty
    /// without one.
    pub authors: Vec<String>,
    /// A mark's votes from its attribution token; empty without one.
    pub votes: Vec<SpecMarkVote>,
    /// A question's individual answers, in the order written.
    pub answers: Vec<SpecIndividualAnswer>,
    /// A conflict's `(base)` text.
    pub base: String,
    /// A conflict's lettered alternatives.
    pub alternatives: Vec<SpecConflictAlternative>,
    /// When a comment or mark was last changed (SOM §11.9.10); `None`
    /// without a time.
    pub changed_at: Option<String>,
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
            options: Vec::new(),
            recommended: None,
            mark_kind: None,
            new_text: None,
            comment: None,
            authors: Vec::new(),
            votes: Vec::new(),
            answers: Vec::new(),
            base: String::new(),
            alternatives: Vec::new(),
            changed_at: None,
        }
    }

    /// Whether a question is still open (no team answer written), or a
    /// conflict (no decision written). For a conflict, `answer` holds the
    /// decision.
    pub fn is_open(&self) -> bool {
        matches!(
            self.kind,
            SpecReviewAnnotationKind::Question | SpecReviewAnnotationKind::Conflict
        ) && self.answer.is_empty()
    }

    /// Whether a question's team answer or a conflict's decision begins with
    /// `open:` — answered for a gate, but handed back (SOM §11.9.8).
    pub fn is_unresolved(&self) -> bool {
        is_unresolved(&self.answer)
    }

    /// The letter a question's team answer starts with (`(b)` or `**(b)**`),
    /// or `None` (always `None` for an unresolved answer, a comment, a mark
    /// or a conflict).
    pub fn answer_letter(&self) -> Option<String> {
        if self.kind != SpecReviewAnnotationKind::Question || self.is_unresolved() {
            return None;
        }
        leading_letter(&self.answer)
    }

    /// A conflict's decision letter: `a`…, `base`, or `None` for rewritten
    /// text or no decision (always `None` for the other kinds).
    pub fn decision_letter(&self) -> Option<String> {
        if self.kind != SpecReviewAnnotationKind::Conflict {
            return None;
        }
        decision_letter(&self.answer)
    }

    /// The canonical JSON form the conformance corpus pins, in the form of
    /// §11.9.1–11.9.7 (see [`to_json_with`](Self::to_json_with)).
    pub fn to_json(&self) -> Json {
        self.to_json_with(SpecReviewJsonOptions::default())
    }

    /// The canonical JSON form; `options.team` adds the members of a team
    /// review (a question's `unresolved` and `answers`, a mark's `authors`
    /// and `votes`). A conflict always carries all of its members.
    pub fn to_json_with(&self, options: SpecReviewJsonOptions) -> Json {
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
            ]
            .into_iter()
            .chain(self.changed_at.as_deref().map(|t| ("changedAt", s(t))))
            .collect(),
            SpecReviewAnnotationKind::Question => {
                let mut pairs = vec![
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
                ];
                if options.team {
                    pairs.push(("unresolved", Json::Bool(self.is_unresolved())));
                }
                pairs.push((
                    "options",
                    Json::Array(self.options.iter().map(|o| o.to_json()).collect()),
                ));
                pairs.push(("recommended", o(&self.recommended)));
                pairs.push(("answerLetter", o(&self.answer_letter())));
                if options.team {
                    pairs.push((
                        "answers",
                        Json::Array(self.answers.iter().map(|a| a.to_json()).collect()),
                    ));
                }
                pairs
            }
            SpecReviewAnnotationKind::Conflict => vec![
                ("kind", s("conflict")),
                ("path", s(&self.path)),
                ("field", o(&self.field)),
                ("line", line),
                ("id", o(&self.id)),
                ("qualifiedId", o(&self.qualified_id)),
                ("topic", o(&self.topic)),
                ("text", s(&self.text)),
                ("base", s(&self.base)),
                (
                    "alternatives",
                    Json::Array(self.alternatives.iter().map(|a| a.to_json()).collect()),
                ),
                ("decision", s(&self.answer)),
                ("decisionLetter", o(&self.decision_letter())),
                ("open", Json::Bool(self.is_open())),
                ("unresolved", Json::Bool(self.is_unresolved())),
            ],
            SpecReviewAnnotationKind::Mark => {
                let mut pairs = vec![
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
                ];
                if let Some(t) = &self.changed_at {
                    pairs.push(("changedAt", s(t)));
                }
                if options.team {
                    pairs.push(("authors", json_strs(&self.authors)));
                    pairs.push(("votes", votes_json(&self.votes)));
                }
                pairs
            }
        };
        Json::Object(pairs.into_iter().map(|(k, v)| (k.to_string(), v)).collect())
    }
}

/// One paragraph of a value (SOM §11.9.1, "Paragraphs"): a run of non-blank
/// lines, where a blank line inside fenced code does not end the run. Its
/// `index` is what `after_paragraph` of the inserts takes.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecParagraph {
    /// The 0-based position among the value's paragraphs.
    pub index: usize,
    /// The 0-based first line within the value.
    pub start_line: usize,
    /// The 0-based last line within the value (inclusive).
    pub end_line: usize,
    /// The paragraph's lines, verbatim, joined with `\n`.
    pub text: String,
    /// `comment`, `question` or `conflict` when the paragraph opens with an
    /// annotation block of that kind, else `None`.
    pub annotation: Option<SpecReviewAnnotationKind>,
}

impl SpecParagraph {
    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        Json::Object(vec![
            ("index".to_string(), Json::Int(self.index as i64)),
            ("startLine".to_string(), Json::Int(self.start_line as i64)),
            ("endLine".to_string(), Json::Int(self.end_line as i64)),
            ("text".to_string(), Json::Str(self.text.clone())),
            (
                "annotation".to_string(),
                match self.annotation {
                    Some(k) => Json::Str(k.name().to_string()),
                    None => Json::Null,
                },
            ),
        ])
    }
}

/// One option of a question (SOM §11.9.2): `- (a) text`, or `- **(b)** text`
/// for the recommended one.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecQuestionOption {
    /// The lowercase letter.
    pub letter: String,
    /// The option's text, its continuation lines joined with one space.
    pub text: String,
    /// Whether the option is written bold — the recommended one.
    pub bold: bool,
}

impl SpecQuestionOption {
    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        Json::Object(vec![
            ("letter".to_string(), Json::Str(self.letter.clone())),
            ("text".to_string(), Json::Str(self.text.clone())),
            ("bold".to_string(), Json::Bool(self.bold)),
        ])
    }
}

/// The JSON options of the listing types. `team: true` gives the extended
/// form `team_annotation_cases.json` pins (SOM §11.9.8): marks with `authors`
/// and `votes`, questions with `unresolved` and `answers`, the counts with the
/// team counts, a removal report with its `conflicts`. Without it the form is
/// the one of §11.9.1–11.9.7, which the older case files pin.
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct SpecReviewJsonOptions {
    /// Render the team form.
    pub team: bool,
}

impl SpecReviewJsonOptions {
    /// The team form.
    pub const TEAM: SpecReviewJsonOptions = SpecReviewJsonOptions { team: true };
}

/// One reviewer's vote on a mark someone else proposed (SOM §11.9.8):
/// `+alice` accepts, `-bob` rejects.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecMarkVote {
    /// The voter's member id.
    pub member: String,
    /// Whether the vote accepts (`+id`) rather than rejects (`-id`).
    pub accept: bool,
}

impl SpecMarkVote {
    /// A vote of `member`, accepting or rejecting.
    pub fn new(member: &str, accept: bool) -> SpecMarkVote {
        SpecMarkVote {
            member: member.to_string(),
            accept,
        }
    }

    /// The wire name of the vote: `accept` or `reject`.
    pub fn vote_name(&self) -> &'static str {
        if self.accept {
            "accept"
        } else {
            "reject"
        }
    }

    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        json_obj(vec![
            ("member", json_str(&self.member)),
            ("vote", json_str(self.vote_name())),
        ])
    }
}

/// One line of individual answers, `**Answer (alice, bob):** (a)`
/// (SOM §11.9.8).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecIndividualAnswer {
    /// The members who gave this answer, in the order written.
    pub members: Vec<String>,
    /// The answer, trimmed.
    pub answer: String,
    /// The letter the answer starts with (`(a)` or `**(a)**`), or `None`.
    pub answer_letter: Option<String>,
    /// When the answer was last written (SOM §11.9.10), or `None`.
    pub changed_at: Option<String>,
}

impl SpecIndividualAnswer {
    /// The answer of `members`; its letter is read from the answer.
    pub fn new(members: Vec<String>, answer: &str) -> SpecIndividualAnswer {
        SpecIndividualAnswer {
            members,
            answer: answer.to_string(),
            answer_letter: leading_letter(answer),
            changed_at: None,
        }
    }

    /// The canonical JSON form; `changedAt` only when the answer has a time.
    pub fn to_json(&self) -> Json {
        let mut pairs = vec![
            ("members", json_strs(&self.members)),
            ("answer", json_str(&self.answer)),
            ("answerLetter", json_opt(&self.answer_letter)),
        ];
        if let Some(t) = &self.changed_at {
            pairs.push(("changedAt", json_str(t)));
        }
        json_obj(pairs)
    }
}

/// One lettered alternative of a conflict block, `- (a) **alice:** text`
/// (SOM §11.9.8).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecConflictAlternative {
    /// The lowercase letter.
    pub letter: String,
    /// The members who made this change.
    pub members: Vec<String>,
    /// The alternative's text; its continuation lines kept as lines.
    pub text: String,
}

impl SpecConflictAlternative {
    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        json_obj(vec![
            ("letter", json_str(&self.letter)),
            ("members", json_strs(&self.members)),
            ("text", json_str(&self.text)),
        ])
    }
}

/// The counts a report needs (SOM §11.9, §11.9.8).
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct SpecReviewAnnotationCounts {
    /// Every question.
    pub questions: usize,
    /// Questions without a team answer.
    pub open_questions: usize,
    /// Questions with a team answer.
    pub answered_questions: usize,
    /// Comment blocks.
    pub comments: usize,
    /// Inline marks.
    pub marks: usize,
    /// Questions whose team answer begins `open:` (also counted as answered).
    pub unresolved_questions: usize,
    /// Conflict blocks.
    pub conflicts: usize,
    /// Conflict blocks without a decision.
    pub open_conflicts: usize,
}

impl SpecReviewAnnotationCounts {
    /// The canonical JSON form of §11.9.1–11.9.7 (see
    /// [`to_json_with`](Self::to_json_with)).
    pub fn to_json(&self) -> Json {
        self.to_json_with(SpecReviewJsonOptions::default())
    }

    /// The canonical JSON form; `options.team` adds the three team counts.
    pub fn to_json_with(&self, options: SpecReviewJsonOptions) -> Json {
        let n = |v: usize| Json::Int(v as i64);
        let mut pairs = vec![
            ("questions", n(self.questions)),
            ("openQuestions", n(self.open_questions)),
            ("answeredQuestions", n(self.answered_questions)),
            ("comments", n(self.comments)),
            ("marks", n(self.marks)),
        ];
        if options.team {
            pairs.push(("unresolvedQuestions", n(self.unresolved_questions)));
            pairs.push(("conflicts", n(self.conflicts)));
            pairs.push(("openConflicts", n(self.open_conflicts)));
        }
        json_obj(pairs)
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
    /// The recommended option's letter; that option is written bold.
    pub recommended: Option<String>,
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
            recommended: j
                .get("recommended")
                .and_then(|r| r.as_str())
                .map(str::to_string),
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

fn json_strs(v: &[String]) -> Json {
    Json::Array(v.iter().map(|x| json_str(x)).collect())
}

fn votes_json(v: &[SpecMarkVote]) -> Json {
    Json::Array(v.iter().map(SpecMarkVote::to_json).collect())
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
    /// The authors its attribution token names (SOM §11.9.8); empty without
    /// one.
    pub authors: Vec<String>,
    /// The votes its attribution token records; empty without one.
    pub votes: Vec<SpecMarkVote>,
    /// A change comment's quote (SOM §11.9.3): `kind`, `oldText`, `newText`
    /// and `outcome`; `None` for any other mark. Its
    /// [`comment`](Self::comment) is the text after the quote.
    pub quoted_change: Option<Json>,
    /// A change's attached comment, by id; `None` without one.
    pub comment_id: Option<String>,
    /// The change an attached change comment is about, by id; `None`
    /// otherwise.
    pub change_id: Option<String>,
    /// When the mark was last changed (SOM §11.9.10); `None` without a time.
    pub changed_at: Option<String>,
}

impl SpecMarkEntry {
    /// The canonical JSON form the conformance corpus pins (see
    /// [`to_json_with`](Self::to_json_with)).
    pub fn to_json(&self) -> Json {
        self.to_json_with(SpecReviewJsonOptions::default())
    }

    /// The canonical JSON form; `options.team` adds `authors` and `votes`.
    /// `quotedChange`, `commentId` and `changeId` appear only on the marks
    /// they describe.
    pub fn to_json_with(&self, options: SpecReviewJsonOptions) -> Json {
        let mut pairs = vec![
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
        ];
        if let Some(q) = &self.quoted_change {
            pairs.push(("quotedChange", q.clone()));
        }
        if let Some(id) = &self.comment_id {
            pairs.push(("commentId", json_str(id)));
        }
        if let Some(id) = &self.change_id {
            pairs.push(("changeId", json_str(id)));
        }
        if let Some(t) = &self.changed_at {
            pairs.push(("changedAt", json_str(t)));
        }
        if options.team {
            pairs.push(("authors", json_strs(&self.authors)));
            pairs.push(("votes", votes_json(&self.votes)));
        }
        json_obj(pairs)
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

/// What [`SpecReviewAnnotations::remove_all_annotations`] did with one
/// conflict block (SOM §11.9.8).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecConflictOutcome {
    /// The conflict id, `X-<n>`.
    pub id: String,
    /// The value's path.
    pub path: String,
    /// The form field, or `None` for content.
    pub field: Option<String>,
    /// The 0-based line within the value where the block opened, before any
    /// change.
    pub line: usize,
    /// The decision as written.
    pub decision: String,
    /// The text the decision chose.
    pub result: String,
}

impl SpecConflictOutcome {
    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        json_obj(vec![
            ("id", json_str(&self.id)),
            ("path", json_str(&self.path)),
            ("field", json_opt(&self.field)),
            ("line", Json::Int(self.line as i64)),
            ("decision", json_str(&self.decision)),
            ("result", json_str(&self.result)),
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
    /// The conflicts [`SpecReviewAnnotations::remove_all_annotations`]
    /// applied, in document order; `None` for the mark operations, which do
    /// not touch conflicts.
    pub conflicts: Option<Vec<SpecConflictOutcome>>,
}

impl SpecMarkReport {
    /// The canonical JSON form of §11.9.3 (see
    /// [`to_json_with`](Self::to_json_with)).
    pub fn to_json(&self) -> Json {
        self.to_json_with(SpecReviewJsonOptions::default())
    }

    /// The canonical JSON form; `options.team` adds the `conflicts` of a
    /// removal.
    pub fn to_json_with(&self, options: SpecReviewJsonOptions) -> Json {
        let mut pairs = vec![
            (
                "applied",
                Json::Array(self.applied.iter().map(|a| a.to_json()).collect()),
            ),
            (
                "malformed",
                Json::Array(self.malformed.iter().map(|m| m.to_json()).collect()),
            ),
        ];
        if let (true, Some(conflicts)) = (options.team, &self.conflicts) {
            pairs.push((
                "conflicts",
                Json::Array(conflicts.iter().map(|c| c.to_json()).collect()),
            ));
        }
        json_obj(pairs)
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
const SCALES: &str = "\u{2696}";
const DECISION_LABEL: &str = "**Decision:**";
const UNRESOLVED_PREFIX: &str = "open:";
/// The start of an individual answer line, `**Answer (alice, bob):**`.
const INDIVIDUAL_ANSWER_OPEN: &str = "**Answer (";

/// Whether `s` is a member id (SOM §11.9.8): lowercase letters, digits and
/// `_`, at least one.
pub fn is_review_member_id(s: &str) -> bool {
    !s.is_empty()
        && s.bytes()
            .all(|b| b.is_ascii_lowercase() || b.is_ascii_digit() || b == b'_')
}

/// Whether `b` from `i` holds `n` ASCII digits.
fn digits_at(b: &[u8], i: usize, n: usize) -> bool {
    b.len() >= i + n && b[i..i + n].iter().all(u8::is_ascii_digit)
}

/// The length of a UTC offset or `Z` at the start of `b` (`Z`,
/// `+01:00`, `-05:00`), or `None`.
fn offset_len(b: &[u8]) -> Option<usize> {
    match b.first() {
        Some(b'Z') => Some(1),
        Some(b'+' | b'-')
            if digits_at(b, 1, 2) && b.get(3) == Some(&b':') && digits_at(b, 4, 2) =>
        {
            Some(6)
        }
        _ => None,
    }
}

/// Whether `b` starts with `YYYY-MM-DDTHH:MM` (16 bytes).
fn is_minute_stamp(b: &[u8]) -> bool {
    digits_at(b, 0, 4)
        && b.get(4) == Some(&b'-')
        && digits_at(b, 5, 2)
        && b.get(7) == Some(&b'-')
        && digits_at(b, 8, 2)
        && b.get(10) == Some(&b'T')
        && digits_at(b, 11, 2)
        && b.get(13) == Some(&b':')
        && digits_at(b, 14, 2)
}

/// Whether `s` is a change time of the form SOM §11.9.10 fixes: minutes with
/// the writer's UTC offset, `2026-11-07T14:05+01:00` or `2026-11-07T13:05Z`.
pub fn is_review_time(s: &str) -> bool {
    let b = s.as_bytes();
    is_minute_stamp(b) && offset_len(&b[16..]) == Some(b.len() - 16)
}

/// `at` (an ISO 8601 time: minutes, optional seconds and fraction, and an
/// offset or `Z`) as a change time (SOM §11.9.10): seconds and fractions cut,
/// the offset kept as given. Any other shape is refused.
pub fn normalize_review_time(at: &str) -> Result<String, SpecReviewAnnotationError> {
    let t = at.trim();
    let b = t.as_bytes();
    let refused = || {
        SpecReviewAnnotationError::new(format!(
            "\"{}\" is not an ISO 8601 time with an offset or Z (e.g. 2026-11-07T14:05+01:00)",
            at
        ))
    };
    if !is_minute_stamp(b) {
        return Err(refused());
    }
    let mut i = 16;
    if b.get(i) == Some(&b':') && digits_at(b, i + 1, 2) {
        i += 3;
        if b.get(i) == Some(&b'.') && digits_at(b, i + 1, 1) {
            i += 1;
            while i < b.len() && b[i].is_ascii_digit() {
                i += 1;
            }
        }
    }
    match offset_len(&b[i..]) {
        Some(n) if i + n == b.len() => Ok(format!("{}{}", &t[..16], &t[i..])),
        _ => Err(refused()),
    }
}

/// The current time as a change time (SOM §11.9.10). The standard library
/// knows no local offset, so it is written in UTC, `…Z`.
pub fn system_review_time() -> String {
    let secs = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0);
    let (y, mo, d) = crate::spec_section_id::civil_from_days(secs.div_euclid(86_400));
    let m = secs.rem_euclid(86_400) / 60;
    format!("{:04}-{:02}-{:02}T{:02}:{:02}Z", y, mo, d, m / 60, m % 60)
}

/// `parts` (a header's or an answer's comma-separated parts) split into the
/// parts before a trailing change time and the time (SOM §11.9.10).
fn split_time<'s>(parts: &[&'s str]) -> (Vec<&'s str>, Option<String>) {
    if let Some(last) = parts.last() {
        if is_review_time(last.trim()) {
            return (
                parts[..parts.len() - 1].to_vec(),
                Some(last.trim().to_string()),
            );
        }
    }
    (parts.to_vec(), None)
}

fn is_unresolved(answer: &str) -> bool {
    answer.starts_with(UNRESOLVED_PREFIX)
}

/// A conflict decision's letter: `a`…, `base`, or `None` (rewritten text,
/// an `open:` decision, or none).
fn decision_letter(decision: &str) -> Option<String> {
    let t = decision.trim_start();
    if t.starts_with("(base)") || t.starts_with("**(base)**") {
        return Some("base".to_string());
    }
    if is_unresolved(t) {
        None
    } else {
        leading_letter(t)
    }
}

/// The members text and the label length of an individual answer line,
/// `**Answer (<ids>):**`, or `None` when `line` does not open with one.
fn individual_answer_label(line: &str) -> Option<(&str, usize)> {
    let rest = line.strip_prefix(INDIVIDUAL_ANSWER_OPEN)?;
    let close = rest.find(')')?;
    if !rest[close + 1..].starts_with(":**") {
        return None;
    }
    Some((&rest[..close], INDIVIDUAL_ANSWER_OPEN.len() + close + 4))
}

/// One `**Answer (<ids>):**` entry of a question (SOM §11.9.8).
#[derive(Debug, Clone)]
struct IndividualAnswerEntry {
    /// The value line of the `**Answer (…):**` line.
    line: usize,
    /// The last value line of the entry with text (inclusive).
    end: usize,
    members: Vec<String>,
    answer: String,
    /// The entry's change time (SOM §11.9.10), or `None`.
    changed_at: Option<String>,
}

/// One question region inside a question block.
#[derive(Debug, Clone)]
struct Question {
    header: usize,
    region_end: usize,
    /// The line of the team's `**Answer:**`.
    answer_line: Option<usize>,
    id: String,
    topic: String,
    starred: bool,
    text: String,
    answer: String,
    options: Vec<SpecQuestionOption>,
    recommended: Option<String>,
    /// The individual answers, in the order written.
    answers: Vec<IndividualAnswerEntry>,
}

/// One parsed conflict block (SOM §11.9.8).
#[derive(Debug, Clone)]
struct Conflict {
    /// `None` when the header is malformed: the block is then not listed.
    id: Option<String>,
    topic: String,
    text: String,
    /// The `(base)` text, or `None` when the block has none.
    base: Option<String>,
    alternatives: Vec<SpecConflictAlternative>,
    decision: String,
}

fn is_letter(c: u8) -> bool {
    c.is_ascii_lowercase()
}

/// The options of a question and its recommended letter (SOM §11.9.2): one
/// option per line, `- (a) …`, the recommended one bold, `- **(b)** …`. The
/// recommended letter is the first bold option's; else the first option's
/// whose text says "recommended"; else the letter a `*Recommendation:*` line
/// names; else none.
fn parse_options(lines: &[String]) -> (Vec<SpecQuestionOption>, Option<String>) {
    let mut options = Vec::new();
    // The open option: (letter, text, bold).
    let mut current: Option<(String, String, bool)> = None;
    fn close(current: &mut Option<(String, String, bool)>, options: &mut Vec<SpecQuestionOption>) {
        if let Some((letter, text, bold)) = current.take() {
            options.push(SpecQuestionOption {
                letter,
                text: text.trim().to_string(),
                bold,
            });
        }
    }
    for l in lines {
        if let Some(r) = l.strip_prefix("- ") {
            let b = r.as_bytes();
            if b.len() >= 7 && r.starts_with("**(") && is_letter(b[3]) && &b[4..7] == b")**" {
                close(&mut current, &mut options);
                current = Some((r[3..4].to_string(), r[7..].to_string(), true));
                continue;
            }
            if b.len() >= 3 && b[0] == b'(' && is_letter(b[1]) && b[2] == b')' {
                close(&mut current, &mut options);
                current = Some((r[1..2].to_string(), r[3..].to_string(), false));
                continue;
            }
        }
        if let Some((_, text, _)) = current.as_mut() {
            if l.starts_with(' ') && !l.trim().is_empty() {
                *text = format!("{} {}", text.trim(), l.trim());
                continue;
            }
        }
        close(&mut current, &mut options);
    }
    close(&mut current, &mut options);
    let recommended = options
        .iter()
        .find(|o| o.bold)
        .or_else(|| {
            options
                .iter()
                .find(|o| o.text.to_lowercase().contains("recommended"))
        })
        .map(|o| o.letter.clone())
        .or_else(|| {
            const LABEL: &str = "*Recommendation:*";
            lines.iter().find_map(|l| {
                l.find(LABEL)
                    .and_then(|i| leading_letter(&l[i + LABEL.len()..]))
            })
        });
    (options, recommended)
}

/// The letter of a leading `(x)` or `**(x)**` in `s` (spaces skipped).
fn leading_letter(s: &str) -> Option<String> {
    let t = s.trim_start();
    let t = t.strip_prefix("**").unwrap_or(t);
    let b = t.as_bytes();
    if b.len() >= 3 && b[0] == b'(' && is_letter(b[1]) && b[2] == b')' {
        Some(t[1..2].to_string())
    } else {
        None
    }
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
    /// A conflict block's content.
    conflict: Option<Conflict>,
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
    /// Where an id is inserted into the first line (a byte offset).
    marker_end: usize,
    /// The first line up to where the author's parentheses (or the text)
    /// start.
    before_author: String,
    /// When the comment was last changed (SOM §11.9.10), or `None`.
    changed_at: Option<String>,
}

/// One parsed mark; `start`/`end` are byte offsets into the value. `end`
/// lies after the attribution token when the mark has one (SOM §11.9.8),
/// `body_end` always right after the mark itself, so the token can be
/// rewritten in place.
#[derive(Debug, Clone)]
struct Mark {
    start: usize,
    end: usize,
    body_end: usize,
    line: usize,
    kind: SpecMarkKind,
    text: String,
    new_text: Option<String>,
    comment: Option<String>,
    authors: Vec<String>,
    votes: Vec<SpecMarkVote>,
    /// A comment mark's quote of a change (SOM §11.9.3), or `None`.
    quote: Option<Quote>,
    /// The time in the mark's attribution token (SOM §11.9.10), or `None`.
    changed_at: Option<String>,
    /// The index (among the value's marks) of the change this change comment
    /// is attached to, or `None`.
    change_index: Option<usize>,
    /// The index of this change's attached comment, or `None`.
    comment_index: Option<usize>,
    /// Whether whitespace was written inside the delimiters at the leading /
    /// trailing edge of `text` and of `new_text` (SOM §11.9.3, edge spaces).
    text_lead: bool,
    text_trail: bool,
    new_lead: bool,
    new_trail: bool,
}

/// The quote a change comment opens with (SOM §11.9.3); offsets are byte
/// offsets into the value.
#[derive(Debug, Clone)]
struct Quote {
    kind: SpecMarkKind,
    old_text: String,
    new_text: String,
    /// `accepted`, `rejected`, or `None` while the change is open.
    outcome: Option<&'static str>,
    /// Right after the quote's closing delimiter.
    delim_end: usize,
    /// Right after the quote's `]`.
    end: usize,
    /// The comment: the text after the quote, trimmed.
    comment: String,
}

impl Quote {
    fn to_json(&self) -> Json {
        json_obj(vec![
            ("kind", json_str(self.kind.name())),
            ("oldText", json_str(&self.old_text)),
            ("newText", json_str(&self.new_text)),
            ("outcome", self.outcome.map(json_str).unwrap_or(Json::Null)),
        ])
    }
}

fn is_blank_char(c: u8) -> bool {
    c == b' ' || c == b'\t'
}

/// Reads the quote at the start of a comment mark's inner text `s`, whose
/// first byte is at value offset `at`: `Ok(Some(quote))`, `Ok(None)` when `s`
/// opens no quote, or `Err(issue)` (`unclosed`, `noArrow`) for a quote that
/// is malformed.
fn read_quote(s: &str, at: usize) -> Result<Option<Quote>, &'static str> {
    let b = s.as_bytes();
    let mut a = 0;
    while a < b.len() && matches!(b[a], b' ' | b'\t' | b'\r' | b'\n') {
        a += 1;
    }
    if a + 3 > b.len() || b[a] != b'[' {
        return Ok(None);
    }
    let d = &b[a + 1..a + 3];
    let kind = match d {
        b"++" => SpecMarkKind::Insertion,
        b"--" => SpecMarkKind::Deletion,
        b"~~" => SpecMarkKind::Substitution,
        _ => return Ok(None),
    };
    // `d` is ASCII, so `a + 3` is a char boundary.
    let d = &s[a + 1..a + 3];
    let mut j = find_from(s, d, a + 3);
    while let Some(jj) = j {
        let mut t = jj + 2;
        while t < b.len() && is_blank_char(b[t]) {
            t += 1;
        }
        let mut outcome = None;
        let mut close = None;
        if t < b.len() && b[t] == b']' {
            close = Some(t);
        } else if t < b.len() && b[t] == b'|' {
            t += 1;
            while t < b.len() && is_blank_char(b[t]) {
                t += 1;
            }
            for w in ["accepted", "rejected"] {
                if !b[t..].starts_with(w.as_bytes()) {
                    continue;
                }
                let mut u = t + w.len();
                while u < b.len() && is_blank_char(b[u]) {
                    u += 1;
                }
                if u < b.len() && b[u] == b']' {
                    outcome = Some(w);
                    close = Some(u);
                }
                break;
            }
        }
        if let Some(close) = close {
            let body = &s[a + 3..jj];
            let (old_text, new_text) = match kind {
                SpecMarkKind::Insertion => (String::new(), body.trim().to_string()),
                SpecMarkKind::Deletion => (body.trim().to_string(), String::new()),
                _ => {
                    let Some(arrow) = body.find("~>") else {
                        return Err("noArrow");
                    };
                    (
                        body[..arrow].trim().to_string(),
                        body[arrow + 2..].trim().to_string(),
                    )
                }
            };
            return Ok(Some(Quote {
                kind,
                old_text,
                new_text,
                outcome,
                delim_end: at + jj + 2,
                end: at + close + 1,
                comment: s[close + 1..].trim().to_string(),
            }));
        }
        // Step one byte on (the delimiter is ASCII): the next delimiter may
        // overlap this one.
        j = find_from(s, d, jj + 1);
    }
    Err("unclosed")
}

/// Links each change comment to the change written directly before it whose
/// kind and texts it quotes (SOM §11.9.3).
fn attach_change_comments(marks: &mut [Mark]) {
    for k in 1..marks.len() {
        let Some(q) = &marks[k].quote else { continue };
        let c = &marks[k - 1];
        if q.outcome.is_some() || !is_change_mark(c.kind) {
            continue;
        }
        if c.end != marks[k].start || c.kind != q.kind {
            continue;
        }
        if mark_replacement(c, false) != q.old_text || mark_replacement(c, true) != q.new_text {
            continue;
        }
        marks[k].change_index = Some(k - 1);
        marks[k - 1].comment_index = Some(k);
    }
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
                conflict: None,
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
                conflict: None,
            });
        } else if first.starts_with(SCALES) {
            let conflict = parse_conflict(&mut p, s, e);
            p.blocks.push(Block {
                start: s,
                end: e,
                kind: SpecReviewAnnotationKind::Conflict,
                questions: Vec::new(),
                combined: false,
                conflict: Some(conflict),
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
    let mut changed_at = None;
    let before_author = raw0[..raw0.len() - rest.len()].to_string();
    if rest.starts_with('(') {
        if let Some(close) = rest.find(')') {
            if close > 0 {
                let inside: Vec<&str> = rest[1..close].split(',').collect();
                let (parts, time) = split_time(&inside);
                author = if time.is_none() {
                    Some(rest[1..close].to_string())
                } else {
                    Some(parts.join(",").trim().to_string()).filter(|a| !a.is_empty())
                };
                changed_at = time;
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
    let mut text_lines: Vec<String> = vec![rest.to_string()];
    for k in start + 1..=end {
        let inn = inner(&p.lines[k]).to_string();
        let t = lstrip(&inn);
        if t.starts_with(QUESTION_OPEN)
            || t.starts_with(ANSWER_LABEL)
            || individual_answer_label(t).is_some()
        {
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
        marker_end,
        before_author,
        changed_at,
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
        // Every `**Answer` line of the region: the individual ones and the team's.
        let answer_lines: Vec<usize> = (k + 1..=region_end)
            .filter(|&m| {
                inn[m].starts_with(ANSWER_LABEL) || individual_answer_label(&inn[m]).is_some()
            })
            .collect();
        // An answer runs to the next `**Answer` line or the end of the region.
        let answer_end = |m: usize| -> usize {
            answer_lines
                .iter()
                .find(|&&x| x > m)
                .map(|&x| x - 1)
                .unwrap_or(region_end)
        };
        let answer_text = |m: usize, label: usize| -> String {
            let mut parts: Vec<&str> = vec![&inn[m][label..]];
            parts.extend(inn[m + 1..=answer_end(m)].iter().map(String::as_str));
            parts.join("\n").trim().to_string()
        };
        // The question's text ends before its first answer line of either kind.
        let text_end = match answer_lines.first() {
            Some(&a) => a - 1,
            None => region_end,
        };
        let (options, recommended) = parse_options(&inn[k + 1..=text_end]);
        let mut parts: Vec<&str> = vec![h.rest.as_str()];
        parts.extend(inn[k + 1..=text_end].iter().map(String::as_str));
        let text = parts.join("\n").trim().to_string();
        let mut answer: Option<usize> = None;
        let mut individual: Vec<IndividualAnswerEntry> = Vec::new();
        let mut answered: HashSet<String> = HashSet::new();
        for &m in &answer_lines {
            let Some((ids, label)) = individual_answer_label(&inn[m]) else {
                answer = answer.or(Some(m));
                continue;
            };
            let ids: Vec<&str> = ids.split(',').collect();
            let (member_parts, answer_time) = split_time(&ids);
            let members: Vec<String> = member_parts.iter().map(|x| x.trim().to_string()).collect();
            for member in &members {
                if !answered.insert(member.clone()) {
                    p.malformed.push(format!(
                        "line {}: {} already answered {}; a member answers a question at \
                         most once (SOM §11.9.8)",
                        start + m,
                        member,
                        h.id
                    ));
                }
            }
            let mut end = answer_end(m);
            while end > m && inn[end].trim().is_empty() {
                end -= 1;
            }
            individual.push(IndividualAnswerEntry {
                line: start + m,
                end: start + end,
                members,
                answer: answer_text(m, label),
                changed_at: answer_time,
            });
        }
        list.push(Question {
            header: start + k,
            region_end: start + region_end,
            answer_line: answer.map(|a| start + a),
            id: h.id.clone(),
            topic: h.topic.clone(),
            starred: h.starred,
            text,
            answer: answer
                .map(|a| answer_text(a, ANSWER_LABEL.len()))
                .unwrap_or_default(),
            options,
            recommended,
            answers: individual,
        });
    }
    (list, combined)
}

/// The header of a conflict block after its marker,
/// `**X-<n> — <topic>:** <text>`, as (id, topic, text); `None` when
/// malformed. The topic is the shortest that a `:**` at the end of the line,
/// or before a space, closes.
fn parse_conflict_header(rest: &str) -> Option<(String, String, String)> {
    let r = rest.strip_prefix("**X-")?;
    let digits = r.bytes().take_while(u8::is_ascii_digit).count();
    if digits == 0 || r.as_bytes()[0] == b'0' {
        return None;
    }
    let id = format!("X-{}", &r[..digits]);
    let t = r[digits..].strip_prefix(EM_DASH_SEP)?;
    // The topic holds at least one character.
    let mut from = t.chars().next().map_or(0, char::len_utf8);
    while let Some(at) = find_from(t, ":**", from) {
        let after = &t[at + 3..];
        if after.is_empty() || after.starts_with(' ') {
            let text = after.strip_prefix(' ').unwrap_or("").trim().to_string();
            return Some((id, t[..at].to_string(), text));
        }
        from = at + 1;
    }
    None
}

/// A conflict alternative's line, `- (a) **alice, bob:** text`, as (letter,
/// members, text); `None` when the line is not one.
fn parse_conflict_alternative(line: &str) -> Option<(String, Vec<String>, String)> {
    let r = line.strip_prefix("- (")?;
    let b = r.as_bytes();
    if b.len() < 2 || !is_letter(b[0]) || b[1] != b')' {
        return None;
    }
    let letter = r[..1].to_string();
    let rest = &r[2..];
    if rest.is_empty() {
        return Some((letter, Vec::new(), String::new()));
    }
    let rest = rest.strip_prefix(' ')?;
    // The optional `**<members>:**` naming who made this change.
    if let Some(m) = rest.strip_prefix("**") {
        let star = m.find('*').unwrap_or(m.len());
        let after = &m[star..];
        if m[..star].ends_with(':') && after.starts_with("**") {
            let after = &after[2..];
            if after.is_empty() || after.starts_with(' ') {
                let members = m[..star - 1]
                    .split(',')
                    .map(str::trim)
                    .filter(|x| !x.is_empty())
                    .map(str::to_string)
                    .collect();
                return Some((
                    letter,
                    members,
                    after.strip_prefix(' ').unwrap_or("").to_string(),
                ));
            }
        }
    }
    Some((letter, Vec::new(), rest.to_string()))
}

/// A conflict block (SOM §11.9.8): the header, the `(base)` line and the
/// lettered alternatives — each continuing on lines indented under it, its
/// line breaks kept — then `**Decision:**`. A malformed header leaves the
/// block unlisted; a missing base line or alternative is a finding.
fn parse_conflict(p: &mut Parsed, start: usize, end: usize) -> Conflict {
    let inn: Vec<String> = (start..=end)
        .map(|k| inner(&p.lines[k]).to_string())
        .collect();
    let mut rest = &inn[0][SCALES.len()..];
    if let Some(r) = rest.strip_prefix(VS16) {
        rest = r;
    }
    let header = parse_conflict_header(rest.trim_start());
    let mut c = Conflict {
        id: None,
        topic: String::new(),
        text: String::new(),
        base: None,
        alternatives: Vec::new(),
        decision: String::new(),
    };
    match &header {
        Some((id, topic, text)) => {
            c.id = Some(id.clone());
            c.topic = topic.clone();
            c.text = text.clone();
        }
        None => p.malformed.push(format!(
            "line {}: conflict header is not \"\u{2696}\u{FE0F} **X-<n> \u{2014} <topic>:**\" \
             (SOM §11.9.8)",
            start
        )),
    }
    let decision_line = (1..inn.len())
        .find(|&k| inn[k].starts_with(DECISION_LABEL))
        .unwrap_or(inn.len());
    // The open entry: the base (letter `None`) or an alternative, with its lines.
    let mut open: Option<(Option<String>, Vec<String>, Vec<String>)> = None;
    let close = |open: &mut Option<(Option<String>, Vec<String>, Vec<String>)>,
                 c: &mut Conflict| {
        if let Some((letter, members, lines)) = open.take() {
            let text = lines.join("\n").trim().to_string();
            match letter {
                None => c.base = Some(text),
                Some(letter) => c.alternatives.push(SpecConflictAlternative {
                    letter,
                    members,
                    text,
                }),
            }
        }
    };
    for l in &inn[1..decision_line] {
        let base = if l == "- (base)" {
            Some("")
        } else {
            l.strip_prefix("- (base) ")
        };
        if let Some(text) = base {
            close(&mut open, &mut c);
            open = Some((None, Vec::new(), vec![text.to_string()]));
        } else if let Some((letter, members, text)) = parse_conflict_alternative(l) {
            close(&mut open, &mut c);
            open = Some((Some(letter), members, vec![text]));
        } else if let (Some((_, _, lines)), true) = (open.as_mut(), l.starts_with(' ')) {
            lines.push(match l.strip_prefix("  ") {
                Some(r) => r.to_string(),
                None => lstrip(l).to_string(),
            });
        } else {
            close(&mut open, &mut c);
        }
    }
    close(&mut open, &mut c);
    if decision_line < inn.len() {
        let mut parts: Vec<&str> = vec![&inn[decision_line][DECISION_LABEL.len()..]];
        parts.extend(inn[decision_line + 1..].iter().map(String::as_str));
        c.decision = parts.join("\n").trim().to_string();
    }
    if let Some(id) = &c.id {
        if c.base.is_none() {
            p.malformed.push(format!(
                "line {}: conflict {} has no \"(base)\" line (SOM §11.9.8)",
                start, id
            ));
        }
        if c.alternatives.is_empty() {
            p.malformed.push(format!(
                "line {}: conflict {} has no lettered alternative (SOM §11.9.8)",
                start, id
            ));
        }
    }
    c
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
    attach_change_comments(&mut p.marks);
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
        if c == b'{' && seg[i..].starts_with("{@") {
            // A token that no mark precedes directly (a mark's own token is
            // read with the mark, below).
            let line = line_of(line_start, base + i);
            p.malformed.push(format!(
                "line {}: an attribution token \"{{@\" does not follow a mark directly \
                 (SOM §11.9.8)",
                line
            ));
            i = find_from(seg, "}", i + 2).map_or(i + 2, |close| close + 1);
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
            body_end: base + end,
            line,
            kind,
            text,
            new_text,
            comment,
            authors: Vec::new(),
            votes: Vec::new(),
            quote: None,
            changed_at: None,
            change_index: None,
            comment_index: None,
            text_lead: false,
            text_trail: false,
            new_lead: false,
            new_trail: false,
        };
        let before = p.marks.len();
        match opener {
            "{>>" => {
                let mut m = mark(
                    SpecMarkKind::Comment,
                    String::new(),
                    None,
                    Some(inn.trim().to_string()),
                    end,
                );
                match read_quote(inn, base + i + 3) {
                    Ok(q) => m.quote = q,
                    Err("unclosed") => p.malformed.push(format!(
                        "line {}: the quote of a change comment is not closed; \
                         it is read as a plain comment (SOM §11.9.3)",
                        line
                    )),
                    Err(_) => p.malformed.push(format!(
                        "line {}: the quote of a change comment has no \"~>\"; \
                         it is read as a plain comment (SOM §11.9.3)",
                        line
                    )),
                }
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
                let mut m = mark(SpecMarkKind::Insertion, inn.trim().to_string(), None, None, end);
                m.text_lead = ws_edge(inn, true);
                m.text_trail = ws_edge(inn, false);
                p.marks.push(m);
            }
            "{--" => {
                let mut m = mark(SpecMarkKind::Deletion, inn.trim().to_string(), None, None, end);
                m.text_lead = ws_edge(inn, true);
                m.text_trail = ws_edge(inn, false);
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
                let (old_raw, new_raw) = (&inn[..arrow], &inn[arrow + 2..]);
                let mut m = mark(
                    SpecMarkKind::Substitution,
                    old_raw.trim().to_string(),
                    Some(new_raw.trim().to_string()),
                    None,
                    end,
                );
                m.text_lead = ws_edge(old_raw, true);
                m.text_trail = ws_edge(old_raw, false);
                m.new_lead = ws_edge(new_raw, true);
                m.new_trail = ws_edge(new_raw, false);
                p.marks.push(m);
            }
        }
        if p.marks.len() > before && seg[end..].starts_with("{@") {
            end = attach_token(p, seg, end, base);
        }
        i = end;
    }
}

/// Reads the attribution token `{@…}` at `at` (SOM §11.9.8) into the last
/// mark, which it directly follows, and returns the segment offset after it.
/// The token is part of the mark — its markup, its decision — so the mark's
/// `end` moves past it. A token that breaks the grammar is still part of the
/// mark (it goes with the mark on a decision) and is a finding; its members
/// are then not listed.
fn attach_token(p: &mut Parsed, seg: &str, at: usize, base: usize) -> usize {
    let line_end = find_from(seg, "\n", at);
    let close = find_from(seg, "}", at + 2);
    let m_line = p.marks.last().map_or(0, |m| m.line);
    let close = match close {
        Some(c) if line_end.is_none_or(|e| c <= e) => c,
        _ => {
            p.malformed.push(format!(
                "line {}: attribution token \"{{@\" is not closed (SOM §11.9.8)",
                m_line
            ));
            return at;
        }
    };
    let kind = p.marks.last().map_or(SpecMarkKind::Comment, |m| m.kind);
    let (changed_at, read) = read_token(&seg[at + 2..close], kind);
    let m = p.marks.last_mut().expect("a token follows a mark");
    m.end = base + close + 1;
    m.changed_at = changed_at;
    match read {
        Ok((authors, votes)) => {
            m.authors = authors;
            m.votes = votes;
        }
        Err(reason) => p.malformed.push(format!(
            "line {}: attribution token {} (SOM §11.9.8)",
            m_line, reason
        )),
    }
    close + 1
}

/// Whether a mark kind is a change, which alone takes votes (SOM §11.9.8).
fn is_change_mark(kind: SpecMarkKind) -> bool {
    matches!(
        kind,
        SpecMarkKind::Insertion | SpecMarkKind::Deletion | SpecMarkKind::Substitution
    )
}

type TokenMembers = (Vec<String>, Vec<SpecMarkVote>);

/// The change time of a token's inside, `[<authors>][ <votes>][ <time>]`
/// (SOM §11.9.10), and its members or the reason they break the grammar of
/// SOM §11.9.8 (the time is read either way).
fn read_token(inside: &str, kind: SpecMarkKind) -> (Option<String>, Result<TokenMembers, String>) {
    // A space after a comma is allowed: `alice, bob` reads as `alice,bob`.
    let mut compact = String::with_capacity(inside.len());
    let mut after_comma = false;
    for ch in inside.chars() {
        if after_comma && ch.is_whitespace() {
            continue;
        }
        after_comma = ch == ',';
        compact.push(ch);
    }
    let mut words: Vec<&str> = compact.split_whitespace().collect();
    if words.is_empty() {
        return (None, Err("is empty".to_string()));
    }
    let mut time = None;
    if words.last().is_some_and(|w| is_review_time(w)) {
        time = words.pop().map(str::to_string);
    }
    (time, read_members(&words, kind))
}

/// The authors and votes of a token's words (its time taken off), or the
/// reason they break the grammar of SOM §11.9.8.
fn read_members(words: &[&str], kind: SpecMarkKind) -> Result<TokenMembers, String> {
    if words.is_empty() {
        return Ok((Vec::new(), Vec::new()));
    }
    let is_vote = |w: &str| w.starts_with('+') || w.starts_with('-');
    let mut authors: Vec<String> = Vec::new();
    let mut votes: Vec<SpecMarkVote> = Vec::new();
    let mut k = 0;
    if !is_vote(words[0]) {
        authors.extend(words[0].split(',').map(str::to_string));
        k = 1;
    }
    for w in &words[k..] {
        if !is_vote(w) {
            return Err(format!("has \"{}\" where a vote belongs", w));
        }
        votes.push(SpecMarkVote::new(&w[1..], w.starts_with('+')));
    }
    let mut seen: HashSet<&str> = HashSet::new();
    for id in authors.iter().chain(votes.iter().map(|v| &v.member)) {
        if !is_review_member_id(id) {
            return Err(format!("names \"{}\", which is not a member id", id));
        }
        if !seen.insert(id) {
            return Err(format!("names {} twice, or as author and voter", id));
        }
    }
    if !votes.is_empty() && !is_change_mark(kind) {
        return Err(format!(
            "carries votes on a {} mark, which takes authors only",
            kind.name()
        ));
    }
    Ok((authors, votes))
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
            a.changed_at = c.changed_at.clone();
            out.push((b.start, 0, seq, a));
            seq += 1;
        } else if let Some(c) = &b.conflict {
            let Some(id) = &c.id else { continue };
            let mut a = SpecReviewAnnotation::base(
                SpecReviewAnnotationKind::Conflict,
                path,
                field,
                b.start,
            );
            a.id = Some(id.clone());
            a.qualified_id = qualifier.map(|q| format!("{} {}", q, id));
            a.topic = Some(c.topic.clone());
            a.text = c.text.clone();
            a.base = c.base.clone().unwrap_or_default();
            a.alternatives = c.alternatives.clone();
            a.answer = c.decision.clone();
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
                a.options = q.options.clone();
                a.recommended = q.recommended.clone();
                a.answers = q
                    .answers
                    .iter()
                    .map(|x| SpecIndividualAnswer {
                        changed_at: x.changed_at.clone(),
                        ..SpecIndividualAnswer::new(x.members.clone(), &x.answer)
                    })
                    .collect();
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
        a.authors = m.authors.clone();
        a.votes = m.votes.clone();
        a.changed_at = m.changed_at.clone();
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
pub fn format_comment_block(
    id: &str,
    text: &str,
    author: Option<&str>,
    changed_at: Option<&str>,
) -> Vec<String> {
    let t: Vec<&str> = text.split('\n').collect();
    let mut head = format!("> {}{} **{}**", ARROW, VS16, id);
    if let Some(who) = author_and_time(author, changed_at) {
        head.push_str(&format!(" ({}):", who));
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
        match &q.recommended {
            Some(r) if o.starts_with(&format!("({})", r)) => {
                lines.push(format!("> - **({})**{}", r, o.get(3..).unwrap_or("")));
            }
            _ => lines.push(format!("> - {}", o)),
        }
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
/// never join two words, keep an edge space written inside a change mark
/// after punctuation and before a word, never leave a double space or a space
/// before punctuation, and a mark that was a whole line leaves no blank line.
/// `accept` names the decision the replacement comes from; `None` when the
/// mark is removed rather than decided.
fn replace_mark(value: &str, m: &Mark, replacement: &str, accept: Option<bool>) -> String {
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
                    .is_some_and(|c| CLOSING_PUNCTUATION.contains(c))
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
    // on that side. An edge space written inside a change mark, beside the
    // text the decision keeps, is kept after punctuation and before a word or
    // an opening bracket.
    let (lead, trail) = accept.map_or((false, false), |a| kept_edges(m, a));
    let before_last = before.chars().next_back();
    let after_first = after.chars().next();
    if (before_last.is_some_and(is_word_char)
        && replacement.chars().next().is_some_and(is_word_char))
        || (lead && before_last.is_some_and(|c| CLOSING_PUNCTUATION.contains(c)))
    {
        replacement.insert(0, ' ');
    }
    if (replacement.chars().next_back().is_some_and(is_word_char)
        && after_first.is_some_and(is_word_char))
        || (trail && after_first.is_some_and(|c| is_word_char(c) || c == '(' || c == '['))
    {
        replacement.push(' ');
    }
    format!("{}{}{}", before, replacement, after)
}

/// The punctuation no space is left before, and after which an edge space is
/// kept (SOM §11.9.3).
const CLOSING_PUNCTUATION: &str = ".,;:!?)]}";

/// Whether `raw`, a mark's text as written between its delimiters, begins
/// (`leading`) or ends with whitespace.
fn ws_edge(raw: &str, leading: bool) -> bool {
    let c = if leading {
        raw.chars().next()
    } else {
        raw.chars().next_back()
    };
    matches!(c, Some(' ' | '\t' | '\n'))
}

/// The edge spaces written beside the text `accept` keeps of `m`: the
/// leading and the trailing one.
fn kept_edges(m: &Mark, accept: bool) -> (bool, bool) {
    match m.kind {
        SpecMarkKind::Insertion if accept => (m.text_lead, m.text_trail),
        SpecMarkKind::Deletion if !accept => (m.text_lead, m.text_trail),
        SpecMarkKind::Substitution if accept => (m.new_lead, m.new_trail),
        SpecMarkKind::Substitution => (m.text_lead, m.text_trail),
        _ => (false, false),
    }
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
        v = replace_mark(&v, m, &mark_replacement(m, accept), Some(accept));
    }
    v
}

/// `value` with every inline mark accepted (`accept`) or rejected, as accept
/// all / reject all write it (SOM §11.9.3): change comments stay, an attached
/// one records the outcome; every other highlight and comment mark is
/// removed. Marks in code and malformed marks stay as written.
pub fn decide_all_marks_text(value: &str, accept: bool) -> String {
    let marks = parse(value).marks;
    let mut v = value.to_string();
    for k in (0..marks.len()).rev() {
        if marks[k].quote.is_some() {
            continue;
        }
        v = decide_mark(&v, &marks, k, accept);
    }
    v
}

/// `value` with the mark `k` of `marks` decided; a change's attached comment
/// records the outcome (SOM §11.9.3).
fn decide_mark(value: &str, marks: &[Mark], k: usize, accept: bool) -> String {
    let m = &marks[k];
    let mut v = value.to_string();
    if let Some(q) = m.comment_index.and_then(|ci| marks[ci].quote.as_ref()) {
        v = record_outcome(&v, q, accept);
    }
    replace_mark(&v, m, &mark_replacement(m, accept), Some(accept))
}

/// `value` with the outcome written into the quote `q`: everything from its
/// closing delimiter to its `]` becomes ` | accepted]` or ` | rejected]`.
fn record_outcome(value: &str, q: &Quote, accept: bool) -> String {
    format!(
        "{} | {}]{}",
        &value[..q.delim_end],
        if accept { "accepted" } else { "rejected" },
        &value[q.end..]
    )
}

/// Whether `t` holds a blank line: a newline, then only spaces, tabs and
/// carriage returns, then a newline.
fn has_blank_line(t: &str) -> bool {
    let b = t.as_bytes();
    let mut i = 0;
    while i < b.len() {
        if b[i] == b'\n' {
            let mut j = i + 1;
            while j < b.len() && matches!(b[j], b' ' | b'\t' | b'\r') {
                j += 1;
            }
            if j < b.len() && b[j] == b'\n' {
                return true;
            }
        }
        i += 1;
    }
    false
}

/// The trimmed `text` of an inline comment, refused when it is empty or
/// holds a mark delimiter or a blank line.
fn check_inline_comment(text: &str) -> Result<String, SpecReviewAnnotationError> {
    let t = text.trim();
    if t.is_empty() {
        return Err(SpecReviewAnnotationError::new("a comment needs text"));
    }
    if has_opener(t) || t.contains("<<}") || has_blank_line(t) {
        return Err(SpecReviewAnnotationError::new(
            "a comment cannot hold a mark delimiter or a blank line",
        ));
    }
    Ok(t.to_string())
}

/// The whitespace of the change-comment anchors (SOM §11.9.3).
fn is_anchor_space(c: u8) -> bool {
    matches!(c, b' ' | b'\t' | b'\r' | b'\n')
}

fn non_space_count(s: &str) -> usize {
    s.bytes().filter(|&c| !is_anchor_space(c)).count()
}

/// `set_marked` with the value's change comments kept (SOM §11.9.3): taken
/// out of the original, then written back where their anchor falls.
fn mark_keeping_change_comments(current: &str, text: &str) -> SpecMarkedChange {
    // 1. The original: every mark rejected except the change comments.
    let mut original = current.to_string();
    let marks = parse(current).marks;
    for m in marks.iter().rev() {
        if m.quote.is_some() {
            continue;
        }
        original = replace_mark(&original, m, &mark_replacement(m, false), Some(false));
    }
    // 2. Each change comment's markup, anchor and leading space.
    let kept: Vec<Mark> = parse(&original)
        .marks
        .into_iter()
        .filter(|m| m.quote.is_some())
        .collect();
    let ob = original.as_bytes();
    let mut anchors: Vec<(String, usize, bool)> = Vec::with_capacity(kept.len());
    let mut counted = 0;
    let mut from = 0;
    for m in &kept {
        counted += non_space_count(&original[from..m.start]);
        from = m.end;
        anchors.push((
            original[m.start..m.end].to_string(),
            counted,
            m.start > 0 && is_blank_char(ob[m.start - 1]),
        ));
    }
    // 3. Removed, compared.
    let mut base = original.clone();
    for m in kept.iter().rev() {
        base = replace_mark(&base, m, "", None);
    }
    let result = mark_change_text(&base, text);
    if anchors.is_empty() {
        return result;
    }
    // 4. Written back where k non-whitespace bytes have passed.
    let r = &result.text;
    let rb = r.as_bytes();
    let rm = parse(r).marks;
    let place = |k: usize| -> usize {
        if k == 0 {
            return 0;
        }
        let (mut n, mut i, mut mi) = (0, 0, 0);
        while i < rb.len() {
            if mi < rm.len() && rm[mi].start == i {
                let m = &rm[mi];
                mi += 1;
                if m.kind != SpecMarkKind::Insertion {
                    n += non_space_count(&m.text);
                }
                i = m.end;
                if n >= k {
                    return i;
                }
                continue;
            }
            if !is_anchor_space(rb[i]) {
                n += 1;
            }
            i += 1;
            if n >= k {
                return i;
            }
        }
        rb.len()
    };
    let at: Vec<usize> = anchors.iter().map(|a| place(a.1)).collect();
    let mut out = r.clone();
    for j in (0..anchors.len()).rev() {
        let (markup, _, space) = &anchors[j];
        out.insert_str(
            at[j],
            &format!("{}{}", if *space { " " } else { "" }, markup),
        );
    }
    SpecMarkedChange {
        text: out,
        exact: result.exact,
    }
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
        v = replace_mark(&v, m, &mark_replacement(m, true), Some(true));
    }
    v
}

// ---------------------------------------------------------------------------
// Team reviews (SOM §11.9.8): individual answers and applying conflicts.
// ---------------------------------------------------------------------------

/// Whether an answer carries anything beyond an option letter (SOM §11.9.8):
/// no letter, or text after it other than exactly that option's text.
fn is_commented_answer(answer: &str, options: &[SpecQuestionOption]) -> bool {
    let Some(letter) = leading_letter(answer) else {
        return true;
    };
    let t = answer.trim_start();
    let bold = t.starts_with("**(") && t.get(4..7) == Some(")**");
    let skip = if bold {
        7
    } else if t.starts_with("**") {
        5
    } else {
        3
    };
    let rest = t[skip..].trim();
    if rest.is_empty() {
        return false;
    }
    options
        .iter()
        .find(|o| o.letter == letter)
        .is_none_or(|o| rest != o.text)
}

/// The lines of one individual-answer entry.
/// A comment header's parentheses: the author and the change time, either
/// alone, or `None` when there is neither (SOM §11.9.10).
fn author_and_time(author: Option<&str>, changed_at: Option<&str>) -> Option<String> {
    match (author.filter(|a| !a.is_empty()), changed_at) {
        (None, t) => t.map(str::to_string),
        (Some(a), None) => Some(a.to_string()),
        (Some(a), Some(t)) => Some(format!("{}, {}", a, t)),
    }
}

fn individual_answer_lines(
    members: &[String],
    answer: &str,
    changed_at: Option<&str>,
) -> Vec<String> {
    let a: Vec<&str> = answer.split('\n').collect();
    let mut who = members.to_vec();
    who.extend(changed_at.map(str::to_string));
    let mut out = vec![format!("> **Answer ({}):** {}", who.join(", "), a[0])
        .trim_end()
        .to_string()];
    out.extend(quoted(&a[1..]));
    out
}

/// `value` with member `member`'s individual answer to question `q` set to
/// `answer` (SOM §11.9.8): the member leaves the line it was on (a line left
/// empty goes); a non-empty answer that is not commented joins the line
/// whose answer is identical and not commented, at its end, and otherwise
/// gets a new line after the last individual answer. The first individual
/// answer opens the run before the team's `**Answer:**`, with a `>` line
/// between run and team answer, and a run left empty takes that line with
/// it. Entries left alone keep their bytes. `changed_at` is the new entry's
/// change time (SOM §11.9.10); entries join only when answer and time are
/// equal.
fn set_individual_answer(
    value: &str,
    q: &Question,
    member: &str,
    answer: &str,
    changed_at: Option<&str>,
) -> String {
    let mut lines = split_lines(value);
    // (members, answer, its lines as written while untouched, change time)
    type Entry = (Vec<String>, String, Option<Vec<String>>, Option<String>);
    let mut entries: Vec<Entry> = q
        .answers
        .iter()
        .map(|a| {
            (
                a.members.clone(),
                a.answer.clone(),
                Some(lines[a.line..=a.end].to_vec()),
                a.changed_at.clone(),
            )
        })
        .collect();
    for e in &mut entries {
        if let Some(at) = e.0.iter().position(|m| m == member) {
            e.0.remove(at);
            e.2 = None;
        }
    }
    let mut kept: Vec<_> = entries.into_iter().filter(|e| !e.0.is_empty()).collect();
    let text = answer.trim();
    if !text.is_empty() {
        let join = if is_commented_answer(text, &q.options) {
            None
        } else {
            kept.iter_mut().find(|e| {
                e.1 == text
                    && e.3.as_deref() == changed_at
                    && !is_commented_answer(&e.1, &q.options)
            })
        };
        match join {
            Some(e) => {
                e.0.push(member.to_string());
                e.2 = None;
            }
            None => kept.push((
                vec![member.to_string()],
                text.to_string(),
                None,
                changed_at.map(str::to_string),
            )),
        }
    }
    let run: Vec<String> = kept
        .iter()
        .flat_map(|(members, answer, written, time)| {
            written
                .clone()
                .unwrap_or_else(|| individual_answer_lines(members, answer, time.as_deref()))
        })
        .collect();
    if let (Some(first), Some(last)) = (q.answers.first(), q.answers.last()) {
        let from = first.line;
        let mut to = last.end;
        // A run left empty takes its separating `>` line with it.
        if run.is_empty() && to + 1 < lines.len() && inner(&lines[to + 1]).trim().is_empty() {
            to += 1;
        }
        lines.splice(from..=to, run);
    } else if !run.is_empty() {
        match q.answer_line {
            Some(at) => {
                let mut ins = run;
                ins.push(">".to_string());
                lines.splice(at..at, ins);
            }
            None => {
                let mut last = q.region_end;
                while last > q.header && inner(&lines[last]).trim().is_empty() {
                    last -= 1;
                }
                let mut ins = vec![">".to_string()];
                ins.extend(run);
                lines.splice(last + 1..last + 1, ins);
            }
        }
    }
    lines.join("\n")
}

/// Topics of the structural conflicts a merge writes (SOM §11.9.9); their
/// decisions are not text.
const STRUCTURAL_TOPICS: [&str; 3] = ["Item removed", "Item moved", "Headline changed"];

/// A decided conflict, as `remove_all_annotations` found it before any
/// change.
struct DecidedConflict {
    path: String,
    field: Option<String>,
    /// The block's position among the value's conflict blocks.
    index: usize,
    id: String,
    line: usize,
    decision: String,
}

/// The text a conflict's decision chooses: the base, an alternative, or the
/// rewritten text.
fn chosen_text(c: &Conflict) -> String {
    match decision_letter(&c.decision).as_deref() {
        Some("base") => c.base.clone().unwrap_or_default(),
        Some(letter) => c
            .alternatives
            .iter()
            .find(|a| a.letter == letter)
            .map(|a| a.text.clone())
            .unwrap_or_default(),
        None => c.decision.clone(),
    }
}

/// Whether a conflict's text names a value path: no space or comma, and a
/// `/` with something on each side.
fn is_value_path(text: &str) -> bool {
    if text.chars().any(|c| c.is_whitespace() || c == ',') {
        return false;
    }
    text.char_indices()
        .any(|(i, c)| c == '/' && i > 0 && i + 1 < text.len())
}

/// The text paragraphs (no annotation block) of a parsed value, as
/// `(first, last)` lines.
fn text_paragraphs(p: &Parsed) -> Vec<(usize, usize)> {
    paragraphs(&p.lines, &p.code)
        .into_iter()
        .filter(|(s, _)| !p.blocks.iter().any(|b| b.start == *s))
        .collect()
}

/// `value` with the lines `[s, e]` replaced by `text`.
fn replace_lines(value: &str, s: usize, e: usize, text: &str) -> String {
    let mut lines = split_lines(value);
    lines.splice(s..=e, split_lines(text));
    lines.join("\n")
}

/// `value` with `text` inserted before block `b`.
fn insert_before_block(value: &str, b: &Block, text: &str) -> String {
    insert_after_line(value, b.start.checked_sub(1), &split_lines(text))
}

/// `value` with the text paragraph directly before block `b` (annotation
/// blocks between them skipped) replaced by `text`; with none, `text` goes
/// before the block.
fn replace_paragraph_before(value: &str, b: &Block, text: &str) -> String {
    let before: Vec<(usize, usize)> = text_paragraphs(&parse(value))
        .into_iter()
        .filter(|&(_, e)| e < b.start)
        .collect();
    match before.last() {
        None => insert_before_block(value, b, text),
        Some(&(s, e)) => replace_lines(value, s, e, text),
    }
}

/// `value` with the run of text paragraphs directly before block `b` — a
/// whole-value unit (SOM §11.9.9) — replaced by `text`.
fn replace_text_run(value: &str, b: &Block, text: &str) -> String {
    let p = parse(value);
    let paras: Vec<(usize, usize)> = paragraphs(&p.lines, &p.code)
        .into_iter()
        .filter(|&(_, e)| e < b.start)
        .collect();
    let mut k = paras.len();
    while k > 0 && !p.blocks.iter().any(|x| x.start == paras[k - 1].0) {
        k -= 1;
    }
    let run = &paras[k..];
    match (run.first(), run.last()) {
        (Some(&(s, _)), Some(&(_, e))) => replace_lines(value, s, e, text),
        _ => insert_before_block(value, b, text),
    }
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
            .chain(p.blocks.iter().flat_map(|b| {
                b.questions
                    .iter()
                    .map(|q| q.id.clone())
                    .chain(b.conflict.as_ref().and_then(|c| c.id.clone()))
            }))
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
    /// The clock the write operations take a change time from when no `at`
    /// is passed (SOM §11.9.10); `None`: the system clock.
    clock: Option<Box<dyn Fn() -> String + 'a>>,
}

type FoundQuestion = (String, Option<String>, String, Block, Question);
type FoundComment = (String, Option<String>, String, Comment);

impl<'a> SpecReviewAnnotations<'a> {
    /// Wraps `doc`, with bare comment ids.
    pub fn new(doc: &'a mut SpecDocument) -> SpecReviewAnnotations<'a> {
        SpecReviewAnnotations {
            doc,
            qualifier: None,
            clock: None,
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
            clock: None,
        }
    }

    /// Wraps `doc` like [`with_qualifier`](Self::with_qualifier); `clock`
    /// fixes the change time the writes record (SOM §11.9.10; the conformance
    /// drivers pass a fixed one).
    pub fn with_clock(
        doc: &'a mut SpecDocument,
        qualifier: Option<&str>,
        clock: impl Fn() -> String + 'a,
    ) -> SpecReviewAnnotations<'a> {
        SpecReviewAnnotations {
            doc,
            qualifier: qualifier.map(str::to_string),
            clock: Some(Box::new(clock)),
        }
    }

    /// The change time a write records: `at` normalized, else the clock's.
    fn change_time(&self, at: Option<&str>) -> Result<String, SpecReviewAnnotationError> {
        match (at, &self.clock) {
            (Some(t), _) => normalize_review_time(t),
            (None, Some(clock)) => Ok(clock()),
            (None, None) => Ok(system_review_time()),
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
                SpecReviewAnnotationKind::Conflict => {
                    out.conflicts += 1;
                    if a.is_open() {
                        out.open_conflicts += 1;
                    }
                }
            }
            if a.kind == SpecReviewAnnotationKind::Question && a.is_unresolved() {
                out.unresolved_questions += 1;
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
    /// its id — `id` when given, else the next free one. The header records
    /// `at` (an ISO 8601 time; `None`: the clock's) as the change time (SOM
    /// §11.9.10).
    #[allow(clippy::too_many_arguments)]
    pub fn insert_comment(
        &mut self,
        path: &str,
        field: Option<&str>,
        after_paragraph: i64,
        text: &str,
        author: Option<&str>,
        id: Option<&str>,
        at: Option<&str>,
    ) -> Result<String, SpecReviewAnnotationError> {
        let time = self.change_time(at)?;
        let cid = match id {
            Some(i) => i.to_string(),
            None => self.next_comment_id(0),
        };
        let value = self.get(path, field);
        let end = paragraph_last_line(&value, after_paragraph)?;
        let block = format_comment_block(&cid, text, author, Some(&time));
        self.set(path, field, &insert_after_line(&value, end, &block));
        Ok(cid)
    }

    /// The paragraphs of the value at `path` / `field`, in order — the units
    /// `after_paragraph` of [`Self::insert_comment`] and
    /// [`Self::insert_question`] counts. Fails when the document holds no such
    /// value.
    pub fn paragraphs(
        &self,
        path: &str,
        field: Option<&str>,
    ) -> Result<Vec<SpecParagraph>, SpecReviewAnnotationError> {
        let value = match field {
            None => self.doc.content(path),
            Some(f) => self.doc.form_field(path, f),
        }
        .cloned()
        .ok_or_else(|| {
            SpecReviewAnnotationError::new(match field {
                None => format!("no value at {path}"),
                Some(f) => format!("no value at {path} / {f}"),
            })
        })?;
        let p = parse(&value);
        Ok(paragraphs(&p.lines, &p.code)
            .into_iter()
            .enumerate()
            .map(|(i, (s, e))| SpecParagraph {
                index: i,
                start_line: s,
                end_line: e,
                text: p.lines[s..=e].join("\n"),
                annotation: p.blocks.iter().find(|b| b.start == s).map(|b| b.kind),
            })
            .collect())
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
        self.set_answer_by(question_id, answer, None, None)
    }

    /// Like [`set_answer`](Self::set_answer); with `author`, writes that
    /// member's individual answer instead, grouped and placed by the rules of
    /// SOM §11.9.8 (empty: only takes the member out). An author that is not
    /// a member id is refused. A member's non-empty answer records `at` (an
    /// ISO 8601 time; `None`: the clock's) as its change time (SOM §11.9.10).
    pub fn set_answer_by(
        &mut self,
        question_id: &str,
        answer: &str,
        author: Option<&str>,
        at: Option<&str>,
    ) -> Result<(), SpecReviewAnnotationError> {
        if let Some(a) = author {
            if !is_review_member_id(a) {
                return Err(SpecReviewAnnotationError::new(format!(
                    "\"{}\" is not a member id (lowercase letters, digits and _)",
                    a
                )));
            }
        }
        let (path, field, text, _b, q) = self.find_question(question_id)?;
        if let Some(a) = author {
            let time = if answer.trim().is_empty() {
                None
            } else {
                Some(self.change_time(at)?)
            };
            let written = set_individual_answer(&text, &q, a, answer, time.as_deref());
            self.set(&path, field.as_deref(), &written);
            return Ok(());
        }
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

    /// Replaces a comment's text; its marker, id and author stay as written,
    /// and the header records `at` (an ISO 8601 time; `None`: the clock's) as
    /// the change time (SOM §11.9.10).
    pub fn edit_comment(
        &mut self,
        comment_id: &str,
        text: &str,
        at: Option<&str>,
    ) -> Result<(), SpecReviewAnnotationError> {
        let time = self.change_time(at)?;
        let (path, field, value, c) = self.find_comment(comment_id)?;
        let mut lines = split_lines(&value);
        let t: Vec<&str> = text.split('\n').collect();
        let who = author_and_time(c.author.as_deref(), Some(&time)).unwrap_or_default();
        let mut block = vec![
            format!("{} ({}): {}", c.before_author.trim_end(), who, t[0])
                .trim_end()
                .to_string(),
        ];
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
        if index >= marks.len() {
            return Err(SpecReviewAnnotationError::new(format!(
                "no inline mark {} at {}{}",
                index,
                path,
                field.map(|f| format!(" / {}", f)).unwrap_or_default()
            )));
        }
        let out = decide_mark(&value, &marks, index, accept);
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

/// A mark found by id: its value and its index among the value's marks.
struct FoundMark {
    path: String,
    field: Option<String>,
    text: String,
    marks: Vec<Mark>,
    index: usize,
}

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
            let first = n + 1;
            let mark_id = |k: Option<usize>| k.map(|k| format!("M-{}", first + k));
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
                    comment: match &m.quote {
                        Some(q) => Some(q.comment.clone()),
                        None => m.comment.clone(),
                    },
                    markup: text[m.start..m.end].to_string(),
                    context: p.lines[s..=e].join("\n"),
                    authors: m.authors.clone(),
                    votes: m.votes.clone(),
                    quoted_change: m.quote.as_ref().map(Quote::to_json),
                    comment_id: mark_id(m.comment_index),
                    change_id: mark_id(m.change_index),
                    changed_at: m.changed_at.clone(),
                });
            }
        }
        out
    }

    /// Applies `decide` to every mark in the subtree `under` (`None`: the
    /// whole document), one write per value.
    fn apply_marks(
        &mut self,
        decide: impl Fn(&str, &Mark) -> Option<SpecMarkDecision>,
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
            let decided: Vec<Option<SpecMarkDecision>> = p
                .marks
                .iter()
                .enumerate()
                .map(|(k, m)| match decide(&ids[k], m) {
                    Some(SpecMarkDecision::Leave) => None,
                    d => d,
                })
                .collect();
            for (k, m) in p.marks.iter().enumerate().rev() {
                let Some(d) = decided[k] else { continue };
                let repl = mark_replacement(m, d == SpecMarkDecision::Accept);
                if let Some(ci) = m.comment_index {
                    if decided[ci].is_none() {
                        if let Some(q) = &p.marks[ci].quote {
                            v = record_outcome(&v, q, d == SpecMarkDecision::Accept);
                        }
                    }
                }
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
                v = replace_mark(&v, m, &repl, Some(d == SpecMarkDecision::Accept));
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
        Ok(self.apply_marks(|id, _| decisions.get(id).copied(), None))
    }

    /// Accepts every inline mark under `path` (`None`: the whole document),
    /// except change comments, which stay (SOM §11.9.3).
    pub fn accept_all_marks(&mut self, path: Option<&str>) -> SpecMarkReport {
        self.apply_marks(
            |_, m| m.quote.is_none().then_some(SpecMarkDecision::Accept),
            path,
        )
    }

    /// Rejects every inline mark under `path` (`None`: the whole document),
    /// except change comments, which stay (SOM §11.9.3).
    pub fn reject_all_marks(&mut self, path: Option<&str>) -> SpecMarkReport {
        self.apply_marks(
            |_, m| m.quote.is_none().then_some(SpecMarkDecision::Reject),
            path,
        )
    }

    /// The mark `M-<n>` `mark_id` with its value — path, field, text, its
    /// marks and its index among them — refused when the document is no
    /// longer at `revision` (when given) or holds no such mark.
    fn find_mark(
        &self,
        mark_id: &str,
        revision: Option<&str>,
    ) -> Result<FoundMark, SpecReviewAnnotationError> {
        if let Some(revision) = revision {
            let current = self.revision();
            if revision != current {
                return Err(SpecReviewAnnotationError::new(format!(
                    "the document changed since revision {} (now {}); list the marks again",
                    revision, current
                )));
            }
        }
        let mut n = 0;
        for (path, field, text) in values_of(self.doc) {
            let marks = parse(&text).marks;
            for k in 0..marks.len() {
                n += 1;
                if format!("M-{}", n) == mark_id {
                    return Ok(FoundMark {
                        path,
                        field,
                        text,
                        marks,
                        index: k,
                    });
                }
            }
        }
        Err(SpecReviewAnnotationError::new(format!(
            "no inline mark {} in the document",
            mark_id
        )))
    }

    /// Writes a change comment (SOM §11.9.3) directly after the change mark
    /// `mark_id`, its quote written from the mark and `text` after it, with
    /// an attribution token `{@author}` when `author` is given, and returns
    /// the new comment's id. Refused — nothing changes — for an unknown id, a
    /// stale `revision`, a mark that is not a change or already has an
    /// attached comment, a change its quote cannot hold, a `text` that is
    /// empty or holds a mark delimiter or a blank line, and an `author` that
    /// is not a member id.
    pub fn comment_change(
        &mut self,
        mark_id: &str,
        text: &str,
        author: Option<&str>,
        revision: Option<&str>,
        at: Option<&str>,
    ) -> Result<String, SpecReviewAnnotationError> {
        let time = self.change_time(at)?;
        let f = self.find_mark(mark_id, revision)?;
        let m = &f.marks[f.index];
        if !is_change_mark(m.kind) {
            return Err(SpecReviewAnnotationError::new(format!(
                "{} is a {} mark, not a change",
                mark_id,
                m.kind.name()
            )));
        }
        if m.comment_index.is_some() {
            return Err(SpecReviewAnnotationError::new(format!(
                "{} already has a comment; edit it instead",
                mark_id
            )));
        }
        let comment = check_inline_comment(text)?;
        if let Some(a) = author {
            if !is_review_member_id(a) {
                return Err(SpecReviewAnnotationError::new(format!(
                    "\"{}\" is not a member id",
                    a
                )));
            }
        }
        let d = match m.kind {
            SpecMarkKind::Insertion => "++",
            SpecMarkKind::Deletion => "--",
            _ => "~~",
        };
        let body = if m.kind == SpecMarkKind::Substitution {
            format!(
                "{} ~> {}",
                m.text,
                m.new_text.as_deref().unwrap_or_default()
            )
        } else {
            m.text.clone()
        };
        if body.contains(&format!("{}]", d)) || body.contains("<<}") {
            return Err(SpecReviewAnnotationError::new(format!(
                "{} holds \"{}]\" or \"<<}}\", which its quote cannot hold",
                mark_id, d
            )));
        }
        let authors: Vec<String> = author.map(str::to_string).into_iter().collect();
        let markup = format!(
            "{{>> [{d} {body} {d}] {comment} <<}}{}",
            format_attribution_token(&authors, &[], Some(&time))
        );
        let out = format!("{}{}{}", &f.text[..m.end], markup, &f.text[m.end..]);
        self.set(&f.path, f.field.as_deref(), &out);
        let n: u64 = mark_id[2..].parse().unwrap_or(0);
        Ok(format!("M-{}", n + 1))
    }

    /// Replaces the comment of the comment mark, change comment or commented
    /// highlight `mark_id` with `text` (SOM §11.9.3). A change comment keeps
    /// its quote as written, and the attribution token keeps its authors and
    /// votes and records `at` (an ISO 8601 time; `None`: the clock's) as the
    /// change time (SOM §11.9.10). Refused —
    /// nothing changes — for an unknown id, a stale `revision`, a mark that
    /// holds no comment, and a `text` that is empty or holds a mark delimiter
    /// or a blank line.
    pub fn edit_mark_comment(
        &mut self,
        mark_id: &str,
        text: &str,
        revision: Option<&str>,
        at: Option<&str>,
    ) -> Result<(), SpecReviewAnnotationError> {
        let time = self.change_time(at)?;
        let f = self.find_mark(mark_id, revision)?;
        let m = &f.marks[f.index];
        let comment = check_inline_comment(text)?;
        let markup = if m.kind == SpecMarkKind::Comment {
            match &m.quote {
                None => format!("{{>> {} <<}}", comment),
                Some(q) => format!(
                    "{{>> {} {} <<}}",
                    f.text[m.start + 3..q.end].trim_start(),
                    comment
                ),
            }
        } else if m.kind == SpecMarkKind::Highlight && m.comment.is_some() {
            format!("{{== {} ==}}{{>> {} <<}}", m.text, comment)
        } else {
            return Err(SpecReviewAnnotationError::new(format!(
                "{} holds no comment",
                mark_id
            )));
        };
        let token = format_attribution_token(&m.authors, &m.votes, Some(&time));
        let out = format!(
            "{}{}{}{}",
            &f.text[..m.start],
            markup,
            token,
            &f.text[m.end..]
        );
        self.set(&f.path, f.field.as_deref(), &out);
        Ok(())
    }

    /// Removes every annotation and writes the result back: every inline mark
    /// accepted, every conflict's decision applied (SOM §11.9.8), every
    /// comment, question and conflict block removed. Malformed marks stay and
    /// are reported. Refused — nothing changes — while a conflict is open,
    /// unresolved (`open:`), malformed, or decided for a letter it has no
    /// alternative for.
    pub fn remove_all_annotations(&mut self) -> Result<SpecMarkReport, SpecReviewAnnotationError> {
        let decided = self.decided_conflicts()?;
        let mut report = self.apply_marks(|_, _| Some(SpecMarkDecision::Accept), None);
        let mut outcomes = Vec::new();
        for (path, field, text) in values_of(self.doc) {
            let mut v = text.clone();
            let here: Vec<&DecidedConflict> = decided
                .iter()
                .filter(|d| d.path == path && d.field == field)
                .collect();
            if !here.is_empty() {
                v = self.apply_conflicts(&path, field.as_deref(), &v, &here, &mut outcomes);
            }
            loop {
                let p = parse(&v);
                let Some(b) = p.blocks.last() else { break };
                v = remove_lines(&v, b.start, b.end);
            }
            if v != text {
                self.set(&path, field.as_deref(), &v);
            }
        }
        report.conflicts = Some(outcomes);
        Ok(report)
    }

    /// Every conflict block of the document with the line it opens on, in
    /// document order — or the refusal of
    /// [`remove_all_annotations`](Self::remove_all_annotations) when one of
    /// them cannot be applied.
    fn decided_conflicts(&self) -> Result<Vec<DecidedConflict>, SpecReviewAnnotationError> {
        let mut out = Vec::new();
        for (path, field, text) in values_of(self.doc) {
            let p = parse(&text);
            let conflicts = p
                .blocks
                .iter()
                .filter_map(|b| b.conflict.as_ref().map(|c| (b, c)));
            for (index, (b, c)) in conflicts.enumerate() {
                let at = match &field {
                    None => format!("{}, line {}", path, b.start),
                    Some(f) => format!("{} / {}, line {}", path, f, b.start),
                };
                let id = match (&c.id, &c.base) {
                    (Some(id), Some(_)) if !c.alternatives.is_empty() => id.clone(),
                    _ => {
                        return Err(SpecReviewAnnotationError::new(format!(
                            "{}: a malformed conflict block cannot be applied",
                            at
                        )))
                    }
                };
                if c.decision.is_empty() || is_unresolved(&c.decision) {
                    return Err(SpecReviewAnnotationError::new(format!(
                        "{}: conflict {} is {}; decide it before removing the annotations",
                        at,
                        id,
                        if c.decision.is_empty() {
                            "open"
                        } else {
                            "unresolved"
                        }
                    )));
                }
                if let Some(letter) = decision_letter(&c.decision) {
                    if letter != "base" && !c.alternatives.iter().any(|a| a.letter == letter) {
                        return Err(SpecReviewAnnotationError::new(format!(
                            "{}: conflict {} has no alternative ({})",
                            at, id, letter
                        )));
                    }
                }
                out.push(DecidedConflict {
                    path: path.clone(),
                    field: field.clone(),
                    index,
                    id,
                    line: b.start,
                    decision: c.decision.clone(),
                });
            }
        }
        Ok(out)
    }

    /// Applies the decided conflicts of one value (marks already accepted),
    /// from the last block up so earlier line numbers stay valid, and records
    /// each. Where the chosen text goes follows the conflict's text (SOM
    /// §11.9.8, "Applying"): a form field, another value, this value's text
    /// paragraphs, or — the default — the text paragraph directly before the
    /// block.
    fn apply_conflicts(
        &mut self,
        path: &str,
        field: Option<&str>,
        value: &str,
        decided: &[&DecidedConflict],
        outcomes: &mut Vec<SpecConflictOutcome>,
    ) -> String {
        let mut v = value.to_string();
        let mut recorded = Vec::new();
        let parsed = parse(&v);
        let conflicts: Vec<(&Block, &Conflict)> = parsed
            .blocks
            .iter()
            .filter_map(|b| b.conflict.as_ref().map(|c| (b, c)))
            .collect();
        for (k, (b, c)) in conflicts.iter().enumerate().rev() {
            let Some(d) = decided.iter().find(|x| x.index == k) else {
                continue;
            };
            let result = chosen_text(c);
            recorded.insert(
                0,
                SpecConflictOutcome {
                    id: d.id.clone(),
                    path: path.to_string(),
                    field: field.map(str::to_string),
                    line: d.line,
                    decision: d.decision.clone(),
                    result: result.clone(),
                },
            );
            v = self.apply_conflict(path, field, &v, b, c, &result);
        }
        outcomes.extend(recorded);
        v
    }

    /// Puts one conflict's chosen text in place (see
    /// [`apply_conflicts`](Self::apply_conflicts)) and returns the value
    /// holding the block. A structural conflict only reports its decision:
    /// the structural change is the caller's.
    fn apply_conflict(
        &mut self,
        path: &str,
        field: Option<&str>,
        value: &str,
        b: &Block,
        c: &Conflict,
        result: &str,
    ) -> String {
        if STRUCTURAL_TOPICS.contains(&c.topic.as_str()) {
            return value.to_string();
        }
        let words: Vec<&str> = c.text.split(' ').collect();
        let no_space = |w: &str| !w.is_empty() && !w.chars().any(char::is_whitespace);
        if words.len() == 2
            && words.iter().all(|w| no_space(w))
            && self.doc.form_field(words[0], words[1]).is_some()
        {
            self.doc.set_form_field(words[0], words[1], result);
            return value.to_string();
        }
        if field.is_none() && c.text == path {
            return replace_text_run(value, b, result);
        }
        if is_value_path(&c.text) && c.text != path {
            self.doc.set_content(&c.text, result);
            return value.to_string();
        }
        replace_paragraph_before(value, b, result)
    }

    /// Writes `text` at `path` / `field` as a marked change against the value
    /// there now (SOM §11.9.3). A value that already holds change marks is
    /// compared from its original — every mark rejected — so a second edit of
    /// the same passage updates its mark instead of nesting one. Change
    /// comments stay: each is taken out of the original and written back
    /// after the same number of non-whitespace characters (SOM §11.9.3).
    /// Every change mark gets an attribution token (SOM §11.9.10): the one it
    /// had when the change was there before, else `{@author T}` (T: `at`, an
    /// ISO 8601 time, or the clock's). An author that is not a member id and
    /// an invalid `at` are refused; nothing changes.
    pub fn set_marked(
        &mut self,
        path: &str,
        field: Option<&str>,
        text: &str,
        author: Option<&str>,
        at: Option<&str>,
    ) -> Result<SpecMarkedChange, SpecReviewAnnotationError> {
        check_author(author)?;
        let time = self.change_time(at)?;
        let current = self.get(path, field);
        let result = mark_keeping_change_comments(&current, text);
        let stamped = SpecMarkedChange {
            text: stamp_marks(&current, &result.text, author, &time),
            exact: result.exact,
        };
        self.set(path, field, &stamped.text);
        Ok(stamped)
    }

    /// Marks the value at `path` / `field` as a change against `earlier`, an
    /// earlier version of it; `author` and `at` as for
    /// [`set_marked`](Self::set_marked).
    pub fn mark_against(
        &mut self,
        path: &str,
        field: Option<&str>,
        earlier: &str,
        author: Option<&str>,
        at: Option<&str>,
    ) -> Result<SpecMarkedChange, SpecReviewAnnotationError> {
        check_author(author)?;
        let time = self.change_time(at)?;
        let current = self.get(path, field);
        let result = mark_change_text(earlier, &current);
        let stamped = SpecMarkedChange {
            text: stamp_marks(&current, &result.text, author, &time),
            exact: result.exact,
        };
        self.set(path, field, &stamped.text);
        Ok(stamped)
    }
}

/// Refuses an author that is not a member id.
fn check_author(author: Option<&str>) -> Result<(), SpecReviewAnnotationError> {
    match author {
        Some(a) if !is_review_member_id(a) => Err(SpecReviewAnnotationError::new(format!(
            "\"{}\" is not a member id (lowercase letters, digits and _)",
            a
        ))),
        _ => Ok(()),
    }
}

/// `after` (a value just written as marks) with an attribution token on every
/// change mark it lacks one on (SOM §11.9.10): the token of the same change
/// in `before` (same kind, old and new text; each used once, in order) when
/// `before` held it, else a new one with `author` and `time`.
fn stamp_marks(before: &str, after: &str, author: Option<&str>, time: &str) -> String {
    let key = |m: &Mark| {
        format!(
            "{}\u{0}{}\u{0}{}",
            m.kind.name(),
            mark_replacement(m, false),
            mark_replacement(m, true)
        )
    };
    let old: Vec<(String, &str)> = parse(before)
        .marks
        .iter()
        .filter(|m| is_change_mark(m.kind))
        .map(|m| (key(m), &before[m.body_end..m.end]))
        .collect();
    let mut used = vec![false; old.len()];
    let authors: Vec<String> = author.map(str::to_string).into_iter().collect();
    let fresh = format_attribution_token(&authors, &[], Some(time));
    let mut inserts: Vec<(usize, String)> = Vec::new();
    for m in &parse(after).marks {
        if !is_change_mark(m.kind) || m.end > m.body_end {
            continue;
        }
        let k = key(m);
        let mut token = fresh.clone();
        if let Some(i) = (0..old.len()).find(|&i| !used[i] && old[i].0 == k) {
            used[i] = true;
            token = old[i].1.to_string();
        }
        if !token.is_empty() {
            inserts.push((m.body_end, token));
        }
    }
    let mut v = after.to_string();
    for (at, token) in inserts.iter().rev() {
        v.insert_str(*at, token);
    }
    v
}

// ---------------------------------------------------------------------------
// Writing changes as inline marks (SOM §11.9.3, annot5).
// ---------------------------------------------------------------------------

/// A value written as a marked change.
#[derive(Debug, Clone, PartialEq)]
pub struct SpecMarkedChange {
    /// The value with every difference marked.
    pub text: String,
    /// Whether accepting the marks gives exactly the new value and rejecting
    /// them exactly the old one. False when a difference cannot be marked — a
    /// change inside fenced code, or text that holds mark delimiters — and the
    /// new value was written unmarked instead.
    pub exact: bool,
}

impl SpecMarkedChange {
    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        json_obj(vec![
            ("text", json_str(&self.text)),
            ("exact", Json::Bool(self.exact)),
        ])
    }
}

/// One token of a value: a run of whitespace, a word (a run of non-whitespace
/// with inline code spans kept whole) or a fenced code block (its lines).
#[derive(Debug, Clone)]
struct Tok {
    text: String,
    space: bool,
}

fn is_ws(c: u8) -> bool {
    c == b' ' || c == b'\t' || c == b'\n'
}

fn tok_add(out: &mut Vec<Tok>, t: &str, space: bool) {
    if t.is_empty() {
        return;
    }
    if space {
        if let Some(last) = out.last_mut() {
            if last.space {
                last.text.push_str(t);
                return;
            }
        }
    }
    out.push(Tok {
        text: t.to_string(),
        space,
    });
}

fn tok_words(out: &mut Vec<Tok>, s: &str) {
    let b = s.as_bytes();
    let mut i = 0;
    while i < b.len() {
        if is_ws(b[i]) {
            let st = i;
            while i < b.len() && is_ws(b[i]) {
                i += 1;
            }
            tok_add(out, &s[st..i], true);
            continue;
        }
        let st = i;
        while i < b.len() && !is_ws(b[i]) {
            if b[i] == b'`' {
                let mut n = 0;
                while i + n < b.len() && b[i + n] == b'`' {
                    n += 1;
                }
                // The matching run of exactly n backticks ends the span.
                let mut j = i + n;
                let mut close = None;
                while j < b.len() {
                    if b[j] == b'`' {
                        let mut m = 0;
                        while j + m < b.len() && b[j + m] == b'`' {
                            m += 1;
                        }
                        if m == n {
                            close = Some(j);
                            break;
                        }
                        j += m;
                    } else {
                        j += 1;
                    }
                }
                i = match close {
                    None => i + n,
                    Some(c) => c + n,
                };
                continue;
            }
            i += 1;
        }
        tok_add(out, &s[st..i], false);
    }
}

fn tokens(value: &str) -> Vec<Tok> {
    let mut out = Vec::new();
    let lines = split_lines(value);
    let code = code_lines(&lines);
    let mut k = 0;
    while k < lines.len() {
        if k > 0 {
            tok_add(&mut out, "\n", true);
        }
        let st = k;
        let is_code = code[k];
        while k + 1 < lines.len() && code[k + 1] == is_code {
            k += 1;
        }
        let run = lines[st..k + 1].join("\n");
        if is_code {
            tok_add(&mut out, &run, false);
        } else {
            tok_words(&mut out, &run);
        }
        k += 1;
    }
    out
}

/// The diff of two token lists as ops: 0 keep, 1 delete (old), 2 insert
/// (new), with their tokens. LCS over token text; ties prefer the deletion.
fn diff(a: &[Tok], b: &[Tok]) -> Vec<(u8, Tok)> {
    let (n, m) = (a.len(), b.len());
    let mut l = vec![vec![0usize; m + 1]; n + 1];
    for i in (0..n).rev() {
        for j in (0..m).rev() {
            l[i][j] = if a[i].text == b[j].text {
                l[i + 1][j + 1] + 1
            } else if l[i + 1][j] >= l[i][j + 1] {
                l[i + 1][j]
            } else {
                l[i][j + 1]
            };
        }
    }
    let mut ops = Vec::new();
    let (mut i, mut j) = (0, 0);
    while i < n || j < m {
        if i < n && j < m && a[i].text == b[j].text {
            ops.push((0, a[i].clone()));
            i += 1;
            j += 1;
        } else if j >= m || (i < n && l[i + 1][j] >= l[i][j + 1]) {
            ops.push((1, a[i].clone()));
            i += 1;
        } else {
            ops.push((2, b[j].clone()));
            j += 1;
        }
    }
    ops
}

/// `s` with its leading and trailing whitespace removed (spaces, tabs,
/// newlines).
fn trim_ws(s: &str) -> &str {
    s.trim_matches([' ', '\t', '\n'])
}

/// The markup for one region whose old text is `o` and new text is `n` (both
/// trimmed, not both empty).
fn markup(o: &str, n: &str) -> String {
    if o.is_empty() {
        format!("{{++ {} ++}}", n)
    } else if n.is_empty() {
        format!("{{-- {} --}}", o)
    } else {
        format!("{{~~ {} ~> {} ~~}}", o, n)
    }
}

fn lead_ws(x: &str) -> &str {
    &x[..x.len() - x.trim_start().len()]
}

fn trail_ws(x: &str) -> &str {
    &x[x.trim_end().len()..]
}

/// The marked emission for the region `[r0, r1)` of `ops`, with the old and
/// the new text around it, or `None` when no mark round-trips there.
#[allow(clippy::too_many_arguments)]
fn emit_region(
    ops: &[(u8, Tok)],
    r0: usize,
    r1: usize,
    old_before: &str,
    new_before: &str,
    old_after: &str,
    new_after: &str,
) -> Option<String> {
    let mut os = String::new();
    let mut ns = String::new();
    for (kind, t) in &ops[r0..r1] {
        if *kind != 2 {
            os.push_str(&t.text);
        }
        if *kind != 1 {
            ns.push_str(&t.text);
        }
    }
    let (ob, nb) = (os.as_bytes(), ns.as_bytes());
    // Whitespace the two sides share at the edges stays outside the mark.
    let mut lead = 0;
    while lead < ob.len() && lead < nb.len() && ob[lead] == nb[lead] && is_ws(ob[lead]) {
        lead += 1;
    }
    let mut trail = 0;
    while trail < ob.len() - lead
        && trail < nb.len() - lead
        && ob[ob.len() - 1 - trail] == nb[nb.len() - 1 - trail]
        && is_ws(ob[ob.len() - 1 - trail])
    {
        trail += 1;
    }
    let oi = &os[lead..os.len() - trail];
    let ni = &ns[lead..ns.len() - trail];
    // The mark's content is trimmed when read, so it must already be trimmed;
    // the whitespace still differing is placed outside, on the side whose
    // text keeps it, and the tidy rules then have to restore the other side.
    let (ot, nt) = (trim_ws(oi), trim_ws(ni));
    if ot.is_empty() && nt.is_empty() {
        return None;
    }
    let pre = &os[..lead];
    let post = &os[os.len() - trail..];
    let candidates = [
        (lead_ws(ni), trail_ws(ni)),
        (lead_ws(oi), trail_ws(oi)),
        ("", ""),
        (lead_ws(ni), ""),
        ("", trail_ws(ni)),
    ];
    let mk = markup(ot, nt);
    for (wl, wr) in candidates {
        let emission = format!("{}{}{}{}{}", pre, wl, mk, wr, post);
        let acc =
            apply_inline_marks_text(&format!("{}{}{}", new_before, emission, new_after), true);
        let rej =
            apply_inline_marks_text(&format!("{}{}{}", old_before, emission, old_after), false);
        if acc == format!("{}{}{}", new_before, ns, new_after)
            && rej == format!("{}{}{}", old_before, os, old_after)
        {
            return Some(emission);
        }
    }
    None
}

/// Marks the token-level differences of `o` → `n`, where the text before
/// them is `ob` (old) / `nb` (new) and after them `oa` / `na`. `None` when
/// the marks do not round-trip.
fn mark_tokens(o: &str, n: &str, ob: &str, nb: &str, oa: &str, na: &str) -> Option<String> {
    let ops = diff(&tokens(o), &tokens(n));
    let mut runs: Vec<(usize, usize)> = Vec::new();
    let mut k = 0;
    while k < ops.len() {
        if ops[k].0 == 0 {
            k += 1;
            continue;
        }
        let s = k;
        while k < ops.len() && ops[k].0 != 0 {
            k += 1;
        }
        runs.push((s, k));
    }
    // Changes separated by at most two unchanged words are one mark.
    let mut merged: Vec<(usize, usize)> = Vec::new();
    for r in runs {
        if let Some(last) = merged.last_mut() {
            let words = (last.1..r.0).filter(|&q| !ops[q].1.space).count();
            if words <= 2 {
                last.1 = r.1;
                continue;
            }
        }
        merged.push(r);
    }
    let runs = merged;

    let side = |from: usize, to: usize, skip: u8| -> String {
        let mut b = String::new();
        for (kind, t) in &ops[from..to] {
            if *kind != skip {
                b.push_str(&t.text);
            }
        }
        b
    };

    // Left to right; a region that does not round-trip grows by one token on
    // each side and is tried again.
    let end = ops.len();
    let mut out = String::new();
    let mut pos = 0;
    let mut ri = 0;
    while ri < runs.len() {
        let (mut r0, mut r1) = runs[ri];
        if r0 < pos {
            r0 = pos;
        }
        let emission = loop {
            let e = emit_region(
                &ops,
                r0,
                r1,
                &format!("{}{}", ob, side(0, r0, 2)),
                &format!("{}{}", nb, side(0, r0, 1)),
                &format!("{}{}", side(r1, end, 2), oa),
                &format!("{}{}", side(r1, end, 1), na),
            );
            if e.is_some() || (r0 <= pos && r1 >= end) {
                break e;
            }
            if r0 > pos {
                r0 -= 1;
            }
            if r1 < end {
                r1 += 1;
            }
        };
        let emission = emission?;
        out.push_str(&side(pos, r0, 1));
        out.push_str(&emission);
        pos = r1;
        while ri + 1 < runs.len() && runs[ri + 1].1 <= pos {
            ri += 1;
        }
        ri += 1;
    }
    out.push_str(&side(pos, end, 1));
    if apply_inline_marks_text(&format!("{}{}{}", nb, out, na), true)
        != format!("{}{}{}", nb, n, na)
        || apply_inline_marks_text(&format!("{}{}{}", ob, out, oa), false)
            != format!("{}{}{}", ob, o, oa)
    {
        return None;
    }
    Some(out)
}

/// A whole line marked as inserted (`++`) or deleted (`--`): its indentation
/// stays outside the mark; a blank line stays blank.
fn line_mark(line: &str, d: &str) -> String {
    let body = line.trim_start();
    if body.trim().is_empty() {
        return line.to_string();
    }
    let indent = &line[..line.len() - body.len()];
    format!("{}{{{} {} {}}}", indent, d, body.trim_end(), d)
}

/// `new_value` with its differences from `old_value` marked, so that
/// accepting every mark gives exactly `new_value` and rejecting every mark
/// exactly `old_value` (SOM §11.9.3). The diff runs by line, then by word
/// inside a changed run of lines; words are never split, changes separated
/// by at most two unchanged words are one mark, and nothing inside code is
/// marked.
pub fn mark_change_text(old_value: &str, new_value: &str) -> SpecMarkedChange {
    if old_value == new_value {
        return SpecMarkedChange {
            text: new_value.to_string(),
            exact: true,
        };
    }
    let ol = split_lines(old_value);
    let nl = split_lines(new_value);
    let (oc, nc) = (code_lines(&ol), code_lines(&nl));
    let as_toks = |ls: &[String]| -> Vec<Tok> {
        ls.iter()
            .map(|l| Tok {
                text: l.clone(),
                space: false,
            })
            .collect()
    };
    let lops = diff(&as_toks(&ol), &as_toks(&nl));
    let join = |parts: &[&[String]]| -> String { parts.concat().join("\n") };
    let blank = |l: &String| l.trim().is_empty();
    let mut out: Vec<String> = Vec::new();
    let mut exact = true;
    let (mut oi, mut ni, mut k) = (0, 0, 0);
    while k < lops.len() {
        if lops[k].0 == 0 {
            out.push(nl[ni].clone());
            oi += 1;
            ni += 1;
            k += 1;
            continue;
        }
        let (d0, n0) = (oi, ni);
        while k < lops.len() && lops[k].0 != 0 {
            if lops[k].0 == 1 {
                oi += 1;
            } else {
                ni += 1;
            }
            k += 1;
        }
        let (del, ins) = (&ol[d0..oi], &nl[n0..ni]);
        let (ob, oa) = (&ol[..d0], &ol[oi..]);
        let (nb, na) = (&nl[..n0], &nl[ni..]);
        let round_trips = |e: &[String]| {
            apply_inline_marks_text(&join(&[nb, e, na]), true) == new_value
                && apply_inline_marks_text(&join(&[ob, e, oa]), false) == old_value
        };
        let mut emitted: Option<Vec<String>> = None;
        let in_code = oc[d0..oi].iter().chain(nc[n0..ni].iter()).any(|&c| c);
        if !in_code {
            let mut candidates: Vec<Vec<String>> = Vec::new();
            if !del.is_empty() && !ins.is_empty() {
                let before = |ls: &[String]| {
                    if ls.is_empty() {
                        String::new()
                    } else {
                        format!("{}\n", ls.join("\n"))
                    }
                };
                let after = |ls: &[String]| {
                    if ls.is_empty() {
                        String::new()
                    } else {
                        format!("\n{}", ls.join("\n"))
                    }
                };
                if let Some(t) = mark_tokens(
                    &del.join("\n"),
                    &ins.join("\n"),
                    &before(ob),
                    &before(nb),
                    &after(oa),
                    &after(na),
                ) {
                    candidates.push(split_lines(&t));
                }
            }
            let dm: Vec<String> = del.iter().map(|l| line_mark(l, "--")).collect();
            let im: Vec<String> = ins.iter().map(|l| line_mark(l, "++")).collect();
            let dmb: Vec<String> = dm.iter().filter(|l| !blank(l)).cloned().collect();
            let imb: Vec<String> = im.iter().filter(|l| !blank(l)).cloned().collect();
            candidates.push([dm.clone(), im.clone()].concat());
            candidates.push([dmb.clone(), im].concat());
            candidates.push([dm, imb.clone()].concat());
            candidates.push([dmb, imb].concat());
            emitted = candidates.into_iter().find(|e| round_trips(e));
        }
        match emitted {
            None => {
                exact = false;
                out.extend(ins.iter().cloned());
            }
            Some(e) => out.extend(e),
        }
    }
    let text = out.join("\n");
    if exact
        && (apply_inline_marks_text(&text, true) != new_value
            || apply_inline_marks_text(&text, false) != old_value)
    {
        return SpecMarkedChange {
            text: new_value.to_string(),
            exact: false,
        };
    }
    SpecMarkedChange { text, exact }
}

// ---------------------------------------------------------------------------
// Text-level building blocks of the merge (SOM §11.9.9). Crate-internal: used
// by `spec_review_merge`, not part of the public API.
// ---------------------------------------------------------------------------

/// One paragraph of a value as the merge sees it: text, or an annotation
/// block.
#[derive(Debug, Clone)]
pub(crate) struct ReviewPiece {
    /// The annotation kind of the block the paragraph opens with; `None` for
    /// a text paragraph.
    pub(crate) kind: Option<SpecReviewAnnotationKind>,
    /// The paragraph's lines, verbatim.
    pub(crate) text: String,
    /// A comment's id (`None` without one), a conflict's id (`None` when
    /// malformed).
    pub(crate) id: Option<String>,
    /// A comment's author, `None` without one.
    pub(crate) author: Option<String>,
    /// A comment's text.
    pub(crate) comment_text: String,
    /// A comment's change time (SOM §11.9.10), `None` without one.
    pub(crate) changed_at: Option<String>,
    /// The ids of a question block's questions.
    pub(crate) question_ids: Vec<String>,
}

/// The paragraphs of `value` (SOM §11.9.1), each classified.
pub(crate) fn review_pieces(value: &str) -> Vec<ReviewPiece> {
    if value.is_empty() {
        return Vec::new();
    }
    let p = parse(value);
    paragraphs(&p.lines, &p.code)
        .into_iter()
        .map(|(s, e)| {
            let b = p.blocks.iter().find(|x| x.start == s);
            let comment = p.comments.iter().find(|c| c.block_start == s);
            ReviewPiece {
                kind: b.map(|b| b.kind),
                text: p.lines[s..=e].join("\n"),
                id: comment.and_then(|c| c.id.clone()).or_else(|| {
                    b.and_then(|b| b.conflict.as_ref())
                        .and_then(|c| c.id.clone())
                }),
                author: comment.and_then(|c| c.author.clone()),
                comment_text: comment.map(|c| c.text.clone()).unwrap_or_default(),
                changed_at: comment.and_then(|c| c.changed_at.clone()),
                question_ids: b
                    .map(|b| b.questions.iter().map(|q| q.id.clone()).collect())
                    .unwrap_or_default(),
            }
        })
        .collect()
}

/// One inline mark of a value, with what its decisions leave.
#[derive(Debug, Clone)]
pub(crate) struct ReviewMark {
    /// Where the mark (its token included) ends in the value.
    pub(crate) end: usize,
    /// Where the mark itself ends, before its token.
    pub(crate) body_end: usize,
    pub(crate) kind: SpecMarkKind,
    /// The mark as written, its attribution token included.
    pub(crate) markup: String,
    pub(crate) authors: Vec<String>,
    pub(crate) votes: Vec<SpecMarkVote>,
    /// Its token's change time (SOM §11.9.10), or `None`.
    pub(crate) changed_at: Option<String>,
    /// The text accepting it leaves.
    pub(crate) accepted: String,
    /// The text rejecting it leaves.
    pub(crate) rejected: String,
}

/// The inline marks of `value`, in order (marks in code are not marks).
pub(crate) fn review_marks(value: &str) -> Vec<ReviewMark> {
    parse(value)
        .marks
        .into_iter()
        .map(|m| ReviewMark {
            end: m.end,
            body_end: m.body_end,
            kind: m.kind,
            markup: value[m.start..m.end].to_string(),
            accepted: mark_replacement(&m, true),
            rejected: mark_replacement(&m, false),
            authors: m.authors,
            votes: m.votes,
            changed_at: m.changed_at,
        })
        .collect()
}

/// `value` with the marks `decisions` names (by index into
/// [`review_marks`]) accepted (`true`) or rejected, by the whitespace rules of
/// SOM §11.9.3.
pub(crate) fn decide_review_marks(value: &str, decisions: &HashMap<usize, bool>) -> String {
    let marks = parse(value).marks;
    let mut v = value.to_string();
    for (k, m) in marks.iter().enumerate().rev() {
        if let Some(&accept) = decisions.get(&k) {
            v = replace_mark(&v, m, &mark_replacement(m, accept), Some(accept));
        }
    }
    v
}

/// The attribution token for `authors`, `votes` and `changed_at`,
/// `{@agent +alice -bob 2026-11-07T14:05+01:00}` (SOM §11.9.8, §11.9.10);
/// empty when there is nothing to write.
pub(crate) fn format_attribution_token(
    authors: &[String],
    votes: &[SpecMarkVote],
    changed_at: Option<&str>,
) -> String {
    let mut parts: Vec<String> = Vec::new();
    if !authors.is_empty() {
        parts.push(authors.join(","));
    }
    parts.extend(
        votes
            .iter()
            .map(|x| format!("{}{}", if x.accept { '+' } else { '-' }, x.member)),
    );
    parts.extend(changed_at.map(str::to_string));
    if parts.is_empty() {
        String::new()
    } else {
        format!("{{@{}}}", parts.join(" "))
    }
}

/// `value` with mark `m`'s token replaced by one for `authors` and `votes`;
/// its change time stays.
pub(crate) fn with_attribution(
    value: &str,
    m: &ReviewMark,
    authors: &[String],
    votes: &[SpecMarkVote],
) -> String {
    format!(
        "{}{}{}",
        &value[..m.body_end],
        format_attribution_token(authors, votes, m.changed_at.as_deref()),
        &value[m.end..]
    )
}

/// The team answer of every question of `value`, by id, in order (the first
/// of a repeated id).
pub(crate) fn review_team_answers(value: &str) -> Vec<(String, String)> {
    let mut out: Vec<(String, String)> = Vec::new();
    for b in parse(value).blocks {
        for q in b.questions {
            if !out.iter().any(|(id, _)| *id == q.id) {
                out.push((q.id, q.answer));
            }
        }
    }
    out
}

/// `value` with `member`'s individual answer to question `question_id` set,
/// as `set_answer_by` with an author does, with `changed_at` as its change
/// time; `None` when the value holds no such question.
pub(crate) fn set_individual_answer_text(
    value: &str,
    question_id: &str,
    member: &str,
    answer: &str,
    changed_at: Option<&str>,
) -> Option<String> {
    let p = parse(value);
    let q = p
        .blocks
        .iter()
        .flat_map(|b| b.questions.iter())
        .find(|q| q.id == question_id)?;
    Some(set_individual_answer(value, q, member, answer, changed_at))
}

/// The lines of a conflict's text: the first after its prefix, the rest
/// indented under it.
fn alternative_lines(prefix: &str, text: &str) -> Vec<String> {
    let t: Vec<&str> = text.split('\n').collect();
    let mut out = vec![format!("> - {} {}", prefix, t[0]).trim_end().to_string()];
    out.extend(t[1..].iter().map(|l| format!(">   {}", l)));
    out
}

/// The lines of a conflict block (SOM §11.9.8): the header, the `(base)`
/// line, one lettered alternative per entry naming its members, and an empty
/// `**Decision:**`. A text's further lines are indented under it, so a reader
/// gets them back with their line breaks.
pub fn format_conflict_block(
    id: &str,
    topic: &str,
    text: &str,
    base: &str,
    alternatives: &[SpecConflictAlternative],
) -> Vec<String> {
    let mut out = vec![format!(
        "> {}{} **{}{}{}:** {}",
        SCALES, VS16, id, EM_DASH_SEP, topic, text
    )
    .trim_end()
    .to_string()];
    out.extend(alternative_lines("(base)", base));
    for a in alternatives {
        let prefix = format!("({}) **{}:**", a.letter, a.members.join(", "));
        out.extend(alternative_lines(&prefix, &a.text));
    }
    out.push(">".to_string());
    out.push(format!("> {}", DECISION_LABEL));
    out
}

/// Carries the edits `x` → `y` over to `b`, a text equal to `x` except where
/// marks of `b` were decided in `x` (SOM §11.9.9, step 3): every edit lands
/// in `b` at the place `x` and `b` agree on. `None` when an edit touches or
/// borders a place where they differ — the edit overlaps a decided mark. Both
/// diffs are the token diffs of `mark_change_text`.
pub(crate) fn transplant_edits(x: &str, y: &str, b: &str) -> Option<String> {
    let xt = tokens(x);
    let bt = tokens(b);
    // Where each token of x is in b (`None`: x and b differ there).
    let mut to_b: Vec<Option<usize>> = vec![None; xt.len()];
    let (mut i, mut j) = (0, 0);
    for (kind, _) in diff(&xt, &bt) {
        match kind {
            0 => {
                to_b[i] = Some(j);
                i += 1;
                j += 1;
            }
            1 => i += 1,
            _ => j += 1,
        }
    }
    // The edits x → y as (first x token, end x token, inserted text).
    let mut hunks: Vec<(usize, usize, String)> = Vec::new();
    let mut i = 0;
    let mut open: Option<(usize, usize, String)> = None;
    for (kind, t) in diff(&xt, &tokens(y)) {
        if kind == 0 {
            if let Some(h) = open.take() {
                hunks.push(h);
            }
            i += 1;
            continue;
        }
        let h = open.get_or_insert_with(|| (i, i, String::new()));
        if kind == 1 {
            i += 1;
            h.1 = i;
        } else {
            h.2.push_str(&t.text);
        }
    }
    if let Some(h) = open {
        hunks.push(h);
    }
    let mut out: Vec<String> = bt.iter().map(|t| t.text.clone()).collect();
    for (x0, x1, ins) in hunks.into_iter().rev() {
        let (from, to) = landing(&to_b, x0, x1, bt.len())?;
        out.splice(from..to, [ins]);
    }
    Some(out.concat())
}

/// The b-token range an x-token range `[x0, x1)` lands on, or `None` when it
/// is not one.
///
/// A replaced range lands where its tokens are in b, which must be
/// contiguous there; its neighbours are not consulted, because the token
/// diff may align a neighbouring space with another space of b (beside a
/// decided mark) without the range touching that mark. A pure insertion
/// (`x0 == x1`) has no tokens of its own, so both neighbours must sit next
/// to each other in b.
fn landing(to_b: &[Option<usize>], x0: usize, x1: usize, b_len: usize) -> Option<(usize, usize)> {
    if x1 > x0 {
        let first = to_b[x0]?;
        for k in x0 + 1..x1 {
            if to_b[k]? != to_b[k - 1]? + 1 {
                return None;
            }
        }
        return Some((first, to_b[x1 - 1]? + 1));
    }
    // A pure insertion: its neighbours must sit next to each other in b.
    let left = if x0 == 0 {
        Some(0)
    } else {
        to_b[x0 - 1].map(|l| l + 1)
    };
    let right = if x1 == to_b.len() {
        Some(b_len)
    } else {
        to_b[x1]
    };
    match (left, right) {
        (Some(from), Some(to)) if from == to => Some((from, from)),
        _ => None,
    }
}
