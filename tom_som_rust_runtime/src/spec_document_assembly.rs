//! `spec_document_assembly` — assembling one spec document from fragments
//! written in parallel, a port of the Dart `spec_document_assembly.dart`.
//!
//! A large document is often authored in parts — one group, or one agent, per
//! set of sections — each part a document of its own holding a subset of the
//! sections. References between parts can only be judged on the whole: the
//! instance tier resolves a `refersTo` against the document it is given, so a
//! part validated alone reports every reference into another part as
//! dangling. [`SpecDocument::assemble`] is the step that produces the whole.
//!
//! The merge is over the plain-data stores ([`SpecDocument::to_json`]), and it
//! is **refusing**: a value two fragments both write — a content path, a form
//! field, a list, a headline, a code-spec location — is an overlap, and an
//! assembly with any overlap yields no document. Choosing a winner would make
//! the result depend on fragment order, and two parts writing one place is an
//! authoring conflict the parts' authors have to settle.

use std::collections::{HashMap, HashSet};
use std::fmt;

use crate::spec_document::{DocumentJson, SpecDocument};

/// The fixed order overlaps are reported in, by the stores' plain-data names.
const STORE_ORDER: [&str; 5] = ["content", "forms", "lists", "headlines", "codeSpecs"];

/// One place two or more fragments both write.
#[derive(Debug, Clone, PartialEq)]
pub struct SpecAssemblyOverlap {
    /// The store: `content`, `forms`, `lists`, `headlines` or `codeSpecs`.
    pub store: String,
    /// The document path.
    pub path: String,
    /// The form field, for the `forms` store; `None` otherwise.
    pub field: Option<String>,
    /// The fragments that write it, in the order they were given.
    pub fragments: Vec<String>,
}

impl SpecAssemblyOverlap {
    /// One sentence naming the place and every fragment that writes it.
    pub fn message(&self) -> String {
        let place = match &self.field {
            None => self.path.clone(),
            Some(field) => format!("{} field `{}`", self.path, field),
        };
        format!(
            "{} ({}) is written by {} \u{2014} a place two fragments both write is an \
             authoring conflict, not something the assembly may resolve",
            place,
            self.store,
            self.fragments.join(" and ")
        )
    }
}

impl fmt::Display for SpecAssemblyOverlap {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.message())
    }
}

/// The result of [`SpecDocument::assemble`].
#[derive(Debug, Clone)]
pub struct SpecDocumentAssembly {
    /// The assembled document; `None` when there is any overlap.
    pub document: Option<SpecDocument>,
    /// Every overlap, in store order and then path order.
    pub overlaps: Vec<SpecAssemblyOverlap>,
}

impl SpecDocumentAssembly {
    /// Whether the fragments assembled.
    pub fn ok(&self) -> bool {
        self.overlaps.is_empty()
    }
}

/// Orders two keys by UTF-16 code units — the order Dart's `String` sort gives
/// (Rust's `str` order is by UTF-8 bytes, which differs above U+FFFF).
fn utf16_cmp(a: &str, b: &str) -> std::cmp::Ordering {
    a.encode_utf16().cmp(b.encode_utf16())
}

/// Merges `fragments` — `(name, document)` pairs, in order — into one
/// document. See the module comment for the refusing rule.
///
/// # Panics
///
/// When two fragments share a name: the reference takes a name → document map,
/// so a name is given at most once there.
pub fn assemble_spec_documents(fragments: &[(&str, &SpecDocument)]) -> SpecDocumentAssembly {
    let mut names = HashSet::new();
    for (name, _) in fragments {
        assert!(names.insert(*name), "fragment name given twice: {}", name);
    }
    // store index → key → writer fragments; key is the path, or `path\0field`.
    let mut writers: Vec<HashMap<String, Vec<String>>> =
        (0..STORE_ORDER.len()).map(|_| HashMap::new()).collect();
    let mut merged = DocumentJson::default();

    fn note(writers: &mut HashMap<String, Vec<String>>, key: String, name: &str) {
        writers.entry(key).or_default().push(name.to_string());
    }

    for (name, doc) in fragments {
        let json = doc.to_json();
        for (path, value) in json.content {
            note(&mut writers[0], path.clone(), name);
            merged.content.entry(path).or_insert(value);
        }
        for (path, fields) in json.forms {
            let target = merged.forms.entry(path.clone()).or_default();
            for (field, value) in fields {
                note(&mut writers[1], format!("{}\u{0}{}", path, field), name);
                target.entry(field).or_insert(value);
            }
        }
        for (path, spec) in json.lists {
            note(&mut writers[2], path.clone(), name);
            merged.lists.entry(path).or_insert(spec);
        }
        for (path, value) in json.headlines {
            note(&mut writers[3], path.clone(), name);
            merged.headlines.entry(path).or_insert(value);
        }
        for (path, value) in json.code_specs {
            note(&mut writers[4], path.clone(), name);
            merged.code_specs.entry(path).or_insert(value);
        }
    }

    let mut overlaps = Vec::new();
    for (index, store) in writers.iter().enumerate() {
        let mut keys: Vec<&String> = store.keys().collect();
        keys.sort_by(|a, b| utf16_cmp(a, b));
        for key in keys {
            let who = &store[key];
            if who.len() < 2 {
                continue;
            }
            let (path, field) = match key.find('\u{0}') {
                None => (key.clone(), None),
                Some(sep) => (key[..sep].to_string(), Some(key[sep + 1..].to_string())),
            };
            overlaps.push(SpecAssemblyOverlap {
                store: STORE_ORDER[index].to_string(),
                path,
                field,
                fragments: who.clone(),
            });
        }
    }
    if !overlaps.is_empty() {
        return SpecDocumentAssembly {
            document: None,
            overlaps,
        };
    }
    let mut document = SpecDocument::new();
    document.load_json(&merged);
    SpecDocumentAssembly {
        document: Some(document),
        overlaps,
    }
}

impl SpecDocument {
    /// Assembles one document from fragments — `(name, document)` pairs, in
    /// order — written in parallel. The merge is refusing: a content path,
    /// form field, list, headline or code-spec location two fragments both
    /// write is a [`SpecAssemblyOverlap`], and an assembly with any overlap has
    /// no document. See [`assemble_spec_documents`].
    pub fn assemble(fragments: &[(&str, &SpecDocument)]) -> SpecDocumentAssembly {
        assemble_spec_documents(fragments)
    }
}
