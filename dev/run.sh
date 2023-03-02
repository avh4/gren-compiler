#!/bin/bash
set -euxo pipefail

(cd ../example-projects/ && git reset --hard)
(cd ../core/ && git reset --hard)
# find ../example-projects/ -name '*.gren' -print0 | xargs -0 cabal run -f dev gren -- format --yes
cabal run -f dev gren -- format --yes ../example-projects
(cd ../core && ../compiler/result/bin/gren format --yes)
(
  (cd ../example-projects/ && git --no-pager diff --color)
  (cd ../core/ && git --no-pager diff --color)
) | less

