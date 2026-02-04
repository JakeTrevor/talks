package-html: package-manager/talk.md out/package-manager/diagram.png
	marp package-manager/talk.md --html --allow-local-files -o ./out/package-manager.html --watch
	
package: package-manager/talk.md out/package-manager/diagram.png
	marp package-manager/talk.md --pdf --allow-local-files -o ./out/package-manager.pdf
	

cfe: cfe-in-qc/talk.md out/cfe-in-qc/classical-lattice.png out/cfe-in-qc/quantum-lattice.png out/cfe-in-qc/deutsch-circuit.png out/cfe-in-qc/teleportation-circuit.png out/cfe-in-qc/co-processor-architecture.png out/cfe-in-qc/co-processor-dyn-lift.png out/cfe-in-qc/reduced-quantum-lattice.png out/cfe-in-qc/labelled-reduced-quantum-lattice.png
	marp cfe-in-qc/talk.md --pdf --allow-local-files -o ./out/cfe-in-qc.pdf

cfe-html: cfe-in-qc/talk.md cfe-in-qc/classical-lattice.png cfe-in-qc/quantum-lattice.png
	marp cfe-in-qc/talk.md --html --allow-local-files -o ./out/cfe-in-qc.html

cfe-watch: 
	marp cfe-in-qc/talk.md --html --allow-local-files -o ./out/cfe-in-qc.html --watch

qplSurvey: qpl-survey/qpl-survey.md
	marp qpl-survey/qpl-survey.md  --pdf --allow-local-files -o ./out/qpl-survey.pdf

.PHONY: clean all
clean:
	rm -r out 

all: html pdf


# Magical tikz png-diagram
out/%.png: %.tex
	mkdir -p out/$*
	rm -r out/$*
	@latexmk -pdf -outdir=out -g -jobname=$* -f $<
	@latexmk -pdf -outdir=out -g -c -jobname=$* -f $<
	magick -density 300 out/$*.pdf -quality 90 $@
	rm out/$*.pdf