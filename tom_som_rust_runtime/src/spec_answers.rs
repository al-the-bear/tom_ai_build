//! `spec_answers` — the answers of a review round, extracted for a step folder
//! (SOM §11.9.7). A port of the Dart reference `spec_answers.dart`.
//!
//! A step of the TomSpecs process starts by collecting what the reviewer wrote
//! into the document — answers to the agent's questions, comments, and
//! optionally the questions still open and the inline marks — into the step
//! folder's `answers.md`. The annotations stay in the document; this reads
//! them through [`SpecReviewAnnotations::list`] and never writes.

use crate::json::Json;
use crate::spec_document::SpecDocument;
use crate::spec_document_markdown::SpecDocumentMarkdown;
use crate::spec_model::{SpecModel, SpecRoot};
use crate::spec_review_annotations::{
    SpecMarkKind, SpecReviewAnnotationKind, SpecReviewAnnotations,
};
use std::collections::{HashMap, HashSet};

/// What an extracted entry is.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SpecAnswerKind {
    /// A question with an answer.
    Answered,
    /// A question without an answer.
    Open,
    /// A comment block.
    Comment,
    /// An inline mark.
    Mark,
}

impl SpecAnswerKind {
    /// Every kind, in declaration order.
    pub const ALL: [SpecAnswerKind; 4] = [
        SpecAnswerKind::Answered,
        SpecAnswerKind::Open,
        SpecAnswerKind::Comment,
        SpecAnswerKind::Mark,
    ];

    /// The wire name (`answered`, `open`, `comment`, `mark`).
    pub fn name(self) -> &'static str {
        match self {
            SpecAnswerKind::Answered => "answered",
            SpecAnswerKind::Open => "open",
            SpecAnswerKind::Comment => "comment",
            SpecAnswerKind::Mark => "mark",
        }
    }
}

/// One extracted entry.
#[derive(Debug, Clone, PartialEq)]
pub struct SpecAnswerEntry {
    /// What it is.
    pub kind: SpecAnswerKind,
    /// The question or comment id (`BQ-81`, `C-12`), or `M-<n>` for a mark;
    /// `None` for a comment without an id.
    pub id: Option<String>,
    /// The section-id chain of the rendition heading the entry sits under
    /// (`SBP > INSC > SYSUM`).
    pub section: String,
    /// The 1-based line in the document's Markdown rendition.
    pub line: usize,
    /// The document path of the value holding the entry.
    pub path: String,
    /// The form field holding it, or `None` for content.
    pub field: Option<String>,
    /// A question's topic.
    pub topic: Option<String>,
    /// Whether a question is part of a combined form block (its topic is then
    /// the field it asks about).
    pub combined: bool,
    /// A question's text, a comment's text, or a mark's markup.
    pub text: String,
    /// A question's answer (empty when open).
    pub answer: String,
    /// A comment's author.
    pub author: Option<String>,
    /// A mark's kind.
    pub mark_kind: Option<SpecMarkKind>,
    /// A mark's text when rejected.
    pub old_text: Option<String>,
    /// A mark's text when accepted.
    pub new_text: Option<String>,
    /// A mark's comment.
    pub comment: Option<String>,
}

impl SpecAnswerEntry {
    fn new(kind: SpecAnswerKind, section: String, line: usize, path: &str) -> Self {
        SpecAnswerEntry {
            kind,
            id: None,
            section,
            line,
            path: path.to_string(),
            field: None,
            topic: None,
            combined: false,
            text: String::new(),
            answer: String::new(),
            author: None,
            mark_kind: None,
            old_text: None,
            new_text: None,
            comment: None,
        }
    }

    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        fn s(v: &str) -> Json {
            Json::Str(v.to_string())
        }
        fn o(v: &Option<String>) -> Json {
            v.as_deref().map(s).unwrap_or(Json::Null)
        }
        let pairs: Vec<(&str, Json)> = vec![
            ("kind", s(self.kind.name())),
            ("id", o(&self.id)),
            ("section", s(&self.section)),
            ("line", Json::Int(self.line as i64)),
            ("path", s(&self.path)),
            ("field", o(&self.field)),
            ("topic", o(&self.topic)),
            ("combined", Json::Bool(self.combined)),
            ("text", s(&self.text)),
            ("answer", s(&self.answer)),
            ("author", o(&self.author)),
            (
                "markKind",
                self.mark_kind.map(|k| s(k.name())).unwrap_or(Json::Null),
            ),
            ("oldText", o(&self.old_text)),
            ("newText", o(&self.new_text)),
            ("comment", o(&self.comment)),
        ];
        Json::Object(pairs.into_iter().map(|(k, v)| (k.to_string(), v)).collect())
    }
}

/// The counts a step's closing item reports.
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct SpecAnswerCounts {
    /// Questions with an answer.
    pub answered: usize,
    /// Questions without one.
    pub open: usize,
    /// Comment blocks.
    pub comments: usize,
    /// Inline marks.
    pub marks: usize,
}

impl std::ops::Add for SpecAnswerCounts {
    type Output = SpecAnswerCounts;

    /// The sum of two counts.
    fn add(self, o: SpecAnswerCounts) -> SpecAnswerCounts {
        SpecAnswerCounts {
            answered: self.answered + o.answered,
            open: self.open + o.open,
            comments: self.comments + o.comments,
            marks: self.marks + o.marks,
        }
    }
}

impl SpecAnswerCounts {
    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        Json::Object(vec![
            ("answered".to_string(), Json::Int(self.answered as i64)),
            ("open".to_string(), Json::Int(self.open as i64)),
            ("comments".to_string(), Json::Int(self.comments as i64)),
            ("marks".to_string(), Json::Int(self.marks as i64)),
        ])
    }
}

/// The extraction of one document.
#[derive(Debug, Clone, PartialEq)]
pub struct SpecAnswerExtract {
    /// The document's label in `answers.md` (its file name, e.g.
    /// `tom_uam.sbp`).
    pub label: String,
    /// The document root's section id, written in front of a comment id
    /// (`SBP C-12`).
    pub qualifier: String,
    /// Every entry, in document order.
    pub entries: Vec<SpecAnswerEntry>,
}

impl SpecAnswerExtract {
    /// The counts over [`entries`](Self::entries).
    pub fn counts(&self) -> SpecAnswerCounts {
        let mut c = SpecAnswerCounts::default();
        for e in &self.entries {
            match e.kind {
                SpecAnswerKind::Answered => c.answered += 1,
                SpecAnswerKind::Open => c.open += 1,
                SpecAnswerKind::Comment => c.comments += 1,
                SpecAnswerKind::Mark => c.marks += 1,
            }
        }
        c
    }

    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        Json::Object(vec![
            ("label".to_string(), Json::Str(self.label.clone())),
            ("qualifier".to_string(), Json::Str(self.qualifier.clone())),
            (
                "entries".to_string(),
                Json::Array(self.entries.iter().map(SpecAnswerEntry::to_json).collect()),
            ),
            ("counts".to_string(), self.counts().to_json()),
        ])
    }
}

/// `^(#+) <!--\[([^\]]+)\]-->`: the heading level and section id.
fn parse_heading(line: &str) -> Option<(usize, &str)> {
    let level = line.bytes().take_while(|&b| b == b'#').count();
    if level == 0 {
        return None;
    }
    let rest = line[level..].strip_prefix(" <!--[")?;
    let end = rest.find(']')?;
    if end == 0 || !rest[end..].starts_with("]-->") {
        return None;
    }
    Some((level, &rest[..end]))
}

fn root_segment(r: &SpecRoot) -> &str {
    if r.section_id.is_empty() {
        &r.type_
    } else {
        &r.section_id
    }
}

fn upper_first(s: &str) -> String {
    let mut chars = s.chars();
    match chars.next() {
        Some(c) => c.to_uppercase().collect::<String>() + chars.as_str(),
        None => String::new(),
    }
}

/// Extracts the annotations of `doc` (or of the subtree at `path`) with their
/// place in the document's Markdown rendition under `model`, in rendition
/// order (by line). The error is the rendition's
/// ([`SpecDocumentMarkdown::export_root_with_map`]).
pub fn extract_answers(
    model: &SpecModel,
    doc: &SpecDocument,
    label: &str,
    path: Option<&str>,
) -> Result<SpecAnswerExtract, String> {
    let root = model
        .roots
        .iter()
        .find(|r| doc.has_values_under(root_segment(r)))
        .or_else(|| model.roots.first())
        .ok_or_else(|| "the model has no roots".to_string())?;
    let qualifier = root_segment(root).to_string();
    let rendition = SpecDocumentMarkdown::new(model, doc).export_root_with_map(root)?;
    let lines: Vec<&str> = rendition.markdown.split('\n').collect();

    // The section-id chain of every heading line (1-based).
    let mut chains: HashMap<usize, String> = HashMap::new();
    let mut stack: Vec<(usize, &str)> = Vec::new();
    for (i, line) in lines.iter().enumerate() {
        let Some((level, id)) = parse_heading(line) else {
            continue;
        };
        while stack.last().is_some_and(|top| top.0 >= level) {
            stack.pop();
        }
        stack.push((level, id));
        let chain: Vec<&str> = stack.iter().map(|e| e.1).collect();
        chains.insert(i + 1, chain.join(" > "));
    }

    // The heading line of a value: the heading whose path is the longest
    // prefix of the value's path (on equal length, the first). The map is
    // ordered by line.
    let heading_line = |value_path: &str| -> usize {
        let mut best = 0usize;
        let mut best_len: i64 = -1;
        for (&l, hp) in &rendition.heading_paths {
            let matches = value_path == hp
                || (value_path.starts_with(hp.as_str()) && value_path[hp.len()..].starts_with('/'));
            if matches && hp.len() as i64 > best_len {
                best = l;
                best_len = hp.len() as i64;
            }
        }
        best
    };

    let chain_at = |line: usize| -> String {
        let mut l = line;
        while l >= 1 {
            if let Some(c) = chains.get(&l) {
                return c.clone();
            }
            l -= 1;
        }
        qualifier.clone()
    };

    let mut claimed: HashSet<usize> = HashSet::new();
    // The claimed set is shared across the whole extraction.
    // The rendition line of an annotation: the first unclaimed line after the
    // value's heading whose trimmed text is the annotation's first line. A
    // form field's first line renders behind its label (`Owner: …`, the
    // field name with its first letter upper-cased).
    let locate = |claimed: &mut HashSet<usize>,
                  value_path: &str,
                  field: Option<&str>,
                  value_line: usize,
                  first_line: &str|
     -> usize {
        let h = heading_line(value_path);
        let want = first_line.trim();
        let labelled = match field {
            Some(f) if value_line == 0 => {
                Some(format!("{}: {}", upper_first(f), want).trim().to_string())
            }
            _ => None,
        };
        for (i, raw) in lines.iter().enumerate().skip(h) {
            let l = i + 1;
            if l <= h || claimed.contains(&l) {
                continue;
            }
            let t = raw.trim();
            if t == want || labelled.as_deref() == Some(t) {
                claimed.insert(l);
                return l;
            }
        }
        if h == 0 {
            1
        } else {
            h
        }
    };

    let in_scope = |p: &str| match path {
        None => true,
        Some(path) => p == path || (p.starts_with(path) && p[path.len()..].starts_with('/')),
    };

    // The annotations API wants a mutable borrow; it only reads here.
    let mut copy = doc.clone();
    let api = SpecReviewAnnotations::new(&mut copy);
    // `list()` and `list_marks()` give the marks in the same order.
    let marks = api.list_marks(None);
    let mut mark_index = 0usize;
    let mut entries: Vec<SpecAnswerEntry> = Vec::new();
    for a in api.list() {
        // Every mark consumes its listing entry before the scope check, so the
        // marks in a subtree keep their document-wide `M-<n>`.
        let m = if a.kind == SpecReviewAnnotationKind::Mark {
            mark_index += 1;
            Some(&marks[mark_index - 1])
        } else {
            None
        };
        if !in_scope(&a.path) {
            continue;
        }
        let value = match &a.field {
            None => doc.content(&a.path),
            Some(f) => doc.form_field(&a.path, f),
        }
        .cloned()
        .unwrap_or_default();
        let first = value.split('\n').nth(a.line).unwrap_or("");
        match a.kind {
            SpecReviewAnnotationKind::Question => {
                let line = locate(&mut claimed, &a.path, a.field.as_deref(), a.line, first);
                let kind = if a.is_open() {
                    SpecAnswerKind::Open
                } else {
                    SpecAnswerKind::Answered
                };
                let mut e = SpecAnswerEntry::new(kind, chain_at(line), line, &a.path);
                e.id = a.id.clone();
                e.field = a.field.clone();
                e.topic = a.topic.clone();
                e.combined = a.combined;
                e.text = a.text.clone();
                e.answer = a.answer.clone();
                entries.push(e);
            }
            SpecReviewAnnotationKind::Comment => {
                let line = locate(&mut claimed, &a.path, a.field.as_deref(), a.line, first);
                let mut e =
                    SpecAnswerEntry::new(SpecAnswerKind::Comment, chain_at(line), line, &a.path);
                e.id = a.id.clone();
                e.field = a.field.clone();
                e.text = a.text.clone();
                e.author = a.author.clone();
                entries.push(e);
            }
            SpecReviewAnnotationKind::Mark => {
                let m = m.expect("a mark annotation has a listing entry");
                let line = locate(&mut claimed, &a.path, a.field.as_deref(), a.line, first);
                // A line holding several marks is found once; later marks on
                // it share the line.
                claimed.remove(&line);
                let mut e =
                    SpecAnswerEntry::new(SpecAnswerKind::Mark, chain_at(line), line, &a.path);
                e.id = Some(m.id.clone());
                e.field = a.field.clone();
                e.text = m.markup.clone();
                e.mark_kind = a.mark_kind;
                e.old_text = Some(m.old_text.clone());
                e.new_text = Some(m.new_text.clone());
                e.comment = a.comment.clone();
                entries.push(e);
            }
        }
    }
    // Rendition order: by line; entries on one line keep their order.
    entries.sort_by_key(|e| e.line);
    Ok(SpecAnswerExtract {
        label: label.to_string(),
        qualifier,
        entries,
    })
}

/// What `answers.md` includes besides the answered questions and comments.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecAnswerRenderOptions {
    /// List the questions still open.
    pub include_open: bool,
    /// List the inline marks.
    pub include_marks: bool,
    /// The file's title.
    pub title: String,
}

impl Default for SpecAnswerRenderOptions {
    fn default() -> Self {
        SpecAnswerRenderOptions {
            include_open: false,
            include_marks: false,
            title: "Answers".to_string(),
        }
    }
}

/// A labelled value: `- **Label:** first line`, further lines indented two
/// spaces.
fn item(label: &str, value: &str) -> String {
    let mut ls = value.split('\n');
    let mut b = format!("- **{}:**", label);
    if let Some(first) = ls.next() {
        if !first.is_empty() {
            b.push(' ');
            b.push_str(first);
        }
    }
    for l in ls {
        if l.is_empty() {
            b.push('\n');
        } else {
            b.push_str("\n  ");
            b.push_str(l);
        }
    }
    b
}

fn plural(n: usize, noun: &str) -> String {
    if n == 1 {
        format!("{} {}", n, noun)
    } else {
        format!("{} {}s", n, noun)
    }
}

fn count_line(c: &SpecAnswerCounts, o: &SpecAnswerRenderOptions) -> String {
    let mut parts = vec![
        plural(c.answered, "answered question"),
        plural(c.open, "open question"),
        plural(c.comments, "comment"),
    ];
    if o.include_marks {
        parts.push(plural(c.marks, "inline mark"));
    }
    format!("{}.", parts.join(", "))
}

fn or_null(s: &Option<String>) -> &str {
    s.as_deref().unwrap_or("null")
}

fn entry_heading(x: &SpecAnswerExtract, e: &SpecAnswerEntry) -> String {
    match e.kind {
        SpecAnswerKind::Answered | SpecAnswerKind::Open => {
            format!("{} — {}", or_null(&e.id), or_null(&e.topic))
        }
        SpecAnswerKind::Comment => match &e.id {
            None => format!("Comment without id (line {})", e.line),
            Some(id) => format!("{} {}", x.qualifier, id),
        },
        SpecAnswerKind::Mark => format!(
            "{} — {}",
            or_null(&e.id),
            e.mark_kind.map(SpecMarkKind::name).unwrap_or("null")
        ),
    }
}

/// Renders `extracts` as a step folder's `answers.md`: deterministic, grouped
/// per document in the order given, entries in document order.
pub fn render_answers(extracts: &[SpecAnswerExtract], options: &SpecAnswerRenderOptions) -> String {
    let total = extracts
        .iter()
        .fold(SpecAnswerCounts::default(), |t, x| t + x.counts());
    let mut out: Vec<String> = vec![
        format!("# {}", options.title),
        String::new(),
        count_line(&total, options),
    ];
    for x in extracts {
        out.push(String::new());
        out.push(format!("## {}", x.label));
        out.push(String::new());
        out.push(count_line(&x.counts(), options));
        let mut section = |heading: &str, kind: SpecAnswerKind| {
            let es: Vec<&SpecAnswerEntry> = x.entries.iter().filter(|e| e.kind == kind).collect();
            out.push(String::new());
            out.push(format!("### {}", heading));
            if es.is_empty() {
                out.push(String::new());
                out.push("None.".to_string());
                return;
            }
            for e in es {
                out.push(String::new());
                out.push(format!("#### {}", entry_heading(x, e)));
                out.push(String::new());
                out.push(item("Section", &format!("`{}`", e.section)));
                out.push(item("Line", &e.line.to_string()));
                if let Some(f) = &e.field {
                    out.push(item("Field", &format!("`{}`", f)));
                }
                match kind {
                    SpecAnswerKind::Answered | SpecAnswerKind::Open => {
                        out.push(item("Question", &e.text));
                        if kind == SpecAnswerKind::Answered {
                            out.push(item("Answer", &e.answer));
                        }
                    }
                    SpecAnswerKind::Comment => {
                        if let Some(author) = &e.author {
                            out.push(item("Author", author));
                        }
                        out.push(item("Comment", &e.text));
                    }
                    SpecAnswerKind::Mark => {
                        out.push(item("Markup", &format!("`{}`", e.text)));
                        out.push(item("Old", e.old_text.as_deref().unwrap_or("")));
                        out.push(item("New", e.new_text.as_deref().unwrap_or("")));
                        if let Some(c) = &e.comment {
                            out.push(item("Note", c));
                        }
                    }
                }
            }
        };
        section("Answered questions", SpecAnswerKind::Answered);
        section("Comments", SpecAnswerKind::Comment);
        if options.include_open {
            section("Open questions", SpecAnswerKind::Open);
        }
        if options.include_marks {
            section("Inline marks", SpecAnswerKind::Mark);
        }
    }
    format!("{}\n", out.join("\n"))
}
