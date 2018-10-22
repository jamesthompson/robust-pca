{ mkDerivation, base, foldl, foldl-statistics, hmatrix, monad-loops
, mtl, stdenv, transformers, lens, openblas, liblapack, darwin
, vector
}:
mkDerivation {
  pname = "robust-pca";
  version = "0.0.0.1";
  src = ./.;
  libraryHaskellDepends = [
    base foldl foldl-statistics hmatrix monad-loops mtl
    transformers lens vector
  ];
  configureFlags = [
    "-fdisable-default-paths"
    "-fopenblas"
  ];
  librarySystemDepends = [ openblas liblapack ];
  homepage = "https://github.com/doctrly/robust-pca";
  description = "Robust Principal Component Analysis a la netflix/surus";
  license = stdenv.lib.licenses.bsd3;
}
