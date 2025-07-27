#!/bin/bash

pdflatex monografia.tex || exit 1
bibtex monografia || exit 1
makeglossaries monografia || exit 1
pdflatex monografia.tex || exit 1