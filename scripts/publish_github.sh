#!/usr/bin/env bash
# OCIN v2.2: publish an existing local git repository as a NEW private GitHub repo.
# Requires GitHub CLI (gh) signed into the intended account. No paid services.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OWNER="${OCIN_GITHUB_OWNER:-dahlah77}"
REPO="${OCIN_GITHUB_REPO:-ocin}"
FULL="$OWNER/$REPO"

fail() { echo "OCIN PUBLISH ABORTED: $*" >&2; exit 1; }
command -v git >/dev/null || fail "git not available"
command -v gh >/dev/null || fail "GitHub CLI (gh) not available"
cd "$ROOT"
gh auth status --hostname github.com >/dev/null || fail "GitHub CLI is not authenticated. Run gh auth login first."
ACTUAL_OWNER="$(gh api user --jq '.login')"
[[ "$ACTUAL_OWNER" == "$OWNER" ]] || fail "Authenticated as '$ACTUAL_OWNER', expected '$OWNER'"
[[ -d .git ]] || fail "Expected initialized local Git repository; see README."
[[ "$(git branch --show-current)" == "main" ]] || fail "Expected main branch"
[[ -z "$(git status --porcelain)" ]] || fail "Uncommitted changes present; commit them before publishing"

if gh repo view "$FULL" --json isPrivate --jq '.isPrivate' >/dev/null 2>&1; then
  PRIVATE="$(gh repo view "$FULL" --json isPrivate --jq '.isPrivate')"
  [[ "$PRIVATE" == 'true' ]] || fail "Existing $FULL is not private. No upload performed."
  REMOTE="$(gh api "repos/$FULL" --jq '.html_url')"
  if [[ -n "$(git ls-remote --heads "https://github.com/$FULL.git")" ]]; then
    fail "$FULL exists and already has commits. Refusing to overwrite or mix histories."
  fi
  echo "Found existing EMPTY PRIVATE repository: $REMOTE"
else
  echo "Creating new PRIVATE repository $FULL. This command does not purchase any plan."
  gh repo create "$FULL" --private \
    --description 'OCIN personal cross-platform connectivity: Flutter/Rust PoC' || fail "Repository create failed"
  PRIVATE="$(gh repo view "$FULL" --json isPrivate --jq '.isPrivate')"
  [[ "$PRIVATE" == 'true' ]] || fail "Repository private check failed; refusing to push"
fi

if git remote get-url origin >/dev/null 2>&1; then
  ORIGIN="$(git remote get-url origin)"
  [[ "$ORIGIN" == "https://github.com/$FULL.git" || "$ORIGIN" == "git@github.com:$FULL.git" ]] || fail "origin points elsewhere: $ORIGIN"
else
  git remote add origin "https://github.com/$FULL.git"
fi

echo "Pushing OCIN main to private $FULL (may trigger GitHub Actions within account's free allowance)."
git push -u origin main
printf '\nOCIN repository published: https://github.com/%s\n' "$FULL"
printf 'Check free-budget limits in GitHub Settings > Billing. Workflow YAML cannot enforce a $0 cap.\n'
