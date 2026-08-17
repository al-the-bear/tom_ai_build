package somruntime

// spec_codespecs_extract.go — the Phase-4 **specification extract generator**,
// the machine half of CodeSpecs production (`codespecs_mapping.md` §1.1.1), a
// faithful port of `tom_som_dart_runtime/lib/src/spec_codespecs_extract.dart`.
//
// Phase 4 runs in two passes. This surface is the first: for each CodeSpecs area
// it collects everything in a filled specification document that
// `@CodeSpecKind` routes to that area, **verbatim and with provenance**, so the
// second pass — an authoring agent, one prompt per authoring step — writes
// against a bounded extract rather than against a 652-section document.
//
// The boundary between the two passes is a rule, not a preference. This
// generator may **copy and index**; it may not summarise, rephrase, compose a
// sentence out of field values, or choose a name — the prohibitions of
// `codespecs_derivation_contract.md` §2.8 **C1**, which bind the extract
// generator word for word. The consequence is checkable rather than trusted:
// every CodeSpecsExtractEntry.Value is a string the document stores, byte for
// byte, and the conformance corpus asserts it.
//
// Three things follow from that and shape the API:
//
//   - **Routing is by the three verdicts** (`codespecs_mapping.md` §8.3) — a
//     class carries `@CodeSpecKind` (feeds code), sits under a `@FollowUpKind`
//     root (feeds a non-generation process), or carries `@NoArtifact` (feeds
//     nothing). The trio is exhaustive by construction, so a class carrying none
//     of them is not "skipped": it is a CodeSpecsExtractError, the `ROUTE-TOTAL`
//     invariant (`tom_specs_model_rules.md` §10.2) failing loudly at the one
//     place that depends on it.
//   - **`@CodeSpecKind` is list-valued** (§9.1), and extracts are **not**
//     deduplicated across areas: a section feeding three areas appears, whole,
//     in three extracts. Each area's prompt must be self-sufficient.
//   - **Every entry carries its provenance** — section id, class, field, the
//     routing marker that put it here and where that marker was declared — so
//     the `@DocSpec`/`DocRef` back-links (§9.3) can be written from the extract
//     alone.
//
// The area catalogue (CodeSpecsAreaCatalog) is an **input**, not a table baked
// into the runtime: it is the machine-readable form of `codespecs_mapping.md`
// §4.1 (the parts catalogue), §4.4.3 (the emission slices) and §4.4.6 (the
// authoring steps), authored once and read by all nine runtimes. Carrying it
// beside the content is what stops an agent having to open the mapping document
// to find out what `CE-FM` means.
//
// # Go's stand-ins for the reference's optionals and throw
//
// The reference's nullable `String? note` / `String? formField` become plain
// strings whose "" means *absent* — the same convention SpecResolution and
// SpecQuery already use, and safe here because neither an annotation note nor a
// form-field name can meaningfully be the empty string. The nullable emitters
// below therefore render "" back as YAML `null`, so the goldens agree with the
// reference byte for byte.
//
// The reference's `extractAll()` **throws** CodeSpecsExtractError; this port
// returns it, following the package's error convention (see SpecCreationError in
// spec_node_creation.go). The walk carries the concrete *CodeSpecsExtractError
// rather than the `error` interface for the same reason spelled out there: a
// typed nil stored in an interface is not nil.

import (
	"encoding/json"
	"strings"
)

// CodeSpecsExtractFormatVersion is the version of the emitted extract artifact's
// on-disk shape. Bumped when the YAML or Markdown layout changes in a way a
// reader could notice.
const CodeSpecsExtractFormatVersion = 1

// The annotation names of the three routing verdicts (`codespecs_mapping.md`
// §8.3). All three ride the generic annotation bag in every SOM runtime (§8.4),
// so they are read by name rather than through a meta slot.
const (
	// CodeSpecKindAnnotation names `@CodeSpecKind(List<CodeSpecPart>, {note})`.
	CodeSpecKindAnnotation = "CodeSpecKind"
	// FollowUpKindAnnotation names `@FollowUpKind(List<FollowUpProcess>, {note})`.
	FollowUpKindAnnotation = "FollowUpKind"
	// NoArtifactAnnotation names `@NoArtifact(NoArtifactReason, {note})`.
	NoArtifactAnnotation = "NoArtifact"
)

// Which of the three `codespecs_mapping.md` §8.3 verdicts a class carries.
const (
	// CodeSpecsVerdictFeedsCode: `@CodeSpecKind(List<CodeSpecPart>)` — the
	// section's content is shown to every named area's extract.
	CodeSpecsVerdictFeedsCode = "feedsCode"

	// CodeSpecsVerdictFeedsProcess: `@FollowUpKind(List<FollowUpProcess>)` — the
	// section is delivered by a non-generation process. The whole subtree is
	// excluded from every extract.
	CodeSpecsVerdictFeedsProcess = "feedsProcess"

	// CodeSpecsVerdictFeedsNothing: `@NoArtifact(NoArtifactReason)` — the section
	// deliberately produces no downstream artifact. Its own leaves contribute
	// nothing; its children are still routed individually (that is what
	// `container` means).
	CodeSpecsVerdictFeedsNothing = "feedsNothing"

	// CodeSpecsVerdictDocumentRoot: a `@Document` root carrying no verdict.
	// Structurally exempt from `ROUTE-TOTAL`: a root is the document, not a
	// section of it.
	CodeSpecsVerdictDocumentRoot = "documentRoot"

	// CodeSpecsVerdictUnrouted: no verdict, and not a `@Document` root — a
	// `ROUTE-TOTAL` violation, and the reason CodeSpecsExtractor.ExtractAll
	// fails.
	CodeSpecsVerdictUnrouted = "unrouted"
)

// CodeSpecsRoutingVerdict is the verdict domain — one of the
// CodeSpecsVerdict* constants. A string alias (rather than a defined type) so it
// matches the string-constant enum convention the rest of this package uses for
// SpecNodeKind, SpecStateFilter and SpecCreationCode; the values are the
// reference enum's `name`s, so they cross the conformance corpus unchanged.
type CodeSpecsRoutingVerdict = string

// CodeSpecsAllRoutingVerdicts is the complete verdict vocabulary, in declaration
// order — the Go stand-in for the reference enum's `values`.
var CodeSpecsAllRoutingVerdicts = []string{
	CodeSpecsVerdictFeedsCode,
	CodeSpecsVerdictFeedsProcess,
	CodeSpecsVerdictFeedsNothing,
	CodeSpecsVerdictDocumentRoot,
	CodeSpecsVerdictUnrouted,
}

// CodeSpecsRouting is the verdict recorded for one class node of the walked
// document, with the provenance of the marker that decided it.
type CodeSpecsRouting struct {
	// Path is the document path of the node the verdict was computed for.
	Path string
	// ClassName is the model class at Path.
	ClassName string
	// Verdict is which verdict the class carries (a CodeSpecsVerdict* constant).
	Verdict CodeSpecsRoutingVerdict
	// Values is the verdict's payload, verbatim from the annotation: the
	// `CodeSpecPart.*` values for CodeSpecsVerdictFeedsCode, the
	// `FollowUpProcess.*` values for CodeSpecsVerdictFeedsProcess, the single
	// `NoArtifactReason.*` for CodeSpecsVerdictFeedsNothing, and empty for the
	// two verdicts that have no marker.
	Values []string
	// Note is the marker's optional `note`, verbatim; "" when it carries none.
	Note string
	// DeclaredAt is where the marker was declared — the class name, or
	// `Class.field` when a field-level `@CodeSpecKind` overrode its class. Empty
	// when there is no marker.
	DeclaredAt string
}

// String renders the routing, matching the reference's toString().
func (r CodeSpecsRouting) String() string {
	return "CodeSpecsRouting(" + r.Path + ", " + r.ClassName + ", " + r.Verdict + ")"
}

// CodeSpecsExtractEntry is one extract entry: a single value the specification
// document stores, with everything needed to trace it back
// (`codespecs_mapping.md` §1.1.1, "Entry").
type CodeSpecsExtractEntry struct {
	// AreaCode is the `CE-*` code of the area this entry was collected for.
	AreaCode string
	// SectionID is the section id of the leaf the value sits on (`@SectionId`,
	// else the model field name).
	SectionID string
	// Path is the document path of the leaf — the source location.
	Path string
	// ClassName is the model class declaring the leaf.
	ClassName string
	// FieldName is the model field name of the leaf.
	FieldName string
	// FormField is the form-field name when the value is one field of a `@Form`
	// section; "" for a content, enum, scalar or scalar-list leaf.
	FormField string
	// RoutedBy is the `CodeSpecPart.*` value that routed this entry here,
	// verbatim.
	RoutedBy string
	// RoutedAt is where that `@CodeSpecKind` was declared — the class name, or
	// `Class.field` for a field-level override.
	RoutedAt string
	// RoutingNote is the `@CodeSpecKind` `note`, verbatim; "" when it carries
	// none.
	RoutingNote string
	// Value is the stored value, **verbatim**. Never assembled, reformatted or
	// trimmed.
	Value string
}

// String renders the entry, matching the reference's toString().
func (e CodeSpecsExtractEntry) String() string {
	return "CodeSpecsExtractEntry(" + e.AreaCode + ", " + e.Path + ")"
}

// CodeSpecsSlice is one emission slice of `codespecs_mapping.md` §4.4.3.
type CodeSpecsSlice struct {
	// Number is the slice's number, 1–7.
	Number int
	// Title is the slice's name as §4.4.3 gives it.
	Title string
	// Project is the §4.2 project the slice emits into.
	Project string
	// Cites are the slices this one may cite — §4.4.3's across-slice edges.
	// Transitively closed by CodeSpecsAreaCatalog.CitableAreaCodes.
	Cites []int
}

// CodeSpecsArea is one row of the `codespecs_mapping.md` §4.1 parts catalogue,
// plus the §4.4.3 slice and §4.4.6 authoring steps that place it. This is the
// **per-area context** an extract carries beside its content.
type CodeSpecsArea struct {
	// Code is the permanent registry key — `CE-FM`, `CE-API`. Never reused,
	// never renamed, and the extract file's name.
	Code string
	// CanonicalID is the §4.1 canonical id — the PascalCase noun (`Form`,
	// `ServerApi`).
	CanonicalID string
	// Part is the `CodeSpecPart` value, camelCase and **without** the enum prefix
	// (`form`, `serverApi`).
	Part string
	// Annotations are the `Cs*` annotation names of the §4.1 row.
	Annotations []string
	// BuiltOn is the §4.1 "Built on" cell, verbatim.
	BuiltOn string
	// AttributeSurface is where the area's spec-authorable attribute surface is
	// stated — a §5.x citation.
	AttributeSurface string
	// Slices are the §4.4.3 slice(s) the area's emission units sit in. More than
	// one when the area is split by locus.
	Slices []int
	// AuthoringSteps are the §4.4.6 authoring step(s) that write the area.
	AuthoringSteps []int
	// Active reports whether the part is active. A deferred part (§4.3) holds a
	// reserved `CodeSpecPart` value but has no generated surface, so it gets no
	// extract.
	Active bool
}

// KindValue is the fully-qualified `@CodeSpecKind` value — `CodeSpecPart.form`.
func (a *CodeSpecsArea) KindValue() string { return "CodeSpecPart." + a.Part }

// String renders the area, matching the reference's toString().
func (a *CodeSpecsArea) String() string { return "CodeSpecsArea(" + a.Code + ")" }

// CodeSpecsAreaCatalog is the machine-readable form of `codespecs_mapping.md`
// §4.1 + §4.4.3 + §4.4.6.
//
// Authored once, read by all nine runtimes. It is an input rather than a baked
// table because the catalogue is the mapping document's content: a copy per
// runtime would be nine things to keep current, and the one thing this quest has
// learned three times is that a vocabulary duplicated nine ways can be wrong in
// agreement.
type CodeSpecsAreaCatalog struct {
	// Source is where the catalogue was transcribed from, for the extract header.
	Source string
	// Slices are the §4.4.3 slices, in emission order.
	Slices []*CodeSpecsSlice
	// Areas are the §4.1 areas, in catalogue order. Catalogue order is the
	// tie-break §4.4.6 rule 2 uses, so it is load-bearing rather than cosmetic.
	Areas []*CodeSpecsArea
}

// codeSpecsSliceJSON, codeSpecsAreaJSON and codeSpecsCatalogJSON mirror the
// catalogue's on-disk shape for unmarshalling. `active` is a *bool because its
// absence means **true** (the reference's `?? true`), which a plain bool cannot
// tell from an authored `false`.
type codeSpecsSliceJSON struct {
	Number  int    `json:"number"`
	Title   string `json:"title"`
	Project string `json:"project"`
	Cites   []int  `json:"cites"`
}

type codeSpecsAreaJSON struct {
	Code             string   `json:"code"`
	CanonicalID      string   `json:"canonicalId"`
	Part             string   `json:"part"`
	Annotations      []string `json:"annotations"`
	BuiltOn          string   `json:"builtOn"`
	AttributeSurface string   `json:"attributeSurface"`
	Slices           []int    `json:"slices"`
	AuthoringSteps   []int    `json:"authoringSteps"`
	Active           *bool    `json:"active"`
}

type codeSpecsCatalogJSON struct {
	Source string                `json:"source"`
	Slices []*codeSpecsSliceJSON `json:"slices"`
	Areas  []*codeSpecsAreaJSON  `json:"areas"`
}

// CodeSpecsAreaCatalogFromJSON decodes the authored catalogue, normalising every
// absent list to an empty (non-nil) slice and every absent `active` to true.
func CodeSpecsAreaCatalogFromJSON(data []byte) (*CodeSpecsAreaCatalog, error) {
	var raw codeSpecsCatalogJSON
	if err := json.Unmarshal(data, &raw); err != nil {
		return nil, err
	}
	catalog := &CodeSpecsAreaCatalog{
		Source: raw.Source,
		Slices: make([]*CodeSpecsSlice, 0, len(raw.Slices)),
		Areas:  make([]*CodeSpecsArea, 0, len(raw.Areas)),
	}
	for _, s := range raw.Slices {
		catalog.Slices = append(catalog.Slices, &CodeSpecsSlice{
			Number:  s.Number,
			Title:   s.Title,
			Project: s.Project,
			Cites:   cseInts(s.Cites),
		})
	}
	for _, a := range raw.Areas {
		active := true
		if a.Active != nil {
			active = *a.Active
		}
		catalog.Areas = append(catalog.Areas, &CodeSpecsArea{
			Code:             a.Code,
			CanonicalID:      a.CanonicalID,
			Part:             a.Part,
			Annotations:      cseStrings(a.Annotations),
			BuiltOn:          a.BuiltOn,
			AttributeSurface: a.AttributeSurface,
			Slices:           cseInts(a.Slices),
			AuthoringSteps:   cseInts(a.AuthoringSteps),
			Active:           active,
		})
	}
	return catalog, nil
}

// ActiveAreas returns the active areas, in catalogue order — one extract each.
func (c *CodeSpecsAreaCatalog) ActiveAreas() []*CodeSpecsArea {
	out := []*CodeSpecsArea{}
	for _, a := range c.Areas {
		if a.Active {
			out = append(out, a)
		}
	}
	return out
}

// ByCode returns the area with this `CE-*` code, or nil.
func (c *CodeSpecsAreaCatalog) ByCode(code string) *CodeSpecsArea {
	for _, a := range c.Areas {
		if a.Code == code {
			return a
		}
	}
	return nil
}

// ByPart returns the area a `@CodeSpecKind` value names, or nil. It accepts both
// the bare value (`form`) and the qualified one (`CodeSpecPart.form`), because
// the meta carries the qualified spelling and callers reach for the bare one.
func (c *CodeSpecsAreaCatalog) ByPart(value string) *CodeSpecsArea {
	bare := strings.TrimPrefix(value, "CodeSpecPart.")
	for _, a := range c.Areas {
		if a.Part == bare {
			return a
		}
	}
	return nil
}

// SliceNumbered returns the slice numbered number, or nil.
func (c *CodeSpecsAreaCatalog) SliceNumbered(number int) *CodeSpecsSlice {
	for _, s := range c.Slices {
		if s.Number == number {
			return s
		}
	}
	return nil
}

// ProjectsFor returns the §4.2 projects area's code lands in, in slice order.
//
// Derived from the area's slices rather than authored on the area: §4.4.3
// already fixes one project per slice, so a per-area project column would be a
// second place for the same fact to be stated — and the areas that would need it
// are exactly the locus-split ones, where getting it wrong is easiest.
func (c *CodeSpecsAreaCatalog) ProjectsFor(area *CodeSpecsArea) []string {
	out := []string{}
	for _, n := range area.Slices {
		slice := c.SliceNumbered(n)
		if slice == nil || slice.Project == "" || containsString(out, slice.Project) {
			continue
		}
		out = append(out, slice.Project)
	}
	return out
}

// CitableAreaCodes returns the area codes area may cite — every other active
// area whose emission units sit in a slice area's slices reach, following
// §4.4.3's edges transitively. Within-slice citation is legal, so an area's own
// slices are part of the reachable set; the area itself is excluded.
//
// Derived rather than authored: a hand-kept per-area citation list is a second
// source of truth for something the slice graph already decides.
func (c *CodeSpecsAreaCatalog) CitableAreaCodes(area *CodeSpecsArea) []string {
	reachable := map[int]bool{}
	stack := append([]int{}, area.Slices...)
	for len(stack) > 0 {
		n := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		if reachable[n] {
			continue
		}
		reachable[n] = true
		if slice := c.SliceNumbered(n); slice != nil {
			stack = append(stack, slice.Cites...)
		}
	}
	out := []string{}
	for _, a := range c.Areas {
		if !a.Active || a.Code == area.Code {
			continue
		}
		for _, s := range a.Slices {
			if reachable[s] {
				out = append(out, a.Code)
				break
			}
		}
	}
	return out
}

// CodeSpecsExtract is one area's extract: the area's context plus every routed
// entry, in SOM document order.
type CodeSpecsExtract struct {
	// Area is the area this extract is for.
	Area *CodeSpecsArea
	// CatalogSource is the `codespecs_mapping.md` §4.1/§4.4.3 source the
	// catalogue names.
	CatalogSource string
	// DocumentRoot is the section segment of the document root the entries were
	// collected from.
	DocumentRoot string
	// CitableParts are the area codes this area may cite (§4.4.3), for the
	// agent's prompt.
	CitableParts []string
	// Projects are the §4.2 projects the area's code lands in (§4.4.3, via the
	// slices).
	Projects []string
	// Entries are the routed entries, in SOM document order.
	Entries []CodeSpecsExtractEntry
}

// FileStem is the extract's file name stem — `CE-FM.extract`.
func (x *CodeSpecsExtract) FileStem() string { return x.Area.Code + ".extract" }

// ToYaml renders the artifact of record (`codespecs_mapping.md` §1.1.1). Scalars
// are emitted as JSON strings, which are valid YAML 1.2 double-quoted scalars —
// so one escaping rule, identical in all nine runtimes, covers every value a
// specification can hold.
func (x *CodeSpecsExtract) ToYaml() string {
	var b strings.Builder
	b.WriteString("# " + x.Area.Code + ".extract.yaml — generated by " +
		"spec_codespecs_extract. Do not edit.\n")
	b.WriteString("extract:\n")
	b.WriteString("  formatVersion: " + itoa(CodeSpecsExtractFormatVersion) + "\n")
	b.WriteString("  catalogSource: " + cseYamlString(x.CatalogSource) + "\n")
	b.WriteString("  area:\n")
	b.WriteString("    code: " + cseYamlString(x.Area.Code) + "\n")
	b.WriteString("    canonicalId: " + cseYamlString(x.Area.CanonicalID) + "\n")
	b.WriteString("    part: " + cseYamlString(x.Area.KindValue()) + "\n")
	b.WriteString("    annotations: " + cseYamlStringList(x.Area.Annotations) + "\n")
	b.WriteString("    builtOn: " + cseYamlString(x.Area.BuiltOn) + "\n")
	b.WriteString("    attributeSurface: " + cseYamlString(x.Area.AttributeSurface) + "\n")
	b.WriteString("    slices: " + cseYamlIntList(x.Area.Slices) + "\n")
	b.WriteString("    authoringSteps: " + cseYamlIntList(x.Area.AuthoringSteps) + "\n")
	b.WriteString("    projects: " + cseYamlStringList(x.Projects) + "\n")
	b.WriteString("    citableParts: " + cseYamlStringList(x.CitableParts) + "\n")
	b.WriteString("  document:\n")
	b.WriteString("    root: " + cseYamlString(x.DocumentRoot) + "\n")
	b.WriteString("    entryCount: " + itoa(len(x.Entries)) + "\n")
	if len(x.Entries) == 0 {
		b.WriteString("  entries: []\n")
		return b.String()
	}
	b.WriteString("  entries:\n")
	for _, e := range x.Entries {
		b.WriteString("    - sectionId: " + cseYamlString(e.SectionID) + "\n")
		b.WriteString("      path: " + cseYamlString(e.Path) + "\n")
		b.WriteString("      className: " + cseYamlString(e.ClassName) + "\n")
		b.WriteString("      fieldName: " + cseYamlString(e.FieldName) + "\n")
		b.WriteString("      formField: " + cseYamlNullableString(e.FormField) + "\n")
		b.WriteString("      routedBy: " + cseYamlString(e.RoutedBy) + "\n")
		b.WriteString("      routedAt: " + cseYamlString(e.RoutedAt) + "\n")
		b.WriteString("      routingNote: " + cseYamlNullableString(e.RoutingNote) + "\n")
		b.WriteString("      value: " + cseYamlString(e.Value) + "\n")
	}
	return b.String()
}

// ToMarkdown renders the view. Regenerated from the YAML's own data — nothing
// reads the Markdown as input — and exists because the agent reads it far better
// than it reads YAML.
func (x *CodeSpecsExtract) ToMarkdown() string {
	var b strings.Builder
	b.WriteString("# " + x.Area.Code + " — " + x.Area.CanonicalID + "\n")
	b.WriteString("\n")
	b.WriteString("Generated by `spec_codespecs_extract` from the specification " +
		"document rooted at `" + x.DocumentRoot + "`.\n")
	b.WriteString("`" + x.Area.Code + ".extract.yaml` beside this file is the " +
		"artifact of record; this is a view of it.\n")
	b.WriteString("\n")
	b.WriteString("## Area\n")
	b.WriteString("\n")
	b.WriteString("| | |\n")
	b.WriteString("|---|---|\n")
	b.WriteString("| CE code | `" + x.Area.Code + "` |\n")
	b.WriteString("| Canonical id | `" + x.Area.CanonicalID + "` |\n")
	b.WriteString("| `@CodeSpecKind` value | `" + x.Area.KindValue() + "` |\n")
	b.WriteString("| `Cs*` annotations | " + cseMdCodeList(x.Area.Annotations) + " |\n")
	b.WriteString("| Built on | " + cseMdCell(x.Area.BuiltOn) + " |\n")
	b.WriteString("| Attribute surface | " + cseMdCell(x.Area.AttributeSurface) + " |\n")
	b.WriteString("| Slice(s) | " + cseMdIntList(x.Area.Slices) + " |\n")
	b.WriteString("| Authoring step(s) | " + cseMdIntList(x.Area.AuthoringSteps) + " |\n")
	b.WriteString("| Project(s) | " + cseMdCodeList(x.Projects) + " |\n")
	b.WriteString("| May cite | " + cseMdCodeList(x.CitableParts) + " |\n")
	b.WriteString("| Catalogue source | " + cseMdCell(x.CatalogSource) + " |\n")
	b.WriteString("\n")
	b.WriteString("## Entries (" + itoa(len(x.Entries)) + ")\n")
	b.WriteString("\n")
	if len(x.Entries) == 0 {
		b.WriteString("_No section of this document is routed to " +
			"`" + x.Area.KindValue() + "`._\n")
		return b.String()
	}
	n := 0
	for _, e := range x.Entries {
		n++
		member := e.FieldName
		if e.FormField != "" {
			member = e.FieldName + "." + e.FormField
		}
		b.WriteString("### " + itoa(n) + ". `" + e.SectionID + "` — `" +
			e.ClassName + "." + member + "`\n")
		b.WriteString("\n")
		b.WriteString("- path: `" + e.Path + "`\n")
		b.WriteString("- routed by: `" + e.RoutedBy + "` declared on `" + e.RoutedAt + "`\n")
		if e.RoutingNote != "" {
			b.WriteString("- routing note: " + cseMdCell(e.RoutingNote) + "\n")
		}
		b.WriteString("\n")
		fence := cseFenceFor(e.Value)
		b.WriteString(fence + " text\n")
		b.WriteString(e.Value + "\n")
		b.WriteString(fence + "\n")
		b.WriteString("\n")
	}
	return b.String()
}

// CodeSpecsExtractError is returned when the document cannot be extracted from
// at all.
//
// The only cause today is a section routed nowhere — `ROUTE-TOTAL`
// (`tom_specs_model_rules.md` §10.2) failing. It is an error rather than a skip
// because a section routed nowhere is a section the agent writing that area
// never sees, and a silent omission at this boundary is indistinguishable from a
// specification that genuinely said nothing.
type CodeSpecsExtractError struct {
	// Message is what went wrong, in one sentence.
	Message string
	// Path is the document path of the offending node.
	Path string
	// ClassName is the model class at Path.
	ClassName string
}

// Error renders the failure, matching the reference's toString().
func (e *CodeSpecsExtractError) Error() string {
	return "CodeSpecsExtractError: " + e.Message + " (" + e.Path + ", " + e.ClassName + ")"
}

// CodeSpecsExtractor produces one CodeSpecsExtract per active area from a filled
// specification document.
type CodeSpecsExtractor struct {
	// Model describes the document's structure and carries the routing verdicts.
	Model *SpecModel
	// Document is the filled specification document.
	Document *SpecDocument
	// Catalog is the area catalogue — `codespecs_mapping.md`
	// §4.1/§4.4.3/§4.4.6.
	Catalog *CodeSpecsAreaCatalog

	reflection *SpecReflection
}

// NewCodeSpecsExtractor binds an extractor to a model / document / catalogue
// triple.
func NewCodeSpecsExtractor(
	model *SpecModel,
	document *SpecDocument,
	catalog *CodeSpecsAreaCatalog,
) *CodeSpecsExtractor {
	return &CodeSpecsExtractor{
		Model:      model,
		Document:   document,
		Catalog:    catalog,
		reflection: NewSpecReflection(model),
	}
}

// Routings returns the verdict of every class node the walk reaches, in document
// order.
//
// Computed by the same walk ExtractAll uses, so "what was routed where" and
// "what landed in which extract" cannot disagree. Unlike ExtractAll this does
// **not** fail on an unrouted class — it reports it, which is what a diagnostic
// is for.
func (x *CodeSpecsExtractor) Routings() []CodeSpecsRouting {
	out := []CodeSpecsRouting{}
	x.walkAll(&out, nil, false)
	return out
}

// ExtractAll returns one extract per active area, in catalogue order.
//
// It returns a *CodeSpecsExtractError on the first class the walk reaches that
// carries none of the three verdicts.
func (x *CodeSpecsExtractor) ExtractAll() ([]*CodeSpecsExtract, error) {
	entries := []CodeSpecsExtractEntry{}
	if bad := x.walkAll(nil, &entries, true); bad != nil {
		return nil, bad
	}
	root := ""
	if len(x.Model.Roots) > 0 {
		root = x.reflection.RootSegment(x.Model.Roots[0])
	}
	out := []*CodeSpecsExtract{}
	for _, area := range x.Catalog.ActiveAreas() {
		mine := []CodeSpecsExtractEntry{}
		for _, e := range entries {
			if e.AreaCode == area.Code {
				mine = append(mine, e)
			}
		}
		out = append(out, &CodeSpecsExtract{
			Area:          area,
			CatalogSource: x.Catalog.Source,
			DocumentRoot:  root,
			CitableParts:  x.Catalog.CitableAreaCodes(area),
			Projects:      x.Catalog.ProjectsFor(area),
			Entries:       mine,
		})
	}
	return out, nil
}

// ExtractFor returns the single extract for areaCode, or nil when the catalogue
// holds no such active area. The error is ExtractAll's.
func (x *CodeSpecsExtractor) ExtractFor(areaCode string) (*CodeSpecsExtract, error) {
	all, err := x.ExtractAll()
	if err != nil {
		return nil, err
	}
	for _, e := range all {
		if e.Area.Code == areaCode {
			return e, nil
		}
	}
	return nil, nil
}

// --- the walk ---------------------------------------------------------------

func (x *CodeSpecsExtractor) walkAll(
	routings *[]CodeSpecsRouting,
	entries *[]CodeSpecsExtractEntry,
	strict bool,
) *CodeSpecsExtractError {
	for _, root := range x.Model.Roots {
		bad := x.walk(
			x.reflection.RootSegment(root),
			x.Model.ClassNamed(root.Type),
			map[string]bool{root.Type: true},
			routings,
			entries,
			strict,
		)
		if bad != nil {
			return bad
		}
	}
	return nil
}

func (x *CodeSpecsExtractor) walk(
	path string,
	cls *SpecClass,
	ancestorTypes map[string]bool,
	routings *[]CodeSpecsRouting,
	entries *[]CodeSpecsExtractEntry,
	strict bool,
) *CodeSpecsExtractError {
	if cls == nil {
		return nil
	}
	routing := x.verdictOf(cls, path)
	if routings != nil {
		*routings = append(*routings, routing)
	}

	switch routing.Verdict {
	case CodeSpecsVerdictFeedsProcess:
		return nil // the whole subtree is delivered by a non-generation process
	case CodeSpecsVerdictUnrouted:
		if strict {
			return &CodeSpecsExtractError{
				Message: "section carries none of the three routing verdicts " +
					"(@CodeSpecKind / @FollowUpKind / @NoArtifact) — " +
					"tom_specs_model_rules.md §10.2 ROUTE-TOTAL",
				Path:      path,
				ClassName: cls.Name,
			}
		}
	}

	var classRouting *CodeSpecsRouting
	if routing.Verdict == CodeSpecsVerdictFeedsCode {
		classRouting = &routing
	}

	for _, field := range cls.Fields {
		fieldPath := SpecPathJoin(path, x.reflection.FieldSegment(field))
		fieldRouting := x.fieldRouting(cls, field)
		if fieldRouting == nil {
			fieldRouting = classRouting
		}

		switch field.Kind {
		case SpecFieldKindContent, SpecFieldKindEnum, SpecFieldKindScalar:
			x.emitValue(entries, fieldRouting, cls, field, fieldPath, "",
				x.Document.ContentOr(fieldPath))
		case SpecFieldKindForm:
			for _, ff := range field.FormFields {
				x.emitValue(entries, fieldRouting, cls, field, fieldPath, ff.Name,
					x.Document.FormFieldOr(fieldPath, ff.Name))
			}
		case SpecFieldKindList:
			for _, itemPath := range x.Document.ListItems(fieldPath) {
				if field.ElementIsComplex && field.ElementType != "" &&
					!ancestorTypes[field.ElementType] {
					bad := x.walk(
						itemPath,
						x.Model.ClassNamed(field.ElementType),
						cseWith(ancestorTypes, field.ElementType),
						routings,
						entries,
						strict,
					)
					if bad != nil {
						return bad
					}
				} else {
					x.emitValue(entries, fieldRouting, cls, field, itemPath, "",
						x.Document.ContentOr(itemPath))
				}
			}
		case SpecFieldKindComplex, SpecFieldKindSection:
			if field.Type != "" && !ancestorTypes[field.Type] {
				bad := x.walk(
					fieldPath,
					x.Model.ClassNamed(field.Type),
					cseWith(ancestorTypes, field.Type),
					routings,
					entries,
					strict,
				)
				if bad != nil {
					return bad
				}
			}
		}
	}
	return nil
}

// emitValue appends one entry **per area the routing names** — never
// deduplicated, because each area's prompt must be self-sufficient (§1.1.1).
func (x *CodeSpecsExtractor) emitValue(
	entries *[]CodeSpecsExtractEntry,
	routing *CodeSpecsRouting,
	cls *SpecClass,
	field *SpecField,
	path string,
	formField string,
	value string,
) {
	if entries == nil || routing == nil {
		return
	}
	if value == "" {
		return
	}
	for _, kind := range routing.Values {
		area := x.Catalog.ByPart(kind)
		if area == nil || !area.Active {
			continue
		}
		*entries = append(*entries, CodeSpecsExtractEntry{
			AreaCode:    area.Code,
			SectionID:   x.reflection.FieldSegment(field),
			Path:        path,
			ClassName:   cls.Name,
			FieldName:   field.Name,
			FormField:   formField,
			RoutedBy:    area.KindValue(),
			RoutedAt:    routing.DeclaredAt,
			RoutingNote: routing.Note,
			Value:       value,
		})
	}
}

// --- verdict resolution -----------------------------------------------------

// verdictOf returns the verdict cls carries. The three markers are mutually
// exclusive (`KIND-EXCLUSIVE`), so the order they are tested in is a readability
// choice rather than a precedence rule.
//
// Read through the model's own annotation accessors (SpecClass.CodeSpecKind and
// friends) rather than off the raw annotation bag: they already know that
// `@CodeSpecKind`'s list argument is `kinds` while `@FollowUpKind`'s is
// `processes`, and they strip the enum prefix, so the codes here are bare
// whatever spelling the meta chose. Two readers of the same annotations would be
// two chances to disagree.
func (x *CodeSpecsExtractor) verdictOf(cls *SpecClass, path string) CodeSpecsRouting {
	if code := cls.CodeSpecKind(); code != nil {
		return CodeSpecsRouting{
			Path:       path,
			ClassName:  cls.Name,
			Verdict:    CodeSpecsVerdictFeedsCode,
			Values:     code.Kinds,
			Note:       code.Note,
			DeclaredAt: cls.Name,
		}
	}
	if followUp := cls.FollowUpKind(); followUp != nil {
		return CodeSpecsRouting{
			Path:       path,
			ClassName:  cls.Name,
			Verdict:    CodeSpecsVerdictFeedsProcess,
			Values:     followUp.Kinds,
			Note:       followUp.Note,
			DeclaredAt: cls.Name,
		}
	}
	if none := cls.NoArtifact(); none != nil {
		return CodeSpecsRouting{
			Path:       path,
			ClassName:  cls.Name,
			Verdict:    CodeSpecsVerdictFeedsNothing,
			Values:     []string{none.Reason},
			Note:       none.Note,
			DeclaredAt: cls.Name,
		}
	}
	if cls.HasAnnotation("Document") {
		return CodeSpecsRouting{
			Path:      path,
			ClassName: cls.Name,
			Verdict:   CodeSpecsVerdictDocumentRoot,
			Values:    []string{},
		}
	}
	return CodeSpecsRouting{
		Path:      path,
		ClassName: cls.Name,
		Verdict:   CodeSpecsVerdictUnrouted,
		Values:    []string{},
	}
}

// fieldRouting returns a field-level `@CodeSpecKind`, which overrides its
// class's routing for that field alone; nil when the field carries none.
func (x *CodeSpecsExtractor) fieldRouting(cls *SpecClass, field *SpecField) *CodeSpecsRouting {
	code := field.CodeSpecKind()
	if code == nil {
		return nil
	}
	return &CodeSpecsRouting{
		Path:       "",
		ClassName:  cls.Name,
		Verdict:    CodeSpecsVerdictFeedsCode,
		Values:     code.Kinds,
		Note:       code.Note,
		DeclaredAt: cls.Name + "." + field.Name,
	}
}

// --- shared emission helpers ------------------------------------------------

// cseStrings / cseInts normalise an absent JSON list to an empty (non-nil)
// slice, so an omitted key encodes as `[]` and never as `null`.
func cseStrings(raw []string) []string {
	if raw == nil {
		return []string{}
	}
	return raw
}

func cseInts(raw []int) []int {
	if raw == nil {
		return []int{}
	}
	return raw
}

// cseWith returns a copy of types with one more member — the reference's
// `{...ancestorTypes, T}`. A copy rather than a mutation: the set is the *path*
// from the root to this node, so a sibling's descent must not see a type only
// its neighbour passed through.
func cseWith(types map[string]bool, add string) map[string]bool {
	out := make(map[string]bool, len(types)+1)
	for k := range types {
		out[k] = true
	}
	out[add] = true
	return out
}

// cseYamlString renders value as a JSON string literal, which is also a valid
// YAML 1.2 double-quoted scalar.
//
// The rule is hand-written rather than delegated to encoding/json so the nine
// runtimes have one rule to transcribe rather than nine encoders to hope agree —
// and this package already carries that hand-written rule as jsJSONString (the
// same short escapes, the same lowercase \u00xx below 0x20, every other rune
// verbatim), which yamlKey reuses the same way. A second copy here would be a
// second chance to drift.
func cseYamlString(value string) string { return jsJSONString(value) }

// cseYamlNullableString renders this port's "" (its stand-in for the reference's
// null) as the YAML `null` the goldens carry.
func cseYamlNullableString(value string) string {
	if value == "" {
		return "null"
	}
	return cseYamlString(value)
}

func cseYamlStringList(values []string) string {
	var b strings.Builder
	b.WriteString("[")
	for i, v := range values {
		if i > 0 {
			b.WriteString(", ")
		}
		b.WriteString(cseYamlString(v))
	}
	b.WriteString("]")
	return b.String()
}

func cseYamlIntList(values []int) string {
	var b strings.Builder
	b.WriteString("[")
	for i, v := range values {
		if i > 0 {
			b.WriteString(", ")
		}
		b.WriteString(itoa(v))
	}
	b.WriteString("]")
	return b.String()
}

// cseMdCell renders a markdown table cell: newlines folded to a space (a cell
// cannot hold one) and `|` escaped. Applied only to catalogue prose, never to a
// stored value — values go into fenced blocks, where they stay verbatim.
func cseMdCell(value string) string {
	return strings.ReplaceAll(strings.ReplaceAll(value, "\n", " "), "|", `\|`)
}

func cseMdCodeList(values []string) string {
	if len(values) == 0 {
		return "—"
	}
	quoted := make([]string, 0, len(values))
	for _, v := range values {
		quoted = append(quoted, "`"+v+"`")
	}
	return strings.Join(quoted, ", ")
}

func cseMdIntList(values []int) string {
	if len(values) == 0 {
		return "—"
	}
	parts := make([]string, 0, len(values))
	for _, v := range values {
		parts = append(parts, itoa(v))
	}
	return strings.Join(parts, ", ")
}

// cseFenceFor returns the shortest backtick fence that cannot be closed by
// value's own content.
func cseFenceFor(value string) string {
	longest, run := 0, 0
	for i := 0; i < len(value); i++ {
		if value[i] == '`' {
			run++
			if run > longest {
				longest = run
			}
		} else {
			run = 0
		}
	}
	width := 3
	if longest >= 3 {
		width = longest + 1
	}
	return strings.Repeat("`", width)
}
