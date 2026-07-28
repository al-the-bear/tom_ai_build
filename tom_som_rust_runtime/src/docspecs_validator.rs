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
    md_heading_line, MarkdownFenceTracker, SpecDocumentMarkdown, SpecMarkdownResult,
};
use crate::spec_model::SpecModel;
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

/// A schema-free structural parse of a DocSpecs markdown document.
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
            if let Some((level, rest)) = md_heading_line(line) {
                let section = match dv_headline_comment(rest) {
                    Some((id, after)) => {
                        let mut title = after.trim().to_string();
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
#[derive(Debug, Clone, Default)]
pub struct DocSpecsDocumentSection {
    pub section_type: String,
    pub optional: bool,
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
                "document" => schema.load_document(v),
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

    fn load_document(&mut self, node: &YamlValue) {
        let m = match node.as_map() {
            Some(m) => m,
            None => return,
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
                    if let Some(s_raw) = s_v.as_map() {
                        if s_raw.has("section-type") {
                            section_type = dv_str(s_raw.get("section-type"));
                        }
                        optional = dv_is_true(s_raw.get("optional"));
                    }
                    self.document_sections.push((
                        s_key.clone(),
                        DocSpecsDocumentSection {
                            section_type,
                            optional,
                        },
                    ));
                }
            } else if k != "name" && k != "description" {
                self.warnings
                    .push(format!("unsupported document key \"{}\" ignored", k));
            }
        }
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
pub struct DocSpecsValidator {
    pub schema: DocSpecsSchema,
}

impl DocSpecsValidator {
    /// Binds a schema to the validator.
    pub fn new(schema: DocSpecsSchema) -> DocSpecsValidator {
        DocSpecsValidator { schema }
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
        self.validate_document_sections(root, &mut v);
        v
    }

    fn resolve_child<'s>(
        &'s self,
        section: &DocSpecsSection,
        v: &mut Vec<DocSpecsViolation>,
    ) -> Option<&'s DocSpecsSectionType> {
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

    fn validate_document_sections(&self, root: &DocSpecsSection, v: &mut Vec<DocSpecsViolation>) {
        // Occurrences per section-type name.
        let mut counts: HashMap<&str, i64> = HashMap::new();
        let slot_types: HashSet<&str> = self
            .schema
            .document_sections
            .iter()
            .map(|(_, slot)| slot.section_type.as_str())
            .collect();
        for child in &root.children {
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

    fn validate_section(
        &self,
        section: &DocSpecsSection,
        t: &DocSpecsSectionType,
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
        self.validate_text(section, t, v);
        self.validate_format(section, t, v);
        // Occurrences per subsection type name.
        let mut counts: HashMap<String, i64> = HashMap::new();
        for child in &section.children {
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
                        section_id: sub_key.clone(),
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
                        section_id: sub_key.clone(),
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
                        section_id: sub_key.clone(),
                        path: String::new(),
                    });
                }
            }
        }
    }

    fn validate_text(
        &self,
        section: &DocSpecsSection,
        t: &DocSpecsSectionType,
        v: &mut Vec<DocSpecsViolation>,
    ) {
        if !t.format.is_empty() && self.schema.form_types.contains_key(&t.format) {
            return; // form sections carry fields, not body text.
        }
        let text = section.text();
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
        section: &DocSpecsSection,
        t: &DocSpecsSectionType,
        v: &mut Vec<DocSpecsViolation>,
    ) {
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
        for raw in &section.body_lines {
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

    fn validate_form(
        &self,
        section: &DocSpecsSection,
        form: &DocSpecsFormType,
        v: &mut Vec<DocSpecsViolation>,
    ) {
        // Lowered name → field.
        let mut by_lower: HashMap<String, &DocSpecsFormField> = HashMap::new();
        for f in &form.fields {
            by_lower.insert(f.name.to_lowercase(), f);
        }
        // Field name → collected value lines.
        let mut values: HashMap<String, Vec<String>> = HashMap::new();
        // Field name → 1-based label line.
        let mut field_lines: HashMap<String, usize> = HashMap::new();
        let mut fence = MarkdownFenceTracker::new();
        let mut current = String::new();
        let mut have_current = false;
        for (i, raw) in section.body_lines.iter().enumerate() {
            if !fence.in_fence() {
                if let Some((label, first)) = dv_field_label(raw) {
                    if let Some(field) = by_lower.get(&label.to_lowercase()) {
                        current = field.name.clone();
                        have_current = true;
                        values.insert(current.clone(), vec![first.to_string()]);
                        field_lines.insert(current.clone(), section.body_start_line() + i);
                        fence.feed(raw);
                        continue;
                    }
                }
            }
            if have_current {
                values.get_mut(&current).unwrap().push(raw.clone());
            }
            fence.feed(raw);
        }
        for field in &form.fields {
            let value = values
                .get(&field.name)
                .map(|collected| collected.join("\n").trim().to_string())
                .unwrap_or_default();
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
                if !value.is_empty() && !pc.matches(&value) {
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
