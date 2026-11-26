package somruntime

// spec_document_markdown_linked.go — navigation between linked places of a
// rendition (SOM §11.2 qualified anchors, SOM §11.11 the `linked` marker), a
// port of the Python runtime's `spec_document_markdown_linked.py` (itself a
// port of the JavaScript, TypeScript and Dart runtimes'
// `spec_document_markdown_linked`).
//
// Both are written from the model and the document's own values, and nothing
// of either is stored: the parser removes the anchors and the marker.
//
// Internal to SpecDocumentMarkdown.

import (
	"strings"
	"unicode/utf16"
)

// mdLinkedPlaceholder is written by the emitter where a markable place has no
// entry: replaced by `[]{.linked}` when the value written after it begins
// with a `linked` span, else removed with its blank line (SOM §11.11).
const mdLinkedPlaceholder = "\x00linked\x00"

// The roles a heading plays for its anchor's qualification (SOM §11.2).
const (
	mdAnchorPlain = iota
	mdAnchorContainer
	mdAnchorItem
	mdAnchorCopy
)

// mdQualifyAnchorRole is mdQualifyAnchor by role.
func mdQualifyAnchorRole(scope []string, section, id string, role int) (string, []string) {
	return mdQualifyAnchor(scope, section, id, role == mdAnchorContainer,
		role == mdAnchorItem, role == mdAnchorCopy)
}

// mdWalk is a path walked through a tree: the anchor and id of the heading it
// ends at, that heading's path, the path as a pattern (items `<list>-*`), the
// items' ids on the way and the node reached (nil: not reached).
type mdWalk struct {
	anchor      string
	headingID   string
	headingPath string
	pattern     string
	itemIDs     []string
	node        *SomMetaNode
}

// mdSide is one side of a `@SyncedWith` pair: its anchor here, the other
// root, the anchor there, whether this side holds the values, the sync.
type mdSide struct {
	mine   string
	other  *SpecRoot
	theirs string
	holder bool
	sync   *SpecSync
}

// mdDerivedSource is one derived value at a heading: a link to a source ("":
// none) and the derived field's name ("": a derived section).
type mdDerivedSource struct {
	link  string
	field string
}

// mdSummaryTarget is a detail element a summary element names: its id, its
// anchor and the other root it is in (nil: this document).
type mdSummaryTarget struct {
	id     string
	anchor string
	other  *SpecRoot
}

// mdCutPattern is path cut before its first `<list>-*` segment, that list's
// path.
func mdCutPattern(path string) string {
	if i := strings.Index(path, "-*"); i >= 0 {
		return path[:i]
	}
	return path
}

// mdListPatternOf is an item pattern's list pattern (`a/L-*` → `a/L`).
func mdListPatternOf(itemPattern string) string {
	return strings.TrimSuffix(itemPattern, "-*")
}

func mdAddUnique(out []string, v string) []string {
	for _, x := range out {
		if x == v {
			return out
		}
	}
	return append(out, v)
}

// mdItemPatternOf is the `@SectionIdPattern` of a list's items: the list's,
// else its element's.
func mdItemPatternOf(listNode *SomMetaNode) string {
	if listNode.SectionIDPattern != "" {
		return listNode.SectionIDPattern
	}
	if listNode.ElementNode != nil {
		return listNode.ElementNode.SectionIDPattern
	}
	return ""
}

// mdMemberStemOf is the stem of a pattern-less list's item ids: its member
// name, else its segment.
func mdMemberStemOf(listNode *SomMetaNode) string {
	if listNode.MemberName != "" {
		return listNode.MemberName
	}
	return listNode.Segment()
}

// mdNavigation is one root's navigation: anchors, markable places and marker
// entries.
type mdNavigation struct {
	codec *SpecDocumentMarkdown
	root  *SpecRoot
	refl  *SpecReflection
	tree  *SomMetaTree

	walks       map[string]*mdWalk
	sides       []*mdSide
	sidesDone   bool
	sameAs      []SpecSameAsBinding
	sameAsDone  bool
	detailKeys  []string
	detailLists map[string][]string
	markables   map[string]bool
	summaryMap  map[string][]string
}

func newMdNavigation(codec *SpecDocumentMarkdown, root *SpecRoot, tree *SomMetaTree) *mdNavigation {
	return &mdNavigation{
		codec:     codec,
		root:      root,
		refl:      NewSpecReflection(codec.Model),
		tree:      tree,
		walks:     map[string]*mdWalk{},
		markables: map[string]bool{},
	}
}

func (n *mdNavigation) doc() *SpecDocument { return n.codec.Document }

func (n *mdNavigation) rootSeg() string { return n.refl.RootSegment(n.root) }

// --- anchors ------------------------------------------------------------------

// itemID returns the heading id of the item at itemPath of listNode in d (nil:
// no document), as the emitter writes it.
func (n *mdNavigation) itemID(d *SpecDocument, listNode *SomMetaNode, itemPath string) string {
	slash := strings.LastIndex(itemPath, "/")
	split, _ := SplitListItemSegment(itemPath[slash+1:])
	listPath := itemPath[:slash+1] + split.Base
	pos := 0
	stored, has := "", false
	if d != nil {
		for i, p := range d.ListItems(listPath) {
			if p == itemPath {
				pos = i + 1
				break
			}
		}
		stored, has = d.ItemSectionID(itemPath)
	}
	if pos == 0 {
		pos = split.Seq
	}
	return EffectiveListItemSectionID(stored, has, mdItemPatternOf(listNode), pos, mdMemberStemOf(listNode))
}

// walk walks path (concrete, or a pattern whose `<list>-*` segments take ids
// in order) through inTree (nil: this root's), the items' ids read from d.
func (n *mdNavigation) walk(path string, inTree *SomMetaTree, d *SpecDocument, ids []string) *mdWalk {
	t := inTree
	if t == nil {
		t = n.tree
	}
	cacheable := inTree == nil && len(ids) == 0 && d == n.doc()
	if cacheable {
		if hit, ok := n.walks[path]; ok {
			return hit
		}
	}
	codec := n.codec
	queue := append([]string{}, ids...)
	segs := strings.Split(path, "/")
	node := t.Root
	cur := segs[0]
	pattern := segs[0]
	anchor := node.Segment()
	headingID := node.Segment()
	headingPath := cur
	var scope []string
	section := node.Segment()
	var itemIDs []string
	reached := node
	for i := 1; i < len(segs); i++ {
		seg := segs[i]
		if child := node.ChildBySegment(seg); child != nil {
			cur += "/" + seg
			pattern += "/" + seg
			node = child
			reached = child
			if codec.isTransparentSection(child) || mdIsTransparentValue(child) {
				continue
			}
			id := codec.headingIdOf(child)
			container := child.Kind == SomMetaKindList
			role := mdAnchorPlain
			if container {
				role = mdAnchorContainer
			} else if codec.isCopyNode(child) {
				role = mdAnchorCopy
			}
			anchor, scope = mdQualifyAnchorRole(scope, section, id, role)
			headingID = id
			headingPath = cur
			if !container {
				section = id
			}
			continue
		}
		star := strings.HasSuffix(seg, "-*")
		base := ""
		ok := true
		if star {
			base = seg[:len(seg)-2]
		} else {
			split, sok := SplitListItemSegment(seg)
			base, ok = split.Base, sok
		}
		var listNode *SomMetaNode
		if ok {
			listNode = node.ChildBySegment(base)
		}
		if listNode == nil || listNode.Kind != SomMetaKindList {
			reached = nil
			break
		}
		itemPath := cur + "/" + seg
		var id string
		if star {
			if len(queue) > 0 {
				id, queue = queue[0], queue[1:]
			}
		} else {
			id = n.itemID(d, listNode, itemPath)
		}
		itemIDs = append(itemIDs, id)
		anchor, scope = mdQualifyAnchorRole(scope, section, id, mdAnchorItem)
		headingID = id
		section = id
		cur = itemPath
		headingPath = itemPath
		pattern += "/" + base + "-*"
		element := listNode.ElementNode
		if element != nil {
			node = element
		} else {
			node = listNode
		}
		reached = node
		if element == nil && i < len(segs)-1 {
			reached = nil
			break
		}
	}
	w := &mdWalk{anchor: anchor, headingID: headingID, headingPath: headingPath,
		pattern: pattern, itemIDs: itemIDs, node: reached}
	if cacheable {
		n.walks[path] = w
	}
	return w
}

// anchorOf returns the anchor of the heading path names in this document.
func (n *mdNavigation) anchorOf(path string) string {
	return n.walk(path, nil, n.doc(), nil).anchor
}

// --- the model's links, per root ------------------------------------------------

// rootOfType is the model's root of type t, nil when there is none.
func (n *mdNavigation) rootOfType(t string) *SpecRoot {
	for _, r := range n.codec.Model.Roots {
		if r.Type == t {
			return r
		}
	}
	return nil
}

// allSides returns every `@SyncedWith` pair this root is a side of.
func (n *mdNavigation) allSides() []*mdSide {
	if n.sidesDone {
		return n.sides
	}
	n.sidesDone = true
	bp, pairs := n.codec.syncPairs()
	if bp == "" {
		return n.sides
	}
	for _, p := range pairs {
		if p.Sync == nil {
			continue
		}
		if n.root.Type == bp {
			other := n.rootOfType(p.DetailRoot)
			if other == nil {
				continue
			}
			n.sides = append(n.sides, &mdSide{p.BlueprintAnchor, other, p.DetailAnchor, false, p.Sync})
		} else if n.root.Type == p.DetailRoot {
			other := n.rootOfType(bp)
			if other == nil {
				continue
			}
			n.sides = append(n.sides, &mdSide{p.DetailAnchor, other, p.BlueprintAnchor, true, p.Sync})
		}
	}
	return n.sides
}

// sameAsBindings returns the `@SameAs` copies of this root with their holders.
func (n *mdNavigation) sameAsBindings() []SpecSameAsBinding {
	if !n.sameAsDone {
		n.sameAsDone = true
		n.sameAs = SpecSameAsBindings(n.refl, n.root.Type)
	}
	return n.sameAs
}

func (n *mdNavigation) underCopy(pattern string) bool {
	for _, b := range n.sameAsBindings() {
		if pattern == b.CopyPath || strings.HasPrefix(pattern, b.CopyPath+"/") {
			return true
		}
	}
	return false
}

// sharedListSide returns the side whose shared list listPattern is: the
// innermost pair anchor holding it, when the list lies directly beneath it
// (not below an item of it), outside a copy and outside the pair's
// `detailOnly` places.
func (n *mdNavigation) sharedListSide(listPattern, concreteList string) *mdSide {
	if n.underCopy(listPattern) {
		return nil
	}
	var best *mdSide
	for _, s := range n.allSides() {
		if !strings.HasPrefix(listPattern, s.mine+"/") {
			continue
		}
		if best == nil || len(s.mine) > len(best.mine) {
			best = s
		}
	}
	if best == nil {
		return nil
	}
	rel := listPattern[len(best.mine)+1:]
	if strings.Contains(rel, "-*") {
		return nil
	}
	// The anchor's concrete path: the list's as long as the anchor is.
	depth := len(strings.Split(best.mine, "/"))
	parts := strings.Split(concreteList, "/")
	if depth < len(parts) {
		parts = parts[:depth]
	}
	anchor := strings.Join(parts, "/")
	for _, place := range best.sync.DetailOnly {
		r := SpecResolvePlaceAt(n.refl, place, anchor)
		if r == nil {
			continue
		}
		p := n.walk(r.Path, nil, n.doc(), nil).pattern
		if listPattern == p || strings.HasPrefix(listPattern, p+"/") {
			return nil
		}
	}
	return best
}

// summaryOfList returns the `@SummaryOf` of the list member at listPath, nil
// when it has none.
func (n *mdNavigation) summaryOfList(listPath string) *SpecSummaryOf {
	r := n.refl.Resolve(listPath)
	if r == nil || r.Field == nil {
		return nil
	}
	return r.Field.SummaryOf()
}

// sameDocument reports whether a summary names its detail elements in this
// document.
func (n *mdNavigation) sameDocument(s *SpecSummaryOf) bool {
	return s.Document == "" || s.Document == n.root.Type
}

// detailListsMap returns detail-list pattern → the summary lists (patterns)
// of this document naming its elements, and the patterns in insertion order.
func (n *mdNavigation) detailListsMap() (map[string][]string, []string) {
	if n.detailLists != nil {
		return n.detailLists, n.detailKeys
	}
	out := map[string][]string{}
	var keys []string
	for _, node := range n.tree.AllNodes() {
		np, _ := node.Path()
		if node.Kind != SomMetaKindList || np == "" {
			continue
		}
		s := n.summaryOfList(np)
		if s == nil || !n.sameDocument(s) {
			continue
		}
		owner := np[:strings.LastIndex(np, "/")]
		r := SpecResolveLinkPlace(n.refl, nil, s.Detail, n.rootSeg(), owner)
		if r == nil {
			continue
		}
		key := n.walk(mdCutPattern(r.Path), nil, n.doc(), nil).pattern
		if _, ok := out[key]; !ok {
			keys = append(keys, key)
		}
		out[key] = append(out[key], np)
	}
	n.detailLists, n.detailKeys = out, keys
	return out, keys
}

// --- markable places (structural: the parser and the emitter agree) -----------

// markable reports whether the heading at path carries one of the links of
// SOM §11.11: a `@SyncedWith` anchor or an element of one of its shared lists,
// an element of a summary list or of a detail list a summary of this document
// names, a heading holding a derived value, a list of link rows extracted from
// text, a `@SameAs` copy or its holder.
func (n *mdNavigation) markable(path string) bool {
	if v, ok := n.markables[path]; ok {
		return v
	}
	v := n.computeMarkable(path)
	n.markables[path] = v
	return v
}

func (n *mdNavigation) computeMarkable(path string) bool {
	w := n.walk(path, nil, n.doc(), nil)
	node := w.node
	if node == nil || w.headingPath != path {
		return false
	}
	pattern := w.pattern
	for _, s := range n.allSides() {
		if s.mine == pattern {
			return true
		}
	}
	if listPath, _, ok := n.itemParts(path); ok {
		listPattern := mdListPatternOf(pattern)
		if n.sharedListSide(listPattern, listPath) != nil {
			return true
		}
		if n.summaryOfList(listPath) != nil {
			return true
		}
		if lists, _ := n.detailListsMap(); lists[listPattern] != nil {
			return true
		}
	}
	if len(n.derivedSources(path, node, true, false)) > 0 {
		return true
	}
	if node.Kind == SomMetaKindList && len(n.extractFrom(path)) > 0 {
		return true
	}
	for _, b := range n.sameAsBindings() {
		if b.CopyPath == pattern || b.HolderPath == pattern {
			return true
		}
	}
	return false
}

// itemParts returns, for an item path, its list's path and its segment; ok
// false otherwise.
func (n *mdNavigation) itemParts(path string) (listPath, seg string, ok bool) {
	slash := strings.LastIndex(path, "/")
	if slash < 0 {
		return "", "", false
	}
	seg = path[slash+1:]
	split, sok := SplitListItemSegment(seg)
	if !sok {
		return "", "", false
	}
	parent := path[:slash]
	if node := n.tree.ByPath(parent); node != nil && node.ChildBySegment(seg) != nil {
		return "", "", false
	}
	listPath = parent + "/" + split.Base
	listNode := n.tree.ByPath(listPath)
	if listNode == nil || listNode.Kind != SomMetaKindList {
		return "", "", false
	}
	return listPath, seg, true
}

// --- the marker -------------------------------------------------------------------

// link returns a link to anchor in other (nil: this document), its text id
// prefixed by the other root's id.
func (n *mdNavigation) link(id, anchor string, other *SpecRoot) string {
	if other == nil {
		return "[" + id + "](#" + anchor + ")"
	}
	name := other.SectionID
	if name == "" {
		name = other.Type
	}
	return "[" + name + " " + id + "](" + n.codec.fileOfRoot(other) + "#" + anchor + ")"
}

// entries returns the marker's entries at the heading path, in the order of
// SOM §11.11; empty when path is not markable or carries no link this time.
// sectionTable: the heading's children are written as a section table.
func (n *mdNavigation) entries(path string, sectionTable bool) []string {
	if !n.markable(path) {
		return nil
	}
	w := n.walk(path, nil, n.doc(), nil)
	node := w.node
	pattern := w.pattern
	var out []string

	// Also in (@SyncedWith).
	note := func(s *mdSide) string {
		held := "held there"
		if s.holder {
			held = "held here"
		}
		if len(s.sync.HeldHere) == 0 {
			return held
		}
		return held + " except " + strings.Join(s.sync.HeldHere, ", ")
	}
	for _, s := range n.allSides() {
		if s.mine != pattern {
			continue
		}
		otherTree, err := n.codec.treeFor(s.other.Type)
		if err != nil {
			continue
		}
		there := n.walk(s.theirs, otherTree, nil, w.itemIDs)
		out = append(out, "Also in "+n.link(w.headingID, there.anchor, s.other)+", "+note(s))
	}
	if listPath, _, ok := n.itemParts(path); ok {
		listPattern := mdListPatternOf(pattern)
		if side := n.sharedListSide(listPattern, listPath); side != nil {
			if otherTree, err := n.codec.treeFor(side.other.Type); err == nil {
				rel := listPattern[len(side.mine):]
				there := n.walk(side.theirs+rel+"-*", otherTree, nil, w.itemIDs)
				out = append(out, "Also in "+n.link(w.headingID, there.anchor, side.other)+", "+note(side))
			}
		}

		// Summary of (@SummaryOf on the list).
		if summary := n.summaryOfList(listPath); summary != nil {
			var links []string
			for _, t := range n.summaryTargets(path, listPath, w.headingID, summary) {
				links = append(links, n.link(t.id, t.anchor, t.other))
			}
			if len(links) > 0 {
				out = append(out, "Summary of "+strings.Join(links, ", "))
			}
		}

		// Summarised in: the summary elements of this document naming it.
		if named, ok := n.summaryLinks()[listPath+"#"+w.headingID]; ok {
			out = append(out, "Summarised in "+strings.Join(named, ", "))
		}
	}

	// Derived from.
	if derived := n.derivedSources(path, node, false, sectionTable); len(derived) > 0 {
		var dlinks, fields []string
		for _, d := range derived {
			if d.link != "" {
				dlinks = mdAddUnique(dlinks, d.link)
			}
			if d.field != "" {
				fields = mdAddUnique(fields, d.field)
			}
		}
		if len(dlinks) > 0 {
			entry := "Derived from " + strings.Join(dlinks, ", ")
			if len(fields) > 0 {
				entry += ": " + strings.Join(fields, ", ")
			}
			out = append(out, entry)
		}
	}

	// Extracted from (@ExtractsLinks, generate).
	if node.Kind == SomMetaKindList {
		if from := n.extractFrom(path); len(from) > 0 {
			out = append(out, "Extracted from "+strings.Join(from, ", "))
		}
	}

	// Copy of / Copied to (@SameAs).
	for _, b := range n.sameAsBindings() {
		if b.CopyPath != pattern || b.HolderPath == "" {
			continue
		}
		h := n.walk(b.HolderPath, nil, n.doc(), w.itemIDs)
		out = append(out, "Copy of "+n.link(h.headingID, h.anchor, nil)+", edit it there")
	}
	var copies []string
	for _, b := range n.sameAsBindings() {
		if b.HolderPath != pattern {
			continue
		}
		c := n.walk(b.CopyPath, nil, n.doc(), w.itemIDs)
		copies = append(copies, n.link(c.headingID, c.anchor, nil))
	}
	if len(copies) > 0 {
		out = append(out, "Copied to "+strings.Join(copies, ", "))
	}
	return out
}

// summaryLinks returns `<detail list path>#<element id>` → the links to the
// summary elements of this document naming that element, in document order.
func (n *mdNavigation) summaryLinks() map[string][]string {
	if n.summaryMap != nil {
		return n.summaryMap
	}
	out := map[string][]string{}
	lists, keys := n.detailListsMap()
	var summaries []string
	for _, k := range keys {
		for _, l := range lists[k] {
			summaries = mdAddUnique(summaries, l)
		}
	}
	doc := n.doc()
	for _, summaryList := range summaries {
		for _, concrete := range SpecExpandPattern(doc, summaryList) {
			s := n.summaryOfList(concrete)
			if s == nil {
				continue
			}
			owner := concrete[:strings.LastIndex(concrete, "/")]
			r := SpecResolveLinkPlace(n.refl, doc, s.Detail, n.rootSeg(), owner)
			if r == nil {
				continue
			}
			detail := mdCutPattern(r.Path)
			for _, e := range doc.ListItems(concrete) {
				ew := n.walk(e, nil, doc, nil)
				for _, id := range n.summaryIDs(e, s, ew.headingID) {
					key := detail + "#" + id
					out[key] = mdAddUnique(out[key], n.link(ew.headingID, ew.anchor, nil))
				}
			}
		}
	}
	n.summaryMap = out
	return out
}

// summaryIDs returns the ids summary element element names: its `match`
// field's ids, else its own ownID.
func (n *mdNavigation) summaryIDs(element string, s *SpecSummaryOf, ownID string) []string {
	if s.Match == "" {
		return []string{ownID}
	}
	r := SpecResolvePlaceAt(n.refl, s.Match, element)
	if r == nil || r.Field() == "" {
		return nil
	}
	raw, ok := n.doc().FormField(r.Path, r.Field())
	if !ok {
		return nil
	}
	var out []string
	for _, x := range strings.Split(raw, ",") {
		if id := strings.TrimSpace(x); id != "" {
			out = append(out, id)
		}
	}
	return out
}

// summaryTargets returns the detail elements summary element element of
// listPath names.
func (n *mdNavigation) summaryTargets(element, listPath, ownID string, s *SpecSummaryOf) []mdSummaryTarget {
	ids := n.summaryIDs(element, s, ownID)
	if len(ids) == 0 {
		return nil
	}
	owner := listPath[:strings.LastIndex(listPath, "/")]
	var out []mdSummaryTarget
	if n.sameDocument(s) {
		r := SpecResolveLinkPlace(n.refl, n.doc(), s.Detail, n.rootSeg(), owner)
		if r == nil {
			return nil
		}
		list := mdCutPattern(r.Path)
		for _, id := range ids {
			out = append(out, mdSummaryTarget{id, n.walk(list+"-*", nil, n.doc(), []string{id}).anchor, nil})
		}
		return out
	}
	other := n.rootOfType(s.Document)
	if other == nil {
		return nil
	}
	otherSeg := n.refl.RootSegment(other)
	r := SpecResolveLinkPlace(n.refl, nil, s.Detail, otherSeg, otherSeg)
	for _, id := range ids {
		anchor := id
		if r != nil && !strings.Contains(r.Path, "-*") {
			if otherTree, err := n.codec.treeFor(other.Type); err == nil {
				anchor = n.walk(r.Path+"-*", otherTree, nil, []string{id}).anchor
			}
		}
		out = append(out, mdSummaryTarget{id, anchor, other})
	}
	return out
}

// summaryIDCell returns the `Id` cell of a records row standing for summary
// element item of listPath whose `@SummaryOf` has no `match` (SOM §11.5,
// §11.11): its anchor, then its id as a link to the detail element it names.
// ok false when the list is no such summary.
func (n *mdNavigation) summaryIDCell(item, listPath, id string) (string, bool) {
	s := n.summaryOfList(listPath)
	if s == nil || s.Match != "" {
		return "", false
	}
	targets := n.summaryTargets(item, listPath, id, s)
	if len(targets) == 0 {
		return "", false
	}
	// Without `match` a summary element names exactly one detail element.
	t := targets[0]
	href := "#" + t.anchor
	if t.other != nil {
		href = n.codec.fileOfRoot(t.other) + "#" + t.anchor
	}
	return `<a id="` + n.anchorOf(item) + `"></a>[` + id + "](" + href + ")", true
}

// derivedSources returns the derived values at the heading path: a link to a
// source ("" none) and the derived field's name ("" a derived section) per
// source. probe: answer whether there is any, structurally (no links built).
func (n *mdNavigation) derivedSources(path string, node *SomMetaNode, probe, sectionTable bool) []mdDerivedSource {
	doc := n.doc()
	codec := n.codec
	var out []mdDerivedSource

	linkTo := func(target string) string {
		t := n.walk(mdCutPattern(target), nil, doc, nil)
		return n.link(t.headingID, t.anchor, nil)
	}
	source := func(place, owner string) string {
		if probe {
			return ""
		}
		r := SpecResolveLinkPlace(n.refl, doc, place, n.rootSeg(), owner)
		if r == nil {
			return ""
		}
		return linkTo(r.Path)
	}
	form := func(formPath, prefix string) {
		owner := formPath[:strings.LastIndex(formPath, "/")]
		res := n.refl.Resolve(formPath)
		if res == nil || res.Field == nil {
			return
		}
		for _, ff := range res.Field.FormFields {
			name := ff.Name
			if prefix != "" {
				name = prefix + "." + ff.Name
			}
			if d := ff.DerivedFrom; d != nil {
				out = append(out, mdDerivedSource{source(d.Source, owner), name})
			}
			for _, t := range ff.CountOf {
				f := TryParseSpecPlaceFilter(t)
				if f == nil {
					continue
				}
				place := f.SectionID
				if f.Scoped {
					place = "./" + f.SectionID
				}
				out = append(out, mdDerivedSource{source(place, owner), name})
			}
			for _, operand := range ff.ProductOf {
				l := ""
				if !probe {
					if dot := strings.Index(operand, "."); dot < 0 {
						l = linkTo(formPath)
					} else {
						l = linkTo(owner + "/" + operand[:dot])
					}
				}
				out = append(out, mdDerivedSource{l, name})
			}
			if ff.RankOf != "" {
				l := ""
				if !probe {
					if listPath, _, ok := n.itemParts(owner); ok {
						l = linkTo(listPath)
					} else {
						l = linkTo(formPath)
					}
				}
				out = append(out, mdDerivedSource{l, name})
			}
		}
	}

	// A member carrying `@DerivedFrom`: name for one written in its owner's
	// body (no heading of its own), "" for the heading itself.
	member := func(memberPath, name string) {
		res := n.refl.Resolve(memberPath)
		if res == nil || res.Field == nil {
			return
		}
		d := res.Field.DerivedFrom()
		if d == nil {
			return
		}
		owner := memberPath[:strings.LastIndex(memberPath, "/")]
		out = append(out, mdDerivedSource{source(d.Source, owner), name})
	}

	_, _, isItem := n.itemParts(path)
	if node.Kind == SomMetaKindForm {
		form(path, "")
	}
	if !isItem && strings.Contains(path, "/") {
		member(path, "")
	}
	if node.Kind == SomMetaKindSection || node.Kind == SomMetaKindComplex || isItem {
		for _, slot := range codec.bodySlots(node) {
			slotPath := path + "/" + slot.rel
			if slot.node.Kind == SomMetaKindForm {
				form(slotPath, "")
			} else {
				name := slot.node.MemberName
				if name == "" {
					name = slot.node.Segment()
				}
				member(slotPath, name)
			}
		}
		if sectionTable || probe {
			for _, child := range codec.effectiveChildren(node) {
				if child.node.Kind != SomMetaKindForm {
					continue
				}
				if probe || doc.HasValuesUnder(path+"/"+child.rel) {
					form(path+"/"+child.rel, codec.headingIdOf(child.node))
				}
			}
		}
	}
	return out
}

// extractFrom returns the `Extracted from` links of the link-row list at
// path: the text places of its `@ExtractsLinks` in `generate` mode.
func (n *mdNavigation) extractFrom(path string) []string {
	res := n.refl.Resolve(path)
	if res == nil || res.Field == nil {
		return nil
	}
	owner := path[:strings.LastIndex(path, "/")]
	var out []string
	for _, e := range res.Field.ExtractsLinks() {
		if e.Mode != "generate" {
			continue
		}
		for _, place := range e.From {
			r := SpecResolveLinkPlace(n.refl, n.doc(), place, n.rootSeg(), owner)
			if r == nil {
				continue
			}
			t := n.walk(mdCutPattern(r.Path), nil, n.doc(), nil)
			out = mdAddUnique(out, n.link(t.headingID, t.anchor, nil))
		}
	}
	return out
}

// mdUTF16Len is the length of text in UTF-16 code units.
func mdUTF16Len(text string) int {
	return len(utf16.Encode([]rune(text)))
}

// mdIsLinkedParagraph reports whether paragraph is exactly one span of kind
// `linked`.
func mdIsLinkedParagraph(paragraph string) bool {
	text := strings.TrimSpace(paragraph)
	if !strings.HasPrefix(text, "[") || !strings.HasSuffix(text, "{.linked}") {
		return false
	}
	scan := ScanNotation(text, false)
	if len(scan.Elements) != 1 {
		return false
	}
	e := scan.Elements[0]
	return e.Type == "span" && e.Kind == "linked" && e.Start == 0 && e.End == mdUTF16Len(text)
}

// mdResolveLinkedPlaceholders returns markdown with every placeholder
// resolved: `[]{.linked}` where the paragraph after it is a `linked` span,
// else removed with its blank line.
func mdResolveLinkedPlaceholders(markdown string) string {
	if !strings.Contains(markdown, mdLinkedPlaceholder) {
		return markdown
	}
	lines := strings.Split(markdown, "\n")
	out := make([]string, 0, len(lines))
	for i := 0; i < len(lines); {
		if lines[i] != mdLinkedPlaceholder {
			out = append(out, lines[i])
			i++
			continue
		}
		// The placeholder, its blank line, then the paragraph that follows.
		k := i + 1
		for k < len(lines) && strings.TrimSpace(lines[k]) == "" {
			k++
		}
		j := k
		for j < len(lines) && strings.TrimSpace(lines[j]) != "" {
			j++
		}
		if j > k && mdIsLinkedParagraph(strings.Join(lines[k:j], "\n")) {
			out = append(out, "[]{.linked}")
			i++
		} else {
			i += 2 // the blank line after the placeholder goes with it
		}
	}
	return strings.Join(out, "\n")
}
