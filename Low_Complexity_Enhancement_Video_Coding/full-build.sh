#!/bin/bash

pdflatex monografia.tex
bibtex monografia
makeglossaries monografia
pdflatex monografia.tex
pdflatex monografia.tex