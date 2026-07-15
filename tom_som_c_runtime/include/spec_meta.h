/* spec_meta — the canonical SOM **metadata tree**: the runtime's DR1 §3.1 node
 * types, a faithful port of the Go `spec_meta.go` (which itself ports the Dart
 * reference `spec_meta.dart` / TypeScript `spec_meta.ts`).
 *
 * One SomMetaTree exists per document root. Its nodes carry *every*
 * `tom_specs_core` annotation the model source declares, plus the exact class
 * and member names, so the tree is the single language-neutral description of
 * a document's structure:
 *
 *   - SomMetaNode — one node per navigable model position (§3.1), with section
 *     id / pattern, kind, serialization order, @Min, content type,
 *     help/comment/doc texts, form metadata, traceability links
 *     (@MapsTo / @DetailedIn / @SecondLevelSectionId) and the lossless extra
 *     annotation list;
 *   - SomMetaTree — wires parent links and absolute paths (the §4 path grammar
 *     shared with spec_paths) and provides the two dynamic lookups every
 *     runtime keeps: by-id and by-path.
 *
 * The runtime only *defines* these types; the generated facades (DR8) emit the
 * populated tree, `som_build_meta_tree` (spec_meta_bridge) expands one from a
 * SpecModel, and tests build small fixture trees by hand.
 *
 * C conventions (shared with the rest of the runtime): string fields are owned
 * char* and never NULL ("" = absent); optional ints use a `has_*` flag; the
 * other ports' throwing accessors take a `char **err` out-parameter that
 * receives an owned message on failure. `kind` points at a static literal
 * (the SOM_META_KIND_* / SPEC_FIELD_KIND_* constants).
 *
 * Ownership: a detached node owns its whole subtree (strings, children,
 * element node) — free an *unattached* root with `som_meta_node_free`. Once
 * `som_meta_tree_new` succeeds the tree owns the root; free the tree with
 * `som_meta_tree_free` (which frees every node). `SomMetaExtra.args` is a
 * *borrowed* pointer (into the SpecModel source when bridged).
 */
#ifndef SPEC_META_H
#define SPEC_META_H

#include <stddef.h>

#include "som_json.h"
#include "som_util.h"

/* The structural kind of a metadata node, mirroring DR1 §3.1
 * (`list | form | section | content | enum | complex | scalar`). The values
 * are identical to the SPEC_FIELD_KIND_* constants, so the bridge maps them
 * 1:1. */
#define SOM_META_KIND_LIST "list"
#define SOM_META_KIND_FORM "form"
#define SOM_META_KIND_SECTION "section"
#define SOM_META_KIND_CONTENT "content"
#define SOM_META_KIND_ENUM_VALUE "enum"
#define SOM_META_KIND_COMPLEX "complex"
#define SOM_META_KIND_SCALAR "scalar"

typedef struct SomMetaNode SomMetaNode;
typedef struct SomMetaTree SomMetaTree;

/* SomContentTypeMeta is the @ContentType(type, description) annotation
 * captured on a node. */
typedef struct {
  char *type;        /* the declared content type ("code", "diagram") */
  char *description; /* human/AI-facing description of the expected content */
} SomContentTypeMeta;

/* SomFormFieldMeta is one field of a @Form section (DR1 §3.1
 * FormMeta.fields). */
typedef struct {
  char *name;        /* exact model field name ("approvedBy") */
  char *type_name;   /* Dart type name ("String", "int", …) */
  char *description; /* display label / description, "" when none */
  int required;      /* whether the form marks the field as required */
  char *hint;        /* authoring hint (e.g. "e.g. 1.0"), "" when absent */
  long long order;   /* declaration order within the form */
} SomFormFieldMeta;

/* SomFormMeta is the form metadata of a @Form node (DR1 §3.1 FormMeta). */
typedef struct {
  SomFormFieldMeta *fields; /* in declaration order */
  size_t fields_len;
} SomFormMeta;

/* Returns the field named `name`, or NULL when absent. */
const SomFormFieldMeta *som_form_meta_field_named(const SomFormMeta *f,
                                                  const char *name);

/* SomDocMeta is the @Document metadata carried by a document root (DR1 §3.1
 * DocMeta). */
typedef struct {
  char *name;         /* the document's display name ("Solution Blueprint") */
  char *description;  /* the document's description */
  SomStrList based_on; /* class names of the documents this one is based on */
} SomDocMeta;

/* SomSecondLevelId is one @SecondLevelSectionId(documentClass, id) entry
 * (DR1 §3.1). */
typedef struct {
  char *document_class; /* the document class the id applies within */
  char *id;             /* the section id used in that document */
} SomSecondLevelId;

/* SomMetaExtra is one annotation captured losslessly into the generic extra
 * list — annotations the tree defines no dedicated slot for (DR1 §3.1 note),
 * e.g. @Max, @MinLength, @PatternCheck, @TextRequired. */
typedef struct {
  char *annotation;   /* the annotation's class name ("Max", …), owned */
  const SomJson *args; /* resolved constructor arguments — *borrowed* object
                        * node (NULL = no arguments) */
} SomMetaExtra;

/* SomMetaNode is one node of the SOM metadata tree (DR1 §3.1 MetaNode).
 *
 * A node describes one navigable position of a document root's structure: the
 * document root itself, a field, or a list's element subtree. Class-level
 * annotations attach to the node where the class is *instantiated*;
 * field-level annotations attach to the node directly (field-level @SectionId
 * wins over the target class's).
 *
 * Nodes are immutable value carriers; SomMetaTree wires the parent links and
 * absolute paths when the tree is constructed. A node instance belongs to at
 * most one tree. */
struct SomMetaNode {
  char *class_name;  /* exact model class name (root/complex/section: the
                      * instantiated class; leaves: the declaring class) */
  char *member_name; /* exact field name in the parent class, "" on the
                      * document root and on list element subtrees */
  char *section_id;  /* effective @SectionId (field wins over class), "" none */
  char *class_section_id; /* target class's own @SectionId (DR1 §2.2 fallback):
                           * used only for a section/complex node's mapping key
                           * when its field carries no id; never enters the path
                           * segment. "" when none */
  char *section_id_pattern; /* @SectionIdPattern on a list field, "" none */
  const char *kind;  /* a SOM_META_KIND_* constant (static literal) */
  char *type_name;   /* Dart type name ("String", "GoalEntry", …) */
  int has_serialization_order; /* whether @SerializationOrder is present */
  long long serialization_order; /* @SerializationOrder(order) */
  int has_min;       /* whether @Min is present */
  long long min;     /* @Min(count) */
  int unused;        /* whether @Unused is present */
  SomContentTypeMeta *content_type; /* @ContentType, NULL when unannotated */
  char *content_help; /* @ContentHelp(guidance), "" when unannotated */
  char *comment;      /* @Comment(text), "" when unannotated */
  char *doc_comment;  /* cleaned /// doc comment (member wins over class) */
  char *class_doc_comment; /* the instantiated class's own doc comment */
  SomFormMeta *form;  /* form metadata, for SOM_META_KIND_FORM nodes */
  SomDocMeta *document; /* @Document metadata; non-NULL only on the root */
  char *maps_to;      /* @MapsTo target class name, "" when unannotated */
  char *detailed_in;  /* @DetailedIn target class name, "" when unannotated */
  SomSecondLevelId *second_level_ids; /* @SecondLevelSectionId entries */
  size_t second_level_ids_len;
  SomMetaExtra *extra; /* annotations without a dedicated slot */
  size_t extra_len;
  int recursive;      /* recursive re-entry reference (a class already on the
                       * descent stack): kind == complex, no children */
  SomMetaNode **children; /* child nodes, in @SerializationOrder order */
  size_t children_len;
  SomMetaNode *element_node; /* for list nodes, the element class subtree */

  /* --- tree wiring (set once by som_meta_tree_new) ----------------------- */
  SomMetaTree *tree;
  SomMetaNode *parent;
  char *path;   /* owned; "" for element-subtree positions */
  int has_path; /* whether this node has a static path */
};

/* Allocates a zeroed node with every string field set to an owned "" and
 * `kind` set to SOM_META_KIND_SCALAR. */
SomMetaNode *som_meta_node_new(void);

/* Frees an **unattached** node and its whole subtree (children, element node,
 * form/document/content-type metadata). Never call this on a node owned by a
 * tree — `som_meta_tree_free` releases those. */
void som_meta_node_free(SomMetaNode *n);

/* Appends `child` (ownership transferred) to `n`'s children. */
void som_meta_node_add_child(SomMetaNode *n, SomMetaNode *child);

/* Returns the tree this node belongs to. When the node is unattached returns
 * NULL and, when `err` is non-NULL, writes an owned message. */
SomMetaTree *som_meta_node_tree(const SomMetaNode *n, char **err);

/* Writes the parent node (NULL on the document root; the parent of a list's
 * element node is the list node itself) to `*out` and returns 1. When the
 * node is unattached returns 0 and writes `*err`. */
int som_meta_node_parent(const SomMetaNode *n, SomMetaNode **out, char **err);

/* Writes the node's absolute document path per the §4 path grammar (borrowed;
 * "" for nodes inside a list element subtree) to `*out` and returns 1. When
 * the node is unattached returns 0 and writes `*err`. */
int som_meta_node_path(const SomMetaNode *n, const char **out, char **err);

/* Returns the path segment this node contributes: the effective section id
 * when present, else the member name, else the class name (document root).
 * Borrowed pointer into the node. */
const char *som_meta_node_segment(const SomMetaNode *n);

/* Returns the path of the seq-th item of this list node (`<path>-<seq>`,
 * owned). Returns NULL and writes `*err` when the node is not a list, is
 * unattached, or has no static path. */
char *som_meta_node_item_path(const SomMetaNode *n, long long seq, char **err);

/* Returns the direct child whose member name equals `name`, or NULL. */
SomMetaNode *som_meta_node_child_by_member(const SomMetaNode *n,
                                           const char *name);

/* Returns the direct child whose segment equals `seg`, or NULL. */
SomMetaNode *som_meta_node_child_by_segment(const SomMetaNode *n,
                                            const char *seg);

/* Returns a short identification for error messages ("Class" or
 * "Class.member"). Owned result. */
char *som_meta_node_debug_name(const SomMetaNode *n);

/* SomMetaTree is the metadata tree of one document root: parent/path wiring
 * plus the two dynamic lookups (by-id, by-path) DR1 §4.3 requires every
 * runtime to keep. */
struct SomMetaTree {
  SomMetaNode *root; /* the document root node (carries `document`), owned */
  SomMetaNode **all_nodes; /* every node, document order; element subtrees
                            * follow their list node */
  size_t all_nodes_len;
  size_t all_nodes_cap;
};

/* Wires root's subtree: sets parent links, computes static paths, and indexes
 * section ids. On success returns the tree, which takes ownership of `root`.
 *
 * Returns NULL (writing `*err` when non-NULL) when root carries no @Document
 * metadata, and when any node is already attached to another tree (nodes
 * belong to exactly one tree). On failure ownership of `root` stays with the
 * caller and any partial wiring of this tree is undone. */
SomMetaTree *som_meta_tree_new(SomMetaNode *root, char **err);

void som_meta_tree_free(SomMetaTree *t);

/* Returns the first node whose effective section id equals `section_id`, in
 * document order.
 *
 * A *resolved list-item id* (a list's @SectionIdPattern with the "xxx"
 * placeholder replaced by digits, e.g. "GOAL-ITEM-3") resolves to that list's
 * element subtree. Returns NULL when nothing matches. */
SomMetaNode *som_meta_tree_by_id(const SomMetaTree *t, const char *section_id);

/* Returns all nodes whose effective section id equals `section_id`, in
 * document order, as a malloc'd array the caller frees with `free` (NULL when
 * none; `*len` always written). A shared class instantiated at several
 * positions yields several nodes (ids resolve within their parent chain,
 * DR1 §1.2). */
SomMetaNode **som_meta_tree_all_by_id(const SomMetaTree *t,
                                      const char *section_id, size_t *len);

/* Resolves a document path (the §4 grammar: segments joined by "/", list
 * items as "-<seq>" suffixes) to the metadata node it addresses, or NULL when
 * the path does not describe a reachable position.
 *
 * A list-item segment ("<listSegment>-<seq>") resolves to the list's element
 * subtree; segments below it match the element class's fields. A list
 * *container* path is only valid as the final segment (descending past a list
 * requires an item suffix). */
SomMetaNode *som_meta_tree_by_path(const SomMetaTree *t, const char *path);

/* Reports whether `id` matches `pattern` with every "xxx" placeholder
 * standing for one-or-more digits. */
int som_matches_section_id_pattern(const char *pattern, const char *id);

/* ---- generated accessor support (DR1 §4) -------------------------------- */

/* SomMetaRef is one position of the generated dot-notation / ID-tree access
 * surfaces (DR1 §4): an absolute document path bound to the tree it belongs
 * to. The generated facades (DR8) emit one accessor type per model class
 * whose getters return further refs; this base type is the leaf accessor
 * itself (content/scalar/enum/form positions). */
typedef struct {
  const SomMetaTree *tree; /* borrowed */
  char *path;              /* owned (§4 path grammar) */
} SomMetaRef;

void som_meta_ref_init(SomMetaRef *r, const SomMetaTree *tree,
                       const char *path);
void som_meta_ref_free(SomMetaRef *r);

/* Returns the metadata node at the ref's path.
 *
 * Returns NULL and writes `*err` when the path resolves to no node — only
 * possible past a recursive re-entry, where the generated chain has ended and
 * the metadata tree carries no further nodes (DR1 §4.1 cycle rule). */
const SomMetaNode *som_meta_ref_meta(const SomMetaRef *r, char **err);

/* SomMetaRefFactory is the factory a SomListMetaRef uses to build the
 * accessor for an item position: factory(tree, path) → the element class's
 * generated accessor (an owned pointer whose concrete type the generated code
 * knows). */
typedef void *(*SomMetaRefFactory)(const SomMetaTree *tree, const char *path);

/* SomListMetaRef is the generated accessor for a **list** position (DR1
 * §4.1): `ref.path` is the list container path; `som_list_meta_ref_item`
 * returns the accessor for the seq-th item position (`<path>-<seq>`), whose
 * children are the element class's accessors. */
typedef struct {
  SomMetaRef ref;
  SomMetaRefFactory element;
} SomListMetaRef;

/* Binds a list container position to its element accessor factory. */
void som_list_meta_ref_init(SomListMetaRef *r, const SomMetaTree *tree,
                            const char *path, SomMetaRefFactory element);
void som_list_meta_ref_free(SomListMetaRef *r);

/* Returns the accessor at the item position `<path>-<seq>` (whatever the
 * factory returned; ownership per the generated factory's contract). */
void *som_list_meta_ref_item(const SomListMetaRef *r, long long seq);

#endif /* SPEC_META_H */
