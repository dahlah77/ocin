# OCIN — GitHub private publication & CI

## Intended target

- Account: `dahlah77`
- Repository: `ocin`
- Visibility: **private**
- Default branch: `main`
- Workflow: `.github/workflows/ci.yml`
- Paid-service dependency: **none intended**

## Automated publishing (when a GitHub-capable host/connector is available)

With GitHub CLI authenticated as `dahlah77` and a locally initialized Git repository, run:

```bash
bash scripts/publish_github.sh
```

The script verifies the signed-in account, creates `dahlah77/ocin` **private** when absent, refuses non-private or nonempty conflicting destinations, and pushes `main`. It does not require paid GitHub subscriptions. If it cannot create a repository, it fails without writing source files to an unrelated project.

## CI verification

CI triggers on push to `main` from `.github/workflows/ci.yml` and executes Python tests, FRB code generation, Rust tests, and Flutter analyze/widget tests on Linux. CI does *not* establish success on macOS, Windows, iOS, Android native, shader GPU or hardware. Actual GitHub logs must be collected before marking PASS.

**No automatic $0 guarantee:** GitHub account/org billing restrictions must be verified in GitHub settings; source code cannot set a billing-spend threshold. Using the included allocation is not the same as a zero compute usage charge. Private repositories consume included runner allocation.

## Current access limitation

The linked GitHub connector can inspect and write files in existing repositories but does not currently expose `create repository`. Creation must occur through a GitHub authenticated host or UI; this is not resolved by repeatedly calling GitHub file-write endpoints. Browser automation was unavailable without a paid balance, contrary to OCIN's Rp0 policy. The source package remains ready for a zero-cost publish command when authenticated GitHub CLI access is available.
