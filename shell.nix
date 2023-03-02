args@{ ... }:
let
  default = import ./. args;
  inherit (default) pkgs haskellPackages haskellTools;
in haskellPackages.shellFor {
  name = "gren-dev";
  packages = p: [ p.gren ];
  buildInputs = with pkgs; [
    # Haskell dev tools
    cabal-install
    # haskellTools.ghcid
    haskellTools.haskell-language-server
    ormolu

    # nix dev tools
    cabal2nix
    niv
    nixfmt
    #taskell
  ];
}
