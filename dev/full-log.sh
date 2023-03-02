#!/bin/bash
set -exuo pipefail

cabal clean
cabal build 2>&1 | tee cabal.log
