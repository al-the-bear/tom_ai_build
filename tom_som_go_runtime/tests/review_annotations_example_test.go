// The quick start of doc/review_annotations.md, run as a Go example so the
// output the guide prints stays true.
package tests

import (
	"fmt"

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
	}); err != nil {
		panic(err)
	}
	if err := review.SetAnswer("BQ-1", "yes"); err != nil {
		panic(err)
	}
	fmt.Printf("%+v\n", review.Counts())
	// Output:
	// [C-1]
	// DEMO C-1
	// {Questions:1 OpenQuestions:0 AnsweredQuestions:1 Comments:1 Marks:0}
}
