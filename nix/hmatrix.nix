{ mkDerivation, array, base, binary, blas, bytestring, deepseq
, fetchgit, liblapack, random, semigroups, split, stdenv
, storable-complex, vector, darwin, openblas
}:
mkDerivation {
  pname = "hmatrix";
  version = "0.18.2.0";
  src = fetchgit {
    url = "https://github.com/albertoruiz/hmatrix";
    sha256 = "11wr59wg21rky59j3kkd3ba6aqns9gkh0r1fnhwhn3fp7zfhanqn";
    rev = "d83b17190029c11e3ab8b504e5cdc917f5863120";
  };
  postUnpack = ''
    sourceRoot+=/packages/base;
    echo source root reset to $sourceRoot
  '';
  buildDepends = [ (stdenv.lib.optionals stdenv.isDarwin darwin.apple_sdk.frameworks.Accelerate) ];
  # preConfigure = "sed -i hmatrix.cabal -e '/\\/usr\\//D'";
  configureFlags = [
    "-fdisable-default-paths"
    "-fopenblas"
  ];
  libraryHaskellDepends = [
    array base binary bytestring deepseq random semigroups split
    storable-complex vector
  ];
  librarySystemDepends = [ openblas liblapack ];
  homepage = "https://github.com/albertoruiz/hmatrix";
  description = "Numeric Linear Algebra";
  license = stdenv.lib.licenses.bsd3;
}

