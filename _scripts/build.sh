#!/bin/bash

set -euo pipefail

docker run --rm \
  --volume="$PWD:/srv/jekyll" \
  jekyll/jekyll:3.5 \
  jekyll build
