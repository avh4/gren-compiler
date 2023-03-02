#!/bin/bash
set -euxo pipefail

exec cabal build -f dev
