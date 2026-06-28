//! `spec_reflection` — generic, value-free traversal of a [`SpecModel`] class
//! graph (the "reflection" surface), a faithful port of the Go
//! `spec_reflection.go`.
//!
//! It answers two kinds of question about a model: enumeration (what roots,
//! classes, fields and annotations exist) and resolution (which model node a
//! concrete document path addresses). It holds no document values.
//!
//! [`SpecResolution`] owns clones of the matched root / field / target class so
//! callers need not juggle borrows of the model.

use crate::spec_model::{
    SpecAnnotation, SpecClass, SpecField, SpecModel, SpecRoot, SPEC_FIELD_KIND_COMPLEX,
    SPEC_FIELD_KIND_CONTENT, SPEC_FIELD_KIND_ENUM, SPEC_FIELD_KIND_FORM, SPEC_FIELD_KIND_LIST,
    SPEC_FIELD_KIND_SCALAR, SPEC_FIELD_KIND_SECTION,
};
use crate::spec_paths::{spec_path_segments, split_list_item_segment};

/// What a resolved path lands on in the model.
pub const SPEC_NODE_KIND_ROOT: &str = "root";
pub const SPEC_NODE_KIND_COMPLEX: &str = "complex";
pub const SPEC_NODE_KIND_SECTION: &str = "section";
pub const SPEC_NODE_KIND_LIST: &str = "list";
pub const SPEC_NODE_KIND_LIST_ITEM_COMPLEX: &str = "listItemComplex";
pub const SPEC_NODE_KIND_LIST_ITEM_SCALAR: &str = "listItemScalar";
pub const SPEC_NODE_KIND_FORM: &str = "form";
pub const SPEC_NODE_KIND_CONTENT: &str = "content";
pub const SPEC_NODE_KIND_ENUM_VALUE: &str = "enumValue";
pub const SPEC_NODE_KIND_SCALAR: &str = "scalar";

fn is_value_leaf_kind(kind: &str) -> bool {
    matches!(
        kind,
        SPEC_NODE_KIND_CONTENT
            | SPEC_NODE_KIND_ENUM_VALUE
            | SPEC_NODE_KIND_SCALAR
            | SPEC_NODE_KIND_LIST_ITEM_SCALAR
    )
}

/// Maps a leaf field kind to its node kind.
fn leaf_kind(field_kind: &str) -> Option<&'static str> {
    match field_kind {
        SPEC_FIELD_KIND_FORM => Some(SPEC_NODE_KIND_FORM),
        SPEC_FIELD_KIND_CONTENT => Some(SPEC_NODE_KIND_CONTENT),
        SPEC_FIELD_KIND_ENUM => Some(SPEC_NODE_KIND_ENUM_VALUE),
        SPEC_FIELD_KIND_SCALAR => Some(SPEC_NODE_KIND_SCALAR),
        _ => None,
    }
}

/// The outcome of resolving a document path against a [`SpecModel`].
#[derive(Debug, Clone)]
pub struct SpecResolution {
    pub path: String,
    pub kind: String,
    pub root: Option<SpecRoot>,
    pub field: Option<SpecField>,
    pub target_class: Option<SpecClass>,
}

impl SpecResolution {
    /// Reports whether a single string value is stored directly at this path (a
    /// content, enum, scalar leaf, or a scalar list item).
    pub fn is_value_leaf(&self) -> bool {
        is_value_leaf_kind(&self.kind)
    }
}

/// Provides read-only queries over a [`SpecModel`].
pub struct SpecReflection<'a> {
    pub model: &'a SpecModel,
}

impl<'a> SpecReflection<'a> {
    /// Binds a reflection surface to a model.
    pub fn new(model: &'a SpecModel) -> SpecReflection<'a> {
        SpecReflection { model }
    }

    // --- enumeration -------------------------------------------------------

    /// Returns the document roots.
    pub fn roots(&self) -> &[SpecRoot] {
        &self.model.roots
    }

    /// Returns every class (unordered).
    pub fn classes(&self) -> Vec<&SpecClass> {
        self.model.classes.values().collect()
    }

    /// Returns the named class, or `None`.
    pub fn class_named(&self, name: &str) -> Option<&SpecClass> {
        self.model.class_named(name)
    }

    /// Returns the fields of the named class.
    pub fn fields_of(&self, class_name: &str) -> &[SpecField] {
        match self.class_named(class_name) {
            Some(c) => &c.fields,
            None => &[],
        }
    }

    /// Returns the annotations of the named class.
    pub fn annotations_of(&self, class_name: &str) -> &[SpecAnnotation] {
        match self.class_named(class_name) {
            Some(c) => &c.annotations,
            None => &[],
        }
    }

    /// Returns the annotations of a named field of a named class.
    pub fn field_annotations(&self, class_name: &str, field_name: &str) -> &[SpecAnnotation] {
        if let Some(cls) = self.class_named(class_name) {
            if let Some(f) = cls.field_named(field_name) {
                return &f.annotations;
            }
        }
        &[]
    }

    // --- resolution --------------------------------------------------------

    /// Returns the section segment of a root.
    pub fn root_segment(&self, root: &SpecRoot) -> String {
        if !root.section_id.is_empty() {
            root.section_id.clone()
        } else {
            root.type_.clone()
        }
    }

    /// Returns the section segment of a field.
    pub fn field_segment(&self, field: &SpecField) -> String {
        if !field.section_id.is_empty() {
            field.section_id.clone()
        } else {
            field.name.clone()
        }
    }

    /// Returns the root whose segment matches, or `None`.
    pub fn root_for_segment(&self, segment: &str) -> Option<&SpecRoot> {
        self.model
            .roots
            .iter()
            .find(|r| self.root_segment(r) == segment)
    }

    fn match_field<'c>(&self, cls: &'c SpecClass, segment: &str) -> Option<&'c SpecField> {
        cls.fields.iter().find(|f| self.field_segment(f) == segment)
    }

    /// Resolves a document path to the model node it addresses, or `None` when
    /// the path does not describe a reachable node.
    pub fn resolve(&self, path: &str) -> Option<SpecResolution> {
        let segs = spec_path_segments(path);
        if segs.is_empty() || segs[0].is_empty() {
            return None;
        }

        let root = self.root_for_segment(&segs[0])?.clone();
        let mut cur_class = self.class_named(&root.type_).cloned();

        if segs.len() == 1 {
            return Some(SpecResolution {
                path: path.to_string(),
                kind: SPEC_NODE_KIND_ROOT.to_string(),
                root: Some(root),
                field: None,
                target_class: cur_class,
            });
        }

        for i in 1..segs.len() {
            let cls = match &cur_class {
                Some(c) => c.clone(),
                None => return None, // cannot descend into a non-class
            };
            let seg = &segs[i];
            let last = i == segs.len() - 1;

            // Prefer an exact field-segment match; only then try a list-item
            // suffix, so a hyphenated @SectionId is never mis-read as an item.
            if let Some(field) = self.match_field(&cls, seg) {
                let field = field.clone();
                if field.kind == SPEC_FIELD_KIND_COMPLEX || field.kind == SPEC_FIELD_KIND_SECTION {
                    cur_class = self.class_named(&field.type_).cloned();
                    if last {
                        let kind = if field.kind == SPEC_FIELD_KIND_SECTION {
                            SPEC_NODE_KIND_SECTION
                        } else {
                            SPEC_NODE_KIND_COMPLEX
                        };
                        return Some(SpecResolution {
                            path: path.to_string(),
                            kind: kind.to_string(),
                            root: Some(root),
                            field: Some(field),
                            target_class: cur_class,
                        });
                    }
                    continue; // descend into the collapsed class
                }
                if field.kind == SPEC_FIELD_KIND_LIST {
                    if last {
                        return Some(SpecResolution {
                            path: path.to_string(),
                            kind: SPEC_NODE_KIND_LIST.to_string(),
                            root: Some(root),
                            field: Some(field),
                            target_class: None,
                        });
                    }
                    return None; // a list path needs a -<seq> item suffix
                }
                // form / content / enum / scalar leaves
                if last {
                    let kind = leaf_kind(&field.kind)?;
                    return Some(SpecResolution {
                        path: path.to_string(),
                        kind: kind.to_string(),
                        root: Some(root),
                        field: Some(field),
                        target_class: None,
                    });
                }
                return None; // a leaf cannot have further segments
            }

            let split = split_list_item_segment(seg)?;
            let list_field = match self.match_field(&cls, &split.base) {
                Some(f) if f.kind == SPEC_FIELD_KIND_LIST => f.clone(),
                _ => return None,
            };
            if list_field.element_is_complex {
                cur_class = self.class_named(&list_field.element_type).cloned();
                if last {
                    return Some(SpecResolution {
                        path: path.to_string(),
                        kind: SPEC_NODE_KIND_LIST_ITEM_COMPLEX.to_string(),
                        root: Some(root),
                        field: Some(list_field),
                        target_class: cur_class,
                    });
                }
                continue;
            }
            // Scalar list item: a value leaf, so it must be the final segment.
            if last {
                return Some(SpecResolution {
                    path: path.to_string(),
                    kind: SPEC_NODE_KIND_LIST_ITEM_SCALAR.to_string(),
                    root: Some(root),
                    field: Some(list_field),
                    target_class: None,
                });
            }
            return None;
        }
        None
    }
}
