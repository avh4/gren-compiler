{ sources ? import ./nix/sources.nix, compiler ? "ghc944" }:
let

  gitignore = import sources."gitignore.nix" { };
  inherit (gitignore) gitignoreSource gitignoreFilterWith;

  # Create an override of nixpkgs that has the set of haskell packages/versions that we want
  # This follows the approach explained at https://github.com/Gabriella439/haskell-nix
  haskellPackageOverrides = pkgs: self: super:
    with pkgs.haskell.lib;
    let inherit (pkgs) lib;
    in rec {
      gren = overrideCabal (self.callCabal2nix "gren" ./. { }) (orig: {
        src = lib.cleanSourceWith {
          name = "source";
          filter = fpath: ftype:
            gitignoreFilterWith { basePath = ./.; } fpath ftype;
          src = ./.;
        };
      });
    };

  pkgs = import sources.nixpkgs {
    config = {
      packageOverrides = pkgs: rec {
        haskell = pkgs.haskell // {
          packages = pkgs.haskell.packages // {
            forGren = pkgs.haskell.packages."${compiler}".override {
              overrides = haskellPackageOverrides pkgs;
            };
          };
        };
      };
    };
  };

  haskellPackages = pkgs.haskell.packages.forGren;

  # This contains haskell tools that we want to match our verion of ghc,
  # but that have dependency version constraints that conflict with ours.
  haskellTools = pkgs.haskell.packages."${compiler}";
in {
  gren = haskellPackages.gren;

  # Make the following available to default.nix and shell.nix
  inherit pkgs haskellPackages haskellTools;
}
