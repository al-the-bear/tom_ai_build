//! `yaml` — a minimal, dependency-free YAML reader for the constrained
//! `*.docspecs.yaml` subset the codec emits, a faithful port of the Go
//! `yaml.go`.
//!
//! The runtime ships with no external libraries, so this hand-rolled
//! indentation parser stands in for a YAML crate. It supports exactly what the
//! encoder produces (and what the self-verify round-trip probe needs): block
//! mappings, block sequences (`- item`), literal block scalars (`|`, `|-`, `|2`,
//! `|2-` …), JSON-quoted flow scalars, plain integers, and the empty flow
//! collections `{}` / `[]`.
//!
//! The dynamic value model is [`YamlValue`]: mappings are **insertion-ordered**
//! maps ([`YamlMap`], mirroring the Go `YamlMap` — the hierarchical v2 codec
//! walks keys in file order), sequences are vectors, scalars are strings or
//! integers. JSON-quoted scalars are parsed via the hand-rolled [`crate::json`]
//! parser. [`yaml_parse_typed`] additionally reads plain scalars by the YAML 1.2
//! core schema (SOM §12.5: null, bool, int, float) — used for the uninterpreted
//! `review:` pass.

use crate::json::Json;

/// An insertion-ordered string-keyed mapping, the Rust mirror of the Go
/// `YamlMap`: keys iterate in the order they first appeared in the source, and
/// re-setting an existing key updates it in place.
#[derive(Debug, Clone, PartialEq, Default)]
pub struct YamlMap {
    entries: Vec<(String, YamlValue)>,
}

impl YamlMap {
    /// Returns an empty map.
    pub fn new() -> YamlMap {
        YamlMap::default()
    }

    /// Returns the number of entries.
    pub fn len(&self) -> usize {
        self.entries.len()
    }

    /// Reports whether the map holds no entries.
    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    /// Reports whether `key` is present.
    pub fn has(&self, key: &str) -> bool {
        self.entries.iter().any(|(k, _)| k == key)
    }

    /// Returns the value at `key`, or `None`.
    pub fn get(&self, key: &str) -> Option<&YamlValue> {
        self.entries.iter().find(|(k, _)| k == key).map(|(_, v)| v)
    }

    /// Sets `key` to `value`: updates in place when present, appends otherwise.
    pub fn insert(&mut self, key: String, value: YamlValue) {
        if let Some(slot) = self.entries.iter_mut().find(|(k, _)| *k == key) {
            slot.1 = value;
        } else {
            self.entries.push((key, value));
        }
    }

    /// Returns the keys in insertion order.
    pub fn keys(&self) -> Vec<&str> {
        self.entries.iter().map(|(k, _)| k.as_str()).collect()
    }

    /// Iterates the entries in insertion order.
    pub fn iter(&self) -> impl Iterator<Item = &(String, YamlValue)> {
        self.entries.iter()
    }
}

/// A parsed YAML value.
///
/// [`yaml_parse`] yields maps, sequences, strings and integers only; `Null`,
/// `Bool` and `Float` come from [`yaml_parse_typed`] (the YAML 1.2 core-schema
/// reading, SOM §12.5), where `Int` and `Float` stay distinct so a whole float
/// (`3.0`) is written back as a float and an integer (`3`) as an integer.
#[derive(Debug, Clone, PartialEq)]
pub enum YamlValue {
    Map(YamlMap),
    Seq(Vec<YamlValue>),
    Str(String),
    Int(i64),
    /// A null (typed reading only).
    Null,
    /// A boolean (typed reading only).
    Bool(bool),
    /// A float (typed reading only).
    Float(f64),
}

impl YamlValue {
    fn empty_map() -> YamlValue {
        YamlValue::Map(YamlMap::new())
    }

    /// Returns the value at `key` when this is a map, else `None`.
    pub fn get(&self, key: &str) -> Option<&YamlValue> {
        match self {
            YamlValue::Map(m) => m.get(key),
            _ => None,
        }
    }

    /// Returns the map entries when this is a map, else `None`.
    pub fn as_map(&self) -> Option<&YamlMap> {
        match self {
            YamlValue::Map(m) => Some(m),
            _ => None,
        }
    }

    /// Returns the elements when this is a sequence, else `None`.
    pub fn as_seq(&self) -> Option<&[YamlValue]> {
        match self {
            YamlValue::Seq(s) => Some(s),
            _ => None,
        }
    }

    /// Returns the string when this is a string scalar, else `None`.
    pub fn as_str(&self) -> Option<&str> {
        match self {
            YamlValue::Str(s) => Some(s),
            _ => None,
        }
    }

    /// Returns the integer when this is an integer scalar, else `None`.
    pub fn as_int(&self) -> Option<i64> {
        match self {
            YamlValue::Int(n) => Some(*n),
            _ => None,
        }
    }

    /// Returns the scalar rendered as a string (string verbatim, integer
    /// formatted), or `""` for non-scalars.
    pub fn scalar_string(&self) -> String {
        match self {
            YamlValue::Str(s) => s.clone(),
            YamlValue::Int(n) => n.to_string(),
            _ => String::new(),
        }
    }
}

fn yaml_leading(line: &str) -> usize {
    line.bytes().take_while(|&b| b == b' ').count()
}

fn yaml_is_integer(s: &str) -> bool {
    if s.is_empty() {
        return false;
    }
    let bytes = s.as_bytes();
    let mut i = 0;
    if bytes[0] == b'-' || bytes[0] == b'+' {
        if bytes.len() == 1 {
            return false;
        }
        i = 1;
    }
    bytes[i..].iter().all(|b| b.is_ascii_digit())
}

fn yaml_find_colon(content: &str) -> Option<usize> {
    let bytes = content.as_bytes();
    if content.starts_with('"') {
        let mut i = 1;
        while i < bytes.len() {
            let c = bytes[i];
            if c == b'\\' {
                i += 2;
                continue;
            }
            if c == b'"' {
                i += 1;
                break;
            }
            i += 1;
        }
        return content[i..].find(':').map(|idx| i + idx);
    }
    content.find(':')
}

fn yaml_parse_scalar_key(key_part: &str) -> String {
    if key_part.starts_with('"') {
        if let Ok(Json::Str(v)) = Json::parse(key_part) {
            return v;
        }
        return String::new();
    }
    key_part.to_string()
}

struct YamlReader {
    lines: Vec<String>,
    idx: usize,
    /// Raw-scalar mode ([`yaml_parse_raw_scalars`]): every flow scalar is kept
    /// as its source text, and a block scalar as the JSON string literal of its
    /// content, so the caller can tell `null` from `"null"`.
    raw: bool,
    /// Typed mode ([`yaml_parse_typed`]): plain scalars are read by the YAML 1.2
    /// core schema ([`yaml_typed_plain`]) and an empty value is null.
    typed: bool,
}

impl YamlReader {
    fn next_significant(&self, from: usize) -> Option<usize> {
        for i in from..self.lines.len() {
            let t = self.lines[i].trim();
            if t.is_empty() || t.starts_with('#') {
                continue;
            }
            return Some(i);
        }
        None
    }

    fn parse_node(&mut self, min_indent: usize) -> YamlValue {
        let i = match self.next_significant(self.idx) {
            Some(i) => i,
            None => return YamlValue::empty_map(),
        };
        let line = &self.lines[i];
        let indent = yaml_leading(line);
        if indent < min_indent {
            return YamlValue::empty_map();
        }
        let content = &line[indent..];
        if content == "-" || content.starts_with("- ") {
            self.parse_sequence(indent)
        } else {
            self.parse_mapping(indent)
        }
    }

    fn parse_mapping(&mut self, indent: usize) -> YamlValue {
        let mut m = YamlMap::new();
        while let Some(i) = self.next_significant(self.idx) {
            let line = self.lines[i].clone();
            let cur_indent = yaml_leading(&line);
            if cur_indent != indent {
                break; // dedent → belongs to the parent.
            }
            self.idx = i + 1;
            let content = &line[indent..];
            let colon = match yaml_find_colon(content) {
                Some(c) => c,
                None => continue, // not a mapping entry — tolerate and skip.
            };
            let key = yaml_parse_scalar_key(content[..colon].trim());
            let rest = content[colon + 1..].trim().to_string();
            let value = if rest.is_empty() {
                match self.parse_nested_after_key(indent) {
                    // An empty value is null (YAML 1.2 core schema).
                    YamlValue::Map(m) if self.typed && m.is_empty() => YamlValue::Null,
                    v => v,
                }
            } else if rest.starts_with('|') || rest.starts_with('>') {
                self.block_value(&rest, indent)
            } else {
                self.parse_flow_scalar(&rest)
            };
            m.insert(key, value);
        }
        YamlValue::Map(m)
    }

    fn parse_sequence(&mut self, indent: usize) -> YamlValue {
        let mut list = Vec::new();
        while let Some(i) = self.next_significant(self.idx) {
            let line = self.lines[i].clone();
            let cur_indent = yaml_leading(&line);
            if cur_indent != indent {
                break;
            }
            let content = &line[indent..];
            if content != "-" && !content.starts_with("- ") {
                break;
            }
            self.idx = i + 1;
            let item_text = if content == "-" {
                String::new()
            } else {
                content[2..].trim().to_string()
            };
            if item_text.is_empty() {
                list.push(self.parse_nested_after_key(indent));
            } else if item_text.starts_with('|') || item_text.starts_with('>') {
                list.push(self.block_value(&item_text, indent));
            } else {
                // A `- key: …` item is a mapping whose first entry sits on the
                // dash line; rewrite the dash as indentation and re-parse as a
                // mapping (mirrors the Go reader).
                let colon = yaml_find_colon(&item_text);
                let is_map_entry = colon.is_some_and(|c| {
                    c == item_text.len() - 1 || item_text.as_bytes()[c + 1] == b' '
                });
                if is_map_entry {
                    self.idx = i;
                    self.lines[i] = format!("{}{}", " ".repeat(indent + 2), &line[indent + 2..]);
                    list.push(self.parse_mapping(indent + 2));
                } else {
                    list.push(self.parse_flow_scalar(&item_text));
                }
            }
        }
        YamlValue::Seq(list)
    }

    fn parse_nested_after_key(&mut self, parent_indent: usize) -> YamlValue {
        let i = match self.next_significant(self.idx) {
            Some(i) => i,
            None => return YamlValue::empty_map(),
        };
        let child_indent = yaml_leading(&self.lines[i]);
        if child_indent <= parent_indent {
            return YamlValue::empty_map();
        }
        self.parse_node(child_indent)
    }

    fn parse_flow_scalar(&self, s: &str) -> YamlValue {
        let t = s.trim();
        if t == "{}" {
            return YamlValue::empty_map();
        }
        if t == "[]" {
            return YamlValue::Seq(Vec::new());
        }
        if self.raw {
            return YamlValue::Str(t.to_string());
        }
        if t.starts_with('"') {
            if let Ok(Json::Str(v)) = Json::parse(t) {
                return YamlValue::Str(v);
            }
            return YamlValue::Str(t.to_string());
        }
        if self.typed {
            return yaml_typed_plain(t);
        }
        if yaml_is_integer(t) {
            if let Ok(n) = t.parse::<i64>() {
                return YamlValue::Int(n);
            }
        }
        YamlValue::Str(t.to_string())
    }

    /// A block scalar as a value: its content, or in raw-scalar mode the JSON
    /// string literal of its content (so it reads back as a quoted scalar).
    fn block_value(&mut self, header: &str, key_indent: usize) -> YamlValue {
        let content = self.parse_block_scalar(header, key_indent);
        if self.raw {
            YamlValue::Str(crate::json::encode_str(&content))
        } else {
            YamlValue::Str(content)
        }
    }

    /// Parses a literal block scalar starting at `header` (e.g. `|2-`) whose body
    /// lines follow. `key_indent` is the indentation of the owning key/sequence
    /// line.
    fn parse_block_scalar(&mut self, header: &str, key_indent: usize) -> String {
        let hbytes = header.as_bytes();
        let mut p = 1; // skip the leading '|' (or '>').
        let digits_start = p;
        while p < hbytes.len() && hbytes[p].is_ascii_digit() {
            p += 1;
        }
        let explicit_indent: Option<usize> = if p > digits_start {
            header[digits_start..p].parse::<usize>().ok()
        } else {
            None
        };
        let mut chomp = b' ';
        while p < hbytes.len() {
            let c = hbytes[p];
            if c == b'-' || c == b'+' {
                chomp = c;
            }
            p += 1;
        }

        // Collect the raw body: blank lines plus any line indented past the key.
        let mut raw_body: Vec<String> = Vec::new();
        while self.idx < self.lines.len() {
            let l = self.lines[self.idx].clone();
            if l.trim().is_empty() {
                raw_body.push(String::new());
                self.idx += 1;
                continue;
            }
            if yaml_leading(&l) <= key_indent {
                break;
            }
            raw_body.push(l);
            self.idx += 1;
        }
        // Drop trailing blank lines that belong to the following node.
        while raw_body.last().map(|l| l.is_empty()).unwrap_or(false) {
            raw_body.pop();
        }

        let content_indent = match explicit_indent {
            Some(ei) => key_indent + ei,
            None => {
                let mut min = usize::MAX;
                for l in &raw_body {
                    if !l.is_empty() {
                        let ld = yaml_leading(l);
                        if ld < min {
                            min = ld;
                        }
                    }
                }
                if min == usize::MAX {
                    key_indent + 1
                } else {
                    min
                }
            }
        };

        let mut body: Vec<String> = Vec::new();
        for l in &raw_body {
            if l.is_empty() {
                body.push(String::new());
            } else {
                let strip = content_indent.min(l.len());
                body.push(l[strip..].to_string());
            }
        }

        let joined = body.join("\n");
        match chomp {
            b'-' => joined.trim_end_matches('\n').to_string(),
            b'+' => joined,
            _ => {
                // Clip (default): exactly one trailing newline when non-empty.
                let clipped = joined.trim_end_matches('\n');
                if clipped.is_empty() {
                    String::new()
                } else {
                    format!("{}\n", clipped)
                }
            }
        }
    }
}

/// Parses `text` into the value model (a map or sequence).
pub fn yaml_parse(text: &str) -> YamlValue {
    yaml_parse_with(text, false, false)
}

/// Parses `text` like [`yaml_parse`], but reads plain scalars by the YAML 1.2
/// core schema ([`yaml_typed_plain`]; an empty value is [`YamlValue::Null`])
/// instead of keeping them as strings — the reading the uninterpreted
/// `review:` pass needs to keep its values' types (SOM §12.5). Quoted and
/// block scalars stay strings.
pub fn yaml_parse_typed(text: &str) -> YamlValue {
    yaml_parse_with(text, false, true)
}

/// The YAML 1.2 core-schema reading of a plain scalar `t` (SOM §12.5, review
/// scalars — the schema package:yaml applies):
///
/// - null: `~`, `null`, `Null`, `NULL` and the empty scalar;
/// - bool: `true|True|TRUE|false|False|FALSE`;
/// - int: `[-+]?[0-9]+`, `0o[0-7]+`, `0x[0-9a-fA-F]+` → [`YamlValue::Int`]; an
///   integer outside the signed 64-bit range is read as a [`YamlValue::Float`];
/// - float: `[-+]?(\.[0-9]+|[0-9]+(\.[0-9]*)?)([eE][-+]?[0-9]+)?`,
///   `[-+]?\.(inf|Inf|INF)`, `\.(nan|NaN|NAN)`.
///
/// A JSON flow collection (the form the review writer gives a list) is parsed
/// as JSON. Anything else stays the string it is.
pub fn yaml_typed_plain(t: &str) -> YamlValue {
    match t {
        "" | "~" | "null" | "Null" | "NULL" => return YamlValue::Null,
        "true" | "True" | "TRUE" => return YamlValue::Bool(true),
        "false" | "False" | "FALSE" => return YamlValue::Bool(false),
        ".nan" | ".NaN" | ".NAN" => return YamlValue::Float(f64::NAN),
        _ => {}
    }
    let unsigned = t.strip_prefix(['-', '+']).unwrap_or(t);
    if matches!(unsigned, ".inf" | ".Inf" | ".INF") {
        let inf = if t.starts_with('-') { f64::NEG_INFINITY } else { f64::INFINITY };
        return YamlValue::Float(inf);
    }
    if yaml_is_integer(t) {
        return match t.parse::<i64>() {
            Ok(n) => YamlValue::Int(n),
            Err(_) => YamlValue::Float(t.parse::<f64>().unwrap_or(f64::NAN)),
        };
    }
    for (prefix, radix) in [("0o", 8), ("0x", 16)] {
        if let Some(digits) = t.strip_prefix(prefix) {
            if !digits.is_empty() && digits.chars().all(|c| c.is_digit(radix)) {
                return yaml_radix_int(digits, radix);
            }
        }
    }
    if yaml_is_float(t) {
        if let Ok(f) = t.parse::<f64>() {
            return YamlValue::Float(f);
        }
    }
    if t.starts_with('[') || t.starts_with('{') {
        if let Ok(j) = Json::parse(t) {
            return yaml_from_json(&j);
        }
    }
    YamlValue::Str(t.to_string())
}

/// `digits` in `radix` as an int when it fits a signed 64-bit integer, else as
/// the nearest float.
fn yaml_radix_int(digits: &str, radix: u32) -> YamlValue {
    if let Ok(n) = i64::from_str_radix(digits, radix) {
        return YamlValue::Int(n);
    }
    if let Ok(n) = u128::from_str_radix(digits, radix) {
        return YamlValue::Float(n as f64);
    }
    let f = digits.chars().fold(0f64, |acc, c| {
        acc * radix as f64 + c.to_digit(radix).unwrap_or(0) as f64
    });
    YamlValue::Float(f)
}

/// Reports whether `t` matches `[-+]?(\.[0-9]+|[0-9]+(\.[0-9]*)?)([eE][-+]?[0-9]+)?`.
fn yaml_is_float(t: &str) -> bool {
    let b = t.as_bytes();
    let mut i = 0;
    if i < b.len() && (b[i] == b'-' || b[i] == b'+') {
        i += 1;
    }
    let digits = |i: &mut usize| {
        let start = *i;
        while *i < b.len() && b[*i].is_ascii_digit() {
            *i += 1;
        }
        *i - start
    };
    if i < b.len() && b[i] == b'.' {
        i += 1;
        if digits(&mut i) == 0 {
            return false;
        }
    } else {
        if digits(&mut i) == 0 {
            return false;
        }
        if i < b.len() && b[i] == b'.' {
            i += 1;
            digits(&mut i);
        }
    }
    if i < b.len() && (b[i] == b'e' || b[i] == b'E') {
        i += 1;
        if i < b.len() && (b[i] == b'-' || b[i] == b'+') {
            i += 1;
        }
        if digits(&mut i) == 0 {
            return false;
        }
    }
    i == b.len()
}

/// A [`Json`] value in the typed value model (object order is kept).
fn yaml_from_json(j: &Json) -> YamlValue {
    match j {
        Json::Null => YamlValue::Null,
        Json::Bool(v) => YamlValue::Bool(*v),
        Json::Int(n) => YamlValue::Int(*n),
        Json::Float(f) => YamlValue::Float(*f),
        Json::Str(s) => YamlValue::Str(s.clone()),
        Json::Array(items) => YamlValue::Seq(items.iter().map(yaml_from_json).collect()),
        Json::Object(pairs) => {
            let mut m = YamlMap::new();
            for (k, v) in pairs {
                m.insert(k.clone(), yaml_from_json(v));
            }
            YamlValue::Map(m)
        }
    }
}

/// Parses `text` like [`yaml_parse`], but keeps every flow scalar as its
/// **source text** (`null`, `42`, `"a \"b\""`, `["x", "y"]` arrive verbatim as
/// [`YamlValue::Str`]) and every block scalar as the JSON string literal of its
/// content. Only `{}` and `[]` are still read as empty collections.
///
/// The default mode decodes a quoted scalar and leaves a plain one as text, so
/// `null` and `"null"` read the same; a reader that has to tell them apart —
/// the CodeSpecs record reader — types the scalars itself from this form.
pub fn yaml_parse_raw_scalars(text: &str) -> YamlValue {
    yaml_parse_with(text, true, false)
}

fn yaml_parse_with(text: &str, raw: bool, typed: bool) -> YamlValue {
    let lines: Vec<String> = text.split('\n').map(|s| s.to_string()).collect();
    let mut y = YamlReader { lines, idx: 0, raw, typed };
    if y.next_significant(0).is_none() {
        return YamlValue::empty_map();
    }
    y.parse_node(0)
}

/// Parses `text`, returning a map (empty when not a mapping).
pub fn yaml_parse_map(text: &str) -> YamlValue {
    match yaml_parse(text) {
        v @ YamlValue::Map(_) => v,
        _ => YamlValue::empty_map(),
    }
}
