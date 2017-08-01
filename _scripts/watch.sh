#!/bin/bash


set -euo pipefail

jekyll serve \
    --quiet \
    --watch \
    --host localhost \
    --drafts \
    --port 8080
