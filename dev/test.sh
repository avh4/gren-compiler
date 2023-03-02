#!/bin/bash
set -euxo pipefail

exec cabal test -f dev
