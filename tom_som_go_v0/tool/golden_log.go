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

	doc, err := som.FromFile(sample)
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
	out = append(out, "FORMAT\t1")
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

	// Generic: list containers + item paths (document order).
	out = append(out, "SECTION\tgeneric-lists")
	listPaths := doc.ListPaths()
	sort.Strings(listPaths)
	for _, p := range listPaths {
		items := doc.ListItems(p)
		out = append(out, fmt.Sprintf("L\t%s\t%d", p, len(items)))
		for _, item := range items {
			out = append(out, "I\t"+item)
		}
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

	if err := os.MkdirAll(filepath.Dir(output), 0o755); err != nil {
		die("mkdir failed: " + err.Error())
	}
	body := strings.Join(out, "\n") + "\n"
	if err := os.WriteFile(output, []byte(body), 0o644); err != nil {
		die("write failed: " + err.Error())
	}
	fmt.Printf("wrote %d lines to %s\n", len(out), output)
}
