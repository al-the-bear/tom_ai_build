/* spec_meta — implementation. See spec_meta.hpp; an idiomatic-C++ port of the C
 * `spec_meta.c` (which itself ports the Go `spec_meta.go`). */
#include "spec_meta.hpp"

#include <cctype>
#include <stdexcept>

#include "spec_paths.hpp"

namespace som {

/* ---- SomFormMeta --------------------------------------------------------- */

const SomFormFieldMeta* SomFormMeta::fieldNamed(const std::string& name) const {
  for (const auto& field : fields) {
    if (field.name == name) {
      return &field;
    }
  }
  return nullptr;
}

const SomFormFieldMeta* SomFormMeta::titleField() const {
  for (const auto& field : fields) {
    if (field.role == "title") {
      return &field;
    }
  }
  return nullptr;
}

const SomFormFieldMeta* SomFormMeta::idField() const {
  for (const auto& field : fields) {
    if (field.role == "id") {
      return &field;
    }
  }
  return nullptr;
}

/* ---- SomMetaNode --------------------------------------------------------- */

void SomMetaNode::addChild(std::unique_ptr<SomMetaNode> child) {
  children.push_back(std::move(child));
}

std::string SomMetaNode::segment() const {
  if (!sectionId.empty()) {
    return sectionId;
  }
  if (!memberName.empty()) {
    return memberName;
  }
  return className;
}

std::string SomMetaNode::debugName() const {
  if (memberName.empty()) {
    return className;
  }
  return className + "." + memberName;
}

const std::string& SomMetaNode::nodePath() const {
  if (tree == nullptr) {
    throw std::logic_error("SomMetaNode(" + debugName() +
                           ") is not attached to a SomMetaTree");
  }
  return path;
}

SomMetaNode* SomMetaNode::nodeParent() const {
  if (tree == nullptr) {
    throw std::logic_error("SomMetaNode(" + debugName() +
                           ") is not attached to a SomMetaTree");
  }
  return parent;
}

std::string SomMetaNode::itemPath(long long seq) const {
  if (kind != std::string(kSomMetaKindList)) {
    throw std::logic_error("itemPath() requires a list node, " + debugName() +
                           " is " + kind);
  }
  // Reuse nodePath()'s attachment check.
  const std::string& p = nodePath();
  if (!hasPath) {
    throw std::logic_error("list " + debugName() +
                           " sits inside a list element subtree and has no "
                           "static path");
  }
  return specListItemPath(p, seq);
}

SomMetaNode* SomMetaNode::childByMember(const std::string& name) const {
  for (const auto& child : children) {
    if (child->memberName == name) {
      return child.get();
    }
  }
  return nullptr;
}

SomMetaNode* SomMetaNode::childBySegment(const std::string& seg) const {
  for (const auto& child : children) {
    if (child->segment() == seg) {
      return child.get();
    }
  }
  return nullptr;
}

/* ---- section-id pattern matching ----------------------------------------- */

/* Recursive backtracking matcher for `^p0[0-9]+p1[0-9]+…pn$` where the p_i are
 * the pattern split on "xxx" (mirroring Go's regexp construction). */
static bool patternMatchFrom(const std::string& pat, const std::string& id) {
  auto x = pat.find("xxx");
  if (x == std::string::npos) {
    return pat == id;
  }
  std::string prefix = pat.substr(0, x);
  if (id.size() < prefix.size() ||
      id.compare(0, prefix.size(), prefix) != 0) {
    return false;
  }
  std::string restPat = pat.substr(x + 3);
  std::string digits = id.substr(prefix.size());
  size_t run = 0;
  while (run < digits.size() &&
         std::isdigit(static_cast<unsigned char>(digits[run]))) {
    run++;
  }
  if (run == 0) {
    return false;
  }
  for (size_t k = 1; k <= run; k++) {
    if (patternMatchFrom(restPat, digits.substr(k))) {
      return true;
    }
  }
  return false;
}

bool matchesSectionIdPattern(const std::string& pattern, const std::string& id) {
  return patternMatchFrom(pattern, id);
}

/* ---- SomMetaTree --------------------------------------------------------- */

std::unique_ptr<SomMetaTree> SomMetaTree::create(
    std::unique_ptr<SomMetaNode> root) {
  if (!root->document.has_value()) {
    throw std::invalid_argument(
        "the tree root must carry @Document metadata (SomMetaNode.document): " +
        root->debugName());
  }
  auto tree = std::unique_ptr<SomMetaTree>(new SomMetaTree());
  SomMetaNode* rootPtr = root.get();
  tree->root_ = std::move(root);
  tree->wire(rootPtr, nullptr, rootPtr->segment(), true);
  return tree;
}

void SomMetaTree::wire(SomMetaNode* node, SomMetaNode* parent, std::string path,
                       bool hasPath) {
  node->tree = this;
  node->parent = parent;
  node->path = std::move(path);
  node->hasPath = hasPath;
  allNodes_.push_back(node);
  for (const auto& child : node->children) {
    std::string childPath =
        hasPath ? specPathJoin(node->path, child->segment()) : std::string();
    wire(child.get(), node, std::move(childPath), hasPath);
  }
  if (node->elementNode) {
    // Item positions are dynamic (`<listPath>-<seq>`), so the element subtree
    // carries no static paths.
    wire(node->elementNode.get(), node, std::string(), false);
  }
}

std::vector<SomMetaNode*> SomMetaTree::allById(
    const std::string& sectionId) const {
  std::vector<SomMetaNode*> out;
  for (SomMetaNode* node : allNodes_) {
    if (node->sectionId == sectionId) {
      out.push_back(node);
    }
  }
  return out;
}

SomMetaNode* SomMetaTree::byId(const std::string& sectionId) const {
  for (SomMetaNode* node : allNodes_) {
    if (node->sectionId == sectionId) {
      return node;
    }
  }
  for (SomMetaNode* node : allNodes_) {
    if (!node->sectionIdPattern.empty() &&
        matchesSectionIdPattern(node->sectionIdPattern, sectionId)) {
      if (node->elementNode) {
        return node->elementNode.get();
      }
      return node;
    }
  }
  return nullptr;
}

SomMetaNode* SomMetaTree::byPath(const std::string& path) const {
  std::vector<std::string> segs = specPathSegments(path);
  if (segs.empty() || segs[0] != root_->segment()) {
    return nullptr;
  }

  SomMetaNode* node = root_.get();
  for (size_t i = 1; i < segs.size(); i++) {
    const std::string& seg = segs[i];
    bool last = i == segs.size() - 1;

    // Prefer an exact segment match; only then try a list-item suffix, so a
    // hyphenated @SectionId is never mis-read as an item.
    SomMetaNode* child = node->childBySegment(seg);
    if (child != nullptr) {
      if (child->kind == std::string(kSomMetaKindList) && !last) {
        return nullptr;  // a list path needs a `-<seq>` item suffix
      }
      if (child->recursive && !last) {
        return nullptr;  // chains terminate at recursive re-entries
      }
      node = child;
      continue;
    }

    std::string base;
    long long seq = 0;
    if (!specSplitListItemSegment(seg, &base, &seq)) {
      return nullptr;
    }
    SomMetaNode* listNode = node->childBySegment(base);
    if (listNode == nullptr ||
        listNode->kind != std::string(kSomMetaKindList)) {
      return nullptr;
    }
    if (!listNode->elementNode) {
      // Scalar list without an element subtree: the item is a value leaf.
      return last ? listNode : nullptr;
    }
    node = listNode->elementNode.get();
  }
  return node;
}

/* ---- SomMetaRef / SomListMetaRef ----------------------------------------- */

const SomMetaNode* SomMetaRef::meta() const {
  const SomMetaNode* node = tree->byPath(path);
  if (node == nullptr) {
    throw std::runtime_error(
        "no metadata node at \"" + path +
        "\" \xE2\x80\x94 the position lies beyond a recursive re-entry; use the "
        "dynamic tree lookups instead");
  }
  return node;
}

void* SomListMetaRef::item(long long seq) const {
  std::string itemPath = specListItemPath(ref.path, seq);
  return element(ref.tree, itemPath);
}

}  // namespace som
