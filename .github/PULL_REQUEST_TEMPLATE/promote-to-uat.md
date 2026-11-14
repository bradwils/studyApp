<!--
  Title: chore(release): promote dev to UAT-testflight
  Source: dev → Target: UAT-testflight
  Merge with **Create a merge commit**. Never squash or rebase: it breaks the
  shared history promotions rely on.
-->

## Before merging

- [ ] Installed the current `dev` build from TestFlight and opened it
- [ ] `MARKETING_VERSION` is the version testers should see
- [ ] If `MARKETING_VERSION` was bumped this cycle, `ci_scripts/build_number_offset` was set in the same commit
- [ ] TestFlight "What to Test" notes written (the only place testers learn what changed)
- [ ] Merging once, deliberately: every push to `UAT-testflight` builds and goes to the UAT group

## What's in this promotion
<!-- list the PRs merged into dev since the last promotion -->

## What to Test notes
<!-- paste the TestFlight "What to Test" text -->
