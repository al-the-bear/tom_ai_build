package somruntime

// spec_editor.go — the generic, meta-model-driven modification API (YRD7), a
// faithful port of `tom_som_dart_runtime/lib/src/spec_editor.dart` (and the
// Python `spec_editor.py`).
//
// SpecEditor lets a consumer walk any document's meta tree and
// create/modify/delete sections, list items, headlines, ids, content and
// **typed** form fields *without a generated facade*: every operation resolves
// its path against the SpecModel first (SpecReflection.Resolve) and converts
// values at the store boundary through the same spec_typed_values helpers the
// generated accessors call — so a typed facade is provably a thin layer over
// exactly this API.
//
// Typed contract (mirrored by all nine runtimes):
//
//   - int / double / num / bool values are native on both sides;
//   - enum values travel as validated **constant-name strings** at this generic
//     layer (`high`), because the generic API has no generated enum types —
//     only the facade layer converts to native constants;
//   - a nil value (or "") clears a value (D4);
//   - reads are forgiving (unparsable stored text reads as nil), writes are
//     strict (an error for a wrong type or an out-of-domain enum name).
//
// # Go's stand-ins for the reference's dynamic types
//
// Go has no dynamic value type and no exceptions, so the two in/out positions
// the reference spells `Object?` take and return `any` holding a string, int,
// float64, bool or nil, and every fallible operation returns an error instead
// of throwing. Because `any` carries no int/double distinction once a value has
// been through a JSON decode (every JSON number lands as a float64), the write
// conversion is driven by the leaf's **declared** type rather than by the Go
// dynamic type: an integral float64 is accepted for an int field, an int for a
// double/num field. A genuine type mismatch still fails — a bool for an int
// field, a fractional value for an int field, or any number for a String field.

import (
	"errors"
	"time"
)

// SpecEditor provides generic, typed, meta-validated editing over a
// SpecDocument.
type SpecEditor struct {
	// Document is the document being edited (the sparse value stores).
	Document *SpecDocument
	// Reflection is the value-free meta-model queries the editor validates
	// against.
	Reflection *SpecReflection
}

// NewSpecEditor binds an editor to a document and the reflection surface it
// validates against.
func NewSpecEditor(document *SpecDocument, reflection *SpecReflection) *SpecEditor {
	return &SpecEditor{Document: document, Reflection: reflection}
}

// NewSpecEditorForModel is the convenience constructor: it builds the editor
// for document over model.
func NewSpecEditorForModel(document *SpecDocument, model *SpecModel) *SpecEditor {
	return &SpecEditor{Document: document, Reflection: NewSpecReflection(model)}
}

// --- resolution --------------------------------------------------------------

// Resolve resolves path against the meta-model, returning an error for a
// dangling path — the strict companion to SpecReflection.Resolve.
func (e *SpecEditor) Resolve(path string) (*SpecResolution, error) {
	r := e.Reflection.Resolve(path)
	if r == nil {
		return nil, errors.New("path '" + path + "' does not resolve against the model")
	}
	return r, nil
}

// --- value leaves (content / scalar / enum / scalar list item) ---------------

// Value returns the typed value at the value leaf path, or nil when unset.
//
// The dynamic type follows the model: int/double/num/bool scalars return the
// parsed native value, enum leaves the validated constant name, everything else
// the raw string. Returns an error when path is not a value leaf.
func (e *SpecEditor) Value(path string) (any, error) {
	r, err := e.valueLeaf(path)
	if err != nil {
		return nil, err
	}
	raw := e.Document.ContentOr(path)
	if raw == "" {
		return nil, nil
	}
	if r.Kind == SpecNodeKindEnumValue {
		if name, ok := SomParseEnumName(raw, enumDomain(r.Field)); ok {
			return name, nil
		}
		return nil, nil
	}
	return parseScalar(raw, scalarBase(fieldType(r.Field))), nil
}

// SetValue sets the value leaf at path to v, converting at the store boundary.
//
// A nil v clears. For typed scalars v must be the declared type (or a string,
// taken verbatim); for enum leaves v must be one of the field's constant names.
// Returns an error for a non-leaf path, a wrong value type, or an out-of-domain
// enum name.
func (e *SpecEditor) SetValue(path string, v any) error {
	r, err := e.valueLeaf(path)
	if err != nil {
		return err
	}
	stored, err := e.format(v, r.Kind, r.Field, path, "", "")
	if err != nil {
		return err
	}
	e.Document.SetContent(path, stored)
	return nil
}

func (e *SpecEditor) valueLeaf(path string) (*SpecResolution, error) {
	r, err := e.Resolve(path)
	if err != nil {
		return nil, err
	}
	if !r.IsValueLeaf() {
		return nil, errors.New(
			"path '" + path + "' is a " + r.Kind + " node, not a value leaf")
	}
	return r, nil
}

// --- headlines (YRD3) --------------------------------------------------------

// Headline returns the stored headline at path, or "" when the section renders
// its effective default title.
func (e *SpecEditor) Headline(path string) (string, error) {
	if _, err := e.Resolve(path); err != nil {
		return "", err
	}
	return e.Document.HeadlineOr(path), nil
}

// SetHeadline sets the stored headline at path; an empty value returns the
// section to its default title.
func (e *SpecEditor) SetHeadline(path, value string) error {
	if _, err := e.Resolve(path); err != nil {
		return err
	}
	e.Document.SetHeadline(path, value)
	return nil
}

// --- typed form fields -------------------------------------------------------

// FormValue returns the typed value of form field at the @Form section path, or
// nil when unset.
//
// It reads the form store and parses per the declared field type (enum fields
// return the validated constant name). Returns an error for a non-form path or
// an unknown field name.
func (e *SpecEditor) FormValue(path, field string) (any, error) {
	ff, err := e.formField(path, field)
	if err != nil {
		return nil, err
	}
	raw := e.Document.FormFieldOr(path, field)
	if raw == "" {
		return nil, nil
	}
	if len(ff.EnumValues) > 0 {
		if name, ok := SomParseEnumName(raw, ff.EnumValues); ok {
			return name, nil
		}
		return nil, nil
	}
	return parseScalar(raw, scalarBase(ff.Type)), nil
}

// SetFormValue sets form field at the @Form section path to the typed value v
// (nil clears), converting through the shared boundary helpers.
//
// Returns an error for a wrong value type or an out-of-domain enum name.
func (e *SpecEditor) SetFormValue(path, field string, v any) error {
	ff, err := e.formField(path, field)
	if err != nil {
		return err
	}
	var stored string
	if len(ff.EnumValues) > 0 {
		name, nameErr := stringOrEmpty(v, path, field)
		if nameErr != nil {
			return nameErr
		}
		stored, err = SomFormatEnumName(name, ff.EnumValues)
	} else {
		stored, err = e.format(v, SpecNodeKindScalar, nil, path, ff.Type, field)
	}
	if err != nil {
		return err
	}
	e.Document.SetFormField(path, field, stored)
	return nil
}

// FormFields returns the form-field specs of the @Form section at path, in
// declaration order — the meta a generic editor UI renders from.
func (e *SpecEditor) FormFields(path string) ([]*FormFieldSpec, error) {
	r, err := e.Resolve(path)
	if err != nil {
		return nil, err
	}
	if r.Kind != SpecNodeKindForm {
		return nil, errors.New(
			"path '" + path + "' is a " + r.Kind + " node, not a @Form section")
	}
	if r.Field == nil {
		return nil, nil
	}
	return r.Field.FormFields, nil
}

func (e *SpecEditor) formField(path, field string) (*FormFieldSpec, error) {
	fields, err := e.FormFields(path)
	if err != nil {
		return nil, err
	}
	for _, ff := range fields {
		if ff.Name == field {
			return ff, nil
		}
	}
	return nil, errors.New("'" + field + "' is not a form field of " + path)
}

// --- structural operations ---------------------------------------------------

// AddListItem appends a new item to the list at listPath and returns its stable
// item path.
//
// When the list field carries a @SectionIdPattern and no explicit sectionID is
// given (""), a fresh id is generated from the pattern
// (GenerateListItemSectionID) dated month/day — either of which defaults to
// today when passed as 0, so a caller with no opinion on the date passes
// `"", 0, 0`. An explicit sectionID is uniqueness-checked against the list's
// other items (a *SpecSectionIDCollision). Returns an error when listPath is
// not a list.
func (e *SpecEditor) AddListItem(listPath, sectionID string, month, day int) (string, error) {
	r, err := e.Resolve(listPath)
	if err != nil {
		return "", err
	}
	if r.Kind != SpecNodeKindList {
		return "", errors.New(
			"path '" + listPath + "' is a " + r.Kind + " node, not a list")
	}
	id := sectionID
	if pattern := sectionIDPattern(r.Field); id == "" && pattern != "" {
		today := time.Now()
		if month == 0 {
			month = int(today.Month())
		}
		if day == 0 {
			day = today.Day()
		}
		id = GenerateListItemSectionID(
			pattern, month, day, e.Document.ListItemSectionIDs(listPath))
	}
	if id == "" {
		return e.Document.AddListItem(listPath), nil
	}
	return e.Document.AddListItemWithSectionID(listPath, id)
}

// RemoveListItem removes the list item at itemPath with every value beneath it.
// It reports whether an item was found and removed.
func (e *SpecEditor) RemoveListItem(itemPath string) bool {
	return e.Document.RemoveListItem(itemPath)
}

// ClearSection clears every value at path and beneath it — content, form
// entries, nested list items, stored headlines and ids — returning the subtree
// to the untouched "empty = no value" state (D4). The node itself remains
// addressable (structure lives in the model, not the document).
func (e *SpecEditor) ClearSection(path string) error {
	if _, err := e.Resolve(path); err != nil {
		return err
	}
	e.Document.RemoveValuesUnder(path)
	return nil
}

// --- conversion --------------------------------------------------------------

// format renders v for the store per the leaf's declared type; strings pass
// through verbatim (the plain-text serialization is authoritative).
//
// typeName overrides the field's own declared type (the form-field case, where
// the type lives on the FormFieldSpec rather than the SpecField) and where
// names the position in an error message; both are "" when not applicable.
func (e *SpecEditor) format(
	v any, kind string, field *SpecField, path, typeName, where string,
) (string, error) {
	if v == nil {
		return "", nil
	}
	at := where
	if at == "" {
		at = path
	}
	if kind == SpecNodeKindEnumValue {
		name, err := stringOrEmpty(v, path, at)
		if err != nil {
			return "", err
		}
		return SomFormatEnumName(name, enumDomain(field))
	}
	declared := typeName
	if declared == "" {
		declared = fieldType(field)
	}
	base := scalarBase(declared)
	// asFloat (spec_meta_diff.go) narrows any Go numeric to the widest carrier;
	// bool is a distinct Go type, so it can never be mistaken for a number.
	number, isNumber := asFloat(v)
	switch base {
	case "int":
		if isNumber && isIntegral(number) {
			return SomFormatInt(int(number)), nil
		}
	case "double":
		if isNumber {
			return SomFormatDouble(number), nil
		}
	case "num":
		if isNumber {
			return SomFormatNum(number), nil
		}
	case "bool":
		if b, ok := v.(bool); ok {
			return SomFormatBool(b), nil
		}
	}
	if s, ok := v.(string); ok {
		return s, nil
	}
	if base == "" {
		base = "String"
	}
	return "", errors.New(
		"value at " + at + ": wrong value type for a " + base + " field")
}

// stringOrEmpty narrows a dynamic value to the string an enum name has to be —
// nil becomes "" (clear), anything else is an error.
func stringOrEmpty(v any, path, field string) (string, error) {
	if v == nil {
		return "", nil
	}
	if s, ok := v.(string); ok {
		return s, nil
	}
	return "", errors.New(
		field + ": expected a string for this field of " + path)
}

// parseScalar parses stored text per the declared scalar base type, returning
// nil when the text does not parse (reads are forgiving).
func parseScalar(raw, base string) any {
	switch base {
	case "int":
		if n, ok := SomParseInt(raw); ok {
			return n
		}
		return nil
	case "double":
		if f, ok := SomParseDouble(raw); ok {
			return f
		}
		return nil
	case "num":
		if n, ok := SomParseNum(raw); ok {
			return n
		}
		return nil
	case "bool":
		if b, ok := SomParseBool(raw); ok {
			return b
		}
		return nil
	}
	return raw
}

// scalarBase strips a trailing `?` from a declared type name.
func scalarBase(typeName string) string {
	if len(typeName) > 0 && typeName[len(typeName)-1] == '?' {
		return typeName[:len(typeName)-1]
	}
	return typeName
}

// fieldType returns a field's declared type, "" for a nil field.
func fieldType(field *SpecField) string {
	if field == nil {
		return ""
	}
	return field.Type
}

// enumDomain returns a field's enum constant names, nil for a nil field.
func enumDomain(field *SpecField) []string {
	if field == nil {
		return nil
	}
	return field.EnumValues
}

// sectionIDPattern returns a field's @SectionIdPattern, "" for a nil field.
func sectionIDPattern(field *SpecField) string {
	if field == nil {
		return ""
	}
	return field.SectionIDPattern
}
