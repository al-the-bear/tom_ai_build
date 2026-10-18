// SpecDocument.HasValuesUnder answers from a prefix index rather than a scan
// of every stored key. The markdown emitter, the validator and the query
// engine ask it once per model node, so a scan made rendering a large
// specification quadratic.
//
// VI-1 holds the index to the scan it replaces, across every mutator, so a
// mutation that forgets to drop the index fails here. VI-2 guards the
// complexity itself.
package tests

import (
	"strconv"
	"strings"
	"testing"
	"time"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// viScan is the predicate the index must reproduce: a stored key equal to the
// query, or continuing it after a '/' or a '-'. (This port has no path
// normalizer, so the query is the storage key.)
func viScan(d *som.SpecDocument, query string) bool {
	j := d.ToJSON()
	var keys []string
	for k := range j.Content {
		keys = append(keys, k)
	}
	for k := range j.Forms {
		keys = append(keys, k)
	}
	for k := range j.Lists {
		keys = append(keys, k)
	}
	for k := range j.Headlines {
		keys = append(keys, k)
	}
	for k := range j.CodeSpecs {
		keys = append(keys, k)
	}
	for _, k := range keys {
		if k == query || strings.HasPrefix(k, query+"/") || strings.HasPrefix(k, query+"-") {
			return true
		}
	}
	return false
}

var viProbes = []string{
	"DEMO",
	"DEMO/TTL",
	"DEMO/TT",
	"DEMO/SUM",
	"DEMO/DET",
	"DEMO/items",
	"DEMO/items-1",
	"DEMO/items-1/label",
	"DEMO/items-2",
	"DEMO/items-3",
	"DEMO/REF-LST",
	"DEMO/REF",
	"DEMO/CARD-LST-1",
	"OTHER",
	"",
}

// viDocProbes adds, for every stored key, each of its prefixes (at every byte)
// and the key with a suffix, so a document the fixed probes miss is covered.
func viDocProbes(d *som.SpecDocument) []string {
	out := append([]string{}, viProbes...)
	j := d.ToJSON()
	add := func(k string) {
		for i := 0; i <= len(k); i++ {
			out = append(out, k[:i])
		}
		out = append(out, k+"x", k+"/x", k+"-1")
	}
	for k := range j.Content {
		add(k)
	}
	for k := range j.Forms {
		add(k)
	}
	for k, l := range j.Lists {
		add(k)
		for _, it := range l.Items {
			add(it)
		}
	}
	for k := range j.Headlines {
		add(k)
	}
	for k := range j.CodeSpecs {
		add(k)
	}
	return out
}

func viExpectAgrees(t *testing.T, d *som.SpecDocument, when string) {
	t.Helper()
	for _, p := range viDocProbes(d) {
		if got, want := d.HasValuesUnder(p), viScan(d, p); got != want {
			t.Errorf("%s: HasValuesUnder(%q) = %v, scan says %v", when, p, got, want)
		}
	}
}

func TestVI1IndexAgreesWithScanAfterEveryMutator(t *testing.T) {
	d := som.NewSpecDocument()
	viExpectAgrees(t, d, "empty")
	d.SetContent("DEMO/TTL", "Hello")
	viExpectAgrees(t, d, "SetContent")
	d.SetHeadline("DEMO/SUM", "Summary")
	viExpectAgrees(t, d, "SetHeadline")
	d.SetCodeSpec("DEMO/DET", "a.b")
	viExpectAgrees(t, d, "SetCodeSpec")
	d.SetFormField("DEMO/CARD-LST-1/content", "note", "x")
	viExpectAgrees(t, d, "SetFormField")
	item := d.AddListItem("DEMO/items")
	d.SetContent(item+"/label", "First")
	d.AddListItem("DEMO/items")
	viExpectAgrees(t, d, "AddListItem")
	if _, err := d.AddListItemWithSectionID("DEMO/REF-LST", "REF-A"); err != nil {
		t.Fatalf("AddListItemWithSectionID: %v", err)
	}
	viExpectAgrees(t, d, "AddListItemWithSectionID")
	if err := d.SetItemSectionID(item, "ITEM-A"); err != nil {
		t.Fatalf("SetItemSectionID: %v", err)
	}
	viExpectAgrees(t, d, "SetItemSectionID")
	d.SetContent("DEMO/TTL", "")
	viExpectAgrees(t, d, "SetContent to empty")
	d.SetFormField("DEMO/CARD-LST-1/content", "note", "")
	viExpectAgrees(t, d, "SetFormField to empty")
	d.SetHeadline("DEMO/SUM", "")
	viExpectAgrees(t, d, "SetHeadline to empty")
	d.SetCodeSpec("DEMO/DET", "")
	viExpectAgrees(t, d, "SetCodeSpec to empty")
	d.RemoveListItem(item)
	viExpectAgrees(t, d, "RemoveListItem")
	d.SetHeadline("DEMO/SUM", "Summary")
	viExpectAgrees(t, d, "SetHeadline again")
	d.RemoveValuesUnder("DEMO/SUM")
	viExpectAgrees(t, d, "RemoveValuesUnder")

	d.LoadJSON(&som.DocumentJson{
		Content: map[string]string{"DEMO/REF-LST-1": "spec"},
		Lists: map[string]som.ListJson{
			"DEMO/REF-LST": {Seq: 1, Items: []string{"DEMO/REF-LST-1"}},
		},
	})
	viExpectAgrees(t, d, "LoadJSON")

	// MoveListItem needs a model list: replay every corpus move case.
	model := loadModel(t)
	var table listMoveCaseTable
	readJSON(t, "list_move_cases.json", &table)
	if len(table.Cases) == 0 {
		t.Fatal("no cases in list_move_cases.json")
	}
	for _, cc := range table.Cases {
		md := docFromState(&cc.State)
		viExpectAgrees(t, md, cc.Name+": before MoveListItem")
		_, _ = md.MoveListItem(model, cc.Move.ItemPath, cc.Move.ToIndex, cc.Move.ToList)
		viExpectAgrees(t, md, cc.Name+": MoveListItem")
	}

	// ApplyMarkdownResult purges and reloads through the mutators above.
	md := docFromState(&table.Cases[0].State)
	viExpectAgrees(t, md, "before ApplyMarkdownResult")
	if err := md.ApplyMarkdownResult(&som.SpecMarkdownResult{
		RootPrefixes: map[string]bool{"DEMO": true},
		Content:      map[string]string{"DEMO/TTL": "Imported"},
	}, true); err != nil {
		t.Fatalf("ApplyMarkdownResult: %v", err)
	}
	viExpectAgrees(t, md, "ApplyMarkdownResult")
}

func TestVI2HasValuesUnderIsNotAScan(t *testing.T) {
	// 20,000 stored values and 20,000 queries. A per-query scan costs
	// 4 * 10^8 key comparisons; the index answers in milliseconds. The bound
	// is generous, so only the complexity class can fail it.
	const n = 20000
	d := som.NewSpecDocument()
	for i := 0; i < n; i++ {
		d.SetContent("ROOT/S"+strconv.Itoa(i/100)+"/F"+strconv.Itoa(i), "v"+strconv.Itoa(i))
	}
	start := time.Now()
	hits := 0
	for i := 0; i < n; i++ {
		if d.HasValuesUnder("ROOT/S" + strconv.Itoa(i/100) + "/F" + strconv.Itoa(i)) {
			hits++
		}
		if d.HasValuesUnder("ROOT/S" + strconv.Itoa(i/100) + "/G" + strconv.Itoa(i)) {
			hits--
		}
	}
	elapsed := time.Since(start)
	if hits != n {
		t.Errorf("hits = %d, want %d", hits, n)
	}
	if elapsed >= 2*time.Second {
		t.Errorf("%d queries took %v, want < 2s", 2*n, elapsed)
	}
}
