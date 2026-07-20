// Cross-language golden-log generator for Go (roadmap item 7b).
//
// Mirror of tom_som_dart_v0/tool/golden_log.dart — see that file for the
// canonical format. Loads the shared sample and emits a byte-identical reading
// of essentially every section through both the generic string-path API and the
// typed facade, asserting typed == generic before writing.
//
// Usage: go run ./tool [samplePath] [outputPath]
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
	somv0 "github.com/al-the-bear/tom_ai_build/tom_som_go_v0"
)

func esc(s string) string {
	s = strings.ReplaceAll(s, "\\", "\\\\")
	s = strings.ReplaceAll(s, "\n", "\\n")
	s = strings.ReplaceAll(s, "\r", "\\r")
	s = strings.ReplaceAll(s, "\t", "\\t")
	return s
}

// kindName maps a native Go SomMetaKind* value to the canonical DART enum
// spelling used across every language's golden log. Only the enum spelling
// differs between the two vocabularies (Go "enum" → Dart "enumValue"); the
// rest are identical, but the full mapping is written out for correctness.
func kindName(kind string) string {
	switch kind {
	case som.SomMetaKindList:
		return "list"
	case som.SomMetaKindForm:
		return "form"
	case som.SomMetaKindSection:
		return "section"
	case som.SomMetaKindContent:
		return "content"
	case som.SomMetaKindEnumValue:
		return "enumValue"
	case som.SomMetaKindComplex:
		return "complex"
	case som.SomMetaKindScalar:
		return "scalar"
	default:
		return kind
	}
}

func die(msg string) {
	fmt.Fprintln(os.Stderr, msg)
	os.Exit(2)
}

func main() {
	sample := filepath.Join("..", "tom_som_conformance", "samples",
		"meridian_order_management.docspecs.yaml")
	output := filepath.Join("..", "tom_som_conformance", "golden", "go.log")
	if len(os.Args) > 1 {
		sample = os.Args[1]
	}
	if len(os.Args) > 2 {
		output = os.Args[2]
	}

	doc, err := som.FromFile(sample, somv0.D00SolutionBlueprintMetaTree)
	if err != nil {
		die("load sample failed: " + err.Error())
	}
	sbp, err := somv0.LoadFileD00SolutionBlueprint(sample)
	if err != nil {
		die("load typed root failed: " + err.Error())
	}

	var out []string
	out = append(out, "# TomSpecs SOM golden log — canonical cross-language reading.")
	out = append(out, "# All nine per-language generators must emit byte-identical output.")
	out = append(out, "FORMAT\t8")
	out = append(out, "MODELVERSION\t"+esc(doc.ModelVersion))

	// Generic: content leaves, sorted by path.
	out = append(out, "SECTION\tgeneric-content")
	contentPaths := doc.ContentPaths()
	sort.Strings(contentPaths)
	for _, p := range contentPaths {
		out = append(out, "C\t"+p+"\t"+esc(doc.ContentOr(p)))
	}

	// Generic: form sections + fields, sorted by path then field.
	out = append(out, "SECTION\tgeneric-forms")
	formPaths := doc.FormPaths()
	sort.Strings(formPaths)
	for _, p := range formPaths {
		fields := doc.FormFieldNames(p)
		sort.Strings(fields)
		for _, f := range fields {
			v, _ := doc.FormField(p, f)
			out = append(out, "F\t"+p+"\t"+f+"\t"+esc(v))
		}
	}

	// Generic: list containers + item paths (document order). FORMAT 3: each
	// item with a *stored* section id additionally emits an `ID` line (item
	// path + stored id); items without one emit no `ID` line.
	out = append(out, "SECTION\tgeneric-lists")
	listPaths := doc.ListPaths()
	sort.Strings(listPaths)
	for _, p := range listPaths {
		items := doc.ListItems(p)
		out = append(out, fmt.Sprintf("L\t%s\t%d", p, len(items)))
		for _, item := range items {
			out = append(out, "I\t"+item)
			if id, ok := doc.ItemSectionID(item); ok {
				out = append(out, "ID\t"+item+"\t"+esc(id))
			}
		}
	}

	// Generic: every stored headline, sorted by path (FORMAT 3, YRD3).
	out = append(out, "SECTION\tgeneric-headlines")
	headlinePaths := doc.HeadlinePaths()
	sort.Strings(headlinePaths)
	for _, p := range headlinePaths {
		out = append(out, "H\t"+p+"\t"+esc(doc.HeadlineOr(p)))
	}

	// Generic: every stored codeSpec, sorted by path (FORMAT 8, §9.2 mirror of headline).
	out = append(out, "SECTION\tgeneric-codespecs")
	codeSpecPaths := doc.CodeSpecPaths()
	sort.Strings(codeSpecPaths)
	for _, p := range codeSpecPaths {
		out = append(out, "CS\t"+p+"\t"+esc(doc.CodeSpecOr(p)))
	}

	// Typed: curated traversal that must agree with the generic reads.
	out = append(out, "SECTION\ttyped")

	typedContent := func(nodePath, value string) {
		leaf := nodePath + "/content"
		generic := doc.ContentOr(leaf)
		if value != generic {
			die("TYPED MISMATCH at " + leaf)
		}
		out = append(out, "T\t"+leaf+"\t"+esc(value))
	}

	typedContent(sbp.Path(), sbp.Content())
	typedContent(sbp.DocumentControl().Path(), sbp.DocumentControl().Content())
	typedContent(sbp.IntroductionAndScope().Path(), sbp.IntroductionAndScope().Content())
	typedContent(sbp.GlossaryAndAbbreviations().Path(), sbp.GlossaryAndAbbreviations().Content())
	typedContent(sbp.StakeholdersAndGovernance().Path(), sbp.StakeholdersAndGovernance().Content())
	typedContent(sbp.CurrentLandscape().Path(), sbp.CurrentLandscape().Content())
	typedContent(sbp.AssumptionsConstraintsDependencies().Path(),
		sbp.AssumptionsConstraintsDependencies().Content())
	typedContent(sbp.TargetOperatingModelConcept().Path(),
		sbp.TargetOperatingModelConcept().Content())
	typedContent(sbp.InformationAndDataModel().Path(), sbp.InformationAndDataModel().Content())
	typedContent(sbp.Requirements().Path(), sbp.Requirements().Content())
	typedContent(sbp.SolutionArchitectureAndTechnology().Path(),
		sbp.SolutionArchitectureAndTechnology().Content())
	typedContent(sbp.SecurityAndAccessModel().Path(), sbp.SecurityAndAccessModel().Content())
	typedContent(sbp.ExperienceAndInterfaceDesign().Path(),
		sbp.ExperienceAndInterfaceDesign().Content())
	typedContent(sbp.QualityAndAcceptanceModel().Path(), sbp.QualityAndAcceptanceModel().Content())
	typedContent(sbp.DeliveryTransitionAndRollout().Path(),
		sbp.DeliveryTransitionAndRollout().Content())

	typedContent(sbp.IntroductionAndScope().Goals().Path(),
		sbp.IntroductionAndScope().Goals().Content())

	metrics := sbp.CurrentLandscape().OperationalMetrics()
	metricItemPaths := doc.ListItems(metrics.ListPath())
	if metrics.Length() != len(metricItemPaths) {
		die("TYPED LIST LENGTH MISMATCH at " + metrics.ListPath())
	}
	out = append(out, fmt.Sprintf("TL\t%s\t%d", metrics.ListPath(), metrics.Length()))
	for i := 0; i < metrics.Length(); i++ {
		elem := metrics.At(i)
		leaf := elem.Path() + "/content"
		generic := doc.ContentOr(leaf)
		if elem.Content() != generic {
			die("TYPED LIST ITEM MISMATCH at " + leaf)
		}
		out = append(out, "TI\t"+leaf+"\t"+esc(elem.Content()))
	}

	// --- Typed non-String form fields (FORMAT 7, YRD7): native int/bool/enum
	// members read through the typed facade and asserted against the generic
	// form store, canonicalised through the SAME boundary rules the facade
	// setters used to write them (int -> decimal, bool -> "true"/"false", enum
	// -> constant name). The emitted value is the raw stored string, so the
	// lines are byte-identical across languages regardless of native types. ---
	out = append(out, "SECTION\ttyped-form")
	somFormatInt := func(v *int) string {
		if v == nil {
			return ""
		}
		return fmt.Sprintf("%d", *v)
	}
	somFormatBool := func(v *bool) string {
		if v == nil {
			return ""
		}
		if *v {
			return "true"
		}
		return "false"
	}
	typedForm := func(formPath, field, canonical string) {
		generic := doc.FormFieldOr(formPath, field)
		if canonical != generic {
			die("TYPED FORM MISMATCH at " + formPath + "." + field + ": " +
				"typed=\"" + canonical + "\" generic=\"" + generic + "\"")
		}
		out = append(out, "TF\t"+formPath+"\t"+field+"\t"+esc(generic))
	}

	actorOverview := sbp.TargetOperatingModelConcept().TargetBusinessProcess().
		ProcessStepsAndActorInteractions().ActorOverview().Overview()
	typedForm(actorOverview.Path(), "totalActorCount",
		somFormatInt(actorOverview.TotalActorCount()))
	typedForm(actorOverview.Path(), "humanActorCount",
		somFormatInt(actorOverview.HumanActorCount()))
	typedForm(actorOverview.Path(), "systemActorCount",
		somFormatInt(actorOverview.SystemActorCount()))
	typedForm(actorOverview.Path(), "externalActorCount",
		somFormatInt(actorOverview.ExternalActorCount()))

	accessibilityOverview := sbp.ExperienceAndInterfaceDesign().
		Accessibility().AccessibilityOverviewContent()
	typedForm(accessibilityOverview.Path(), "accessibilityStatement",
		somFormatBool(accessibilityOverview.AccessibilityStatement()))

	coverage := sbp.QualityAndAcceptanceModel().Iso25010Coverage().Characteristics()
	out = append(out, fmt.Sprintf("TL\t%s\t%d", coverage.ListPath(), coverage.Length()))
	for i := 0; i < coverage.Length(); i++ {
		cform := coverage.At(i).Content()
		typedForm(cform.Path(), "characteristic", cform.Characteristic())
	}

	// --- Meta (FORMAT 2): the generated metadata tree read three ways. Every
	// path and every emitted field is model-derived, so the lines are byte-
	// identical across all nine languages even though the accessor names and
	// node types differ. ---
	metaTree := somv0.D00SolutionBlueprintMetaTree

	// Metadata reads: for a curated set of nodes resolved by path, emit the
	// node's kind (mapped to the canonical Dart enum spelling) plus its help /
	// comment / doc-comment.
	out = append(out, "SECTION\tmeta")
	metaNode := func(path string) {
		n := metaTree.ByPath(path)
		if n == nil {
			fmt.Fprintln(os.Stderr, "META MISSING at "+path)
			os.Exit(3)
		}
		out = append(out, "M\t"+path+"\t"+kindName(n.Kind)+"\t"+esc(n.SectionID)+
			"\t"+esc(n.ContentHelp)+"\t"+esc(n.Comment)+"\t"+esc(n.DocComment)+
			"\t"+esc(n.Headline))
	}
	metaNode("SBP")
	metaNode("SBP/documentControl")
	metaNode("SBP/documentControl/RVHST-REVS-LST")
	metaNode("SBP/introductionAndScope")
	metaNode("SBP/introductionAndScope/goals")
	metaNode("SBP/introductionAndScope/goals/content")
	metaNode("SBP/currentLandscape")
	metaNode("SBP/currentLandscape/CUOPME-OPER-LST")
	metaNode("SBP/requirements")
	metaNode("SBP/requirements/content")

	// --- Meta form fields (FORMAT 7, YRD7): a list-element content form read
	// through the metadata tree — one MF line per field (declaration order) with
	// type/required plus the enumValues column (comma-joined constant names,
	// empty for non-enum fields). Emitted for the FRE requirement form (no
	// enums) and the ISO 25010 coverage form (an enum-typed field). All values
	// are model-derived. ---
	out = append(out, "SECTION\tmeta-form")
	metaForm := func(listPath string) {
		listNode := metaTree.ByPath(listPath)
		var element *som.SomMetaNode
		if listNode != nil {
			element = listNode.ElementNode
		}
		var contentNode *som.SomMetaNode
		if element != nil {
			for _, child := range element.Children {
				if child.MemberName == "content" {
					contentNode = child
				}
			}
		}
		var form *som.SomFormMeta
		if contentNode != nil {
			form = contentNode.Form
		}
		if form == nil {
			fmt.Fprintln(os.Stderr, "META FORM MISSING at "+listPath+" element content")
			os.Exit(3)
		}
		// Element subtrees have no static document path; use an ASCII marker
		// segment so the log path stays ASCII (mirrored verbatim per language).
		formPath := listPath + "/#element/content"
		for _, f := range form.Fields {
			required := 0
			if f.Required {
				required = 1
			}
			out = append(out, fmt.Sprintf("MF\t%s\t%s\t%s\t%d\t%s",
				formPath, esc(f.Name), esc(f.TypeName), required,
				esc(strings.Join(f.EnumValues, ","))))
		}
	}

	metaForm("SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST")
	metaForm("SBP/qualityAndAcceptanceModel/iso25010Coverage/I25CV-CHAR-LST")

	// Dot-notation navigation: the typed nav accessors must resolve to exactly
	// the path ByPath finds, and to the same node instance.
	out = append(out, "SECTION\tmeta-nav")
	metaNav := func(ref *som.SomMetaRef, expectedPath string) {
		if ref.Path != expectedPath {
			fmt.Fprintln(os.Stderr, "META NAV PATH at "+ref.Path+" expected "+expectedPath)
			os.Exit(3)
		}
		node, err := ref.Meta()
		if err != nil {
			fmt.Fprintln(os.Stderr, "META NAV Meta() at "+expectedPath+": "+err.Error())
			os.Exit(3)
		}
		byPath := metaTree.ByPath(expectedPath)
		if byPath == nil || node != byPath {
			fmt.Fprintln(os.Stderr, "META NAV NODE mismatch at "+expectedPath)
			os.Exit(3)
		}
		out = append(out, "N\t"+expectedPath)
	}
	nav := somv0.D00SolutionBlueprintMeta
	metaNav(&nav.SomMetaRef, "SBP")
	metaNav(&nav.DocumentControl().SomMetaRef, "SBP/documentControl")
	metaNav(&nav.IntroductionAndScope().SomMetaRef, "SBP/introductionAndScope")
	metaNav(&nav.IntroductionAndScope().Goals().SomMetaRef, "SBP/introductionAndScope/goals")
	metaNav(nav.IntroductionAndScope().Goals().Content(), "SBP/introductionAndScope/goals/content")
	metaNav(&nav.CurrentLandscape().SomMetaRef, "SBP/currentLandscape")
	metaNav(&nav.Requirements().SomMetaRef, "SBP/requirements")
	metaNav(nav.Requirements().Content(), "SBP/requirements/content")

	// ID-tree navigation: the hoisted-id accessors must agree — same path, same
	// node instance — with the dot-notation position, including list elements.
	out = append(out, "SECTION\tmeta-id")
	metaID := func(idRef, navRef *som.SomMetaRef) {
		idNode, errI := idRef.Meta()
		navNode, errN := navRef.Meta()
		if errI != nil || errN != nil || idRef.Path != navRef.Path || idNode != navNode {
			fmt.Fprintln(os.Stderr, "META ID mismatch at "+idRef.Path+" vs "+navRef.Path)
			os.Exit(3)
		}
		out = append(out, "D\t"+idRef.Path)
	}
	revs := nav.DocumentControl().RevisionHistory()
	metaID(&somv0.SBP.SomMetaRef, &nav.SomMetaRef)
	metaID(&somv0.SBP.RVHST_REVS_LST().SomMetaRef, &revs.SomMetaRef)
	metaID(&somv0.SBP.RVHST_REVS_LST().Item(0).SomMetaRef, &revs.Item(0).SomMetaRef)

	// DocSpecs validation: the shared markdown rendering of the sample validates
	// cleanly against the facade's generated Solution-Blueprint schema.
	out = append(out, "SECTION\tdocspecs")
	schemaText, err := os.ReadFile(filepath.Join(
		"schemas", "solution-blueprint", "solution-blueprint.1.0.docspecs-schema.yaml"))
	if err != nil {
		die("read schema failed: " + err.Error())
	}
	schema, err := som.DocSpecsSchemaFromYamlText(string(schemaText))
	if err != nil {
		die("parse schema failed: " + err.Error())
	}
	sampleMd, err := os.ReadFile(filepath.Join("..", "tom_som_conformance", "samples",
		"meridian_order_management.md"))
	if err != nil {
		die("read sample md failed: " + err.Error())
	}
	violations := som.NewDocSpecsValidator(schema).ValidateMarkdown(string(sampleMd))
	out = append(out, "DS\troot\t"+esc(schema.RootSectionID()))
	out = append(out, fmt.Sprintf("DS\twarnings\t%d", len(schema.Warnings)))
	out = append(out, fmt.Sprintf("DS\tviolations\t%d", len(violations)))
	for _, v := range violations {
		out = append(out, fmt.Sprintf("DV\t%s\t%s\t%d", v.Rule, esc(v.SectionID), v.Line))
	}

	if err := os.MkdirAll(filepath.Dir(output), 0o755); err != nil {
		die("mkdir failed: " + err.Error())
	}
	body := strings.Join(out, "\n") + "\n"
	if err := os.WriteFile(output, []byte(body), 0o644); err != nil {
		die("write failed: " + err.Error())
	}
	fmt.Printf("wrote %d lines to %s\n", len(out), output)
}
