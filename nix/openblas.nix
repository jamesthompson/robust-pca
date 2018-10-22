{ stdenv, fetchurl, gfortran, perl, which, config, coreutils
# Most packages depending on openblas expect integer width to match
# pointer width, but some expect to use 32-bit integers always
# (for compatibility with reference BLAS).
, blas64 ? null
, cpuMarch
}:

with stdenv.lib;

let blas64_ = blas64; in

let
  # See https://github.com/xianyi/OpenBLAS/blob/develop/TargetList.txt
  # and https://gcc.gnu.org/onlinedocs/gcc-6.3.0/gcc/x86-Options.html#x86-Options
  cpuMarchTargets = {
    nehalem = "NEHALEM";
    westmere = "NEHALEM";
    sandybridge = "SANDYBRIDGE";
    ivybridge = "SANDYBRIDGE";
    haswell = "HASWELL";
    broadwell = "HASWELL";
    skylake = "HASWELL";
    knl = "HASWELL";
    skylake-avx512 = "HASWELL";
  };

  config = if cpuMarch == "x86-64"
    then {
      BINARY = "64";
      TARGET = "ATHLON";
      DYNAMIC_ARCH = "1";
      CC = "gcc";
      USE_OPENMP = "1";
    }
    else {
      BINARY = "64";
      TARGET = cpuMarchTargets.${cpuMarch} or (throw "unsupported march: ${cpuMarch}");
      DYNAMIC_ARCH = "0";
      CC = "gcc";
      USE_OPENMP = "1";
      # Setting HOSTCC and CROSS enables cross compilation, which prevents
      # running tests that we might not be able to execute due to missing
      # CPU instructions.
      HOSTCC = "gcc";
      CROSS = "1";
    };
in

let
  blas64 =
    if blas64_ != null
      then blas64_
      else hasPrefix "x86_64" stdenv.system;

  version = "0.2.19";
in
stdenv.mkDerivation {
  name = "openblas-${version}";
  src = fetchurl {
    url = "https://github.com/xianyi/OpenBLAS/archive/v${version}.tar.gz";
    sha256 = "0mw5ra1vjsqiba79zdhqfkqq6v3bla5a5c0wj7vca9qgjzjbah4w";
    name = "openblas-${version}.tar.gz";
  };

  inherit blas64;

  # Some hardening features are disabled due to sporadic failures in
  # OpenBLAS-based programs. The problem may not be with OpenBLAS itself, but
  # with how these flags interact with hardening measures used downstream.
  # In either case, OpenBLAS must only be used by trusted code--it is
  # inherently unsuitable for security-conscious applications--so there should
  # be no objection to disabling these hardening measures.
  hardeningDisable = [
    # don't modify or move the stack
    "stackprotector" "pic"
    # don't alter index arithmetic
    "strictoverflow"
    # don't interfere with dynamic target detection
    "relro" "bindnow"
  ];

  nativeBuildInputs =
    [gfortran perl which]
    ++ optionals stdenv.isDarwin [coreutils];

  makeFlags =
    [
      "FC=gfortran"
      ''PREFIX="''$(out)"''
      "NUM_THREADS=64"
      "INTERFACE64=${if blas64 then "1" else "0"}"
    ]
    ++ mapAttrsToList (var: val: var + "=" + val) config;

  doCheck = true;
  checkTarget = "tests";

  meta = with stdenv.lib; {
    description = "Basic Linear Algebra Subprograms";
    license = licenses.bsd3;
    homepage = "https://github.com/xianyi/OpenBLAS";
    platforms = platforms.unix;
    maintainers = with maintainers; [ ttuegel ];
  };
}
