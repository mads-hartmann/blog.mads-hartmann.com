#!/bin/bash

set -euo pipefail

docker run --rm \
  --volume="$PWD:/srv/jekyll" \
  jekyll/jekyll:3.8 \
  jekyll build
