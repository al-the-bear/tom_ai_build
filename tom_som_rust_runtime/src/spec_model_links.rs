//! `spec_model_links` — the typed readers of the link vocabulary
//! (`tom_specs_model_rules.md` §9.7), a port of the link readers of
//! `tom_som_dart_runtime/lib/src/spec_model.dart` (and the TypeScript,
//! JavaScript, Python, Go and Java `spec_model` modules).
//!
//! They are read from the lossless `annotations` block (member and class
//! annotations: `@SyncedWith`, `@SummaryOf`, `@DerivedFrom`, `@ExtractsLinks`,
//! `@SameAs`) or from the curated `formFields[]` keys (the `Field` qualifiers
//! `derivedFrom:`, `inverseOf:`, `summaryOf:`). They follow [`KindLink`]: an
//! enum constant is read with its type prefix stripped (`LinkRelation.subset`
//! → `subset`), a key the reader does not know is ignored, and an absent key
//! takes the annotation's default — so a meta written before a key existed
//! loads unchanged.
//!
//! An optional string argument that is absent reads as `""` (the crate's usual
//! absent-string convention); the canonical JSON forms leave it out. A string
//! → string argument (`repeats`, `map`, `set`) keeps the order the meta writes
//! it in, as the reference's maps do: it is a `Vec<(String, String)>`, never a
//! hash map. The annotation arguments are already kept in source order
//! ([`SpecAnnotation::arguments`]), so the order is read off them directly.
//!
//! [`KindLink`]: crate::spec_model::KindLink

use crate::json::Json;
use crate::spec_model::{
    annotation_named, strip_enum_prefix, SpecAnnotation, SpecClass, SpecField,
};

/// One entry of an ordered string → string argument (`SummaryOf.repeats`,
/// `DerivedFrom.map`, `ExtractsLinks.set`): key, value.
pub type SpecStringPair = (String, String);

/// The pairs as a JSON object, in their order.
fn string_pairs_json(pairs: &[SpecStringPair]) -> Json {
    Json::Object(
        pairs
            .iter()
            .map(|(k, v)| (k.clone(), Json::Str(v.clone())))
            .collect(),
    )
}

/// A string list as a JSON list.
pub(crate) fn strings_json(items: &[String]) -> Json {
    Json::Array(items.iter().map(|s| Json::Str(s.clone())).collect())
}

/// The value of `key` in the pairs (the last of a repeated key wins), or
/// `None`.
pub fn spec_string_pair_value<'p>(pairs: &'p [SpecStringPair], key: &str) -> Option<&'p str> {
    pairs
        .iter()
        .rev()
        .find(|(k, _)| k == key)
        .map(|(_, v)| v.as_str())
}

// --- reading the arguments ---------------------------------------------------

/// An argument object as the readers see it, in source order.
#[derive(Clone, Copy)]
struct LinkArguments<'j> {
    values: &'j [(String, Json)],
}

impl<'j> LinkArguments<'j> {
    fn get(&self, key: &str) -> Option<&'j Json> {
        self.values.iter().find(|(k, _)| k == key).map(|(_, v)| v)
    }

    /// A string argument with a default when absent (or `null`).
    fn str(&self, key: &str, fallback: &str) -> String {
        match self.get(key) {
            None | Some(Json::Null) => fallback.to_string(),
            Some(v) => link_json_text(v),
        }
    }

    /// An optional string argument: the string, or `""` for anything else.
    fn opt_string(&self, key: &str) -> String {
        match self.get(key) {
            Some(Json::Str(s)) => s.clone(),
            _ => String::new(),
        }
    }

    /// A JSON list read as strings, nulls dropped; anything else as empty.
    fn string_list(&self, key: &str) -> Vec<String> {
        match self.get(key) {
            Some(Json::Array(items)) => items
                .iter()
                .filter(|e| !matches!(e, Json::Null))
                .map(link_json_text)
                .collect(),
            _ => Vec::new(),
        }
    }

    /// A JSON object read as string → string, in the order the meta writes
    /// it; anything else as empty.
    fn string_pairs(&self, key: &str) -> Vec<SpecStringPair> {
        match self.get(key) {
            Some(Json::Object(pairs)) => {
                let mut out: Vec<SpecStringPair> = Vec::new();
                for (k, v) in pairs {
                    // A repeated key keeps its first position and its last
                    // value, as a decoded map would.
                    match out.iter_mut().find(|(ok, _)| ok == k) {
                        Some(entry) => entry.1 = link_json_text(v),
                        None => out.push((k.clone(), link_json_text(v))),
                    }
                }
                out
            }
            _ => Vec::new(),
        }
    }

    /// A list argument's object entries (anything else skipped).
    fn objects(&self, key: &str) -> Vec<LinkArguments<'j>> {
        match self.get(key) {
            Some(Json::Array(items)) => items
                .iter()
                .filter_map(|e| match e {
                    Json::Object(pairs) => Some(LinkArguments { values: pairs }),
                    _ => None,
                })
                .collect(),
            _ => Vec::new(),
        }
    }
}

/// A JSON value as text, the way the reference writes it (`true`, not `True`;
/// `null`; a whole number without a fraction).
fn link_json_text(v: &Json) -> String {
    match v {
        Json::Null => "null".to_string(),
        Json::Str(s) => s.clone(),
        Json::Bool(b) => b.to_string(),
        Json::Int(n) => n.to_string(),
        Json::Float(f) => {
            if f.fract() == 0.0 && *f > -1e15 && *f < 1e15 {
                (*f as i64).to_string()
            } else {
                f.to_string()
            }
        }
        Json::Array(items) => format!(
            "[{}]",
            items
                .iter()
                .map(link_json_encoded)
                .collect::<Vec<_>>()
                .join(",")
        ),
        Json::Object(_) => link_json_encoded(v),
    }
}

/// A JSON value encoded as JSON text.
fn link_json_encoded(v: &Json) -> String {
    match v {
        Json::Str(s) => crate::json::encode_str(s),
        Json::Array(items) => format!(
            "[{}]",
            items
                .iter()
                .map(link_json_encoded)
                .collect::<Vec<_>>()
                .join(",")
        ),
        Json::Object(pairs) => format!(
            "{{{}}}",
            pairs
                .iter()
                .map(|(k, v)| format!("{}:{}", crate::json::encode_str(k), link_json_encoded(v)))
                .collect::<Vec<_>>()
                .join(",")
        ),
        other => link_json_text(other),
    }
}

fn annotation_arguments(a: &SpecAnnotation) -> LinkArguments<'_> {
    LinkArguments {
        values: &a.arguments,
    }
}

/// A qualifier value read as an argument object, `None` when it is absent or
/// no object.
fn object_arguments(v: Option<&Json>) -> Option<LinkArguments<'_>> {
    match v {
        Some(Json::Object(pairs)) => Some(LinkArguments { values: pairs }),
        _ => None,
    }
}

// --- the readers -------------------------------------------------------------

/// The relation of the elements of a list on two sides of a link, as the
/// annotated side reads it (`ListRelation`, `tom_specs_model_rules.md` §9.7).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecListRelation {
    /// The list or multi-valued reference field the relation is about.
    pub place: String,
    /// `equal`, `subset` or `superset` (the `LinkRelation` constant name).
    pub relation: String,
    /// The filter selecting the elements the relation applies to, `""` for all
    /// of them (the [`SpecPlaceFilter`](crate::SpecPlaceFilter) grammar).
    pub r#where: String,
}

impl SpecListRelation {
    fn from_arguments(a: LinkArguments<'_>) -> SpecListRelation {
        SpecListRelation {
            place: a.str("place", ""),
            relation: strip_enum_prefix(&a.str("relation", "equal")),
            r#where: a.opt_string("where"),
        }
    }

    /// The canonical JSON form, `""` left out.
    pub fn to_json(&self) -> Json {
        let mut out = vec![
            ("place".to_string(), Json::Str(self.place.clone())),
            ("relation".to_string(), Json::Str(self.relation.clone())),
        ];
        if !self.r#where.is_empty() {
            out.push(("where".to_string(), Json::Str(self.r#where.clone())));
        }
        Json::Object(out)
    }
}

/// `@SyncedWith(document, {detailOnly, heldHere, relations, note})`: the
/// annotated section is kept in sync with the section of the same id in
/// `document` (`tom_specs_model_rules.md` §9.7).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecSync {
    /// The other document's root class name.
    pub document: String,
    /// The places only `document` carries.
    pub detail_only: Vec<String>,
    /// The places whose value this document holds.
    pub held_here: Vec<String>,
    /// The lists whose relation is not `equal`.
    pub relations: Vec<SpecListRelation>,
    /// The annotation's free-text note, `""` when it carries none.
    pub note: String,
}

impl SpecSync {
    /// Reads the sync out of a `@SyncedWith` annotation.
    pub fn from_annotation(annotation: &SpecAnnotation) -> SpecSync {
        let a = annotation_arguments(annotation);
        SpecSync {
            document: a.str("document", ""),
            detail_only: a.string_list("detailOnly"),
            held_here: a.string_list("heldHere"),
            relations: a
                .objects("relations")
                .into_iter()
                .map(SpecListRelation::from_arguments)
                .collect(),
            note: a.opt_string("note"),
        }
    }

    /// The canonical JSON form, `""` left out.
    pub fn to_json(&self) -> Json {
        let mut out = vec![
            ("document".to_string(), Json::Str(self.document.clone())),
            ("detailOnly".to_string(), strings_json(&self.detail_only)),
            ("heldHere".to_string(), strings_json(&self.held_here)),
            (
                "relations".to_string(),
                Json::Array(
                    self.relations
                        .iter()
                        .map(SpecListRelation::to_json)
                        .collect(),
                ),
            ),
        ];
        if !self.note.is_empty() {
            out.push(("note".to_string(), Json::Str(self.note.clone())));
        }
        Json::Object(out)
    }
}

/// `@SummaryOf` on a member, or the `summaryOf:` qualifier of a form field:
/// the annotated list or reference field summarises a detailed list
/// (`tom_specs_model_rules.md` §9.7).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecSummaryOf {
    /// The detailed list, `<LIST-ID>` (a `/` path where needed).
    pub detail: String,
    /// The root class name of the document holding `detail`; `""`: this one.
    pub document: String,
    /// The summary element's field naming its detail element; `""`: the
    /// summary element carries the detail element's own section id.
    pub r#match: String,
    /// `equal`, `subset` (the default) or `superset`.
    pub relation: String,
    /// Summary place → detail place for every value the summary repeats, in
    /// the meta's order.
    pub repeats: Vec<SpecStringPair>,
    /// The annotation's free-text note, `""` when it carries none.
    pub note: String,
}

impl SpecSummaryOf {
    fn from_link_arguments(a: LinkArguments<'_>) -> SpecSummaryOf {
        SpecSummaryOf {
            detail: a.str("detail", ""),
            document: a.opt_string("document"),
            r#match: a.opt_string("match"),
            relation: strip_enum_prefix(&a.str("relation", "subset")),
            repeats: a.string_pairs("repeats"),
            note: a.opt_string("note"),
        }
    }

    /// Reads the arguments of a `SummaryOf` (annotation or qualifier), in
    /// source order.
    pub fn from_arguments(arguments: &[(String, Json)]) -> SpecSummaryOf {
        Self::from_link_arguments(LinkArguments { values: arguments })
    }

    /// The canonical JSON form, `""` left out.
    pub fn to_json(&self) -> Json {
        let mut out = vec![("detail".to_string(), Json::Str(self.detail.clone()))];
        if !self.document.is_empty() {
            out.push(("document".to_string(), Json::Str(self.document.clone())));
        }
        if !self.r#match.is_empty() {
            out.push(("match".to_string(), Json::Str(self.r#match.clone())));
        }
        out.push(("relation".to_string(), Json::Str(self.relation.clone())));
        out.push(("repeats".to_string(), string_pairs_json(&self.repeats)));
        if !self.note.is_empty() {
            out.push(("note".to_string(), Json::Str(self.note.clone())));
        }
        Json::Object(out)
    }
}

/// `@DerivedFrom` on a member, or the `derivedFrom:` qualifier of a form
/// field: the value is derived from other places (`tom_specs_model_rules.md`
/// §9.7).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecDerivation {
    /// `copy`, `rows` or `lookup` (the `DerivationKind` constant name).
    pub kind: String,
    /// For copy, the place copied; for rows / lookup, the rows read.
    pub source: String,
    /// For rows, which rows count (the place-filter grammar); `""` for all.
    pub r#where: String,
    /// For rows / lookup, the row places collected.
    pub take: Vec<String>,
    /// For rows / lookup, the row field compared with this element's `by`;
    /// `""` for none.
    pub key: String,
    /// For rows / lookup, this element's field holding the key; `""` for none.
    pub by: String,
    /// For a list member, target element place ← row place, in the meta's
    /// order.
    pub map: Vec<SpecStringPair>,
    /// The annotation's free-text note, `""` when it carries none.
    pub note: String,
}

impl SpecDerivation {
    fn from_link_arguments(a: LinkArguments<'_>) -> SpecDerivation {
        SpecDerivation {
            kind: strip_enum_prefix(&a.str("kind", "copy")),
            source: a.str("source", ""),
            r#where: a.opt_string("where"),
            take: a.string_list("take"),
            key: a.opt_string("key"),
            by: a.opt_string("by"),
            map: a.string_pairs("map"),
            note: a.opt_string("note"),
        }
    }

    /// Reads the arguments of a `DerivedFrom` (annotation or qualifier), in
    /// source order.
    pub fn from_arguments(arguments: &[(String, Json)]) -> SpecDerivation {
        Self::from_link_arguments(LinkArguments { values: arguments })
    }

    /// The canonical JSON form, `""` left out.
    pub fn to_json(&self) -> Json {
        let mut out = vec![
            ("kind".to_string(), Json::Str(self.kind.clone())),
            ("source".to_string(), Json::Str(self.source.clone())),
        ];
        if !self.r#where.is_empty() {
            out.push(("where".to_string(), Json::Str(self.r#where.clone())));
        }
        out.push(("take".to_string(), strings_json(&self.take)));
        if !self.key.is_empty() {
            out.push(("key".to_string(), Json::Str(self.key.clone())));
        }
        if !self.by.is_empty() {
            out.push(("by".to_string(), Json::Str(self.by.clone())));
        }
        out.push(("map".to_string(), string_pairs_json(&self.map)));
        if !self.note.is_empty() {
            out.push(("note".to_string(), Json::Str(self.note.clone())));
        }
        Json::Object(out)
    }
}

/// The `inverseOf:` qualifier of a reference form field: the other ends of the
/// link (`tom_specs_model_rules.md` §9.7).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecInverseOf {
    /// The other ends, `<FORMSECTIONID>.<field>`; `["@self"]` for the
    /// symmetric form.
    pub fields: Vec<String>,
    /// Only values (or rows) matching this filter have an inverse; `""` for
    /// all.
    pub r#where: String,
}

impl SpecInverseOf {
    fn from_link_arguments(a: LinkArguments<'_>) -> SpecInverseOf {
        SpecInverseOf {
            fields: a.string_list("fields"),
            r#where: a.opt_string("where"),
        }
    }

    /// Reads the `inverseOf` key of a `formFields[]` entry, in source order.
    pub fn from_arguments(arguments: &[(String, Json)]) -> SpecInverseOf {
        Self::from_link_arguments(LinkArguments { values: arguments })
    }

    /// Whether the link is stored on both entries in the same field
    /// (`InverseOf.symmetric`).
    pub fn symmetric(&self) -> bool {
        self.fields.len() == 1 && self.fields[0] == "@self"
    }

    /// The canonical JSON form, `""` left out.
    pub fn to_json(&self) -> Json {
        let mut out = vec![("fields".to_string(), strings_json(&self.fields))];
        if !self.r#where.is_empty() {
            out.push(("where".to_string(), Json::Str(self.r#where.clone())));
        }
        Json::Object(out)
    }
}

/// `@ExtractsLinks` on a list of link rows: ids named in text get rows
/// (`tom_specs_model_rules.md` §9.7). A member may carry it more than once.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecExtractsLinks {
    /// The row's `refersTo` field receiving a found id.
    pub r#ref: String,
    /// The text places searched for ids.
    pub from: Vec<String>,
    /// The values every generated row gets, in the meta's order.
    pub set: Vec<SpecStringPair>,
    /// `generate` (the default) or `warn` (the `ExtractMode` constant name).
    pub mode: String,
    /// The annotation's free-text note, `""` when it carries none.
    pub note: String,
}

impl SpecExtractsLinks {
    /// Reads one `ExtractsLinks` annotation.
    pub fn from_annotation(annotation: &SpecAnnotation) -> SpecExtractsLinks {
        let a = annotation_arguments(annotation);
        SpecExtractsLinks {
            from: a.string_list("from"),
            r#ref: a.str("ref", ""),
            set: a.string_pairs("set"),
            mode: strip_enum_prefix(&a.str("mode", "generate")),
            note: a.opt_string("note"),
        }
    }

    /// The canonical JSON form, `""` left out.
    pub fn to_json(&self) -> Json {
        let mut out = vec![
            ("from".to_string(), strings_json(&self.from)),
            ("ref".to_string(), Json::Str(self.r#ref.clone())),
            ("set".to_string(), string_pairs_json(&self.set)),
            ("mode".to_string(), Json::Str(self.mode.clone())),
        ];
        if !self.note.is_empty() {
            out.push(("note".to_string(), Json::Str(self.note.clone())));
        }
        Json::Object(out)
    }
}

/// `@SameAs({holder, note})` on a section member: the member holds a copy of
/// the section the same document holds at another position, the holder
/// (`tom_specs_model_rules.md` §9.7). [`spec_same_as_bindings`] finds the
/// holder per document.
///
/// [`spec_same_as_bindings`]: crate::spec_place::spec_same_as_bindings
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecSameAs {
    /// The holder's section-id path, its last ids as far as needed
    /// (`ACPLN/ACRITL`); `""`: the one other position of the class.
    pub holder: String,
    /// The annotation's free-text note, `""` when it carries none.
    pub note: String,
}

impl SpecSameAs {
    /// Reads the copy out of a `@SameAs` annotation.
    pub fn from_annotation(annotation: &SpecAnnotation) -> SpecSameAs {
        let a = annotation_arguments(annotation);
        SpecSameAs {
            holder: a.opt_string("holder"),
            note: a.opt_string("note"),
        }
    }

    /// The canonical JSON form, `""` left out.
    pub fn to_json(&self) -> Json {
        let mut out = Vec::new();
        if !self.holder.is_empty() {
            out.push(("holder".to_string(), Json::Str(self.holder.clone())));
        }
        if !self.note.is_empty() {
            out.push(("note".to_string(), Json::Str(self.note.clone())));
        }
        Json::Object(out)
    }
}

// --- the form-field qualifiers ----------------------------------------------

/// The link qualifiers of one `formFields[]` entry: `derivedFrom`,
/// `inverseOf`, `summaryOf`, each `None` when absent or no object.
pub(crate) fn form_field_qualifiers(
    ff: &Json,
) -> (
    Option<SpecDerivation>,
    Option<SpecInverseOf>,
    Option<SpecSummaryOf>,
) {
    (
        object_arguments(ff.get("derivedFrom")).map(SpecDerivation::from_link_arguments),
        object_arguments(ff.get("inverseOf")).map(SpecInverseOf::from_link_arguments),
        object_arguments(ff.get("summaryOf")).map(SpecSummaryOf::from_link_arguments),
    )
}

// --- the accessors on classes and fields ------------------------------------

/// Every annotation named `name`, in source order.
pub fn annotations_named<'a>(
    annotations: &'a [SpecAnnotation],
    name: &str,
) -> Vec<&'a SpecAnnotation> {
    annotations.iter().filter(|a| a.name == name).collect()
}

fn synced_with_from(annotations: &[SpecAnnotation]) -> Option<SpecSync> {
    annotation_named(annotations, "SyncedWith").map(SpecSync::from_annotation)
}

fn summary_of_from(annotations: &[SpecAnnotation]) -> Option<SpecSummaryOf> {
    annotation_named(annotations, "SummaryOf").map(|a| SpecSummaryOf::from_arguments(&a.arguments))
}

fn derived_from_from(annotations: &[SpecAnnotation]) -> Option<SpecDerivation> {
    annotation_named(annotations, "DerivedFrom")
        .map(|a| SpecDerivation::from_arguments(&a.arguments))
}

fn extracts_links_from(annotations: &[SpecAnnotation]) -> Vec<SpecExtractsLinks> {
    annotations_named(annotations, "ExtractsLinks")
        .into_iter()
        .map(SpecExtractsLinks::from_annotation)
        .collect()
}

fn same_as_from(annotations: &[SpecAnnotation]) -> Option<SpecSameAs> {
    annotation_named(annotations, "SameAs").map(SpecSameAs::from_annotation)
}

impl SpecField {
    /// Every annotation named `name` on this field, in source order — empty
    /// when absent. Some annotations are repeatable (`@ExtractsLinks`,
    /// `@Case`); reading only the first would drop the rest.
    pub fn annotations_named(&self, name: &str) -> Vec<&SpecAnnotation> {
        annotations_named(&self.annotations, name)
    }

    /// The `@SyncedWith` sync, or `None` when this field carries none.
    pub fn synced_with(&self) -> Option<SpecSync> {
        synced_with_from(&self.annotations)
    }

    /// The `@SummaryOf` link of this member, or `None`.
    pub fn summary_of(&self) -> Option<SpecSummaryOf> {
        summary_of_from(&self.annotations)
    }

    /// The `@DerivedFrom` derivation of this member, or `None`.
    pub fn derived_from(&self) -> Option<SpecDerivation> {
        derived_from_from(&self.annotations)
    }

    /// Every `@ExtractsLinks` of this member, in source order; empty when it
    /// carries none.
    pub fn extracts_links(&self) -> Vec<SpecExtractsLinks> {
        extracts_links_from(&self.annotations)
    }

    /// The `@SameAs` copy of this member, or `None`.
    pub fn same_as(&self) -> Option<SpecSameAs> {
        same_as_from(&self.annotations)
    }
}

impl SpecClass {
    /// Every annotation named `name` on this class, in source order — empty
    /// when absent.
    pub fn annotations_named(&self, name: &str) -> Vec<&SpecAnnotation> {
        annotations_named(&self.annotations, name)
    }

    /// The `@SyncedWith` sync, or `None` when this class carries none — a
    /// `@DetailedIn` without one is "not declared yet", not "nothing shared".
    pub fn synced_with(&self) -> Option<SpecSync> {
        synced_with_from(&self.annotations)
    }

    /// The `@SummaryOf` link of this class, or `None`.
    pub fn summary_of(&self) -> Option<SpecSummaryOf> {
        summary_of_from(&self.annotations)
    }

    /// The `@DerivedFrom` derivation of this class, or `None`.
    pub fn derived_from(&self) -> Option<SpecDerivation> {
        derived_from_from(&self.annotations)
    }

    /// Every `@ExtractsLinks` of this class, in source order.
    pub fn extracts_links(&self) -> Vec<SpecExtractsLinks> {
        extracts_links_from(&self.annotations)
    }

    /// The `@SameAs` copy of this class, or `None`.
    pub fn same_as(&self) -> Option<SpecSameAs> {
        same_as_from(&self.annotations)
    }

    /// Whether this class is the CodeSpecs projection root
    /// (`@CodeSpecsProjection`).
    pub fn is_code_specs_projection(&self) -> bool {
        self.has_annotation("CodeSpecsProjection")
    }
}
