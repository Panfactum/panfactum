#!/usr/bin/env bash

# This script coordinates building an image for one 
# of our packages in our remote buildkit instance

set -eo pipefail

PORT=$((RANDOM % 64510 + 1024))
echo "Using port $PORT for tunneling"

scale-buildkit --turn-on

sleep 1

BUILDKIT_ADR=$(get-buildkit-address | cut -c 7-)
export BUILDKIT_HOST=tcp://localhost:$PORT

scale-buildkit --record-build

tunnel $BUILDKIT_ADR $PORT &
TUNNEL_PID=$!
trap "pkill -P $TUNNEL_PID" EXIT ERR

sleep 5

REPO=$(echo $1 | sed 's/.*\///; s/:.*//')

buildctl \
    build \
    --frontend=dockerfile.v0 \
    --output "type=image,name=$1,push=true" \
    --local context=. \
    --local dockerfile=packages/$REPO \
    --opt filename=./Containerfile \
    --export-cache type=s3,region=us-east-2,bucket=buildkit-cache-41151449fc2ce51f,name=$REPO \
    --import-cache type=s3,region=us-east-2,bucket=buildkit-cache-41151449fc2ce51f,name=$REPO \
    $2