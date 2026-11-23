# Proposed dev merge gate

This is an optional administrator rollout, **not an enabled gate**. Merging
this document or its [disabled ruleset candidate](../.github/rulesets/dev-verification.json)
does not change GitHub settings. No app build, Apple configuration or release
is involved. Shared CI documentation follows the `ci/*` maintenance route in
[pipeline.md](../pipeline.md#ci-maintenance); the proposed live rule targets
only `dev`.

Read-only inspection on 2026-11-23 found that `dev`'s effective ruleset rules
were `deletion` and `non_fast_forward`; its GraphQL `branchProtectionRule` was
null. Neither made a PR or lint mandatory. A green Actions run alone does not
make a check required. The existing long-lived branch ruleset must remain.

## Reuse the existing check

Require the job context **`swiftlint`**, supplied by **GitHub Actions**, app ID
**15368**. `SwiftLint` is the workflow's display name, not the required context.
The [existing workflow](../.github/workflows/swiftlint.yml) owns the pinned
SwiftLint executable and lint command; this proposal adds no second lint job,
dispatcher or aggregate status.

The candidate requires PRs with zero approvals, an up-to-date branch, and that
one status check. There are no bypass actors. Activating it removes the
current direct-push exception for small `dev` fixes. Merge, squash and rebase
remain available on `dev`; promotion branch rules do not change. No merge queue
is configured: enabling one later also needs `merge_group` trigger coverage.

## Workflow prerequisite

Before activation, every PR targeting `dev` must run the unconditional
`swiftlint` job, including documentation-only changes. Remove the top-level
**PR** path and target-branch filters so stacked and disposable-target PRs
can exercise the same workflow. Do not mark a filtered/skipped job successful.
Do not add job/step `if`, `continue-on-error` or a success fallback to the lint
command. Keep the existing direct-push path filter on `dev`: post-push feedback
cannot protect a merge.

[#233](https://github.com/bradwils/studyApp/pull/233) provides the always-run PR
trigger, including stacked PR targets, and runs custom-rule fixtures before
lint in the same `swiftlint` job. Selecting both options must preserve that
fixture step: a fixture failure must fail the required job. If #233 is not
selected, first land the equivalent always-run PR trigger in the existing
workflow. **Selecting this proposal alone is not sufficient to activate it.**
With #233 selected, fixture-only changes must also run both steps; do not
restore its old PR path filter. Dev push filters can remain file-limited.

The previous #233 head `fd79d2b` had a successful
[hosted run](https://github.com/bradwils/studyApp/actions/runs/45115659493)
whose sole `swiftlint` job ran fixtures and lint. That proves the check name
and composition at that head, not the later always-run trigger, final merge
result, or branch enforcement.

## Prove the rollout

First verify these cases on disposable PRs against the intended `dev` merge
result, without merging the failing examples. Use a disposable protected
branch/ruleset for denial tests before changing `dev`; match its workflow and
rule settings. Record the head/merge SHA, job conclusion, step logs and merge
box result. Recheck the final `dev` rule after activation.

| Case | Expected Actions evidence | Expected result when the rule is active |
| --- | --- | --- |
| Documentation-only PR | `swiftlint` runs checkout and lint; fixtures also run if #233 is selected. | Successful current check satisfies lint requirement. |
| Valid Swift or `.swiftlint.yml` change | Same job and steps succeed. | Lint requirement satisfied. |
| Add `studyApp/Models/GateProbe.swift` containing `import SwiftUI` | The existing error-level model import rule fails lint. Warnings intentionally pass. | Merge blocked; close the probe without merging it. |
| Invalid/missing lint config | Existing lint command fails; job fails. | Merge blocked. |
| Fixture-only change, with #233 | Passing fixtures are followed by lint; a deliberate mismatch fails the job at the fixture step. | Broken fixture blocks merge. |
| Workflow never starts: PR path filter, commit skip directive, Actions disabled or fork awaiting approval | Required `swiftlint` is absent/pending, not successful. | Merge blocked while required result is missing. |
| Failed/cancelled run or a new push after a previous success | Inspect the current SHA; old success cannot cover the new commit. | Merge blocked until the current check succeeds. |
| Base branch advances after a successful run | Branch is behind; update it and rerun the merge result. | Strict freshness blocks merge until up to date. |
| Direct push without a PR | No workflow run can retroactively satisfy the PR rule. | Push rejected, including the administrator unless explicitly bypassed. |

Do not infer enforcement from a green badge or a workflow's `active` state.
The PR merge box must show `swiftlint` as **Required**. Verify the effective
rules read-only with `gh api repos/bradwils/studyApp/rules/branches/dev`, and
inspect the new ruleset's enforcement, conditions, app source and bypass list.

### False greens and scope

GitHub accepts `skipped` and `neutral` check conclusions as satisfying required
checks. A skipped job is therefore different from a workflow that never ran.
The current unconditional job must actually execute its fixture/lint steps;
a same-name job with `if: false`, a swallowed failure or a removed lint step
would defeat this proposal. Another workflow using the same job name and app
can also supply a misleading status: app binding restricts the publisher, not
the workflow file. Keep job names unique and review workflow/config changes.
This is enforcement of the reviewed workflow, not protection against someone
authorized to change that workflow or the live rule.

It gates lint errors and, when selected, custom-rule fixtures. It does not
prove compilation, unit-test coverage, SwiftData behavior or Xcode Cloud
success. Those remain separate verification work in #186. Fork approval,
runner/image download and Actions availability can block this check; resolve
the cause or deliberately roll back the rule rather than manufacture success.

## Exact activation and rollback

An administrator can perform the following after the prerequisite and proof
matrix are complete. These are rollout instructions; none were executed for
this proposal.

1. In repository **Settings → Rules → Rulesets**, create/import a branch
   ruleset from `.github/rulesets/dev-verification.json`. Leave enforcement
   **Disabled**. Alternatively, create the disabled candidate with:

   ```sh
   gh api --method POST repos/bradwils/studyApp/rulesets \
     --input .github/rulesets/dev-verification.json \
     --jq '{id, name, enforcement, conditions, rules, bypass_actors}'
   ```

2. Record the returned ruleset ID. Confirm its only include is
   `refs/heads/dev`, no exclusions or bypass actors, PRs required with zero
   approvals, and status `swiftlint` from GitHub Actions (`15368`). Confirm
   strict up-to-date checking and no exemption on branch creation. Check all
   applicable rulesets and classic protection; overlapping rules accumulate.
3. Change only this new rule's enforcement to **Active** and save. API
   equivalent, replacing `RULESET_ID` with the recorded numeric ID:

   ```sh
   gh api --method PUT repos/bradwils/studyApp/rulesets/RULESET_ID \
     -f enforcement=active
   ```

4. Read back the ruleset and effective `dev` rules. Confirm a fresh
   documentation-only PR shows the actual successful `swiftlint` run as
   **Required**, then confirm a fresh, intentionally failing lint PR into
   `dev` is blocked. Close the failing probe without merging it. Use the
   disposable branch for direct-push denial tests. Record the confirmed live
   change in `pipeline.md` only after these checks pass.

To roll back, set **only this new ruleset** to **Disabled** and save, or use
the same PUT command with `-f enforcement=disabled`. Read it back and confirm
its PR/status requirements no longer apply. Leave the existing long-lived
branch deletion/force-push protection and workflow intact. Rollback restores
the prior allowance for direct pushes to `dev`. Disable the requirement
**before** renaming/removing the `swiftlint` job or restoring PR path filters,
so open PRs are not stranded waiting for a check that cannot report.
