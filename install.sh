#!/usr/bin/env bash
set -euo pipefail

[[ "$(uname -s)" == Linux && "$(uname -m)" == x86_64 ]] || {
  echo 'This installer supports Linux x86_64 only.' >&2
  exit 1
}

bin_dir=${TOKEN_TOOLS_BIN_DIR:-"$HOME/.local/bin"}
scratch_dir=$(mktemp -d)
trap 'rm -rf -- "$scratch_dir"' EXIT
mkdir -p -- "$bin_dir"

fetch_binary() {
  local repo=$1 tag=$2 archive=$3 digest=$4 binary=$5
  local dir="$scratch_dir/$binary"
  mkdir -p -- "$dir"

  curl --fail --location --retry 2 --silent --show-error \
    "https://github.com/$repo/releases/download/$tag/$archive" \
    -o "$dir/$archive"
  (cd "$dir" && echo "$digest  $archive" | sha256sum -c -)
  tar -xzf "$dir/$archive" -C "$dir"

  local src
  src=$(find "$dir" -type f -name "$binary" -print -quit)
  [[ -n "$src" ]] || { echo "$binary not found in archive" >&2; exit 1; }

  install -m 755 -- "$src" "$bin_dir/$binary"
  "$bin_dir/$binary" --version
}

fetch_binary yvgude/lean-ctx v3.11.4 lean-ctx-x86_64-unknown-linux-gnu.tar.gz \
  5044d0393f7b51bbb861435bd9d98694339678b4f827a690216d870b6719d56a lean-ctx
fetch_binary rtk-ai/rtk v1.0.1 rtk-x86_64-unknown-linux-musl.tar.gz \
  5b919c3bccb799b67a61866d0e617410a4fcdf173e2614440e59de2fa2003436 rtk

echo "Installed CLIs in $bin_dir. Use absolute paths if it is not on your PATH."
