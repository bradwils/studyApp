#!/bin/zsh

# Xcode Cloud runs this after cloning, before each xcodebuild invocation.
#
# Build number : Xcode Cloud's counter minus build_number_offset. The counter is
#                shared by every workflow and can never go down, so lanes can't
#                collide. App Store Connect only needs (version, build) to be
#                unique, so when MARKETING_VERSION is bumped, set the offset in
#                the same commit to the current counter (Settings > Build Number
#                in Xcode Cloud, minus one) and the new version restarts near 1.
# Version      : on a v1.2.3 tag the tag is the source of truth, so a shipped
#                build is always traceable back to a tag. dev and UAT keep
#                whatever is in the project — the version being worked toward.

set -euo pipefail

PROJECT="$CI_PRIMARY_REPOSITORY_PATH/studyApp.xcodeproj/project.pbxproj"
OFFSET="$(<"$CI_PRIMARY_REPOSITORY_PATH/ci_scripts/build_number_offset")"

if [[ ! "$OFFSET" =~ '^[0-9]+$' ]]; then
  echo "error: ci_scripts/build_number_offset must be a whole number, got '${OFFSET}'" >&2
  exit 1
fi

BUILD_NUMBER=$(( ${CI_BUILD_NUMBER:-1} - OFFSET ))
if (( BUILD_NUMBER < 1 )); then
  echo "error: counter ${CI_BUILD_NUMBER:-1} minus offset ${OFFSET} is ${BUILD_NUMBER}; the offset is set too high" >&2
  exit 1
fi

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
