package somruntime

// spec_model.go — in-memory representation of the exported TomSpecs class graph
// (the spec-model meta-data file), a faithful port of
// `tom_som_dart_runtime/lib/src/spec_model.dart` (and the TypeScript
// `spec_model.ts`).
//
// The model is a class graph, not an expanded tree: each class appears once and
// field elementType / type references are followed on demand by a traversal.
// This is the "reflection" surface — it describes any document's structure,
// independent of the values a concrete document holds.

import (
	"encoding/json"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// Field render kinds, mirroring the exporter's classification.
const (
	SpecFieldKindList    = "list"
	SpecFieldKindForm    = "form"
	SpecFieldKindSection = "section"
	SpecFieldKindContent = "content"
	SpecFieldKindEnum    = "enum"
	SpecFieldKindComplex = "complex"
	SpecFieldKindScalar  = "scalar"
)

var fieldKindValues = map[string]bool{
	SpecFieldKindList:    true,
	SpecFieldKindForm:    true,
	SpecFieldKindSection: true,
	SpecFieldKindContent: true,
	SpecFieldKindEnum:    true,
	SpecFieldKindComplex: true,
	SpecFieldKindScalar:  true,
}

// ParseFieldKind parses a raw kind string, falling back to scalar.
func ParseFieldKind(raw string) string {
	if fieldKindValues[raw] {
		return raw
	}
	return SpecFieldKindScalar
}

// SpecAnnotation is a single annotation captured losslessly from the model
// source (som_multiplatform_spec_model.md §5.3): its name and the resolved
// argument map.
type SpecAnnotation struct {
	Name      string                 `json:"name"`
	Arguments map[string]interface{} `json:"arguments"`
}

// Argument returns the resolved value of a named annotation argument.
func (a *SpecAnnotation) Argument(key string) interface{} {
	if a.Arguments == nil {
		return nil
	}
	return a.Arguments[key]
}

// FormFieldSpec is a single form field within a @Form content section.
type FormFieldSpec struct {
	Name     string `json:"name"`
	Label    string `json:"label"`
	Type     string `json:"type"`
	Hint     string `json:"hint"`
	Required bool   `json:"required"`
}

// SpecField is a single field of a SpecClass.
type SpecField struct {
	Name string `json:"name"`
	Kind string `json:"kind"`
	Doc  string `json:"doc"`
	Help string `json:"help"`
	// Headline is the `@Headline(text)` default headline (YRD4), "" when
	// unannotated. Render precedence: stored headline > this default > name
	// derivation.
	Headline           string            `json:"headline"`
	SectionID          string            `json:"sectionId"`
	SectionIDPattern   string            `json:"sectionIdPattern"`
	SerializationOrder *int              `json:"serializationOrder"`
	ElementType        string            `json:"elementType"`
	ElementIsComplex   bool              `json:"elementIsComplex"`
	Min                *int              `json:"min"`
	ContentType        string            `json:"contentType"`
	SectionType        string            `json:"sectionType"`
	EnumType           string            `json:"enumType"`
	EnumValues         []string          `json:"enumValues"`
	Type               string            `json:"type"`
	FormFields         []*FormFieldSpec  `json:"formFields"`
	Annotations        []*SpecAnnotation `json:"annotations"`
}

// IsExpandable reports whether expanding this field reveals further tree nodes.
func (f *SpecField) IsExpandable() bool {
	return f.Kind == SpecFieldKindList || f.Kind == SpecFieldKindComplex
}

// Annotation returns the named annotation on this field, or nil.
func (f *SpecField) Annotation(name string) *SpecAnnotation {
	for _, a := range f.Annotations {
		if a.Name == name {
			return a
		}
	}
	return nil
}

// SpecClass is a model class with its fields.
type SpecClass struct {
	Name      string `json:"name"`
	SectionID string `json:"sectionId"`
	Doc       string `json:"doc"`
	Help      string `json:"help"`
	// Headline is the class-level `@Headline(text)` default headline (YRD4),
	// "" when unannotated. A field-level `@Headline` on the instantiating
	// field wins over this.
	Headline    string            `json:"headline"`
	MapsTo      string            `json:"mapsTo"`
	DetailedIn  string            `json:"detailedIn"`
	Fields      []*SpecField      `json:"fields"`
	Annotations []*SpecAnnotation `json:"annotations"`
}

// FieldNamed returns the field with the given name, or nil.
func (c *SpecClass) FieldNamed(name string) *SpecField {
	for _, f := range c.Fields {
		if f.Name == name {
			return f
		}
	}
	return nil
}

// Annotation returns the named annotation on this class, or nil.
func (c *SpecClass) Annotation(name string) *SpecAnnotation {
	for _, a := range c.Annotations {
		if a.Name == name {
			return a
		}
	}
	return nil
}

// SpecRoot is a document root (a class carrying @Document).
type SpecRoot struct {
	Type        string `json:"type"`
	Title       string `json:"title"`
	SectionID   string `json:"sectionId"`
	Description string `json:"description"`
	Doc         string `json:"doc"`
}

// DefaultMaxSnapshotAge is how old a snapshot may get before CheckStamp calls
// it aged.
//
// A fortnight: long enough that a healthy working copy is never nagged, short
// enough that structural feedback keyed to a snapshot's paths is not recorded
// against a model that has moved past them.
const DefaultMaxSnapshotAge = 14 * 24 * time.Hour

// stampPattern is the generation-stamp timestamp grammar, spelled out rather
// than delegated to time.Parse: `YYYY-MM-DDTHH:MM:SS`, an optional fractional
// part, and an optional `Z` / `±HH:MM` / `±HHMM` offset.
//
// Every SOM runtime carries this same grammar. Delegating to each platform's
// own parser would make the accepted set differ by language — several of the
// nine have no date library at all — and a stamp that reads on one platform and
// not another is exactly the divergence the shared corpus exists to catch.
var stampPattern = regexp.MustCompile(
	`^(\d{4})-(\d{2})-(\d{2})[Tt ](\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?(Z|z|[+-]\d{2}:?\d{2})?$`)

// daysInMonth is the length of month in year, Gregorian. Used to reject a day
// that does not exist rather than letting it roll into the next month:
// time.Date would turn 31 February into 3 March, while several other SOM
// runtimes' date types reject it outright — so the grammar rejects it
// everywhere.
func daysInMonth(year, month int) int {
	if month != 2 {
		return [12]int{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}[month-1]
	}
	if year%4 == 0 && (year%100 != 0 || year%400 == 0) {
		return 29
	}
	return 28
}

// ParseStampTimestamp parses a generation-stamp timestamp to UTC, returning nil
// when it is unreadable.
//
// A timestamp carrying no zone is read as UTC — a staleness verdict that
// changed with the reader's timezone would be a defect in its own right, and
// one the other eight SOM runtimes could not mirror anyway (several have no
// timezone database).
//
// Anything outside the grammar — or carrying an out-of-range field — degrades
// to nil rather than erroring: an unreadable stamp is not worth failing a whole
// model over.
func ParseStampTimestamp(raw string) *time.Time {
	m := stampPattern.FindStringSubmatch(strings.TrimSpace(raw))
	if m == nil {
		return nil
	}
	year, _ := strconv.Atoi(m[1])
	month, _ := strconv.Atoi(m[2])
	day, _ := strconv.Atoi(m[3])
	hour, _ := strconv.Atoi(m[4])
	minute, _ := strconv.Atoi(m[5])
	second, _ := strconv.Atoi(m[6])
	if month < 1 || month > 12 || day < 1 || day > daysInMonth(year, month) {
		return nil
	}
	if hour > 23 || minute > 59 || second > 59 {
		return nil
	}
	// Right-pad the fraction to nanoseconds; a longer fraction is truncated.
	frac := m[7]
	if len(frac) > 9 {
		frac = frac[:9]
	}
	frac += strings.Repeat("0", 9-len(frac))
	nanos, _ := strconv.Atoi(frac)
	value := time.Date(year, time.Month(month), day, hour, minute, second, nanos, time.UTC)
	if zone := m[8]; zone != "" && zone != "Z" && zone != "z" {
		digits := strings.ReplaceAll(zone[1:], ":", "")
		oh, _ := strconv.Atoi(digits[:2])
		om, _ := strconv.Atoi(digits[2:])
		offset := time.Duration(oh)*time.Hour + time.Duration(om)*time.Minute
		if zone[0] == '-' {
			value = value.Add(offset)
		} else {
			value = value.Add(-offset)
		}
	}
	return &value
}

// SpecModelStampCheck is the outcome of checking a loaded snapshot's generation
// stamp against its own payload and against the clock — see
// SpecModel.CheckStamp.
//
// The two findings are independent and can both hold at once: IsAged says the
// snapshot is probably behind the live model, while CountsDisagree says the
// file no longer describes itself correctly. Only the second is a defect in the
// file.
type SpecModelStampCheck struct {
	// Age is how long ago the snapshot was generated, or nil when it carries no
	// generatedAt (an older export, or a hand-built model).
	Age *time.Duration
	// MaxAge is the threshold Age was judged against.
	MaxAge time.Duration
	// DeclaredClassCount is the class count the stamp declares, or nil.
	DeclaredClassCount *int
	// ActualClassCount is the number of classes the payload actually carries.
	ActualClassCount int
	// DeclaredRootCount is the document-root count the stamp declares, or nil.
	DeclaredRootCount *int
	// ActualRootCount is the number of roots the payload actually carries.
	ActualRootCount int
}

// IsAged reports whether the snapshot is older than MaxAge. Always false when
// it carries no generatedAt — an unknown age is not evidence of a stale one.
func (c SpecModelStampCheck) IsAged() bool {
	return c.Age != nil && *c.Age > c.MaxAge
}

// ClassCountDisagrees reports whether the declared and actual class counts
// differ.
//
// An absent declaration is not a disagreement: older snapshots predate the
// stamp keys, and reading absent as 0 would make every one of them look
// corrupt.
func (c SpecModelStampCheck) ClassCountDisagrees() bool {
	return c.DeclaredClassCount != nil && *c.DeclaredClassCount != c.ActualClassCount
}

// RootCountDisagrees reports whether the declared and actual root counts
// differ. Absent declarations are ignored, as for ClassCountDisagrees.
func (c SpecModelStampCheck) RootCountDisagrees() bool {
	return c.DeclaredRootCount != nil && *c.DeclaredRootCount != c.ActualRootCount
}

// CountsDisagree reports whether either declared size disagrees with the
// payload.
//
// The exporter derives both counts *from* the payload it writes, so a
// disagreement cannot arise from a normal export — it means the file was edited
// or truncated afterwards.
func (c SpecModelStampCheck) CountsDisagree() bool {
	return c.ClassCountDisagrees() || c.RootCountDisagrees()
}

// IsStale reports whether anything at all was found.
func (c SpecModelStampCheck) IsStale() bool {
	return c.IsAged() || c.CountsDisagree()
}

// Warnings are the findings as ready-to-display sentences, empty when there are
// none. The wording is identical in all nine runtimes.
func (c SpecModelStampCheck) Warnings() []string {
	out := []string{}
	if c.IsAged() {
		days := int64(*c.Age / (24 * time.Hour))
		threshold := int64(c.MaxAge / (24 * time.Hour))
		out = append(out, "Snapshot is "+strconv.FormatInt(days, 10)+
			" days old (threshold "+strconv.FormatInt(threshold, 10)+
			" days) — the model may have moved on since it was exported.")
	}
	if c.ClassCountDisagrees() {
		out = append(out, "Stamp declares "+itoa(*c.DeclaredClassCount)+
			" classes but the snapshot carries "+itoa(c.ActualClassCount)+
			" — it was edited after export.")
	}
	if c.RootCountDisagrees() {
		out = append(out, "Stamp declares "+itoa(*c.DeclaredRootCount)+
			" document roots but the snapshot carries "+itoa(c.ActualRootCount)+
			" — it was edited after export.")
	}
	return out
}

// SpecModel is the complete exported model.
type SpecModel struct {
	Roots             []*SpecRoot
	Classes           map[string]*SpecClass
	ModelVersion      int
	ModelVersionLabel string
	// GeneratedAt is when the snapshot was exported (UTC), or nil when it
	// carries no generatedAt — an export predating the key, or a hand-built
	// model.
	GeneratedAt *time.Time
	// MetaSchemaVersion is the *file format's* own version, distinct from
	// ModelVersion (which model the snapshot describes). Nil when undeclared.
	MetaSchemaVersion *int
	// ClassCount is the class count the snapshot declares, or nil when
	// undeclared. Kept separate from len(Classes): the declared value is what
	// the exporter recorded, the actual value is what survived to the reader,
	// and comparing them is the point (CheckStamp).
	ClassCount *int
	// RootCount is the document-root count the snapshot declares, or nil.
	RootCount *int
	// ContainerRoot is the canonical container class — the single true tree
	// root, which is not itself a document and so does not appear in Roots.
	// Empty when the model has no container (e.g. a synthetic export).
	ContainerRoot string
}

// CheckStamp checks the generation stamp against the payload and the clock.
//
// now is injectable so callers (and tests) can evaluate age against a fixed
// instant instead of the wall clock; pass the zero Time for "now".
func (m *SpecModel) CheckStamp(maxAge time.Duration, now time.Time) SpecModelStampCheck {
	if now.IsZero() {
		now = time.Now()
	}
	var age *time.Duration
	if m.GeneratedAt != nil {
		d := now.Sub(*m.GeneratedAt)
		age = &d
	}
	return SpecModelStampCheck{
		Age:                age,
		MaxAge:             maxAge,
		DeclaredClassCount: m.ClassCount,
		ActualClassCount:   len(m.Classes),
		DeclaredRootCount:  m.RootCount,
		ActualRootCount:    len(m.Roots),
	}
}

// ClassNamed returns the class with the given name, or nil.
func (m *SpecModel) ClassNamed(name string) *SpecClass {
	if name == "" {
		return nil
	}
	return m.Classes[name]
}

// ModelVersionString is the `major.minor` version string used in the DocSpecs
// markdown declaration (Dart / Python parity — mirrors Python's
// `SpecModel.model_version_string`).
func (m *SpecModel) ModelVersionString() string {
	return SomModelVersionString(m.ModelVersion, m.ModelVersionLabel)
}

// RootByType returns the document root whose Type equals the argument (SOM §21).
// It replaces the recurring "range Roots looking for r.Type == …"
// boilerplate. When no root carries that type it returns a
// rootTypeNotFoundError whose message names the missing type and the ones that
// do exist.
func (m *SpecModel) RootByType(rootType string) (*SpecRoot, error) {
	for _, r := range m.Roots {
		if r.Type == rootType {
			return r, nil
		}
	}
	return nil, errRootType(rootType, m.rootTypes())
}

// rootTypes returns the Type of every root, in root order.
func (m *SpecModel) rootTypes() []string {
	types := make([]string, 0, len(m.Roots))
	for _, r := range m.Roots {
		types = append(types, r.Type)
	}
	return types
}

func errRootType(rootType string, have []string) error {
	return &rootTypeNotFoundError{rootType: rootType, have: have}
}

type rootTypeNotFoundError struct {
	rootType string
	have     []string
}

func (e *rootTypeNotFoundError) Error() string {
	return "no document root with type '" + e.rootType +
		"' (have: " + strings.Join(e.have, ", ") + ")"
}

// SomModelVersionString derives the `major.minor` DocSpecs version string from
// a model's integer version and its optional free-form label (port of Python's
// `som_model_version_string`).
//
// When the label's `+`-stripped core has at least two dot-separated integer
// components, those become `major.minor`; otherwise the result is `<major>.0`.
func SomModelVersionString(major int, label string) string {
	if label != "" {
		core := strings.TrimSpace(strings.SplitN(label, "+", 2)[0])
		parts := strings.Split(core, ".")
		if len(parts) >= 2 {
			maj := strings.TrimSpace(parts[0])
			minor := strings.TrimSpace(parts[1])
			if isSignedDigits(maj) && isSignedDigits(minor) {
				return itoa(atoi(maj)) + "." + itoa(atoi(minor))
			}
		}
	}
	return itoa(major) + ".0"
}

// isSignedDigits reports whether s matches /^[+-]?[0-9]+$/.
func isSignedDigits(s string) bool {
	if s == "" {
		return false
	}
	if s[0] == '+' || s[0] == '-' {
		return isAllDigits(s[1:])
	}
	return isAllDigits(s)
}

// specModelJSON mirrors the on-disk meta-data shape for unmarshalling.
type specModelJSON struct {
	Roots             []*SpecRoot           `json:"roots"`
	Classes           map[string]*SpecClass `json:"classes"`
	ModelVersion      int                   `json:"modelVersion"`
	ModelVersionLabel string                `json:"modelVersionLabel"`
	GeneratedAt       string                `json:"generatedAt"`
	MetaSchemaVersion *int                  `json:"metaSchemaVersion"`
	ClassCount        *int                  `json:"classCount"`
	RootCount         *int                  `json:"rootCount"`
	ContainerRoot     string                `json:"containerRoot"`
}

// SpecModelFromJSON decodes a meta-data JSON document into a SpecModel,
// normalising every field kind through ParseFieldKind.
func SpecModelFromJSON(data []byte) (*SpecModel, error) {
	var raw specModelJSON
	if err := json.Unmarshal(data, &raw); err != nil {
		return nil, err
	}
	if raw.Classes == nil {
		raw.Classes = map[string]*SpecClass{}
	}
	for _, cls := range raw.Classes {
		for _, f := range cls.Fields {
			f.Kind = ParseFieldKind(f.Kind)
			if f.Type == "" {
				// FormFieldSpec defaults its type to "String" (parity with the
				// other ports' fromJson); field types stay as authored.
			}
		}
		for _, ff := range cls.Fields {
			for _, form := range ff.FormFields {
				if form.Type == "" {
					form.Type = "String"
				}
				if form.Label == "" {
					form.Label = form.Name
				}
			}
		}
	}
	return &SpecModel{
		Roots:             raw.Roots,
		Classes:           raw.Classes,
		ModelVersion:      raw.ModelVersion,
		ModelVersionLabel: raw.ModelVersionLabel,
		GeneratedAt:       ParseStampTimestamp(raw.GeneratedAt),
		MetaSchemaVersion: raw.MetaSchemaVersion,
		ClassCount:        raw.ClassCount,
		RootCount:         raw.RootCount,
		ContainerRoot:     raw.ContainerRoot,
	}, nil
}
