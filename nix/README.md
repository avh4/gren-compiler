This folder (and `default.nix`, `shell.nix` at the top-level) are files used to build gren
using [nix](https://nixos.org/).


# Dev environment

```sh
nix-shell
```

Then use `cabal` commands as normal within the shell.  The shell also provides `ghcid`
and `haskell-language-server`.


# Reproducible build

```sh
nix-build
```

The resulting binary is put in `./result/bin/gren`


# Updating the nix files

To update the nixpkgs snapshot that the build is locked to:

```sh
niv update nixpkgs --branch nixpkgs-unstable
```

or use `--rev <git sha>` instead of `--branch` for a specific version.
