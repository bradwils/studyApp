<!--
  Title: chore(release): promote dev to UAT-testflight
  Source: dev → Target: UAT-testflight
  Merge with **Create a merge commit**. Never squash or rebase: it breaks the
  shared history promotions rely on.
-->

## Before merging

- [ ] Current-head build/test checks reviewed (SwiftLint alone does not verify the app)
- [ ] Installed the current `dev` build from TestFlight and opened it
- [ ] `MARKETING_VERSION` is the version testers should see
- [ ] If `MARKETING_VERSION` was bumped this cycle, `ci_scripts/build_number_offset` was set in the same commit
- [ ] TestFlight "What to Test" notes reviewed and supplied (manual until automated notes are integrated and verified)
- [ ] Confirm the promotion matches the [Swift-file trigger](../../pipeline.md#xcode-cloud-workflows) if a UAT TestFlight build is expected

## What's in this promotion
<!-- list the PRs merged into dev since the last promotion -->

## What to Test notes
<!-- paste the TestFlight "What to Test" text -->
