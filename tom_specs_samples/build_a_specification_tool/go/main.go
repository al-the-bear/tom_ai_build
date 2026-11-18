// TomSpecs sample — building tooling ON a specification (Go).
//
// The Go port of `../bin/build_a_specification_tool.dart`: the same five steps
// over the same fixture. Its output differs from the Dart sample in the places
// where the Dart text names a Dart-only surface, and in two places where Go
// differs from Dart; `expected_output.txt` here records the Go output, and
// README.md says where it differs.
//
// Run (from this folder; see README.md):  go run .
//
// For the reader who is not authoring specifications but writing programs that
// read them: an editor, a linter, a report, an importer, a migration. That
// reader needs four things, and this sample walks them in the order they are
// needed:
//
//  1. REFLECTION   — what the model CAN hold, read from the metadata tree
//  2. GENERIC      — what a document DOES hold, with no compile-time knowledge
//     of its shape
//  3. SCHEMA       — the generated schema, where it comes from and what it is
//  4. VALIDATION   — the two runtime tiers, and the third that is not here
//  5. A TOOL       — a completeness report built on all four
//
// The individual APIs are demonstrated one at a time in the facade module's
// own examples (`tom_som_go_v0/examples/`): `b_generic_document` and
// `c_reflection_metadata`.
package main

import (
	"encoding/json"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"time"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
	somv0 "github.com/al-the-bear/tom_ai_build/tom_som_go_v0"
)

// kRoot is the document root this sample inspects.
const kRoot = "D00SolutionBlueprint"

// kRootSegment is that root's addressable segment — the first element of every
// path in it.
const kRootSegment = "SBP"

// The creation date section-id generation is pinned to (1 January).
// `SomList.Add` derives an item's id from the current date, so an unpinned run
// would emit different ids every day and `expected_output.txt` would record the
// day it was taken rather than the pipeline.
const (
	kAuthoredMonth = 1
	kAuthoredDay   = 1
)

// kTitleWidth is the report's title column width. Titles are clipped to it
// rather than wrapped: a completeness report is scanned down its numbers, and a
// wrapped title puts a row's two halves on different lines.
const kTitleWidth = 38

func main() {
	metaJSON := readCheckout("tom_som_go_v0", "meta", "spec_model.meta.json")
	model := check(som.SpecModelFromJSON(metaJSON))
	schema := check(som.DocSpecsSchemaFromYamlText(string(readCheckout(
		"tom_som_go_v0", "schemas", "solution-blueprint", "solution-blueprint.1.0.docspecs-schema.yaml"))))

	doc := som.NewSpecDocument()
	authorFixture(newRoot(doc))

	section(0, "The document this run inspects")
	fmt.Println("A Solution Blueprint with a handful of sections written and the")
	fmt.Println("rest left blank — small enough that every number below can be")
	fmt.Println("checked by reading `authorFixture` in this file.")
	fmt.Println()
	fmt.Printf("  content leaves written : %d\n", len(doc.ContentPaths()))
	fmt.Printf("  form sections written  : %d\n", len(doc.FormPaths()))
	fmt.Printf("  lists with items       : %d\n", len(doc.ListPaths()))

	reflectionStep(model, metaJSON)
	genericAccess(model, doc)
	theSchema(schema)
	validation(model, schema, doc)
	theTool(model, schema, doc)
}

// ===========================================================================
// 1. Reflection — what the model CAN hold
// ===========================================================================

func reflectionStep(model *som.SpecModel, metaJSON []byte) {
	section(1, "Reflection — what the model CAN hold")
	fmt.Println("`SpecModel` is the exported class graph; `SpecReflection` is the")
	fmt.Println("value-free query surface over it. No document is involved here.")
	fmt.Println()

	fmt.Println("THE TWO VERSION STAMPS. They answer different questions and a tool")
	fmt.Println("that checks one for the other will accept a file it cannot read:")
	fmt.Printf("  modelVersion      = %d  — WHICH MODEL this snapshot describes\n", model.ModelVersion)
	fmt.Printf("  metaSchemaVersion = %s  — the FILE FORMAT the snapshot itself is written in\n", intOrNull(model.MetaSchemaVersion))
	fmt.Printf("  modelVersionLabel = %s\n", model.ModelVersionLabel)
	// The stamp is printed as the snapshot writes it, so it reads the same in
	// every port whatever precision its clock type keeps.
	var stampOnly struct {
		GeneratedAt string `json:"generatedAt"`
	}
	must(json.Unmarshal(metaJSON, &stampOnly))
	fmt.Printf("  generatedAt       = %s\n", stampOnly.GeneratedAt)
	fmt.Println()
	fmt.Println("A tool reads `metaSchemaVersion` to decide whether it can parse the")
	fmt.Println("file at all, and `modelVersion` to decide whether the documents it")
	fmt.Println("holds are the ones this model describes. `modelVersionLabel` is a")
	fmt.Println("build label for humans — never branch on it.")
	fmt.Println()

	// A snapshot is a photograph. `CheckStamp` compares what the exporter
	// DECLARED against what survived to the reader, and ages the file out. `now`
	// is derived from the model's own stamp so the printed age stays at exactly
	// the offset this sample means to demonstrate. Go has no default arguments:
	// the 30-day threshold is the other runtimes' default.
	exportedAt := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	if model.GeneratedAt != nil {
		exportedAt = *model.GeneratedAt
	}
	stamp := model.CheckStamp(30*24*time.Hour, exportedAt.Add(3*24*time.Hour))
	fmt.Println("SNAPSHOT CHECK (`CheckStamp`), against a fixed clock:")
	age := "null"
	if stamp.Age != nil {
		age = fmt.Sprint(int64(*stamp.Age / (24 * time.Hour)))
	}
	fmt.Printf("  age                 : %s days (aged: %t)\n", age, stamp.IsAged())
	fmt.Printf("  classes  declared/actual : %s/%d  disagrees: %t\n",
		intOrNull(stamp.DeclaredClassCount), stamp.ActualClassCount, stamp.ClassCountDisagrees())
	fmt.Printf("  roots    declared/actual : %s/%d  disagrees: %t\n",
		intOrNull(stamp.DeclaredRootCount), stamp.ActualRootCount, stamp.RootCountDisagrees())
	fmt.Println("  Declared-vs-actual is not redundant: the declared value is what")
	fmt.Println("  the exporter recorded, the actual value is what survived to the")
	fmt.Println("  reader, and a truncated file is exactly where they part.")
	fmt.Println()

	reflection := som.NewSpecReflection(model)
	fmt.Println("SHAPE:")
	fmt.Printf("  document roots : %d\n", len(reflection.Roots()))
	fmt.Printf("  classes        : %d\n", len(reflection.Classes()))
	fmt.Printf("  container root : %s — the one true tree root, which is not itself a document\n", model.ContainerRoot)
	fmt.Println()

	root := reflection.RootForSegment("SBP")
	fields := reflection.FieldsOf(root.Type)
	fmt.Printf("FIELDS of %s (%d total, first 4):\n", root.Type, len(fields))
	for _, f := range fields[:4] {
		fmt.Printf("  %-24s kind=%-8s %s\n", f.Name, kindName(f.Kind), f.Type)
	}
	fmt.Println()

	// A form's slots are on the field itself, not on a separate class — the
	// shape a tool must handle to render or fill one.
	var form *som.SpecField
	for _, f := range reflection.FieldsOf("DataEntityEntry") {
		if f.Kind == som.SpecFieldKindForm {
			form = f
			break
		}
	}
	fmt.Printf("FORM SLOTS of DataEntityEntry.%s (section id %s):\n", form.Name, form.SectionID)
	for _, slot := range form.FormFields {
		fmt.Printf("  %-16s %s\n", slot.Name, slot.Label)
	}
	fmt.Println()

	fmt.Println("ANNOTATIONS the meta carries — the model's own metadata, exported")
	fmt.Println("into the snapshot and therefore visible in ALL NINE language")
	fmt.Println("runtimes, not just Dart:")
	for _, a := range reflection.AnnotationsOf(root.Type) {
		// A Go map has no order: the argument names are sorted.
		names := make([]string, 0, len(a.Arguments))
		for k := range a.Arguments {
			names = append(names, k)
		}
		sort.Strings(names)
		args := ""
		if len(names) > 0 {
			args = "(" + strings.Join(names, ", ") + ")"
		}
		fmt.Printf("  @%s%s\n", a.Name, args)
	}
	// The display semantics of these annotations (`kRenderedAnnotations`) are in
	// the Dart runtime only: they are what the two Flutter apps share.
	fmt.Println("  How each is displayed is the Dart runtime's (`kRenderedAnnotations`,")
	fmt.Println("  shared by the two Flutter apps); the annotations themselves are")
	fmt.Println("  data every runtime reads.")
	fmt.Println()

	fmt.Println("PATH RESOLUTION — a document path to the model node it lands on:")
	for _, p := range []string{
		"SBP",
		"SBP/content",
		"SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST",
		"SBP/informationAndDataModel/nosuchthing",
	} {
		r := reflection.Resolve(p)
		if r == nil {
			fmt.Printf("  %-50s (unresolved)\n", p)
		} else {
			fmt.Printf("  %-50s kind=%s  leaf=%t\n", p, r.Kind, r.IsValueLeaf())
		}
	}
}

// ===========================================================================
// 2. Generic access — what a document DOES hold
// ===========================================================================

func genericAccess(model *som.SpecModel, doc *som.SpecDocument) {
	section(2, "Generic access — what the document DOES hold")
	fmt.Println("`SpecDocument` is a sparse, path-keyed store. A tool reads it")
	fmt.Println("without knowing the document's shape, and asks the model what each")
	fmt.Println("path means. That pairing is the whole of generic access.")
	fmt.Println()

	reflection := som.NewSpecReflection(model)
	fmt.Println("EVERY written content leaf, resolved against the model:")
	for _, p := range sorted(doc.ContentPaths()) {
		kind := "?"
		if r := reflection.Resolve(p); r != nil {
			kind = r.Kind
		}
		fmt.Printf("  %-52s %s\n", p, kind)
		fmt.Printf("      %s\n", clip(doc.ContentOr(p), 66))
	}
	fmt.Println()

	fmt.Println("EVERY written form section, slot by slot:")
	for _, p := range sorted(doc.FormPaths()) {
		fmt.Printf("  %s\n", p)
		for _, slot := range sorted(doc.FormFieldNames(p)) {
			fmt.Printf("      %-16s %s\n", slot, clip(doc.FormFieldOr(p, slot), 52))
		}
	}
	fmt.Println()

	fmt.Println("EVERY list, with its items' section ids:")
	for _, p := range sorted(doc.ListPaths()) {
		fmt.Printf("  %-52s %d item(s)\n", p, doc.ListItemCount(p))
		for _, id := range doc.ListItemSectionIDs(p) {
			fmt.Printf("      %s\n", id)
		}
	}
	fmt.Println()

	fmt.Println("WHERE PATHS COME FROM. A tool must never hard-code a path literal —")
	fmt.Println("a literal is undiscoverable and rots silently when the model moves.")
	fmt.Println("Two safe sources, both from the generated metadata module:")
	fmt.Println()
	fmt.Println("  1. the generated metadata refs —")
	fmt.Println("     D00SolutionBlueprintMeta.InformationAndDataModel().DataModel().Path")
	fmt.Printf("       = %s\n", somv0.D00SolutionBlueprintMeta.InformationAndDataModel().DataModel().Path)
	fmt.Println("  2. the id-keyed metadata tree, for a path known only at runtime —")
	fmt.Println(`     D00SolutionBlueprintMetaTree.ByID("DAENT-ENTI-LST")`)
	nodePath := "<nil>"
	if node := somv0.D00SolutionBlueprintMetaTree.ByID("DAENT-ENTI-LST"); node != nil {
		nodePath = check(node.Path())
	}
	fmt.Printf("       = %s\n", nodePath)
	fmt.Println()
	fmt.Println("  The tree also goes the other way: ByPath gives the node, and with")
	fmt.Println("  it the class, kind and children a generic renderer needs.")
	byPath := somv0.D00SolutionBlueprintMetaTree.ByPath("SBP/informationAndDataModel/dataModel")
	fmt.Println(`     ByPath("SBP/informationAndDataModel/dataModel")`)
	fmt.Printf("       class=%s kind=%s children=%d\n", byPath.ClassName, byPath.Kind, len(byPath.Children))
}

// ===========================================================================
// 3. The generated schema
// ===========================================================================

func theSchema(schema *som.DocSpecsSchema) {
	section(3, "The generated schema")
	fmt.Println("Each of the 14 document roots has a schema GENERATED from the model")
	fmt.Println("and SHIPPED as data inside the facade package, under")
	fmt.Println("`schemas/<document>/<document>.1.0.docspecs-schema.yaml`. A tool")
	fmt.Println("loads one; it never writes one, and never derives one itself.")
	fmt.Println()
	fmt.Println("IT IS A DocSpecs SCHEMA, NOT JSON SCHEMA. It describes a *markdown*")
	fmt.Println("document — headings, their ids, their formats, the form fields a")
	fmt.Println("section carries and which of them are required. A tool reaching for")
	fmt.Println("a JSON-Schema validator will not find one, because the artifact the")
	fmt.Println("schema governs is not JSON.")
	fmt.Println()
	fmt.Printf("  root section id : %s\n", schema.RootSectionID())
	fmt.Printf("  section types   : %d\n", len(schema.SectionTypes))
	fmt.Println()
	fmt.Println("  That count is large because a Solution Blueprint SEEDS the twelve")
	fmt.Println("  Phase-3 documents: its own section classes ARE those documents'")
	fmt.Println("  types, so its schema covers every section id they define. Step 5")
	fmt.Println("  meets the same fact from the other side.")
	fmt.Println()
	fmt.Println("  A section type resolves by ID PREFIX, which is how a generated id")
	fmt.Println("  like `DAENT-ENTI-7` finds its type without the schema listing")
	fmt.Println("  every instance:")
	for _, id := range []string{"DAENT-IDEN", "DAENT-ENTI-7", "NOSUCH-1"} {
		if t := schema.ResolveSectionType(id); t == nil {
			fmt.Printf("    %-16s -> (no type — a tool treats this as unknownSection)\n", id)
		} else {
			fmt.Printf("    %-16s -> %s\n", id, t.Prefix)
		}
	}
}

// ===========================================================================
// 4. Validation — the tiers
// ===========================================================================

func validation(model *som.SpecModel, schema *som.DocSpecsSchema, doc *som.SpecDocument) {
	section(4, "Validation — three tiers, two of them here")
	fmt.Println("THIS IS THE DISTINCTION TOOLING AUTHORS MISS. A tool that wants one")
	fmt.Println("tier and calls another gets nothing useful — not an error, just an")
	fmt.Println("empty list that reads like a pass.")
	fmt.Println()
	fmt.Println("  STATIC tier   — checks the MODEL'S OWN ANNOTATIONS: field-type")
	fmt.Println("                  rules, @ContentType compatibility, cycles, the")
	fmt.Println("                  §10.2 structural invariants. Runs ONCE at")
	fmt.Println("                  generation time, in")
	fmt.Println("                  `tom_specs_clitool/lib/src/validator.dart`, and is")
	fmt.Println("                  deliberately NOT part of the nine-language runtime")
	fmt.Println("                  surface. Not reachable from this sample, and that")
	fmt.Println("                  is the point: by the time a document exists, this")
	fmt.Println("                  tier has already run.")
	fmt.Println("  INSTANCE tier — checks A DOCUMENT'S VALUES against the model:")
	fmt.Println("                  `ValidateDocument` (SOM §9). In every runtime.")
	fmt.Println("  DOCUMENT tier — checks a MARKDOWN RENDITION against the generated")
	fmt.Println("                  schema: `DocSpecsValidator` (SOM §14).")
	fmt.Println()
	fmt.Println("The two runtime tiers overlap and neither implies the other:")
	fmt.Println("`ValidateDocument` reports a required field left empty in a form the")
	fmt.Println("document holds, but not a required section that is absent; the")
	fmt.Println("schema validator reports the absent section, but does not follow a")
	fmt.Println(`reference it sees filled. A tool that wants "is this document good?"`)
	fmt.Println("runs BOTH.")
	fmt.Println()

	instance := som.ValidateDocument(model, doc)
	document := som.NewDocSpecsValidator(schema).ValidateMarkdown(check(doc.ToMarkdown(model, kRoot)))
	fmt.Println("THE FIXTURE, both tiers:")
	fmt.Printf("  instance tier : %d error(s)\n", len(instance))
	fmt.Printf("  document tier : %d violation(s)\n", len(document))
	for i, v := range document {
		if i == 4 {
			break
		}
		fmt.Printf("    line %d: %s [%s] %s\n", v.Line, v.Rule, v.SectionID, clip(v.Message, 54))
	}
	if len(document) > 4 {
		fmt.Printf("    … and %d more\n", len(document)-4)
	}
	fmt.Println()

	// A document broken on purpose, to show the instance tier firing where the
	// document tier cannot see anything wrong.
	broken := som.NewSpecDocument()
	authorFixture(newRoot(broken))
	broken.SetContent("SBP/informationAndDataModel/nosuchsection/content", "x")
	broken.SetFormField("SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAENT-IDEN", "notAField", "x")
	fmt.Println("A DELIBERATELY BROKEN COPY — one path the model does not have, one")
	fmt.Println("form slot the form does not declare:")
	for _, e := range som.ValidateDocument(model, broken) {
		fmt.Printf("  %-20s %s\n", e.Code, clip(e.Path, 50))
	}
	fmt.Println()

	fmt.Println("THE CLOSED VERDICT SETS. Go has no enums: both are closed lists of")
	fmt.Println("string constants, so a tool switches over them exhaustively rather")
	fmt.Println("than matching on message text:")
	codes := som.SpecValidationAllCodes
	fmt.Printf("  SpecValidationAllCodes (%d): %s\n", len(codes), strings.Join(codes, ", "))
	rules := som.DocSpecsAllRules
	fmt.Printf("  DocSpecsAllRules (%d):\n", len(rules))
	for i := 0; i < len(rules); i += 4 {
		end := i + 4
		if end > len(rules) {
			end = len(rules)
		}
		fmt.Printf("    %s\n", strings.Join(rules[i:end], ", "))
	}
}

// ===========================================================================
// 5. The tool
// ===========================================================================

func theTool(model *som.SpecModel, schema *som.DocSpecsSchema, doc *som.SpecDocument) {
	section(5, "A tool: the completeness report")
	fmt.Println("Built on all four surfaces above, and it reports something NEITHER")
	fmt.Println("validator can. The schema names what is REQUIRED and missing; an")
	fmt.Println("optional section left blank is perfectly valid and no validator will")
	fmt.Println(`ever mention it. But "which parts of this specification has nobody`)
	fmt.Println(`written yet?" is the question a specification author actually has,`)
	fmt.Println("and answering it means walking the model and asking the document.")
	fmt.Println()

	report := specificationCoverage(model, doc, kRootSegment)
	fmt.Printf("  %s WRITTEN / OFFERED\n", padRight("SECTION", kTitleWidth))
	for _, row := range report.rows {
		bar := ""
		if row.offered != 0 {
			bar = fmt.Sprintf("%6s", fmt.Sprintf("%d%%", pct(row.written, row.offered)))
		}
		fmt.Printf("  %s %5d / %5d%s\n", padRight(row.title, kTitleWidth), row.written, row.offered, bar)
	}
	fmt.Printf("  %s %s\n", strings.Repeat("-", kTitleWidth), strings.Repeat("-", 19))
	fmt.Printf("  %s %5d / %5d%6s\n", padRight("TOTAL", kTitleWidth), report.written, report.offered,
		fmt.Sprintf("%d%%", pct(report.written, report.offered)))
	fmt.Println()
	largest := report.rows[0]
	for _, r := range report.rows[1:] {
		if r.offered > largest.offered {
			largest = r
		}
	}
	fmt.Printf("  %s offers %d positions because a Solution Blueprint SEEDS\n",
		strings.Split(largest.title, " ")[0], largest.offered)
	fmt.Println("  the twelve Phase-3 documents: its section classes ARE those")
	fmt.Println("  documents' types, so the model surface under an SBP root includes")
	fmt.Println(`  everything it seeds. A tool that reports "0 %" against a number`)
	fmt.Println("  like that should say what the denominator is — which is why the")
	fmt.Println("  report is per section and not one headline figure.")
	fmt.Println()
	fmt.Println("  Required-and-missing, from the schema tier, for contrast:")
	required := 0
	for _, v := range som.NewDocSpecsValidator(schema).ValidateMarkdown(check(doc.ToMarkdown(model, kRoot))) {
		if v.Rule == som.DocSpecsRuleMissingRequiredField {
			required++
		}
	}
	fmt.Printf("    %d missing required field(s) — the only gaps a validator\n", required)
	fmt.Printf("    will name, out of %d unwritten positions.\n", report.offered-report.written)
	fmt.Println()
	fmt.Println("That gap between the two numbers is the tool's reason to exist.")
}

type coverageRow struct {
	title            string
	offered, written int
}

type coverageReport struct {
	rows             []coverageRow
	offered, written int
}

type counter struct{ offered, written int }

// specificationCoverage walks model from rootSegment and counts, per top-level
// section, how many content positions the model offers and how many doc has
// written.
//
// **Lists count as one position, not as their items.** A list the author left
// empty offers exactly one thing to write — the first item — and a list with
// forty items has not made the document forty times more complete.
//
// The walk is entirely generic: it knows no class or field name, so it works
// unchanged against any of the fourteen document roots.
func specificationCoverage(model *som.SpecModel, doc *som.SpecDocument, rootSegment string) coverageReport {
	reflection := som.NewSpecReflection(model)
	root := reflection.RootForSegment(rootSegment)
	var report coverageReport
	for _, field := range reflection.FieldsOf(root.Type) {
		if field.Kind == som.SpecFieldKindContent {
			continue // the root's own body
		}
		c := &counter{}
		walk(reflection, doc, c, field, rootSegment+"/"+reflection.FieldSegment(field), map[string]bool{root.Type: true})
		if c.offered == 0 {
			continue
		}
		report.rows = append(report.rows, coverageRow{title: rowTitle(field), offered: c.offered, written: c.written})
		report.offered += c.offered
		report.written += c.written
	}
	return report
}

// walk adds every content position under field at path. seen carries the class
// names already on this branch; the model is a graph, and a section type that
// can contain itself would otherwise recurse forever.
func walk(reflection *som.SpecReflection, doc *som.SpecDocument, c *counter, field *som.SpecField, path string, seen map[string]bool) {
	switch field.Kind {
	case som.SpecFieldKindContent, som.SpecFieldKindScalar, som.SpecFieldKindEnum:
		c.offered++
		if doc.HasContent(path) {
			c.written++
		}
	case som.SpecFieldKindForm:
		for _, slot := range field.FormFields {
			c.offered++
			if doc.FormFieldOr(path, slot.Name) != "" {
				c.written++
			}
		}
	case som.SpecFieldKindList:
		c.offered++
		if doc.ListItemCount(path) > 0 {
			c.written++
		}
	case som.SpecFieldKindSection, som.SpecFieldKindComplex:
		typ := field.Type
		if typ == "" || seen[typ] {
			return
		}
		next := map[string]bool{typ: true}
		for k := range seen {
			next[k] = true
		}
		for _, child := range reflection.FieldsOf(typ) {
			walk(reflection, doc, c, child, path+"/"+reflection.FieldSegment(child), next)
		}
	}
}

// rowTitle is a section's title for the report — its model doc comment's first
// sentence, falling back to the field name where the model carries no doc.
func rowTitle(field *som.SpecField) string {
	text := strings.TrimSpace(strings.Split(field.Doc, "\n")[0])
	if stop := strings.Index(text, ". "); stop >= 0 {
		text = text[:stop]
	}
	text = strings.TrimSpace(strings.TrimRight(text, "."))
	if text == "" {
		return field.Name
	}
	r := []rune(text)
	if len(r) <= kTitleWidth {
		return text
	}
	return string(r[:kTitleWidth-1]) + "…"
}

// ===========================================================================
// The fixture
// ===========================================================================

// authorFixture writes the small, deliberately incomplete document this run
// inspects — the same one the Dart sample writes.
func authorFixture(sbp *somv0.D00SolutionBlueprint) {
	sbp.SetContent("A platform that unifies our fragmented order systems.")
	sbp.IntroductionAndScope().SetContent("Replace three regional order desks with one intake service.")
	sbp.CurrentLandscape().SetContent("Three legacy systems with no shared customer record.")

	metrics := sbp.CurrentLandscape().OperationalMetrics()
	metrics.AddContentOn("Average order turnaround: 4.2 days.", kAuthoredMonth, kAuthoredDay)
	metrics.AddContentOn("Manual reconciliation: ~12 hours per week.", kAuthoredMonth, kAuthoredDay)

	customer := sbp.InformationAndDataModel().DataModel().Entities().AddOn(kAuthoredMonth, kAuthoredDay)
	customer.SetHeadline("Customer")
	identity := customer.Identity()
	identity.SetEntityName("Customer")
	identity.SetTableName("customers")
	identity.SetDescription("A party that places orders.")
	// `category` is written and `aggregateRoot` is not, and `aggregateRoot` is
	// REQUIRED — so the schema tier has one real violation to report in step 4.
	customer.Classification().SetCategory("MasterData")
}

// ===========================================================================
// Small helpers
// ===========================================================================

func newRoot(doc *som.SpecDocument) *somv0.D00SolutionBlueprint {
	return check(somv0.NewD00SolutionBlueprint(doc, ""))
}

// readCheckout reads a file of the checkout, given relative to `tom_ai/ai_build`
// (three folders above this one). The Dart packages ship the model and the
// schemas with accessors; the Go modules ship them as files.
func readCheckout(parts ...string) []byte {
	_, file, _, _ := runtime.Caller(0)
	return check(os.ReadFile(filepath.Join(append([]string{filepath.Dir(file), "..", "..", ".."}, parts...)...)))
}

func section(n int, title string) {
	fmt.Println()
	fmt.Println(strings.Repeat("=", 74))
	fmt.Printf("%d. %s\n", n, title)
	fmt.Println(strings.Repeat("=", 74))
}

func clip(s string, width int) string {
	r := []rune(strings.ReplaceAll(s, "\n", " "))
	if len(r) <= width {
		return string(r)
	}
	return string(r[:width-1]) + "…"
}

// padRight pads to width runes (fmt's %-*s counts bytes, and titles may hold
// multi-byte characters such as the ellipsis).
func padRight(s string, width int) string {
	if n := len([]rune(s)); n < width {
		return s + strings.Repeat(" ", width-n)
	}
	return s
}

func pct(written, offered int) int {
	return int(math.Round(100 * float64(written) / float64(offered)))
}

func sorted(values []string) []string {
	out := append([]string(nil), values...)
	sort.Strings(out)
	return out
}

func intOrNull(v *int) string {
	if v == nil {
		return "null"
	}
	return fmt.Sprint(*v)
}

// kindName is a field kind by the name the Dart enum gives it (`enum` is
// `enumValue`).
func kindName(kind string) string {
	if kind == som.SpecFieldKindEnum {
		return "enumValue"
	}
	return kind
}

func check[T any](value T, err error) T {
	must(err)
	return value
}

func must(err error) {
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
