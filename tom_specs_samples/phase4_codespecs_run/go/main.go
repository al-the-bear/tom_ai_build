// TomSpecs sample — a Phase 4 CodeSpecs run, as far as the Go runtime goes.
//
// The Go port of `../bin/phase4_codespecs_run.dart`. Phase 4 has four stages,
// and the Go runtime carries the first two:
//
//	stage 1  the starting prompt's quality gate   [MECHANICAL]  here
//	stage 2  the extract generator                [MECHANICAL]  here
//	stage 3  the authoring agent                  [JUDGMENT]    the IR, Dart tools
//	stage 4  validating the emitted trio          [MECHANICAL]  Dart tools
//
// Stages 3 and 4 run on the Dart tools (`tomspecs :ir-map`,
// `tomspecs :codespecs-validate`); the Dart sample shows them. This port runs
// the same specification through the gate and the extract generator, and its
// extracts are the ones the Dart sample writes (`CodeSpecsExtract` is in all
// nine runtimes, byte for byte the same).
//
// Run (from this folder; see README.md):  go run .
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
	somv0 "github.com/al-the-bear/tom_ai_build/tom_som_go_v0"
)

// kRoot is the one `@Document` root this run extracts from
// (codespecs_prompt.md §5).
const kRoot = "D00SolutionBlueprint"

// The creation date section-id generation is pinned to (1 January), so the ids
// (and with them `expected_output.txt`) do not change with the calendar.
const (
	kAuthoredMonth = 1
	kAuthoredDay   = 1
)

// inputs is what every gate run takes: the model, the schema and the area
// catalogue.
type inputs struct {
	model   *som.SpecModel
	schema  *som.DocSpecsSchema
	catalog *som.CodeSpecsAreaCatalog
}

func main() {
	in := inputs{
		model:   check(som.SpecModelFromJSON(readCheckout("tom_som_go_v0", "meta", "spec_model.meta.json"))),
		schema:  check(som.DocSpecsSchemaFromYamlText(string(readCheckout("tom_som_go_v0", "schemas", "solution-blueprint", "solution-blueprint.1.0.docspecs-schema.yaml")))),
		catalog: check(som.CodeSpecsAreaCatalogFromJSON(readCheckout("tom_specs_model", "generated-doc", "codespecs", "codespecs_areas.json"))),
	}

	rule("A Phase 4 CodeSpecs run, stage by stage")
	fmt.Println("Every step is marked [MECHANICAL] or [JUDGMENT].")
	fmt.Println()

	extracts := variantA(in)
	variantB(in)

	fmt.Println()
	fmt.Printf("Extracts written to build/codespecs_extracts/ (%d files).\n", len(extracts)*2)
}

// ---------------------------------------------------------------------------
// Variant A — a document that passes, taken as far as the extracts.
// ---------------------------------------------------------------------------

func variantA(in inputs) []*som.CodeSpecsExtract {
	doc := som.NewSpecDocument()
	authorSpecification(newRoot(doc), true)

	rule("Variant A — a sufficient specification")
	fmt.Println("0. The document under Phase 4                 [input]")
	fmt.Println("   a Solution Blueprint whose information model holds 2 entities")
	fmt.Println("   and 4 stored attributes; every other section is unwritten.")
	fmt.Println()

	gate := runGate(in, doc)
	if !gate.Passed() {
		fmt.Fprintln(os.Stderr, "variant A was supposed to pass the gate")
		for _, f := range gate.Findings() {
			fmt.Fprintf(os.Stderr, "  %s\n", f)
		}
		os.Exit(1)
	}
	fmt.Println("   gate verdict             : PASS — the run may begin")
	fmt.Println()

	extracts := gate.Extracts
	stage2(extracts)
	stages3and4()
	return extracts
}

// ---------------------------------------------------------------------------
// Variant B — the same document with one required field cleared.
// ---------------------------------------------------------------------------

func variantB(in inputs) {
	doc := som.NewSpecDocument()
	authorSpecification(newRoot(doc), false)

	rule("Variant B — the same document, one required field cleared")
	fmt.Println("Both entities keep their `DAENT-CLAS` section and its `category`, and")
	fmt.Println("both have `aggregateRoot` cleared. Nothing else changed.")
	fmt.Println()

	gate := runGate(in, doc)
	if gate.Passed() {
		fmt.Fprintln(os.Stderr, "variant B was supposed to be rejected")
		os.Exit(1)
	}
	fmt.Println("   gate verdict             : REJECTED — the run may not begin")
	fmt.Println()
	fmt.Println("   What the gate names, per finding:")
	for _, f := range gate.Findings() {
		fmt.Printf("     %s %s [%s] %s\n", f.Check.Label(), f.Code, f.Location, f.Message)
	}
	fmt.Println()
	a2 := len(gate.Result(som.CodeSpecsGateA2).Findings)
	fmt.Printf("   A2 moved too: %d violations, against 0 for variant A. The\n", a2)
	fmt.Println("   classification form still holds other values, so its empty")
	fmt.Println("   required field is reported by both tiers. They part where a value")
	fmt.Println("   is absent rather than empty: a missing required section is seen by")
	fmt.Println("   A1 alone. That is why the gate runs both tiers and not either one")
	fmt.Println("   (codespecs_prompt.md §4.1/§4.2 and its §10.1/§10.2 fixtures).")
	fmt.Println()
}

// ---------------------------------------------------------------------------
// Stage 1 — the mechanical gate (codespecs_prompt.md §4).
// ---------------------------------------------------------------------------

var titles = map[som.CodeSpecsGateCheck]string{
	som.CodeSpecsGateA1: "schema completeness  ",
	som.CodeSpecsGateA2: "instance-tier values ",
	som.CodeSpecsGateA3: "routing totality     ",
	som.CodeSpecsGateA4: "required arguments   ",
	som.CodeSpecsGateA5: "structured carriers  ",
}

// runGate runs the mechanical tier over doc and prints each check's verdict.
// All five checks run as one gate and none stops the others; a check that
// could not run says so, and the gate does not pass.
func runGate(in inputs, doc *som.SpecDocument) *som.CodeSpecsGateReport {
	fmt.Println("1. The starting prompt's quality gate        [MECHANICAL]")
	report := check(som.NewCodeSpecsGate(in.model, doc, in.catalog, in.schema, kRoot).Run())
	for _, r := range report.Results {
		var verdict string
		switch {
		case !r.Ran:
			verdict = "NOT RUN — " + r.NotRunReason
		case len(r.Findings) == 0:
			verdict = "pass — 0 findings"
		default:
			verdict = fmt.Sprintf("FAIL — %d findings", len(r.Findings))
		}
		fmt.Printf("   %s %s: %s\n", r.Check.Label(), titles[r.Check], verdict)
	}
	fmt.Printf("   (A4 held %d required-argument rows, A5 %d carriers, both from the catalogue's gate tables)\n",
		len(in.catalog.RequiredArguments), len(in.catalog.Carriers))
	return report
}

// ---------------------------------------------------------------------------
// Stage 2 — the extract generator.
// ---------------------------------------------------------------------------

func stage2(extracts []*som.CodeSpecsExtract) {
	fmt.Println("2. The extract generator                      [MECHANICAL]")
	var populated []*som.CodeSpecsExtract
	for _, e := range extracts {
		if len(e.Entries) > 0 {
			populated = append(populated, e)
		}
	}
	fmt.Printf("   areas in the catalogue   : %d\n", len(extracts))
	fmt.Printf("   populated                : %d\n", len(populated))
	for _, e := range populated {
		fmt.Printf("     %-6s %d entries  → %s\n", e.Area.Code, len(e.Entries), strings.Join(e.Projects, ", "))
	}
	fmt.Printf("   empty                    : %d\n", len(extracts)-len(populated))
	fmt.Println("   Most areas are empty because this document says nothing about")
	fmt.Println("   screens, jobs, reports or migrations. An empty extract is a")
	fmt.Println(`   CANDIDATE for "not applicable" — never the verdict itself, which`)
	fmt.Println("   is a judgment and belongs to stage B (codespecs_prompt.md §6.4).")

	out := filepath.Join("build", "codespecs_extracts")
	must(os.MkdirAll(out, 0o755))
	for _, e := range extracts {
		must(os.WriteFile(filepath.Join(out, e.FileStem()+".yaml"), []byte(e.ToYaml()), 0o644))
		must(os.WriteFile(filepath.Join(out, e.FileStem()+".md"), []byte(e.ToMarkdown()), 0o644))
	}
	fmt.Println()

	var db *som.CodeSpecsExtract
	for _, e := range extracts {
		if e.Area.Code == "CE-DB" {
			db = e
		}
	}
	fmt.Printf("   Area %s — %s, the extract the\n", db.Area.Code, db.Area.CanonicalID)
	fmt.Println("   authoring agent reads in stage 3:")
	fmt.Printf("   built on   : %s\n", db.Area.BuiltOn)
	fmt.Printf("   may cite   : %s\n", strings.Join(db.CitableParts, ", "))
	fmt.Printf("   entries carried to the agent (%d):\n", len(db.Entries))
	for _, entry := range db.Entries {
		fmt.Printf("     %-11s %-14s %s\n", entry.SectionID, entry.FieldName, short(entry.Value))
	}
	fmt.Println()
}

func stages3and4() {
	fmt.Println("3. The authoring agent                        [JUDGMENT]")
	fmt.Println("4. Validating the emitted trio                [MECHANICAL]")
	fmt.Println("   Not in the Go runtime. The authoring agent writes the IR")
	fmt.Println("   from these extracts, and the Dart tools map and validate it")
	fmt.Println("   (`tomspecs :ir-map`, `tomspecs :codespecs-validate`); the Dart")
	fmt.Println("   sample in ../bin/ shows both stages on this same specification.")
	fmt.Println()
}

// ---------------------------------------------------------------------------
// The specification — the one the Dart sample authors.
// ---------------------------------------------------------------------------

// authorSpecification writes two entities, four attributes and their keys: one
// area populated and the rest empty. aggregateRoots false clears the one
// required field variant B removes — `DAENT-CLAS.aggregateRoot` — and nothing
// else.
func authorSpecification(sbp *somv0.D00SolutionBlueprint, aggregateRoots bool) {
	sbp.SetContent("Order intake for a single region.")

	// The bounded context CE-SU's required `boundedContext` argument resolves
	// against: an unauthored registry would make the reference dangle at A2.
	ordering := sbp.SolutionArchitectureAndTechnology().TechnicalFramework().SoftwareDesign().
		LayeringAndModuleStructure().BoundedContexts().AddOn(kAuthoredMonth, kAuthoredDay)
	ordering.SetHeadline("Ordering")
	ordering.Content().SetContextName("Ordering")
	ordering.Content().SetDomainArea("Order management")

	entities := sbp.InformationAndDataModel().DataModel().Entities()

	customer := entities.AddOn(kAuthoredMonth, kAuthoredDay)
	customer.SetHeadline("Customer")
	customer.SetContent("A party that places orders.")
	customer.Identity().SetEntityName("Customer")
	customer.Identity().SetTableName("customers")
	customer.Identity().SetEntityAlias("CUST")
	customer.Identity().SetDescription("A person or organisation that places orders.")
	customer.Classification().SetCategory("MasterData")
	customer.Classification().SetBoundedContext("Ordering")
	if aggregateRoots {
		customer.Classification().SetAggregateRoot("Customer")
	}

	email := customer.Attributes().AddOn(kAuthoredMonth, kAuthoredDay)
	email.SetHeadline("email")
	email.Identity().SetColumnName("email")
	email.Identity().SetDescription("The address order confirmations are sent to.")
	email.DataTypeSpec().SetPhysicalType("VARCHAR")

	displayName := customer.Attributes().AddOn(kAuthoredMonth, kAuthoredDay)
	displayName.SetHeadline("displayName")
	displayName.Identity().SetColumnName("display_name")
	displayName.Identity().SetDescription("The name the customer trades under.")
	displayName.DataTypeSpec().SetPhysicalType("VARCHAR")

	// A customer is identified by the address it trades under: a natural key.
	customerKey := customer.KeyAttributes().AddOn(kAuthoredMonth, kAuthoredDay)
	customerKey.SetHeadline("pk_customers")
	customerKey.Content().SetKeyType("Natural")
	customerKey.Content().SetKeyColumns("email")
	customerKey.Content().SetDescription("A customer is identified by its e-mail address.")

	order := entities.AddOn(kAuthoredMonth, kAuthoredDay)
	order.SetHeadline("Order")
	order.SetContent("One accepted customer order.")
	order.Identity().SetEntityName("Order")
	order.Identity().SetTableName("orders")
	order.Identity().SetEntityAlias("ORD")
	order.Identity().SetDescription("A single order placed by a customer.")
	order.Classification().SetCategory("TransactionData")
	order.Classification().SetBoundedContext("Ordering")
	if aggregateRoots {
		order.Classification().SetAggregateRoot("Order")
	}

	orderID := order.Attributes().AddOn(kAuthoredMonth, kAuthoredDay)
	orderID.SetHeadline("orderId")
	orderID.Identity().SetColumnName("order_id")
	orderID.Identity().SetDescription("The identifier the order is filed under.")
	orderID.DataTypeSpec().SetPhysicalType("UUID")

	orderKey := order.KeyAttributes().AddOn(kAuthoredMonth, kAuthoredDay)
	orderKey.SetHeadline("pk_orders")
	orderKey.Content().SetKeyType("Primary")
	orderKey.Content().SetKeyColumns("order_id")
	orderKey.Content().SetDescription("The order identifier.")
	orderKey.Generation().SetGenerationStrategy("UUID")

	placedAt := order.Attributes().AddOn(kAuthoredMonth, kAuthoredDay)
	placedAt.SetHeadline("placedAt")
	placedAt.Identity().SetColumnName("placed_at")
	placedAt.Identity().SetDescription("The moment the order was accepted.")
	placedAt.DataTypeSpec().SetPhysicalType("TIMESTAMP")
}

// ---------------------------------------------------------------------------
// Helpers.
// ---------------------------------------------------------------------------

func newRoot(doc *som.SpecDocument) *somv0.D00SolutionBlueprint {
	sbp, err := somv0.NewD00SolutionBlueprint(doc, "")
	must(err)
	return sbp
}

// readCheckout reads a file of the checkout, given relative to `tom_ai/ai_build`
// (three folders above this one). The Dart packages ship the model, schema and
// area catalogue with accessors; the Go modules read them as files.
func readCheckout(parts ...string) []byte {
	_, file, _, _ := runtime.Caller(0)
	p := filepath.Join(append([]string{filepath.Dir(file), "..", "..", ".."}, parts...)...)
	data, err := os.ReadFile(p)
	must(err)
	return data
}

func short(value string) string {
	r := []rune(value)
	if len(r) <= 44 {
		return value
	}
	return string(r[:41]) + "..."
}

func rule(title string) {
	fmt.Println(strings.Repeat("=", 72))
	fmt.Println(title)
	fmt.Println(strings.Repeat("=", 72))
}

func must(err error) {
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

// check returns value, or stops the sample on err.
func check[T any](value T, err error) T {
	must(err)
	return value
}
