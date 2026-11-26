//! `spec_document_markdown_generated` — generated parts of a rendition (SOM
//! §11.12): tables the rendition derives completely from the links of a
//! document, written at the start of the section they belong to as a
//! `derived` block and read back as nothing. A port of the Go runtime's
//! `spec_document_markdown_generated.go` (itself a port of the Python,
//! JavaScript, TypeScript and Dart runtimes'
//! `spec_document_markdown_generated`).
//!
//! Internal to [`SpecDocumentMarkdown`]: a child module, so it reads the
//! codec's private helpers.

use std::cell::OnceCell;
use std::collections::HashMap;
use std::rc::Rc;

use super::linked::MdNavigation;
use super::{md_is_transparent_value, SpecDocumentMarkdown};
use crate::spec_links_validator::spec_resolve_place_at;
use crate::spec_meta::{
    SomMetaNode, SOM_META_KIND_COMPLEX, SOM_META_KIND_LIST, SOM_META_KIND_SECTION,
};

/// Written by the emitter at a generated place without a table: replaced by
/// an empty `derived` block when the value written after it begins with a
/// `derived` block, else removed with its blank line (SOM §11.12).
pub(super) const MD_DERIVED_PLACEHOLDER: &str = "\u{0}derived\u{0}";

/// The requirement classes whose elements are the rows of the requirement
/// views: every element `INTR.relatedRequirements` may name.
const MD_REQUIREMENT_CLASSES: &[&str] = &["FRE", "TERQ", "SECRQ", "ORRQ"];

/// A column of a generated table: its header, the place its cells read
/// (`""`: the row's id), whether it says only `yes` / `no`.
struct MdGenColumn {
    header: &'static str,
    place: &'static str,
    covered: bool,
}

const fn col(header: &'static str, place: &'static str) -> MdGenColumn {
    MdGenColumn {
        header,
        place,
        covered: false,
    }
}

/// A generated table: the section ids it opens, its label, the classes of its
/// rows, the classes the row's id is taken from (empty: the row's own), its
/// columns.
struct MdGenTable {
    at: &'static [&'static str],
    label: &'static str,
    rows: &'static [&'static str],
    owner: &'static [&'static str],
    columns: &'static [MdGenColumn],
}

/// The generated tables (SOM §11.12): the requirement views of
/// DP-part-model-links-5 / -11 (D1–D4) where the links hold a table.
static MD_GENERATED_TABLES: [MdGenTable; 4] = [
    MdGenTable {
        at: &["RSP-TRAC", "RO-TRAC"],
        label: "Generated from each requirement's traceability; edit it there",
        rows: MD_REQUIREMENT_CLASSES,
        owner: &[],
        columns: &[
            col("Requirement", ""),
            col("Use cases", "RT-TRAC.relatedUseCases"),
            col("Screens", "RETRAR.relatedScreens"),
            col("Data entities", "RETRAR.relatedDataEntities"),
            col("Tests", "RETRAR.relatedTestCases"),
        ],
    },
    MdGenTable {
        at: &["REQCOV"],
        label: "Generated from each requirement's test cases; edit them there",
        rows: MD_REQUIREMENT_CLASSES,
        owner: &[],
        columns: &[
            col("Requirement", ""),
            MdGenColumn {
                header: "Covered",
                place: "RETRAR.relatedTestCases",
                covered: true,
            },
            col("By", "RETRAR.relatedTestCases"),
        ],
    },
    MdGenTable {
        at: &["RERE-REQU-LST"],
        label: "Generated from each requirement's dependencies; edit them there",
        rows: &["RQDEP"],
        owner: MD_REQUIREMENT_CLASSES,
        columns: &[
            col("Requirement", ""),
            col("Dependency", "RQDEP.dependencyType"),
            col("Related requirement", "RQDEP-RELA-REF.ref"),
        ],
    },
    MdGenTable {
        at: &["USCATR"],
        label: "Generated from each use case's traceability; edit it there",
        rows: &["INEN"],
        owner: &[],
        columns: &[
            col("Use case", ""),
            col("Process", "INTR.relatedProcess"),
            col("Requirements", "INTR.relatedRequirements"),
            col("Tests", "INTR.relatedTestCases"),
        ],
    },
];

/// The generated table opening a heading with section id `id`.
fn md_generated_table_at(id: &str) -> Option<&'static MdGenTable> {
    MD_GENERATED_TABLES.iter().find(|t| t.at.contains(&id))
}

/// Whether the heading at `path` is a generated place (structural: its
/// section id opens a generated table).
pub(super) fn md_is_generated_place(
    nav: &MdNavigation<'_>,
    c: &SpecDocumentMarkdown<'_>,
    path: &str,
) -> bool {
    let Some(node) = nav.tree.by_path(path) else {
        return false;
    };
    if nav.walk(c, path, None, &[]).heading_path != path {
        return false;
    }
    md_generated_table_at(&c.heading_id_of(&node)).is_some()
}

/// One root's generated parts.
pub(super) struct MdGenerated<'a> {
    pub(super) nav: Rc<MdNavigation<'a>>,
    block_map: OnceCell<HashMap<String, Vec<String>>>,
    items_list: OnceCell<Vec<String>>,
}

impl<'a> MdGenerated<'a> {
    pub(super) fn new(nav: Rc<MdNavigation<'a>>) -> MdGenerated<'a> {
        MdGenerated {
            nav,
            block_map: OnceCell::new(),
            items_list: OnceCell::new(),
        }
    }

    /// Whether the heading at `path` is a generated place.
    pub(super) fn is_place(&self, c: &SpecDocumentMarkdown<'_>, path: &str) -> bool {
        md_is_generated_place(&self.nav, c, path)
    }

    /// The blocks of this document, by heading path: only the places whose
    /// table has rows.
    pub(super) fn blocks(&self, c: &SpecDocumentMarkdown<'_>) -> &HashMap<String, Vec<String>> {
        self.block_map.get_or_init(|| {
            let mut out = HashMap::new();
            for n in self.nav.tree.all_nodes() {
                let path = n.path().unwrap_or_default();
                if path.is_empty() || c.is_transparent_section(n) || md_is_transparent_value(n) {
                    continue;
                }
                let Some(table) = md_generated_table_at(&c.heading_id_of(n)) else {
                    continue;
                };
                if let Some(block) = self.block(c, table) {
                    out.insert(path, block);
                }
            }
            out
        })
    }

    /// Whether a generated block stands at or beneath `path`, so the heading
    /// is written even when the document holds no value there.
    pub(super) fn forces(&self, c: &SpecDocumentMarkdown<'_>, path: &str) -> bool {
        self.blocks(c)
            .keys()
            .any(|p| p == path || p.strip_prefix(path).is_some_and(|r| r.starts_with('/')))
    }

    /// Every element of the document, in rendition order.
    fn items(&self, c: &SpecDocumentMarkdown<'_>) -> &[String] {
        self.items_list.get_or_init(|| {
            let mut out = Vec::new();
            self.collect_items(c, &self.nav.tree.root, &self.nav.root_seg(), &mut out);
            out
        })
    }

    fn collect_items(
        &self,
        c: &SpecDocumentMarkdown<'_>,
        node: &SomMetaNode,
        path: &str,
        out: &mut Vec<String>,
    ) {
        let doc = c.document;
        for child in c.effective_children(node) {
            let p = format!("{}/{}", path, child.rel);
            if !doc.has_values_under(&p) {
                continue;
            }
            match child.node.kind.as_str() {
                SOM_META_KIND_LIST => {
                    for item in doc.list_items(&p) {
                        out.push(item.clone());
                        if let Some(element) =
                            child.node.element_node.as_ref().filter(|e| !e.recursive)
                        {
                            self.collect_items(c, element, &item, out);
                        }
                    }
                }
                SOM_META_KIND_SECTION | SOM_META_KIND_COMPLEX => {
                    self.collect_items(c, &child.node, &p, out);
                }
                _ => {}
            }
        }
    }

    /// The section id of the class of the element at `item`, `""` when it
    /// does not resolve.
    fn class_id(&self, item: &str) -> String {
        self.nav
            .refl()
            .resolve(item)
            .and_then(|r| r.target_class)
            .map(|c| c.section_id)
            .unwrap_or_default()
    }

    /// The block lines of `table`, `None` when it has no row.
    fn block(&self, c: &SpecDocumentMarkdown<'_>, table: &MdGenTable) -> Option<Vec<String>> {
        let doc = c.document;
        let refl = self.nav.refl();
        let mut rows: Vec<Vec<String>> = Vec::new();
        for item in self.items(c) {
            let class_id = self.class_id(item);
            if class_id.is_empty() || !table.rows.contains(&class_id.as_str()) {
                continue;
            }
            let mut cells: Vec<String> = Vec::new();
            for col in table.columns {
                if col.place.is_empty() {
                    cells.push(self.id_cell(c, &self.row_owner(item, table)));
                    continue;
                }
                let r = spec_resolve_place_at(&refl, col.place, item);
                let fld = r
                    .as_ref()
                    .map(|r| r.field().to_string())
                    .unwrap_or_default();
                let value = match &r {
                    Some(r) if !fld.is_empty() => doc
                        .form_field(&r.path, &fld)
                        .map(|v| v.trim().to_string())
                        .unwrap_or_default(),
                    _ => String::new(),
                };
                if col.covered {
                    cells.push(if value.is_empty() { "no" } else { "yes" }.to_string());
                    continue;
                }
                if value.is_empty() {
                    cells.push(String::new());
                    continue;
                }
                let form_node = r.as_ref().and_then(|r| self.nav.tree.by_path(&r.path));
                let meta = form_node
                    .as_ref()
                    .and_then(|n| n.form.as_ref())
                    .and_then(|f| f.field_named(&fld));
                cells.push(match meta {
                    Some(meta) => c.linked_cell_text(meta, &value),
                    None => value.replace('|', "\\|"),
                });
            }
            rows.push(cells);
        }
        if rows.is_empty() {
            return None;
        }
        let headers: Vec<&str> = table.columns.iter().map(|c| c.header).collect();
        let mut out = vec![
            format!("::: {{.derived label=\"{}\"}}", table.label),
            format!("| {} |", headers.join(" | ")),
            format!("| {} |", vec!["---"; headers.len()].join(" | ")),
        ];
        for r in rows {
            out.push(format!("| {} |", r.join(" | ")));
        }
        out.push(":::".to_string());
        Some(out)
    }

    /// The element a row names: itself, or its nearest owner of the table's
    /// owner classes (`""`: none).
    fn row_owner(&self, item: &str, table: &MdGenTable) -> String {
        if table.owner.is_empty() {
            return item.to_string();
        }
        let mut p = item;
        while let Some(slash) = p.rfind('/') {
            p = &p[..slash];
            if self.nav.item_list_path(p).is_some() {
                let id = self.class_id(p);
                if !id.is_empty() && table.owner.contains(&id.as_str()) {
                    return p.to_string();
                }
            }
        }
        String::new()
    }

    /// A link to the element at `item` by its id and anchor.
    fn id_cell(&self, c: &SpecDocumentMarkdown<'_>, item: &str) -> String {
        if item.is_empty() {
            return String::new();
        }
        let w = self.nav.walk(c, item, None, &[]);
        format!("[{}](#{})", w.heading_id, w.anchor)
    }
}

/// The length of the `:::` run opening a `derived` block on `line`
/// (`^ {0,3}:{3,}[ \t]*\{\.derived[\s}]`), `None` when it opens none.
fn md_derived_fence(line: &str) -> Option<usize> {
    let indent = line.bytes().take_while(|&b| b == b' ').count();
    if indent > 3 {
        return None;
    }
    let rest = &line[indent..];
    let colons = rest.bytes().take_while(|&b| b == b':').count();
    if colons < 3 {
        return None;
    }
    let rest = rest[colons..].trim_start_matches([' ', '\t']);
    let after = rest.strip_prefix("{.derived")?;
    match after.chars().next() {
        Some(ch) if ch == '}' || ch.is_ascii_whitespace() => Some(colons),
        _ => None,
    }
}

/// Whether `line` opens a `derived` block.
pub(super) fn md_opens_derived(line: &str) -> bool {
    md_derived_fence(line).is_some()
}

/// Whether `line` closes the `derived` block `open` opens
/// (`^ {0,3}:{N,}[ \t]*$`, N the opening run's length).
pub(super) fn md_closes_derived(open: &str, line: &str) -> bool {
    let Some(n) = md_derived_fence(open) else {
        return false;
    };
    let indent = line.bytes().take_while(|&b| b == b' ').count();
    if indent > 3 {
        return false;
    }
    let rest = &line[indent..];
    let colons = rest.bytes().take_while(|&b| b == b':').count();
    colons >= n && rest[colons..].bytes().all(|b| b == b' ' || b == b'\t')
}

/// `markdown` with every derived placeholder resolved: an empty `derived`
/// block where the block after it opens a `derived` block, else removed with
/// its blank line.
pub(super) fn md_resolve_derived_placeholders(markdown: String) -> String {
    if !markdown.contains(MD_DERIVED_PLACEHOLDER) {
        return markdown;
    }
    let lines: Vec<&str> = markdown.split('\n').collect();
    let mut out: Vec<&str> = Vec::with_capacity(lines.len());
    let mut i = 0;
    while i < lines.len() {
        if lines[i] != MD_DERIVED_PLACEHOLDER {
            out.push(lines[i]);
            i += 1;
            continue;
        }
        let mut k = i + 1;
        while k < lines.len() && lines[k].trim().is_empty() {
            k += 1;
        }
        if k < lines.len() && md_opens_derived(lines[k]) {
            out.push("::: {.derived}");
            out.push(":::");
            i += 1;
        } else {
            i += 2; // the blank line after the placeholder goes with it
        }
    }
    out.join("\n")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn derived_fences_open_and_close() {
        assert!(md_opens_derived("::: {.derived}"));
        assert!(md_opens_derived("   :::: {.derived label=\"x\"}"));
        assert!(!md_opens_derived("    ::: {.derived}"));
        assert!(!md_opens_derived("::: {.derivedX}"));
        assert!(!md_opens_derived(":: {.derived}"));
        assert!(md_closes_derived(":::: {.derived}", "::::"));
        assert!(md_closes_derived("::: {.derived}", ":::::  "));
        assert!(!md_closes_derived(":::: {.derived}", ":::"));
        assert!(!md_closes_derived("::: {.derived}", "::: x"));
    }

    #[test]
    fn tables_open_at_their_section_ids() {
        assert_eq!(
            md_generated_table_at("REQCOV").map(|t| t.columns.len()),
            Some(3)
        );
        assert_eq!(
            md_generated_table_at("RO-TRAC").map(|t| t.rows.len()),
            Some(4)
        );
        assert!(md_generated_table_at("FRE").is_none());
    }

    #[test]
    fn derived_placeholders_resolve_to_the_empty_block_or_go() {
        let kept = format!(
            "# H\n\n{}\n\n::: {{.derived}}\nx\n:::\n",
            MD_DERIVED_PLACEHOLDER
        );
        assert_eq!(
            md_resolve_derived_placeholders(kept),
            "# H\n\n::: {.derived}\n:::\n\n::: {.derived}\nx\n:::\n"
        );
        let gone = format!("# H\n\n{}\n\nText.\n", MD_DERIVED_PLACEHOLDER);
        assert_eq!(md_resolve_derived_placeholders(gone), "# H\n\nText.\n");
    }
}
