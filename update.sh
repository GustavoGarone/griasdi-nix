#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq
# shellcheck shell=bash
# Pin sources.json to the newest griasdi build on the update server.
# The server keeps only the newest build and the one before it, so a pin
# stops downloading soon after a new build is published; rerun this then.
set -euo pipefail

updates=https://griasdi.doodleshnookie.net/updates
cd "$(dirname "$0")"
trap 'rm -f sources.json.tmp' EXIT

fetch() { curl -sf --max-time 30 "$1"; }

channel='' build=''
for ch in ${1:-release dev}; do
  b=$(fetch "$updates/$ch/latest" | tr -d '[:space:]') || continue
  if [[ $b =~ ^[0-9]+$ ]]; then
    channel=$ch build=$b
    break
  fi
done
[[ -n $build ]] || { echo "no build found" >&2; exit 1; }

base=$updates/$channel/$build
fetch "$base/manifest.json" | jq --arg base "$base" --arg channel "$channel" --argjson build "$build" '
  def desktop($target): [.artifacts[]
    | select(.component == "desktop" and .kind == "tar.gz" and .target == $target)
    | { url: "\($base)/\(.file)", sha256 }];
  {
    channel: $channel, build: $build, version,
    "x86_64-linux": desktop("x86_64-unknown-linux-gnu")[0],
    "aarch64-linux": desktop("aarch64-unknown-linux-gnu")[0]
  }' > sources.json.tmp

# Keep the old pin unless the new one is complete.
if ! jq -e '
  (.version | type == "string")
  and ([."x86_64-linux", ."aarch64-linux"]
    | all(type == "object" and (.sha256 | test("^[0-9a-f]{64}$"))))' \
  sources.json.tmp > /dev/null; then
  echo "manifest of build $build is incomplete; keeping sources.json" >&2
  exit 1
fi
mv sources.json.tmp sources.json
echo "griasdi $(jq -r '"\(.version) build \(.build) (\(.channel))"' sources.json)"
