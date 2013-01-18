all		: manual.ps

squeaky 	:
		\rm -f manual.{ps,dvi}

clean 		: 
		\rm -f manual.{blg,log,aux,bbl}

manual.ps	: manual.dvi
		dvips -t a4 -o manual.ps manual

manual.dvi 	: manual.tex manual.bbl
		latex manual
		latex manual

manual.bbl	: manual.tex manual.bib
		latex  manual
		bibtex manual

