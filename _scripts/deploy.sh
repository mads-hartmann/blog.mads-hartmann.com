#!/usr/bin/env bash

set -euo pipefail

bucket=mads-hartmann.com

function deploy-to-s3 {
  echo "Deploying to ${bucket}"
  aws s3 sync \
    --region eu-central-1 \
    _site/ \
    s3://${bucket}/ \
      --acl public-read \
      --cache-control "max-age=0, no-cache, no-store" \
      --expires "Thu, 01 Jan 1970 00:00:00 GMT"
}

function invlidate-cache {
    echo "Invalidating CloudFront distribution"
    aws cloudfront create-invalidation \
        --distribution-id E2PIM647ASI75H \
        --paths '/*'
}

function main {
    ./_scripts/build.sh
    deploy-to-s3
    invlidate-cache
}

main
