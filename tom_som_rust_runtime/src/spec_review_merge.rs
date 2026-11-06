//! `spec_review_merge` — merging the reviewed copies of a team review (SOM
//! §11.9.9) into one document in the team notation of §11.9.8: who proposed,
//! voted for and answered what, and where two members changed the same
//! passage differently. A port of the TypeScript runtime's
//! `spec_review_merge.ts`.
//!
//! [`merge_reviews`] merges a SOM document ([`SpecDocument`], by model path,
//! list items matched by section id) and [`merge_reviews_markdown`] a plain
//! annotated Markdown file (by heading path). Both share one engine that works
//! value by value; only the way values are found, and the SOM-only structure
//! and revision entry, differ.
//!
//! The engine is built on the review-annotation building blocks: the
//! paragraph split and the mark decisions of
//! [`SpecReviewAnnotations`](crate::SpecReviewAnnotations),
//! [`mark_change_text`] for edits written as plain text, the
//! individual-answer rules of `set_answer_by`, and the list-item id
//! generation of [`generate_list_item_section_id`].

use std::collections::{BTreeMap, HashMap, HashSet};

use crate::json::Json;
use crate::spec_document::SpecDocument;
use crate::spec_document_markdown::MarkdownFenceTracker;
use crate::spec_model::{
    FormFieldSpec, SpecClass, SpecField, SpecModel, SPEC_FIELD_KIND_COMPLEX,
    SPEC_FIELD_KIND_CONTENT, SPEC_FIELD_KIND_FORM, SPEC_FIELD_KIND_LIST, SPEC_FIELD_KIND_SECTION,
};
use crate::spec_paths::spec_parent_path;
use crate::spec_reflection::{
    SpecReflection, SPEC_NODE_KIND_CONTENT, SPEC_NODE_KIND_ENUM_VALUE, SPEC_NODE_KIND_FORM,
    SPEC_NODE_KIND_LIST_ITEM_SCALAR, SPEC_NODE_KIND_SCALAR,
};
use crate::spec_review_annotations::{
    apply_inline_marks_text, decide_review_marks, format_comment_block, format_conflict_block,
    format_question_block, mark_change_text, review_marks, review_pieces, review_team_answers,
    set_individual_answer_text, transplant_edits, with_attribution, ReviewMark, ReviewPiece,
    SpecConflictAlternative, SpecMarkKind, SpecMarkVote, SpecQuestionDraft,
    SpecReviewAnnotationKind,
};
use crate::spec_section_id::{effective_list_item_section_id, generate_list_item_section_id};

// ---------------------------------------------------------------------------
// Inputs, report and result.
// ---------------------------------------------------------------------------

/// A member of a review team (SOM §11.9.8).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecReviewMember {
    /// The member id: lowercase letters, digits and `_`.
    pub member_id: String,
    /// The name a tool shows.
    pub display_name: String,
    /// The member's role in the round; may be empty.
    pub role: String,
}

/// One returned copy: its reviewer and the copy's document.
#[derive(Debug, Clone)]
pub struct SpecReviewedCopy<D> {
    /// Who reviewed the copy.
    pub member: SpecReviewMember,
    /// The copy as the reviewer returned it.
    pub document: D,
}

/// The options of [`merge_reviews`] and [`merge_reviews_markdown`].
#[derive(Debug, Clone, Default)]
pub struct SpecReviewMergeOptions {
    /// The members the round started with, in team order; a copy of anybody
    /// else is a guest's.
    pub team: Vec<SpecReviewMember>,
    /// The round's date (ISO 8601): the revision entry's date, and the date of
    /// every generated list-item id.
    pub date: String,
    /// The revision entry's author.
    pub author: String,
    /// The id prefix of the questions the merge writes; `None`: `RQ`.
    pub question_prefix: Option<String>,
}

/// Returned when a copy's structure does not fit the base (or the options
/// cannot be read); nothing is merged.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecReviewMergeError {
    /// What does not fit.
    pub message: String,
}

impl SpecReviewMergeError {
    fn new(message: impl Into<String>) -> Self {
        SpecReviewMergeError {
            message: message.into(),
        }
    }
}

impl std::fmt::Display for SpecReviewMergeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "SpecReviewMergeError: {}", self.message)
    }
}

impl std::error::Error for SpecReviewMergeError {}

/// A reviewer as the report lists it.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecMergeReviewer {
    /// The reviewer.
    pub member: SpecReviewMember,
    /// Whether the reviewer is not of `options.team`.
    pub guest: bool,
}

/// A conflict block the merge wrote.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecMergeConflict {
    /// `X-<n>`.
    pub id: String,
    /// The value or node the conflict is about.
    pub path: String,
    /// The form field, or `None`.
    pub field: Option<String>,
    /// The unit's index among the value's text paragraphs; `None` for a whole
    /// value or a structural conflict.
    pub paragraph: Option<usize>,
    /// The members of every alternative, in letter order.
    pub members: Vec<String>,
}

/// A base mark left with votes.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecMergeVotes {
    /// The value's path.
    pub path: String,
    /// The form field, or `None`.
    pub field: Option<String>,
    /// The mark as merged, its token carrying the votes.
    pub markup: String,
    /// The votes, in round order.
    pub votes: Vec<SpecMarkVote>,
}

/// A base mark every copy decided the same way, applied or dropped.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecMergeUnanimous {
    /// The value's path.
    pub path: String,
    /// The form field, or `None`.
    pub field: Option<String>,
    /// The mark as the base wrote it.
    pub markup: String,
    /// Whether every copy accepted it (else every copy rejected it).
    pub accept: bool,
    /// The text that replaced it.
    pub result: String,
}

/// A base question the copies answered.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecMergeAnswers {
    /// The question id.
    pub question_id: String,
    /// The members whose answers were written, in round order.
    pub members: Vec<String>,
}

/// A new comment.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecMergeComment {
    /// `C-<n>`, numbered above the base's highest.
    pub id: String,
    /// The comment's author (the member id when the comment named none).
    pub author: String,
    /// The value's path.
    pub path: String,
    /// The form field, or `None`.
    pub field: Option<String>,
}

/// An item a copy added.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecMergeAddition {
    /// The item's path in the merged document.
    pub path: String,
    /// The members who added it alike.
    pub members: Vec<String>,
}

/// The question proposing a guest for the next round's team.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecMergeGuestQuestion {
    /// The question id.
    pub id: String,
    /// The guest.
    pub member_id: String,
    /// Where it was written; `None` when the document has no place for it.
    pub path: Option<String>,
}

/// The draft revision entry the merge appended.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecMergeRevision {
    /// The entry's item path.
    pub path: String,
    /// The version it records.
    pub version: String,
}

/// The merge report (SOM §11.9.9), every list in merged document order.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct SpecReviewMergeReport {
    pub reviewers: Vec<SpecMergeReviewer>,
    pub conflicts: Vec<SpecMergeConflict>,
    pub votes: Vec<SpecMergeVotes>,
    pub unanimous: Vec<SpecMergeUnanimous>,
    pub answers: Vec<SpecMergeAnswers>,
    pub comments: Vec<SpecMergeComment>,
    pub additions: Vec<SpecMergeAddition>,
    pub guest_questions: Vec<SpecMergeGuestQuestion>,
    pub revision: Option<SpecMergeRevision>,
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

fn json_list<T>(items: &[T], f: impl Fn(&T) -> Json) -> Json {
    Json::Array(items.iter().map(f).collect())
}

impl SpecReviewMergeReport {
    /// The canonical JSON form the conformance corpus pins.
    pub fn to_json(&self) -> Json {
        json_obj(vec![
            (
                "reviewers",
                json_list(&self.reviewers, |r| {
                    json_obj(vec![
                        ("memberId", json_str(&r.member.member_id)),
                        ("displayName", json_str(&r.member.display_name)),
                        ("role", json_str(&r.member.role)),
                        ("guest", Json::Bool(r.guest)),
                    ])
                }),
            ),
            (
                "conflicts",
                json_list(&self.conflicts, |c| {
                    json_obj(vec![
                        ("id", json_str(&c.id)),
                        ("path", json_str(&c.path)),
                        ("field", json_opt(&c.field)),
                        (
                            "paragraph",
                            c.paragraph.map_or(Json::Null, |p| Json::Int(p as i64)),
                        ),
                        ("members", json_strs(&c.members)),
                    ])
                }),
            ),
            (
                "votes",
                json_list(&self.votes, |v| {
                    json_obj(vec![
                        ("path", json_str(&v.path)),
                        ("field", json_opt(&v.field)),
                        ("markup", json_str(&v.markup)),
                        ("votes", json_list(&v.votes, SpecMarkVote::to_json)),
                    ])
                }),
            ),
            (
                "unanimous",
                json_list(&self.unanimous, |u| {
                    json_obj(vec![
                        ("path", json_str(&u.path)),
                        ("field", json_opt(&u.field)),
                        ("markup", json_str(&u.markup)),
                        (
                            "decision",
                            json_str(if u.accept { "accept" } else { "reject" }),
                        ),
                        ("result", json_str(&u.result)),
                    ])
                }),
            ),
            (
                "answers",
                json_list(&self.answers, |a| {
                    json_obj(vec![
                        ("questionId", json_str(&a.question_id)),
                        ("members", json_strs(&a.members)),
                    ])
                }),
            ),
            (
                "comments",
                json_list(&self.comments, |c| {
                    json_obj(vec![
                        ("id", json_str(&c.id)),
                        ("author", json_str(&c.author)),
                        ("path", json_str(&c.path)),
                        ("field", json_opt(&c.field)),
                    ])
                }),
            ),
            (
                "additions",
                json_list(&self.additions, |a| {
                    json_obj(vec![
                        ("path", json_str(&a.path)),
                        ("members", json_strs(&a.members)),
                    ])
                }),
            ),
            (
                "guestQuestions",
                json_list(&self.guest_questions, |g| {
                    json_obj(vec![
                        ("id", json_str(&g.id)),
                        ("memberId", json_str(&g.member_id)),
                        ("path", json_opt(&g.path)),
                    ])
                }),
            ),
            (
                "revision",
                match &self.revision {
                    None => Json::Null,
                    Some(r) => json_obj(vec![
                        ("path", json_str(&r.path)),
                        ("version", json_str(&r.version)),
                    ]),
                },
            ),
        ])
    }
}

/// The merged document and its report.
#[derive(Debug, Clone)]
pub struct SpecReviewMergeResult<D> {
    /// The merged document.
    pub merged: D,
    /// What the merge did.
    pub report: SpecReviewMergeReport,
}

// ---------------------------------------------------------------------------
// The engine: one value at a time.
// ---------------------------------------------------------------------------

/// Ids the merge writes before it can number them are placeholders
/// `\u{1}<C|X><n>\u{1}`, renumbered in merged document order at the end.
const PLACEHOLDER_MARK: char = '\u{1}';

/// One value to merge, located in the merged document.
struct MergeValue {
    path: String,
    field: Option<String>,
    base: String,
    /// Per copy, in round order; `None` when the copy holds no such value (it
    /// removed the item).
    copies: Vec<Option<String>>,
    /// A typed leaf (number, bool, enum, code): never marked, any change is a
    /// conflict.
    typed: bool,
    /// Where a conflict about a form field or a typed leaf goes; `None` for a
    /// content value.
    conflict_home: Option<String>,
}

/// What one copy did to one unit (SOM §11.9.9, steps 1–4).
struct UnitReading {
    changed: bool,
    /// The reviewer's text.
    t: String,
    /// The change as it is written into the merged document.
    written: String,
    /// The copy's votes, by the index of the base unit's mark: accept
    /// (`true`) or reject.
    votes: HashMap<usize, bool>,
}

impl UnitReading {
    fn unchanged(b: &str, votes: HashMap<usize, bool>) -> UnitReading {
        UnitReading {
            changed: false,
            t: b.to_string(),
            written: b.to_string(),
            votes,
        }
    }
}

/// The copies that made one change: the text `t`, its members, and the
/// change as the first of them wrote it.
struct ChangeGroup {
    text: String,
    members: Vec<String>,
    written: String,
}

/// The state one merge carries from value to value.
struct MergeContext {
    report: SpecReviewMergeReport,
    /// Blocks to append to the end of a content value, by its key, in the
    /// order the keys were first used.
    appends: Vec<(String, Vec<String>)>,
    members: Vec<String>,
    next_placeholder: usize,
    /// Placeholder → report entry, filled in when the ids are numbered.
    pending_conflicts: HashMap<String, SpecMergeConflict>,
    pending_comments: HashMap<String, SpecMergeComment>,
    base_comment_ids: HashSet<String>,
    base_question_ids: HashSet<String>,
}

/// What a conflict block the merge writes is about.
struct ConflictSpec<'a> {
    topic: &'a str,
    text: String,
    base: &'a str,
    groups: Vec<(String, Vec<String>)>,
    path: &'a str,
    field: Option<&'a str>,
    paragraph: Option<usize>,
}

impl MergeContext {
    fn new(copies: &[SpecReviewMember], base_texts: &[String]) -> MergeContext {
        let (comments, questions) = block_ids(base_texts);
        MergeContext {
            report: SpecReviewMergeReport::default(),
            appends: Vec::new(),
            members: copies.iter().map(|c| c.member_id.clone()).collect(),
            next_placeholder: 0,
            pending_conflicts: HashMap::new(),
            pending_comments: HashMap::new(),
            base_comment_ids: comments,
            base_question_ids: questions,
        }
    }

    fn placeholder(&mut self, kind: char) -> String {
        self.next_placeholder += 1;
        format!(
            "{}{}{}{}",
            PLACEHOLDER_MARK, kind, self.next_placeholder, PLACEHOLDER_MARK
        )
    }

    fn append(&mut self, key: &str, block: String) {
        match self.appends.iter_mut().find(|(k, _)| k == key) {
            Some((_, blocks)) => blocks.push(block),
            None => self.appends.push((key.to_string(), vec![block])),
        }
    }

    /// Writes a conflict block with a placeholder id and records it for the
    /// report.
    fn conflict(&mut self, spec: ConflictSpec) -> String {
        let id = self.placeholder('X');
        self.pending_conflicts.insert(
            id.clone(),
            SpecMergeConflict {
                id: id.clone(),
                path: spec.path.to_string(),
                field: spec.field.map(str::to_string),
                paragraph: spec.paragraph,
                members: spec.groups.iter().flat_map(|g| g.1.clone()).collect(),
            },
        );
        let alternatives: Vec<SpecConflictAlternative> = spec
            .groups
            .into_iter()
            .enumerate()
            .map(|(k, (text, members))| SpecConflictAlternative {
                letter: ((b'a' + k as u8) as char).to_string(),
                members,
                text,
            })
            .collect();
        format_conflict_block(&id, spec.topic, &spec.text, spec.base, &alternatives).join("\n")
    }
}

/// Groups the changed readings by their text `t`, in order of first
/// appearance.
fn change_groups(readings: &[Option<UnitReading>], members: &[String]) -> Vec<ChangeGroup> {
    let mut groups: Vec<ChangeGroup> = Vec::new();
    for (k, r) in readings.iter().enumerate() {
        let Some(r) = r.as_ref().filter(|r| r.changed) else {
            continue;
        };
        match groups.iter_mut().find(|g| g.text == r.t) {
            Some(g) => g.members.push(members[k].clone()),
            None => groups.push(ChangeGroup {
                text: r.t.clone(),
                members: vec![members[k].clone()],
                written: r.written.clone(),
            }),
        }
    }
    groups
}

/// Aligns two mark lists by their markup (longest common subsequence): index
/// in `a` → index in `b`.
fn align_marks(a: &[ReviewMark], b: &[ReviewMark]) -> HashMap<usize, usize> {
    let (n, m) = (a.len(), b.len());
    let mut l = vec![vec![0usize; m + 1]; n + 1];
    for i in (0..n).rev() {
        for j in (0..m).rev() {
            l[i][j] = if a[i].markup == b[j].markup {
                l[i + 1][j + 1] + 1
            } else {
                l[i + 1][j].max(l[i][j + 1])
            };
        }
    }
    let mut out = HashMap::new();
    let (mut i, mut j) = (0, 0);
    while i < n && j < m {
        if a[i].markup == b[j].markup {
            out.insert(i, j);
            i += 1;
            j += 1;
        } else if l[i + 1][j] >= l[i][j + 1] {
            i += 1;
        } else {
            j += 1;
        }
    }
    out
}

/// The most base marks a unit may have that a copy no longer holds as
/// written: the combinations of step 2 grow as 2^n. Beyond it the copy's unit
/// is read as an edit (step 4), so every runtime gives up at the same point.
const MAX_DECIDED_MARKS: usize = 16;

/// The first combination of decisions on `b`'s marks (step 2) whose result
/// is `target`, or `None`. Each mark takes leave, accept, reject in that
/// order, the first mark varying slowest. A mark the copy still holds as
/// written can only have been left, and a mark it no longer holds cannot have
/// been, so only the others vary — the same first combination, found without
/// trying the rest.
fn find_votes(
    b: &str,
    marks: &[ReviewMark],
    left: &HashSet<usize>,
    target: &str,
) -> Option<HashMap<usize, bool>> {
    let free: Vec<usize> = (0..marks.len()).filter(|i| !left.contains(i)).collect();
    if free.len() > MAX_DECIDED_MARKS {
        return None;
    }
    for combo in 0u32..(1u32 << free.len()) {
        // Bit set: reject; the first mark is the most significant bit.
        let decisions: HashMap<usize, bool> = free
            .iter()
            .enumerate()
            .map(|(k, &mark)| (mark, (combo >> (free.len() - 1 - k)) & 1 == 0))
            .collect();
        if decide_review_marks(b, &decisions) == target {
            return Some(decisions);
        }
    }
    None
}

/// Step 4: the copy edited text that holds base marks; it casts no votes.
fn read_as_edit(b: &str, c: &str) -> UnitReading {
    let t = apply_inline_marks_text(c, true);
    UnitReading {
        changed: t != b,
        written: mark_change_text(&apply_inline_marks_text(b, false), &t).text,
        t,
        votes: HashMap::new(),
    }
}

/// What copy unit `c` did to base unit `b` (SOM §11.9.9, steps 1–4).
fn read_unit(b: &str, c: &str) -> UnitReading {
    if c == b {
        return UnitReading::unchanged(b, HashMap::new());
    }
    let base_marks = review_marks(b);
    let copy_marks = review_marks(c);
    let kept = align_marks(&copy_marks, &base_marks);
    // 1. Own marks: the copy's marks that are not the base's.
    let own: Vec<usize> = (0..copy_marks.len())
        .filter(|i| !kept.contains_key(i))
        .collect();
    let reject: HashMap<usize, bool> = own.iter().map(|&i| (i, false)).collect();
    let accept: HashMap<usize, bool> = own.iter().map(|&i| (i, true)).collect();
    // 2. Votes: the decisions on the base marks that give c with its own marks
    // rejected.
    let c_prime = decide_review_marks(c, &reject);
    let left: HashSet<usize> = kept.values().copied().collect();
    let Some(votes) = find_votes(b, &base_marks, &left, &c_prime) else {
        return read_as_edit(b, c);
    };
    if own.is_empty() {
        return UnitReading::unchanged(b, votes);
    }
    // 3. Change: the own marks, carried over to the base text where marks were
    // voted on.
    let own_accepted = decide_review_marks(c, &accept);
    let (written, t) = if votes.is_empty() {
        (Some(c.to_string()), Some(own_accepted))
    } else {
        (
            transplant_edits(&c_prime, c, b),
            transplant_edits(&c_prime, &own_accepted, b),
        )
    };
    match (written, t) {
        (Some(written), Some(t)) => UnitReading {
            changed: t != b,
            t,
            written,
            votes,
        },
        _ => read_as_edit(b, c),
    }
}

/// `written` with every mark that is not one of the base's attributed to
/// `members`.
fn attribute(written: &str, base_marks: &[ReviewMark], members: &[String]) -> String {
    let marks = review_marks(written);
    let base = align_marks(&marks, base_marks);
    let mut out = written.to_string();
    for (k, m) in marks.iter().enumerate().rev() {
        if !base.contains_key(&k) {
            out = with_attribution(&out, m, members, &m.votes);
        }
    }
    out
}

/// Whether a mark is a change, which alone takes votes.
fn is_change(m: &ReviewMark) -> bool {
    matches!(
        m.kind,
        SpecMarkKind::Insertion | SpecMarkKind::Deletion | SpecMarkKind::Substitution
    )
}

/// `text` with the copies' votes on the base marks it holds: a base mark
/// every copy decided the same way is applied (accept) or dropped (reject);
/// any other voted change mark gets the votes in its token, `agent` as author
/// when it had no token. A highlight or comment mark takes no votes and
/// stays.
fn apply_votes(
    text: &str,
    base_marks: &[ReviewMark],
    readings: &[Option<UnitReading>],
    v: &MergeValue,
    ctx: &mut MergeContext,
) -> String {
    let marks = review_marks(text);
    let base = align_marks(&marks, base_marks);
    let taking = readings.iter().filter(|r| r.is_some()).count();
    let mut votes: Vec<SpecMergeVotes> = Vec::new();
    let mut unanimous: Vec<SpecMergeUnanimous> = Vec::new();
    let mut out = text.to_string();
    for (k, m) in marks.iter().enumerate().rev() {
        let Some(&b) = base.get(&k) else { continue };
        let cast: Vec<SpecMarkVote> = readings
            .iter()
            .enumerate()
            .filter_map(|(i, r)| {
                let d = r.as_ref()?.votes.get(&b)?;
                Some(SpecMarkVote::new(&ctx.members[i], *d))
            })
            .collect();
        if cast.is_empty() {
            continue;
        }
        if cast.len() == taking && cast.iter().all(|x| x.accept == cast[0].accept) {
            let accept = cast[0].accept;
            out = decide_review_marks(&out, &HashMap::from([(k, accept)]));
            unanimous.insert(
                0,
                SpecMergeUnanimous {
                    path: v.path.clone(),
                    field: v.field.clone(),
                    markup: base_marks[b].markup.clone(),
                    accept,
                    result: if accept {
                        base_marks[b].accepted.clone()
                    } else {
                        base_marks[b].rejected.clone()
                    },
                },
            );
            continue;
        }
        if !is_change(m) {
            continue;
        }
        let authors = if m.end > m.body_end {
            m.authors.clone()
        } else {
            vec!["agent".to_string()]
        };
        let mut merged: Vec<SpecMarkVote> = m
            .votes
            .iter()
            .filter(|x| !cast.iter().any(|y| y.member == x.member))
            .cloned()
            .collect();
        merged.extend(cast);
        out = with_attribution(&out, m, &authors, &merged);
        votes.insert(
            0,
            SpecMergeVotes {
                path: v.path.clone(),
                field: v.field.clone(),
                markup: review_marks(&out)[k].markup.clone(),
                votes: merged,
            },
        );
    }
    ctx.report.votes.extend(votes);
    ctx.report.unanimous.extend(unanimous);
    out
}

/// `path[ field]`, as a conflict's text names a value.
fn value_name(v: &MergeValue) -> String {
    match &v.field {
        None => v.path.clone(),
        Some(f) => format!("{} {}", v.path, f),
    }
}

/// One unit merged: the base text with votes when no copy changed it, the
/// one change attributed to every member who made it, or the base text and a
/// conflict block when the copies changed it differently.
fn merge_unit(
    b: &str,
    units: &[Option<String>],
    paragraph: Option<usize>,
    v: &MergeValue,
    ctx: &mut MergeContext,
) -> (String, Option<String>) {
    let readings: Vec<Option<UnitReading>> = units
        .iter()
        .map(|c| c.as_deref().map(|c| read_unit(b, c)))
        .collect();
    let groups = change_groups(&readings, &ctx.members);
    let base_marks = review_marks(b);
    let mut text = b.to_string();
    if groups.len() == 1 {
        text = attribute(&groups[0].written, &base_marks, &groups[0].members);
    }
    text = apply_votes(&text, &base_marks, &readings, v, ctx);
    if groups.len() < 2 {
        return (text, None);
    }
    let name = value_name(v);
    let conflict = ctx.conflict(ConflictSpec {
        topic: "Conflicting changes",
        text: match paragraph {
            None => name,
            Some(p) => format!("{}, paragraph {}", name, p),
        },
        base: b,
        groups: groups.into_iter().map(|g| (g.text, g.members)).collect(),
        path: &v.path,
        field: v.field.as_deref(),
        paragraph,
    });
    (text, Some(conflict))
}

/// A typed leaf: it cannot hold a mark, so a change by any copy is a `Value
/// changed` conflict at the leaf's home, the base value kept.
fn merge_typed(v: &MergeValue, ctx: &mut MergeContext) -> String {
    let readings: Vec<Option<UnitReading>> = v
        .copies
        .iter()
        .map(|c| {
            c.as_ref().map(|c| UnitReading {
                changed: *c != v.base,
                t: c.clone(),
                written: c.clone(),
                votes: HashMap::new(),
            })
        })
        .collect();
    let groups = change_groups(&readings, &ctx.members);
    if let (false, Some(home)) = (groups.is_empty(), &v.conflict_home) {
        let block = ctx.conflict(ConflictSpec {
            topic: "Value changed",
            text: value_name(v),
            base: &v.base,
            groups: groups.into_iter().map(|g| (g.text, g.members)).collect(),
            path: &v.path,
            field: v.field.as_deref(),
            paragraph: None,
        });
        ctx.append(home, block);
    }
    v.base.clone()
}

/// A form-field value: always one unit; its conflict goes to the end of the
/// form's preamble.
fn merge_field(v: &MergeValue, ctx: &mut MergeContext) -> String {
    let (text, conflict) = merge_unit(&v.base, &v.copies, None, v, ctx);
    if let (Some(block), Some(home)) = (conflict, &v.conflict_home) {
        ctx.append(home, block);
    }
    text
}

/// Whether a copy's block is new: a comment whose id the base lacks (or that
/// has none), a question block with no base question.
fn is_new_block(piece: &ReviewPiece, ctx: &MergeContext) -> bool {
    match piece.kind {
        Some(SpecReviewAnnotationKind::Comment) => piece
            .id
            .as_ref()
            .is_none_or(|id| !ctx.base_comment_ids.contains(id)),
        Some(SpecReviewAnnotationKind::Question) => {
            !piece.question_ids.is_empty()
                && piece
                    .question_ids
                    .iter()
                    .all(|id| !ctx.base_question_ids.contains(id))
        }
        _ => false,
    }
}

/// The anchor of each block of a value: the index of the text paragraph it
/// follows (-1: before every one). In whole-value mode every block that
/// follows text follows the one unit.
fn anchors(pieces: &[ReviewPiece], whole: bool) -> Vec<i64> {
    let mut texts: i64 = -1;
    pieces
        .iter()
        .map(|p| {
            if p.kind.is_none() {
                texts += 1;
                texts
            } else if whole {
                texts.min(0)
            } else {
                texts
            }
        })
        .collect()
}

fn text_pieces(pieces: &[ReviewPiece]) -> Vec<String> {
    pieces
        .iter()
        .filter(|p| p.kind.is_none())
        .map(|p| p.text.clone())
        .collect()
}

/// A content value: split into text paragraphs and annotation blocks, merged
/// unit by unit, the copies' new comments and questions placed after the unit
/// they followed. A copy whose text-paragraph count differs from the base's
/// makes the whole text one unit, for every copy.
fn merge_content(v: &MergeValue, ctx: &mut MergeContext) -> String {
    let base_pieces = review_pieces(&v.base);
    let copy_pieces: Vec<Option<Vec<ReviewPiece>>> = v
        .copies
        .iter()
        .map(|c| c.as_deref().map(review_pieces))
        .collect();
    let base_texts = text_pieces(&base_pieces);
    let whole = copy_pieces
        .iter()
        .flatten()
        .any(|ps| text_pieces(ps).len() != base_texts.len());
    let units_of = |ps: &[ReviewPiece]| -> Vec<String> {
        if whole {
            vec![text_pieces(ps).join("\n\n")]
        } else {
            text_pieces(ps)
        }
    };
    let base_units = units_of(&base_pieces);
    let copy_units: Vec<Option<Vec<String>>> = copy_pieces
        .iter()
        .map(|ps| ps.as_deref().map(units_of))
        .collect();

    // Blocks by anchor: the base's first, then each copy's new ones in round
    // order.
    let mut after: BTreeMap<i64, Vec<String>> = BTreeMap::new();
    let base_anchors = anchors(&base_pieces, whole);
    for (k, p) in base_pieces.iter().enumerate() {
        if p.kind.is_some() {
            after
                .entry(base_anchors[k])
                .or_default()
                .push(p.text.clone());
        }
    }
    for (i, ps) in copy_pieces.iter().enumerate() {
        let Some(ps) = ps else { continue };
        let copy_anchors = anchors(ps, false);
        for (k, p) in ps.iter().enumerate() {
            if p.kind.is_none() || !is_new_block(p, ctx) {
                continue;
            }
            let anchor = if whole {
                base_units.len() as i64 - 1
            } else {
                copy_anchors[k]
            };
            let block = new_block(p, &ctx.members[i].clone(), v, ctx);
            after.entry(anchor).or_default().push(block);
        }
    }

    let mut out: Vec<String> = after.remove(&-1).unwrap_or_default();
    for (u, b) in base_units.iter().enumerate() {
        let units: Vec<Option<String>> = copy_units
            .iter()
            .map(|cs| cs.as_ref().map(|cs| cs[u].clone()))
            .collect();
        let (text, conflict) = merge_unit(b, &units, (!whole).then_some(u), v, ctx);
        if !text.is_empty() {
            out.push(text);
        }
        out.extend(conflict);
        out.extend(after.remove(&(u as i64)).unwrap_or_default());
    }
    out.join("\n\n")
}

/// A copy's new block as merged: a comment renumbered and attributed, a
/// question as written.
fn new_block(p: &ReviewPiece, member: &str, v: &MergeValue, ctx: &mut MergeContext) -> String {
    if p.kind != Some(SpecReviewAnnotationKind::Comment) {
        return p.text.clone();
    }
    let id = ctx.placeholder('C');
    let author = p.author.clone().unwrap_or_else(|| member.to_string());
    ctx.pending_comments.insert(
        id.clone(),
        SpecMergeComment {
            id: id.clone(),
            author: author.clone(),
            path: v.path.clone(),
            field: v.field.clone(),
        },
    );
    format_comment_block(&id, &p.comment_text, Some(&author)).join("\n")
}

/// One value merged; the base text when no copy differs from it.
fn merge_value(v: &MergeValue, ctx: &mut MergeContext) -> String {
    if v.copies
        .iter()
        .all(|c| c.as_ref().is_none_or(|c| *c == v.base))
    {
        return v.base.clone();
    }
    if v.typed {
        merge_typed(v, ctx)
    } else if v.field.is_some() {
        merge_field(v, ctx)
    } else {
        merge_content(v, ctx)
    }
}

// ---------------------------------------------------------------------------
// Shared phases over the merged texts.
// ---------------------------------------------------------------------------

/// The merged document's values, by key, in merged document order.
trait MergeTexts {
    fn keys(&self) -> Vec<String>;
    fn get(&self, key: &str) -> String;
    fn set(&mut self, key: &str, value: &str);
}

/// `value` with `block` appended as its last paragraph.
fn appended(value: &str, blocks: &[String]) -> String {
    let mut parts: Vec<&str> = Vec::new();
    if !value.is_empty() {
        parts.push(value);
    }
    parts.extend(blocks.iter().map(String::as_str));
    parts.join("\n\n")
}

/// Appends the collected blocks (field and structural conflicts) to the end
/// of their values.
fn apply_appends(texts: &mut dyn MergeTexts, ctx: &MergeContext) {
    for (key, blocks) in &ctx.appends {
        let value = texts.get(key);
        texts.set(key, &appended(&value, blocks));
    }
}

/// The number of `<prefix>-<n>`, read as `parseInt` reads it (leading
/// digits), or `None`.
fn id_number(id: &str, prefix: &str) -> Option<u64> {
    let rest = id.strip_prefix(prefix)?.strip_prefix('-')?;
    let digits: String = rest.chars().take_while(char::is_ascii_digit).collect();
    digits.parse().ok()
}

/// The highest `<prefix>-<n>` of the texts' annotations of one kind.
fn highest_id(texts: &[String], prefix: &str, kind: SpecReviewAnnotationKind) -> u64 {
    let mut high = 0;
    for t in texts {
        for p in review_pieces(t) {
            if p.kind != Some(kind) {
                continue;
            }
            let ids: Vec<String> = if kind == SpecReviewAnnotationKind::Question {
                p.question_ids
            } else {
                p.id.into_iter().collect()
            };
            for id in ids {
                if let Some(n) = id_number(&id, prefix) {
                    high = high.max(n);
                }
            }
        }
    }
    high
}

/// `value` with each placeholder replaced by `number(kind, placeholder)`.
fn replace_placeholders(value: &str, mut number: impl FnMut(char, &str) -> String) -> String {
    let mut out = String::with_capacity(value.len());
    let mut rest = value;
    while let Some(at) = rest.find(PLACEHOLDER_MARK) {
        let after = &rest[at + 1..];
        let kind = after.chars().next().filter(|c| *c == 'C' || *c == 'X');
        let digits = after
            .get(1..)
            .map_or(0, |d| d.bytes().take_while(u8::is_ascii_digit).count());
        let closed =
            kind.is_some() && digits > 0 && after[1 + digits..].starts_with(PLACEHOLDER_MARK);
        out.push_str(&rest[..at]);
        if !closed {
            out.push(PLACEHOLDER_MARK);
            rest = after;
            continue;
        }
        let len = 1 + 1 + digits + 1;
        let placeholder = &rest[at..at + len];
        out.push_str(&number(kind.unwrap_or('C'), placeholder));
        rest = &rest[at + len..];
    }
    out.push_str(rest);
    out
}

/// Numbers the new comments and conflicts in merged document order, above
/// the base's highest `C-<n>` and `X-<n>`, and fills their report entries in.
fn number_ids(texts: &mut dyn MergeTexts, base_texts: &[String], ctx: &mut MergeContext) {
    let mut next_c = highest_id(base_texts, "C", SpecReviewAnnotationKind::Comment);
    let mut next_x = highest_id(base_texts, "X", SpecReviewAnnotationKind::Conflict);
    for key in texts.keys() {
        let value = texts.get(&key);
        if !value.contains(PLACEHOLDER_MARK) {
            continue;
        }
        let numbered = replace_placeholders(&value, |kind, placeholder| {
            if kind == 'C' {
                next_c += 1;
                let id = format!("C-{}", next_c);
                if let Some(c) = ctx.pending_comments.get(placeholder) {
                    ctx.report.comments.push(SpecMergeComment {
                        id: id.clone(),
                        ..c.clone()
                    });
                }
                id
            } else {
                next_x += 1;
                let id = format!("X-{}", next_x);
                if let Some(c) = ctx.pending_conflicts.get(placeholder) {
                    ctx.report.conflicts.push(SpecMergeConflict {
                        id: id.clone(),
                        ..c.clone()
                    });
                }
                id
            }
        });
        texts.set(&key, &numbered);
    }
}

/// The team answers of `texts` by question id, in order; the first of a
/// repeated id wins.
fn team_answers(texts: &[String]) -> Vec<(String, String)> {
    let mut out: Vec<(String, String)> = Vec::new();
    for t in texts {
        for (id, a) in review_team_answers(t) {
            if !out.iter().any(|(x, _)| *x == id) {
                out.push((id, a));
            }
        }
    }
    out
}

/// Writes each copy's team answer to a base question, where it differs from
/// the base's, as that member's individual answer (copies in round order).
fn merge_answers(
    texts: &mut dyn MergeTexts,
    base_texts: &[String],
    copy_texts: &[Vec<String>],
    ctx: &mut MergeContext,
) {
    let copy_answers: Vec<Vec<(String, String)>> =
        copy_texts.iter().map(|ts| team_answers(ts)).collect();
    for (id, base_answer) in team_answers(base_texts) {
        let mut members: Vec<String> = Vec::new();
        for (i, answers) in copy_answers.iter().enumerate() {
            let Some((_, a)) = answers.iter().find(|(x, _)| *x == id) else {
                continue;
            };
            if *a == base_answer || a.is_empty() {
                continue;
            }
            for key in texts.keys() {
                let Some(written) =
                    set_individual_answer_text(&texts.get(&key), &id, &ctx.members[i], a)
                else {
                    continue;
                };
                texts.set(&key, &written);
                members.push(ctx.members[i].clone());
                break;
            }
        }
        if !members.is_empty() {
            ctx.report.answers.push(SpecMergeAnswers {
                question_id: id,
                members,
            });
        }
    }
}

/// The question proposing guest `g` for the next round's team.
fn guest_question(id: &str, g: &SpecReviewMember) -> String {
    let who = if g.role.is_empty() {
        g.display_name.clone()
    } else {
        format!("{}, {}", g.display_name, g.role)
    };
    let mut draft = SpecQuestionDraft::new(
        id,
        &format!("Guest {}", g.member_id),
        &format!("add {} ({}) to the review team?", g.member_id, who),
    );
    draft.options = vec![
        "(a) yes, from the next round on".to_string(),
        "(b) no, this round only".to_string(),
    ];
    draft.recommended = Some("a".to_string());
    format_question_block(&draft).join("\n")
}

/// Where the guest questions go: the key of a value and its path.
struct GuestHome {
    key: String,
    path: String,
}

/// Lists the reviewers and writes one question per guest to the end of the
/// value at `home` (`None`: the report only), numbered above the base's
/// highest question id with the prefix.
fn add_guests(
    texts: &mut dyn MergeTexts,
    base_texts: &[String],
    copies: &[SpecReviewMember],
    options: &SpecReviewMergeOptions,
    home: Option<&GuestHome>,
    ctx: &mut MergeContext,
) {
    let team: HashSet<&str> = options.team.iter().map(|m| m.member_id.as_str()).collect();
    let prefix = options.question_prefix.as_deref().unwrap_or("RQ");
    let mut n = highest_id(base_texts, prefix, SpecReviewAnnotationKind::Question);
    for c in copies {
        let guest = !team.contains(c.member_id.as_str());
        ctx.report.reviewers.push(SpecMergeReviewer {
            member: c.clone(),
            guest,
        });
        if !guest {
            continue;
        }
        n += 1;
        let id = format!("{}-{}", prefix, n);
        ctx.report.guest_questions.push(SpecMergeGuestQuestion {
            id: id.clone(),
            member_id: c.member_id.clone(),
            path: home.map(|h| h.path.clone()),
        });
        if let Some(h) = home {
            let value = texts.get(&h.key);
            texts.set(&h.key, &appended(&value, &[guest_question(&id, c)]));
        }
    }
}

/// The ids of the comments and of the questions of `texts`.
fn block_ids(texts: &[String]) -> (HashSet<String>, HashSet<String>) {
    let mut comments = HashSet::new();
    let mut questions = HashSet::new();
    for t in texts {
        for p in review_pieces(t) {
            if p.kind == Some(SpecReviewAnnotationKind::Comment) {
                comments.extend(p.id);
            }
            questions.extend(p.question_ids);
        }
    }
    (comments, questions)
}

/// What both formats share after the structure.
struct TextPhase<'a> {
    base_texts: &'a [String],
    copy_texts: &'a [Vec<String>],
    copies: &'a [SpecReviewMember],
    options: &'a SpecReviewMergeOptions,
    home: Option<GuestHome>,
}

/// The phases after the structure, shared by both formats: the values, the
/// appended blocks, the ids, the answers and the guests.
fn merge_texts(
    values: &[MergeValue],
    key_of: impl Fn(usize, &MergeValue) -> String,
    texts: &mut dyn MergeTexts,
    phase: &TextPhase,
    ctx: &mut MergeContext,
) {
    for (k, v) in values.iter().enumerate() {
        let merged = merge_value(v, ctx);
        if merged != v.base {
            texts.set(&key_of(k, v), &merged);
        }
    }
    apply_appends(texts, ctx);
    number_ids(texts, phase.base_texts, ctx);
    merge_answers(texts, phase.base_texts, phase.copy_texts, ctx);
    add_guests(
        texts,
        phase.base_texts,
        phase.copies,
        phase.options,
        phase.home.as_ref(),
        ctx,
    );
}

// ---------------------------------------------------------------------------
// Plain Markdown: values by heading path.
// ---------------------------------------------------------------------------

/// A Markdown file cut at its headings: body `i` follows heading `i - 1`
/// (body 0 precedes them all).
struct MarkdownSplit {
    headings: Vec<String>,
    /// The heading path of each body, its heading texts joined by ` > `
    /// (body 0: ``).
    paths: Vec<String>,
    bodies: Vec<Vec<String>>,
}

/// A heading line's level and text (`#{1,6}`, then nothing or a space or tab
/// before the text), or `None`.
fn heading_of(line: &str) -> Option<(usize, String)> {
    let level = line.bytes().take_while(|&b| b == b'#').count();
    if !(1..=6).contains(&level) {
        return None;
    }
    let rest = &line[level..];
    if !rest.is_empty() && !rest.starts_with([' ', '\t']) {
        return None;
    }
    Some((level, rest.trim_matches([' ', '\t']).to_string()))
}

fn split_markdown(text: &str) -> MarkdownSplit {
    let mut out = MarkdownSplit {
        headings: Vec::new(),
        paths: vec![String::new()],
        bodies: vec![Vec::new()],
    };
    let mut fence = MarkdownFenceTracker::new();
    let mut stack: Vec<(usize, String)> = Vec::new();
    for line in text.split('\n') {
        let was_fenced = fence.in_fence();
        fence.feed(line);
        let heading = if was_fenced || fence.in_fence() {
            None
        } else {
            heading_of(line)
        };
        let Some((level, title)) = heading else {
            out.bodies
                .last_mut()
                .expect("a body")
                .push(line.to_string());
            continue;
        };
        while stack.last().is_some_and(|(l, _)| *l >= level) {
            stack.pop();
        }
        stack.push((level, title));
        out.headings.push(line.to_string());
        out.paths.push(
            stack
                .iter()
                .map(|(_, t)| t.as_str())
                .collect::<Vec<_>>()
                .join(" > "),
        );
        out.bodies.push(Vec::new());
    }
    out
}

/// A body's blank lines before and after its value, and the value.
struct BodyParts {
    lead: usize,
    trail: usize,
    value: String,
}

fn body_parts(lines: &[String]) -> BodyParts {
    let blank = |l: &String| l.trim().is_empty();
    let lead = lines.iter().take_while(|l| blank(l)).count();
    if lead == lines.len() {
        return BodyParts {
            lead,
            trail: 0,
            value: String::new(),
        };
    }
    let trail = lines.iter().rev().take_while(|l| blank(l)).count();
    BodyParts {
        lead,
        trail,
        value: lines[lead..lines.len() - trail].join("\n"),
    }
}

/// The body lines for a new value, keeping the body's blank lines around it.
fn body_lines(lines: &[String], value: &str, after_heading: bool) -> Vec<String> {
    let parts = body_parts(lines);
    if value == parts.value {
        return lines.to_vec();
    }
    if value.is_empty() {
        return lines[..parts.lead].to_vec();
    }
    let value_lines = value.split('\n').map(str::to_string);
    if parts.value.is_empty() {
        let mut out: Vec<String> = Vec::new();
        if after_heading {
            out.push(String::new());
        }
        out.extend(value_lines);
        if !lines.is_empty() {
            out.push(String::new());
        }
        return out;
    }
    let mut out = lines[..parts.lead].to_vec();
    out.extend(value_lines);
    out.extend(lines[lines.len() - parts.trail..].iter().cloned());
    out
}

/// The bodies of a Markdown file, by index.
struct MarkdownTexts(Vec<String>);

impl MergeTexts for MarkdownTexts {
    fn keys(&self) -> Vec<String> {
        (0..self.0.len()).map(|k| k.to_string()).collect()
    }

    fn get(&self, key: &str) -> String {
        key.parse::<usize>()
            .ok()
            .and_then(|k| self.0.get(k).cloned())
            .unwrap_or_default()
    }

    fn set(&mut self, key: &str, value: &str) {
        if let Some(slot) = key.parse::<usize>().ok().and_then(|k| self.0.get_mut(k)) {
            *slot = value.to_string();
        }
    }
}

/// Merges the reviewed `copies` of the plain annotated Markdown file `base`
/// (SOM §11.9.9), value by value under each heading. Neither the base nor a
/// copy is changed. A copy whose heading sequence differs from the base's is
/// refused.
pub fn merge_reviews_markdown(
    base: &str,
    copies: &[SpecReviewedCopy<String>],
    options: &SpecReviewMergeOptions,
) -> Result<SpecReviewMergeResult<String>, SpecReviewMergeError> {
    let b = split_markdown(base);
    let cs: Vec<MarkdownSplit> = copies.iter().map(|c| split_markdown(&c.document)).collect();
    for (i, c) in cs.iter().enumerate() {
        let same = c.headings.len() == b.headings.len()
            && c.headings
                .iter()
                .zip(&b.headings)
                .all(|(x, y)| x.trim() == y.trim());
        if !same {
            return Err(SpecReviewMergeError::new(format!(
                "the copy of {} has other headings than the base",
                copies[i].member.member_id
            )));
        }
    }
    let base_texts: Vec<String> = b.bodies.iter().map(|l| body_parts(l).value).collect();
    let copy_texts: Vec<Vec<String>> = cs
        .iter()
        .map(|c| c.bodies.iter().map(|l| body_parts(l).value).collect())
        .collect();
    let members: Vec<SpecReviewMember> = copies.iter().map(|c| c.member.clone()).collect();
    let mut ctx = MergeContext::new(&members, &base_texts);
    let values: Vec<MergeValue> = base_texts
        .iter()
        .enumerate()
        .map(|(k, t)| MergeValue {
            path: b.paths[k].clone(),
            field: None,
            base: t.clone(),
            copies: copy_texts.iter().map(|ct| Some(ct[k].clone())).collect(),
            typed: false,
            conflict_home: None,
        })
        .collect();
    let first = if b.headings.is_empty() { 0 } else { 1 };
    let mut texts = MarkdownTexts(base_texts.clone());
    let phase = TextPhase {
        base_texts: &base_texts,
        copy_texts: &copy_texts,
        copies: &members,
        options,
        home: Some(GuestHome {
            key: first.to_string(),
            path: b.paths[first].clone(),
        }),
    };
    merge_texts(&values, |k, _| k.to_string(), &mut texts, &phase, &mut ctx);
    let mut lines: Vec<String> = Vec::new();
    for (k, body) in b.bodies.iter().enumerate() {
        if k > 0 {
            lines.push(b.headings[k - 1].clone());
        }
        lines.extend(body_lines(body, &texts.0[k], k > 0));
    }
    Ok(SpecReviewMergeResult {
        merged: lines.join("\n"),
        report: ctx.report,
    })
}

// ---------------------------------------------------------------------------
// SOM documents: values by model path, list items by section id.
// ---------------------------------------------------------------------------

/// Whether `path` is `item` or lies under it.
fn is_under(path: &str, item: &str) -> bool {
    path == item || (path.starts_with(item) && path[item.len()..].starts_with('/'))
}

/// A document's paths with every list item named by its section id instead
/// of its position (`DEMO/CARD-LST#CARD-BETA/content`), so the same item has
/// the same name in the base, in every copy and in the merged document.
struct CanonicalPaths {
    /// Item path → its list's path.
    list_of: HashMap<String, String>,
    /// Item path → the section id it is matched by.
    ids: HashMap<String, String>,
    /// Canonical item path → item path.
    by_canonical: HashMap<String, String>,
    /// List path → its item paths, in order.
    items: HashMap<String, Vec<String>>,
}

impl CanonicalPaths {
    fn new(doc: &SpecDocument, refl: &SpecReflection) -> CanonicalPaths {
        let mut out = CanonicalPaths {
            list_of: HashMap::new(),
            ids: HashMap::new(),
            by_canonical: HashMap::new(),
            items: HashMap::new(),
        };
        for list in doc.list_paths() {
            let field = refl.resolve(&list).and_then(|r| r.field);
            let pattern = field.as_ref().map_or("", |f| f.section_id_pattern.as_str());
            let stem = field.as_ref().map_or(list.as_str(), |f| f.name.as_str());
            let items = doc.list_items(&list);
            for (k, item) in items.iter().enumerate() {
                out.list_of.insert(item.clone(), list.clone());
                let id = effective_list_item_section_id(
                    doc.item_section_id(item).map(String::as_str),
                    pattern,
                    k + 1,
                    stem,
                );
                out.ids.insert(item.clone(), id);
            }
            out.items.insert(list, items);
        }
        let items: Vec<String> = out.list_of.keys().cloned().collect();
        for item in items {
            let canonical = out.of(&item);
            out.by_canonical.insert(canonical, item);
        }
        out
    }

    /// The item paths of the list at `list`, in order.
    fn items(&self, list: &str) -> Vec<String> {
        self.items.get(list).cloned().unwrap_or_default()
    }

    /// The section id an item is matched by.
    fn id_of(&self, item: &str) -> String {
        self.ids.get(item).cloned().unwrap_or_default()
    }

    /// The canonical form of `path`.
    fn of(&self, path: &str) -> String {
        let segs: Vec<&str> = path.split('/').collect();
        for k in (1..=segs.len()).rev() {
            let prefix = segs[..k].join("/");
            let Some(list) = self.list_of.get(&prefix) else {
                continue;
            };
            let rest = segs[k..].join("/");
            let tail = if rest.is_empty() {
                String::new()
            } else {
                format!("/{}", rest)
            };
            return format!("{}#{}{}", self.of(list), self.id_of(&prefix), tail);
        }
        path.to_string()
    }

    /// The document's path for a canonical path, or `None` when the document
    /// lacks one of its items.
    fn path_of(&self, canonical: &str) -> Option<String> {
        let segs: Vec<&str> = canonical.split('/').collect();
        for k in (1..=segs.len()).rev() {
            let Some(item) = self.by_canonical.get(&segs[..k].join("/")) else {
                continue;
            };
            let rest = segs[k..].join("/");
            return Some(if rest.is_empty() {
                item.clone()
            } else {
                format!("{}/{}", item, rest)
            });
        }
        (!canonical.contains('#')).then(|| canonical.to_string())
    }
}

/// Every path a document holds a value or a list at.
fn document_paths(doc: &SpecDocument) -> Vec<String> {
    let json = doc.to_json();
    let mut paths: Vec<String> = Vec::new();
    paths.extend(json.content.keys().cloned());
    paths.extend(json.forms.keys().cloned());
    paths.extend(json.headlines.keys().cloned());
    paths.extend(json.code_specs.keys().cloned());
    for (list, l) in &json.lists {
        paths.push(list.clone());
        paths.extend(l.items.iter().cloned());
    }
    paths
}

/// A copy whose paths the model does not resolve does not fit the base.
fn check_structure(
    doc: &SpecDocument,
    what: &str,
    refl: &SpecReflection,
) -> Result<(), SpecReviewMergeError> {
    for p in document_paths(doc) {
        if refl.resolve(&p).is_none() {
            return Err(SpecReviewMergeError::new(format!(
                "{} holds {}, a path the base model does not resolve",
                what, p
            )));
        }
    }
    Ok(())
}

/// The form field `field` of the form at `path`, or `None`.
fn form_field_spec(refl: &SpecReflection, path: &str, field: &str) -> Option<FormFieldSpec> {
    let f = refl.resolve(path)?.field?;
    f.form_fields.into_iter().find(|x| x.name == field)
}

/// Whether the value at `path` / `field` is text, which can hold marks: a
/// content value (a form's preamble included) or a String form field that is
/// not code. Scalar and enum leaves, and typed or code fields, are not.
fn is_text(refl: &SpecReflection, path: &str, field: Option<&str>) -> bool {
    if let Some(field) = field {
        return form_field_spec(refl, path, field).is_none_or(|s| s.type_ == "String" && !s.code);
    }
    let Some(res) = refl.resolve(path) else {
        return true;
    };
    if res.kind == SPEC_NODE_KIND_SCALAR || res.kind == SPEC_NODE_KIND_ENUM_VALUE {
        return false;
    }
    res.kind != SPEC_NODE_KIND_LIST_ITEM_SCALAR
        || res.field.is_some_and(|f| f.element_type == "String")
}

/// The first node at or below `path` that holds content (a content leaf or a
/// form's preamble), in model order.
fn first_content_slot(refl: &SpecReflection, path: &str, deep: bool) -> Option<String> {
    let res = refl.resolve(path)?;
    if res.kind == SPEC_NODE_KIND_CONTENT || res.kind == SPEC_NODE_KIND_FORM {
        return Some(path.to_string());
    }
    let cls = res.target_class?;
    for f in &cls.fields {
        let child = format!("{}/{}", path, refl.field_segment(f));
        if f.kind == SPEC_FIELD_KIND_CONTENT || f.kind == SPEC_FIELD_KIND_FORM {
            return Some(child);
        }
        if deep && (f.kind == SPEC_FIELD_KIND_COMPLEX || f.kind == SPEC_FIELD_KIND_SECTION) {
            if let Some(found) = first_content_slot(refl, &child, true) {
                return Some(found);
            }
        }
    }
    None
}

/// Where a block about the node at `path` goes (SOM §11.9.9, "Structure"):
/// the first content value at or below it in document order (`own_first`);
/// else the first node at or below it that can hold content; else its
/// nearest ancestor's own.
fn block_home(
    doc: &SpecDocument,
    refl: &SpecReflection,
    path: &str,
    own_first: bool,
) -> Option<String> {
    if own_first {
        if let Some(existing) = doc.content_paths().into_iter().find(|p| is_under(p, path)) {
            return Some(existing);
        }
        if let Some(slot) = first_content_slot(refl, path, true) {
            return Some(slot);
        }
    }
    let mut a = spec_parent_path(path);
    while !a.is_empty() {
        if doc.content(&a).is_some() {
            return Some(a);
        }
        if let Some(slot) = first_content_slot(refl, &a, false) {
            return Some(slot);
        }
        let parent = spec_parent_path(&a);
        if parent == a {
            break;
        }
        a = parent;
    }
    None
}

/// One structural change the copies disagree with the base on.
struct Structural {
    /// The canonical path of the item (or section) concerned.
    node: String,
    topic: &'static str,
    base: String,
    groups: Vec<(String, Vec<String>)>,
}

const ITEM_REMOVED: &str = "Item removed";
const ITEM_MOVED: &str = "Item moved";
const HEADLINE_CHANGED: &str = "Headline changed";

fn add_structural(
    all: &mut Vec<Structural>,
    node: &str,
    topic: &'static str,
    base: &str,
    text: &str,
    member: &str,
) {
    let at = match all.iter().position(|x| x.node == node && x.topic == topic) {
        Some(at) => at,
        None => {
            all.push(Structural {
                node: node.to_string(),
                topic,
                base: base.to_string(),
                groups: Vec::new(),
            });
            all.len() - 1
        }
    };
    let s = &mut all[at];
    match s.groups.iter_mut().find(|g| g.0 == text) {
        Some(g) => g.1.push(member.to_string()),
        None => s.groups.push((text.to_string(), vec![member.to_string()])),
    }
}

/// The ids of `ids` that are not in their longest common subsequence with
/// `order`.
fn moved_ids(order: &[String], ids: &[String]) -> Vec<String> {
    let (n, m) = (order.len(), ids.len());
    let mut l = vec![vec![0usize; m + 1]; n + 1];
    for i in (0..n).rev() {
        for j in (0..m).rev() {
            l[i][j] = if order[i] == ids[j] {
                l[i + 1][j + 1] + 1
            } else {
                l[i + 1][j].max(l[i][j + 1])
            };
        }
    }
    let mut stay: HashSet<&str> = HashSet::new();
    let (mut i, mut j) = (0, 0);
    while i < n && j < m {
        if order[i] == ids[j] {
            stay.insert(&order[i]);
            i += 1;
            j += 1;
        } else if l[i + 1][j] >= l[i][j + 1] {
            i += 1;
        } else {
            j += 1;
        }
    }
    ids.iter()
        .filter(|id| !stay.contains(id.as_str()))
        .cloned()
        .collect()
}

/// `value` written as attributed insertions, one per text paragraph (an
/// added item's text); a fenced code paragraph and an annotation block are
/// copied as they are.
fn as_insertion(value: &str, members: &[String]) -> String {
    let token = format!("{{@{}}}", members.join(","));
    review_pieces(value)
        .into_iter()
        .map(|p| {
            let fenced = {
                let t = p.text.trim_start();
                t.starts_with("```") || t.starts_with("~~~")
            };
            if p.kind.is_some() || fenced {
                p.text
            } else {
                format!("{{++ {} ++}}{}", p.text.trim(), token)
            }
        })
        .collect::<Vec<_>>()
        .join("\n\n")
}

fn list_error(e: impl std::fmt::Display) -> SpecReviewMergeError {
    SpecReviewMergeError::new(e.to_string())
}

/// Copies item `from` of `src`, with everything under it, to item `to` of
/// `dst`, its text written as insertions attributed to `members`.
fn copy_item(
    src: &SpecDocument,
    from: &str,
    dst: &mut SpecDocument,
    to: &str,
    members: &[String],
    refl: &SpecReflection,
) -> Result<(), SpecReviewMergeError> {
    let mut moved: HashMap<String, String> = HashMap::from([(from.to_string(), to.to_string())]);
    let remap = |moved: &HashMap<String, String>, p: &str| -> String {
        let segs: Vec<&str> = p.split('/').collect();
        for k in (1..=segs.len()).rev() {
            if let Some(target) = moved.get(&segs[..k].join("/")) {
                let mut out = vec![target.as_str()];
                out.extend(&segs[k..]);
                return out.join("/");
            }
        }
        p.to_string()
    };
    let mut lists: Vec<String> = src
        .list_paths()
        .into_iter()
        .filter(|l| is_under(l, from))
        .collect();
    lists.sort_by_key(|l| l.split('/').count());
    let canonical = CanonicalPaths::new(src, refl);
    for list in &lists {
        for item in src.list_items(list) {
            let target = dst
                .add_list_item_with_section_id(&remap(&moved, list), &canonical.id_of(&item))
                .map_err(list_error)?;
            moved.insert(item, target);
        }
    }
    for p in src
        .content_paths()
        .into_iter()
        .filter(|x| is_under(x, from))
    {
        let value = src.content_or(&p);
        let written = if is_text(refl, &p, None) {
            as_insertion(&value, members)
        } else {
            value
        };
        dst.set_content(&remap(&moved, &p), &written);
    }
    for p in src.form_paths().into_iter().filter(|x| is_under(x, from)) {
        for f in src.form_field_names(&p) {
            let value = src.form_field_or(&p, &f);
            let written = if is_text(refl, &p, Some(&f)) {
                as_insertion(&value, members)
            } else {
                value
            };
            dst.set_form_field(&remap(&moved, &p), &f, &written);
        }
    }
    for p in src
        .headline_paths()
        .into_iter()
        .filter(|x| is_under(x, from))
    {
        dst.set_headline(&remap(&moved, &p), &src.headline_or(&p));
    }
    for p in src
        .code_spec_paths()
        .into_iter()
        .filter(|x| is_under(x, from))
    {
        dst.set_code_spec(&remap(&moved, &p), &src.code_spec_or(&p));
    }
    Ok(())
}

/// Everything under an item, as one comparable value, independent of the
/// item's position: copies adding the same item alike add it once.
fn item_signature(doc: &SpecDocument, item: &str) -> String {
    let json = doc.to_json();
    // Nested item paths start with the item's own path, which is a position:
    // cut it.
    let cut = |p: &str| -> String { p.strip_prefix(item).unwrap_or(p).to_string() };
    let mut parts: Vec<String> = Vec::new();
    for (k, v) in json.content.iter().filter(|(k, _)| is_under(k, item)) {
        parts.push(format!("c\u{0}{}\u{0}{}", cut(k), v));
    }
    for (k, fields) in json.forms.iter().filter(|(k, _)| is_under(k, item)) {
        for (f, v) in fields {
            parts.push(format!("f\u{0}{}\u{0}{}\u{0}{}", cut(k), f, v));
        }
    }
    for (k, v) in json.headlines.iter().filter(|(k, _)| is_under(k, item)) {
        parts.push(format!("h\u{0}{}\u{0}{}", cut(k), v));
    }
    for (k, l) in json.lists.iter().filter(|(k, _)| is_under(k, item)) {
        let items: Vec<String> = l.items.iter().map(|x| cut(x)).collect();
        let ids: Vec<String> = l
            .ids
            .iter()
            .map(|(x, id)| format!("{}={}", cut(x), id))
            .collect();
        parts.push(format!(
            "l\u{0}{}\u{0}{}\u{0}{}\u{0}{}",
            cut(k),
            l.seq,
            items.join("\u{2}"),
            ids.join("\u{2}")
        ));
    }
    parts.join("\u{3}")
}

/// One item the copies added, by its section id.
struct AddedItem {
    id: String,
    /// The first copy that added it.
    copy: usize,
    /// The section id of the base item before it in that copy.
    anchor: Option<String>,
    members: Vec<String>,
    signature: String,
}

/// The structure phase: items the copies added are added (attributed to
/// every copy that added them alike); items removed or moved, and changed
/// headlines, become structural conflicts. Returns the canonical paths of
/// the added items.
fn merge_structure(
    merged: &mut SpecDocument,
    base: &SpecDocument,
    copies: &[SpecReviewedCopy<SpecDocument>],
    refl: &SpecReflection,
    model: &SpecModel,
    ctx: &mut MergeContext,
) -> Result<Vec<String>, SpecReviewMergeError> {
    let base_canon = CanonicalPaths::new(base, refl);
    let copy_canon: Vec<CanonicalPaths> = copies
        .iter()
        .map(|c| CanonicalPaths::new(&c.document, refl))
        .collect();
    let mut added: Vec<String> = Vec::new();
    let mut structural: Vec<Structural> = Vec::new();
    let mut additions: Vec<(String, Vec<String>)> = Vec::new();
    let mut lists: HashSet<String> = base.list_paths().iter().map(|l| base_canon.of(l)).collect();
    for (i, c) in copies.iter().enumerate() {
        lists.extend(c.document.list_paths().iter().map(|l| copy_canon[i].of(l)));
    }
    let mut ordered: Vec<String> = lists.into_iter().collect();
    ordered.sort_by(|a, b| {
        a.matches('#')
            .count()
            .cmp(&b.matches('#').count())
            .then_with(|| a.cmp(b))
    });
    for list in &ordered {
        if added.iter().any(|a| is_under(list, a)) {
            continue;
        }
        let Some(base_path) = base_canon.path_of(list) else {
            continue;
        };
        let base_ids: Vec<String> = base_canon
            .items(&base_path)
            .iter()
            .map(|p| base_canon.id_of(p))
            .collect();
        let mut groups: Vec<AddedItem> = Vec::new();
        for (i, c) in copies.iter().enumerate() {
            let Some(copy_path) = copy_canon[i].path_of(list) else {
                continue;
            };
            let items = copy_canon[i].items(&copy_path);
            let ids: Vec<String> = items.iter().map(|p| copy_canon[i].id_of(p)).collect();
            let member = &c.member.member_id;
            for (k, id) in ids.iter().enumerate() {
                if base_ids.contains(id) {
                    continue;
                }
                let signature = item_signature(&c.document, &items[k]);
                match groups.iter_mut().find(|g| g.id == *id) {
                    None => groups.push(AddedItem {
                        id: id.clone(),
                        copy: i,
                        anchor: ids[..k]
                            .iter()
                            .rev()
                            .find(|x| base_ids.contains(x))
                            .cloned(),
                        members: vec![member.clone()],
                        signature,
                    }),
                    Some(g) if g.signature == signature => g.members.push(member.clone()),
                    Some(_) => {}
                }
            }
            for id in base_ids.iter().filter(|x| !ids.contains(x)) {
                let node = format!("{}#{}", list, id);
                add_structural(
                    &mut structural,
                    &node,
                    ITEM_REMOVED,
                    "kept",
                    "removed",
                    member,
                );
            }
            let kept_order: Vec<String> = base_ids
                .iter()
                .filter(|x| ids.contains(x))
                .cloned()
                .collect();
            let kept_ids: Vec<String> = ids
                .iter()
                .filter(|x| base_ids.contains(x))
                .cloned()
                .collect();
            for id in moved_ids(&kept_order, &kept_ids) {
                let from = base_ids.iter().position(|x| *x == id).unwrap_or(0) + 1;
                let to = ids.iter().position(|x| *x == id).unwrap_or(0) + 1;
                add_structural(
                    &mut structural,
                    &format!("{}#{}", list, id),
                    ITEM_MOVED,
                    &format!("position {}", from),
                    &format!("moved to position {}", to),
                    member,
                );
            }
        }
        for g in groups {
            let merged_canon = CanonicalPaths::new(merged, refl);
            let list_path = merged_canon.path_of(list).unwrap_or_else(|| list.clone());
            let merged_ids: Vec<String> = merged_canon
                .items(&list_path)
                .iter()
                .map(|p| merged_canon.id_of(p))
                .collect();
            let mut at = match &g.anchor {
                None => 0,
                Some(a) => merged_ids.iter().position(|x| x == a).map_or(0, |p| p + 1),
            };
            while at < merged_ids.len() && !base_ids.contains(&merged_ids[at]) {
                at += 1;
            }
            let mut item = merged
                .add_list_item_with_section_id(&list_path, &g.id)
                .map_err(list_error)?;
            if at < merged_ids.len() {
                item = merged
                    .move_list_item(model, &item, at as i64, None)
                    .map_err(list_error)?
                    .path;
            }
            let node = format!("{}#{}", list, g.id);
            let src_item = copy_canon[g.copy]
                .path_of(&node)
                .ok_or_else(|| SpecReviewMergeError::new(format!("no item {}", node)))?;
            copy_item(
                &copies[g.copy].document,
                &src_item,
                merged,
                &item,
                &g.members,
                refl,
            )?;
            added.push(node.clone());
            additions.push((node, g.members));
        }
    }
    headline_changes(
        base,
        &base_canon,
        copies,
        &copy_canon,
        &added,
        &mut structural,
    );
    let merged_canon = CanonicalPaths::new(merged, refl);
    for (node, members) in additions {
        ctx.report.additions.push(SpecMergeAddition {
            path: merged_canon.path_of(&node).unwrap_or(node),
            members,
        });
    }
    for s in structural {
        let node = merged_canon
            .path_of(&s.node)
            .unwrap_or_else(|| s.node.clone());
        let home = block_home(merged, refl, &node, true);
        let block = ctx.conflict(ConflictSpec {
            topic: s.topic,
            text: node.clone(),
            base: &s.base,
            groups: s.groups,
            path: &node,
            field: None,
            paragraph: None,
        });
        if let Some(home) = home {
            ctx.append(&content_key(&home), block);
        }
    }
    Ok(added)
}

/// Every headline a copy changed (items it added aside) is a structural
/// conflict.
fn headline_changes(
    base: &SpecDocument,
    base_canon: &CanonicalPaths,
    copies: &[SpecReviewedCopy<SpecDocument>],
    copy_canon: &[CanonicalPaths],
    added: &[String],
    structural: &mut Vec<Structural>,
) {
    let mut nodes: HashSet<String> = base
        .headline_paths()
        .iter()
        .map(|p| base_canon.of(p))
        .collect();
    for (i, c) in copies.iter().enumerate() {
        nodes.extend(
            c.document
                .headline_paths()
                .iter()
                .map(|p| copy_canon[i].of(p)),
        );
    }
    let mut nodes: Vec<String> = nodes.into_iter().collect();
    nodes.sort();
    for node in &nodes {
        if added.iter().any(|a| is_under(node, a)) {
            continue;
        }
        let Some(base_path) = base_canon.path_of(node) else {
            continue;
        };
        let was = base.headline_or(&base_path);
        for (i, c) in copies.iter().enumerate() {
            let Some(path) = copy_canon[i].path_of(node) else {
                continue;
            };
            let now = c.document.headline_or(&path);
            if now != was {
                add_structural(
                    structural,
                    node,
                    HEADLINE_CHANGED,
                    &was,
                    &now,
                    &c.member.member_id,
                );
            }
        }
    }
}

/// The key of a content value in [`SomTexts`].
fn content_key(path: &str) -> String {
    format!("c\u{0}{}", path)
}

/// The key of a form-field value in [`SomTexts`].
fn field_key(path: &str, field: &str) -> String {
    format!("f\u{0}{}\u{0}{}", path, field)
}

/// A SOM document's values as [`MergeTexts`], in document order (content
/// sorted, then forms and fields sorted).
struct SomTexts<'a>(&'a mut SpecDocument);

/// The values of a document in document order, as keys.
fn som_keys(doc: &SpecDocument) -> Vec<String> {
    let mut keys: Vec<String> = doc.content_paths().iter().map(|p| content_key(p)).collect();
    for p in doc.form_paths() {
        keys.extend(doc.form_field_names(&p).iter().map(|f| field_key(&p, f)));
    }
    keys
}

/// The value at `key` of [`som_keys`].
fn som_get(doc: &SpecDocument, key: &str) -> String {
    let parts: Vec<&str> = key.split('\u{0}').collect();
    match parts.as_slice() {
        ["c", path] => doc.content_or(path),
        ["f", path, field] => doc.form_field_or(path, field),
        _ => String::new(),
    }
}

impl MergeTexts for SomTexts<'_> {
    fn keys(&self) -> Vec<String> {
        som_keys(self.0)
    }

    fn get(&self, key: &str) -> String {
        som_get(self.0, key)
    }

    fn set(&mut self, key: &str, value: &str) {
        let parts: Vec<&str> = key.split('\u{0}').collect();
        match parts.as_slice() {
            ["c", path] => self.0.set_content(path, value),
            ["f", path, field] => self.0.set_form_field(path, field, value),
            _ => {}
        }
    }
}

/// The values of `doc`, in document order.
fn som_values_of(doc: &SpecDocument) -> Vec<String> {
    som_keys(doc).iter().map(|k| som_get(doc, k)).collect()
}

/// The value at `path` / `field` of `doc`, `""` when unset.
fn read_value(doc: &SpecDocument, path: &str, field: Option<&str>) -> String {
    match field {
        None => doc.content_or(path),
        Some(f) => doc.form_field_or(path, f),
    }
}

/// The values to merge: every value of the base and of the copies, items the
/// copies added aside, located in the merged document; in its document
/// order.
fn som_values(
    merged: &SpecDocument,
    base: &SpecDocument,
    copies: &[SpecReviewedCopy<SpecDocument>],
    added: &[String],
    refl: &SpecReflection,
) -> Vec<MergeValue> {
    let base_canon = CanonicalPaths::new(base, refl);
    let copy_canon: Vec<CanonicalPaths> = copies
        .iter()
        .map(|c| CanonicalPaths::new(&c.document, refl))
        .collect();
    let merged_canon = CanonicalPaths::new(merged, refl);
    let mut keys: BTreeMap<String, (String, Option<String>)> = BTreeMap::new();
    let mut collect = |doc: &SpecDocument, canon: &CanonicalPaths| {
        for p in doc.content_paths() {
            let node = canon.of(&p);
            keys.insert(content_key(&node), (node, None));
        }
        for p in doc.form_paths() {
            let node = canon.of(&p);
            for f in doc.form_field_names(&p) {
                keys.insert(field_key(&node, &f), (node.clone(), Some(f)));
            }
        }
    };
    collect(base, &base_canon);
    for (i, c) in copies.iter().enumerate() {
        collect(&c.document, &copy_canon[i]);
    }
    let mut values: Vec<MergeValue> = Vec::new();
    for (node, field) in keys.into_values() {
        if added.iter().any(|a| is_under(&node, a)) {
            continue;
        }
        let Some(base_path) = base_canon.path_of(&node) else {
            continue;
        };
        let path = merged_canon.path_of(&node).unwrap_or_else(|| node.clone());
        let text = is_text(refl, &path, field.as_deref());
        let conflict_home = if field.is_some() {
            Some(content_key(&path))
        } else if text {
            None
        } else {
            block_home(merged, refl, &path, false).map(|h| content_key(&h))
        };
        values.push(MergeValue {
            base: read_value(base, &base_path, field.as_deref()),
            copies: copies
                .iter()
                .enumerate()
                .map(|(i, c)| {
                    copy_canon[i]
                        .path_of(&node)
                        .map(|p| read_value(&c.document, &p, field.as_deref()))
                })
                .collect(),
            typed: !text,
            conflict_home,
            path,
            field,
        });
    }
    let order = |v: &MergeValue| {
        format!(
            "{}\u{0}{}\u{0}{}",
            if v.field.is_none() { 0 } else { 1 },
            v.path,
            v.field.as_deref().unwrap_or("")
        )
    };
    values.sort_by_cached_key(order);
    values
}

/// The class field of `cls` named `name` with kind `kind`, or `None`.
fn class_field<'c>(cls: Option<&'c SpecClass>, name: &str, kind: &str) -> Option<&'c SpecField> {
    cls?.field_named(name).filter(|f| f.kind == kind)
}

/// The model classes the revision entry is written with (`tom_specs_model`'s
/// document front matter).
const REVISION_ENTRY: &str = "RevisionEntry";
const DOCUMENT_HEADER: &str = "DocumentHeader";

/// The next minor of a `major.minor[.patch]` version; `0.1.0` for anything
/// else.
fn next_minor(version: Option<&str>) -> String {
    let v = version.unwrap_or("").trim();
    let parts: Vec<&str> = v.split('.').collect();
    let numeric = |s: &str| !s.is_empty() && s.bytes().all(|b| b.is_ascii_digit());
    if !(parts.len() == 2 || parts.len() == 3) || !parts.iter().all(|p| numeric(p)) {
        return "0.1.0".to_string();
    }
    let Ok(minor) = parts[1].parse::<u64>() else {
        return "0.1.0".to_string();
    };
    let next = format!("{}.{}", parts[0], minor + 1);
    if parts.len() == 3 {
        format!("{}.0", next)
    } else {
        next
    }
}

/// The month and day of an ISO 8601 date.
fn month_day(date: &str) -> Result<(i64, i64), SpecReviewMergeError> {
    let refused =
        || SpecReviewMergeError::new(format!("options.date \"{}\" is not an ISO 8601 date", date));
    let b = date.as_bytes();
    let digits =
        |r: std::ops::Range<usize>| b.get(r).is_some_and(|d| d.iter().all(u8::is_ascii_digit));
    if !(digits(0..4)
        && b.get(4) == Some(&b'-')
        && digits(5..7)
        && b.get(7) == Some(&b'-')
        && digits(8..10))
    {
        return Err(refused());
    }
    let month = date[5..7].parse().map_err(|_| refused())?;
    let day = date[8..10].parse().map_err(|_| refused())?;
    Ok((month, day))
}

/// Adds an item with a generated id to the list `field` at `list`, and
/// returns its path.
fn add_generated_item(
    doc: &mut SpecDocument,
    list: &str,
    field: &SpecField,
    date: (i64, i64),
) -> Result<String, SpecReviewMergeError> {
    let pattern = if field.section_id_pattern.is_empty() {
        format!("{}-xxx", field.name)
    } else {
        field.section_id_pattern.clone()
    };
    let id =
        generate_list_item_section_id(&pattern, date.0, date.1, &doc.list_item_section_ids(list));
    doc.add_list_item_with_section_id(list, &id)
        .map_err(list_error)
}

/// Writes one reviewer record into the list `field` at `list`.
fn add_reviewer_record(
    doc: &mut SpecDocument,
    refl: &SpecReflection,
    list: &str,
    field: &SpecField,
    member: &SpecReviewMember,
    guest: bool,
    date: (i64, i64),
) -> Result<(), SpecReviewMergeError> {
    let item = add_generated_item(doc, list, field, date)?;
    let Some(form) = class_field(
        refl.class_named(&field.element_type),
        "content",
        SPEC_FIELD_KIND_FORM,
    ) else {
        return Ok(());
    };
    let path = format!("{}/{}", item, refl.field_segment(form));
    doc.set_form_field(&path, "memberId", &member.member_id);
    doc.set_form_field(&path, "displayName", &member.display_name);
    doc.set_form_field(&path, "role", &member.role);
    if guest {
        doc.set_form_field(&path, "guest", "true");
    }
    Ok(())
}

/// Appends the draft revision entry when the root has a revision history:
/// the next minor version, the date and author, the team the round started
/// with and every reviewer who returned a copy, guests marked.
fn add_revision_entry(
    merged: &mut SpecDocument,
    root: &str,
    copies: &[SpecReviewMember],
    options: &SpecReviewMergeOptions,
    refl: &SpecReflection,
    ctx: &mut MergeContext,
) -> Result<(), SpecReviewMergeError> {
    let root_class = refl
        .root_for_segment(root)
        .and_then(|r| refl.class_named(&r.type_));
    let Some(root_class) = root_class else {
        return Ok(());
    };
    let Some(history) = root_class
        .fields
        .iter()
        .find(|f| f.kind == SPEC_FIELD_KIND_LIST && f.element_type == REVISION_ENTRY)
    else {
        return Ok(());
    };
    let date = month_day(&options.date)?;
    let header = root_class
        .fields
        .iter()
        .find(|f| f.type_ == DOCUMENT_HEADER);
    let header_form = header.and_then(|_| {
        class_field(
            refl.class_named(DOCUMENT_HEADER),
            "content",
            SPEC_FIELD_KIND_FORM,
        )
    });
    let current = match (header, header_form) {
        (Some(h), Some(form)) => merged
            .form_field(
                &format!(
                    "{}/{}/{}",
                    root,
                    refl.field_segment(h),
                    refl.field_segment(form)
                ),
                "version",
            )
            .cloned(),
        _ => None,
    };
    let version = next_minor(current.as_deref());
    let list = format!("{}/{}", root, refl.field_segment(history));
    let item = add_generated_item(merged, &list, history, date)?;
    let entry = refl.class_named(REVISION_ENTRY);
    if let Some(form) = class_field(entry, "content", SPEC_FIELD_KIND_FORM) {
        let path = format!("{}/{}", item, refl.field_segment(form));
        merged.set_form_field(&path, "version", &version);
        merged.set_form_field(&path, "date", &options.date);
        merged.set_form_field(&path, "author", &options.author);
    }
    let team: HashSet<&str> = options.team.iter().map(|m| m.member_id.as_str()).collect();
    let records: [(&str, &[SpecReviewMember], bool); 2] = [
        ("reviewTeam", &options.team, false),
        ("reviewers", copies, true),
    ];
    for (name, members, mark_guests) in records {
        let Some(list) = class_field(entry, name, SPEC_FIELD_KIND_LIST) else {
            continue;
        };
        let list_path = format!("{}/{}", item, refl.field_segment(list));
        for m in members {
            let guest = mark_guests && !team.contains(m.member_id.as_str());
            add_reviewer_record(merged, refl, &list_path, list, m, guest, date)?;
        }
    }
    ctx.report.revision = Some(SpecMergeRevision {
        path: item,
        version,
    });
    Ok(())
}

/// The root segment of a document: the first segment of its paths, else the
/// model's first root.
fn root_of(doc: &SpecDocument, refl: &SpecReflection) -> Option<String> {
    let json = doc.to_json();
    let any = json
        .content
        .keys()
        .chain(json.forms.keys())
        .chain(json.lists.keys())
        .chain(json.headlines.keys())
        .next();
    match any {
        Some(p) => p.split('/').next().map(str::to_string),
        None => refl.roots().first().map(|r| refl.root_segment(r)),
    }
}

/// Merges the reviewed `copies` of the SOM document `base` (SOM §11.9.9) by
/// model path, list items matched by section id. Neither the base nor a copy
/// is changed. A copy holding a path `model` does not resolve is refused with
/// [`SpecReviewMergeError`].
pub fn merge_reviews(
    model: &SpecModel,
    base: &SpecDocument,
    copies: &[SpecReviewedCopy<SpecDocument>],
    options: &SpecReviewMergeOptions,
) -> Result<SpecReviewMergeResult<SpecDocument>, SpecReviewMergeError> {
    let refl = SpecReflection::new(model);
    check_structure(base, "the base", &refl)?;
    for c in copies {
        check_structure(
            &c.document,
            &format!("the copy of {}", c.member.member_id),
            &refl,
        )?;
    }
    let base_texts = som_values_of(base);
    let copy_texts: Vec<Vec<String>> = copies.iter().map(|c| som_values_of(&c.document)).collect();
    let members: Vec<SpecReviewMember> = copies.iter().map(|c| c.member.clone()).collect();
    let mut ctx = MergeContext::new(&members, &base_texts);
    let mut merged = base.clone();
    let added = merge_structure(&mut merged, base, copies, &refl, model, &mut ctx)?;
    let values = som_values(&merged, base, copies, &added, &refl);
    let root = root_of(base, &refl);
    let root_class = root
        .as_deref()
        .and_then(|r| refl.root_for_segment(r))
        .and_then(|r| refl.class_named(&r.type_));
    let home = match (
        &root,
        class_field(root_class, "content", SPEC_FIELD_KIND_CONTENT),
    ) {
        (Some(root), Some(content)) => {
            let path = format!("{}/{}", root, refl.field_segment(content));
            Some(GuestHome {
                key: content_key(&path),
                path,
            })
        }
        _ => None,
    };
    let phase = TextPhase {
        base_texts: &base_texts,
        copy_texts: &copy_texts,
        copies: &members,
        options,
        home,
    };
    merge_texts(
        &values,
        |_, v| match &v.field {
            None => content_key(&v.path),
            Some(f) => field_key(&v.path, f),
        },
        &mut SomTexts(&mut merged),
        &phase,
        &mut ctx,
    );
    if let Some(root) = &root {
        add_revision_entry(&mut merged, root, &members, options, &refl, &mut ctx)?;
    }
    Ok(SpecReviewMergeResult {
        merged,
        report: ctx.report,
    })
}
