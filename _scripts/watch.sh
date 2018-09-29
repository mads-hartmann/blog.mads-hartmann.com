#!/bin/bash

set -euo pipefail

docker run --rm \
  --volume="$PWD:/srv/jekyll" \
  -it \
  -p 8080:8080 \
  jekyll/jekyll:3.8 \
  jekyll serve \
    --watch \
    --host 0.0.0.0 \
    --drafts \
    --port 8080
