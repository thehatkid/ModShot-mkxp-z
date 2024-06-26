if [[ "${BASH_SOURCE-}" = "$0" ]]; then
  echo "You must 'source' this script: source $0" >&2
  exit 1
fi

if [[ "$MKXPZ_PREFIX" ]]; then
  echo "Already done" >&2
  return
fi

MKXPZ_ENVDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
MKXPZ_ARCH="$(uname -m)"

# Export environment variables for build stuff
export MKXPZ_PREFIX="${MKXPZ_ENVDIR}/build-${MKXPZ_ARCH}"
export PATH="${MKXPZ_PREFIX}/bin:${PATH}"
export PKG_CONFIG_PATH="${MKXPZ_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}"
export CMAKE_PREFIX_PATH="${MKXPZ_PREFIX}:${CMAKE_PREFIX_PATH}"
