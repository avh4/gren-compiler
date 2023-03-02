#!/bin/bash
set -euxo pipefail

nixfmt default.nix shell.nix
ormolu --mode inplace $(git ls-files '*.hs')

echo "OK"
