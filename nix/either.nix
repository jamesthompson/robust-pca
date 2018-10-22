{ mkDerivation, base, bifunctors, fetchgit, hedgehog, mtl
, profunctors, semigroupoids, semigroups, stdenv
}:
mkDerivation {
  pname = "either";
  version = "5";
  src = fetchgit {
    url = "https://github.com/ekmett/either.git";
    sha256 = "1xjmcrh149xljnddn8b98cg5ggnpspdxsaqa2d39ivl0w18pk011";
    rev = "a20c3d6b7ca6e25e2bae3c7d464fe12360fef65c";
  };
  libraryHaskellDepends = [
    base bifunctors mtl profunctors semigroupoids semigroups
  ];
  testHaskellDepends = [ base hedgehog ];
  homepage = "http://github.com/ekmett/either/";
  description = "Combinators for working with sums";
  license = stdenv.lib.licenses.bsd3;
}
