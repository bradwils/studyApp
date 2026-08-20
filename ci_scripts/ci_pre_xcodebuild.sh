#!/bin/zsh

# Xcode Cloud runs this after cloning, before each xcodebuild invocation.
#
# Build number : climbs on every build in every lane, set from Xcode Cloud's own
#                counter. Never reset, never reused — App Store Connect rejects a
#                build number it has already seen for a given marketing version.
# Version      : on a v1.2.3 tag the tag is the source of truth, so a shipped
#                build is always traceable back to a tag. dev and UAT keep
#                whatever is in the project — the version being worked toward.

set -euo pipefail

PROJECT="$CI_PRIMARY_REPOSITORY_PATH/studyApp.xcodeproj/project.pbxproj"
BUILD_NUMBER="${CI_BUILD_NUMBER:-1}"

sed -i '' "s/CURRENT_PROJECT_VERSION = .*;/CURRENT_PROJECT_VERSION = ${BUILD_NUMBER};/g" "$PROJECT"

if [[ -n "${CI_TAG:-}" && "${CI_TAG}" == v* ]]; then
  VERSION="${CI_TAG#v}"
  # App Store Connect accepts at most three dot-separated integers, no leading
  # zeros. Fail loudly here rather than 40 minutes later at the upload step.
  if [[ ! "$VERSION" =~ '^[1-9]?[0-9]+(\.[0-9]+){0,2}$' ]]; then
    echo "error: tag '${CI_TAG}' is not 1-3 dot-separated integers" >&2
    exit 1
  fi
  sed -i '' "s/MARKETING_VERSION = .*;/MARKETING_VERSION = ${VERSION};/g" "$PROJECT"
fi

echo "lane          -> ${CI_TAG:-${CI_BRANCH:-unknown}}"
echo "build number  -> ${BUILD_NUMBER}"
echo "marketing ver -> $(grep -m1 -o 'MARKETING_VERSION = [^;]*' "$PROJECT")"
