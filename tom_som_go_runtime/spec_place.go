package somruntime

// spec_place.go — places and filters of the link vocabulary
// (`tom_specs_model_rules.md` §9.7): the grammar every link annotation names
// places in, parsed once and resolved under an anchor through SpecReflection —
// a port of `tom_som_dart_runtime/lib/src/spec_place.dart` (and the
// TypeScript, JavaScript and Python `spec_place` modules).
//
//   - A place names a section, a list, a form field, a heading, a content
//     value or a registry id: `FRED.description`, `FRE.@headline`,
//     `FRE-REQU-LST`, `./RQDEP`, `FRE/REQDEP/RQDEP.description`,
//     `<SECTIONID>.@content`, `<SECTIONID>.@sectionId` (SpecPlace).
//   - A filter selects entries by one of their form values: `<SECTIONID>`,
//     `./<SECTIONID>`, `<SECTIONID>.<field>=<value>` with `|` between
//     alternatives (`FRE.priority=must|should`) (SpecPlaceFilter). `countOf`
//     and every `where:` read it.
//
// Resolution is value-free, like SpecReflection: it says where in a document
// the place is stored, with every list item below the anchor written
// `<list>-*`, and never reads a value.

import (
	"regexp"
	"sort"
	"strings"
)

// What a resolved place is (the corpus compares the string values).
const (
	// SpecPlaceKindSection is a section (a class's own node or a complex
	// member), whole.
	SpecPlaceKindSection = "section"
	// SpecPlaceKindList is a `-LST` list container.
	SpecPlaceKindList = "list"
	// SpecPlaceKindForm is a form member, every field of it.
	SpecPlaceKindForm = "form"
	// SpecPlaceKindFormField is one field of a form.
	SpecPlaceKindFormField = "formField"
	// SpecPlaceKindHeadline is the stored headline of a section (`.@headline`).
	SpecPlaceKindHeadline = "headline"
	// SpecPlaceKindContent is the content value of a section (`.@content`, or
	// a content member).
	SpecPlaceKindContent = "content"
	// SpecPlaceKindSectionID is the stored section id of a list element
	// (`.@sectionId`).
	SpecPlaceKindSectionID = "sectionId"
)

// Why a place or a filter does not parse or does not resolve.
const (
	// SpecPlaceProblemMalformed: the text is not a place (or not a filter) of
	// the grammar.
	SpecPlaceProblemMalformed = "malformed"
	// SpecPlaceProblemAnchorUnresolved: the anchor path resolves to no section
	// of the model.
	SpecPlaceProblemAnchorUnresolved = "anchorUnresolved"
	// SpecPlaceProblemNotScoped: the place is `./`-scoped, but no list element
	// lies at or above the anchor.
	SpecPlaceProblemNotScoped = "notScoped"
	// SpecPlaceProblemUnresolved: no section with the place's id (and `/`
	// path) lies in the scope.
	SpecPlaceProblemUnresolved = "unresolved"
	// SpecPlaceProblemAmbiguous: the place's id is reached at more than one
	// position in the scope.
	SpecPlaceProblemAmbiguous = "ambiguous"
	// SpecPlaceProblemNoSuchField: the named field is no form field of the
	// section.
	SpecPlaceProblemNoSuchField = "noSuchField"
	// SpecPlaceProblemNoContent: `.@content` names a section that holds no
	// content value.
	SpecPlaceProblemNoContent = "noContent"
	// SpecPlaceProblemNotListElement: `.@sectionId` names a section that is no
	// list element.
	SpecPlaceProblemNotListElement = "notListElement"
	// SpecPlaceProblemReservedSlot: a slot starting with `@` other than
	// `@headline`, `@content`, `@sectionId`.
	SpecPlaceProblemReservedSlot = "reservedSlot"
)

// SpecPlaceError is a place or filter that does not parse or resolve, with the
// reason.
type SpecPlaceError struct {
	// Problem is what went wrong (a SpecPlaceProblem constant); the corpus
	// compares this, never the message.
	Problem string
	// Text is the place or filter as written.
	Text string
	// Message is the prose for the reader.
	Message string
}

// Error implements the error interface.
func (e *SpecPlaceError) Error() string {
	return "SpecPlaceException(" + e.Problem + "): \"" + e.Text + "\" " + e.Message
}

var (
	placeSegmentRE = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9-]*$`)
	placeSlotRE    = regexp.MustCompile(`^@?[A-Za-z_][A-Za-z0-9_]*$`)
	placeFieldRE   = regexp.MustCompile(`^[A-Za-z_][A-Za-z0-9_]*$`)
)

// SpecPlace is a place as written: `./` scope, `/` segments, section id and
// slot.
type SpecPlace struct {
	// Text is the text it was parsed from.
	Text string
	// Scoped is whether it is written `./…`: resolved beneath the nearest list
	// element at or above the anchor.
	Scoped bool
	// Prefix are the section ids written before the last `/`, which the path
	// to the place holds in this order.
	Prefix []string
	// SectionID is the section id the place names.
	SectionID string
	// Slot is the part after the dot: a form field name, `@headline`,
	// `@content`, `@sectionId`; "" for the section, list or form itself.
	Slot string
}

// ParseSpecPlace parses text; it fails with a *SpecPlaceError (`malformed`)
// when it is not a place.
func ParseSpecPlace(text string) (*SpecPlace, error) {
	if p := TryParseSpecPlace(text); p != nil {
		return p, nil
	}
	return nil, &SpecPlaceError{
		Problem: SpecPlaceProblemMalformed,
		Text:    text,
		Message: "is not a place (`<SECTIONID>[.<field>|.@headline|.@content|" +
			".@sectionId]`, optionally `./`-scoped or a `/` path)",
	}
}

// TryParseSpecPlace parses text, or returns nil when it is not a place.
func TryParseSpecPlace(text string) *SpecPlace {
	scoped := strings.HasPrefix(text, "./")
	body := text
	if scoped {
		body = text[2:]
	}
	if body == "" {
		return nil
	}
	segments := strings.Split(body, "/")
	last := segments[len(segments)-1]
	segments = segments[:len(segments)-1]
	id, slot := last, ""
	hasSlot := false
	if dot := strings.Index(last, "."); dot >= 0 {
		id, slot, hasSlot = last[:dot], last[dot+1:], true
	}
	if !placeSegmentRE.MatchString(id) {
		return nil
	}
	for _, s := range segments {
		if !placeSegmentRE.MatchString(s) {
			return nil
		}
	}
	if hasSlot && !placeSlotRE.MatchString(slot) {
		return nil
	}
	return &SpecPlace{
		Text:      text,
		Scoped:    scoped,
		Prefix:    append([]string{}, segments...),
		SectionID: id,
		Slot:      slot,
	}
}

// ToJSON returns the parsed parts, for the corpus.
func (p *SpecPlace) ToJSON() map[string]any {
	out := map[string]any{
		"scoped":    p.Scoped,
		"prefix":    stringsJSON(p.Prefix),
		"sectionId": p.SectionID,
	}
	if p.Slot != "" {
		out["slot"] = p.Slot
	}
	return out
}

// String returns the place as written.
func (p *SpecPlace) String() string { return p.Text }

// Resolve resolves the place under anchor, a document path of a section (a
// root, a complex or section member, or a list item). It fails with a
// *SpecPlaceError when the place does not resolve.
//
// The place is looked for in the subtree of the anchor's class — beneath the
// nearest list element at or above the anchor when it is `./`-scoped — among
// the positions whose section id is SectionID and whose path holds the Prefix
// ids in order (only `-LST` containers and the scope's own id may lie between
// them). More than one such position is `ambiguous`.
func (p *SpecPlace) Resolve(refl *SpecReflection, anchor string) (*SpecPlaceResolution, error) {
	scope, err := placeScopeOf(refl, anchor, p.Scoped, p.Text)
	if err != nil {
		return nil, err
	}
	byPath := map[string]placePosition{}
	for _, pos := range placePositions(refl, scope) {
		if pos.node.id == p.SectionID && placePathMatches(pos.ids[:len(pos.ids)-1], p.Prefix) {
			byPath[pos.node.path] = pos
		}
	}
	if len(byPath) == 0 {
		return nil, &SpecPlaceError{
			Problem: SpecPlaceProblemUnresolved,
			Text:    p.Text,
			Message: "resolves to no section beneath " + scope.path,
		}
	}
	if len(byPath) > 1 {
		paths := make([]string, 0, len(byPath))
		for k := range byPath {
			paths = append(paths, k)
		}
		sort.Strings(paths)
		return nil, &SpecPlaceError{
			Problem: SpecPlaceProblemAmbiguous,
			Text:    p.Text,
			Message: "is ambiguous: " + p.SectionID + " is reached at " +
				strings.Join(paths, ", ") + " — write it as a `/` path",
		}
	}
	for _, pos := range byPath {
		return p.withSlot(pos)
	}
	return nil, nil // unreachable
}

func (p *SpecPlace) withSlot(pos placePosition) (*SpecPlaceResolution, error) {
	n := pos.node
	result := func(kind, path string, formField *FormFieldSpec) (*SpecPlaceResolution, error) {
		return &SpecPlaceResolution{
			Place:      p,
			Kind:       kind,
			Path:       path,
			ClassName:  n.className,
			SectionIDs: pos.ids,
			FormField:  formField,
		}, nil
	}
	slot := p.Slot
	switch {
	case slot == "":
		switch n.shape {
		case "list":
			return result(SpecPlaceKindList, n.path, nil)
		case "form":
			return result(SpecPlaceKindForm, n.path, nil)
		case "content":
			return result(SpecPlaceKindContent, n.path, nil)
		}
		return result(SpecPlaceKindSection, n.path, nil)
	case slot == "@headline":
		return result(SpecPlaceKindHeadline, n.path, nil)
	case slot == "@content":
		if n.contentPath == "" {
			return nil, &SpecPlaceError{
				Problem: SpecPlaceProblemNoContent,
				Text:    p.Text,
				Message: "names @content of " + p.SectionID + ", which holds no content value",
			}
		}
		return result(SpecPlaceKindContent, n.contentPath, nil)
	case slot == KSectionIDSlot:
		if !n.isListElement {
			return nil, &SpecPlaceError{
				Problem: SpecPlaceProblemNotListElement,
				Text:    p.Text,
				Message: "names @sectionId of " + p.SectionID + ", which is no list element",
			}
		}
		return result(SpecPlaceKindSectionID, n.path, nil)
	case strings.HasPrefix(slot, "@"):
		return nil, &SpecPlaceError{
			Problem: SpecPlaceProblemReservedSlot,
			Text:    p.Text,
			Message: "names the slot " + slot + " — \"@\" is reserved for @headline, " +
				"@content and @sectionId",
		}
	}
	var ff *FormFieldSpec
	for _, f := range n.formFields {
		if f.Name == slot {
			ff = f
			break
		}
	}
	if ff == nil || n.formPath == "" {
		return nil, &SpecPlaceError{
			Problem: SpecPlaceProblemNoSuchField,
			Text:    p.Text,
			Message: "names " + p.SectionID + "." + slot + ", which is no form field",
		}
	}
	return result(SpecPlaceKindFormField, n.formPath, ff)
}

// SpecPlaceResolution is where a place is stored in a document.
type SpecPlaceResolution struct {
	// Place is the place resolved.
	Place *SpecPlace
	// Kind is what the place is (a SpecPlaceKind constant).
	Kind string
	// Path is the document path the value lives at, with every list item
	// beneath the anchor written `<list>-*`: the section (or list item) for a
	// section, a headline or a section id; the list for a list; the form for a
	// form or a form field; the content leaf for a content value.
	Path string
	// ClassName is the class of the section the place sits on (for a member,
	// its owner).
	ClassName string
	// SectionIDs are the section ids on the way from the scope to the place,
	// the place's own last.
	SectionIDs []string
	// FormField is, for SpecPlaceKindFormField, the field; nil otherwise.
	FormField *FormFieldSpec
}

// Field returns the form field name for SpecPlaceKindFormField, else "".
func (r *SpecPlaceResolution) Field() string {
	if r.FormField == nil {
		return ""
	}
	return r.FormField.Name
}

// ToJSON is the canonical JSON form the corpus compares.
func (r *SpecPlaceResolution) ToJSON() map[string]any {
	out := map[string]any{"kind": r.Kind, "path": r.Path}
	if r.FormField != nil {
		out["field"] = r.FormField.Name
	}
	return out
}

// SpecPlaceFilter is an entry filter: `<SECTIONID>`, `./<SECTIONID>` or
// `<SECTIONID>.<field>=<value>[|<value>…]`, optionally `./`-scoped.
//
// It selects the entries (list elements of the class with that section id)
// one of whose own forms holds one of Values in Field; without a field every
// entry. `countOf` counts the entries it selects, a `where:` keeps the
// elements or rows it selects.
type SpecPlaceFilter struct {
	// Text is the text it was parsed from.
	Text string
	// Scoped is whether it is written `./…`: only the entries beneath the
	// nearest list element (for `countOf`: beneath the section holding the
	// form).
	Scoped bool
	// SectionID is the section id of the entries.
	SectionID string
	// Field is the form field compared, or "" for every entry.
	Field string
	// Values are the values accepted, in written order; empty exactly when
	// Field is "".
	Values []string
}

// ParseSpecPlaceFilter parses text; it fails with a *SpecPlaceError
// (`malformed`) when it is not a filter.
func ParseSpecPlaceFilter(text string) (*SpecPlaceFilter, error) {
	if f := TryParseSpecPlaceFilter(text); f != nil {
		return f, nil
	}
	return nil, &SpecPlaceError{
		Problem: SpecPlaceProblemMalformed,
		Text:    text,
		Message: "is not a filter (`<SECTIONID>[.<field>=<value>[|<value>…]]`, " +
			"optionally `./`-scoped)",
	}
}

// TryParseSpecPlaceFilter parses text, or returns nil when it is not a filter.
func TryParseSpecPlaceFilter(text string) *SpecPlaceFilter {
	scoped := strings.HasPrefix(text, "./")
	body := text
	if scoped {
		body = text[2:]
	}
	dot := strings.Index(body, ".")
	id := body
	if dot >= 0 {
		id = body[:dot]
	}
	if !placeSegmentRE.MatchString(id) {
		return nil
	}
	if dot < 0 {
		return &SpecPlaceFilter{Text: text, Scoped: scoped, SectionID: id, Values: []string{}}
	}
	eq := strings.Index(body[dot:], "=")
	if eq < 0 {
		return nil
	}
	eq += dot
	name := body[dot+1 : eq]
	if !placeFieldRE.MatchString(name) {
		return nil
	}
	values := strings.Split(body[eq+1:], "|")
	for _, v := range values {
		if v == "" {
			return nil
		}
	}
	return &SpecPlaceFilter{Text: text, Scoped: scoped, SectionID: id, Field: name, Values: values}
}

// Matches reports whether an entry whose Field holds stored (values trimmed,
// as many as its forms hold) is selected.
func (f *SpecPlaceFilter) Matches(stored []string) bool {
	if f.Field == "" {
		return true
	}
	for _, v := range stored {
		t := strings.TrimSpace(v)
		for _, want := range f.Values {
			if t == want {
				return true
			}
		}
	}
	return false
}

// matchesSet is Matches over a set of stored values.
func (f *SpecPlaceFilter) matchesSet(stored map[string]bool) bool {
	if f.Field == "" {
		return true
	}
	values := make([]string, 0, len(stored))
	for v := range stored {
		values = append(values, v)
	}
	return f.Matches(values)
}

// Place returns the place of the entries: SectionID, scoped as the filter is.
func (f *SpecPlaceFilter) Place() *SpecPlace {
	text := f.SectionID
	if f.Scoped {
		text = "./" + f.SectionID
	}
	return &SpecPlace{Text: text, Scoped: f.Scoped, Prefix: []string{}, SectionID: f.SectionID}
}

// Resolve resolves the entries under anchor as SpecPlace.Resolve does, and
// checks that Field is a field of one of the entry's own forms (a form member
// of the entry, or its content form). It fails with a *SpecPlaceError when it
// does not resolve.
func (f *SpecPlaceFilter) Resolve(refl *SpecReflection, anchor string) (*SpecPlaceResolution, error) {
	r, err := f.Place().Resolve(refl, anchor)
	if err != nil {
		if pe, ok := err.(*SpecPlaceError); ok {
			return nil, &SpecPlaceError{Problem: pe.Problem, Text: f.Text, Message: pe.Message}
		}
		return nil, err
	}
	if f.Field != "" {
		cls := refl.ClassNamed(r.ClassName)
		found := false
		if r.Kind == SpecPlaceKindSection && cls != nil {
			for _, field := range cls.Fields {
				if field.Kind != SpecFieldKindForm {
					continue
				}
				for _, ff := range field.FormFields {
					if ff.Name == f.Field {
						found = true
					}
				}
			}
		}
		if !found {
			return nil, &SpecPlaceError{
				Problem: SpecPlaceProblemNoSuchField,
				Text:    f.Text,
				Message: "names " + f.SectionID + "." + f.Field + ", which no form of " +
					f.SectionID + " holds",
			}
		}
	}
	return r, nil
}

// ToJSON returns the parsed parts, for the corpus.
func (f *SpecPlaceFilter) ToJSON() map[string]any {
	out := map[string]any{"scoped": f.Scoped, "sectionId": f.SectionID}
	if f.Field != "" {
		out["field"] = f.Field
		out["values"] = stringsJSON(f.Values)
	}
	return out
}

// String returns the filter as written.
func (f *SpecPlaceFilter) String() string { return f.Text }

// SpecSameAsBinding is a `@SameAs` copy at one position of a document root,
// with its holder.
type SpecSameAsBinding struct {
	// Root is the root the positions are in.
	Root string
	// ClassName is the class both positions hold.
	ClassName string
	// CopyPath is the copy's document path (list items written `<list>-*`).
	CopyPath string
	// CopySectionIDs is the copy's section-id path from the root.
	CopySectionIDs []string
	// HolderPath is the holder's document path, "" when Problem is set.
	HolderPath string
	// HolderSectionIDs is the holder's section-id path from the root, nil when
	// Problem is set.
	HolderSectionIDs []string
	// Problem is why no single holder was found: `unresolved` (no position
	// fits) or `ambiguous` (several do); "" when HolderPath is set.
	Problem string
}

// ToJSON is the canonical JSON form the corpus compares.
func (b SpecSameAsBinding) ToJSON() map[string]any {
	out := map[string]any{"root": b.Root, "className": b.ClassName, "copy": b.CopyPath}
	if b.HolderPath != "" {
		out["holder"] = b.HolderPath
	}
	if b.Problem != "" {
		out["problem"] = b.Problem
	}
	return out
}

// rootScope is the scope of the whole document root rootType, ok=false when
// the model has no such root or class.
func rootScope(refl *SpecReflection, rootType string) (placeScope, bool) {
	var root *SpecRoot
	for _, r := range refl.Model.Roots {
		if r.Type == rootType {
			root = r
			break
		}
	}
	cls := refl.ClassNamed(rootType)
	if root == nil || cls == nil {
		return placeScope{}, false
	}
	return placeScope{path: refl.RootSegment(root), cls: cls}, true
}

// SpecSameAsBindings returns every `@SameAs` copy the document root rootType
// reaches, each with its holder (`tom_specs_model_rules.md` §9.7, invariant
// `SAME-AS`): among the positions of the copy's class in the root that are no
// copy themselves, the one whose section-id path ends with `holder`, or —
// without `holder` — the one there is. In position order.
func SpecSameAsBindings(refl *SpecReflection, rootType string) []SpecSameAsBinding {
	out := []SpecSameAsBinding{}
	scope, ok := rootScope(refl, rootType)
	if !ok {
		return out
	}
	var sections []placePosition
	for _, p := range placePositions(refl, scope) {
		if p.node.shape == "section" && p.node.ownNode {
			sections = append(sections, p)
		}
	}
	for _, copyPos := range sections {
		if copyPos.member == nil {
			continue
		}
		sameAs := copyPos.member.SameAs()
		if sameAs == nil {
			continue
		}
		typ := copyPos.node.className
		var holderTail []string
		if sameAs.Holder != "" {
			holderTail = strings.Split(sameAs.Holder, "/")
		}
		var holders []placePosition
		for _, p := range sections {
			if p.node.className != typ {
				continue
			}
			if p.member != nil && p.member.SameAs() != nil {
				continue
			}
			if holderTail != nil && !placeEndsWith(p.ids, holderTail) {
				continue
			}
			holders = append(holders, p)
		}
		b := SpecSameAsBinding{
			Root:           rootType,
			ClassName:      typ,
			CopyPath:       copyPos.node.path,
			CopySectionIDs: copyPos.ids,
		}
		switch {
		case len(holders) == 0:
			b.Problem = SpecPlaceProblemUnresolved
		case len(holders) > 1:
			b.Problem = SpecPlaceProblemAmbiguous
		default:
			b.HolderPath = holders[0].node.path
			b.HolderSectionIDs = holders[0].ids
		}
		out = append(out, b)
	}
	return out
}

// SpecSectionPosition is one position of a section in a document root: a
// class reached there (its own node), or a member of a class that carries a
// section id of its own.
type SpecSectionPosition struct {
	// Path is the document path, list items written `<list>-*`.
	Path string
	// ClassName is the class reached (Member nil), or the class the member
	// belongs to.
	ClassName string
	// SectionIDs are the section ids from the root to here, this position's
	// own last.
	SectionIDs []string
	// IsMember is whether this is a member position (a form, list, content or
	// section member with its own section id) rather than a class reached.
	IsMember bool
	// Member is, for a class position, the member it is reached through (nil
	// at the root); for a member position, the member itself.
	Member *SpecField
}

// SpecSectionPositions returns every section position of the document root
// rootType, in walk order: a class reached again on its own path is not
// descended into, and a `@Reference` member's target is not walked.
func SpecSectionPositions(refl *SpecReflection, rootType string) []SpecSectionPosition {
	out := []SpecSectionPosition{}
	scope, ok := rootScope(refl, rootType)
	if !ok {
		return out
	}
	for _, p := range placePositions(refl, scope) {
		out = append(out, SpecSectionPosition{
			Path:       p.node.path,
			ClassName:  p.node.className,
			SectionIDs: p.ids,
			Member:     p.member,
			IsMember:   !p.node.ownNode,
		})
	}
	return out
}

// --- the positions of a subtree ----------------------------------------------

type placeScope struct {
	path          string
	cls           *SpecClass
	isListElement bool
}

type placeNode struct {
	id            string
	path          string
	className     string
	shape         string
	ownNode       bool
	formFields    []*FormFieldSpec
	formPath      string
	contentPath   string
	isListElement bool
}

type placePosition struct {
	node   placeNode
	ids    []string
	member *SpecField
}

// placeScopeOf is the scope a place is looked for in under anchor.
func placeScopeOf(refl *SpecReflection, anchor string, scoped bool, text string) (placeScope, error) {
	segs := SpecPathSegments(anchor)
	for n := len(segs); n > 0; n-- {
		path := strings.Join(segs[:n], "/")
		r := refl.Resolve(path)
		if n == len(segs) && (r == nil || r.TargetClass == nil) {
			return placeScope{}, &SpecPlaceError{
				Problem: SpecPlaceProblemAnchorUnresolved,
				Text:    text,
				Message: "has the anchor " + anchor + ", which resolves to no section",
			}
		}
		isItem := r != nil && r.Kind == SpecNodeKindListItemComplex
		if !scoped || isItem {
			// As in Dart (`r!.targetClass!`): an ancestor that resolves to no
			// class cannot be a scope.
			if r == nil || r.TargetClass == nil {
				return placeScope{}, &placeScopeError{path: path}
			}
			return placeScope{path: path, cls: r.TargetClass, isListElement: isItem}, nil
		}
	}
	return placeScope{}, &SpecPlaceError{
		Problem: SpecPlaceProblemNotScoped,
		Text:    text,
		Message: "is `./`-scoped, but no list element lies at or above " + anchor,
	}
}

// placeScopeError is an ancestor of an anchor that resolves to no class (the
// reference fails on it with a null check, not a place problem).
type placeScopeError struct{ path string }

func (e *placeScopeError) Error() string { return "no class at " + e.path }

// placeClassOf is the class a complex or section member reaches.
func placeClassOf(refl *SpecReflection, f *SpecField) *SpecClass {
	return refl.ClassNamed(strings.ReplaceAll(f.Type, "?", ""))
}

// placePositions returns every addressable position beneath (and including)
// scope, in model order. A class reached again on its own path is not
// descended into, and a `@Reference` member is a place whose target is not
// walked.
func placePositions(refl *SpecReflection, scope placeScope) []placePosition {
	var out []placePosition
	onPath := map[string]bool{}
	var walk func(cls *SpecClass, path string, ids []string, isItem bool, via *SpecField)
	walk = func(cls *SpecClass, path string, ids []string, isItem bool, via *SpecField) {
		if onPath[cls.Name] {
			return
		}
		onPath[cls.Name] = true
		content := cls.FieldNamed("content")
		here := ids
		if ownID := cls.SectionID; ownID != "" {
			here = appendID(ids, ownID)
			node := placeNode{
				id:            ownID,
				path:          path,
				className:     cls.Name,
				shape:         "section",
				ownNode:       true,
				formFields:    []*FormFieldSpec{},
				isListElement: isItem,
			}
			if content != nil {
				seg := path + "/" + refl.FieldSegment(content)
				switch content.Kind {
				case SpecFieldKindForm:
					node.formFields = content.FormFields
					node.formPath = seg
				case SpecFieldKindContent:
					node.contentPath = seg
				}
			}
			out = append(out, placePosition{node: node, ids: here, member: via})
		}
		for _, f := range cls.Fields {
			memberPath := path + "/" + refl.FieldSegment(f)
			below := here
			if sid := f.SectionID; f.Name != "content" && sid != "" {
				below = appendID(here, sid)
				var shape string
				switch f.Kind {
				case SpecFieldKindList:
					shape = "list"
				case SpecFieldKindForm:
					shape = "form"
				case SpecFieldKindComplex, SpecFieldKindSection:
					shape = "section"
				default:
					shape = "content"
				}
				node := placeNode{
					id:         sid,
					path:       memberPath,
					className:  cls.Name,
					shape:      shape,
					ownNode:    false,
					formFields: []*FormFieldSpec{},
				}
				if f.Kind == SpecFieldKindForm {
					node.formFields = f.FormFields
					node.formPath = memberPath
				}
				if shape == "content" {
					node.contentPath = memberPath
				}
				out = append(out, placePosition{node: node, ids: below, member: f})
			}
			if f.HasAnnotation("Reference") {
				continue
			}
			if f.Kind == SpecFieldKindList && f.ElementIsComplex {
				if el := refl.ClassNamed(f.ElementType); el != nil {
					walk(el, memberPath+"-*", below, true, f)
				}
			} else if f.Kind == SpecFieldKindComplex || f.Kind == SpecFieldKindSection {
				if child := placeClassOf(refl, f); child != nil {
					walk(child, memberPath, below, false, f)
				}
			}
		}
		delete(onPath, cls.Name)
	}
	walk(scope.cls, scope.path, []string{}, scope.isListElement, nil)
	return out
}

// appendID returns ids with id appended, never sharing ids's backing array.
func appendID(ids []string, id string) []string {
	out := make([]string, len(ids), len(ids)+1)
	copy(out, ids)
	return append(out, id)
}

// placePathMatches reports whether the `/` segments lead to a position whose
// ancestors are path: they name every section on the way, leaving out only
// `-LST` containers and the scope's own id. No segments: any position.
func placePathMatches(path, segments []string) bool {
	if len(segments) == 0 {
		return true
	}
	from := func(start int) bool {
		j := 0
		for i := start; i < len(path); i++ {
			if j < len(segments) && path[i] == segments[j] {
				j++
			} else if !strings.HasSuffix(path[i], "-LST") {
				return false
			}
		}
		return j == len(segments)
	}
	return from(0) || (len(path) > 0 && from(1))
}

// placeEndsWith reports whether path ends with exactly the ids of tail, as the
// static validator's `SAME-AS` reads a holder.
func placeEndsWith(path, tail []string) bool {
	if len(path) < len(tail) {
		return false
	}
	off := len(path) - len(tail)
	for i, t := range tail {
		if path[off+i] != t {
			return false
		}
	}
	return true
}
