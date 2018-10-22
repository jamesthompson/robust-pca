{ mkDerivation, base, containers, criterion, fetchgit, foldl
, hashable, math-functions, mwc-random, profunctors
, quickcheck-instances, statistics, stdenv, tasty, tasty-quickcheck
, unordered-containers, vector
}:
mkDerivation {
  pname = "foldl-statistics";
  version = "0.1.5.0";
  doCheck = false;
  src = fetchgit {
    url = "https://github.com/Data61/foldl-statistics.git";
    sha256 = "0grxvaiqlwhgyfjzixdfzpmvv8c7525p3vsxjk34za4kii877adw";
    rev = "e03ca274c8fa9db75b28de55e63012322c69ece6";
  };
  libraryHaskellDepends = [
    base containers foldl hashable math-functions profunctors
    unordered-containers
  ];
  testHaskellDepends = [
    base foldl profunctors quickcheck-instances statistics tasty
    tasty-quickcheck vector
  ];
  benchmarkHaskellDepends = [
    base criterion foldl mwc-random statistics vector
  ];
  homepage = "http://github.com/Data61/foldl-statistics#readme";
  description = "Statistical functions from the statistics package implemented as Folds";
  license = stdenv.lib.licenses.bsd3;
}
