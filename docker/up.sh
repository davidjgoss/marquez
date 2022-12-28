#!/bin/bash
#
# Copyright 2018-2022 contributors to the Marquez project
# SPDX-License-Identifier: Apache-2.0
#
# Usage: $ ./build-and-push.sh [FLAGS] [ARG...]

set -e

# Version of Marquez
readonly VERSION=0.29.0
# Build version of Marquez
readonly BUILD_VERSION="$(git log --pretty=format:'%h' -n 1)" # SHA1

title() {
  echo -e "\033[1m${1}\033[0m"
}

usage() {
  echo "usage: ./$(basename -- ${0}) [FLAGS] [ARG...]"
  echo "A script used to run Marquez via Docker"
  echo
  title "EXAMPLES:"
  echo "  # Build image from source"
  echo "  $ ./up.sh --build"
  echo
  echo "  # Build image from source, then seed HTTP API server with metadata"
  echo "  $ ./up.sh --build --seed"
  echo
  echo "  # Use tagged image"
  echo "  ./up.sh --tag X.Y.X"
  echo
  echo "  # Use tagged image, then seed HTTP API server with metadata"
  echo "  ./up.sh --tag X.Y.X --seed"
  echo
  echo "  # Set HTTP API server port"
  echo "  ./up.sh --api-port 9000"
  echo
  title "ARGUMENTS:"
  echo "  -a, --api-port int          api port (default: 5000)"
  echo "  -m, --api-admin-port int    api admin port (default: 5001)"
  echo "  -w, --web-port int          web port (default: 3000)"
  echo "  -t, --tag string            docker image tag (default: ${VERSION})"
  echo "  --args string               docker arguments"
  echo
  title "FLAGS:"
  echo "  -b, --build           build images from source"
  echo "  -s, --seed            seed HTTP API server with metadata"
  echo "  -d, --detach          run in the background"
  echo "  --no-web              don't start the web UI"
  echo "  --no-volumes          don't create volumes"
  echo "  -h, --help            show help for script"
  exit 1
}

# Change working directory to project root
project_root=$(git rev-parse --show-toplevel)
cd "${project_root}/"

# Base docker compose file
compose_files="-f docker-compose.yml"

API_PORT=5000
API_ADMIN_PORT=5001
WEB_PORT=3000
TAG=${VERSION}
ARGS="-V --force-recreate --remove-orphans"
while [ $# -gt 0 ]; do
  case $1 in
    -a|'--api-port')
       shift
       API_PORT="${1}"
       ;;
    -m|'--api-admin-port')
       shift
       API_ADMIN_PORT="${1}"
       ;;
    -w|'--web-port')
       shift
       WEB_PORT="${1}"
       ;;
    -t|'--tag')
       shift
       TAG="${1}"
       ;;
    --args)
       shift
       ARGS="${1}"
       ;;
    --no-web)
       NO_WEB='true'
       ;;
    --no-volumes)
      NO_VOLUMES='true'
      ;;
    -b|'--build')
       BUILD='true'
       TAG="${BUILD_VERSION}"
       ;;
    -s|'--seed')
       SEED='true'
       ;;
    -d|'--detach')
       DETACH='true'
       ;;
    -h|'--help')
       usage
       exit 0
       ;;
    *) usage
       exit 1
       ;;
  esac
  shift
done

# Enable detach mode to run containers in background
if [[ "${DETACH}" = "true" ]]; then
  ARGS+=" --detach"
fi

# Enable building from source
if [[ "${BUILD}" = "true" ]]; then
  compose_files+=" -f docker-compose.dev.yml"
  ARGS+=" --build"
fi

# Enable starting HTTP server with sample metadata
if [[ "${SEED}" = "true" ]]; then
  compose_files+=" -f docker-compose.seed.yml"
fi

# Enable web UI
if [[ "${NO_WEB}" = "false" ]]; then
  # Enable building web UI from source; otherwise use 'latest' build
  [[ "${BUILD}" = "true" ]] && compose_files+=" -f docker-compose.web-dev.yml" \
    || compose_files+=" -f docker-compose.web.yml"
fi

# Create docker volume for Marquez
if [[ "${NO_VOLUMES}" = "false" ]]; then
  ./docker/volumes.sh marquez
fi

# Run docker compose cmd with overrides
DOCKER_SCAN_SUGGEST=false API_PORT=${API_PORT} API_ADMIN_PORT=${API_ADMIN_PORT} WEB_PORT=${WEB_PORT} TAG=${TAG} \
  docker-compose --log-level ERROR $compose_files up $ARGS
