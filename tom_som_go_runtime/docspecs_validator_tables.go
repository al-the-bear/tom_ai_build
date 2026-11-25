package somruntime

// docspecs_validator_tables.go — the reading view in the DocSpecs validator
// (DocSpecs specification, List Bodies; Findings in list bodies and tables):
// the sections the validator walks, which can be virtual (rebuilt from a list
// body or a section table), the table reader, the list-body expansion, the
// styled-div headings and the section's own anchor. A port of the JavaScript
// `docspecs_validator.js` (itself a port of the Dart / TypeScript reference).

import (
	"regexp"
	"strconv"
	"strings"
)

var (
	docspecsStyledDivRE = regexp.MustCompile(`^<div class="heading([0-9]+)"[^>]*>(.*)</div>$`)
	docspecsAnchorRE    = regexp.MustCompile(`^<a id="([^"]*)"></a>\s*`)
	docspecsLinkedRE    = regexp.MustCompile(`^\[.*\]\{\.linked\}$`)
	docspecsDerivedRE   = regexp.MustCompile(`^ {0,3}(:{3,})[ \t]*\{\.derived[\s}]`)
	docspecsCellAnchors = regexp.MustCompile(`<a id="([^"]*)"></a>\s*`)
	docspecsCellLinks   = regexp.MustCompile(`\[([^\]]+)\]\([^)\s]*\)`)
)

// docspecsStyledDivHeading reads a styled-div heading (the DocSpecs
// specification's *Styled-div headings*): a whole line
// `<div class="heading<N>" …>…</div>` at column 0 with N ≥ 7 reads as a
// heading of level N whose text is the div's inner text with `&amp;`, `&lt;`,
// `&gt;` decoded. ok is false for any other line — a `heading<N>` div with
// N ≤ 6 is content.
func docspecsStyledDivHeading(line string) (level int, text string, ok bool) {
	m := docspecsStyledDivRE.FindStringSubmatch(line)
	if m == nil {
		return 0, "", false
	}
	level, err := strconv.Atoi(m[1])
	if err != nil || level < 7 {
		return 0, "", false
	}
	text = strings.ReplaceAll(m[2], "&lt;", "<")
	text = strings.ReplaceAll(text, "&gt;", ">")
	text = strings.ReplaceAll(text, "&amp;", "&")
	return level, text, true
}

// StripOwnAnchor returns text with a leading anchor `<a id="ID"></a>` removed
// when it is the section's own (Section Anchors): its id is id, or the
// qualified form `<A>/…/<id>` a heading below a list item carries. Any other
// anchor is ordinary text and stays.
func StripOwnAnchor(text, id string) string {
	m := docspecsAnchorRE.FindStringSubmatch(text)
	if m != nil && docspecsIsOwnAnchor(m[1], id) {
		return text[len(m[0]):]
	}
	return text
}

// docspecsIsOwnAnchor reports whether anchor is the own anchor of a section
// with id: id itself, or a qualified form `<A>/…/<id>` whose segments are all
// non-empty (Section Anchors).
func docspecsIsOwnAnchor(anchor, id string) bool {
	if anchor == id {
		return true
	}
	if !strings.HasSuffix(anchor, "/"+id) {
		return false
	}
	for _, s := range strings.Split(anchor, "/") {
		if s == "" {
			return false
		}
	}
	return true
}

// docspecsGeneratedLead is the number of leading lines of a section's lines
// that the rendition writes from the document and that hold no value: a
// paragraph that is one `linked` span (SOM §11.11), then a `derived` block
// (SOM §11.12), with the blank lines around them (DocSpecs RN-5, *Not text*).
func docspecsGeneratedLead(lines []string) int {
	skipBlank := func(i int) int {
		for i < len(lines) && strings.TrimSpace(lines[i]) == "" {
			i++
		}
		return i
	}
	i := skipBlank(0)
	end := i
	for end < len(lines) && strings.TrimSpace(lines[end]) != "" {
		end++
	}
	para := strings.TrimSpace(strings.Join(lines[i:end], " "))
	if end > i && docspecsLinkedRE.MatchString(para) {
		i = skipBlank(end)
	}
	if i < len(lines) {
		if open := docspecsDerivedRE.FindStringSubmatch(lines[i]); open != nil {
			closeRE := regexp.MustCompile(`^ {0,3}:{` + itoa(len(open[1])) + `,}[ \t]*$`)
			k := i + 1
			for k < len(lines) && !closeRE.MatchString(lines[k]) {
				k++
			}
			if k < len(lines) {
				i = skipBlank(k + 1)
			}
		}
	}
	return i
}

// docspecsWithoutGeneratedText is text without its docspecsGeneratedLead:
// what the text rules read.
func docspecsWithoutGeneratedText(text string) string {
	lines := strings.Split(text, "\n")
	return strings.TrimSpace(strings.Join(lines[docspecsGeneratedLead(lines):], "\n"))
}

// docspecsValue is a form value a table row or a list body gave a section:
// its label ("" for a bare virtual body line), value and line.
type docspecsValue struct {
	label string
	value string
	line  int
}

// docspecsNode is a section as the validator walks it: a parsed
// DocSpecsSection, or a virtual one rebuilt from a list body or a section
// table (the DocSpecs specification's *List Bodies*). The body is a copy, so
// blanking a table or div never touches the parsed document.
type docspecsNode struct {
	id string
	// line is the heading's line, or the row's or div's line of a virtual
	// section.
	line int
	// body holds the own body lines; a list body or section table already
	// read is blank.
	body []string
	// typ is the section-type of a virtual list item, given by the schema.
	typ      *DocSpecsSectionType
	children []*docspecsNode
	// values holds the form values given by a table row or a list body.
	values []docspecsValue
}

// docspecsNodeOf is the walk's view of a parsed section and its subtree.
func docspecsNodeOf(s *DocSpecsSection) *docspecsNode {
	n := &docspecsNode{id: s.ID, line: s.Line, body: append([]string(nil), s.BodyLines...)}
	for _, c := range s.Children {
		n.children = append(n.children, docspecsNodeOf(c))
	}
	return n
}

// docspecsVirtual is a virtual section at line, with no body.
func docspecsVirtual(id string, line int, typ *DocSpecsSectionType) *docspecsNode {
	return &docspecsNode{id: id, line: line, typ: typ}
}

func (n *docspecsNode) bodyStartLine() int {
	return n.line + 1
}

// text is the trimmed body text, after the virtual body lines of values — the
// text the same section has in the fields layout, where a section without a
// form in the schema carries its values as `FieldName:` lines.
func (n *docspecsNode) text() string {
	lines := make([]string, 0, len(n.values)+len(n.body))
	for _, v := range n.values {
		if v.label == "" {
			lines = append(lines, v.value)
		} else {
			lines = append(lines, v.label+": "+v.value)
		}
	}
	lines = append(lines, n.body...)
	start, end := 0, len(lines)
	for start < end && strings.TrimSpace(lines[start]) == "" {
		start++
	}
	for end > start && strings.TrimSpace(lines[end-1]) == "" {
		end--
	}
	return strings.Join(lines[start:end], "\n")
}

// docspecsCellValue is a value cell's value: `\|` unescaped, a cell of links
// read as their texts.
func docspecsCellValue(cell string) string {
	text := strings.ReplaceAll(cell, `\|`, "|")
	if mdLinkCellRE.MatchString(text) {
		var texts []string
		for _, m := range mdLinkTextRE.FindAllStringSubmatch(text, -1) {
			texts = append(texts, m[1])
		}
		return strings.Join(texts, ", ")
	}
	return text
}

// docspecsCellID is an `Id` or `Section` cell with its own anchors
// (`<a id="X"></a>X`) removed (Section Anchors): in a `<LIST> / <ITEM>` cell
// each part's anchor, and one before the whole cell naming its item. Any
// other anchor stays. A summary row's id written as a link is read as its
// text (SOM §11.5).
func docspecsCellID(cell string) string {
	cell = docspecsCellLinks.ReplaceAllString(cell, "${1}")
	var out strings.Builder
	pos := 0
	for _, m := range docspecsCellAnchors.FindAllStringSubmatchIndex(cell, -1) {
		start, end := m[0], m[1]
		out.WriteString(cell[pos:start])
		id := cell[m[2]:m[3]]
		rest := mdSectionSplitRE.Split(cell[end:], -1)
		own := docspecsIsOwnAnchor(id, strings.TrimSpace(rest[0])) ||
			(start == 0 && docspecsIsOwnAnchor(id, strings.TrimSpace(rest[len(rest)-1])))
		if !own {
			out.WriteString(cell[start:end])
		}
		pos = end
	}
	out.WriteString(cell[pos:])
	return out.String()
}

// docspecsTable is a table read by docspecsReadTable: the header cells, the
// body rows with their line indexes, and the index after the table.
type docspecsTable struct {
	header []string
	rows   []mdTableRow
	end    int
}

// docspecsReadTable reads the table whose header is lines[start]. A missing
// or mismatched delimiter row is a DocSpecsRuleMalformedBlock at the header
// and the table yields no rows; a row of another cell count is a
// DocSpecsRuleMalformedBlock at that row and is left out.
func docspecsReadTable(
	lines []string, start int, lineOf func(int) int, sectionID string,
	v []*DocSpecsViolation,
) (docspecsTable, []*DocSpecsViolation) {
	end := start + 1
	for end < len(lines) && mdTableLineRE.MatchString(lines[end]) {
		end++
	}
	header := mdRowCells(lines[start])
	var delimiter []string
	if start+1 < end {
		delimiter = mdRowCells(lines[start+1])
	}
	delimiterOk := delimiter != nil
	for _, c := range delimiter {
		if !mdDelimiterCellRE.MatchString(c) {
			delimiterOk = false
		}
	}
	if !delimiterOk || len(delimiter) != len(header) {
		message := "table without its delimiter row"
		if delimiterOk {
			message = "table whose delimiter row does not match its header"
		}
		v = append(v, &DocSpecsViolation{
			Rule: DocSpecsRuleMalformedBlock, Line: lineOf(start), Message: message,
			SectionID: sectionID,
		})
		return docspecsTable{header: header, end: end}, v
	}
	var rows []mdTableRow
	for i := start + 2; i < end; i++ {
		cells := mdRowCells(lines[i])
		if len(cells) != len(header) {
			v = append(v, &DocSpecsViolation{
				Rule: DocSpecsRuleMalformedBlock,
				Line: lineOf(i),
				Message: "table row with " + itoa(len(cells)) + " cells, the header has " +
					itoa(len(header)),
				SectionID: sectionID,
			})
			continue
		}
		rows = append(rows, mdTableRow{index: i, cells: cells})
	}
	return docspecsTable{header: header, rows: rows, end: end}, v
}

// expandSectionTables reads every section table of node's body (header
// `Section | TomSpecField | Value`): each row's `Section` cell names a child —
// by its id relative to node, a list item as `<LIST> / <ITEM>`, an empty cell
// the row above's — and its `TomSpecField` / `Value` cells become that
// child's form values. A child without a heading becomes a virtual section;
// one whose id resolves to no type allowed under node is
// DocSpecsRuleUnknownSection at the row, and its rows are skipped. The
// table's lines are blanked.
func (val *DocSpecsValidator) expandSectionTables(
	node *docspecsNode, allowed func(*DocSpecsSectionType) bool, v []*DocSpecsViolation,
) []*DocSpecsViolation {
	body := node.body
	fence := &MarkdownFenceTracker{}
	lineOf := func(k int) int { return node.bodyStartLine() + k }
	for i := 0; i < len(body); i++ {
		line := body[i]
		var h []string
		if !fence.InFence() {
			h = mdLayoutTableHeaderRE.FindStringSubmatch(line)
		}
		if h == nil || h[1] == "" {
			fence.Feed(line)
			continue
		}
		var table docspecsTable
		table, v = docspecsReadTable(body, i, lineOf, node.id, v)
		var target *docspecsNode
		skip := false
		for _, row := range table.rows {
			cell := docspecsCellID(row.cells[0])
			if cell != "" {
				target = val.sectionTableTarget(node, cell, allowed, lineOf(row.index))
				skip = target == nil
				if target == nil {
					v = append(v, &DocSpecsViolation{
						Rule:      DocSpecsRuleUnknownSection,
						Line:      lineOf(row.index),
						Message:   "section-table row names no child section of \"" + node.id + "\"",
						SectionID: cell,
					})
					continue
				}
			} else if skip {
				continue // the rejected child's further rows
			} else if target == nil {
				v = append(v, &DocSpecsViolation{
					Rule:      DocSpecsRuleUnknownSection,
					Line:      lineOf(row.index),
					Message:   "section-table row names no section",
					SectionID: node.id,
				})
				continue
			}
			target.values = append(target.values, docspecsValue{
				row.cells[1], docspecsCellValue(row.cells[2]), lineOf(row.index),
			})
		}
		for k := i; k < table.end; k++ {
			body[k] = ""
		}
		i = table.end - 1
	}
	return v
}

// sectionTableTarget is the child a section-table `Section` cell names under
// node: a child section by its id, or `<LIST> / <ITEM>` — an item of a child
// list. A child or item without a heading is created as a virtual section
// when its id resolves to a type allowed where it stands; nil otherwise.
func (val *DocSpecsValidator) sectionTableTarget(
	node *docspecsNode, cell string, allowed func(*DocSpecsSectionType) bool, line int,
) *docspecsNode {
	parts := mdSectionSplitRE.Split(cell, -1)
	if len(parts) > 2 {
		return nil
	}
	child := func(parent *docspecsNode, id string, ok func(*DocSpecsSectionType) bool) *docspecsNode {
		for _, c := range parent.children {
			if c.id == id {
				return c
			}
		}
		t := val.Schema.ResolveSectionType(id)
		if t == nil || !ok(t) {
			return nil
		}
		created := docspecsVirtual(id, line, nil)
		parent.children = append(parent.children, created)
		return created
	}
	first := child(node, parts[0], allowed)
	if len(parts) == 1 || first == nil {
		return first
	}
	listType := first.typ
	if listType == nil {
		listType = val.Schema.ResolveSectionType(parts[0])
	}
	if listType == nil {
		return nil
	}
	return child(first, parts[1], func(t *DocSpecsSectionType) bool {
		_, ok := listType.SubsectionTypes[t.Name]
		return ok
	})
}

// expandListBody reads a list container's body: one `refs` div (a reference
// line) or one `records` div (a record table) stands for its items when the
// container has no item heading; the items become virtual sections of the
// container's one subsection type, and the div's lines are blanked.
func (val *DocSpecsValidator) expandListBody(
	node *docspecsNode, t *DocSpecsSectionType, v []*DocSpecsViolation,
) []*DocSpecsViolation {
	body := node.body
	fence := &MarkdownFenceTracker{}
	for i := 0; i < len(body); i++ {
		line := body[i]
		var open []string
		if !fence.InFence() {
			open = mdListDivOpenRE.FindStringSubmatch(line)
		}
		if open == nil {
			fence.Feed(line)
			continue
		}
		kind := open[1]
		if kind == "" {
			kind = open[2]
		}
		at := node.bodyStartLine() + i
		reject := func(message string) {
			v = append(v, &DocSpecsViolation{
				Rule: DocSpecsRuleMalformedBlock, Line: at, Message: message, SectionID: node.id,
			})
		}
		closeAt := -1
		for k := i + 1; k < len(body); k++ {
			if mdDivCloseRE.MatchString(body[k]) {
				closeAt = k
				break
			}
		}
		if closeAt < 0 {
			reject("unclosed " + kind + " fence") // its lines stay text
			return v
		}
		lead := docspecsGeneratedLead(body)
		besideText := false
		for k, l := range body {
			if k >= lead && (k < i || k > closeAt) && strings.TrimSpace(l) != "" {
				besideText = true
				break
			}
		}
		hasItems := len(node.children) > 0
		inner := append([]string(nil), body[i+1:closeAt]...)
		for k := i; k <= closeAt; k++ {
			body[k] = ""
		}
		if besideText || hasItems {
			beside := "other text"
			if hasItems {
				beside = "item headings"
			}
			reject("a " + kind + " div beside " + beside + " in a list container")
			return v
		}
		var itemType *DocSpecsSectionType
		if len(t.subsectionOrder) == 1 {
			itemType = val.Schema.SectionTypesByName[t.subsectionOrder[0]]
		}
		if itemType == nil {
			reject("a " + kind + " div in a section that is not a list container")
			return v
		}
		if kind == "refs" {
			val.refsItems(node, itemType, inner, at)
		} else {
			v = val.recordItems(node, itemType, inner, at, v)
		}
		return v
	}
	return v
}

// itemForm is the form a `refs` item of itemType holds its reference in: the
// type's own form, else the form of its one subsection type that has one (the
// item's virtual child, childType, then carries the value). With oneField,
// only forms of exactly one field count. A record table reads the type's own
// form only (recordItems).
func (val *DocSpecsValidator) itemForm(
	itemType *DocSpecsSectionType, oneField bool,
) (form *DocSpecsFormType, childType *DocSpecsSectionType, ok bool) {
	formOf := func(t *DocSpecsSectionType) *DocSpecsFormType {
		if t == nil || t.Format == "" {
			return nil
		}
		return val.Schema.FormTypes[t.Format]
	}
	fits := func(f *DocSpecsFormType) bool {
		return f != nil && (!oneField || len(f.Fields) == 1)
	}
	if own := formOf(itemType); fits(own) {
		return own, nil, true
	}
	var candForm *DocSpecsFormType
	var candType *DocSpecsSectionType
	n := 0
	for _, name := range itemType.subsectionOrder {
		sub := val.Schema.SectionTypesByName[name]
		if f := formOf(sub); fits(f) {
			candForm, candType = f, sub
			n++
		}
	}
	if n == 1 {
		return candForm, candType, true
	}
	return nil, nil, false
}

// addItem adds a virtual item of itemType with id at line to list; it
// returns the section its form values go to — the item itself, or its
// virtual child of childType (id: the child type's name upper-cased).
func docspecsAddItem(
	list *docspecsNode, itemType, childType *DocSpecsSectionType, id string, line int,
) *docspecsNode {
	item := docspecsVirtual(id, line, itemType)
	list.children = append(list.children, item)
	if childType == nil {
		return item
	}
	child := docspecsVirtual(strings.ToUpper(childType.Name), line, childType)
	item.children = append(item.children, child)
	return child
}

// refsItems reads a `refs` div: its text split on commas and whitespace into
// ids, a link counting as its link text; item <n> gets the positional id (the
// container's id with `-LST` replaced by `-<n>`, else `<id>-<n>`) and the
// virtual body line `<Label>: <id>`.
func (val *DocSpecsValidator) refsItems(
	node *docspecsNode, itemType *DocSpecsSectionType, inner []string, at int,
) {
	// Without a one-field form in the schema the reference is the item's
	// virtual body line; nothing in the schema checks it further.
	form, childType, ok := val.itemForm(itemType, true)
	var ids []string
	for _, tok := range mdRefsSplitRE.Split(strings.Join(inner, " "), -1) {
		if tok == "" {
			continue
		}
		if m := mdLinkTextRE.FindStringSubmatch(tok); m != nil {
			tok = m[1]
		}
		ids = append(ids, tok)
	}
	stem := strings.TrimSuffix(node.id, "-LST")
	label := ""
	if ok {
		label = form.Fields[0].Name
	}
	for n := 1; n <= len(ids); n++ {
		holder := docspecsAddItem(node, itemType, childType, stem+"-"+itoa(n), at)
		holder.values = append(holder.values, docspecsValue{label, ids[n-1], at})
	}
}

// recordItems reads a `records` div: one table, `Id` first, `Title`
// optionally second, then field names of the item's form; each row one
// virtual item in row order.
func (val *DocSpecsValidator) recordItems(
	node *docspecsNode, itemType *DocSpecsSectionType, inner []string, at int,
	v []*DocSpecsViolation,
) []*DocSpecsViolation {
	reject := func(message string) {
		v = append(v, &DocSpecsViolation{
			Rule: DocSpecsRuleMalformedBlock, Line: at, Message: message, SectionID: node.id,
		})
	}
	lineOf := func(k int) int { return at + 1 + k }
	start := -1
	for k, l := range inner {
		if strings.TrimSpace(l) != "" {
			start = k
			break
		}
	}
	if start < 0 || !mdTableLineRE.MatchString(inner[start]) {
		reject("a records div holding no table")
		return v
	}
	header := mdRowCells(inner[start])
	if header[0] != "Id" {
		reject("a records table whose first column is not Id")
		return v
	}
	// The item type's own form decides the columns; an item type the schema
	// gives no form of its own takes its columns as virtual body lines
	// unchecked. A record's cells are the item's own body lines (DocSpecs
	// specification, *The record table*): unlike a `refs` reference they never
	// go to a child's form.
	var own *DocSpecsFormType
	if itemType.Format != "" {
		own = val.Schema.FormTypes[itemType.Format]
	}
	withTitle := len(header) > 1 && header[1] == "Title"
	first := 1
	if withTitle {
		first = 2
	}
	var columns []string
	for _, label := range header[first:] {
		f, found := label, true
		if own != nil {
			found = false
			for _, x := range own.Fields {
				if strings.ToLower(x.Name) == strings.ToLower(label) {
					f, found = x.Name, true
					break
				}
			}
		}
		if !found {
			v = append(v, &DocSpecsViolation{
				Rule:      DocSpecsRuleUnknownField,
				Line:      lineOf(start),
				Message:   "records column \"" + label + "\" names no field of the items",
				SectionID: node.id,
			})
			return v
		}
		columns = append(columns, f)
	}
	var table docspecsTable
	table, v = docspecsReadTable(inner, start, lineOf, node.id, v)
	for _, row := range table.rows {
		holder := docspecsAddItem(node, itemType, nil, docspecsCellID(row.cells[0]), lineOf(row.index))
		for c, column := range columns {
			value := docspecsCellValue(row.cells[first+c])
			if value == "" {
				continue
			}
			holder.values = append(holder.values, docspecsValue{column, value, lineOf(row.index)})
		}
	}
	return v
}
