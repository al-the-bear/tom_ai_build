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
//! The dynamic value model is [`YamlValue`]: mappings are maps, sequences are
//! vectors, scalars are strings or integers. JSON-quoted scalars are parsed via
//! the hand-rolled [`crate::json`] parser.

use std::collections::BTreeMap;

use crate::json::Json;

/// A parsed YAML value.
#[derive(Debug, Clone, PartialEq)]
pub enum YamlValue {
    Map(BTreeMap<String, YamlValue>),
    Seq(Vec<YamlValue>),
    Str(String),
    Int(i64),
}

impl YamlValue {
    fn empty_map() -> YamlValue {
        YamlValue::Map(BTreeMap::new())
    }

    /// Returns the value at `key` when this is a map, else `None`.
    pub fn get(&self, key: &str) -> Option<&YamlValue> {
        match self {
            YamlValue::Map(m) => m.get(key),
            _ => None,
        }
    }

    /// Returns the map entries when this is a map, else `None`.
    pub fn as_map(&self) -> Option<&BTreeMap<String, YamlValue>> {
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
        let mut m: BTreeMap<String, YamlValue> = BTreeMap::new();
        loop {
            let i = match self.next_significant(self.idx) {
                Some(i) => i,
                None => break,
            };
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
                self.parse_nested_after_key(indent)
            } else if rest.starts_with('|') || rest.starts_with('>') {
                YamlValue::Str(self.parse_block_scalar(&rest, indent))
            } else {
                self.parse_flow_scalar(&rest)
            };
            m.insert(key, value);
        }
        YamlValue::Map(m)
    }

    fn parse_sequence(&mut self, indent: usize) -> YamlValue {
        let mut list = Vec::new();
        loop {
            let i = match self.next_significant(self.idx) {
                Some(i) => i,
                None => break,
            };
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
                list.push(YamlValue::Str(self.parse_block_scalar(&item_text, indent)));
            } else {
                list.push(self.parse_flow_scalar(&item_text));
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
        if t.starts_with('"') {
            if let Ok(Json::Str(v)) = Json::parse(t) {
                return YamlValue::Str(v);
            }
            return YamlValue::Str(t.to_string());
        }
        if yaml_is_integer(t) {
            if let Ok(n) = t.parse::<i64>() {
                return YamlValue::Int(n);
            }
        }
        YamlValue::Str(t.to_string())
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
    let lines: Vec<String> = text.split('\n').map(|s| s.to_string()).collect();
    let mut y = YamlReader { lines, idx: 0 };
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
