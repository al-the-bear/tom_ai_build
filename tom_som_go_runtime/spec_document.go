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
// Three sparse stores cover the writable field kinds:
//
//   - content — content/scalar leaves: path → string value;
//   - form — @Form sections: path → (form-field name → value);
//   - listItems — lists: list path → ordered item paths.
//
// List item paths are "<listPath>-<seq>" where seq is a per-list monotonic
// counter that never reuses a number.

import (
	"os"
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
	Content map[string]string            `json:"content,omitempty"`
	Forms   map[string]map[string]string `json:"forms,omitempty"`
	Lists   map[string]ListJson          `json:"lists,omitempty"`
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
	}
}

// FromYaml loads a hierarchical `*.docspecs.yaml` document in one call: decode
// the YAML against the document's metadata tree (DR5) and retain the parsed
// ModelVersion on the document. Collapses the former DecodeYaml →
// thread-documentVersion incantation (§ item 4). Format problems surface as a
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
// null-free companion to ContentOr. (SOM roadmap § item 5.)
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
}

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

// ToMarkdown renders this document to Markdown in one call (SOM § item 12).
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
	return NewSpecDocumentMarkdown(model, d).ExportRoot(root), nil
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
	return len(d.content) == 0 && len(d.form) == 0 && len(d.listItems) == 0
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
}
