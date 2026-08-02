/* spec_meta_diff — implementation. See spec_meta_diff.hpp; an idiomatic-C++
 * port of the C `spec_meta_diff.c`. */
#include "spec_meta_diff.hpp"

#include <cstdio>
#include <string>
#include <vector>

#include "som_json.hpp"
#include "som_util.hpp"

namespace som {
namespace {

/* ---- MetaValue: the scalar values the generic diff compares ---------------
 *
 * Across every call site a compared value is one of: a string (never absent —
 * className/kind/…), absent-or-string (contentTypeField), absent-or-int
 * (optIntRepr), or a bool (unused/recursive). This tagged union covers exactly
 * those shapes. */
enum class MetaValueKind { Null, Str, Bool, Int };

struct MetaValue {
  MetaValueKind kind = MetaValueKind::Null;
  std::string str;        // Str only
  bool boolean = false;   // Bool only
  long long integer = 0;  // Int only
};

MetaValue mvNull() { return MetaValue{MetaValueKind::Null, "", false, 0}; }
MetaValue mvStr(const std::string& s) {
  return MetaValue{MetaValueKind::Str, s, false, 0};
}
MetaValue mvBool(bool b) { return MetaValue{MetaValueKind::Bool, "", b, 0}; }
MetaValue mvInt(long long n) { return MetaValue{MetaValueKind::Int, "", false, n}; }

/* optIntRepr: absent → Null, else the int value. */
MetaValue optIntRepr(bool has, long long v) { return has ? mvInt(v) : mvNull(); }

/* contentTypeField: absent content type → Null, else the type/description
 * string. */
MetaValue contentTypeField(const std::optional<SomContentTypeMeta>& ct,
                           bool wantType) {
  if (!ct.has_value()) {
    return mvNull();
  }
  return mvStr(wantType ? ct->type : ct->description);
}

/* metaValueEq for the scalar MetaValue shapes. Numbers compare by value (only
 * Int appears here); across kinds nothing is equal except the matching
 * branch. */
bool mvEq(const MetaValue& a, const MetaValue& b) {
  if (a.kind == MetaValueKind::Int || b.kind == MetaValueKind::Int) {
    return a.kind == MetaValueKind::Int && b.kind == MetaValueKind::Int &&
           a.integer == b.integer;
  }
  if (a.kind != b.kind) {
    return false;
  }
  switch (a.kind) {
    case MetaValueKind::Null:
      return true;
    case MetaValueKind::Str:
      return a.str == b.str;
    case MetaValueKind::Bool:
      return a.boolean == b.boolean;
    default:
      return false;
  }
}

/* metaValueRepr: `null` for absent, the string verbatim, `true`/`false` for a
 * bool, the decimal for an int. */
std::string mvRepr(const MetaValue& v) {
  switch (v.kind) {
    case MetaValueKind::Null:
      return "null";
    case MetaValueKind::Str:
      return v.str;
    case MetaValueKind::Bool:
      return v.boolean ? "true" : "false";
    case MetaValueKind::Int:
      return formatI64(v.integer);
  }
  return "";
}

/* ---- compact JSON rendering (mirrors the sibling ports' marshalling) ------ */

void jsonWrite(std::string& out, const JsonRef& v) {
  if (!v) {
    out += "null";
    return;
  }
  switch (v->type) {
    case JsonType::Null:
      out += "null";
      break;
    case JsonType::Bool:
      out += v->boolean ? "true" : "false";
      break;
    case JsonType::Int:
      out += formatI64(v->integer);
      break;
    case JsonType::Float: {
      /* Integral floats render without a decimal point. */
      double r = v->real;
      long long asInt = static_cast<long long>(r);
      if (static_cast<double>(asInt) == r) {
        out += formatI64(asInt);
      } else {
        char tmp[64];
        int n = std::snprintf(tmp, sizeof(tmp), "%g", r);
        if (n > 0) {
          out.append(tmp, static_cast<std::size_t>(n));
        }
      }
      break;
    }
    case JsonType::Str:
      out += jsonEncodeStr(v->str);
      break;
    case JsonType::Array: {
      out += '[';
      for (std::size_t i = 0; i < v->array.size(); i++) {
        if (i > 0) {
          out += ',';
        }
        jsonWrite(out, std::const_pointer_cast<const Json>(v->array[i]));
      }
      out += ']';
      break;
    }
    case JsonType::Object: {
      out += '{';
      for (std::size_t i = 0; i < v->object.size(); i++) {
        if (i > 0) {
          out += ',';
        }
        out += jsonEncodeStr(v->object[i].first);
        out += ':';
        jsonWrite(out, std::const_pointer_cast<const Json>(v->object[i].second));
      }
      out += '}';
      break;
    }
  }
}

/* jsonRepr for an args object (null renders as the empty object `{}`). */
std::string jsonReprArgs(const JsonRef& v) {
  std::string out;
  if (!v) {
    out = "{}";
  } else {
    jsonWrite(out, v);
  }
  return out;
}

/* jsonRepr for a string list ([]string): `["a","b"]`. */
std::string jsonReprStrList(const std::vector<std::string>& l) {
  std::string out;
  out += '[';
  for (std::size_t i = 0; i < l.size(); i++) {
    if (i > 0) {
      out += ',';
    }
    out += jsonEncodeStr(l[i]);
  }
  out += ']';
  return out;
}

/* jsonRepr for a temporary list of names (memberNames / annotationNames). */
std::string jsonReprNames(const std::vector<std::string>& names) {
  return jsonReprStrList(names);
}

/* ---- deep JSON equality for annotation args ------------------------------ */

/* asFloat: yields the numeric value of an Int/Float node. */
bool jsonAsFloat(const JsonRef& v, double* out) {
  if (!v) {
    return false;
  }
  if (v->type == JsonType::Int) {
    *out = static_cast<double>(v->integer);
    return true;
  }
  if (v->type == JsonType::Float) {
    *out = v->real;
    return true;
  }
  return false;
}

/* Reports whether a (possibly null) node is an empty object / null. */
bool jsonIsEmptyObject(const JsonRef& v) {
  if (!v) {
    return true;
  }
  return v->type == JsonType::Object && v->object.empty();
}

/* metaValueEq over JSON-shaped values: numbers by value across int/float,
 * arrays element-wise, objects key-wise (order-independent), scalars by value.
 * null is treated as an empty object, so a null args node equals an empty `{}`
 * node. */
bool jsonValueEq(const JsonRef& a, const JsonRef& b) {
  double an, bn;
  if (jsonAsFloat(a, &an)) {
    return jsonAsFloat(b, &bn) && an == bn;
  }
  /* nil map == empty map. */
  if (!a || !b) {
    return jsonIsEmptyObject(a) && jsonIsEmptyObject(b);
  }
  if (a->type == JsonType::Array) {
    if (b->type != JsonType::Array || a->array.size() != b->array.size()) {
      return false;
    }
    for (std::size_t i = 0; i < a->array.size(); i++) {
      if (!jsonValueEq(std::const_pointer_cast<const Json>(a->array[i]),
                       std::const_pointer_cast<const Json>(b->array[i]))) {
        return false;
      }
    }
    return true;
  }
  if (a->type == JsonType::Object) {
    if (b->type != JsonType::Object || a->object.size() != b->object.size()) {
      return false;
    }
    for (std::size_t i = 0; i < a->object.size(); i++) {
      const std::string& key = a->object[i].first;
      bool has = false;
      JsonRef bv;
      for (std::size_t j = 0; j < b->object.size(); j++) {
        if (b->object[j].first == key) {
          has = true;
          bv = std::const_pointer_cast<const Json>(b->object[j].second);
          break;
        }
      }
      if (!has ||
          !jsonValueEq(std::const_pointer_cast<const Json>(a->object[i].second),
                       bv)) {
        return false;
      }
    }
    return true;
  }
  /* remaining scalars: null / bool / string */
  if (a->type != b->type) {
    return false;
  }
  switch (a->type) {
    case JsonType::Null:
      return true;
    case JsonType::Bool:
      return a->boolean == b->boolean;
    case JsonType::Str:
      return a->str == b->str;
    default:
      return false;
  }
}

/* ---- message builders ---------------------------------------------------- */

/* The em-dash separator used in every difference message. */
const char* kDash = "\xE2\x80\x94";

/* diff(field, va, vb): "" when equal, else `at: field differs — repr != repr`. */
std::string diffField(const std::string& at, const std::string& field,
                      const MetaValue& va, const MetaValue& vb) {
  if (mvEq(va, vb)) {
    return "";
  }
  return at + ": " + field + " differs " + kDash + " " + mvRepr(va) + " != " +
         mvRepr(vb);
}

/* ---- sub-diffs ----------------------------------------------------------- */

std::string metaFormDiff(const std::string& at,
                         const std::optional<SomFormMeta>& a,
                         const std::optional<SomFormMeta>& b) {
  bool aSet = a.has_value();
  bool bSet = b.has_value();
  if (aSet != bSet) {
    return at + ": form presence differs " + kDash + " " +
           (aSet ? "true" : "false") + " != " + (bSet ? "true" : "false");
  }
  if (!aSet) {
    return "";
  }
  if (a->fields.size() != b->fields.size()) {
    return at + ": form field count differs " + kDash + " " +
           formatI64(static_cast<long long>(a->fields.size())) + " != " +
           formatI64(static_cast<long long>(b->fields.size()));
  }
  for (std::size_t i = 0; i < a->fields.size(); i++) {
    const SomFormFieldMeta& fa = a->fields[i];
    const SomFormFieldMeta& fb = b->fields[i];
    if (fa.name != fb.name || fa.typeName != fb.typeName ||
        fa.description != fb.description || fa.required != fb.required ||
        fa.hint != fb.hint || fa.order != fb.order ||
        fa.enumValues != fb.enumValues || fa.refersTo != fb.refersTo) {
      return at + ": form field " + fa.name + " differs";
    }
  }
  return "";
}

std::string metaDocumentDiff(const std::string& at,
                             const std::optional<SomDocMeta>& a,
                             const std::optional<SomDocMeta>& b) {
  bool aSet = a.has_value();
  bool bSet = b.has_value();
  if (aSet != bSet) {
    return at + ": document presence differs " + kDash + " " +
           (aSet ? "true" : "false") + " != " + (bSet ? "true" : "false");
  }
  if (!aSet) {
    return "";
  }
  if (a->name != b->name) {
    return at + ": document.name differs " + kDash + " " + a->name + " != " +
           b->name;
  }
  if (a->description != b->description) {
    return at + ": document.description differs";
  }
  if (a->basedOn != b->basedOn) {
    return at + ": document.basedOn differs " + kDash + " " +
           jsonReprStrList(a->basedOn) + " != " + jsonReprStrList(b->basedOn);
  }
  return "";
}

std::string metaExtraDiff(const std::string& at,
                          const std::vector<SomMetaExtra>& a,
                          const std::vector<SomMetaExtra>& b) {
  if (a.size() != b.size()) {
    std::vector<std::string> an, bn;
    an.reserve(a.size());
    bn.reserve(b.size());
    for (const auto& e : a) an.push_back(e.annotation);
    for (const auto& e : b) bn.push_back(e.annotation);
    return at + ": extra annotation count differs " + kDash + " " +
           formatI64(static_cast<long long>(a.size())) + " != " +
           formatI64(static_cast<long long>(b.size())) + " (" +
           jsonReprNames(an) + " vs " + jsonReprNames(bn) + ")";
  }
  for (std::size_t i = 0; i < a.size(); i++) {
    if (a[i].annotation != b[i].annotation ||
        !jsonValueEq(a[i].args, b[i].args)) {
      return at + ": extra annotation " + a[i].annotation + " differs " + kDash +
             " " + jsonReprArgs(a[i].args) + " != " + jsonReprArgs(b[i].args);
    }
  }
  return "";
}

/* ---- core recursion ------------------------------------------------------ */

std::string diffAt(const SomMetaNode& a, const SomMetaNode& b,
                   const std::string& at);

/* Runs one field check; a non-empty result short-circuits the caller. */
#define CHECK(expr)                     \
  do {                                  \
    std::string d_ = (expr);            \
    if (!d_.empty()) return d_;         \
  } while (0)

std::string diffAt(const SomMetaNode& a, const SomMetaNode& b,
                   const std::string& at) {
  CHECK(diffField(at, "className", mvStr(a.className), mvStr(b.className)));
  CHECK(diffField(at, "memberName", mvStr(a.memberName), mvStr(b.memberName)));
  CHECK(diffField(at, "sectionId", mvStr(a.sectionId), mvStr(b.sectionId)));
  CHECK(diffField(at, "sectionIdPattern", mvStr(a.sectionIdPattern),
                  mvStr(b.sectionIdPattern)));
  CHECK(diffField(at, "kind", mvStr(a.kind), mvStr(b.kind)));
  CHECK(diffField(at, "typeName", mvStr(a.typeName), mvStr(b.typeName)));
  CHECK(diffField(at, "serializationOrder",
                  optIntRepr(a.hasSerializationOrder, a.serializationOrder),
                  optIntRepr(b.hasSerializationOrder, b.serializationOrder)));
  CHECK(diffField(at, "min", optIntRepr(a.hasMin, a.min),
                  optIntRepr(b.hasMin, b.min)));
  CHECK(diffField(at, "unused", mvBool(a.unused), mvBool(b.unused)));
  CHECK(diffField(at, "contentType.type", contentTypeField(a.contentType, true),
                  contentTypeField(b.contentType, true)));
  CHECK(diffField(at, "contentType.description",
                  contentTypeField(a.contentType, false),
                  contentTypeField(b.contentType, false)));
  CHECK(diffField(at, "contentHelp", mvStr(a.contentHelp),
                  mvStr(b.contentHelp)));
  CHECK(diffField(at, "headline", mvStr(a.headline), mvStr(b.headline)));
  CHECK(diffField(at, "comment", mvStr(a.comment), mvStr(b.comment)));
  CHECK(diffField(at, "docComment", mvStr(a.docComment), mvStr(b.docComment)));
  CHECK(diffField(at, "classDocComment", mvStr(a.classDocComment),
                  mvStr(b.classDocComment)));
  CHECK(diffField(at, "mapsTo", mvStr(a.mapsTo), mvStr(b.mapsTo)));
  CHECK(diffField(at, "detailedIn", mvStr(a.detailedIn),
                  mvStr(b.detailedIn)));
  CHECK(diffField(at, "recursive", mvBool(a.recursive), mvBool(b.recursive)));
  CHECK(metaFormDiff(at, a.form, b.form));
  CHECK(metaDocumentDiff(at, a.document, b.document));
  CHECK(metaExtraDiff(at, a.extra, b.extra));

  if (a.children.size() != b.children.size()) {
    std::vector<std::string> an, bn;
    an.reserve(a.children.size());
    bn.reserve(b.children.size());
    for (const auto& c : a.children) an.push_back(c->memberName);
    for (const auto& c : b.children) bn.push_back(c->memberName);
    return at + ": children count differs " + kDash + " " +
           formatI64(static_cast<long long>(a.children.size())) + " != " +
           formatI64(static_cast<long long>(b.children.size())) + " (" +
           jsonReprNames(an) + " vs " + jsonReprNames(bn) + ")";
  }
  for (std::size_t i = 0; i < a.children.size(); i++) {
    const SomMetaNode& ca = *a.children[i];
    std::string name = ca.memberName;
    if (name.empty()) {
      name = ca.className;
    }
    std::string childAt = at + "/" + name;
    std::string d = diffAt(ca, *b.children[i], childAt);
    if (!d.empty()) {
      return d;
    }
  }

  bool aElem = a.elementNode != nullptr;
  bool bElem = b.elementNode != nullptr;
  if (aElem != bElem) {
    return at + ": elementNode presence differs " + kDash + " " +
           (aElem ? "true" : "false") + " != " + (bElem ? "true" : "false");
  }
  if (aElem) {
    std::string childAt = at + "/" + "\xC2\xA7" "element";
    return diffAt(*a.elementNode, *b.elementNode, childAt);
  }
  return "";
}

#undef CHECK

}  // namespace

std::string somMetaNodeDiff(const SomMetaNode& a, const SomMetaNode& b) {
  return diffAt(a, b, "<root>");
}

}  // namespace som
