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
	"math"
	"sort"
	"strconv"
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
	// A form field whose model type is an enum holds a token the enum does not
	// declare. The typed read is forgiving (an unknown token answers the zero
	// value), and a document is loaded far more often than it is written through
	// a setter, so without this the value is simply dropped. An EMPTY value is
	// absence, not a bad value, and is not reported.
	SpecValidationCodeEnumValueUnknown = "enumValueUnknown"
	// A form field that states a count (`FormFieldSpec.CountOf`) holds a number
	// that is not the number of entries the document holds, or no whole number
	// at all (vsctsa43). A total kept by hand drifts from the list it describes
	// the first time the list changes and the total does not.
	SpecValidationCodeCountMismatch = "countMismatch"
	// A typed field (`int`, `double`, `num` or `bool`) — a form field or a
	// scalar leaf — holds text its type cannot read (`lots` in an `int`). The
	// typed read refuses such text rather than answering nil, and the setters
	// refuse to store it, but a document edited by hand or by another tool can
	// still carry it; this is where it is reported. Empty text is absence, not
	// a bad value, and is not reported.
	SpecValidationCodeValueTypeMismatch = "valueTypeMismatch"
	// A form field whose value is derived from other fields — a product
	// (`FormFieldSpec.ProductOf`) or a rank by a sibling field
	// (`FormFieldSpec.RankOf`) — holds a value the fields it is derived from do
	// not give, or no number at all (uamtc10). A risk score kept by hand drifts
	// the first time probability or impact changes and the score does not.
	SpecValidationCodeDerivedValueMismatch = "derivedValueMismatch"
	// A form the document holds leaves a `required` field empty (uamtc16).
	// Checked for every form instance the document holds — a class-level form,
	// a form declared on a section member, in a list item or not — so an absent
	// form is absence, not an incomplete one. The schema tier checks
	// class-level forms of the rendition only; this is the check that reaches
	// every form.
	SpecValidationCodeMissingRequiredField = "missingRequiredField"
	// A reference field that holds one id (no `Field.multiple`) holds a
	// comma-separated list (uamtc17). A field meant for one reference must not
	// silently hold several; each id of the list is still resolved, so a
	// dangling one is a `danglingReference` as well.
	SpecValidationCodeMultipleReferences = "multipleReferences"
	// A comment block or a question block sits inside a form field's value —
	// between or below the form's fields — instead of in the form's preamble
	// (SOM §11.9.4).
	SpecValidationCodeAnnotationMisplaced = "annotationMisplaced"
	// An annotation does not follow the notation (SOM §11.9.5): an unclosed or
	// nested inline mark, a substitution without `~>`, a comment id that is
	// not `C-<n>`, a question header that is not `**❓ <ID> — <topic>:**`, or a
	// question or answer inside a comment block.
	SpecValidationCodeAnnotationMalformed = "annotationMalformed"
	// A comment id or a question id is used twice in one document
	// (SOM §11.9.5).
	SpecValidationCodeDuplicateAnnotationID = "duplicateAnnotationId"
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
		// A wrapper section (TextSection, ...) is the other: its class is not
		// exported, so it resolves to no class and its text is stored at its
		// own path, the way the YAML codec writes it.
		isWrapperSection := res.Kind == SpecNodeKindSection && res.TargetClass == nil
		if !res.IsValueLeaf() && res.Kind != SpecNodeKindForm && !isWrapperSection {
			errors = append(errors, SpecValidationError{
				Path:    path,
				Code:    SpecValidationCodeKindMismatch,
				Message: "expected a value leaf but path resolves to " + res.Kind,
			})
			continue
		}
		if res.Kind == SpecNodeKindScalar {
			typ := fieldType(res.Field)
			value := doc.ContentOr(path)
			if !SomTypedTextReadable(typ, value) {
				errors = append(errors, SpecValidationError{
					Path: path,
					Code: SpecValidationCodeValueTypeMismatch,
					Message: "holds \"" + value + "\", which is not readable as " +
						SomScalarBase(typ),
				})
			}
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
		declared := map[string]*FormFieldSpec{}
		for _, ff := range res.Field.FormFields {
			declared[ff.Name] = ff
		}
		for _, name := range sortedCopy(doc.FormFieldNames(path)) {
			spec, ok := declared[name]
			if !ok {
				errors = append(errors, SpecValidationError{
					Path:    path,
					Code:    SpecValidationCodeUnknownFormField,
					Message: "form field \"" + name + "\" is not declared on " + res.Field.Name,
				})
				continue
			}
			if len(spec.EnumValues) == 0 {
				text := doc.FormFieldOr(path, name)
				// A stated count (CountOf) is checked by countMismatch, a derived
				// value (ProductOf, RankOf) by derivedValueMismatch; both already
				// report text that is no number, and one finding is enough.
				if len(spec.CountOf) == 0 && len(spec.ProductOf) == 0 && spec.RankOf == "" &&
					!SomTypedTextReadable(spec.Type, text) {
					errors = append(errors, SpecValidationError{
						Path: path,
						Code: SpecValidationCodeValueTypeMismatch,
						Message: "form field \"" + name + "\" holds \"" + text +
							"\", which is not readable as " + SomScalarBase(spec.Type),
					})
				}
				continue
			}
			value := doc.FormFieldOr(path, name)
			// Absence is not a bad value.
			if value == "" {
				continue
			}
			known := false
			for _, v := range spec.EnumValues {
				if v == value {
					known = true
					break
				}
			}
			if !known {
				errors = append(errors, SpecValidationError{
					Path: path,
					Code: SpecValidationCodeEnumValueUnknown,
					Message: "form field \"" + name + "\" holds \"" + value +
						"\", which " + spec.Type + " does not declare (" +
						strings.Join(spec.EnumValues, ", ") + ")",
				})
			}
		}
		// A form the document holds must fill its required fields; the
		// declared order makes the findings for one form stable (uamtc16).
		formName := res.Field.Name
		if slash := strings.LastIndex(path, "/"); slash > 0 {
			if owner := refl.Resolve(path[:slash]); owner != nil && owner.TargetClass != nil {
				formName = owner.TargetClass.Name + "." + res.Field.Name
			}
		}
		for _, ff := range res.Field.FormFields {
			if !ff.Required {
				continue
			}
			if strings.TrimSpace(doc.FormFieldOr(path, ff.Name)) == "" {
				errors = append(errors, SpecValidationError{
					Path:    path,
					Code:    SpecValidationCodeMissingRequiredField,
					Message: "form field \"" + ff.Name + "\" is required on " + formName + " but empty",
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

	// 6. Stated counts (instance tier, vsctsa43).
	//
	// A form field declaring `countOf` states how many entries the document
	// holds; only the instance tier can count them.
	errors = append(errors, validateCountInstances(refl, doc)...)
	errors = append(errors, validateDerivedValues(refl, doc)...)

	// 7. Review annotations (SOM §11.9.5): malformed, misplaced or duplicated
	// comment blocks, question blocks and inline marks. Findings, never parse
	// rejections — the rest of the document still validates.
	errors = append(errors, NewSpecReviewAnnotations(doc, "").Validate()...)

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
	forms := resolvedForms(refl, doc)

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

			// One id, unless the field says it holds several. Decidable without
			// the registries, so it is checked before the scope test below.
			if !ff.Multiple {
				ids := []string{}
				for _, part := range strings.Split(value, ",") {
					if p := strings.TrimSpace(part); p != "" {
						ids = append(ids, p)
					}
				}
				if len(ids) > 1 {
					errors = append(errors, SpecValidationError{
						Path: form.path,
						Code: SpecValidationCodeMultipleReferences,
						Message: "form field \"" + ff.Name + "\" holds " +
							strconv.Itoa(len(ids)) + " references (" +
							strings.Join(ids, ", ") + ") but takes one",
					})
				}
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

// validateCountInstances is the instance-tier stated-count check (vsctsa43):
// every non-empty value of a `countOf` form field must be a whole number equal
// to the number of entries the document holds.
//
// An *entry* is a list item whose element class carries @SectionId(X). A target
// `X` counts every such entry; `X.f=v` counts only the entries one of whose own
// forms — a form member of the entry, at `<item>/<member>` — holds `v` in form
// field `f`. The count is the sum over the targets. As with the reference check,
// a target whose section id the document's root cannot reach makes the field
// undecidable here, so it is skipped rather than reported, and an empty value is
// completeness, not a count.
func validateCountInstances(refl *SpecReflection, doc *SpecDocument) []SpecValidationError {
	forms := resolvedForms(refl, doc)
	anyCount := false
	for _, form := range forms {
		for _, ff := range form.field.FormFields {
			if len(ff.CountOf) > 0 {
				anyCount = true
			}
		}
	}
	if !anyCount {
		return nil
	}
	scope := registryScope(refl, doc)

	// Every entry, by its class's section id, with the form values its own form
	// members hold.
	entriesByID := map[string][]string{}
	for _, listPath := range sortedCopy(doc.ListPaths()) {
		for _, item := range doc.ListItems(listPath) {
			res := refl.Resolve(item)
			if res == nil || res.TargetClass == nil || res.TargetClass.SectionID == "" {
				continue
			}
			id := res.TargetClass.SectionID
			entriesByID[id] = append(entriesByID[id], item)
		}
	}
	valuesByItem := map[string]map[string]map[string]bool{}
	for _, path := range doc.FormPaths() {
		slash := strings.LastIndex(path, "/")
		if slash <= 0 {
			continue
		}
		owner := path[:slash]
		res := refl.Resolve(path)
		if res == nil || res.Field == nil {
			continue
		}
		for _, ff := range res.Field.FormFields {
			v := strings.TrimSpace(doc.FormFieldOr(path, ff.Name))
			if v == "" {
				continue
			}
			if valuesByItem[owner] == nil {
				valuesByItem[owner] = map[string]map[string]bool{}
			}
			if valuesByItem[owner][ff.Name] == nil {
				valuesByItem[owner][ff.Name] = map[string]bool{}
			}
			valuesByItem[owner][ff.Name][v] = true
		}
	}

	// A target written `./…` counts only the entries beneath owner, the section
	// holding the form; any other target counts the whole document.
	countTarget := func(target, owner string) int {
		scoped := strings.HasPrefix(target, "./")
		if scoped {
			target = target[2:]
		}
		inScope := func(item string) bool {
			return !scoped || strings.HasPrefix(item, owner+"/")
		}
		dot := strings.Index(target, ".")
		if dot < 0 {
			n := 0
			for _, item := range entriesByID[target] {
				if inScope(item) {
					n++
				}
			}
			return n
		}
		id := target[:dot]
		field := target[dot+1:]
		value := ""
		if eq := strings.Index(target[dot:], "="); eq >= 0 {
			field = target[dot+1 : dot+eq]
			value = target[dot+eq+1:]
		}
		n := 0
		for _, item := range entriesByID[id] {
			if inScope(item) && valuesByItem[item][field][value] {
				n++
			}
		}
		return n
	}

	var errors []SpecValidationError
	for _, form := range forms {
		for _, ff := range form.field.FormFields {
			if len(ff.CountOf) == 0 {
				continue
			}
			stated := strings.TrimSpace(doc.FormFieldOr(form.path, ff.Name))
			if stated == "" {
				continue
			}
			allInScope := true
			for _, target := range ff.CountOf {
				if !scope[registrySectionID(countTargetID(target))] {
					allInScope = false
					break
				}
			}
			if !allInScope {
				continue
			}
			owner := form.path[:strings.LastIndex(form.path, "/")]
			counted := 0
			for _, target := range ff.CountOf {
				counted += countTarget(target, owner)
			}
			targets := strings.Join(ff.CountOf, " + ")
			countedText := strconv.Itoa(counted)
			if !isWholeNumber(stated) {
				errors = append(errors, SpecValidationError{
					Path: form.path,
					Code: SpecValidationCodeCountMismatch,
					Message: "form field \"" + ff.Name + "\" states \"" + stated +
						"\", which is not a whole number — it counts " + targets +
						", of which the document holds " + countedText,
				})
			} else if n, err := strconv.Atoi(stated); err != nil || n != counted {
				// A digit string too large for an int cannot equal any count.
				errors = append(errors, SpecValidationError{
					Path: form.path,
					Code: SpecValidationCodeCountMismatch,
					Message: "form field \"" + ff.Name + "\" states " + stated +
						", but the document holds " + countedText +
						" (counting " + targets + ")",
				})
			}
		}
	}
	return errors
}

// isWholeNumber reports whether s is one or more ASCII digits — the reference's
// `^[0-9]+$`.
func isWholeNumber(s string) bool {
	if s == "" {
		return false
	}
	for i := 0; i < len(s); i++ {
		if s[i] < '0' || s[i] > '9' {
			return false
		}
	}
	return true
}

// countTargetID returns the section id of a `countOf` target — the part before
// any `.field=value`, without the `./` scope prefix.
func countTargetID(target string) string {
	target = strings.TrimPrefix(target, "./")
	if dot := strings.Index(target, "."); dot >= 0 {
		return target[:dot]
	}
	return target
}

// validateDerivedValues is the instance-tier derived-value check (uamtc10): a
// `productOf` field must hold the product of its operands, and a `rankOf` field
// must rank the instances of its form by their score, highest first.
//
// Operands. A plain operand is a field of the same form; `F.x` is field `x` of
// the form `F` beside it, at `<owner>/F` where `<owner>` is the section holding
// this form. A numeric operand contributes its number, an enum operand its
// 1-based position among the enum's values. When the value or any operand is
// empty — or an operand is unreadable, which other checks report — the product
// is undecidable and is skipped; a stated value that is no number at all is
// still reported.
//
// Precision. The stated number is held to the precision it is written in: `2.8`
// matches 0.7 × 4.0, and `15` matches 3 × 5, but `2.9` does not.
//
// Ranks. Over every instance of the same form whose rank and score are both
// filled, the ranks must be the whole numbers 1 to n, each once, and an
// instance may not rank below one that scores lower. Equal scores take their
// ranks in any order. Each offending instance is reported once.
func validateDerivedValues(refl *SpecReflection, doc *SpecDocument) []SpecValidationError {
	forms := resolvedForms(refl, doc)
	anyDerived := false
	for _, form := range forms {
		for _, ff := range form.field.FormFields {
			if len(ff.ProductOf) > 0 || ff.RankOf != "" {
				anyDerived = true
			}
		}
	}
	if !anyDerived {
		return nil
	}

	// The number a filled form field contributes, or ok=false when it is empty
	// or unreadable.
	numberOf := func(formPath string, spec *FormFieldSpec) (float64, bool) {
		v := strings.TrimSpace(doc.FormFieldOr(formPath, spec.Name))
		if v == "" {
			return 0, false
		}
		if len(spec.EnumValues) > 0 {
			for i, e := range spec.EnumValues {
				if e == v {
					return float64(i + 1), true
				}
			}
			return 0, false
		}
		if !isDecimalNumber(v) {
			return 0, false
		}
		f, err := strconv.ParseFloat(v, 64)
		if err != nil {
			return 0, false
		}
		return f, true
	}

	// The spec of field name on the form at path, or nil.
	specAt := func(path, name string) *FormFieldSpec {
		res := refl.Resolve(path)
		if res == nil || res.Kind != SpecNodeKindForm || res.Field == nil {
			return nil
		}
		for i := range res.Field.FormFields {
			if res.Field.FormFields[i].Name == name {
				return res.Field.FormFields[i]
			}
		}
		return nil
	}

	type rankedEntry struct {
		path, name, stated string
		score              float64
	}
	ranked := map[string][]rankedEntry{}
	var rankedOrder []string

	var errors []SpecValidationError
	for _, form := range forms {
		owner := form.path[:strings.LastIndex(form.path, "/")]
		for i := range form.field.FormFields {
			ff := form.field.FormFields[i]
			if len(ff.ProductOf) > 0 {
				stated := strings.TrimSpace(doc.FormFieldOr(form.path, ff.Name))
				if stated != "" {
					product := 1.0
					decidable := true
					for _, operand := range ff.ProductOf {
						path, name := form.path, operand
						if dot := strings.Index(operand, "."); dot >= 0 {
							path = owner + "/" + operand[:dot]
							name = operand[dot+1:]
						}
						spec := specAt(path, name)
						if spec == nil {
							decidable = false
							break
						}
						n, ok := numberOf(path, spec)
						if !ok {
							decidable = false
							break
						}
						product *= n
					}
					operands := strings.Join(ff.ProductOf, " × ")
					if !isDecimalNumber(stated) {
						errors = append(errors, SpecValidationError{
							Path: form.path,
							Code: SpecValidationCodeDerivedValueMismatch,
							Message: "form field \"" + ff.Name + "\" states \"" + stated +
								"\", which is not a number — it is the product " + operands,
						})
					} else if decidable {
						decimals := 0
						if dot := strings.Index(stated, "."); dot >= 0 {
							decimals = len(stated) - dot - 1
						}
						tolerance := 0.5*pow10(-decimals) + 1e-9
						value, _ := strconv.ParseFloat(stated, 64)
						if math.Abs(value-product) > tolerance {
							errors = append(errors, SpecValidationError{
								Path: form.path,
								Code: SpecValidationCodeDerivedValueMismatch,
								Message: "form field \"" + ff.Name + "\" states " + stated +
									", but " + operands + " gives " + formatNumber(product),
							})
						}
					}
				}
			}
			if ff.RankOf != "" {
				stated := strings.TrimSpace(doc.FormFieldOr(form.path, ff.Name))
				scoreSpec := specAt(form.path, ff.RankOf)
				if stated != "" && scoreSpec != nil {
					if score, ok := numberOf(form.path, scoreSpec); ok {
						key := form.cls.Name + "#" + form.field.Name + "#" + ff.Name
						if _, seen := ranked[key]; !seen {
							rankedOrder = append(rankedOrder, key)
						}
						ranked[key] = append(ranked[key], rankedEntry{
							path: form.path, name: ff.Name, stated: stated, score: score,
						})
					}
				}
			}
		}
	}

	for _, key := range rankedOrder {
		group := ranked[key]
		n := len(group)
		rankOf := map[string]int{}
		seen := map[int]int{}
		for _, e := range group {
			if !isWholeNumber(e.stated) {
				continue
			}
			r, err := strconv.Atoi(e.stated)
			if err != nil {
				// Too large for an int: out of range either way.
				r = n + 1
			}
			rankOf[e.path] = r
			seen[r]++
		}
		for _, e := range group {
			r, valid := rankOf[e.path]
			problem := ""
			if !valid {
				problem = "states \"" + e.stated + "\", which is not a whole number"
			} else if r < 1 || r > n || seen[r] > 1 {
				problem = "states rank " + strconv.Itoa(r) + ", but the " + strconv.Itoa(n) +
					" ranked entries take the ranks 1 to " + strconv.Itoa(n) + ", each once"
			} else {
				for _, o := range group {
					ro, ok := rankOf[o.path]
					if ok && o.score < e.score && ro < r {
						problem = "ranks " + strconv.Itoa(r) + " with score " + formatNumber(e.score) +
							", below an entry ranked " + strconv.Itoa(ro) +
							" with the lower score " + formatNumber(o.score)
						break
					}
				}
			}
			if problem != "" {
				errors = append(errors, SpecValidationError{
					Path:    e.path,
					Code:    SpecValidationCodeDerivedValueMismatch,
					Message: "form field \"" + e.name + "\" " + problem,
				})
			}
		}
	}
	// Like every phase's group, the findings are ordered by path; the sort is
	// stable, so a path's own findings keep the order they were found in.
	sort.SliceStable(errors, func(i, j int) bool { return errors[i].Path < errors[j].Path })
	return errors
}

// isDecimalNumber reports whether s matches the reference's
// `^-?[0-9]+(\.[0-9]+)?$`.
func isDecimalNumber(s string) bool {
	s = strings.TrimPrefix(s, "-")
	intPart, frac, hasDot := strings.Cut(s, ".")
	if !isWholeNumber(intPart) {
		return false
	}
	return !hasDot || isWholeNumber(frac)
}

// pow10 returns 10^exponent by repeated multiplication, as the reference does.
func pow10(exponent int) float64 {
	v := 1.0
	abs := exponent
	if abs < 0 {
		abs = -abs
	}
	for i := 0; i < abs; i++ {
		v *= 10
	}
	if exponent < 0 {
		return 1 / v
	}
	return v
}

// formatNumber renders a whole number without a fraction, any other number in
// its shortest form.
func formatNumber(v float64) string {
	if v == math.Round(v) && math.Abs(v) < 1e15 {
		return strconv.FormatInt(int64(v), 10)
	}
	return strconv.FormatFloat(v, 'g', -1, 64)
}

// resolvedForms returns every form instance in doc with its field and the class
// it sits on, in path order — the shape both the reference and the count check
// sweep.
func resolvedForms(refl *SpecReflection, doc *SpecDocument) []formInstance {
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
	return forms
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
