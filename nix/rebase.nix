{ mkDerivation, base, base-prelude, bifunctors, bytestring
, containers, contravariant, contravariant-extras, deepseq, dlist
, either, fail, fetchgit, hashable, mtl, profunctors, scientific
, semigroupoids, semigroups, stdenv, stm, text, time, transformers
, unordered-containers, uuid, vector, void
}:
mkDerivation {
  pname = "rebase";
  version = "1.2.3";
  src = fetchgit {
    url = "https://github.com/nikita-volkov/rebase.git";
    sha256 = "1kj2fch4sdgnis4022cd6m4mg68g30g123706wn8d2n1qjixlg07";
    rev = "2dcd9842627c91e8d7f62d07bb54f622c81b709d";
  };
  libraryHaskellDepends = [
    base base-prelude bifunctors bytestring containers contravariant
    contravariant-extras deepseq dlist either fail hashable mtl
    profunctors scientific semigroupoids semigroups stm text time
    transformers unordered-containers uuid vector void
  ];
  homepage = "https://github.com/nikita-volkov/rebase";
  description = "A more progressive alternative to the \"base\" package";
  license = stdenv.lib.licenses.mit;
}
