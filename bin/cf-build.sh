#!/usr/bin/env bash
# Cloudflare Pages build command for staging/beta/production. Shared by all
# three CF Pages projects so the build logic lives in this repo, not inlined
# in the CF dashboard.
# Usage: bin/cf-build.sh <staging|beta|production>
set -euo pipefail

ENV="${1:-}"

if [[ ! "${ENV}" =~ ^(staging|beta|production)$ ]]; then
    echo "Error: Invalid environment. Must be one of: staging, beta, production"
    echo "Usage: bin/cf-build.sh <staging|beta|production>"
    exit 1
fi

ROOT="$(cd "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

if [[ -d flutter ]]; then
    (cd flutter && git checkout stable && git pull)
else
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git
fi

flutter/bin/flutter doctor
flutter/bin/flutter clean
flutter/bin/flutter config --enable-web

cp ".env.${ENV}" .env

COMMIT="$(git rev-parse --short HEAD)"
BUILD_DATE="$(date "+%Y-%b-%d")"
sed -i "s/VERSION_PLACEHOLDER/${COMMIT} (${BUILD_DATE})/" .env

if [[ -n "${SEQ_API_KEY:-}" ]]; then
    sed -i "s/SEQ_API_KEY_PLACEHOLDER/${SEQ_API_KEY}/" .env
fi

flutter/bin/flutter build web --base-href="/" --release
