package somruntime

// spec_document.go — a sparse, live instance of a TomSpecs document, a faithful
// port of `tom_som_dart_runtime/lib/src/spec_document.dart` (and the TypeScript
// `spec_document.ts`).
//
// The structure is defined by the SpecModel class graph; this holds only the
// values the user/agent has actually set, keyed by the globally-unique
// section-ID path. Nothing is materialised until written, so an untouched
// document is empty (the "empty = no value" rule).
//
// Four sparse stores cover the writable field kinds:
//
//   - content — content/scalar leaves: path → string value;
//   - form — @Form sections: path → (form-field name → value);
//   - listItems — lists: list path → ordered item paths;
//   - headline — stored headlines (YRD3): path → heading text, present only
//     when it differs from the derived default.
//
// List item paths are "<listPath>-<seq>" where seq is a per-list monotonic
// counter that never reuses a number.

import (
	"fmt"
	"os"
	"regexp"
	"sort"
	"strings"
)

// ListJson is the plain-data shape of a single list store entry. Ids maps an
// item path to its assigned section id; it is present only for lists that carry
// section ids (AA1 criteria 3–6).
type ListJson struct {
	Seq   int               `json:"seq"`
	Items []string          `json:"items"`
	Ids   map[string]string `json:"ids,omitempty"`
}

// DocumentJson is a SpecDocument.ToJSON-shaped plain-data view of a document.
// Only non-empty stores are populated.
type DocumentJson struct {
	Content   map[string]string            `json:"content,omitempty"`
	Forms     map[string]map[string]string `json:"forms,omitempty"`
	Lists     map[string]ListJson          `json:"lists,omitempty"`
	Headlines map[string]string            `json:"headlines,omitempty"`
	CodeSpecs map[string]string            `json:"codeSpecs,omitempty"`
}

// SpecDocument is the sparse in-memory document.
//
// Each list item also carries a **section id** (AA1 criteria 3–6): the
// document-semantic identity generated from the list field's @SectionIdPattern.
// This is distinct from the internal "-<seq>" path key: the seq path keeps
// nested values attached across edits (never renumbered), while the section id
// is what the document exposes and may be overridden (SetItemSectionID,
// criterion 5) or reused same-day after the last item is deleted (criterion 6).
// Section ids live in itemSectionID, keyed by the internal item path.
type SpecDocument struct {
	content       map[string]string
	form          map[string]map[string]string
	listItems     map[string][]string
	listSeq       map[string]int
	itemSectionID map[string]string
	headline      map[string]string
	// codeSpec is the concrete instance-level forward DocSpecs→CodeSpecs link
	// (codespecs_mapping.md §9.2): any section path → the comma-joined list of
	// CodeSpecs code locations that section maps to. Sparse like headline: unset
	// means "no code mapping".
	codeSpec map[string]string

	// ModelVersion is the authoring object-model version (major.minor) this
	// document was loaded from, or "" for a brand-new / unstamped document. Go's
	// idiomatic nullable string is the empty string, matching DecodeYaml's
	// SpecYamlContents.ModelVersion and CheckSomModelVersion's documentVersion.
	// It is retained here by FromYaml so a consumer need not thread
	// decoded.ModelVersion to the typed facade by hand (the "forgot the stamp"
	// class of bug); the generated LoadYaml / LoadFile funcs apply it
	// automatically.
	ModelVersion string
}

// NewSpecDocument returns an empty document.
func NewSpecDocument() *SpecDocument {
	return &SpecDocument{
		content:       map[string]string{},
		form:          map[string]map[string]string{},
		listItems:     map[string][]string{},
		listSeq:       map[string]int{},
		itemSectionID: map[string]string{},
		headline:      map[string]string{},
		codeSpec:      map[string]string{},
	}
}

// FromYaml loads a hierarchical `*.docspecs.yaml` document in one call: decode
// the YAML against the document's metadata tree (SOM §12) and retain the parsed
// ModelVersion on the document. Collapses the former DecodeYaml →
// thread-documentVersion incantation (SOM §21). Format problems surface as a
// *SpecYamlFormatException.
func FromYaml(yaml string, tree *SomMetaTree) (*SpecDocument, error) {
	decoded, err := DecodeYaml(yaml, tree)
	if err != nil {
		return nil, err
	}
	return decoded.Document, nil
}

// FromFile loads a `*.docspecs.yaml` document from the file at path — the file
// companion to FromYaml the generated LoadFile funcs delegate to. A read error
// is returned to the caller (Go has no exceptions).
func FromFile(path string, tree *SomMetaTree) (*SpecDocument, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	return FromYaml(string(data), tree)
}

func (d *SpecDocument) ensure() {
	if d.content == nil {
		d.content = map[string]string{}
	}
	if d.form == nil {
		d.form = map[string]map[string]string{}
	}
	if d.listItems == nil {
		d.listItems = map[string][]string{}
	}
	if d.listSeq == nil {
		d.listSeq = map[string]int{}
	}
	if d.itemSectionID == nil {
		d.itemSectionID = map[string]string{}
	}
	if d.headline == nil {
		d.headline = map[string]string{}
	}
	if d.codeSpec == nil {
		d.codeSpec = map[string]string{}
	}
}

// --- content ---------------------------------------------------------------

// Content returns the content string at path, and ok=false when unset.
func (d *SpecDocument) Content(path string) (string, bool) {
	v, ok := d.content[path]
	return v, ok
}

// ContentOr returns the content string at path, or "" when unset.
func (d *SpecDocument) ContentOr(path string) string {
	return d.content[path]
}

// HasContent reports whether a non-empty content-leaf value exists at exactly
// path (leaf-exact; a value nested under path does not count). It is the
// null-free companion to ContentOr. (SOM §21.)
func (d *SpecDocument) HasContent(path string) bool {
	return d.ContentOr(path) != ""
}

// SetContent sets the content string at path. An empty value clears it.
func (d *SpecDocument) SetContent(path, value string) {
	d.ensure()
	if value == "" {
		delete(d.content, path)
	} else {
		d.content[path] = value
	}
}

// --- forms -----------------------------------------------------------------

// FormField returns form fieldName at path, and ok=false when unset.
func (d *SpecDocument) FormField(path, fieldName string) (string, bool) {
	fields, ok := d.form[path]
	if !ok {
		return "", false
	}
	v, ok := fields[fieldName]
	return v, ok
}

// FormFieldOr returns form fieldName at path, or "" when unset.
func (d *SpecDocument) FormFieldOr(path, fieldName string) string {
	if fields, ok := d.form[path]; ok {
		return fields[fieldName]
	}
	return ""
}

// SetFormField sets form fieldName at path. An empty value clears that field
// (and the whole form entry once its last field is gone).
func (d *SpecDocument) SetFormField(path, fieldName, value string) {
	d.ensure()
	if value == "" {
		if fields, ok := d.form[path]; ok {
			delete(fields, fieldName)
			if len(fields) == 0 {
				delete(d.form, path)
			}
		}
		return
	}
	fields, ok := d.form[path]
	if !ok {
		fields = map[string]string{}
		d.form[path] = fields
	}
	fields[fieldName] = value
}

// --- headlines (YRD3) --------------------------------------------------------

// Headline returns the stored headline at path, and ok=false when none is
// stored (the effective heading then falls back to the derived default).
func (d *SpecDocument) Headline(path string) (string, bool) {
	v, ok := d.headline[path]
	return v, ok
}

// HeadlineOr returns the stored headline at path, or "" when none is stored.
func (d *SpecDocument) HeadlineOr(path string) string {
	return d.headline[path]
}

// SetHeadline sets the stored headline at path. An empty value clears it
// (reverting the section to its derived default heading).
func (d *SpecDocument) SetHeadline(path, value string) {
	d.ensure()
	if value == "" {
		delete(d.headline, path)
	} else {
		d.headline[path] = value
	}
}

// HeadlinePaths returns the set of paths carrying a stored headline (unordered).
func (d *SpecDocument) HeadlinePaths() []string {
	out := make([]string, 0, len(d.headline))
	for k := range d.headline {
		out = append(out, k)
	}
	return out
}

// --- codeSpec (codespecs_mapping.md §9.2)
// --------------------------------------------------------

// CodeSpec returns the stored codeSpec mapping at path (the comma-joined list
// of CodeSpecs code locations), and ok=false when the section carries no
// mapping (codespecs_mapping.md §9.2 — codeSpec is sparse like the headline).
func (d *SpecDocument) CodeSpec(path string) (string, bool) {
	v, ok := d.codeSpec[path]
	return v, ok
}

// CodeSpecOr returns the stored codeSpec mapping at path, or "" when none.
func (d *SpecDocument) CodeSpecOr(path string) string {
	return d.codeSpec[path]
}

// SetCodeSpec sets the stored codeSpec mapping at path (the comma-joined list
// of CodeSpecs code locations). An empty value clears it, returning the section
// to "no code mapping" (codespecs_mapping.md §9.2).
func (d *SpecDocument) SetCodeSpec(path, value string) {
	d.ensure()
	if value == "" {
		delete(d.codeSpec, path)
	} else {
		d.codeSpec[path] = value
	}
}

// CodeSpecPaths returns the set of paths carrying a stored codeSpec mapping
// (unordered).
func (d *SpecDocument) CodeSpecPaths() []string {
	out := make([]string, 0, len(d.codeSpec))
	for k := range d.codeSpec {
		out = append(out, k)
	}
	return out
}

// --- lists -----------------------------------------------------------------

// ListItems returns a copy of the item paths of the list at listPath.
func (d *SpecDocument) ListItems(listPath string) []string {
	items := d.listItems[listPath]
	out := make([]string, len(items))
	copy(out, items)
	return out
}

// AddListItem appends a new item to the list at listPath and returns its stable
// path.
func (d *SpecDocument) AddListItem(listPath string) string {
	d.ensure()
	seq := d.listSeq[listPath] + 1
	d.listSeq[listPath] = seq
	itemPath := listPath + "-" + itoa(seq)
	d.listItems[listPath] = append(d.listItems[listPath], itemPath)
	return itemPath
}

// AddListItemWithSectionID appends a new item to the list at listPath, assigns
// it the given section id, and returns its stable path. The id is checked for
// uniqueness against the list's other items (AA1 criterion 5); a collision
// returns a *SpecSectionIDCollision and leaves the document untouched. Section
// id *generation* from a @SectionIdPattern lives in the caller (it needs the
// pattern); this layer only stores and guards uniqueness.
func (d *SpecDocument) AddListItemWithSectionID(listPath, sectionID string) (string, error) {
	d.ensure()
	if err := d.assertSectionIDFree(listPath, sectionID, ""); err != nil {
		return "", err
	}
	itemPath := d.AddListItem(listPath)
	d.itemSectionID[itemPath] = sectionID
	return itemPath, nil
}

// ItemSectionID returns the section id assigned to the list item at itemPath,
// with ok=false when none has been set (AA1 criterion 1 read path).
func (d *SpecDocument) ItemSectionID(itemPath string) (string, bool) {
	id, ok := d.itemSectionID[itemPath]
	return id, ok
}

// ItemSectionIDOr returns the section id assigned to itemPath, or "" when none.
func (d *SpecDocument) ItemSectionIDOr(itemPath string) string {
	return d.itemSectionID[itemPath]
}

// SetItemSectionID overrides the section id of the list item at itemPath (AA1
// criterion 5). It validates that the new id is unique among the *other* items
// of the same owning list; a collision returns a *SpecSectionIDCollision.
// Assigning an id equal to the item's current id is a no-op. Returns an error if
// itemPath is not a live list item.
func (d *SpecDocument) SetItemSectionID(itemPath, id string) error {
	d.ensure()
	owningList, ok := d.owningListOf(itemPath)
	if !ok {
		return errNotLiveItem(itemPath)
	}
	if cur, has := d.itemSectionID[itemPath]; has && cur == id {
		return nil
	}
	if err := d.assertSectionIDFree(owningList, id, itemPath); err != nil {
		return err
	}
	d.itemSectionID[itemPath] = id
	return nil
}

// ListItemSectionIDs returns the section ids currently assigned within the list
// at listPath, in item order (items without an id are skipped). Feeds both id
// generation (existingIDs) and uniqueness checks.
func (d *SpecDocument) ListItemSectionIDs(listPath string) []string {
	items := d.listItems[listPath]
	out := make([]string, 0, len(items))
	for _, itemPath := range items {
		if id, ok := d.itemSectionID[itemPath]; ok {
			out = append(out, id)
		}
	}
	return out
}

// owningListOf returns the listItems entry that owns itemPath, with ok=false
// when none does.
func (d *SpecDocument) owningListOf(itemPath string) (string, bool) {
	for key, items := range d.listItems {
		for _, it := range items {
			if it == itemPath {
				return key, true
			}
		}
	}
	return "", false
}

// assertSectionIDFree returns a *SpecSectionIDCollision when id is already used
// by an item of listPath other than exceptItemPath ("" for none).
func (d *SpecDocument) assertSectionIDFree(listPath, id, exceptItemPath string) error {
	for _, itemPath := range d.listItems[listPath] {
		if itemPath == exceptItemPath {
			continue
		}
		if cur, ok := d.itemSectionID[itemPath]; ok && cur == id {
			return &SpecSectionIDCollision{ID: id, ListPath: listPath}
		}
	}
	return nil
}

// MoveListItem moves the list item at itemPath to position toIndex (0-based) of
// its list, or of toList, another list of the same element class (vsctsa44).
// toList "" means the item's own list.
//
// A path is a position, the section id is the identity. Every affected list is
// renumbered to `<list>-1 … <list>-n` in its new order, and every value under
// each item — content, forms, nested lists, headline, code-spec, stored id —
// travels with it. An anonymous item whose positional id would change has its
// old id stored, so its identity survives the renumbering. The result maps
// every old item path to its new one; a caller holding anything else keyed by
// path (the `review:` pass) re-keys it with RekeyReview.
//
// Across lists, the destination must hold the same element class, and an item
// with a stored id keeps it only when the id fits the destination's
// `@SectionIdPattern` and is free there. Every refusal changes nothing: a
// *SpecListMoveArgumentError (not a live list item, not a model list, another
// element class, an id not fitting the destination pattern), a
// *SpecSectionIDCollision (the stored id is taken in the destination), or a
// *SpecListMoveRangeError (toIndex outside 0..len(destination without the
// item)). An anonymous item takes its positional id in the destination.
func (d *SpecDocument) MoveListItem(
	model *SpecModel, itemPath string, toIndex int, toList string,
) (*SpecListItemMove, error) {
	d.ensure()
	item := itemPath
	from, ok := d.owningListOf(item)
	if !ok {
		return nil, &SpecListMoveArgumentError{
			Name: "itemPath", Value: itemPath, Message: "not a live list item",
		}
	}
	to := from
	if toList != "" {
		to = toList
	}
	refl := NewSpecReflection(model)
	var fromField, toField *SpecField
	if res := refl.Resolve(from); res != nil {
		fromField = res.Field
	}
	if res := refl.Resolve(to); res != nil {
		toField = res.Field
	}
	if toField == nil || toField.Kind != SpecFieldKindList {
		return nil, &SpecListMoveArgumentError{
			Name: "toList", Value: toList, Message: "not a list of the model",
		}
	}
	fromElement := ""
	if fromField != nil {
		fromElement = fromField.ElementType
	}
	if to != from && toField.ElementType != fromElement {
		return nil, &SpecListMoveArgumentError{
			Name:  "toList",
			Value: toList,
			Message: "holds " + toField.ElementType + ", but the item is a " +
				fromElement + " — an item moves only between lists of its own " +
				"element class",
		}
	}
	storedID, hasStored := d.itemSectionID[item]
	if to != from && hasStored {
		pattern := toField.SectionIDPattern
		if pattern != "" && !sectionIDFitsPattern(pattern, storedID) {
			return nil, &SpecListMoveArgumentError{
				Name:  "itemPath",
				Value: storedID,
				Message: "section id does not fit the destination pattern " +
					pattern + " — set an id that does before moving the item",
			}
		}
		if err := d.assertSectionIDFree(to, storedID, ""); err != nil {
			return nil, err
		}
	}

	// The new orders.
	fromItems := []string{}
	for _, p := range d.listItems[from] {
		if p != item {
			fromItems = append(fromItems, p)
		}
	}
	var toItems []string
	if to == from {
		toItems = fromItems
	} else {
		toItems = append([]string{}, d.listItems[to]...)
	}
	if toIndex < 0 || toIndex > len(toItems) {
		return nil, &SpecListMoveRangeError{Index: toIndex, Max: len(toItems)}
	}
	toItems = append(toItems, "")
	copy(toItems[toIndex+1:], toItems[toIndex:])
	toItems[toIndex] = item
	if to == from {
		fromItems = toItems
	}

	fieldOf := func(list string) *SpecField {
		if list == from {
			return fromField
		}
		return toField
	}
	patternOf := func(list string) string {
		if f := fieldOf(list); f != nil {
			return f.SectionIDPattern
		}
		return ""
	}
	stemOf := func(list string) string {
		if f := fieldOf(list); f != nil {
			return f.Name
		}
		segs := strings.Split(list, "/")
		return segs[len(segs)-1]
	}

	// Each affected item's effective id before the move, so an anonymous item
	// keeps its identity when its position changes.
	before := map[string]string{}
	listsBefore := []string{from}
	if to != from {
		listsBefore = append(listsBefore, to)
	}
	for _, list := range listsBefore {
		for i, p := range d.listItems[list] {
			id, has := d.itemSectionID[p]
			before[p] = EffectiveListItemSectionID(
				id, has, patternOf(list), i+1, stemOf(list))
		}
	}

	// Old → new item paths (in move order: the source list, then the
	// destination), and the ids anonymous items must now store.
	var renamed []listItemRename
	var pinned []listItemRename
	renumber := func(list string, items []string) {
		for i, old := range items {
			now := list + "-" + itoa(i+1)
			if old != now {
				renamed = append(renamed, listItemRename{old: old, now: now})
			}
			crossing := old == item && to != from
			if _, has := d.itemSectionID[old]; has || crossing {
				continue
			}
			positional := EffectiveListItemSectionID(
				"", false, patternOf(list), i+1, stemOf(list))
			if positional != before[old] {
				pinned = append(pinned, listItemRename{old: old, now: before[old]})
			}
		}
	}
	renumber(from, fromItems)
	if to != from {
		renumber(to, toItems)
	}

	remap := func(key string) string { return rekeyPath(key, renamed) }
	rekeyStrings := func(store map[string]string) map[string]string {
		out := make(map[string]string, len(store))
		for k, v := range store {
			out[remap(k)] = v
		}
		return out
	}

	content := rekeyStrings(d.content)
	headline := rekeyStrings(d.headline)
	codeSpec := rekeyStrings(d.codeSpec)
	ids := rekeyStrings(d.itemSectionID)
	for _, p := range pinned {
		ids[remap(p.old)] = p.now
	}
	form := make(map[string]map[string]string, len(d.form))
	for k, v := range d.form {
		form[remap(k)] = v
	}
	seq := make(map[string]int, len(d.listSeq))
	for k, v := range d.listSeq {
		seq[remap(k)] = v
	}
	remapAll := func(items []string) []string {
		out := make([]string, len(items))
		for i, p := range items {
			out[i] = remap(p)
		}
		return out
	}
	lists := make(map[string][]string, len(d.listItems))
	for k, v := range d.listItems {
		lists[remap(k)] = remapAll(v)
	}
	lists[remap(from)] = remapAll(fromItems)
	seq[remap(from)] = len(fromItems)
	if to != from {
		lists[remap(to)] = remapAll(toItems)
		seq[remap(to)] = len(toItems)
	}
	for k, v := range lists {
		if len(v) == 0 {
			delete(lists, k)
		}
	}

	d.content = content
	d.form = form
	d.headline = headline
	d.codeSpec = codeSpec
	d.itemSectionID = ids
	d.listSeq = seq
	d.listItems = lists

	result := &SpecListItemMove{
		Path:      remap(item),
		Renamed:   map[string]string{},
		PinnedIDs: map[string]string{},
	}
	for _, r := range renamed {
		result.Renamed[r.old] = r.now
	}
	for _, p := range pinned {
		result.PinnedIDs[remap(p.old)] = p.now
	}
	return result, nil
}

// SpecListItemMove is the result of SpecDocument.MoveListItem.
type SpecListItemMove struct {
	// Path is the moved item's path after the move.
	Path string `json:"path"`
	// Renamed holds every item path the move changed, old → new: the moved
	// item and each sibling whose position moved. Values under a renamed item
	// moved with it.
	Renamed map[string]string `json:"renamed"`
	// PinnedIDs holds the items (by new path) that were anonymous and now
	// store the id they had by position, so their identity did not change with
	// their position.
	PinnedIDs map[string]string `json:"pinnedIds"`
}

// SpecListMoveArgumentError is returned by MoveListItem for a move it refuses
// on its arguments: not a live list item, a toList that is not a list of the
// model or holds another element class, or a stored id that does not fit the
// destination's @SectionIdPattern. Nothing was changed.
type SpecListMoveArgumentError struct {
	// Name is the argument at fault (`itemPath` or `toList`).
	Name string
	// Value is the offending value.
	Value string
	// Message says what is wrong with it.
	Message string
}

// Error implements the error interface.
func (e *SpecListMoveArgumentError) Error() string {
	return fmt.Sprintf("Invalid argument (%s): %s: %q", e.Name, e.Message, e.Value)
}

// SpecListMoveRangeError is returned by MoveListItem when toIndex lies outside
// 0..Max, Max being the destination's length without the moved item. Nothing
// was changed.
type SpecListMoveRangeError struct {
	Index int
	Max   int
}

// Error implements the error interface.
func (e *SpecListMoveRangeError) Error() string {
	return "RangeError (toIndex): Invalid value: Not in inclusive range 0.." +
		itoa(e.Max) + ": " + itoa(e.Index)
}

// listItemRename is one old → new pair, kept in a slice so the first-match
// rule of rekeyPath follows the move order as the reference's ordered map does.
type listItemRename struct{ old, now string }

// rekeyPath returns key with the first old path of renamed it equals or lies
// under (`old`, `old/…`, `old-…`) replaced by its new path; key itself when it
// lies under none.
func rekeyPath(key string, renamed []listItemRename) string {
	for _, r := range renamed {
		if key == r.old {
			return r.now
		}
		if hasPrefix(key, r.old+"/") || hasPrefix(key, r.old+"-") {
			return r.now + key[len(r.old):]
		}
	}
	return key
}

// sectionIDFitsPattern reports whether id fits the @SectionIdPattern pattern —
// its `xxx` placeholder standing for one or more characters, the whole id
// matched.
func sectionIDFitsPattern(pattern, id string) bool {
	parts := strings.Split(pattern, "xxx")
	for i, p := range parts {
		parts[i] = regexp.QuoteMeta(p)
	}
	return regexp.MustCompile("^" + strings.Join(parts, ".+") + "$").MatchString(id)
}

// RemoveListItem removes the list item at itemPath along with every value nested
// beneath it. The counter is left untouched so future items keep getting fresh
// sequence numbers (no renumbering). Returns whether an item was removed.
func (d *SpecDocument) RemoveListItem(itemPath string) bool {
	owningList := ""
	found := false
	for key, items := range d.listItems {
		for _, it := range items {
			if it == itemPath {
				owningList = key
				found = true
				break
			}
		}
		if found {
			break
		}
	}
	if !found {
		return false
	}
	items := d.listItems[owningList]
	at := -1
	for i, it := range items {
		if it == itemPath {
			at = i
			break
		}
	}
	items = append(items[:at], items[at+1:]...)
	if len(items) == 0 {
		delete(d.listItems, owningList)
	} else {
		d.listItems[owningList] = items
	}
	d.purgeUnder(itemPath)
	return true
}

func isUnder(key, prefix string) bool {
	return key == prefix ||
		hasPrefix(key, prefix+"/") ||
		hasPrefix(key, prefix+"-")
}

func hasPrefix(s, prefix string) bool {
	return len(s) >= len(prefix) && s[:len(prefix)] == prefix
}

func (d *SpecDocument) purgeUnder(prefix string) {
	for k := range d.content {
		if isUnder(k, prefix) {
			delete(d.content, k)
		}
	}
	for k := range d.form {
		if isUnder(k, prefix) {
			delete(d.form, k)
		}
	}
	for k := range d.listItems {
		if isUnder(k, prefix) {
			delete(d.listItems, k)
		}
	}
	for k := range d.listSeq {
		if isUnder(k, prefix) {
			delete(d.listSeq, k)
		}
	}
	for k := range d.itemSectionID {
		if isUnder(k, prefix) {
			delete(d.itemSectionID, k)
		}
	}
	for k := range d.headline {
		if isUnder(k, prefix) {
			delete(d.headline, k)
		}
	}
	for k := range d.codeSpec {
		if isUnder(k, prefix) {
			delete(d.codeSpec, k)
		}
	}
}

// RemoveValuesUnder drops every value at prefix or nested beneath it — content,
// form entries, list items (with their nested values, ids and counters), and
// stored headlines (YRD7 generic modification API: "clear section").
//
// The predicate is the same one HasValuesUnder uses, so after this call
// HasValuesUnder(prefix) is false. Note this clears *values under a section
// path*; removing a single list item from its owning list is RemoveListItem.
func (d *SpecDocument) RemoveValuesUnder(prefix string) { d.purgeUnder(prefix) }

// errNotLiveItem describes an attempt to set a section id on a path that is not
// a live list item.
func errNotLiveItem(itemPath string) error {
	return &notLiveItemError{itemPath: itemPath}
}

type notLiveItemError struct{ itemPath string }

func (e *notLiveItemError) Error() string {
	return "'" + e.itemPath + "' is not a live list item"
}

// --- markdown --------------------------------------------------------------

// SpecDocumentFromMarkdown loads a DocSpecs Markdown document into a fresh
// document in one call: parse against model, then ApplyMarkdownResult.
//
// Blocks the parser rejects are not loaded, and are returned with the document
// (SpecMarkdownImport.Rejections), so a caller can show them or refuse to save:
// re-exporting a document whose source had rejections drops those blocks for
// good. The error return is reserved for a failed apply and is nil in practice,
// because rejections are allowed here.
func SpecDocumentFromMarkdown(text string, model *SpecModel) (*SpecMarkdownImport, error) {
	document := NewSpecDocument()
	result := NewSpecDocumentMarkdown(model, document).Parse(text)
	if err := document.ApplyMarkdownResult(result, true); err != nil {
		return nil, err
	}
	return &SpecMarkdownImport{Document: document, Result: result}, nil
}

// ApplyMarkdownResult applies a parsed Markdown import as a **full overwrite**
// of the roots it covers (SOM §11.7): every value under each of
// result.RootPrefixes is removed, then the parsed content, forms, lists,
// headlines and codeSpecs are written. Other roots are left as they are.
//
// A result with rejections is refused with an error — and the document left
// unchanged — unless allowRejections is true: the blocks it rejected would
// otherwise vanish from a document the caller believes it imported whole.
//
// Store-agnostic on both halves: the purge goes through RemoveValuesUnder,
// which clears every store, and the carry-over is whatever ToJSON emits. This
// port has no path normalizer, so parsed paths are written as they are.
func (d *SpecDocument) ApplyMarkdownResult(result *SpecMarkdownResult, allowRejections bool) error {
	if result == nil {
		return nil
	}
	if !allowRejections && len(result.Rejections) > 0 {
		first := result.Rejections[0]
		return fmt.Errorf(
			"markdown import has %d rejected block(s); first at line %d: %s",
			len(result.Rejections), first.Line, first.Message)
	}
	if len(result.RootPrefixes) == 0 {
		return nil
	}
	for prefix := range result.RootPrefixes {
		d.RemoveValuesUnder(prefix)
	}

	held := d.ToJSON()
	merged := &DocumentJson{
		Content:   map[string]string{},
		Forms:     map[string]map[string]string{},
		Lists:     map[string]ListJson{},
		Headlines: map[string]string{},
		CodeSpecs: map[string]string{},
	}
	for k, v := range held.Content {
		merged.Content[k] = v
	}
	for k, v := range result.Content {
		merged.Content[k] = v
	}
	for k, v := range held.Forms {
		merged.Forms[k] = v
	}
	for k, v := range result.Forms {
		merged.Forms[k] = v
	}
	for k, v := range held.Lists {
		merged.Lists[k] = v
	}
	for k, spec := range result.Lists {
		items := make([]string, len(spec.Items))
		copy(items, spec.Items)
		entry := ListJson{Seq: spec.Seq, Items: items}
		if spec.Ids != nil {
			ids := map[string]string{}
			for itemPath, id := range spec.Ids {
				ids[itemPath] = id
			}
			entry.Ids = ids
		}
		merged.Lists[k] = entry
	}
	for k, v := range held.Headlines {
		merged.Headlines[k] = v
	}
	for k, v := range result.Headlines {
		merged.Headlines[k] = v
	}
	for k, v := range held.CodeSpecs {
		merged.CodeSpecs[k] = v
	}
	for k, v := range result.CodeSpecs {
		merged.CodeSpecs[k] = v
	}
	d.LoadJSON(merged)
	return nil
}

// ToMarkdown renders this document to Markdown in one call (SOM §21).
//
// It collapses the former
// `NewSpecDocumentMarkdown(model, doc).ExportRoot(model.RootByType(…))`
// incantation. An empty rootType ("") means "omitted": the document's single
// populated root is used — a root is populated when it has any value beneath its
// segment (HasValuesUnder). When rootType is non-empty that root is exported
// (via SpecModel.RootByType). Returns an error when the default is ambiguous —
// zero populated roots, or more than one — so the caller names rootType.
func (d *SpecDocument) ToMarkdown(model *SpecModel, rootType string) (string, error) {
	var root *SpecRoot
	var err error
	if rootType != "" {
		root, err = model.RootByType(rootType)
	} else {
		root, err = d.singlePopulatedRoot(model)
	}
	if err != nil {
		return "", err
	}
	return NewSpecDocumentMarkdown(model, d).ExportRoot(root)
}

// singlePopulatedRoot returns the one root under which this document holds any
// value, for ToMarkdown's default. It returns an error when zero or more than
// one root is populated.
func (d *SpecDocument) singlePopulatedRoot(model *SpecModel) (*SpecRoot, error) {
	populated := make([]*SpecRoot, 0, len(model.Roots))
	for _, r := range model.Roots {
		section := r.SectionID
		if section == "" {
			section = r.Type
		}
		if d.HasValuesUnder(section) {
			populated = append(populated, r)
		}
	}
	if len(populated) == 1 {
		return populated[0], nil
	}
	if len(populated) == 0 {
		return nil, &noPopulatedRootError{}
	}
	types := make([]string, 0, len(populated))
	for _, r := range populated {
		types = append(types, r.Type)
	}
	return nil, &ambiguousRootError{types: types}
}

type noPopulatedRootError struct{}

func (e *noPopulatedRootError) Error() string {
	return "document has no populated root to export; pass rootType to choose one"
}

type ambiguousRootError struct{ types []string }

func (e *ambiguousRootError) Error() string {
	return "document has " + itoa(len(e.types)) + " populated roots (" +
		strings.Join(e.types, ", ") + "); pass rootType to choose one"
}

// --- queries ---------------------------------------------------------------

// IsEmpty reports whether the document holds no values at all.
func (d *SpecDocument) IsEmpty() bool {
	return len(d.content) == 0 && len(d.form) == 0 && len(d.listItems) == 0 &&
		len(d.headline) == 0 && len(d.codeSpec) == 0
}

// HasValuesUnder reports whether any value exists at prefix or nested beneath it
// — the structural "empty = no value" test (the exact inverse of the purge
// predicate, so emptiness and purge stay in lock-step).
func (d *SpecDocument) HasValuesUnder(prefix string) bool {
	for k := range d.content {
		if isUnder(k, prefix) {
			return true
		}
	}
	for k := range d.form {
		if isUnder(k, prefix) {
			return true
		}
	}
	for k := range d.listItems {
		if isUnder(k, prefix) {
			return true
		}
	}
	for k := range d.headline {
		if isUnder(k, prefix) {
			return true
		}
	}
	for k := range d.codeSpec {
		if isUnder(k, prefix) {
			return true
		}
	}
	return false
}

// ContentPaths returns the set of content paths (unordered).
func (d *SpecDocument) ContentPaths() []string {
	out := make([]string, 0, len(d.content))
	for k := range d.content {
		out = append(out, k)
	}
	return out
}

// FormPaths returns the set of form paths (unordered).
func (d *SpecDocument) FormPaths() []string {
	out := make([]string, 0, len(d.form))
	for k := range d.form {
		out = append(out, k)
	}
	return out
}

// ListPaths returns the set of list paths (unordered).
func (d *SpecDocument) ListPaths() []string {
	out := make([]string, 0, len(d.listItems))
	for k := range d.listItems {
		out = append(out, k)
	}
	return out
}

// FormFieldNames returns the field names set at a form path (unordered).
func (d *SpecDocument) FormFieldNames(path string) []string {
	fields := d.form[path]
	out := make([]string, 0, len(fields))
	for k := range fields {
		out = append(out, k)
	}
	return out
}

// ListItemCount returns the number of items in the list at listPath.
func (d *SpecDocument) ListItemCount(listPath string) int {
	return len(d.listItems[listPath])
}

// --- persistence -----------------------------------------------------------

// ToJSON returns a plain-data view of every value held, for persistence. Only
// non-empty stores are included; each map carries the full values (callers that
// need byte-stable ordering sort keys at write time). The inverse of LoadJSON.
func (d *SpecDocument) ToJSON() *DocumentJson {
	out := &DocumentJson{}
	if len(d.content) > 0 {
		content := map[string]string{}
		for k, v := range d.content {
			content[k] = v
		}
		out.Content = content
	}
	if len(d.form) > 0 {
		forms := map[string]map[string]string{}
		for k, fields := range d.form {
			entry := map[string]string{}
			for f, v := range fields {
				entry[f] = v
			}
			forms[k] = entry
		}
		out.Forms = forms
	}
	if len(d.listItems) > 0 {
		lists := map[string]ListJson{}
		for k, items := range d.listItems {
			seq, ok := d.listSeq[k]
			if !ok {
				seq = len(items)
			}
			cp := make([]string, len(items))
			copy(cp, items)
			entry := ListJson{Seq: seq, Items: cp}
			ids := map[string]string{}
			for _, itemPath := range items {
				if id, has := d.itemSectionID[itemPath]; has {
					ids[itemPath] = id
				}
			}
			if len(ids) > 0 {
				entry.Ids = ids
			}
			lists[k] = entry
		}
		out.Lists = lists
	}
	if len(d.headline) > 0 {
		headlines := map[string]string{}
		for k, v := range d.headline {
			headlines[k] = v
		}
		out.Headlines = headlines
	}
	if len(d.codeSpec) > 0 {
		codeSpecs := map[string]string{}
		for k, v := range d.codeSpec {
			codeSpecs[k] = v
		}
		out.CodeSpecs = codeSpecs
	}
	return out
}

// SortedContentPaths returns content paths in ascending order.
func (d *SpecDocument) SortedContentPaths() []string {
	out := d.ContentPaths()
	sort.Strings(out)
	return out
}

// LoadJSON replaces every store from a DocumentJson-shaped value. Empty entries
// are skipped, mirroring the other ports' loadJson.
func (d *SpecDocument) LoadJSON(j *DocumentJson) {
	d.content = map[string]string{}
	d.form = map[string]map[string]string{}
	d.listItems = map[string][]string{}
	d.listSeq = map[string]int{}
	d.itemSectionID = map[string]string{}
	d.headline = map[string]string{}
	d.codeSpec = map[string]string{}
	if j == nil {
		return
	}
	for k, v := range j.Content {
		d.content[k] = v
	}
	for k, fields := range j.Forms {
		if len(fields) == 0 {
			continue
		}
		entry := map[string]string{}
		for f, v := range fields {
			entry[f] = v
		}
		d.form[k] = entry
	}
	for k, spec := range j.Lists {
		if len(spec.Items) > 0 {
			cp := make([]string, len(spec.Items))
			copy(cp, spec.Items)
			d.listItems[k] = cp
			if spec.Seq != 0 {
				d.listSeq[k] = spec.Seq
			} else {
				d.listSeq[k] = len(spec.Items)
			}
			for itemPath, id := range spec.Ids {
				d.itemSectionID[itemPath] = id
			}
		}
	}
	for k, v := range j.Headlines {
		if v != "" {
			d.headline[k] = v
		}
	}
	for k, v := range j.CodeSpecs {
		if v != "" {
			d.codeSpec[k] = v
		}
	}
}
