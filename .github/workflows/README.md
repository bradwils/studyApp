# GitHub Actions workflows

Branch names below describe trigger scope; PR branch filters match the **target**
branch. Workflows must also be present on the ref GitHub uses for the event.
Issue/comment events use the default branch (`master`), so those entry points
need the workflow merged there. PR, review and inline review-comment events use
the PR's own merge ref, so they need the workflow on the PR's target branch too.

| Workflow | What it does | When it triggers | Where it operates |
| --- | --- | --- | --- |
| [Claude Code](claude.yml) | Runs Claude on a request containing `@claude`, or on an issue labeled `claude`. | Issue/PR comments and inline review comments (created or edited), PR reviews (submitted or edited), PRs (opened or edited, title or body), and opened issues; the relevant text must contain `@claude`. Labeling an issue `claude` needs no mention. | Repository issues and PRs, with no branch filter. Only `OWNER`, `MEMBER` or `COLLABORATOR` authors start a run; bots never do. One run at a time per issue/PR. Requires `CLAUDE_CODE_OAUTH_TOKEN`; forks do not receive repository secrets. Not triggers: issue edits or assignment (the action ignores them) and PR pushes (ask with a comment instead). |
| [PR title](pr-title.yml) | Checks that the PR title follows Conventional Commits, e.g. `fix(ui): correct layout`. | PR opened, edited, synchronized (new commits), or reopened. | PRs targeting any branch. |
| [SwiftLint](swiftlint.yml) | Lints Swift with SwiftLint 0.65.1; errors fail the job, warnings are annotated. | PR opened, synchronized, or reopened; pushes to `dev`. Both require changes to `**/*.swift`, `.swiftlint.yml`, or this workflow file. | PRs targeting `dev`, `UAT-testflight`, or `master`; direct pushes to `dev` only. |
| [TestFlight PR build](testflight-pr.yml) | Requests an Xcode Cloud build of the PR's head branch for TestFlight. | PR opened/reopened or its description edited, or a new PR comment, with `/testflight` on its own line (case-insensitive). | Open, same-repository PRs targeting any branch; forks are excluded. Comment requests require author association `OWNER`, `MEMBER`, or `COLLABORATOR`. |

TestFlight requires the App Store Connect secrets `APP_STORE_CONNECT_KEY_ID`,
`APP_STORE_CONNECT_ISSUER_ID`, and `APP_STORE_CONNECT_PRIVATE_KEY`. It selects
the Xcode Cloud workflow named by `XCODE_CLOUD_PR_WORKFLOW` (repository variable),
defaulting to `PR TestFlight`, for bundle ID `personal.studyBud`.

All four Actions workflows run on Ubuntu. App builds and TestFlight distribution
run in Xcode Cloud; its start conditions and distribution settings are managed
there. See [Pipeline](../../pipeline.md) for the branch promotion and release flow.

## Workflow ownership

Keep all four workflows on `dev`, `UAT-testflight` and `master`. Each has an
execution path that depends on the PR merge ref or a push ref. A workflow with
both PR and default-branch events still needs its dev copy:

| Event | Workflow/code ref | Why dev needs it |
| --- | --- | --- |
| `pull_request` | PR merge ref (`refs/pull/NUMBER/merge`) | PR titles, Claude mentions in title/body, TestFlight requests in descriptions, and lint where its target/path filters match. Keep workflows on stacked PR targets too. |
| `pull_request_review`, `pull_request_review_comment` | PR merge ref | Claude review and inline-comment mentions. |
| `push` | Pushed ref | SwiftLint on dev, subject to path filters. |
| `issues`, `issue_comment` | Default branch (`master`) | No dev copy needed for these events alone. Claude issue/PR comments and labels, and TestFlight PR comments, use master's workflow and checkout, even for PRs targeting dev. |

Change shared workflow behavior through a `ci/*` PR into master and merge its
history back into UAT and dev. Do not delete mixed-event workflows from dev just
because their comment entry points use master, and do not switch to
`pull_request_target` merely to centralize them: that changes the trust context.
Xcode Cloud separately reads `ci_scripts/` from the ref it builds.

The master-only `promotion-source.yml` and live `source-branch` requirement were
retired together (#164, #223). Promotion sources remain a manual review policy;
PR and merge-commit protection remain active. Removing the obsolete workflow
from every lane prevents a later promotion or backmerge from restoring it.
For future master-only automation, document event/ref ownership and how
promotions/backmerges preserve it before introducing branch-specific files.
