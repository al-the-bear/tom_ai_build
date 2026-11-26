package somruntime

// spec_document_markdown_generated.go — generated parts of a rendition (SOM
// §11.12): tables the rendition derives completely from the links of a
// document, written at the start of the section they belong to as a `derived`
// block and read back as nothing. A port of the Python runtime's
// `spec_document_markdown_generated.py` (itself a port of the JavaScript,
// TypeScript and Dart runtimes' `spec_document_markdown_generated`).
//
// Internal to SpecDocumentMarkdown.

import (
	"regexp"
	"strconv"
	"strings"
)

// mdDerivedPlaceholder is written by the emitter at a generated place without
// a table: replaced by an empty `derived` block when the value written after
// it begins with a `derived` block, else removed with its blank line (SOM
// §11.12).
const mdDerivedPlaceholder = "\x00derived\x00"

// mdRequirementClasses are the requirement classes whose elements are the
// rows of the requirement views: every element `INTR.relatedRequirements` may
// name.
var mdRequirementClasses = []string{"FRE", "TERQ", "SECRQ", "ORRQ"}

// mdGenColumn is a column of a generated table: its header, the place its
// cells read ("": the row's id), whether it says only `yes` / `no`.
type mdGenColumn struct {
	header  string
	place   string
	covered bool
}

// mdGenTable is a generated table: the section ids it opens, its label, the
// classes of its rows, the classes the row's id is taken from (empty: the
// row's own), its columns.
type mdGenTable struct {
	at      []string
	label   string
	rows    []string
	owner   []string
	columns []mdGenColumn
}

// mdGeneratedTables are the generated tables (SOM §11.12): the requirement
// views of DP-part-model-links-5 / -11 (D1–D4) where the links hold a table.
var mdGeneratedTables = []mdGenTable{
	{
		at:    []string{"RSP-TRAC", "RO-TRAC"},
		label: "Generated from each requirement's traceability; edit it there",
		rows:  mdRequirementClasses,
		columns: []mdGenColumn{
			{header: "Requirement"},
			{header: "Use cases", place: "RT-TRAC.relatedUseCases"},
			{header: "Screens", place: "RETRAR.relatedScreens"},
			{header: "Data entities", place: "RETRAR.relatedDataEntities"},
			{header: "Tests", place: "RETRAR.relatedTestCases"},
		},
	},
	{
		at:    []string{"REQCOV"},
		label: "Generated from each requirement's test cases; edit them there",
		rows:  mdRequirementClasses,
		columns: []mdGenColumn{
			{header: "Requirement"},
			{header: "Covered", place: "RETRAR.relatedTestCases", covered: true},
			{header: "By", place: "RETRAR.relatedTestCases"},
		},
	},
	{
		at:    []string{"RERE-REQU-LST"},
		label: "Generated from each requirement's dependencies; edit them there",
		rows:  []string{"RQDEP"},
		owner: mdRequirementClasses,
		columns: []mdGenColumn{
			{header: "Requirement"},
			{header: "Dependency", place: "RQDEP.dependencyType"},
			{header: "Related requirement", place: "RQDEP-RELA-REF.ref"},
		},
	},
	{
		at:    []string{"USCATR"},
		label: "Generated from each use case's traceability; edit it there",
		rows:  []string{"INEN"},
		columns: []mdGenColumn{
			{header: "Use case"},
			{header: "Process", place: "INTR.relatedProcess"},
			{header: "Requirements", place: "INTR.relatedRequirements"},
			{header: "Tests", place: "INTR.relatedTestCases"},
		},
	},
}

// mdGeneratedTableAt returns the generated table opening a heading with
// section id id, nil when none does.
func mdGeneratedTableAt(id string) *mdGenTable {
	for i := range mdGeneratedTables {
		if containsString(mdGeneratedTables[i].at, id) {
			return &mdGeneratedTables[i]
		}
	}
	return nil
}

// mdGenerated is one root's generated parts.
type mdGenerated struct {
	nav       *mdNavigation
	blockMap  map[string][]string
	itemsList []string
	itemsDone bool
}

func newMdGenerated(nav *mdNavigation) *mdGenerated { return &mdGenerated{nav: nav} }

// isPlace reports whether the heading at path is a generated place
// (structural: its section id opens a generated table).
func (g *mdGenerated) isPlace(path string) bool {
	node := g.nav.tree.ByPath(path)
	if node == nil || g.nav.walk(path, nil, g.nav.doc(), nil).headingPath != path {
		return false
	}
	return mdGeneratedTableAt(g.nav.codec.headingIdOf(node)) != nil
}

// blocks returns the blocks of this document, by heading path: only the
// places whose table has rows.
func (g *mdGenerated) blocks() map[string][]string {
	if g.blockMap != nil {
		return g.blockMap
	}
	out := map[string][]string{}
	codec := g.nav.codec
	for _, n := range g.nav.tree.AllNodes() {
		path, _ := n.Path()
		if path == "" || codec.isTransparentSection(n) || mdIsTransparentValue(n) {
			continue
		}
		table := mdGeneratedTableAt(codec.headingIdOf(n))
		if table == nil {
			continue
		}
		if block := g.block(table); block != nil {
			out[path] = block
		}
	}
	g.blockMap = out
	return out
}

// forces reports whether a generated block stands at or beneath path, so the
// heading is written even when the document holds no value there.
func (g *mdGenerated) forces(path string) bool {
	for p := range g.blocks() {
		if p == path || strings.HasPrefix(p, path+"/") {
			return true
		}
	}
	return false
}

// items returns every element of the document, in rendition order.
func (g *mdGenerated) items() []string {
	if g.itemsDone {
		return g.itemsList
	}
	g.itemsDone = true
	doc := g.nav.doc()
	codec := g.nav.codec
	var out []string
	var walk func(node *SomMetaNode, path string)
	walk = func(node *SomMetaNode, path string) {
		for _, child := range codec.effectiveChildren(node) {
			p := path + "/" + child.rel
			if !doc.HasValuesUnder(p) {
				continue
			}
			switch child.node.Kind {
			case SomMetaKindList:
				for _, item := range doc.ListItems(p) {
					out = append(out, item)
					if element := child.node.ElementNode; element != nil && !element.Recursive {
						walk(element, item)
					}
				}
			case SomMetaKindSection, SomMetaKindComplex:
				walk(child.node, p)
			}
		}
	}
	walk(g.nav.tree.Root, g.nav.rootSeg())
	g.itemsList = out
	return out
}

// classID is the section id of the class of the element at item, "" when it
// does not resolve.
func (g *mdGenerated) classID(item string) string {
	r := g.nav.refl.Resolve(item)
	if r == nil || r.TargetClass == nil {
		return ""
	}
	return r.TargetClass.SectionID
}

// block returns the block lines of table, nil when it has no row.
func (g *mdGenerated) block(table *mdGenTable) []string {
	var rows [][]string
	doc := g.nav.doc()
	for _, item := range g.items() {
		classID := g.classID(item)
		if classID == "" || !containsString(table.rows, classID) {
			continue
		}
		var cells []string
		for _, c := range table.columns {
			if c.place == "" {
				cells = append(cells, g.idCell(g.rowOwner(item, table)))
				continue
			}
			r := SpecResolvePlaceAt(g.nav.refl, c.place, item)
			fld := ""
			if r != nil {
				fld = r.Field()
			}
			value := ""
			if r != nil && fld != "" {
				if v, ok := doc.FormField(r.Path, fld); ok {
					value = strings.TrimSpace(v)
				}
			}
			if c.covered {
				if value == "" {
					cells = append(cells, "no")
				} else {
					cells = append(cells, "yes")
				}
				continue
			}
			if value == "" {
				cells = append(cells, "")
				continue
			}
			var meta *SomFormFieldMeta
			if formNode := g.nav.tree.ByPath(r.Path); formNode != nil && formNode.Form != nil {
				for _, f := range formNode.Form.Fields {
					if f.Name == fld {
						meta = f
						break
					}
				}
			}
			if meta == nil {
				cells = append(cells, strings.ReplaceAll(value, "|", `\|`))
			} else {
				cells = append(cells, g.nav.codec.linkedCellText(meta, value))
			}
		}
		rows = append(rows, cells)
	}
	if len(rows) == 0 {
		return nil
	}
	headers := make([]string, len(table.columns))
	delims := make([]string, len(table.columns))
	for i, c := range table.columns {
		headers[i] = c.header
		delims[i] = "---"
	}
	out := []string{
		`::: {.derived label="` + table.label + `"}`,
		"| " + strings.Join(headers, " | ") + " |",
		"| " + strings.Join(delims, " | ") + " |",
	}
	for _, r := range rows {
		out = append(out, "| "+strings.Join(r, " | ")+" |")
	}
	return append(out, ":::")
}

// rowOwner returns the element a row names: itself, or its nearest owner of
// the table's owner classes ("": none).
func (g *mdGenerated) rowOwner(item string, table *mdGenTable) string {
	if len(table.owner) == 0 {
		return item
	}
	p := item
	for strings.Contains(p, "/") {
		p = p[:strings.LastIndex(p, "/")]
		if _, _, ok := g.nav.itemParts(p); ok {
			if id := g.classID(p); id != "" && containsString(table.owner, id) {
				return p
			}
		}
	}
	return ""
}

// idCell returns a link to the element at item by its id and anchor.
func (g *mdGenerated) idCell(item string) string {
	if item == "" {
		return ""
	}
	w := g.nav.walk(item, nil, g.nav.doc(), nil)
	return "[" + w.headingID + "](#" + w.anchor + ")"
}

var (
	mdOpensDerivedRE = regexp.MustCompile(`^ {0,3}:{3,}[ \t]*\{\.derived[\s}]`)
	mdDerivedFenceRE = regexp.MustCompile(`^ {0,3}(:{3,})`)
)

// mdOpensDerived reports whether line opens a `derived` block.
func mdOpensDerived(line string) bool {
	return mdOpensDerivedRE.MatchString(line)
}

// mdDerivedFenceClose returns the closing line pattern of the `derived` block
// line opens.
func mdDerivedFenceClose(line string) *regexp.Regexp {
	m := mdDerivedFenceRE.FindStringSubmatch(line)
	return regexp.MustCompile(`^ {0,3}:{` + strconv.Itoa(len(m[1])) + `,}[ \t]*$`)
}

// mdResolveDerivedPlaceholders returns markdown with every derived
// placeholder resolved: an empty `derived` block where the block after it
// opens a `derived` block, else removed with its blank line.
func mdResolveDerivedPlaceholders(markdown string) string {
	if !strings.Contains(markdown, mdDerivedPlaceholder) {
		return markdown
	}
	lines := strings.Split(markdown, "\n")
	out := make([]string, 0, len(lines))
	for i := 0; i < len(lines); {
		if lines[i] != mdDerivedPlaceholder {
			out = append(out, lines[i])
			i++
			continue
		}
		k := i + 1
		for k < len(lines) && strings.TrimSpace(lines[k]) == "" {
			k++
		}
		if k < len(lines) && mdOpensDerived(lines[k]) {
			out = append(out, "::: {.derived}", ":::")
			i++
		} else {
			i += 2 // the blank line after the placeholder goes with it
		}
	}
	return strings.Join(out, "\n")
}
