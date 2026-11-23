<!--
  Title: chore(release): release vX.Y.Z
  Source: UAT-testflight (or hotfix/*) → Target: master
  CI-only maintenance uses its own PR and does not require a release.
  Merge with **Create a merge commit**. Never squash or rebase: it breaks the
  shared history promotions rely on.
-->

## Before merging

- [ ] Source branch is `UAT-testflight` (or `hotfix/*` for a hotfix) and the `source-branch` check passes
- [ ] Current-head checks pass and the UAT build was tested (or the hotfix candidate was tested)
- [ ] Version/tag and build-number offset reviewed
- [ ] TestFlight "What to Test" instructions reviewed; release notes do not replace them

## After merging

Publish a GitHub Release to create the tag that triggers the release build.

- [ ] Releases → Draft a new release
- [ ] Choose tag `vX.Y.Z`, *Create new tag on publish* (1–3 dot-separated integers: `v1.2.3`, `v1.2` or `v2`; the tag sets `MARKETING_VERSION`)
- [ ] Target: `master` (always)
- [ ] Generate release notes, then Publish release
- [ ] Hotfix only: merge `master` back into `dev`

## Version

`vX.Y.Z`

## What's shipping
<!-- the merged PRs in this release; Generate release notes can fill this in -->
