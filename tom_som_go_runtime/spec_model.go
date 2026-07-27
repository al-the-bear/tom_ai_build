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
	"strings"
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

// SpecModel is the complete exported model.
type SpecModel struct {
	Roots             []*SpecRoot
	Classes           map[string]*SpecClass
	ModelVersion      int
	ModelVersionLabel string
}

// ClassNamed returns the class with the given name, or nil.
func (m *SpecModel) ClassNamed(name string) *SpecClass {
	if name == "" {
		return nil
	}
	return m.Classes[name]
}

// ModelVersionString is the `major.minor` version string used in the DocSpecs
// markdown declaration (DR6/DR11 parity — mirrors Python's
// `SpecModel.model_version_string`).
func (m *SpecModel) ModelVersionString() string {
	return SomModelVersionString(m.ModelVersion, m.ModelVersionLabel)
}

// RootByType returns the document root whose Type equals the argument (SOM
// § item 12). It replaces the recurring "range Roots looking for r.Type == …"
// boilerplate. When no root carries that type it returns a rootTypeNotFoundError
// whose message names the missing type and the ones that do exist.
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
	}, nil
}
