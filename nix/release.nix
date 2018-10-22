{ compiler ? "ghc843" }:

let
  config = {
    packageOverrides = pkgs: rec {
      openblas = (pkgs.callPackage ./openblas.nix {
        cpuMarch = "x86-64";
        # See <https://github.com/albertoruiz/hmatrix/issues/211>
        blas64 = false;
      });
      haskell = pkgs.haskell // {
        packages = pkgs.haskell.packages // {
          "${compiler}" = pkgs.haskell.packages."${compiler}".override {
            overrides = haskellPackagesNew: haskellPackagesOld: rec {
              foldl = haskellPackagesNew.callPackage ./foldl.nix {};
              foldl-statistics = haskellPackagesNew.callPackage ./foldl-statistics.nix {};
              hmatrix = pkgs.haskell.lib.enableCabalFlag (pkgs.haskell.lib.enableCabalFlag (haskellPackagesNew.callPackage ./hmatrix.nix { }) "openblas") "disable-default-paths";
              robust-pca = haskellPackagesNew.callPackage ./default.nix {};
              # rebase = haskellPackagesNew.callPackage ./rebase.nix {};
              # either = haskellPackagesNew.callPackage ./either.nix {};
            };
          };
        };
      };
    };
    allowBroken = true;
  };

in

let
  pkgs = import ./pkgs.nix { inherit config; };
in
  {
    robust-pca = pkgs.haskell.packages.${compiler}.robust-pca;
  }
