// SpecValidationAllCodes must list every SpecValidationCode constant, in
// declaration order: it is the enumerable vocabulary a constant-based port
// owes its readers in place of an enum, and a code added without it would be
// invisible to every tool that enumerates the list.
package tests

import (
	"os"
	"regexp"
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

func TestSpecValidationAllCodesListsEveryConstant(t *testing.T) {
	src, err := os.ReadFile("../spec_validator.go")
	if err != nil {
		t.Fatal(err)
	}
	text := string(src)
	start := strings.Index(text, "// Why a single value in a document is invalid against the model.")
	if start < 0 {
		t.Fatal("the SpecValidationCode constant block was not found")
	}
	block := text[start:]
	block = block[:strings.Index(block, "\n)\n")]
	values := regexp.MustCompile(`(?m)^\tSpecValidationCode[A-Za-z]+\s*=\s*"([A-Za-z]+)"`).
		FindAllStringSubmatch(block, -1)
	var declared []string
	for _, m := range values {
		declared = append(declared, m[1])
	}
	if len(declared) == 0 {
		t.Fatal("no SpecValidationCode constants were read")
	}
	if strings.Join(declared, ",") != strings.Join(som.SpecValidationAllCodes, ",") {
		t.Fatalf("SpecValidationAllCodes = %v, the constants declare %v",
			som.SpecValidationAllCodes, declared)
	}
}
