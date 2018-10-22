# Robust PCA

Robust principal component analysis library for periodic data (e.g. time-series) anomaly detection in GHC/Haskell.

It is a fairly faithful port of [Netflix/Surus](https://github.com/Netflix/Surus) based on the work in the [robust PCA paper](http://statweb.stanford.edu/~candes/papers/RobustPCA.pdf) by Wright *et al.*

In short, the library is aimed toward optimization of the problem `M = L + S`, where `M` is the matrix of (idealized) input data, `L` is a low-rank matrix approximating the input data and `S` is a sparse matrix of "outliers". The procedure also outputs the difference between the input data and tolerated delta (error), should that be required.

This approach assumes that the data is periodic, as such this is provided as an optimization input parameter along with tolerances. More detail is given in the module itself.


## Building

This library is built with [nix](https://nixos.org/nix/). It depends upon [hmatrix](https://hackage.haskell.org/package/hmatrix) for linear algebra functionality and is currently only working in x86-64 Linux environments due to difficulties with OpenBlas linking on OS X.

To enter the nix-shell:

```nix
$ nix-shell -A robust-pca.env nix/release.nix
```

If `cabal` is in scope, `cabal repl` should bring you into GHCi for experimentation.
