# GitHub Actions workflows

Branch names below describe trigger scope; PR branch filters match the **target**
branch. Workflows must also be present on the ref GitHub uses for the event.
Issue/comment events use the default branch (`master`), so those entry points
need the workflow merged there.

| Workflow | What it does | When it triggers | Where it operates |
| --- | --- | --- | --- |
| [Claude Code](claude.yml) | Runs Claude on a request containing `@claude`. | New issue/PR comments, new inline review comments, submitted PR reviews, opened PRs, and opened/assigned issues; the relevant text must contain `@claude`. | Repository issues and PRs, with no branch filter. Requires `CLAUDE_CODE_OAUTH_TOKEN`; forks do not receive repository secrets. |
| [PR title](pr-title.yml) | Checks that the PR title follows Conventional Commits, e.g. `fix(ui): correct layout`. | PR opened, edited, synchronized (new commits), or reopened. | PRs targeting `dev` only. |
| [Promotion source](promotion-source.yml) | Rejects source branch names other than `UAT-testflight`, `hotfix/*`, or `ci/*`. | PR opened, synchronized, reopened, edited, or marked ready for review. | PRs targeting `master` only; the `source-branch` check is required by the master ruleset. It checks the name, not where the branch was cut. |
| [SwiftLint](swiftlint.yml) | Lints Swift with SwiftLint 0.65.1; errors fail the job, warnings are annotated. | PR opened, synchronized, or reopened; pushes to `dev`. Both require changes to `**/*.swift`, `.swiftlint.yml`, or this workflow file. | PRs targeting `dev`, `UAT-testflight`, or `master`; direct pushes to `dev` only. |
| [TestFlight PR build](testflight-pr.yml) | Requests an Xcode Cloud build of the PR's head branch for TestFlight. | PR opened/reopened or its description edited, or a new PR comment, with `/testflight` on its own line (case-insensitive). | Open, same-repository PRs targeting any branch; forks are excluded. Comment requests require author association `OWNER`, `MEMBER`, or `COLLABORATOR`. |

TestFlight requires the App Store Connect secrets `APP_STORE_CONNECT_KEY_ID`,
`APP_STORE_CONNECT_ISSUER_ID`, and `APP_STORE_CONNECT_PRIVATE_KEY`. It selects
the Xcode Cloud workflow named by `XCODE_CLOUD_PR_WORKFLOW` (repository variable),
defaulting to `PR TestFlight`, for bundle ID `personal.studyBud`.

All five Actions workflows run on Ubuntu. App builds and TestFlight distribution
run in Xcode Cloud; its start conditions and distribution settings are managed
there. See [Pipeline](../../pipeline.md) for the branch promotion and release flow.
