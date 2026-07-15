/* spec_meta — the canonical SOM **metadata tree** (DR1 §3.1), an idiomatic-C++
 * port of the C `spec_meta` module (which itself ports the Go / Dart / TS
 * references).
 *
 * One SomMetaTree exists per document root. Its nodes carry *every*
 * `tom_specs_core` annotation the model source declares, plus the exact class
 * and member names, so the tree is the single language-neutral description of a
 * document's structure:
 *
 *   - SomMetaNode — one node per navigable model position (§3.1), with section
 *     id / pattern, kind, serialization order, @Min, content type,
 *     help/comment/doc texts, form metadata, traceability links
 *     (@MapsTo / @DetailedIn / @SecondLevelSectionId) and the lossless extra
 *     annotation list;
 *   - SomMetaTree — wires parent links and absolute paths (the §4 path grammar
 *     shared with spec_paths) and provides the two dynamic lookups every runtime
 *     keeps: by-id and by-path.
 *
 * C++ conventions (shared with the rest of the runtime): string fields are
 * std::string ("" = absent); optional ints use a `has*` flag; children are owned
 * by their parent (std::unique_ptr), the element subtree by the list node. The C
 * port's err-out accessors become throwing accessors (std::logic_error for an
 * unattached node). `SomMetaExtra.args` retains a shared reference into the model
 * source (JsonRef), so it stays valid for the node's lifetime.
 */
#ifndef SPEC_META_HPP
#define SPEC_META_HPP

#include <functional>
#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "som_json.hpp"

namespace som {

/* The structural kind of a metadata node, mirroring DR1 §3.1
 * (`list | form | section | content | enum | complex | scalar`). The values are
 * identical to the kSpecFieldKind* constants, so the bridge maps them 1:1. */
inline constexpr const char* kSomMetaKindList = "list";
inline constexpr const char* kSomMetaKindForm = "form";
inline constexpr const char* kSomMetaKindSection = "section";
inline constexpr const char* kSomMetaKindContent = "content";
inline constexpr const char* kSomMetaKindEnumValue = "enum";
inline constexpr const char* kSomMetaKindComplex = "complex";
inline constexpr const char* kSomMetaKindScalar = "scalar";

class SomMetaTree;

/* @ContentType(type, description) captured on a node. */
struct SomContentTypeMeta {
  std::string type;         // the declared content type ("code", "diagram")
  std::string description;  // description of the expected content
};

/* One field of a @Form section (DR1 §3.1 FormMeta.fields). */
struct SomFormFieldMeta {
  std::string name;         // exact model field name ("approvedBy")
  std::string typeName;     // Dart type name ("String", "int", …)
  std::string description;  // display label / description, "" when none
  bool required = false;    // whether the form marks the field as required
  std::string hint;         // authoring hint (e.g. "e.g. 1.0"), "" when absent
  long long order = 0;      // declaration order within the form
};

/* The form metadata of a @Form node (DR1 §3.1 FormMeta). */
struct SomFormMeta {
  std::vector<SomFormFieldMeta> fields;  // in declaration order

  /* Returns the field named `name`, or nullptr when absent. */
  const SomFormFieldMeta* fieldNamed(const std::string& name) const;
};

/* @Document metadata carried by a document root (DR1 §3.1 DocMeta). */
struct SomDocMeta {
  std::string name;                  // display name ("Solution Blueprint")
  std::string description;           // the document's description
  std::vector<std::string> basedOn;  // class names this document is based on
};

/* One @SecondLevelSectionId(documentClass, id) entry (DR1 §3.1). */
struct SomSecondLevelId {
  std::string documentClass;  // the document class the id applies within
  std::string id;             // the section id used in that document
};

/* One annotation captured losslessly into the generic extra list — annotations
 * the tree defines no dedicated slot for (e.g. @Max, @MinLength). `args` retains
 * the resolved constructor arguments (null = no arguments). */
struct SomMetaExtra {
  std::string annotation;  // the annotation's class name ("Max", …)
  JsonRef args;            // resolved constructor arguments (object node or null)
};

/* One node of the SOM metadata tree (DR1 §3.1 MetaNode).
 *
 * A node describes one navigable position of a document root's structure: the
 * root itself, a field, or a list's element subtree. Class-level annotations
 * attach to the node where the class is instantiated; field-level annotations
 * attach to the node directly (field-level @SectionId wins over the target
 * class's). SomMetaTree wires the parent links and absolute paths on
 * construction; a node instance belongs to at most one tree. */
class SomMetaNode {
 public:
  std::string className;   // exact model class name
  std::string memberName;  // exact field name; "" on root and element subtrees
  std::string sectionId;   // effective @SectionId (field wins over class), "" none
  std::string classSectionId;  // the instantiated class's own @SectionId, "" none
  std::string sectionIdPattern;  // @SectionIdPattern on a list field, "" none
  const char* kind = kSomMetaKindScalar;  // a kSomMetaKind* constant
  std::string typeName;    // Dart type name ("String", "GoalEntry", …)
  bool hasSerializationOrder = false;
  long long serializationOrder = 0;
  bool hasMin = false;
  long long min = 0;
  bool unused = false;                       // whether @Unused is present
  std::optional<SomContentTypeMeta> contentType;  // @ContentType
  std::string contentHelp;                   // @ContentHelp(guidance), "" none
  std::string comment;                       // @Comment(text), "" none
  std::string docComment;                    // cleaned /// (member wins over class)
  std::string classDocComment;               // the instantiated class's own doc
  std::optional<SomFormMeta> form;           // for kSomMetaKindForm nodes
  std::optional<SomDocMeta> document;        // @Document; set only on the root
  std::string mapsTo;                        // @MapsTo target class, "" none
  std::string detailedIn;                    // @DetailedIn target class, "" none
  std::vector<SomSecondLevelId> secondLevelIds;
  std::vector<SomMetaExtra> extra;           // annotations without a slot
  bool recursive = false;                    // recursive re-entry (complex, no children)
  std::vector<std::unique_ptr<SomMetaNode>> children;  // in @SerializationOrder
  std::unique_ptr<SomMetaNode> elementNode;  // for list nodes, the element subtree

  // --- tree wiring (set once by SomMetaTree::create) ---------------------
  SomMetaTree* tree = nullptr;
  SomMetaNode* parent = nullptr;
  std::string path;        // "" for element-subtree positions
  bool hasPath = false;    // whether this node has a static path

  /* Appends `child` (ownership transferred) to this node's children. */
  void addChild(std::unique_ptr<SomMetaNode> child);

  /* The path segment this node contributes: the effective section id when
   * present, else the member name, else the class name (document root). */
  std::string segment() const;

  /* A short identification for error messages ("Class" or "Class.member"). */
  std::string debugName() const;

  /* The node's absolute document path (§4 path grammar; "" inside a list element
   * subtree). Throws std::logic_error when the node is unattached. */
  const std::string& nodePath() const;

  /* The parent node (nullptr on the root; a list's element node's parent is the
   * list node). Throws std::logic_error when the node is unattached. */
  SomMetaNode* nodeParent() const;

  /* The path of the seq-th item of this list node (`<path>-<seq>`). Throws
   * std::logic_error when the node is not a list, is unattached, or has no static
   * path. */
  std::string itemPath(long long seq) const;

  /* The direct child whose member name equals `name`, or nullptr. */
  SomMetaNode* childByMember(const std::string& name) const;

  /* The direct child whose segment equals `seg`, or nullptr. */
  SomMetaNode* childBySegment(const std::string& seg) const;
};

/* The metadata tree of one document root: parent/path wiring plus the two
 * dynamic lookups (by-id, by-path) DR1 §4.3 requires. */
class SomMetaTree {
 public:
  /* Wires `root`'s subtree: sets parent links, computes static paths, and
   * indexes every node in document order (element subtrees follow their list
   * node). Takes ownership of `root`. Throws std::invalid_argument when `root`
   * carries no @Document metadata. */
  static std::unique_ptr<SomMetaTree> create(std::unique_ptr<SomMetaNode> root);

  SomMetaNode* root() const { return root_.get(); }
  const std::vector<SomMetaNode*>& allNodes() const { return allNodes_; }

  /* The first node whose effective section id equals `sectionId`, in document
   * order. A resolved list-item id (a list's @SectionIdPattern with the "xxx"
   * placeholder replaced by digits) resolves to that list's element subtree.
   * Returns nullptr when nothing matches. */
  SomMetaNode* byId(const std::string& sectionId) const;

  /* All nodes whose effective section id equals `sectionId`, in document order.
   * A shared class instantiated at several positions yields several nodes. */
  std::vector<SomMetaNode*> allById(const std::string& sectionId) const;

  /* Resolves a document path (§4 grammar: segments joined by "/", list items as
   * "-<seq>" suffixes) to the node it addresses, or nullptr. A list-item segment
   * resolves to the list's element subtree; a list container path is only valid
   * as the final segment. */
  SomMetaNode* byPath(const std::string& path) const;

 private:
  std::unique_ptr<SomMetaNode> root_;
  std::vector<SomMetaNode*> allNodes_;  // non-owning; root_ owns the subtree

  void wire(SomMetaNode* node, SomMetaNode* parent, std::string path,
            bool hasPath);
};

/* Reports whether `id` matches `pattern` with every "xxx" placeholder standing
 * for one-or-more digits. */
bool matchesSectionIdPattern(const std::string& pattern, const std::string& id);

/* ---- generated accessor support (DR1 §4) -------------------------------- */

/* One position of the generated dot-notation / ID-tree access surfaces (DR1
 * §4): an absolute document path bound to the tree it belongs to. */
class SomMetaRef {
 public:
  const SomMetaTree* tree = nullptr;  // borrowed
  std::string path;                   // §4 path grammar

  SomMetaRef() = default;
  SomMetaRef(const SomMetaTree* t, std::string p)
      : tree(t), path(std::move(p)) {}

  /* The metadata node at the ref's path. Throws std::runtime_error when the path
   * resolves to no node — only possible past a recursive re-entry (DR1 §4.1
   * cycle rule). */
  const SomMetaNode* meta() const;
};

/* Factory a SomListMetaRef uses to build the accessor for an item position:
 * factory(tree, path) → the element class's generated accessor. */
using SomMetaRefFactory =
    std::function<void*(const SomMetaTree*, const std::string&)>;

/* The generated accessor for a **list** position (DR1 §4.1): `ref.path` is the
 * list container path; `item(seq)` returns the accessor for the seq-th item
 * position (`<path>-<seq>`). */
class SomListMetaRef {
 public:
  SomMetaRef ref;
  SomMetaRefFactory element;

  SomListMetaRef() = default;
  SomListMetaRef(const SomMetaTree* tree, std::string path,
                 SomMetaRefFactory element)
      : ref(tree, std::move(path)), element(std::move(element)) {}

  /* The accessor at the item position `<path>-<seq>` (whatever the factory
   * returned). */
  void* item(long long seq) const;
};

}  // namespace som

#endif  // SPEC_META_HPP
