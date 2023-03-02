#!/bin/bash

set -euxo pipefail

git status
dev/autofix.sh
dev/test.sh
dev/build.sh
git status
