#include "spec_model.hpp"

#include <cstdio>

namespace som {

std::string specParseFieldKind(const std::string& raw) {
  static const char* known[] = {
      kSpecFieldKindList,    kSpecFieldKindForm,   kSpecFieldKindSection,
      kSpecFieldKindContent, kSpecFieldKindEnum,   kSpecFieldKindComplex,
      kSpecFieldKindScalar};
  for (const char* k : known) {
    if (raw == k) {
      return k;
    }
  }
  return kSpecFieldKindScalar;
}

JsonRef SpecAnnotation::argument(const std::string& key) const {
  return jsonGet(arguments, key);
}

std::string specStripEnumPrefix(const std::string& raw) {
  std::size_t dot = raw.rfind('.');
  return dot == std::string::npos ? raw : raw.substr(dot + 1);
}

const SpecAnnotation* specAnnotationNamed(
    const std::vector<SpecAnnotation>& annotations, const std::string& name) {
  for (const SpecAnnotation& a : annotations) {
    if (a.name == name) {
      return &a;
    }
  }
  return nullptr;
}

bool specHasAnnotation(const std::vector<SpecAnnotation>& annotations,
                       const std::string& name) {
  return specAnnotationNamed(annotations, name) != nullptr;
}

namespace {

/* The annotation's `note` argument, unset when absent — so "carries no note"
 * stays distinguishable from "carries an empty one". */
std::optional<std::string> annotationNote(const SpecAnnotation& a) {
  const std::string* s = jsonAsStr(a.argument("note"));
  return s != nullptr ? std::optional<std::string>(*s) : std::nullopt;
}

/* Reads a KindLink out of `a`, taking the code list from the argument named
 * `listArgument` — `kinds` for `@CodeSpecKind`, `processes` for
 * `@FollowUpKind`. A non-string element contributes nothing, the same way
 * strListFromJson treats the model's other string arrays. */
KindLink kindLinkFromAnnotation(const SpecAnnotation& a,
                                const char* listArgument) {
  KindLink out;
  JsonRef raw = a.argument(listArgument);
  std::size_t n = jsonArrayLen(raw);
  for (std::size_t i = 0; i < n; i++) {
    const std::string* k = jsonAsStr(jsonArrayAt(raw, i));
    if (k != nullptr) {
      out.kinds.push_back(specStripEnumPrefix(*k));
    }
  }
  out.note = annotationNote(a);
  return out;
}

}  // namespace

std::optional<KindLink> specCodeSpecKind(
    const std::vector<SpecAnnotation>& annotations) {
  const SpecAnnotation* a = specAnnotationNamed(annotations, "CodeSpecKind");
  if (a == nullptr) {
    return std::nullopt;
  }
  return kindLinkFromAnnotation(*a, "kinds");
}

std::optional<KindLink> specFollowUpKind(
    const std::vector<SpecAnnotation>& annotations) {
  const SpecAnnotation* a = specAnnotationNamed(annotations, "FollowUpKind");
  if (a == nullptr) {
    return std::nullopt;
  }
  return kindLinkFromAnnotation(*a, "processes");
}

std::optional<NoArtifactLink> specNoArtifact(
    const std::vector<SpecAnnotation>& annotations) {
  const SpecAnnotation* a = specAnnotationNamed(annotations, "NoArtifact");
  if (a == nullptr) {
    return std::nullopt;
  }
  NoArtifactLink out;
  const std::string* reason = jsonAsStr(a->argument("reason"));
  out.reason = specStripEnumPrefix(reason != nullptr ? *reason : "container");
  out.note = annotationNote(*a);
  return out;
}

namespace {

bool versionIsSpace(char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' ||
         c == '\v';
}

// Trims ASCII whitespace from both ends of [begin, end) within `s`.
std::string versionTrim(const std::string& s) {
  std::size_t b = 0;
  std::size_t e = s.size();
  while (b < e && versionIsSpace(s[b])) {
    ++b;
  }
  while (e > b && versionIsSpace(s[e - 1])) {
    --e;
  }
  return s.substr(b, e - b);
}

// Reports whether `s` is a (optionally signed) run of decimal digits.
bool versionIsSignedDigits(const std::string& s) {
  if (s.empty()) {
    return false;
  }
  std::size_t i = 0;
  if (s[0] == '+' || s[0] == '-') {
    i = 1;
  }
  if (i >= s.size()) {
    return false;
  }
  for (; i < s.size(); ++i) {
    if (s[i] < '0' || s[i] > '9') {
      return false;
    }
  }
  return true;
}

}  // namespace

std::string somModelVersionString(long long major, const std::string& label) {
  if (!label.empty()) {
    // core = the `+`-stripped, trimmed prefix of the label.
    std::string core = label;
    std::size_t plus = core.find('+');
    if (plus != std::string::npos) {
      core = core.substr(0, plus);
    }
    core = versionTrim(core);
    // At least two dot-separated components → major.minor.
    std::size_t dot = core.find('.');
    if (dot != std::string::npos) {
      std::string maj = versionTrim(core.substr(0, dot));
      std::string minor = core.substr(dot + 1);
      std::size_t dot2 = minor.find('.');
      if (dot2 != std::string::npos) {
        minor = minor.substr(0, dot2);
      }
      minor = versionTrim(minor);
      if (versionIsSignedDigits(maj) && versionIsSignedDigits(minor)) {
        long long majV = std::stoll(maj);
        long long minorV = std::stoll(minor);
        return std::to_string(majV) + "." + std::to_string(minorV);
      }
    }
  }
  return std::to_string(major) + ".0";
}

bool SpecField::isExpandable() const {
  return kind == kSpecFieldKindList || kind == kSpecFieldKindComplex;
}

const SpecField* SpecClass::fieldNamed(const std::string& name) const {
  for (const auto& f : fields) {
    if (f.name == name) {
      return &f;
    }
  }
  return nullptr;
}

const SpecClass* SpecModel::classNamed(const std::string& name) const {
  if (name.empty()) {
    return nullptr;
  }
  auto it = classesByName_.find(name);
  return it != classesByName_.end() ? &it->second : nullptr;
}

const SpecRoot& SpecModel::rootByType(const std::string& type) const {
  for (const auto& r : roots) {
    if (r.type == type) {
      return r;
    }
  }
  std::string have;
  for (const auto& r : roots) {
    if (!have.empty()) {
      have += ", ";
    }
    have += r.type;
  }
  throw std::invalid_argument("no document root with type '" + type +
                              "' (have: " + have + ")");
}

/* ---- decoding ----------------------------------------------------------- */

static std::vector<SpecAnnotation> annotationsFromJson(const JsonRef& v) {
  std::vector<SpecAnnotation> out;
  std::size_t n = jsonArrayLen(v);
  for (std::size_t i = 0; i < n; i++) {
    JsonRef a = jsonArrayAt(v, i);
    SpecAnnotation ann;
    ann.name = jsonStrOr(a, "name");
    JsonRef args = jsonGet(a, "arguments");
    ann.arguments =
        (args != nullptr && args->type == JsonType::Object) ? args : nullptr;
    out.push_back(std::move(ann));
  }
  return out;
}

// Returns the string elements of `parent[key]`, empty when the key is absent —
// so a meta file predating the key still loads.
static std::vector<std::string> strListFromJson(const JsonRef& parent,
                                                const char* key) {
  std::vector<std::string> out;
  JsonRef arr = jsonGet(parent, key);
  std::size_t n = jsonArrayLen(arr);
  for (std::size_t i = 0; i < n; i++) {
    const std::string* s = jsonAsStr(jsonArrayAt(arr, i));
    if (s != nullptr) {
      out.push_back(*s);
    }
  }
  return out;
}

static SpecField fieldFromJson(const JsonRef& f) {
  SpecField out;
  out.name = jsonStrOr(f, "name");
  out.kind = specParseFieldKind(jsonStrOr(f, "kind"));
  out.doc = jsonStrOr(f, "doc");
  out.help = jsonStrOr(f, "help");
  out.headline = jsonStrOr(f, "headline");
  out.sectionId = jsonStrOr(f, "sectionId");
  out.sectionIdPattern = jsonStrOr(f, "sectionIdPattern");
  out.elementType = jsonStrOr(f, "elementType");
  out.elementIsComplex = jsonBoolOr(f, "elementIsComplex");

  auto min = jsonAsI64(jsonGet(f, "min"));
  if (min.has_value()) {
    out.hasMin = true;
    out.min = *min;
  }
  out.contentType = jsonStrOr(f, "contentType");
  out.sectionType = jsonStrOr(f, "sectionType");
  out.enumType = jsonStrOr(f, "enumType");

  out.enumValues = strListFromJson(f, "enumValues");

  out.type = jsonStrOr(f, "type");

  auto so = jsonAsI64(jsonGet(f, "serializationOrder"));
  if (so.has_value()) {
    out.hasSerializationOrder = true;
    out.serializationOrder = *so;
  }

  JsonRef ffs = jsonGet(f, "formFields");
  std::size_t fn = jsonArrayLen(ffs);
  for (std::size_t i = 0; i < fn; i++) {
    JsonRef ff = jsonArrayAt(ffs, i);
    FormFieldSpec ffs_out;
    std::string type = jsonStrOr(ff, "type");
    ffs_out.type = !type.empty() ? type : "String";
    std::string fname = jsonStrOr(ff, "name");
    std::string label = jsonStrOr(ff, "label");
    ffs_out.name = fname;
    ffs_out.label = !label.empty() ? label : fname;
    ffs_out.hint = jsonStrOr(ff, "hint");
    ffs_out.required = jsonBoolOr(ff, "required");
    ffs_out.enumValues = strListFromJson(ff, "enumValues");
    ffs_out.refersTo = strListFromJson(ff, "refersTo");
    out.formFields.push_back(std::move(ffs_out));
  }

  out.annotations = annotationsFromJson(jsonGet(f, "annotations"));
  return out;
}

static SpecClass classFromJson(const std::string& name, const JsonRef& cls) {
  SpecClass out;
  std::string cname = jsonStrOr(cls, "name");
  out.name = !cname.empty() ? cname : name;
  out.sectionId = jsonStrOr(cls, "sectionId");
  out.doc = jsonStrOr(cls, "doc");
  out.help = jsonStrOr(cls, "help");
  out.headline = jsonStrOr(cls, "headline");
  out.mapsTo = jsonStrOr(cls, "mapsTo");
  out.detailedIn = jsonStrOr(cls, "detailedIn");

  JsonRef fields = jsonGet(cls, "fields");
  std::size_t n = jsonArrayLen(fields);
  for (std::size_t i = 0; i < n; i++) {
    out.fields.push_back(fieldFromJson(jsonArrayAt(fields, i)));
  }
  out.annotations = annotationsFromJson(jsonGet(cls, "annotations"));
  return out;
}

// ---- generation stamp -----------------------------------------------------

namespace {

// The length of `month` in `year`, Gregorian. Used to reject a day that does not
// exist rather than letting it roll into the next month: some SOM runtimes' date
// types would turn 31 February into 3 March while others reject it outright — so
// the grammar rejects it everywhere.
long long daysInMonth(long long year, long long month) {
  static const long long kLengths[] = {31, 28, 31, 30, 31, 30,
                                       31, 31, 30, 31, 30, 31};
  if (month != 2) {
    return kLengths[month - 1];
  }
  return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
}

// Days since 1970-01-01 for a proleptic-Gregorian civil date (Howard Hinnant's
// `days_from_civil`) — the same arithmetic the Rust, Java and C ports use.
long long epochDay(long long year, long long month, long long day) {
  long long y = year - (month <= 2 ? 1 : 0);
  long long era = (y >= 0 ? y : y - 399) / 400;
  long long yoe = y - era * 400;
  long long doy = (153 * (month + (month > 2 ? -3 : 9)) + 2) / 5 + day - 1;
  long long doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
  return era * 146097 + doe - 719468;
}

bool isDigit(char c) { return c >= '0' && c <= '9'; }

// Reads `count` decimal digits at `at`, or nullopt when any is not a digit.
std::optional<long long> digitsAt(const std::string& s, std::size_t at,
                                  std::size_t count) {
  if (at + count > s.size()) {
    return std::nullopt;
  }
  long long value = 0;
  for (std::size_t i = 0; i < count; i++) {
    char c = s[at + i];
    if (!isDigit(c)) {
      return std::nullopt;
    }
    value = value * 10 + (c - '0');
  }
  return value;
}

std::string formatWarning(const char* fmt, long long a, long long b) {
  char buf[256];
  std::snprintf(buf, sizeof(buf), fmt, a, b);
  return std::string(buf);
}

}  // namespace

std::optional<long long> specParseStampTimestamp(const std::string& raw) {
  std::size_t start = raw.find_first_not_of(" \t\n\r");
  if (start == std::string::npos) {
    return std::nullopt;
  }
  std::size_t end = raw.find_last_not_of(" \t\n\r");
  std::string s = raw.substr(start, end - start + 1);

  if (s.size() < 19 || s[4] != '-' || s[7] != '-' || s[13] != ':' ||
      s[16] != ':') {
    return std::nullopt;
  }
  if (s[10] != 'T' && s[10] != 't' && s[10] != ' ') {
    return std::nullopt;
  }
  auto year = digitsAt(s, 0, 4);
  auto month = digitsAt(s, 5, 2);
  auto day = digitsAt(s, 8, 2);
  auto hour = digitsAt(s, 11, 2);
  auto minute = digitsAt(s, 14, 2);
  auto second = digitsAt(s, 17, 2);
  if (!year || !month || !day || !hour || !minute || !second) {
    return std::nullopt;
  }
  if (*month < 1 || *month > 12 || *day < 1 ||
      *day > daysInMonth(*year, *month)) {
    return std::nullopt;
  }
  if (*hour > 23 || *minute > 59 || *second > 59) {
    return std::nullopt;
  }

  std::size_t idx = 19;
  if (idx < s.size() && s[idx] == '.') {
    idx++;
    std::size_t fracStart = idx;
    while (idx < s.size() && isDigit(s[idx])) {
      idx++;
    }
    if (idx == fracStart) {
      return std::nullopt;  // a `.` with no digits is not the grammar
    }
  }

  long long epoch = epochDay(*year, *month, *day) * kSecondsPerDay +
                    *hour * 3600 + *minute * 60 + *second;
  if (idx < s.size()) {
    char sign = s[idx];
    if (sign == 'Z' || sign == 'z') {
      if (idx + 1 != s.size()) {
        return std::nullopt;
      }
    } else if (sign == '+' || sign == '-') {
      std::string rest = s.substr(idx + 1);
      std::optional<long long> oh, om;
      if (rest.size() == 4) {
        oh = digitsAt(rest, 0, 2);
        om = digitsAt(rest, 2, 2);
      } else if (rest.size() == 5 && rest[2] == ':') {
        oh = digitsAt(rest, 0, 2);
        om = digitsAt(rest, 3, 2);
      } else {
        return std::nullopt;
      }
      if (!oh || !om) {
        return std::nullopt;
      }
      long long offset = (*oh * 60 + *om) * 60;
      epoch += (sign == '-') ? offset : -offset;
    } else {
      return std::nullopt;
    }
  }
  return epoch;
}

bool SpecModelStampCheck::isAged() const {
  return ageSeconds.has_value() && *ageSeconds > maxAgeSeconds;
}

bool SpecModelStampCheck::classCountDisagrees() const {
  return declaredClassCount.has_value() && *declaredClassCount != actualClassCount;
}

bool SpecModelStampCheck::rootCountDisagrees() const {
  return declaredRootCount.has_value() && *declaredRootCount != actualRootCount;
}

bool SpecModelStampCheck::countsDisagree() const {
  return classCountDisagrees() || rootCountDisagrees();
}

bool SpecModelStampCheck::isStale() const {
  return isAged() || countsDisagree();
}

std::vector<std::string> SpecModelStampCheck::warnings() const {
  std::vector<std::string> out;
  if (isAged()) {
    out.push_back(formatWarning(
        "Snapshot is %lld days old (threshold %lld days) — the model may have "
        "moved on since it was exported.",
        *ageSeconds / kSecondsPerDay, maxAgeSeconds / kSecondsPerDay));
  }
  if (classCountDisagrees()) {
    out.push_back(formatWarning(
        "Stamp declares %lld classes but the snapshot carries %lld — it was "
        "edited after export.",
        *declaredClassCount, actualClassCount));
  }
  if (rootCountDisagrees()) {
    out.push_back(formatWarning(
        "Stamp declares %lld document roots but the snapshot carries %lld — it "
        "was edited after export.",
        *declaredRootCount, actualRootCount));
  }
  return out;
}

std::unique_ptr<SpecModel> SpecModel::buildFromRoot(const JsonRef& root) {
  auto m = std::make_unique<SpecModel>();
  m->source_ = root;

  JsonRef roots = jsonGet(root, "roots");
  std::size_t rn = jsonArrayLen(roots);
  for (std::size_t i = 0; i < rn; i++) {
    JsonRef r = jsonArrayAt(roots, i);
    SpecRoot sr;
    sr.type = jsonStrOr(r, "type");
    sr.title = jsonStrOr(r, "title");
    sr.sectionId = jsonStrOr(r, "sectionId");
    sr.description = jsonStrOr(r, "description");
    sr.doc = jsonStrOr(r, "doc");
    m->roots.push_back(std::move(sr));
  }

  JsonRef classes = jsonGet(root, "classes");
  if (classes != nullptr && classes->type == JsonType::Object) {
    for (const auto& mem : classes->object) {
      // Re-create a const JsonRef view of the member value.
      JsonRef val = std::const_pointer_cast<const Json>(mem.second);
      SpecClass cls = classFromJson(mem.first, val);
      // key by the source member key (matches the C entry name).
      m->classesByName_[mem.first] = std::move(cls);
    }
  }

  auto mv = jsonAsI64(jsonGet(root, "modelVersion"));
  m->modelVersion = mv.value_or(0);
  m->modelVersionLabel = jsonStrOr(root, "modelVersionLabel");

  // Generation stamp — every key optional. An absent count stays absent rather
  // than defaulting to zero: reading absent as 0 would make every pre-stamp
  // snapshot look like it had been edited down to nothing.
  m->generatedAt = specParseStampTimestamp(jsonStrOr(root, "generatedAt"));
  m->metaSchemaVersion = jsonAsI64(jsonGet(root, "metaSchemaVersion"));
  m->classCount = jsonAsI64(jsonGet(root, "classCount"));
  m->rootCount = jsonAsI64(jsonGet(root, "rootCount"));
  m->containerRoot = jsonStrOr(root, "containerRoot");
  return m;
}

SpecModelStampCheck SpecModel::checkStamp(long long maxAgeSeconds,
                                          long long nowEpochSeconds) const {
  SpecModelStampCheck out;
  if (generatedAt.has_value()) {
    out.ageSeconds = nowEpochSeconds - *generatedAt;
  }
  out.maxAgeSeconds = maxAgeSeconds;
  out.declaredClassCount = classCount;
  out.actualClassCount = static_cast<long long>(classesByName_.size());
  out.declaredRootCount = rootCount;
  out.actualRootCount = static_cast<long long>(roots.size());
  return out;
}

std::unique_ptr<SpecModel> SpecModel::fromJsonStr(const std::string& data,
                                                  std::string* err) {
  JsonPtr root = jsonParse(data, err);
  if (root == nullptr) {
    return nullptr;
  }
  return buildFromRoot(std::const_pointer_cast<const Json>(root));
}

std::unique_ptr<SpecModel> SpecModel::fromJson(const JsonRef& root) {
  if (root == nullptr) {
    return nullptr;
  }
  return buildFromRoot(root);
}

}  // namespace som
