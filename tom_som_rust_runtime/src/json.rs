//! `json` — a hand-rolled, dependency-free JSON parser and value model.
//!
//! Rust's standard library ships no JSON support (unlike Go's `encoding/json`),
//! and the SOM runtime carries **zero external dependencies** — so this module
//! stands in for `serde_json`. It parses the meta-data file, the conformance
//! corpus fixtures, and the `document:` pass loaded from YAML. Output (the
//! byte-stable `*.docspecs.yaml` scalars) is produced by
//! [`crate::spec_document_yaml::js_json_string`], not here, so this parser only
//! needs to *read*.
//!
//! The value model ([`Json`]) keeps object keys in source order in a `Vec` of
//! pairs; callers that need stable ordering sort at use sites (the document
//! stores use `BTreeMap`).

/// A parsed JSON value.
#[derive(Debug, Clone, PartialEq)]
pub enum Json {
    Null,
    Bool(bool),
    Int(i64),
    Float(f64),
    Str(String),
    Array(Vec<Json>),
    Object(Vec<(String, Json)>),
}

impl Json {
    /// Returns the value at `key` when this is an object, else `None`.
    pub fn get(&self, key: &str) -> Option<&Json> {
        match self {
            Json::Object(pairs) => pairs.iter().find(|(k, _)| k == key).map(|(_, v)| v),
            _ => None,
        }
    }

    /// Returns the string when this is a `Str`, else `None`.
    pub fn as_str(&self) -> Option<&str> {
        match self {
            Json::Str(s) => Some(s),
            _ => None,
        }
    }

    /// Returns the integer when this is an `Int` (or an integral `Float`).
    pub fn as_i64(&self) -> Option<i64> {
        match self {
            Json::Int(n) => Some(*n),
            Json::Float(f) if f.fract() == 0.0 => Some(*f as i64),
            _ => None,
        }
    }

    /// Returns the boolean when this is a `Bool`, else `None`.
    pub fn as_bool(&self) -> Option<bool> {
        match self {
            Json::Bool(b) => Some(*b),
            _ => None,
        }
    }

    /// Returns the elements when this is an `Array`, else `None`.
    pub fn as_array(&self) -> Option<&[Json]> {
        match self {
            Json::Array(a) => Some(a),
            _ => None,
        }
    }

    /// Returns the key/value pairs when this is an `Object`, else `None`.
    pub fn as_object(&self) -> Option<&[(String, Json)]> {
        match self {
            Json::Object(o) => Some(o),
            _ => None,
        }
    }

    /// Convenience: the string at `key`, or `""`.
    pub fn str_or(&self, key: &str) -> String {
        self.get(key).and_then(|v| v.as_str()).unwrap_or("").to_string()
    }

    /// Convenience: the bool at `key`, or `false`.
    pub fn bool_or(&self, key: &str) -> bool {
        self.get(key).and_then(|v| v.as_bool()).unwrap_or(false)
    }

    /// Parses a JSON document from text.
    pub fn parse(text: &str) -> Result<Json, String> {
        let chars: Vec<char> = text.chars().collect();
        let mut p = Parser { chars, idx: 0 };
        p.skip_ws();
        let v = p.parse_value()?;
        p.skip_ws();
        if p.idx != p.chars.len() {
            return Err(format!("trailing data at position {}", p.idx));
        }
        Ok(v)
    }
}

/// Encodes `s` as a JSON string literal (wrapped in double quotes), used for the
/// internal canonical-JSON comparison in the document stores. Matches
/// JavaScript's `JSON.stringify` for a string: short escapes for the C0 set,
/// `\u00xx` for the remaining control characters, everything else verbatim.
pub fn encode_str(s: &str) -> String {
    const HEX: &[u8] = b"0123456789abcdef";
    let mut out = String::with_capacity(s.len() + 2);
    out.push('"');
    for ch in s.chars() {
        match ch {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\u{0008}' => out.push_str("\\b"),
            '\u{000C}' => out.push_str("\\f"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if (c as u32) < 0x20 => {
                let code = c as u32;
                out.push_str("\\u00");
                out.push(HEX[((code >> 4) & 0xf) as usize] as char);
                out.push(HEX[(code & 0xf) as usize] as char);
            }
            c => out.push(c),
        }
    }
    out.push('"');
    out
}

struct Parser {
    chars: Vec<char>,
    idx: usize,
}

impl Parser {
    fn peek(&self) -> Option<char> {
        self.chars.get(self.idx).copied()
    }

    fn skip_ws(&mut self) {
        while let Some(c) = self.peek() {
            if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
                self.idx += 1;
            } else {
                break;
            }
        }
    }

    fn parse_value(&mut self) -> Result<Json, String> {
        self.skip_ws();
        match self.peek() {
            Some('{') => self.parse_object(),
            Some('[') => self.parse_array(),
            Some('"') => Ok(Json::Str(self.parse_string()?)),
            Some('t') | Some('f') => self.parse_bool(),
            Some('n') => self.parse_null(),
            Some(c) if c == '-' || c.is_ascii_digit() => self.parse_number(),
            other => Err(format!("unexpected token {:?} at {}", other, self.idx)),
        }
    }

    fn parse_object(&mut self) -> Result<Json, String> {
        self.idx += 1; // '{'
        let mut pairs = Vec::new();
        self.skip_ws();
        if self.peek() == Some('}') {
            self.idx += 1;
            return Ok(Json::Object(pairs));
        }
        loop {
            self.skip_ws();
            if self.peek() != Some('"') {
                return Err(format!("expected object key at {}", self.idx));
            }
            let key = self.parse_string()?;
            self.skip_ws();
            if self.peek() != Some(':') {
                return Err(format!("expected ':' at {}", self.idx));
            }
            self.idx += 1;
            let value = self.parse_value()?;
            pairs.push((key, value));
            self.skip_ws();
            match self.peek() {
                Some(',') => {
                    self.idx += 1;
                }
                Some('}') => {
                    self.idx += 1;
                    break;
                }
                other => return Err(format!("expected ',' or '}}' at {}, got {:?}", self.idx, other)),
            }
        }
        Ok(Json::Object(pairs))
    }

    fn parse_array(&mut self) -> Result<Json, String> {
        self.idx += 1; // '['
        let mut items = Vec::new();
        self.skip_ws();
        if self.peek() == Some(']') {
            self.idx += 1;
            return Ok(Json::Array(items));
        }
        loop {
            let value = self.parse_value()?;
            items.push(value);
            self.skip_ws();
            match self.peek() {
                Some(',') => {
                    self.idx += 1;
                }
                Some(']') => {
                    self.idx += 1;
                    break;
                }
                other => return Err(format!("expected ',' or ']' at {}, got {:?}", self.idx, other)),
            }
        }
        Ok(Json::Array(items))
    }

    fn parse_string(&mut self) -> Result<String, String> {
        self.idx += 1; // opening '"'
        let mut out = String::new();
        loop {
            let c = match self.peek() {
                Some(c) => c,
                None => return Err("unterminated string".to_string()),
            };
            self.idx += 1;
            match c {
                '"' => break,
                '\\' => {
                    let esc = match self.peek() {
                        Some(e) => e,
                        None => return Err("unterminated escape".to_string()),
                    };
                    self.idx += 1;
                    match esc {
                        '"' => out.push('"'),
                        '\\' => out.push('\\'),
                        '/' => out.push('/'),
                        'b' => out.push('\u{0008}'),
                        'f' => out.push('\u{000C}'),
                        'n' => out.push('\n'),
                        'r' => out.push('\r'),
                        't' => out.push('\t'),
                        'u' => {
                            let cp = self.parse_hex4()?;
                            if (0xD800..=0xDBFF).contains(&cp) {
                                // high surrogate — expect a following \uXXXX low surrogate.
                                if self.peek() == Some('\\') {
                                    self.idx += 1;
                                    if self.peek() == Some('u') {
                                        self.idx += 1;
                                        let low = self.parse_hex4()?;
                                        if (0xDC00..=0xDFFF).contains(&low) {
                                            let combined = 0x10000
                                                + ((cp - 0xD800) << 10)
                                                + (low - 0xDC00);
                                            out.push(
                                                char::from_u32(combined)
                                                    .unwrap_or('\u{FFFD}'),
                                            );
                                        } else {
                                            out.push('\u{FFFD}');
                                            out.push(
                                                char::from_u32(low).unwrap_or('\u{FFFD}'),
                                            );
                                        }
                                    } else {
                                        out.push('\u{FFFD}');
                                    }
                                } else {
                                    out.push('\u{FFFD}');
                                }
                            } else {
                                out.push(char::from_u32(cp).unwrap_or('\u{FFFD}'));
                            }
                        }
                        other => return Err(format!("invalid escape \\{}", other)),
                    }
                }
                _ => out.push(c),
            }
        }
        Ok(out)
    }

    fn parse_hex4(&mut self) -> Result<u32, String> {
        let mut v = 0u32;
        for _ in 0..4 {
            let c = match self.peek() {
                Some(c) => c,
                None => return Err("unterminated \\u escape".to_string()),
            };
            let d = c.to_digit(16).ok_or_else(|| format!("bad hex digit {}", c))?;
            v = v * 16 + d;
            self.idx += 1;
        }
        Ok(v)
    }

    fn parse_bool(&mut self) -> Result<Json, String> {
        if self.matches("true") {
            Ok(Json::Bool(true))
        } else if self.matches("false") {
            Ok(Json::Bool(false))
        } else {
            Err(format!("invalid literal at {}", self.idx))
        }
    }

    fn parse_null(&mut self) -> Result<Json, String> {
        if self.matches("null") {
            Ok(Json::Null)
        } else {
            Err(format!("invalid literal at {}", self.idx))
        }
    }

    fn matches(&mut self, lit: &str) -> bool {
        let lit_chars: Vec<char> = lit.chars().collect();
        if self.idx + lit_chars.len() > self.chars.len() {
            return false;
        }
        for (k, &lc) in lit_chars.iter().enumerate() {
            if self.chars[self.idx + k] != lc {
                return false;
            }
        }
        self.idx += lit_chars.len();
        true
    }

    fn parse_number(&mut self) -> Result<Json, String> {
        let start = self.idx;
        let mut is_float = false;
        if self.peek() == Some('-') {
            self.idx += 1;
        }
        while let Some(c) = self.peek() {
            match c {
                '0'..='9' => self.idx += 1,
                '.' | 'e' | 'E' | '+' | '-' => {
                    is_float = true;
                    self.idx += 1;
                }
                _ => break,
            }
        }
        let s: String = self.chars[start..self.idx].iter().collect();
        if is_float {
            s.parse::<f64>()
                .map(Json::Float)
                .map_err(|e| format!("bad number {}: {}", s, e))
        } else {
            match s.parse::<i64>() {
                Ok(n) => Ok(Json::Int(n)),
                Err(_) => s
                    .parse::<f64>()
                    .map(Json::Float)
                    .map_err(|e| format!("bad number {}: {}", s, e)),
            }
        }
    }
}
