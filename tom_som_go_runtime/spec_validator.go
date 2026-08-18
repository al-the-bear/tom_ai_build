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

import (
	"sort"
	"strings"
)

// Why a single value in a document is invalid against the model.
const (
	SpecValidationCodeDanglingPath      = "danglingPath"
	SpecValidationCodeKindMismatch      = "kindMismatch"
	SpecValidationCodeUnknownFormField  = "unknownFormField"
	SpecValidationCodeMinItems          = "minItems"
	SpecValidationCodeOneOfCaseMismatch = "oneOfCaseMismatch"
	SpecValidationCodeDanglingReference = "danglingReference"
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
		// A form node is the one non-leaf that legitimately carries content: it
		// is the form's preamble, the free text before the first field line
		// (SOM §11.4 rule 7), in the same slot a plain section's body uses.
		if !res.IsValueLeaf() && res.Kind != SpecNodeKindForm {
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

	// 4. @OneOf/@Case closed choice (csmb6).
	//
	// The static tier checks the group is well formed; only here can we see which
	// case a document actually chose and whether the subsections it populated are
	// the ones that choice selects.
	errors = append(errors, validateOneOfInstances(refl, doc)...)

	// 5. Cross-registry references (csrb3).
	//
	// A reference form field holds an id that must already be declared by some
	// entry of a target registry. The static tier has checked the `refersTo`
	// targets are resolvable; only here can we see whether the id a document
	// actually wrote is one the document also declares.
	errors = append(errors, validateReferenceInstances(refl, doc)...)

	return errors
}

// caseConstant returns the constant part of a qualified `EnumType.constant`
// @Case token (or the whole string when it is not qualified).
func caseConstant(token string) string {
	if dot := strings.Index(token, "."); dot >= 0 {
		return token[dot+1:]
	}
	return token
}

// documentSectionPaths returns every section-instance path present in doc: each
// stored value path plus all of its ancestor prefixes (a container's own
// discriminator form lives at `<container>/content`, so the container path is
// always a prefix of a populated path), sorted.
func documentSectionPaths(doc *SpecDocument) []string {
	seen := map[string]bool{}
	for _, group := range [][]string{
		doc.ContentPaths(), doc.FormPaths(), doc.ListPaths(), doc.HeadlinePaths(),
	} {
		for _, full := range group {
			segs := strings.Split(full, "/")
			buf := ""
			for i, seg := range segs {
				if i > 0 {
					buf += "/"
				}
				buf += seg
				seen[buf] = true
			}
		}
	}
	out := make([]string, 0, len(seen))
	for p := range seen {
		out = append(out, p)
	}
	sort.Strings(out)
	return out
}

// validateOneOfInstances is the instance-tier @OneOf/@Case check (csmb6): for
// every @OneOf container instance present in doc, verify the populated case
// subsections match the chosen discriminator value.
func validateOneOfInstances(refl *SpecReflection, doc *SpecDocument) []SpecValidationError {
	var errors []SpecValidationError

	for _, path := range documentSectionPaths(doc) {
		res := refl.Resolve(path)
		if res == nil || res.TargetClass == nil {
			continue
		}
		cls := res.TargetClass
		oneOf := cls.Annotation("OneOf")
		if oneOf == nil {
			continue
		}
		discriminator, _ := oneOf.Argument("discriminator").(string)
		if discriminator == "" {
			continue
		}

		// Read the chosen discriminator value from the container's own @Form.
		var formHolder *SpecField
		for _, f := range cls.Fields {
			if f.Kind != SpecFieldKindForm {
				continue
			}
			for _, ff := range f.FormFields {
				if ff.Name == discriminator {
					formHolder = f
					break
				}
			}
			if formHolder != nil {
				break
			}
		}
		if formHolder == nil {
			continue // static tier flagged the mismatch
		}
		chosen := doc.FormFieldOr(path+"/"+refl.FieldSegment(formHolder), discriminator)
		if chosen == "" {
			continue // no case chosen yet
		}

		// Inspect each case-bound subsection: present + not-selected → mismatch.
		var presentForChosen []string
		for _, f := range cls.Fields {
			caseSet := map[string]bool{}
			for _, a := range f.Annotations {
				if a.Name != "Case" {
					continue
				}
				if v, ok := a.Argument("value").(string); ok {
					caseSet[caseConstant(v)] = true
				}
			}
			if len(caseSet) == 0 {
				continue // common subsection — always allowed
			}
			childPath := path + "/" + refl.FieldSegment(f)
			if !doc.HasValuesUnder(childPath) {
				continue
			}
			if caseSet[chosen] {
				presentForChosen = append(presentForChosen, f.Name)
				continue
			}
			cases := make([]string, 0, len(caseSet))
			for c := range caseSet {
				cases = append(cases, c)
			}
			sort.Strings(cases)
			errors = append(errors, SpecValidationError{
				Path: childPath,
				Code: SpecValidationCodeOneOfCaseMismatch,
				Message: "subsection \"" + f.Name + "\" is present but the chosen " +
					discriminator + "=\"" + chosen + "\" does not select it (cases: " +
					strings.Join(cases, ", ") + ")",
			})
		}
		if len(presentForChosen) > 1 {
			sort.Strings(presentForChosen)
			errors = append(errors, SpecValidationError{
				Path: path,
				Code: SpecValidationCodeOneOfCaseMismatch,
				Message: "chosen " + discriminator + "=\"" + chosen +
					"\" selects more than one populated subsection (" +
					strings.Join(presentForChosen, ", ") +
					") — at most one case subsection may be present",
			})
		}
	}

	return errors
}

// formInstance is one resolved form section: its path, the class it sits on, and
// its field.
type formInstance struct {
	path  string
	cls   *SpecClass
	field *SpecField
}

// validateReferenceInstances is the instance-tier cross-registry reference check
// (csrb3): every id written into a `refersTo` form field must be declared by some
// entry of one of its target registries *in this document*.
//
// The pass is two sweeps over the document's form sections, so it costs one extra
// walk rather than a resolve per reference:
//
//  1. Declare. Every form instance whose class carries @SectionId(X) and declares
//     form field `f` contributes its value of `f` to the registry key `X.f`. Every
//     item of a list whose element class carries @SectionId(X) additionally
//     contributes its *effective* section id — stored, else positional, see
//     EffectiveListItemSectionID — to the reserved key `X.@sectionId`. That second
//     half is what makes a registry keeping its id nowhere but the section id (a
//     functional requirement) referenceable at all.
//  2. Resolve. Every form instance holding a `refersTo` field checks its value
//     against those sets. A value naming several ids writes them comma-separated,
//     so each segment resolves independently.
//
// A value is valid when it resolves in *any* listed registry: some fields
// legitimately accept an id from more than one. An empty value is not a dangling
// reference — it means "not filled in yet".
//
// Cross-document references (csre2). A reference whose target registry the
// document's own root cannot reach is skipped rather than reported. Such a
// reference is a *cross-document* one and the registry it names is absent from
// the document by construction, not undeclared; see registryScope.
func validateReferenceInstances(refl *SpecReflection, doc *SpecDocument) []SpecValidationError {
	var errors []SpecValidationError
	scope := registryScope(refl, doc)

	// Resolve every form path once; both sweeps read the same resolutions.
	//
	// A form resolution names the form *field*, not a class — the section id a
	// registry key is written against belongs to the class the form sits on, so
	// the owner is resolved from the parent path.
	var forms []formInstance
	for _, path := range sortedCopy(doc.FormPaths()) {
		res := refl.Resolve(path)
		if res == nil || res.Kind != SpecNodeKindForm || res.Field == nil {
			continue
		}
		slash := strings.LastIndex(path, "/")
		if slash <= 0 {
			continue
		}
		owner := refl.Resolve(path[:slash])
		if owner == nil || owner.TargetClass == nil {
			continue
		}
		forms = append(forms, formInstance{path: path, cls: owner.TargetClass, field: res.Field})
	}

	// 1. Declare.
	declared := map[string]map[string]bool{}
	declare := func(key, value string) {
		if declared[key] == nil {
			declared[key] = map[string]bool{}
		}
		declared[key][value] = true
	}
	for _, form := range forms {
		if form.cls.SectionID == "" {
			continue
		}
		for _, ff := range form.field.FormFields {
			value := strings.TrimSpace(doc.FormFieldOr(form.path, ff.Name))
			if value == "" {
				continue
			}
			declare(form.cls.SectionID+"."+ff.Name, value)
		}
	}

	// 1b. Declare the per-item section ids under the reserved `@sectionId` slot.
	// The key is the *element class's* section id, not the `-LST` container's: a
	// target names the entry, so `FRE.@sectionId` reads as "an id of some
	// functional-requirement entry".
	for _, listPath := range sortedCopy(doc.ListPaths()) {
		listRes := refl.Resolve(listPath)
		pattern := ""
		stem := ""
		if listRes != nil && listRes.Field != nil {
			pattern = listRes.Field.SectionIDPattern
			stem = listRes.Field.Name
		}
		if stem == "" {
			segs := strings.Split(listPath, "/")
			stem = segs[len(segs)-1]
		}
		for i, itemPath := range doc.ListItems(listPath) {
			itemRes := refl.Resolve(itemPath)
			if itemRes == nil || itemRes.TargetClass == nil || itemRes.TargetClass.SectionID == "" {
				continue
			}
			storedID, hasStored := doc.ItemSectionID(itemPath)
			declare(
				itemRes.TargetClass.SectionID+"."+KSectionIDSlot,
				EffectiveListItemSectionID(storedID, hasStored, pattern, i+1, stem),
			)
		}
	}

	// 2. Resolve.
	for _, form := range forms {
		for _, ff := range form.field.FormFields {
			if len(ff.RefersTo) == 0 {
				continue
			}
			value := strings.TrimSpace(doc.FormFieldOr(form.path, ff.Name))
			if value == "" {
				continue
			}

			// Every target must be in scope, not merely one of them: a disjunction
			// says the id may come from any of the listed registries, so one absent
			// registry is enough to make "no registry declares it" unsound.
			allInScope := true
			for _, target := range ff.RefersTo {
				if !scope[registrySectionID(target)] {
					allInScope = false
					break
				}
			}
			if !allInScope {
				continue
			}

			for _, segment := range strings.Split(value, ",") {
				id := strings.TrimSpace(segment)
				if id == "" {
					continue
				}
				resolves := false
				for _, target := range ff.RefersTo {
					if declared[target][id] {
						resolves = true
						break
					}
				}
				if resolves {
					continue
				}
				noun := "registries"
				if len(ff.RefersTo) == 1 {
					noun = "registry"
				}
				errors = append(errors, SpecValidationError{
					Path: form.path,
					Code: SpecValidationCodeDanglingReference,
					Message: "form field \"" + ff.Name + "\" references \"" + id +
						"\", which no entry of " + noun + " " +
						strings.Join(ff.RefersTo, ", ") + " declares",
				})
			}
		}
	}

	return errors
}

// registrySectionID returns the section id part of a registry key written
// `<SECTIONID>.<slot>`. A key with no dot is malformed — the static tier reports
// it — and is treated whole here so it simply fails to match any section id.
func registrySectionID(target string) string {
	dot := strings.Index(target, ".")
	if dot <= 0 {
		return target
	}
	return target[:dot]
}

// registryScope returns the registry section ids that are *in scope* for doc: the
// @SectionId of every class reachable from a document root the document actually
// uses (csre2).
//
// A `refersTo` target names its registry by section id, and a document can only
// ever declare entries of registries its own root reaches. Anything outside this
// set is absent from the document by construction — which is precisely the case
// the dangling-reference check must not call an error.
//
// The roots are read off the document rather than passed in: every path begins
// with its root's segment, so the document already says which root(s) it belongs
// to. A document spanning several roots contributes the union.
func registryScope(refl *SpecReflection, doc *SpecDocument) map[string]bool {
	rootTypes := map[string]bool{}
	for _, group := range [][]string{
		doc.ContentPaths(), doc.FormPaths(), doc.ListPaths(), doc.HeadlinePaths(),
	} {
		for _, path := range group {
			segment := path
			if slash := strings.Index(path, "/"); slash >= 0 {
				segment = path[:slash]
			}
			if root := refl.RootForSegment(segment); root != nil {
				rootTypes[root.Type] = true
			}
		}
	}

	ids := map[string]bool{}
	for rootType := range rootTypes {
		for name := range refl.ReachableClassNames(rootType) {
			if cls := refl.ClassNamed(name); cls != nil && cls.SectionID != "" {
				ids[cls.SectionID] = true
			}
		}
	}
	return ids
}
