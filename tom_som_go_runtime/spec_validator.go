package somruntime

// spec_validator.go — validates a concrete SpecDocument's values against a
// SpecModel via the SpecReflection resolver, a faithful port of
// `tom_som_dart_runtime/lib/src/spec_validator.dart` (and the TypeScript
// `spec_validator.ts`).
//
// The check is over the values a document holds: every set path must resolve to
// a node of a compatible kind, every form sub-key must name a real form field,
// and every populated list must meet its @Min item count. Schema completeness
// (mandatory-but-absent nodes) is a separate concern and is not reported here.

import "sort"

// Why a single value in a document is invalid against the model.
const (
	SpecValidationCodeDanglingPath     = "danglingPath"
	SpecValidationCodeKindMismatch     = "kindMismatch"
	SpecValidationCodeUnknownFormField = "unknownFormField"
	SpecValidationCodeMinItems         = "minItems"
)

// SpecValidationError is one problem found while validating a document.
type SpecValidationError struct {
	Path    string
	Code    string
	Message string
}

// String renders the error as "[code] path: message".
func (e SpecValidationError) String() string {
	return "[" + e.Code + "] " + e.Path + ": " + e.Message
}

func dangling(path string) SpecValidationError {
	return SpecValidationError{
		Path:    path,
		Code:    SpecValidationCodeDanglingPath,
		Message: "path does not resolve to any model node",
	}
}

func sortedCopy(in []string) []string {
	out := make([]string, len(in))
	copy(out, in)
	sort.Strings(out)
	return out
}

// ValidateDocument validates doc against model. Returns nil/empty when the
// document is valid; otherwise one SpecValidationError per problem, in a stable
// order (content paths, then forms, then lists; each group sorted by path).
func ValidateDocument(model *SpecModel, doc *SpecDocument) []SpecValidationError {
	refl := NewSpecReflection(model)
	var errors []SpecValidationError

	// 1. Content/scalar/enum leaves.
	for _, path := range sortedCopy(doc.ContentPaths()) {
		res := refl.Resolve(path)
		if res == nil {
			errors = append(errors, dangling(path))
			continue
		}
		if !res.IsValueLeaf() {
			errors = append(errors, SpecValidationError{
				Path:    path,
				Code:    SpecValidationCodeKindMismatch,
				Message: "expected a value leaf but path resolves to " + res.Kind,
			})
		}
	}

	// 2. Form sections.
	for _, path := range sortedCopy(doc.FormPaths()) {
		res := refl.Resolve(path)
		if res == nil {
			errors = append(errors, dangling(path))
			continue
		}
		if res.Kind != SpecNodeKindForm || res.Field == nil {
			errors = append(errors, SpecValidationError{
				Path:    path,
				Code:    SpecValidationCodeKindMismatch,
				Message: "expected a form section but path resolves to " + res.Kind,
			})
			continue
		}
		declared := map[string]bool{}
		for _, ff := range res.Field.FormFields {
			declared[ff.Name] = true
		}
		for _, name := range sortedCopy(doc.FormFieldNames(path)) {
			if !declared[name] {
				errors = append(errors, SpecValidationError{
					Path:    path,
					Code:    SpecValidationCodeUnknownFormField,
					Message: "form field \"" + name + "\" is not declared on " + res.Field.Name,
				})
			}
		}
	}

	// 3. Lists (container kind + @Min count on populated lists).
	for _, path := range sortedCopy(doc.ListPaths()) {
		res := refl.Resolve(path)
		if res == nil {
			errors = append(errors, dangling(path))
			continue
		}
		if res.Kind != SpecNodeKindList || res.Field == nil {
			errors = append(errors, SpecValidationError{
				Path:    path,
				Code:    SpecValidationCodeKindMismatch,
				Message: "expected a list but path resolves to " + res.Kind,
			})
			continue
		}
		if res.Field.Min != nil {
			count := doc.ListItemCount(path)
			if count < *res.Field.Min {
				errors = append(errors, SpecValidationError{
					Path:    path,
					Code:    SpecValidationCodeMinItems,
					Message: "list holds " + itoa(count) + " item(s) but requires at least " + itoa(*res.Field.Min),
				})
			}
		}
	}

	return errors
}
