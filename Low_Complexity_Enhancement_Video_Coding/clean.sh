#!/bin/bash

echo "🧹 Limpando arquivos auxiliares..."
rm -f monografia.{aux,bbl,blg,glo,glg,acn,alg,ist,acr,lof,lot,idx,ilg,ind,log,out,toc,xdy}
rm -f monografia.glossary* monografia.glsdefs
echo "✔️ Pronto!"