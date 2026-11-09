// The quick start of doc/review_annotations.md, run as a Go example so the
// output the guide prints stays true.
package tests

import (
	"fmt"
	"os"
	"path/filepath"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

func ExampleSpecReviewAnnotations() {
	doc := som.NewSpecDocument()
	doc.LoadJSON(&som.DocumentJson{Content: map[string]string{
		"DEMO/SUM": "Sessions expire after 30 minutes.\n\n" +
			"> ⬆️ (Alexis): Too long for kiosks.",
	}})
	review := som.NewSpecReviewAnnotations(doc, "DEMO")
	fmt.Println(review.AssignCommentIDs(0))
	fmt.Println(*review.List()[0].QualifiedID)
	if err := review.InsertQuestionAfterComment("C-1", som.SpecQuestionDraft{
		ID: "BQ-1", Topic: "C-1 kiosks", Text: "Kiosks only?",
	}, ""); err != nil {
		panic(err)
	}
	if err := review.SetAnswer("BQ-1", "yes", "", ""); err != nil {
		panic(err)
	}
	fmt.Printf("%+v\n", review.Counts())
	// Output:
	// [C-1]
	// DEMO C-1
	// {Questions:1 OpenQuestions:0 AnsweredQuestions:1 Comments:1 Marks:0 UnresolvedQuestions:0 Conflicts:0 OpenConflicts:0}
}

// The merge example of doc/review_annotations.md ("Team reviews"), over the
// corpus DEMO model.
func ExampleMergeReviews() {
	raw, err := os.ReadFile(filepath.Join(corpusRel, "model.meta.json"))
	if err != nil {
		panic(err)
	}
	model, err := som.SpecModelFromJSON(raw)
	if err != nil {
		panic(err)
	}
	doc := func(text string) *som.SpecDocument {
		d := som.NewSpecDocument()
		d.LoadJSON(&som.DocumentJson{Content: map[string]string{"DEMO/SUM": text}})
		return d
	}
	team := []som.SpecReviewMember{
		{MemberID: "alice", DisplayName: "Alice Owner", Role: "Product owner"},
		{MemberID: "bob", DisplayName: "Bob Dev", Role: "Developer"},
	}
	result, err := som.MergeReviews(model, doc("Sessions expire after 30 minutes."),
		[]som.SpecReviewedCopy[*som.SpecDocument]{
			{SpecReviewMember: team[0], Document: doc("Sessions expire after 15 minutes.")},
			{SpecReviewMember: team[1], Document: doc("Sessions expire after 15 minutes.")},
		},
		som.SpecReviewMergeOptions{Team: team, Date: "2026-11-05", Author: "Alice Owner"})
	if err != nil {
		panic(err)
	}
	fmt.Println(result.Merged.ContentOr("DEMO/SUM"))
	fmt.Println(len(result.Report.Conflicts))
	// Output:
	// Sessions expire after {~~ 30 ~> 15 ~~}{@alice,bob} minutes.
	// 0
}
