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

import "sort"

// ListJson is the plain-data shape of a single list store entry.
type ListJson struct {
	Seq   int      `json:"seq"`
	Items []string `json:"items"`
}

// DocumentJson is a SpecDocument.ToJSON-shaped plain-data view of a document.
// Only non-empty stores are populated.
type DocumentJson struct {
	Content map[string]string            `json:"content,omitempty"`
	Forms   map[string]map[string]string `json:"forms,omitempty"`
	Lists   map[string]ListJson          `json:"lists,omitempty"`
}

// SpecDocument is the sparse in-memory document.
type SpecDocument struct {
	content   map[string]string
	form      map[string]map[string]string
	listItems map[string][]string
	listSeq   map[string]int
}

// NewSpecDocument returns an empty document.
func NewSpecDocument() *SpecDocument {
	return &SpecDocument{
		content:   map[string]string{},
		form:      map[string]map[string]string{},
		listItems: map[string][]string{},
		listSeq:   map[string]int{},
	}
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
			lists[k] = ListJson{Seq: seq, Items: cp}
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
		}
	}
}
