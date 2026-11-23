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
| [TestFlight PR build](testflight-pr.yml) | Requests an Xcode Cloud PR build for TestFlight. | PR opened/reopened or its description edited, or a new PR comment, with `/testflight` on its own line (case-insensitive). | Open, same-repository PRs targeting any branch; forks are excluded. Comment requests require author association `OWNER`, `MEMBER`, or `COLLABORATOR`. |
| [TestFlight tooling tests](testflight-tooling-tests.yml) | Checks hook syntax and runs the two TestFlight Python regression suites, including the archive-hook fixture. | PR opened, synchronized, or reopened, with changes to the notes generator, the two suites, the pre/post-build hooks, build number offset, `.github/scripts/start_xcode_cloud_build.py`, `testflight-pr.yml`, or this test workflow. | PRs targeting any branch, including forks. One short macOS job; no secrets, package installs, app build or distribution. |

The TestFlight PR build workflow requires the App Store Connect secrets
`APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, and
`APP_STORE_CONNECT_PRIVATE_KEY`. It selects
the Xcode Cloud workflow named by `XCODE_CLOUD_PR_WORKFLOW` (repository variable),
defaulting to `PR TestFlight`, for bundle ID `personal.studyBud`.

The tooling tests use macOS for BSD `sed`, PlistBuddy and zsh, which the
archive-hook fixture requires. The single job is path-filtered and cancels
superseded PR runs to limit macOS runner cost. Python 3.12 is selected explicitly;
the suites use local Git fixtures and mock App Store Connect calls, so they need
no PyJWT or cryptography install. Both suites are named explicitly so unrelated
tooling tests do not run in this job. Other Actions workflows run on Ubuntu.

No remote setup is required for the tooling tests. They do not verify App Store
Connect authentication or distribution. App builds and distribution run in
Xcode Cloud; see [Pipeline](../../pipeline.md) for workflow ownership, promotion
and default-branch `/testflight` comment activation.
