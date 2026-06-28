//! `spec_document_yaml` — generic YAML codec for the native `*.docspecs.yaml`
//! document format, a faithful port of the Go `spec_document_yaml.go`.
//!
//! A header comment, `version:` (the on-disk format version), an optional
//! `modelVersion:` stamp (the authoring object-model major.minor), then the
//! `document:` pass — the live object-model values, sorted by full section path.
//!
//! All text values are written as literal block scalars (`|2-`) so multi-line
//! content round-trips verbatim. The emitter is self-verifying: it re-parses each
//! block it produces (via the hand-rolled YAML reader) and falls back to a
//! JSON-quoted scalar (always valid YAML) for any value a clean block can't
//! represent. The JSON quoting is byte-for-byte identical to JavaScript's
//! `JSON.stringify` (see [`js_json_string`]) so output is stable across every
//! language port.

use std::collections::BTreeMap;

use crate::spec_document::{DocumentJson, ListJson, SpecDocument};
use crate::yaml::{yaml_parse, YamlValue};

/// The on-disk format version (independent of the model-version stamp).
pub const FORMAT_VERSION: i64 = 1;

/// The decoded passes of a `*.docspecs.yaml` file: the `document:` pass as a
/// [`DocumentJson`], the `review:` pass as a raw map (the runtime is
/// review-agnostic), and the optional authoring model-version stamp.
#[derive(Debug, Clone, Default)]
pub struct SpecYamlContents {
    pub document: DocumentJson,
    pub review: BTreeMap<String, YamlValue>,
    pub model_version: String,
}

/// Renders `s` exactly as JavaScript's `JSON.stringify` would: wrapped in double
/// quotes, with the short escapes for `" \ \b \f \n \r \t`, control characters
/// below `0x20` as lowercase `\u00xx`, and every other char (including all
/// non-ASCII and the HTML-sensitive `< > & /`) emitted verbatim.
pub fn js_json_string(s: &str) -> String {
    crate::json::encode_str(s)
}

/// Returns a safely-quoted mapping key.
fn yaml_key(key: &str) -> String {
    js_json_string(key)
}

fn trailing_newlines(value: &str) -> usize {
    value.bytes().rev().take_while(|&b| b == b'\n').count()
}

/// Builds a literal block scalar (`|2<chomp>`) with body at relative indent 2, or
/// `None` when chomping can't reproduce the value's trailing newlines (two or
/// more) — those fall back to JSON quoting.
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

/// Reports whether re-parsing `_v: <block>` yields exactly `value`.
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
}

/// Writes `<indent><key>: <scalar>` where the scalar is a self-verified block
/// scalar (or a JSON-quoted fallback). Body lines, emitted at a relative indent
/// of 2, are re-indented to `key_indent + 2`.
fn write_scalar(b: &mut YamlBuffer, key_indent: usize, key: &str, value: &str) {
    let pad = " ".repeat(key_indent);
    let repr = scalar_repr(value);
    let lines: Vec<&str> = repr.split('\n').collect();
    b.writeln(&format!("{}{}: {}", pad, yaml_key(key), lines[0]));
    for line in &lines[1..] {
        if line.is_empty() {
            b.writeln("");
        } else {
            b.writeln(&format!("{}{}", pad, line));
        }
    }
}

fn write_header(b: &mut YamlBuffer, model_version: &str) {
    b.writeln("# TomSpecs document (*.docspecs.yaml).");
    b.writeln("# `document:` holds the object-model values, sorted by section id; text");
    b.writeln("# values use block scalars so multi-line content round-trips verbatim (\u{00A7}15.1).");
    b.writeln(&format!("version: {}", FORMAT_VERSION));
    if !model_version.is_empty() {
        b.writeln(&format!("modelVersion: {}", js_json_string(model_version)));
    }
}

fn write_document_pass(b: &mut YamlBuffer, doc: &DocumentJson) {
    if doc.content.is_empty() && doc.forms.is_empty() && doc.lists.is_empty() {
        b.writeln("document: {}");
        return;
    }
    b.writeln("document:");

    if !doc.content.is_empty() {
        b.writeln("  content:");
        for (k, v) in &doc.content {
            write_scalar(b, 4, k, v);
        }
    }

    if !doc.forms.is_empty() {
        b.writeln("  forms:");
        for (k, fields) in &doc.forms {
            if fields.is_empty() {
                continue;
            }
            b.writeln(&format!("    {}:", yaml_key(k)));
            for (f, v) in fields {
                write_scalar(b, 6, f, v);
            }
        }
    }

    if !doc.lists.is_empty() {
        b.writeln("  lists:");
        for (k, spec) in &doc.lists {
            b.writeln(&format!("    {}:", yaml_key(k)));
            b.writeln(&format!("      seq: {}", spec.seq));
            if !spec.items.is_empty() {
                b.writeln("      items:");
                for it in &spec.items {
                    b.writeln(&format!("        - {}", yaml_key(it)));
                }
            } else {
                b.writeln("      items: []");
            }
        }
    }
}

/// Serializes `document` to a header + `version:` (+ `modelVersion:`) +
/// `document:` pass.
pub fn encode_yaml(document: &SpecDocument, model_version: &str) -> String {
    let mut b = YamlBuffer::new();
    write_header(&mut b, model_version);
    write_document_pass(&mut b, &document.to_json());
    b.out
}

/// Parses a `*.docspecs.yaml` document into its passes. A missing pass decodes as
/// empty rather than failing, so a partial/hand-written file still loads what it
/// has.
pub fn decode_yaml(yaml_text: &str) -> SpecYamlContents {
    let root = if yaml_text.trim().is_empty() {
        YamlValue::Map(BTreeMap::new())
    } else {
        yaml_parse(yaml_text)
    };

    let document = match root.get("document") {
        Some(v) => doc_json_from_yaml(v),
        None => DocumentJson::default(),
    };
    let review = match root.get("review") {
        Some(YamlValue::Map(m)) => m.clone(),
        _ => BTreeMap::new(),
    };
    let model_version = match root.get("modelVersion") {
        Some(YamlValue::Str(s)) if !s.is_empty() => s.clone(),
        _ => String::new(),
    };

    SpecYamlContents {
        document,
        review,
        model_version,
    }
}

/// Converts the parsed `document:` mapping into a [`DocumentJson`].
fn doc_json_from_yaml(v: &YamlValue) -> DocumentJson {
    let mut out = DocumentJson::default();
    let m = match v.as_map() {
        Some(m) => m,
        None => return out,
    };
    if let Some(YamlValue::Map(content)) = m.get("content") {
        for (k, val) in content {
            out.content.insert(k.clone(), val.scalar_string());
        }
    }
    if let Some(YamlValue::Map(forms)) = m.get("forms") {
        for (k, val) in forms {
            if let YamlValue::Map(fields) = val {
                let mut entry = BTreeMap::new();
                for (f, fv) in fields {
                    entry.insert(f.clone(), fv.scalar_string());
                }
                out.forms.insert(k.clone(), entry);
            }
        }
    }
    if let Some(YamlValue::Map(lists)) = m.get("lists") {
        for (k, val) in lists {
            if let YamlValue::Map(spec) = val {
                let seq = spec.get("seq").and_then(|s| s.as_int()).unwrap_or(0);
                let mut items = Vec::new();
                if let Some(YamlValue::Seq(raw_items)) = spec.get("items") {
                    for it in raw_items {
                        items.push(it.scalar_string());
                    }
                }
                out.lists.insert(k.clone(), ListJson { seq, items });
            }
        }
    }
    out
}
