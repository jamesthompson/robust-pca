{ mkDerivation, base, bytestring, comonad, containers
, contravariant, criterion, fetchgit, hashable, mwc-random
, primitive, profunctors, semigroups, stdenv, text, transformers
, unordered-containers, vector, vector-builder
}:
mkDerivation {
  pname = "foldl";
  version = "1.3.7";
  src = fetchgit {
    url = "https://github.com/Gabriel439/Haskell-Foldl-Library";
    sha256 = "1y7p9v04bgmn2bk0l3cdfzn7ish37n751mi197npz4vnyfvsv9xw";
    rev = "64c260f19fe08f1abca4669177fa0bd422e4ac4b";
  };
  libraryHaskellDepends = [
    base bytestring comonad containers contravariant hashable
    mwc-random primitive profunctors semigroups text transformers
    unordered-containers vector vector-builder
  ];
  benchmarkHaskellDepends = [ base criterion ];
  description = "Composable, streaming, and efficient left folds";
  license = stdenv.lib.licenses.bsd3;
}
