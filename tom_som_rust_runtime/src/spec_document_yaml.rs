//! `spec_document_yaml` — generic YAML codec for the native `*.docspecs.yaml`
//! document format — **hierarchical format v2** (SOM §12); a faithful port of
//! the Go `spec_document_yaml.go` (itself a port of
//! `tom_som_dart_runtime/lib/src/spec_document_yaml.dart`).
//!
//! One nested YAML tree whose indentation mirrors the document structure: every
//! model node becomes a mapping key (`<section-id> <member-name>`, SOM §12.2),
//! sections nest their children, list items appear under their container keyed
//! by their stored section id (or an anonymous positional `<member>-<n>` key), a
//! node's own body text uses the literal key `content`, a node's own stored
//! headline (YRD3) uses the literal key `headline`, and form fields use their
//! bare field names. A scalar-valued node (content/scalar/enum leaf or scalar
//! list item) that carries a stored headline is emitted as a
//! `{headline: …, content: …}` mapping. The former flat two-level path-map format
//! (`document: {content: {"A/b": …}}`) is **retired**; readers reject
//! `version: 1` files with a clear error (no compatibility path).
//!
//! Text values are written as literal block scalars (`|2-`), with the SOM §12.4
//! escaping rules: the emitter is **self-verifying** (it re-parses each scalar
//! it produces via the hand-rolled [`crate::yaml`] reader — the runtime ships
//! no external YAML library — and falls back to a double-quoted JSON-escaped
//! flow scalar when the parse differs), and **runs of 2+ consecutive empty
//! lines are collapsed to one** before serialization (a deliberate, documented
//! lossy normalization — round-trip guarantees are stated "modulo empty-line
//! dedup"). Non-text values (`int`/`double`/`bool`, enum member names) are
//! plain scalars when they self-verify (SOM §12.5). The JSON quoting is
//! byte-for-byte identical to JavaScript's `JSON.stringify` (see
//! [`js_json_string`]) so output is stable across every language port.
//!
//! Both [`encode_yaml`] and [`decode_yaml`] walk the [`SomMetaTree`] of the
//! document root: the file carries **no paths** — the runtime reconstructs
//! them by matching keys against the metadata tree, and a key that matches
//! nothing at its position is a structured load error
//! ([`SpecYamlFormatException`]; no silent skips). Symmetrically,
//! [`encode_yaml`] errors when the document holds values the tree cannot place
//! (nothing is silently dropped).
//!
//! The optional `review:` pass stays opaque to the runtime ([`decode_yaml`]
//! returns it as a raw mapping for the editor to interpret).
//!
//! Divergences shared with the hand-rolled parser (documented in the JS/TS
//! ports too): a bare `key:` parses as an empty mapping (which counts as an
//! empty scalar at scalar positions), and the parser never yields booleans, so
//! plain-scalar self-verification needs no bool canonicalisation.

use std::collections::{BTreeMap, BTreeSet, HashSet};
use std::fmt;

use crate::spec_document::SpecDocument;
use crate::spec_meta::{
    SomFormMeta, SomMetaNode, SomMetaTree, SOM_META_KIND_COMPLEX, SOM_META_KIND_CONTENT,
    SOM_META_KIND_ENUM_VALUE, SOM_META_KIND_FORM, SOM_META_KIND_LIST, SOM_META_KIND_SCALAR,
    SOM_META_KIND_SECTION,
};
use crate::spec_paths::spec_path_join;
use crate::spec_section_id::SpecSectionIdError;
use crate::yaml::{yaml_parse, YamlMap, YamlValue};

/// The on-disk format version (independent of the model-version stamp).
/// Version 2 is the hierarchical tree format; version-1 flat files are rejected
/// on read.
pub const FORMAT_VERSION: i64 = 2;

/// A structural error in a `*.docspecs.yaml` file: wrong/unsupported format
/// version, a key that does not match the metadata tree at its position, a
/// malformed value shape, or (on encode) document values the tree cannot place.
#[derive(Debug, Clone, PartialEq)]
pub struct SpecYamlFormatException {
    /// Says what went wrong, naming the offending path/key where applicable.
    pub message: String,
}

impl fmt::Display for SpecYamlFormatException {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "SpecYamlFormatException: {}", self.message)
    }
}

impl std::error::Error for SpecYamlFormatException {}

/// The error surface of the YAML codec: a structural format error, or a
/// section-id collision propagated from the document's list-item write path
/// (the Rust analogue of the Go functions returning either error type through
/// the `error` interface).
#[derive(Debug, Clone, PartialEq)]
pub enum SpecYamlError {
    /// A structural `*.docspecs.yaml` error.
    Format(SpecYamlFormatException),
    /// A section-id error raised while materialising a decoded list item.
    SectionId(SpecSectionIdError),
}

impl fmt::Display for SpecYamlError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            SpecYamlError::Format(e) => write!(f, "{}", e),
            SpecYamlError::SectionId(e) => write!(f, "{}", e),
        }
    }
}

impl std::error::Error for SpecYamlError {}

fn yaml_format_err(message: String) -> SpecYamlError {
    SpecYamlError::Format(SpecYamlFormatException { message })
}

/// The decoded passes of a `*.docspecs.yaml` file: the `document:` pass as a
/// populated [`SpecDocument`], the `review:` pass as a raw mapping (the runtime
/// is review-agnostic), and the optional authoring model-version stamp.
#[derive(Debug, Clone, Default)]
pub struct SpecYamlContents {
    /// The `document:` pass, loaded into a live document (its
    /// [`SpecDocument::model_version`] is already set from the file stamp).
    pub document: SpecDocument,
    /// The `review:` pass exactly as parsed (empty when absent). The runtime
    /// does not interpret it; the editor maps it onto its own review entries.
    pub review: YamlMap,
    /// The authoring object-model version (major.minor) this document was last
    /// written against, or `""` for an unstamped/hand-written file. Distinct
    /// from [`FORMAT_VERSION`] (the on-disk format version).
    pub model_version: String,
}

// --- Shared scalar machinery (public for the editor's review writer) ---------

/// Returns the mapping key a metadata node writes (SOM §12.2): its effective
/// section id, one space, then the exact member name (class name on the
/// document root); just the name when the node carries no id.
///
/// A section/complex node's key carries the *full* section id — the field-level
/// `@SectionId` if present, else the target class's own `@SectionId`
/// (`class_section_id`, the SOM §12.2 class fallback) — mirroring the markdown
/// codec's heading rule. Content/scalar/enum/form and list-item keys keep only
/// their field-level id; the path segment is never affected (see
/// [`SomMetaNode::segment`]).
pub fn node_key(node: &SomMetaNode) -> String {
    let name = if node.member_name.is_empty() {
        &node.class_name
    } else {
        &node.member_name
    };
    let id = if node.section_id.is_empty()
        && matches!(node.kind.as_str(), SOM_META_KIND_SECTION | SOM_META_KIND_COMPLEX)
    {
        &node.class_section_id
    } else {
        &node.section_id
    };
    if id.is_empty() {
        return name.clone();
    }
    format!("{} {}", id, name)
}

/// Renders `s` exactly as JavaScript's `JSON.stringify` would: wrapped in
/// double quotes, with the short escapes for `" \ \b \f \n \r \t`, control
/// characters below `0x20` as lowercase `\u00xx`, and every other char
/// (including all non-ASCII and the HTML-sensitive `< > & /`) emitted verbatim.
pub fn js_json_string(s: &str) -> String {
    crate::json::encode_str(s)
}

/// Returns a safely-quoted mapping key. JSON strings are valid YAML flow
/// scalars, so this both quotes and escapes any path/field name unambiguously.
fn yaml_key(key: &str) -> String {
    js_json_string(key)
}

/// Reports whether `key` matches the plain-key pattern
/// `^[A-Za-z0-9_][A-Za-z0-9_. -]*[A-Za-z0-9_.\-]$|^[A-Za-z0-9_]$` (the
/// dependency-free stand-in for the other ports' regex).
fn is_plain_key(key: &str) -> bool {
    let b = key.as_bytes();
    let word = |c: u8| c.is_ascii_alphanumeric() || c == b'_';
    match b.len() {
        0 => false,
        1 => word(b[0]),
        n => {
            let last = b[n - 1];
            word(b[0])
                && (word(last) || last == b'.' || last == b'-')
                && b[1..n - 1]
                    .iter()
                    .all(|&c| word(c) || c == b'.' || c == b' ' || c == b'-')
        }
    }
}

/// Returns `key` as a plain key when it is YAML-safe by construction (section
/// ids, member names, `<id> <name>` pairs), else a JSON-quoted one.
pub fn plain_key(key: &str) -> String {
    if is_plain_key(key) {
        return key.to_string();
    }
    yaml_key(key)
}

/// Collapses runs of two or more consecutive empty lines to a single empty
/// line (SOM §12.4 — the deliberate lossy normalization applied to every text
/// value before serialization).
pub fn dedup_empty_lines(value: &str) -> String {
    let mut out = String::with_capacity(value.len());
    let mut rest = value;
    while let Some(pos) = rest.find('\n') {
        out.push_str(&rest[..pos]);
        let after = &rest[pos..];
        let run = after.bytes().take_while(|&b| b == b'\n').count();
        if run >= 3 {
            out.push_str("\n\n");
        } else {
            out.push_str(&after[..run]);
        }
        rest = &after[run..];
    }
    out.push_str(rest);
    out
}

/// The Dart-toString-compatible string of a parsed YAML scalar (the
/// hand-rolled parser yields string or int only, so no bool canonicalisation
/// is needed).
fn parsed_scalar_str(v: &YamlValue) -> String {
    match v {
        YamlValue::Str(s) => s.clone(),
        YamlValue::Int(n) => n.to_string(),
        _ => String::new(),
    }
}

fn trailing_newlines(value: &str) -> usize {
    value.bytes().rev().take_while(|&b| b == b'\n').count()
}

/// Builds a literal block scalar (`|2<chomp>`) with body at relative indent 2,
/// or `None` when chomping can't reproduce the value's trailing newlines (two
/// or more) — those fall back to JSON quoting.
fn literal_block(value: &str) -> Option<String> {
    let trailing = trailing_newlines(value);
    let (chomp, core): (&str, &str) = match trailing {
        0 => ("-", value),
        1 => ("", &value[..value.len() - 1]),
        _ => return None,
    };
    let mut parts = String::new();
    parts.push_str("|2");
    parts.push_str(chomp);
    for line in core.split('\n') {
        parts.push('\n');
        if !line.is_empty() {
            parts.push_str("  ");
            parts.push_str(line);
        }
    }
    Some(parts)
}

/// Reports whether re-parsing `_v: <block>` yields exactly `value` (the
/// emitter's correctness guard).
fn round_trips(block: &str, value: &str) -> bool {
    let parsed = yaml_parse(&format!("_v: {}\n", block));
    matches!(parsed.get("_v"), Some(YamlValue::Str(s)) if s == value)
}

/// Returns the scalar representation of `value`: a literal block at relative
/// indent 2 when that round-trips, else a JSON-quoted scalar.
fn scalar_repr(value: &str) -> String {
    if let Some(block) = literal_block(value) {
        if round_trips(&block, value) {
            return block;
        }
    }
    js_json_string(value)
}

/// Reports whether `value` is a YAML 1.1 boolean word that YAML 1.2 treats as
/// a plain string (`^(y|Y|yes|Yes|YES|n|N|no|No|NO|on|On|ON|off|Off|OFF)$`).
fn is_yaml11_bool(value: &str) -> bool {
    matches!(
        value,
        "y" | "Y"
            | "yes"
            | "Yes"
            | "YES"
            | "n"
            | "N"
            | "no"
            | "No"
            | "NO"
            | "on"
            | "On"
            | "ON"
            | "off"
            | "Off"
            | "OFF"
    )
}

/// Reports whether `value` is a YAML 1.1 sexagesimal literal — an int
/// (`^[-+]?[1-9][0-9_]*(:[0-5]?[0-9])+$`) when `float` is false, or a float
/// (`^[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+\.[0-9_]*$`) when true. A dependency-free
/// stand-in for the other ports' regexes (Rust runtime has no `regex` crate).
fn is_yaml11_sexagesimal(value: &str, float: bool) -> bool {
    let b = value.as_bytes();
    let n = b.len();
    let mut i = 0usize;
    if n == 0 {
        return false;
    }
    if b[i] == b'+' || b[i] == b'-' {
        i += 1;
    }
    if i >= n {
        return false;
    }
    // First digit: [1-9] for int, [0-9] for float.
    if float {
        if !b[i].is_ascii_digit() {
            return false;
        }
    } else if !(b[i] >= b'1' && b[i] <= b'9') {
        return false;
    }
    i += 1;
    // [0-9_]*
    while i < n && (b[i].is_ascii_digit() || b[i] == b'_') {
        i += 1;
    }
    // (:[0-5]?[0-9])+  — greedy two-digit consumption is equivalent to the
    // regex here (any trailing digit that is not `:`/end/`.` fails either way).
    let mut groups = 0usize;
    while i < n && b[i] == b':' {
        i += 1;
        if i >= n || !b[i].is_ascii_digit() {
            return false;
        }
        if b[i] >= b'0' && b[i] <= b'5' && i + 1 < n && b[i + 1].is_ascii_digit() {
            i += 2;
        } else {
            i += 1;
        }
        groups += 1;
    }
    if groups == 0 {
        return false;
    }
    if float {
        if i >= n || b[i] != b'.' {
            return false;
        }
        i += 1;
        while i < n && (b[i].is_ascii_digit() || b[i] == b'_') {
            i += 1;
        }
    }
    i == n
}

/// Reports whether `value`'s text is a YAML 1.1 special that a 1.1 parser would
/// resolve to a non-string, so it must never be emitted as a plain scalar
/// (SOM §12.5). Covers the 1.1-only boolean words and sexagesimal int/float
/// literals. Mirrors the Dart reference rule so every emitter's plain-scalar
/// decision is identical regardless of the local YAML parser's schema.
fn is_yaml11_special(value: &str) -> bool {
    is_yaml11_bool(value)
        || is_yaml11_sexagesimal(value, false)
        || is_yaml11_sexagesimal(value, true)
}

/// Returns a plain one-line scalar for a non-text value (int/double/bool/enum
/// member name, SOM §12.5) when writing it plainly re-parses to exactly `value`
/// (string compare, matching the document's string-typed stores); `None`
/// otherwise. Values whose text is a YAML 1.1 special are forced to the
/// quoted/block path so cross-language round-trips stay identical.
fn plain_scalar(value: &str) -> Option<String> {
    if value.is_empty() || value.contains('\n') {
        return None;
    }
    if is_yaml11_special(value) {
        return None;
    }
    let parsed = yaml_parse(&format!("_v: {}\n", value));
    let v = parsed.get("_v")?;
    match v {
        YamlValue::Map(_) | YamlValue::Seq(_) => return None,
        _ => {}
    }
    if parsed_scalar_str(v) != value {
        return None;
    }
    Some(value.to_string())
}

struct YamlBuffer {
    out: String,
}

impl YamlBuffer {
    fn new() -> YamlBuffer {
        YamlBuffer { out: String::new() }
    }

    fn writeln(&mut self, text: &str) {
        self.out.push_str(text);
        self.out.push('\n');
    }

    fn write(&mut self, text: &str) {
        self.out.push_str(text);
    }
}

/// Writes `<indent><renderedKey>: <repr>` where block body lines, emitted by
/// the builder at a relative indent of 2, are re-indented past `key_indent`.
fn write_rendered(b: &mut YamlBuffer, key_indent: usize, rendered_key: &str, repr: &str) {
    let pad = " ".repeat(key_indent);
    let lines: Vec<&str> = repr.split('\n').collect();
    b.writeln(&format!("{}{}: {}", pad, rendered_key, lines[0]));
    for line in &lines[1..] {
        if line.is_empty() {
            b.writeln("");
        } else {
            b.writeln(&format!("{}{}", pad, line));
        }
    }
}

/// Writes the file header comment + `version:` line, and the optional
/// `modelVersion:` stamp when `model_version` is non-empty.
fn write_header(b: &mut YamlBuffer, model_version: &str) {
    b.writeln("# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.");
    b.writeln(&format!("version: {}", FORMAT_VERSION));
    if !model_version.is_empty() {
        b.writeln(&format!("modelVersion: {}", js_json_string(model_version)));
    }
}

// --- Encode -------------------------------------------------------------------

fn is_numeric_or_bool(type_name: &str) -> bool {
    type_name == "int" || type_name == "double" || type_name == "num" || type_name == "bool"
}

/// Serializes `document` to a header + `version:` (+ `modelVersion:`) +
/// hierarchical `document:` pass, walking `tree` (the metadata tree of the
/// document's root).
///
/// Sibling order is the tree's child order (`@SerializationOrder`), list items
/// follow their stored sequence; emission is sparse (only populated subtrees
/// appear). Returns a [`SpecYamlError::Format`] when the document holds values
/// `tree` cannot place — nothing is silently dropped.
pub fn encode_yaml(
    document: &SpecDocument,
    tree: &SomMetaTree,
    model_version: &str,
) -> Result<String, SpecYamlError> {
    let mut b = YamlBuffer::new();
    write_header(&mut b, model_version);
    YamlEncoder::new(document).write_document_pass(&mut b, tree)?;
    Ok(b.out)
}

/// One encode run: it walks the metadata tree, consuming values from snapshots
/// of the document's stores so anything left unconsumed at the end is a
/// structured error (nothing is silently dropped).
struct YamlEncoder<'a> {
    doc: &'a SpecDocument,
    content: BTreeMap<String, String>,
    forms: BTreeMap<String, BTreeMap<String, String>>,
    lists: BTreeSet<String>,
    headlines: BTreeMap<String, String>,
    code_specs: BTreeMap<String, String>,
}

impl<'a> YamlEncoder<'a> {
    fn new(doc: &'a SpecDocument) -> YamlEncoder<'a> {
        let mut e = YamlEncoder {
            doc,
            content: BTreeMap::new(),
            forms: BTreeMap::new(),
            lists: BTreeSet::new(),
            headlines: BTreeMap::new(),
            code_specs: BTreeMap::new(),
        };
        for p in doc.content_paths() {
            let v = doc.content_or(&p);
            e.content.insert(p, v);
        }
        for p in doc.form_paths() {
            let mut fields = BTreeMap::new();
            for f in doc.form_field_names(&p) {
                let v = doc.form_field_or(&p, &f);
                fields.insert(f, v);
            }
            e.forms.insert(p, fields);
        }
        for p in doc.list_paths() {
            e.lists.insert(p);
        }
        for p in doc.headline_paths() {
            let v = doc.headline_or(&p);
            e.headlines.insert(p, v);
        }
        for p in doc.code_spec_paths() {
            let v = doc.code_spec_or(&p);
            e.code_specs.insert(p, v);
        }
        e
    }

    fn write_document_pass(
        &mut self,
        b: &mut YamlBuffer,
        tree: &SomMetaTree,
    ) -> Result<(), SpecYamlError> {
        let root = &tree.root;
        let body = self.mapping_body(root, root.segment(), 4)?;
        self.assert_nothing_left()?;
        if body.is_empty() {
            b.writeln("document: {}");
            return Ok(());
        }
        b.writeln("document:");
        b.writeln(&format!("  {}:", plain_key(&node_key(root))));
        b.write(&body);
        Ok(())
    }

    /// Renders the mapping body of `node` at `path` (root, a collapsed
    /// section/complex field, or a list item's element), one line per
    /// populated entry at `indent`. Empty when nothing under the node is
    /// populated.
    fn mapping_body(
        &mut self,
        node: &SomMetaNode,
        path: &str,
        indent: usize,
    ) -> Result<String, SpecYamlError> {
        let mut b = YamlBuffer::new();

        // The node's own stored headline — the literal `headline` key (YRD3).
        if let Some(own_headline) = self.headlines.remove(path) {
            for c in &node.children {
                if node_key(c) == "headline" {
                    return Err(yaml_format_err(format!(
                        "cannot emit the stored headline at `{}`: a child of {} also serializes as key `headline`",
                        path,
                        node.debug_name()
                    )));
                }
            }
            self.write_text(&mut b, indent, "headline", &own_headline);
        }

        // The node's own codeSpec mapping — the literal `codeSpec` key (§9.2).
        if let Some(own_code_spec) = self.code_specs.remove(path) {
            for c in &node.children {
                if node_key(c) == "codeSpec" {
                    return Err(yaml_format_err(format!(
                        "cannot emit the stored codeSpec at `{}`: a child of {} also serializes as key `codeSpec`",
                        path,
                        node.debug_name()
                    )));
                }
            }
            self.write_text(&mut b, indent, "codeSpec", &own_code_spec);
        }

        // The node's own body text — the literal `content` key (SOM §12.2).
        if let Some(own) = self.content.remove(path) {
            for c in &node.children {
                if node_key(c) == "content" {
                    return Err(yaml_format_err(format!(
                        "cannot emit body text at `{}`: a child of {} also serializes as key `content`",
                        path,
                        node.debug_name()
                    )));
                }
            }
            self.write_text(&mut b, indent, "content", &own);
        }

        for child in &node.children {
            let child_path = spec_path_join(path, child.segment());
            let key = node_key(child);
            match child.kind.as_str() {
                SOM_META_KIND_CONTENT => {
                    let v = self.content.remove(&child_path);
                    let h = self.headlines.remove(&child_path);
                    let cs = self.code_specs.remove(&child_path);
                    if h.is_some() || cs.is_some() {
                        self.write_scalar_with_meta(&mut b, indent, &key, &h, &cs, &v, true);
                    } else if let Some(v) = v {
                        self.write_text(&mut b, indent, &key, &v);
                    }
                }
                SOM_META_KIND_SCALAR | SOM_META_KIND_ENUM_VALUE => {
                    let v = self.content.remove(&child_path);
                    let h = self.headlines.remove(&child_path);
                    let cs = self.code_specs.remove(&child_path);
                    if h.is_some() || cs.is_some() {
                        self.write_scalar_with_meta(&mut b, indent, &key, &h, &cs, &v, false);
                    } else if let Some(v) = v {
                        self.write_value(&mut b, indent, &key, &v);
                    }
                }
                SOM_META_KIND_FORM => {
                    self.write_form(&mut b, indent, &key, child, &child_path)?;
                }
                SOM_META_KIND_SECTION | SOM_META_KIND_COMPLEX => {
                    let sub = self.mapping_body(child, &child_path, indent + 2)?;
                    if !sub.is_empty() {
                        b.writeln(&format!("{}{}:", " ".repeat(indent), plain_key(&key)));
                        b.write(&sub);
                    }
                }
                SOM_META_KIND_LIST => {
                    self.write_list(&mut b, indent, &key, child, &child_path)?;
                }
                _ => {}
            }
        }
        Ok(b.out)
    }

    /// Emits a scalar-valued node (content/scalar/enum leaf or scalar list
    /// item) that carries a stored headline and/or a codeSpec mapping as a
    /// `{headline?: …, codeSpec?: …, content?: …}` mapping (YRD3 + §9.2). Each
    /// entry is emitted only when its value is `Some`; at least one of
    /// `headline`/`code_spec` is `Some` at every call.
    #[allow(clippy::too_many_arguments)]
    fn write_scalar_with_meta(
        &self,
        b: &mut YamlBuffer,
        indent: usize,
        key: &str,
        headline: &Option<String>,
        code_spec: &Option<String>,
        value: &Option<String>,
        text: bool,
    ) {
        b.writeln(&format!("{}{}:", " ".repeat(indent), plain_key(key)));
        if let Some(h) = headline {
            self.write_text(b, indent + 2, "headline", h);
        }
        if let Some(cs) = code_spec {
            self.write_text(b, indent + 2, "codeSpec", cs);
        }
        if let Some(v) = value {
            if text {
                self.write_text(b, indent + 2, "content", v);
            } else {
                self.write_value(b, indent + 2, "content", v);
            }
        }
    }

    fn write_form(
        &mut self,
        b: &mut YamlBuffer,
        indent: usize,
        key: &str,
        node: &SomMetaNode,
        path: &str,
    ) -> Result<(), SpecYamlError> {
        let fields = self.forms.remove(path).unwrap_or_default();
        let headline = self.headlines.remove(path);
        let code_spec = self.code_specs.remove(path);
        if fields.is_empty() && headline.is_none() && code_spec.is_none() {
            return Ok(());
        }
        let empty_meta = SomFormMeta::default();
        let meta = node.form.as_ref().unwrap_or(&empty_meta);
        for name in fields.keys() {
            if meta.field_named(name).is_none() {
                return Err(yaml_format_err(format!(
                    "form `{}` holds a field `{}` unknown to the model",
                    path, name
                )));
            }
        }
        if headline.is_some() && meta.field_named("headline").is_some() {
            return Err(yaml_format_err(format!(
                "cannot emit the stored headline at `{}`: the form declares a field literally named `headline`",
                path
            )));
        }
        if code_spec.is_some() && meta.field_named("codeSpec").is_some() {
            return Err(yaml_format_err(format!(
                "cannot emit the stored codeSpec at `{}`: the form declares a field literally named `codeSpec`",
                path
            )));
        }
        b.writeln(&format!("{}{}:", " ".repeat(indent), plain_key(key)));
        if let Some(h) = &headline {
            self.write_text(b, indent + 2, "headline", h);
        }
        if let Some(cs) = &code_spec {
            self.write_text(b, indent + 2, "codeSpec", cs);
        }
        for f in &meta.fields {
            let v = match fields.get(&f.name) {
                Some(v) => v,
                None => continue,
            };
            if is_numeric_or_bool(&f.type_name) {
                self.write_value(b, indent + 2, &f.name, v);
            } else {
                self.write_text(b, indent + 2, &f.name, v);
            }
        }
        Ok(())
    }

    fn write_list(
        &mut self,
        b: &mut YamlBuffer,
        indent: usize,
        key: &str,
        node: &SomMetaNode,
        path: &str,
    ) -> Result<(), SpecYamlError> {
        self.lists.remove(path);
        let headline = self.headlines.remove(path);
        let code_spec = self.code_specs.remove(path);
        let items = self.doc.list_items(path);
        if items.is_empty() && headline.is_none() && code_spec.is_none() {
            return Ok(());
        }
        b.writeln(&format!("{}{}:", " ".repeat(indent), plain_key(key)));
        if let Some(h) = &headline {
            self.write_text(b, indent + 2, "headline", h);
        }
        if let Some(cs) = &code_spec {
            self.write_text(b, indent + 2, "codeSpec", cs);
        }
        let mut used: HashSet<String> = HashSet::new();
        used.insert("headline".to_string());
        used.insert("codeSpec".to_string());
        let mut pos = 0usize;
        for item_path in &items {
            pos += 1;
            let stored_id = self.doc.item_section_id(item_path);
            match stored_id {
                Some(id) => {
                    let item_key = id.clone();
                    if used.contains(&item_key) {
                        return Err(yaml_format_err(format!(
                            "duplicate list item key `{}` at `{}`",
                            item_key, path
                        )));
                    }
                    used.insert(item_key.clone());
                    self.write_list_item(b, indent, node, &item_key, item_path)?;
                }
                None => {
                    let mut item_key = format!("{}-{}", node.member_name, pos);
                    let mut bump = pos;
                    while used.contains(&item_key) {
                        bump += 1;
                        item_key = format!("{}-{}", node.member_name, bump);
                    }
                    used.insert(item_key.clone());
                    self.write_list_item(b, indent, node, &item_key, item_path)?;
                }
            }
        }
        Ok(())
    }

    fn write_list_item(
        &mut self,
        b: &mut YamlBuffer,
        indent: usize,
        node: &SomMetaNode,
        item_key: &str,
        item_path: &str,
    ) -> Result<(), SpecYamlError> {
        match &node.element_node {
            None => {
                // Scalar list: the item is a direct value — unless it carries
                // a stored headline, in which case it becomes a
                // `{headline: …, content: …}` mapping (YRD3).
                let v = self.content.remove(item_path);
                let h = self.headlines.remove(item_path);
                let cs = self.code_specs.remove(item_path);
                if h.is_some() || cs.is_some() {
                    self.write_scalar_with_meta(b, indent + 2, item_key, &h, &cs, &v, false);
                } else {
                    self.write_value(b, indent + 2, item_key, &v.unwrap_or_default());
                }
            }
            Some(element) => {
                let sub = self.mapping_body(element, item_path, indent + 4)?;
                if sub.is_empty() {
                    b.writeln(&format!(
                        "{}{}: {{}}",
                        " ".repeat(indent + 2),
                        plain_key(item_key)
                    ));
                } else {
                    b.writeln(&format!("{}{}:", " ".repeat(indent + 2), plain_key(item_key)));
                    b.write(&sub);
                }
            }
        }
        Ok(())
    }

    /// Writes a text value: empty-line dedup, then a self-verified block
    /// scalar (or the JSON-quoted fallback).
    fn write_text(&self, b: &mut YamlBuffer, indent: usize, key: &str, value: &str) {
        write_rendered(b, indent, &plain_key(key), &scalar_repr(&dedup_empty_lines(value)));
    }

    /// Writes a non-text value (SOM §12.5): plain when it self-verifies, else the
    /// text path.
    fn write_value(&self, b: &mut YamlBuffer, indent: usize, key: &str, value: &str) {
        if let Some(plain) = plain_scalar(value) {
            b.writeln(&format!("{}{}: {}", " ".repeat(indent), plain_key(key), plain));
        } else {
            self.write_text(b, indent, key, value);
        }
    }

    fn assert_nothing_left(&self) -> Result<(), SpecYamlError> {
        let mut leftovers: Vec<String> = Vec::new();
        for p in self.content.keys() {
            leftovers.push(format!("content at `{}`", p));
        }
        for p in self.forms.keys() {
            leftovers.push(format!("form values at `{}`", p));
        }
        for p in &self.lists {
            leftovers.push(format!("list items at `{}`", p));
        }
        for p in self.headlines.keys() {
            leftovers.push(format!("headline at `{}`", p));
        }
        for p in self.code_specs.keys() {
            leftovers.push(format!("codeSpec at `{}`", p));
        }
        if leftovers.is_empty() {
            return Ok(());
        }
        leftovers.sort();
        Err(yaml_format_err(format!(
            "document holds values the metadata tree cannot place: {}",
            leftovers.join("; ")
        )))
    }
}

// --- Decode -------------------------------------------------------------------

/// Parses a `*.docspecs.yaml` file into its passes, matching every `document:`
/// key against `tree`.
///
/// Returns a [`SpecYamlError::Format`] for a missing/unsupported `version:`
/// (version 1 is rejected explicitly — the flat format has no compatibility
/// path), for any key the metadata tree cannot place, and for malformed value
/// shapes. A missing/empty `document:` pass decodes as an empty document.
pub fn decode_yaml(yaml_text: &str, tree: &SomMetaTree) -> Result<SpecYamlContents, SpecYamlError> {
    let root = if yaml_text.trim().is_empty() {
        None
    } else {
        Some(yaml_parse(yaml_text))
    };
    let root_map = match root.as_ref().and_then(|r| r.as_map()) {
        Some(m) => m,
        None => {
            return Err(yaml_format_err(
                "not a *.docspecs.yaml mapping (expected version/document keys)".to_string(),
            ))
        }
    };
    match root_map.get("version") {
        None => {
            return Err(yaml_format_err(format!(
                "missing `version:` (expected version: {})",
                FORMAT_VERSION
            )));
        }
        Some(version) => {
            let repr = parsed_scalar_str(version);
            if repr != FORMAT_VERSION.to_string() {
                if repr == "1" {
                    return Err(yaml_format_err(
                        "format version 1 (flat path-map) is no longer supported; \
re-save the document in the hierarchical v2 format"
                            .to_string(),
                    ));
                }
                return Err(yaml_format_err(format!(
                    "unsupported format version `{}` (expected {})",
                    version_repr(version),
                    FORMAT_VERSION
                )));
            }
        }
    }

    let stamp = root_map
        .get("modelVersion")
        .map(parsed_scalar_str)
        .unwrap_or_default();

    let review = match root_map.get("review") {
        Some(YamlValue::Map(m)) => m.clone(),
        _ => YamlMap::new(),
    };

    let mut document = SpecDocument::new();
    document.model_version = stamp.clone();
    if let Some(doc_pass) = root_map.get("document") {
        let doc_map = match doc_pass.as_map() {
            Some(m) => m,
            None => return Err(yaml_format_err("`document:` must be a mapping".to_string())),
        };
        if !doc_map.is_empty() {
            let root_key = node_key(&tree.root);
            let keys = doc_map.keys();
            if keys.len() != 1 || keys[0] != root_key {
                let found: Vec<String> = keys.iter().map(|k| format!("`{}`", k)).collect();
                return Err(yaml_format_err(format!(
                    "expected the single document root key `{}`, found: {}",
                    root_key,
                    found.join(", ")
                )));
            }
            let body = doc_map.get(keys[0]).unwrap();
            let body_map = match body.as_map() {
                Some(m) => m,
                None => {
                    return Err(yaml_format_err(format!(
                        "root `{}` must hold a mapping, not a scalar",
                        root_key
                    )))
                }
            };
            let mut d = YamlDecoder { doc: &mut document };
            d.load_mapping(&tree.root, tree.root.segment(), body_map)?;
        }
    }

    Ok(SpecYamlContents {
        document,
        review,
        model_version: stamp,
    })
}

/// Renders the raw parsed `version:` value for the unsupported-version error
/// message (mirroring JS/TS string interpolation, where a non-scalar mapping
/// renders as `"[object Object]"`).
fn version_repr(v: &YamlValue) -> String {
    match v {
        YamlValue::Map(_) => "[object Object]".to_string(),
        _ => parsed_scalar_str(v),
    }
}

/// One decode run: it walks a parsed YAML mapping alongside the metadata tree
/// and populates `doc`. Any key that matches nothing at its position is an
/// error.
struct YamlDecoder<'a> {
    doc: &'a mut SpecDocument,
}

impl YamlDecoder<'_> {
    fn load_mapping(
        &mut self,
        node: &SomMetaNode,
        path: &str,
        body: &YamlMap,
    ) -> Result<(), SpecYamlError> {
        for (key, value) in body.iter() {
            if let Some(child) = decoder_child_by_key(node, key) {
                let child_path = spec_path_join(path, child.segment());
                self.load_child(&child, &child_path, key, value)?;
                continue;
            }
            if key == "content" {
                let v = decoder_scalar_of(value, &format!("{}/content", path))?;
                self.doc.set_content(path, &v);
                continue;
            }
            if key == "headline" {
                let v = decoder_scalar_of(value, &format!("{} (headline)", path))?;
                self.doc.set_headline(path, &v);
                continue;
            }
            if key == "codeSpec" {
                let v = decoder_scalar_of(value, &format!("{} (codeSpec)", path))?;
                self.doc.set_code_spec(path, &v);
                continue;
            }
            return Err(yaml_format_err(format!(
                "key `{}` under `{}` matches no member of {} (expected one of: {})",
                key,
                path,
                node.debug_name(),
                decoder_expected_keys(node).join(", ")
            )));
        }
        Ok(())
    }

    fn load_child(
        &mut self,
        child: &SomMetaNode,
        path: &str,
        key: &str,
        value: &YamlValue,
    ) -> Result<(), SpecYamlError> {
        match child.kind.as_str() {
            SOM_META_KIND_CONTENT | SOM_META_KIND_SCALAR | SOM_META_KIND_ENUM_VALUE => {
                // A populated mapping is a headline-/codeSpec-extended scalar
                // node (YRD3 + §9.2): `{headline?: …, codeSpec?: …, content: …}`.
                // An empty mapping is the hand-rolled parser's spelling of a
                // bare `key:` and stays the empty scalar.
                if let Some(m) = value.as_map() {
                    if !m.is_empty() {
                        return self.load_scalar_with_meta(path, key, m);
                    }
                }
                let v = decoder_scalar_of(value, path)?;
                self.doc.set_content(path, &v);
                Ok(())
            }
            SOM_META_KIND_FORM => {
                let fields = match value.as_map() {
                    Some(m) => m,
                    None => {
                        return Err(yaml_format_err(format!(
                            "form `{}` at `{}` must hold a field mapping",
                            key, path
                        )))
                    }
                };
                let empty_meta = SomFormMeta::default();
                let meta = child.form.as_ref().unwrap_or(&empty_meta);
                for (name, raw) in fields.iter() {
                    if meta.field_named(name).is_none() {
                        if name == "headline" {
                            let v = decoder_scalar_of(raw, &format!("{} (headline)", path))?;
                            self.doc.set_headline(path, &v);
                            continue;
                        }
                        if name == "codeSpec" {
                            let v = decoder_scalar_of(raw, &format!("{} (codeSpec)", path))?;
                            self.doc.set_code_spec(path, &v);
                            continue;
                        }
                        return Err(yaml_format_err(format!(
                            "form `{}` has no field `{}` in the model",
                            path, name
                        )));
                    }
                    let v = decoder_scalar_of(raw, &format!("{}.{}", path, name))?;
                    self.doc.set_form_field(path, name, &v);
                }
                Ok(())
            }
            SOM_META_KIND_SECTION | SOM_META_KIND_COMPLEX => {
                let mapping = match value.as_map() {
                    Some(m) => m,
                    None => {
                        return Err(yaml_format_err(format!(
                            "section `{}` at `{}` must hold a mapping, not a scalar",
                            key, path
                        )))
                    }
                };
                self.load_mapping(child, path, mapping)
            }
            SOM_META_KIND_LIST => {
                let items = match value.as_map() {
                    Some(m) => m,
                    None => {
                        return Err(yaml_format_err(format!(
                            "list `{}` at `{}` must hold an item mapping",
                            key, path
                        )))
                    }
                };
                self.load_list(child, path, items)
            }
            _ => Ok(()),
        }
    }

    fn load_list(
        &mut self,
        node: &SomMetaNode,
        path: &str,
        items: &YamlMap,
    ) -> Result<(), SpecYamlError> {
        for (key, value) in items.iter() {
            if key == "headline" {
                // The list container's own stored headline (YRD3), not an item.
                let v = decoder_scalar_of(value, &format!("{} (headline)", path))?;
                self.doc.set_headline(path, &v);
                continue;
            }
            if key == "codeSpec" {
                // The list container's own codeSpec mapping (§9.2), not an item.
                let v = decoder_scalar_of(value, &format!("{} (codeSpec)", path))?;
                self.doc.set_code_spec(path, &v);
                continue;
            }
            let item_path = if is_anonymous_item_key(&node.member_name, key) {
                self.doc.add_list_item(path)
            } else {
                self.doc
                    .add_list_item_with_section_id(path, key)
                    .map_err(SpecYamlError::SectionId)?
            };
            match &node.element_node {
                None => {
                    // Scalar list item: the value is the item itself — or a
                    // `{headline?: …, codeSpec?: …, content: …}` mapping when it
                    // carries a stored headline and/or codeSpec (YRD3 + §9.2).
                    // The hand-rolled parser cannot distinguish a bare `key:`
                    // (null) from `key: {}`, so an empty mapping counts as "no
                    // value" here.
                    match value {
                        YamlValue::Seq(_) => {
                            return Err(yaml_format_err(format!(
                                "scalar list item `{}` at `{}` must hold a scalar",
                                key, path
                            )));
                        }
                        YamlValue::Map(m) => {
                            if !m.is_empty() {
                                self.load_scalar_with_meta(&item_path, key, m)?;
                            }
                            continue;
                        }
                        _ => {
                            self.doc.set_content(&item_path, &parsed_scalar_str(value));
                        }
                    }
                }
                Some(element) => {
                    let mapping = match value.as_map() {
                        Some(m) => m,
                        None => {
                            return Err(yaml_format_err(format!(
                                "list item `{}` at `{}` must hold a mapping (use `{{}}` for an empty item)",
                                key, path
                            )))
                        }
                    };
                    self.load_mapping(element, &item_path, mapping)?;
                }
            }
        }
        Ok(())
    }

    /// Loads a headline-/codeSpec-extended scalar node (YRD3 + §9.2): a mapping
    /// holding only the literal keys `headline`, `codeSpec` and `content`.
    fn load_scalar_with_meta(
        &mut self,
        path: &str,
        key: &str,
        value: &YamlMap,
    ) -> Result<(), SpecYamlError> {
        for (name, v) in value.iter() {
            match name.as_str() {
                "headline" => {
                    let s = decoder_scalar_of(v, &format!("{} (headline)", path))?;
                    self.doc.set_headline(path, &s);
                }
                "codeSpec" => {
                    let s = decoder_scalar_of(v, &format!("{} (codeSpec)", path))?;
                    self.doc.set_code_spec(path, &s);
                }
                "content" => {
                    let s = decoder_scalar_of(v, &format!("{}/content", path))?;
                    self.doc.set_content(path, &s);
                }
                _ => {
                    return Err(yaml_format_err(format!(
                        "scalar node `{}` at `{}` may only hold `headline`/`codeSpec`/`content` keys when written as a mapping, found `{}`",
                        key, path, name
                    )));
                }
            }
        }
        Ok(())
    }
}

/// Reports whether `key` is an anonymous positional item key
/// (`^<member>-[0-9]+$`).
fn is_anonymous_item_key(member_name: &str, key: &str) -> bool {
    match key.strip_prefix(member_name).and_then(|r| r.strip_prefix('-')) {
        Some(digits) => !digits.is_empty() && digits.bytes().all(|b| b.is_ascii_digit()),
        None => false,
    }
}

fn decoder_child_by_key(node: &SomMetaNode, key: &str) -> Option<std::rc::Rc<SomMetaNode>> {
    node.children.iter().find(|c| node_key(c) == key).cloned()
}

fn decoder_expected_keys(node: &SomMetaNode) -> Vec<String> {
    let mut out: Vec<String> = node
        .children
        .iter()
        .map(|c| format!("`{}`", node_key(c)))
        .collect();
    out.push("`content`".to_string());
    out.push("`headline`".to_string());
    out.push("`codeSpec`".to_string());
    out
}

/// Coerces a parsed leaf value to the document's string store. The hand-rolled
/// parser yields an empty mapping for a bare `key:` (where a real YAML parser
/// yields null), so an *empty* mapping counts as the empty string; a populated
/// mapping or a sequence is still a structural error.
fn decoder_scalar_of(value: &YamlValue, where_: &str) -> Result<String, SpecYamlError> {
    match value {
        YamlValue::Seq(_) => Err(yaml_format_err(format!(
            "expected a scalar value at `{}`",
            where_
        ))),
        YamlValue::Map(m) => {
            if m.is_empty() {
                Ok(String::new())
            } else {
                Err(yaml_format_err(format!(
                    "expected a scalar value at `{}`",
                    where_
                )))
            }
        }
        _ => Ok(parsed_scalar_str(value)),
    }
}
