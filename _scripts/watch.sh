#!/bin/bash


set -euo pipefail

jekyll serve \
    --watch \
    --host localhost \
    --drafts \
    --port 8080
