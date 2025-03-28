watch: qpl-survey/qpl-survey.md
	marp qpl-survey/qpl-survey.md -o ./out/qpl-survey.html -w

html: qpl-survey/qpl-survey.md
	marp qpl-survey/qpl-survey.md -o ./out/qpl-survey.html

pdf: qpl-survey/qpl-survey.md
	marp qpl-survey/qpl-survey.md  --pdf --allow-local-files -o ./out/qpl-survey.pdf

.PHONY: clean
clean:
	rm -r out 
