<!--
  Title: chore(release): release vX.Y.Z
  Source: UAT-testflight (or hotfix/* or ci/*) → Target: master
  Merge with **Create a merge commit**. Never squash or rebase: it breaks the
  shared history promotions rely on.
-->

## Before merging

- [ ] Source branch is `UAT-testflight` (or `hotfix/*` / `ci/*`) and the `source-branch` check passes
- [ ] UAT build was tested

## After merging

Merging builds nothing. Publish a GitHub Release to cut the build:

- [ ] Releases → Draft a new release
- [ ] Choose tag `vX.Y.Z`, *Create new tag on publish* (1–3 dot-separated integers: `v1.2.3`, `v1.2` or `v2`; the tag sets `MARKETING_VERSION`)
- [ ] Target: `master` (always)
- [ ] Generate release notes, then Publish release
- [ ] Hotfix only: merge `master` back into `dev`

## Version

`vX.Y.Z`

## What's shipping
<!-- the merged PRs in this release; Generate release notes can fill this in -->
