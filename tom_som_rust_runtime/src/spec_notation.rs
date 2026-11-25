//! The reading notation's scanner: one call per text value, returning the
//! value's fenced divs, bracketed spans and citation shapes with their kind,
//! attributes, source ranges and nesting, and the findings the DocSpecs
//! specification lists for the notation (*Reading Notation*, RN-1 … RN-13).
//!
//! The Rust port of `tom_som_typescript_runtime`'s `spec_notation.ts` (itself
//! the port of `tom_som_dart_runtime`'s `spec_notation.dart`): the same
//! grammar, the same elements and findings, the same offsets; all run
//! `tom_som_conformance/corpus/notation_cases.json`.
//!
//! - a **fenced div** is a line of at least three colons, indented up to three
//!   spaces, then attribute braces (`::: {.provenance}`) or a bare kind word
//!   (`::: aside`); it closes at a line of at least three colons and nothing
//!   else, and a closing fence closes the innermost open div;
//! - a **bracketed span** is `[text]` followed immediately by attribute braces,
//!   inside one paragraph;
//! - a **citation shape** is `(-> ids)` (kind `trace`), `(<- source)` or
//!   `(<~ source)` (kind `provenance`);
//! - fenced code and code spans are literal, and so are `\:::` and `]\{.`.
//!
//! An unknown kind passes through as an element like any other.
//!
//! **Offsets are UTF-16 code units**, as in every other runtime: a Rust string
//! is UTF-8, so the scanner works on code points (`char`s) and converts each
//! offset it reports (`start`, `end`, `content_start`, `content_end`,
//! `offset`) to UTF-16 code units. Whitespace, `trim` and the regular
//! expressions' `.` follow JavaScript, as the TypeScript scanner does.
//! [`NotationElement::to_json`] slices the text by those UTF-16 offsets.

use std::collections::HashMap;
use std::collections::HashSet;

use crate::json::Json;

/// The kinds the notation registers (RN-5); any other kind passes through.
pub const REGISTERED_NOTATION_KINDS: [&str; 9] = [
    "provenance",
    "trace",
    "editorial",
    "aside",
    "linked",
    "derived",
    "refs",
    "records",
    "rejected",
];

/// The kinds the notation registers (RN-5), as [`REGISTERED_NOTATION_KINDS`].
pub fn registered_notation_kinds() -> &'static [&'static str] {
    &REGISTERED_NOTATION_KINDS
}

/// The notation's findings (RN-10); [`NotationFindingCode::as_str`] is the
/// rule's name in the DocSpecs validator.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum NotationFindingCode {
    UnclosedDiv,
    StrayClosingFence,
    UnclosedSpan,
    DivWithoutKind,
    UnknownKind,
    MarkAcrossNotation,
    AnnotationInsideDiv,
    DivInsideAnnotation,
    RejectedBlock,
}

impl NotationFindingCode {
    /// Every code, in declaration order (the order findings at one offset
    /// are sorted by).
    pub const ALL: [NotationFindingCode; 9] = [
        NotationFindingCode::UnclosedDiv,
        NotationFindingCode::StrayClosingFence,
        NotationFindingCode::UnclosedSpan,
        NotationFindingCode::DivWithoutKind,
        NotationFindingCode::UnknownKind,
        NotationFindingCode::MarkAcrossNotation,
        NotationFindingCode::AnnotationInsideDiv,
        NotationFindingCode::DivInsideAnnotation,
        NotationFindingCode::RejectedBlock,
    ];

    /// The code's name (`unclosedDiv`, …), the DocSpecs validator's rule.
    pub fn as_str(self) -> &'static str {
        match self {
            NotationFindingCode::UnclosedDiv => "unclosedDiv",
            NotationFindingCode::StrayClosingFence => "strayClosingFence",
            NotationFindingCode::UnclosedSpan => "unclosedSpan",
            NotationFindingCode::DivWithoutKind => "divWithoutKind",
            NotationFindingCode::UnknownKind => "unknownKind",
            NotationFindingCode::MarkAcrossNotation => "markAcrossNotation",
            NotationFindingCode::AnnotationInsideDiv => "annotationInsideDiv",
            NotationFindingCode::DivInsideAnnotation => "divInsideAnnotation",
            NotationFindingCode::RejectedBlock => "rejectedBlock",
        }
    }

    /// The code named `name`, `None` for any other name.
    pub fn from_name(name: &str) -> Option<NotationFindingCode> {
        NotationFindingCode::ALL
            .iter()
            .copied()
            .find(|c| c.as_str() == name)
    }

    fn index(self) -> usize {
        NotationFindingCode::ALL
            .iter()
            .position(|c| *c == self)
            .unwrap_or(0)
    }
}

/// The severity of `code`: an unknown kind is a `warning`, the rest `error`s.
pub fn notation_severity(code: NotationFindingCode) -> &'static str {
    if code == NotationFindingCode::UnknownKind {
        "warning"
    } else {
        "error"
    }
}

/// `text` between the UTF-16 offsets `start` and `end`.
fn utf16_slice(text: &str, start: usize, end: usize) -> String {
    let units: Vec<u16> = text.encode_utf16().collect();
    let end = end.min(units.len());
    let start = start.min(end);
    String::from_utf16_lossy(&units[start..end])
}

/// One element of the notation: a div, a span or a citation.
#[derive(Debug, Clone, PartialEq)]
pub struct NotationElement {
    /// `div`, `span` or `citation`.
    pub type_: &'static str,
    /// The first class; `trace` / `provenance` for a citation; `None` without
    /// a class.
    pub kind: Option<String>,
    /// Every class, the kind first.
    pub classes: Vec<String>,
    /// The `#id` of the attributes (not a section id).
    pub id: Option<String>,
    /// The `key="value"` pairs, in their order.
    pub attributes: Vec<(String, String)>,
    /// A citation's arrow: `->`, `<-` or `<~`; `None` otherwise.
    pub shape: Option<&'static str>,
    /// The UTF-16 offset of the first character.
    pub start: usize,
    /// The UTF-16 offset after the last character.
    pub end: usize,
    /// The UTF-16 offset of the content.
    pub content_start: usize,
    /// The UTF-16 offset after the content.
    pub content_end: usize,
    /// The 1-based line of `start`.
    pub line: usize,
    /// The 1-based line of the last character.
    pub end_line: usize,
    /// `false` for a div without a closing fence.
    pub closed: bool,
    /// The elements nested in this one, in source order.
    pub children: Vec<NotationElement>,
}

impl NotationElement {
    /// Whether the kind is registered.
    pub fn is_registered(&self) -> bool {
        self.kind
            .as_deref()
            .is_some_and(|k| REGISTERED_NOTATION_KINDS.contains(&k))
    }

    /// The element's text in `text` (the scanned value).
    pub fn source(&self, text: &str) -> String {
        utf16_slice(text, self.start, self.end)
    }

    /// The element's content in `text` (the scanned value).
    pub fn content(&self, text: &str) -> String {
        utf16_slice(text, self.content_start, self.content_end)
    }

    /// The element as the conformance corpus writes it.
    pub fn to_json(&self, text: &str) -> Json {
        let opt = |s: &Option<String>| match s {
            Some(v) => Json::Str(v.clone()),
            None => Json::Null,
        };
        Json::Object(vec![
            ("type".to_string(), Json::Str(self.type_.to_string())),
            ("kind".to_string(), opt(&self.kind)),
            (
                "classes".to_string(),
                Json::Array(self.classes.iter().map(|c| Json::Str(c.clone())).collect()),
            ),
            ("id".to_string(), opt(&self.id)),
            (
                "attributes".to_string(),
                Json::Object(
                    self.attributes
                        .iter()
                        .map(|(k, v)| (k.clone(), Json::Str(v.clone())))
                        .collect(),
                ),
            ),
            (
                "shape".to_string(),
                match self.shape {
                    Some(s) => Json::Str(s.to_string()),
                    None => Json::Null,
                },
            ),
            ("start".to_string(), Json::Int(self.start as i64)),
            ("end".to_string(), Json::Int(self.end as i64)),
            ("line".to_string(), Json::Int(self.line as i64)),
            ("endLine".to_string(), Json::Int(self.end_line as i64)),
            ("closed".to_string(), Json::Bool(self.closed)),
            ("source".to_string(), Json::Str(self.source(text))),
            ("content".to_string(), Json::Str(self.content(text))),
            (
                "children".to_string(),
                Json::Array(self.children.iter().map(|c| c.to_json(text)).collect()),
            ),
        ])
    }
}

/// One finding of the scan.
#[derive(Debug, Clone, PartialEq)]
pub struct NotationFinding {
    pub code: NotationFindingCode,
    /// The UTF-16 offset it stands at.
    pub offset: usize,
    /// Its 1-based line.
    pub line: usize,
    pub message: String,
}

impl NotationFinding {
    /// The severity of the code.
    pub fn severity(&self) -> &'static str {
        notation_severity(self.code)
    }

    /// The finding as the conformance corpus writes it.
    pub fn to_json(&self) -> Json {
        Json::Object(vec![
            (
                "code".to_string(),
                Json::Str(self.code.as_str().to_string()),
            ),
            (
                "severity".to_string(),
                Json::Str(self.severity().to_string()),
            ),
            ("line".to_string(), Json::Int(self.line as i64)),
        ])
    }
}

impl std::fmt::Display for NotationFinding {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "line {}: {} \u{2014} {}",
            self.line,
            self.code.as_str(),
            self.message
        )
    }
}

/// The result of [`scan_notation`].
#[derive(Debug, Clone)]
pub struct NotationScan {
    pub text: String,
    /// The elements not nested in another, in source order.
    pub elements: Vec<NotationElement>,
    /// The findings, by offset.
    pub findings: Vec<NotationFinding>,
}

impl NotationScan {
    /// Every element, depth-first in source order.
    pub fn all(&self) -> Vec<&NotationElement> {
        fn walk<'a>(list: &'a [NotationElement], out: &mut Vec<&'a NotationElement>) {
            for e in list {
                out.push(e);
                walk(&e.children, out);
            }
        }
        let mut out = Vec::new();
        walk(&self.elements, &mut out);
        out
    }

    /// Whether a finding of severity `error` is present.
    pub fn has_errors(&self) -> bool {
        self.findings.iter().any(|f| f.severity() == "error")
    }
}

/// Scans one text value for the reading notation. `tom_specs` says the value
/// belongs to a TomSpecs rendition: only then are a div without a class and
/// an unregistered kind reported (RN-10).
pub fn scan_notation(text: &str, tom_specs: bool) -> NotationScan {
    Scanner::new(text, tom_specs).scan()
}

// --- JavaScript character classes --------------------------------------------

/// JavaScript's whitespace (`\s`, `String.prototype.trim`).
fn is_js_ws(c: char) -> bool {
    matches!(
        c,
        '\t' | '\n' | '\u{0B}' | '\u{0C}' | '\r' | ' ' | '\u{A0}' | '\u{1680}' | '\u{2000}'
            ..='\u{200A}'
                | '\u{2028}'
                | '\u{2029}'
                | '\u{202F}'
                | '\u{205F}'
                | '\u{3000}'
                | '\u{FEFF}'
    )
}

/// A JavaScript line terminator: what the regular expressions' `.` excludes.
fn is_line_terminator(c: char) -> bool {
    matches!(c, '\n' | '\r' | '\u{2028}' | '\u{2029}')
}

fn js_trim(s: &[char]) -> &[char] {
    let mut start = 0;
    let mut end = s.len();
    while start < end && is_js_ws(s[start]) {
        start += 1;
    }
    while end > start && is_js_ws(s[end - 1]) {
        end -= 1;
    }
    &s[start..end]
}

fn js_trim_left(s: &[char]) -> &[char] {
    let mut start = 0;
    while start < s.len() && is_js_ws(s[start]) {
        start += 1;
    }
    &s[start..]
}

fn starts_with_at(text: &[char], at: usize, pat: &str) -> bool {
    let n = pat.chars().count();
    at + n <= text.len() && text[at..at + n].iter().copied().eq(pat.chars())
}

/// The first index `>= from` where `pat` stands in `text`.
fn find_from(text: &[char], from: usize, pat: &str) -> Option<usize> {
    let n = pat.chars().count();
    if text.len() < n {
        return None;
    }
    (from..=text.len() - n).find(|&i| starts_with_at(text, i, pat))
}

const ASCII_PUNCTUATION: &str = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~";
const MARK_OPENERS: [&str; 5] = ["{++", "{--", "{~~", "{==", "{>>"];

fn mark_closer(opener: &str) -> &'static str {
    match opener {
        "{++" => "++}",
        "{--" => "--}",
        "{~~" => "~~}",
        "{==" => "==}",
        _ => "<<}",
    }
}

fn citation_kind(arrow: &[char]) -> Option<(&'static str, &'static str)> {
    match arrow {
        ['-', '>'] => Some(("->", "trace")),
        ['<', '-'] => Some(("<-", "provenance")),
        ['<', '~'] => Some(("<~", "provenance")),
        _ => None,
    }
}

// --- The line grammar (the TypeScript scanner's regular expressions) ---------

/// ` {0,3}`: the index after up to three leading spaces, or `None` when a
/// fourth space follows.
fn indent_end(line: &[char]) -> Option<usize> {
    let mut i = 0;
    while i < line.len() && line[i] == ' ' {
        i += 1;
        if i > 3 {
            return None;
        }
    }
    Some(i)
}

/// The fence opening of a div from `at` on (`:{3,}[ \t]*(?:\{(.*)\}|(word))[ \t]*$`):
/// `Some(Ok(inner))` for attribute braces, `Some(Err(word))` for a bare kind.
fn div_open_from(line: &[char], at: usize) -> Option<Result<String, String>> {
    let mut i = at;
    while i < line.len() && line[i] == ':' {
        i += 1;
    }
    if i - at < 3 {
        return None;
    }
    while i < line.len() && (line[i] == ' ' || line[i] == '\t') {
        i += 1;
    }
    let mut end = line.len();
    while end > i && (line[end - 1] == ' ' || line[end - 1] == '\t') {
        end -= 1;
    }
    if i >= end {
        return None;
    }
    if line[i] == '{' {
        if end - i < 2 || line[end - 1] != '}' {
            return None;
        }
        let inner = &line[i + 1..end - 1];
        if inner.iter().any(|c| is_line_terminator(*c)) {
            return None;
        }
        return Some(Ok(inner.iter().collect()));
    }
    if !line[i].is_ascii_alphabetic() {
        return None;
    }
    let word = &line[i..end];
    if word
        .iter()
        .all(|c| c.is_ascii_alphanumeric() || *c == '_' || *c == '-')
    {
        return Some(Err(word.iter().collect()));
    }
    None
}

/// `^ {0,3}:{3,}[ \t]*(?:\{(.*)\}|([A-Za-z][A-Za-z0-9_-]*))[ \t]*$`.
fn match_div_open(line: &[char]) -> Option<Result<String, String>> {
    div_open_from(line, indent_end(line)?)
}

/// `^ {0,3}:{3,}[ \t]*$`.
fn match_div_close(line: &[char]) -> bool {
    let Some(mut i) = indent_end(line) else {
        return false;
    };
    let at = i;
    while i < line.len() && line[i] == ':' {
        i += 1;
    }
    if i - at < 3 {
        return false;
    }
    line[i..].iter().all(|c| *c == ' ' || *c == '\t')
}

/// `^ {0,3}(`{3,}|~{3,})(.*)$`: the fence run and the rest of the line.
fn match_code_fence_open(line: &[char]) -> Option<(String, Vec<char>)> {
    let at = indent_end(line)?;
    let c = *line.get(at)?;
    if c != '`' && c != '~' {
        return None;
    }
    let mut i = at;
    while i < line.len() && line[i] == c {
        i += 1;
    }
    if i - at < 3 {
        return None;
    }
    let rest = &line[i..];
    if rest.iter().any(|c| is_line_terminator(*c)) {
        return None;
    }
    Some((line[at..i].iter().collect(), rest.to_vec()))
}

/// `^ {0,3}>`.
fn match_quote_line(line: &[char]) -> bool {
    indent_end(line).is_some_and(|i| line.get(i) == Some(&'>'))
}

/// `^ {0,3}> ?(?:⬆|\*\*❓|⚖)`.
fn match_annotation_start(line: &[char]) -> bool {
    let Some(mut i) = indent_end(line) else {
        return false;
    };
    if line.get(i) != Some(&'>') {
        return false;
    }
    i += 1;
    if line.get(i) == Some(&' ') {
        i += 1;
    }
    match line.get(i) {
        Some('\u{2B06}') | Some('\u{2696}') => true,
        Some('*') => starts_with_at(line, i, "**\u{2753}"),
        _ => false,
    }
}

/// `^ {0,3}>[ \t]?( {0,3}:{3,}[ \t]*(?:\{.*\}|[A-Za-z][A-Za-z0-9_-]*)[ \t]*)$`.
fn match_quoted_div_open(line: &[char]) -> bool {
    let Some(mut i) = indent_end(line) else {
        return false;
    };
    if line.get(i) != Some(&'>') {
        return false;
    }
    i += 1;
    if matches!(line.get(i), Some(' ') | Some('\t')) {
        i += 1;
    }
    let rest = &line[i..];
    match indent_end(rest) {
        Some(j) => div_open_from(rest, j).is_some(),
        None => false,
    }
}

// --- Attributes ---------------------------------------------------------------

struct Attributes {
    classes: Vec<String>,
    id: Option<String>,
    pairs: Vec<(String, String)>,
}

/// `[^\s.#}="']+` from `at`: the index after the run (`at` when empty).
fn attribute_word_end(s: &[char], at: usize) -> usize {
    let mut i = at;
    while i < s.len() {
        let c = s[i];
        if is_js_ws(c) || matches!(c, '.' | '#' | '}' | '=' | '"' | '\'') {
            break;
        }
        i += 1;
    }
    i
}

/// `([A-Za-z_][A-Za-z0-9_:.-]*)=("[^"]*"|'[^']*'|[^\s}]+)` at `at`: the key,
/// the raw value and the index after the match.
fn attribute_pair_at(s: &[char], at: usize) -> Option<(String, String, usize)> {
    let c = *s.get(at)?;
    if !(c.is_ascii_alphabetic() || c == '_') {
        return None;
    }
    let mut i = at + 1;
    while i < s.len() && (s[i].is_ascii_alphanumeric() || matches!(s[i], '_' | ':' | '.' | '-')) {
        i += 1;
    }
    if s.get(i) != Some(&'=') {
        return None;
    }
    let key: String = s[at..i].iter().collect();
    let v = i + 1;
    if let Some(q @ ('"' | '\'')) = s.get(v).copied() {
        if let Some(close) = (v + 1..s.len()).find(|&k| s[k] == q) {
            return Some((key, s[v..=close].iter().collect(), close + 1));
        }
    }
    let mut j = v;
    while j < s.len() && !is_js_ws(s[j]) && s[j] != '}' {
        j += 1;
    }
    if j == v {
        return None;
    }
    Some((key, s[v..j].iter().collect(), j))
}

fn parse_attributes(inner: &[char]) -> Attributes {
    let mut classes = Vec::new();
    let mut id: Option<String> = None;
    let mut pairs: Vec<(String, String)> = Vec::new();
    let mut i = 0;
    while i < inner.len() {
        let c = inner[i];
        if c == '.' || c == '#' {
            let end = attribute_word_end(inner, i + 1);
            if end > i + 1 {
                let word: String = inner[i + 1..end].iter().collect();
                if c == '.' {
                    classes.push(word);
                } else if id.is_none() {
                    id = Some(word);
                }
                i = end;
                continue;
            }
        }
        if let Some((key, raw, end)) = attribute_pair_at(inner, i) {
            let n = raw.chars().count();
            let value = if n >= 2
                && ((raw.starts_with('"') && raw.ends_with('"'))
                    || (raw.starts_with('\'') && raw.ends_with('\'')))
            {
                raw.chars().skip(1).take(n - 2).collect()
            } else {
                raw
            };
            match pairs.iter_mut().find(|(k, _)| *k == key) {
                Some(slot) => slot.1 = value,
                None => pairs.push((key, value)),
            }
            i = end;
            continue;
        }
        i += 1;
    }
    Attributes { classes, id, pairs }
}

// --- The scanner --------------------------------------------------------------

struct OpenDiv {
    start: usize,
    content_start: usize,
    line: usize,
    attributes: Attributes,
}

/// An element found, with the code-point offset of its start (the kind
/// findings stand there).
struct Found {
    element: NotationElement,
    cp_start: usize,
}

/// Works on code-point offsets; every offset it reports is converted to UTF-16
/// code units (`u16`).
struct Scanner {
    text: Vec<char>,
    tom_specs: bool,
    line_starts: Vec<usize>,
    lines: Vec<(usize, usize)>,
    elements: Vec<Found>,
    findings: Vec<NotationFinding>,
    /// The UTF-16 offset of every code-point offset 0 … len(text).
    u16: Vec<usize>,
}

const TYPE_ORDER: [&str; 3] = ["div", "span", "citation"];

fn type_index(t: &str) -> usize {
    TYPE_ORDER.iter().position(|x| *x == t).unwrap_or(0)
}

impl Scanner {
    fn new(text: &str, tom_specs: bool) -> Scanner {
        let chars: Vec<char> = text.chars().collect();
        let mut u16 = Vec::with_capacity(chars.len() + 1);
        let mut unit = 0;
        for c in &chars {
            u16.push(unit);
            unit += c.len_utf16();
        }
        u16.push(unit);
        let mut line_starts = Vec::new();
        let mut lines = Vec::new();
        let mut start = 0;
        for (i, c) in chars.iter().enumerate() {
            if *c == '\n' {
                line_starts.push(start);
                lines.push((start, i));
                start = i + 1;
            }
        }
        line_starts.push(start);
        lines.push((start, chars.len()));
        Scanner {
            text: chars,
            tom_specs,
            line_starts,
            lines,
            elements: Vec::new(),
            findings: Vec::new(),
            u16,
        }
    }

    fn line_of(&self, offset: usize) -> usize {
        let mut lo = 0;
        let mut hi = self.line_starts.len() - 1;
        while lo < hi {
            let mid = (lo + hi + 1) >> 1;
            if self.line_starts[mid] <= offset {
                lo = mid;
            } else {
                hi = mid - 1;
            }
        }
        lo + 1
    }

    fn find(&mut self, code: NotationFindingCode, offset: usize, message: String) {
        let line = self.line_of(offset);
        self.findings.push(NotationFinding {
            code,
            offset: self.u16[offset],
            line,
            message,
        });
    }

    #[allow(clippy::too_many_arguments)]
    fn push_element(
        &mut self,
        type_: &'static str,
        attributes: Attributes,
        shape: Option<&'static str>,
        start: usize,
        end: usize,
        content_start: usize,
        content_end: usize,
        line: usize,
        end_line: usize,
        closed: bool,
    ) {
        let element = NotationElement {
            type_,
            kind: attributes.classes.first().cloned(),
            classes: attributes.classes,
            id: attributes.id,
            attributes: attributes.pairs,
            shape,
            start: self.u16[start],
            end: self.u16[end],
            content_start: self.u16[content_start],
            content_end: self.u16[content_end],
            line,
            end_line,
            closed,
            children: Vec::new(),
        };
        self.elements.push(Found {
            element,
            cp_start: start,
        });
    }

    fn scan(mut self) -> NotationScan {
        self.blocks();
        self.kind_findings();
        let mut ordered: Vec<NotationElement> =
            self.elements.drain(..).map(|f| f.element).collect();
        ordered.sort_by(|a, b| {
            a.start
                .cmp(&b.start)
                .then(b.end.cmp(&a.end))
                .then(type_index(a.type_).cmp(&type_index(b.type_)))
        });
        // Nest by containment: a stack of open ancestors, folded into their
        // parents as they close.
        let mut roots: Vec<NotationElement> = Vec::new();
        let mut stack: Vec<NotationElement> = Vec::new();
        fn pop_into(stack: &mut Vec<NotationElement>, roots: &mut Vec<NotationElement>) {
            let done = stack.pop().expect("non-empty stack");
            match stack.last_mut() {
                Some(parent) => parent.children.push(done),
                None => roots.push(done),
            }
        }
        for e in ordered {
            while let Some(top) = stack.last() {
                if e.start >= top.start && e.end <= top.end {
                    break;
                }
                pop_into(&mut stack, &mut roots);
            }
            stack.push(e);
        }
        while !stack.is_empty() {
            pop_into(&mut stack, &mut roots);
        }
        let mut findings = std::mem::take(&mut self.findings);
        findings.sort_by(|a, b| {
            a.offset
                .cmp(&b.offset)
                .then(a.code.index().cmp(&b.code.index()))
        });
        NotationScan {
            text: self.text.iter().collect(),
            elements: roots,
            findings,
        }
    }

    // --- Blocks ---------------------------------------------------------------

    fn blocks(&mut self) {
        let total = self.text.len();
        let mut open_divs: Vec<OpenDiv> = Vec::new();
        let mut code_fence: Option<Vec<char>> = None;
        let mut in_annotation = false;
        let mut region_start: Option<usize> = None;
        let mut region_end = 0;

        for i in 0..self.lines.len() {
            let (start, line_end) = self.lines[i];
            let line: Vec<char> = self.text[start..line_end].to_vec();
            let next = if i + 1 < self.lines.len() {
                self.line_starts[i + 1]
            } else {
                total
            };

            if let Some(fence) = &code_fence {
                let t = js_trim_left(&line);
                if line.len() - t.len() <= 3 && t.starts_with(fence) {
                    let rest: Vec<char> = t[fence.len()..]
                        .iter()
                        .copied()
                        .filter(|c| *c != fence[0])
                        .collect();
                    if js_trim(&rest).is_empty() {
                        code_fence = None;
                    }
                }
                continue;
            }

            if match_annotation_start(&line) {
                if !in_annotation && !open_divs.is_empty() {
                    self.find(
                        NotationFindingCode::AnnotationInsideDiv,
                        start,
                        "a comment or question block stands inside a div".to_string(),
                    );
                }
                in_annotation = true;
            } else if !match_quote_line(&line) {
                in_annotation = false;
            }
            if in_annotation {
                if match_quoted_div_open(&line) {
                    self.find(
                        NotationFindingCode::DivInsideAnnotation,
                        start,
                        "a div stands inside a comment or question block".to_string(),
                    );
                }
                if region_start.is_none() {
                    region_start = Some(start);
                }
                region_end = line_end;
                continue;
            }

            if let Some((run, rest)) = match_code_fence_open(&line) {
                if !(run.starts_with('`') && rest.contains(&'`')) {
                    if let Some(rs) = region_start.take() {
                        self.inline(rs, region_end);
                    }
                    code_fence = Some(run.chars().collect());
                    continue;
                }
            }

            if let Some(open) = match_div_open(&line) {
                if let Some(rs) = region_start.take() {
                    self.inline(rs, region_end);
                }
                let attributes = match open {
                    Ok(inner) => parse_attributes(&inner.chars().collect::<Vec<char>>()),
                    Err(word) => Attributes {
                        classes: vec![word],
                        id: None,
                        pairs: Vec::new(),
                    },
                };
                open_divs.push(OpenDiv {
                    start,
                    content_start: next,
                    line: i + 1,
                    attributes,
                });
                continue;
            }

            if match_div_close(&line) {
                if let Some(rs) = region_start.take() {
                    self.inline(rs, region_end);
                }
                match open_divs.pop() {
                    None => self.find(
                        NotationFindingCode::StrayClosingFence,
                        start,
                        "a closing fence has no open div".to_string(),
                    ),
                    Some(d) => self.add_div(d, line_end, start, true),
                }
                continue;
            }

            if js_trim(&line).is_empty() {
                if let Some(rs) = region_start.take() {
                    self.inline(rs, region_end);
                }
                continue;
            }
            if region_start.is_none() {
                region_start = Some(start);
            }
            region_end = line_end;
        }
        if let Some(rs) = region_start.take() {
            self.inline(rs, region_end);
        }
        while let Some(d) = open_divs.pop() {
            self.find(
                NotationFindingCode::UnclosedDiv,
                d.start,
                "an opening fence has no closing fence".to_string(),
            );
            self.add_div(d, total, total, false);
        }
    }

    fn add_div(&mut self, d: OpenDiv, end: usize, content_end: usize, closed: bool) {
        let content_start = if d.content_start > content_end {
            content_end
        } else {
            d.content_start
        };
        let end_line = self.line_of(if end > d.start { end - 1 } else { d.start });
        self.push_element(
            "div",
            d.attributes,
            None,
            d.start,
            end,
            content_start,
            content_end,
            d.line,
            end_line,
            closed,
        );
    }

    // --- Inline ---------------------------------------------------------------

    fn inline(&mut self, start: usize, end: usize) {
        let mut literal: HashMap<usize, usize> = HashMap::new();
        let mut escaped: HashSet<usize> = HashSet::new();
        let mut i = start;
        while i < end {
            let c = self.text[i];
            if c == '\\' && i + 1 < end && ASCII_PUNCTUATION.contains(self.text[i + 1]) {
                escaped.insert(i + 1);
                i += 2;
                continue;
            }
            if c == '`' {
                let mut n = 0;
                while i + n < end && self.text[i + n] == '`' {
                    n += 1;
                }
                match self.closing_backticks(i + n, end, n) {
                    Some(close) => {
                        literal.insert(i, close + n);
                        i = close + n;
                    }
                    None => i += n,
                }
                continue;
            }
            i += 1;
        }

        // (start, end, type) of every span and citation, in code points.
        let mut spans: Vec<(usize, usize, &'static str)> = Vec::new();
        let mut marks: Vec<(usize, usize)> = Vec::new();
        let mut brackets: Vec<usize> = Vec::new();
        let mut i = start;
        while i < end {
            if let Some(&skip) = literal.get(&i) {
                i = skip;
                continue;
            }
            let c = self.text[i];
            if escaped.contains(&i) || (c == '\\' && escaped.contains(&(i + 1))) {
                i += 1;
                continue;
            }
            if c == '{' {
                if let Some(opener) = MARK_OPENERS
                    .iter()
                    .find(|o| starts_with_at(&self.text, i, o))
                {
                    let closer = mark_closer(opener);
                    if let Some(close) = find_from(&self.text, i + 3, closer) {
                        if close + closer.len() <= end {
                            marks.push((i, close + closer.len()));
                        }
                    }
                    i += 3;
                    continue;
                }
            }
            if c == '[' {
                brackets.push(i);
            } else if c == ']' && !brackets.is_empty() {
                let open_at = brackets.pop().expect("non-empty");
                if i + 1 < end
                    && self.text[i + 1] == '{'
                    && !escaped.contains(&(i + 1))
                    && !MARK_OPENERS
                        .iter()
                        .any(|o| starts_with_at(&self.text, i + 1, o))
                {
                    match self.closing_brace(i + 2, end) {
                        None => self.find(
                            NotationFindingCode::UnclosedSpan,
                            i + 1,
                            "a span's attribute braces do not close on the paragraph".to_string(),
                        ),
                        Some(close) => {
                            let attributes = parse_attributes(&self.text[i + 2..close]);
                            let line = self.line_of(open_at);
                            let end_line = self.line_of(close);
                            self.push_element(
                                "span",
                                attributes,
                                None,
                                open_at,
                                close + 1,
                                open_at + 1,
                                i,
                                line,
                                end_line,
                                true,
                            );
                            spans.push((open_at, close + 1, "span"));
                            i = close + 1;
                            continue;
                        }
                    }
                }
            } else if c == '(' && i + 3 < end && self.text[i + 3] == ' ' {
                if let Some((arrow, kind)) = citation_kind(&self.text[i + 1..i + 3]) {
                    if let Some(close) = self.closing_parenthesis(i + 4, end, &literal) {
                        if close > i + 4 && !js_trim(&self.text[i + 4..close]).is_empty() {
                            let line = self.line_of(i);
                            let end_line = self.line_of(close);
                            self.push_element(
                                "citation",
                                Attributes {
                                    classes: vec![kind.to_string()],
                                    id: None,
                                    pairs: Vec::new(),
                                },
                                Some(arrow),
                                i,
                                close + 1,
                                i + 4,
                                close,
                                line,
                                end_line,
                                true,
                            );
                            spans.push((i, close + 1, "citation"));
                            i += 4;
                            continue;
                        }
                    }
                }
            }
            i += 1;
        }

        for (ms, me) in marks {
            let crossed = spans.iter().find(|(es, ee, _)| {
                (ms < *es && *es < me && me < *ee) || (*es < ms && ms < *ee && *ee < me)
            });
            if let Some((_, _, etype)) = crossed {
                self.find(
                    NotationFindingCode::MarkAcrossNotation,
                    ms,
                    format!("an inline review mark crosses the boundary of a {}", etype),
                );
            }
        }
    }

    fn closing_backticks(&self, from: usize, end: usize, n: usize) -> Option<usize> {
        let mut i = from;
        while i < end {
            if self.text[i] == '`' {
                let mut m = 0;
                while i + m < end && self.text[i + m] == '`' {
                    m += 1;
                }
                if m == n {
                    return Some(i);
                }
                i += m;
            } else {
                i += 1;
            }
        }
        None
    }

    fn closing_brace(&self, from: usize, end: usize) -> Option<usize> {
        let mut quote: Option<char> = None;
        for i in from..end {
            let c = self.text[i];
            if let Some(q) = quote {
                if c == q {
                    quote = None;
                }
            } else if c == '"' || c == '\'' {
                quote = Some(c);
            } else if c == '}' {
                return Some(i);
            } else if c == '{' {
                return None;
            }
        }
        None
    }

    fn closing_parenthesis(
        &self,
        from: usize,
        end: usize,
        literal: &HashMap<usize, usize>,
    ) -> Option<usize> {
        let mut depth = 0usize;
        let mut i = from;
        while i < end {
            if let Some(&skip) = literal.get(&i) {
                i = skip;
                continue;
            }
            match self.text[i] {
                '(' => depth += 1,
                ')' => {
                    if depth == 0 {
                        return Some(i);
                    }
                    depth -= 1;
                }
                _ => {}
            }
            i += 1;
        }
        None
    }

    // --- Kinds ----------------------------------------------------------------

    fn kind_findings(&mut self) {
        let mut found: Vec<(NotationFindingCode, usize, String)> = Vec::new();
        for f in &self.elements {
            let e = &f.element;
            if e.type_ == "citation" {
                continue;
            }
            if e.type_ == "div" && e.kind.as_deref() == Some("rejected") {
                found.push((
                    NotationFindingCode::RejectedBlock,
                    f.cp_start,
                    "a rejected block waits for its resolution".to_string(),
                ));
            }
            if !self.tom_specs {
                continue;
            }
            match &e.kind {
                None => {
                    if e.type_ == "div" {
                        found.push((
                            NotationFindingCode::DivWithoutKind,
                            f.cp_start,
                            "a div's attributes hold no class".to_string(),
                        ));
                    }
                }
                Some(kind) if !e.is_registered() => found.push((
                    NotationFindingCode::UnknownKind,
                    f.cp_start,
                    format!("the kind \"{}\" is not registered", kind),
                )),
                Some(_) => {}
            }
        }
        for (code, offset, message) in found {
            self.find(code, offset, message);
        }
    }
}
