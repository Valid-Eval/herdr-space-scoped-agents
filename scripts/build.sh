#!/bin/sh
# Install-time build step for macOS/Linux (run by Herdr at `plugin install`,
# cwd = plugin root).
#
# Builds the binary from source with `go`. There is deliberately no prebuilt
# download: the binary is always compiled from the code you installed, so
# nothing is fetched from a GitHub release at install time (see
# specs/006-build-from-source.md).
set -eu

BIN="herdr-space-scoped-agents"

root="${HERDR_PLUGIN_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}"
manifest="$root/herdr-plugin.toml"
out="$root/bin/$BIN"

version="$(sed -n 's/^version *= *"\([^"]*\)".*/\1/p' "$manifest" | head -n1)"
[ -n "$version" ] || { echo "cannot read version from $manifest" >&2; exit 1; }

command -v go >/dev/null 2>&1 || {
  echo "ERROR: Go is required to build $BIN (https://go.dev/dl/)" >&2
  exit 1
}

mkdir -p "$root/bin"
echo "building $BIN v${version} from source with go..." >&2
( cd "$root" && go build -trimpath -ldflags "-s -w -X main.version=${version}" -o "$out" . )
echo "built -> $out" >&2
