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
| [Promotion source](promotion-source.yml) | Rejects source branch names other than `UAT-testflight`, `hotfix/*`, or `ci/*`. | PR opened, synchronized, reopened, edited, or marked ready for review. | PRs targeting `master` only; the `source-branch` check is required by the master ruleset. It checks the name, not where the branch was cut. |
| [SwiftLint](swiftlint.yml) | Lints Swift with SwiftLint 0.65.1; errors fail the job, warnings are annotated. | PR opened, synchronized, or reopened; pushes to `dev`. Both require changes to `**/*.swift`, `.swiftlint.yml`, or this workflow file. | PRs targeting `dev`, `UAT-testflight`, or `master`; direct pushes to `dev` only. |
| [TestFlight PR build](testflight-pr.yml) | Requests an on-demand Xcode Cloud build for TestFlight. | PR opened/reopened or its description edited, or a new PR comment, with `/testflight` on its own line (case-insensitive). | Open, same-repository PRs targeting any branch; forks are excluded. Comment requests require author association `OWNER`, `MEMBER`, or `COLLABORATOR`. |

TestFlight requires the App Store Connect secrets `APP_STORE_CONNECT_KEY_ID`,
`APP_STORE_CONNECT_ISSUER_ID`, and `APP_STORE_CONNECT_PRIVATE_KEY`. It selects
the Xcode Cloud workflow named by `XCODE_CLOUD_PR_WORKFLOW` (repository variable),
defaulting to `PR TestFlight`, for bundle ID `personal.studyBud`. See
[PR builds](../../pipeline.md#pr-builds) for event behavior and manual start
requirements.

All five Actions workflows run on Ubuntu. App builds and TestFlight distribution
run in Xcode Cloud; its start conditions and distribution settings are managed
there. See [Pipeline](../../pipeline.md) for the branch promotion and release flow.
