#!/bin/bash
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Swift on Linux can lint, format and compile non-Apple code, but not build this app:
# SwiftUI, SwiftData and xcodebuild need macOS. Real builds and tests run in Xcode Cloud.

SWIFT_VERSION="6.2.4"
SWIFT_DIR="/opt/swift"
SWIFTLINT_VERSION="0.63.2"

if [ "$(uname -m)" != "x86_64" ]; then
  echo "session-start: unsupported architecture $(uname -m); skipping Swift setup" >&2
  exit 0
fi

# download.swift.org is blocked by the cloud network policy, so the official toolchain is
# taken from the swift Docker Hub image: the registry is reachable and blobs are verified
# against the digest in the manifest.
install_swift() {
  local work token manifest layer_digest
  work="$(mktemp -d)"
  trap 'rm -rf "$work"' RETURN

  token="$(curl -fsS "https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/swift:pull" \
    | python3 -I -c 'import sys,json; print(json.load(sys.stdin)["token"])')"

  local index_digest
  index_digest="$(curl -fsS -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.oci.image.index.v1+json" \
    "https://registry-1.docker.io/v2/library/swift/manifests/${SWIFT_VERSION}-noble" \
    | jq -r '.manifests[] | select(.platform.architecture=="amd64" and .platform.os=="linux") | .digest')"

  manifest="$(curl -fsS -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.oci.image.manifest.v1+json" \
    "https://registry-1.docker.io/v2/library/swift/manifests/${index_digest}")"

  # The toolchain is by far the largest layer
  layer_digest="$(jq -r '.layers | max_by(.size) | .digest' <<<"$manifest")"

  curl -fsSL -H "Authorization: Bearer $token" -o "$work/toolchain.tar.gz" \
    "https://registry-1.docker.io/v2/library/swift/blobs/${layer_digest}"

  if [ "$(sha256sum "$work/toolchain.tar.gz" | cut -d' ' -f1)" != "${layer_digest#sha256:}" ]; then
    echo "session-start: Swift toolchain digest mismatch" >&2
    return 1
  fi

  rm -rf "$SWIFT_DIR"
  mkdir -p "$SWIFT_DIR"
  tar xzf "$work/toolchain.tar.gz" -C "$SWIFT_DIR" --strip-components=1 usr
}

install_swiftlint() {
  local work
  work="$(mktemp -d)"
  trap 'rm -rf "$work"' RETURN

  curl -fsSL -o "$work/swiftlint.zip" \
    "https://github.com/realm/SwiftLint/releases/download/${SWIFTLINT_VERSION}/swiftlint_linux_amd64.zip"
  unzip -q -o "$work/swiftlint.zip" -d "$work"

  # The dynamic binary is needed: swiftlint-static has no SourceKit and silently skips
  # custom_rules (our layer rules). The wrapper points it at the toolchain's SourceKit.
  mkdir -p /opt/swiftlint
  install -m 755 "$work/swiftlint" /opt/swiftlint/swiftlint
  cat > /usr/local/bin/swiftlint << WRAPPER
#!/bin/bash
export LINUX_SOURCEKIT_LIB_PATH="$SWIFT_DIR/lib"
exec /opt/swiftlint/swiftlint "\$@"
WRAPPER
  chmod 755 /usr/local/bin/swiftlint
}

# Runtime libraries the toolchain links against (list from swift.org's Ubuntu 24.04 install page)
SWIFT_APT_DEPS=(
  binutils git libc6-dev libcurl4-openssl-dev libedit2 libgcc-13-dev libncurses-dev
  libsqlite3-0 libstdc++-13-dev libxml2-dev libz3-dev pkg-config tzdata unzip zlib1g-dev
)
MISSING_DEPS=()
for pkg in "${SWIFT_APT_DEPS[@]}"; do
  dpkg -s "$pkg" >/dev/null 2>&1 || MISSING_DEPS+=("$pkg")
done
if [ "${#MISSING_DEPS[@]}" -gt 0 ]; then
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends "${MISSING_DEPS[@]}"
fi

if ! "$SWIFT_DIR/bin/swift" --version 2>/dev/null | grep -q "Swift version ${SWIFT_VERSION} "; then
  install_swift
fi

if ! swiftlint --version 2>/dev/null | grep -qx "$SWIFTLINT_VERSION"; then
  install_swiftlint
fi

if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$SWIFT_DIR/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

"$SWIFT_DIR/bin/swift" --version
swiftlint --version
