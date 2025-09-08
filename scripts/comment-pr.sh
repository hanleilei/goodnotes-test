#!/usr/bin/env bash
set -euo pipefail

# use GitHub CLI to comment the load test report on the PR
# requires GITHUB_TOKEN with repo scope to be set in the environment
# requires jq to be installed
REPORT_FILE="${GITHUB_WORKSPACE:-.}/loadtest-report.md"

if [[ ! -f "$REPORT_FILE" ]]; then
  echo "❌ $REPORT_FILE not found, please run load test first."
  exit 1
fi

# determine the branch name and create a safe version for filenames
BRANCH=${GITHUB_HEAD_REF:-$GITHUB_REF_NAME}
SAFE_BRANCH=$(echo "$BRANCH" | tr '/:' '-')
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# generate a temporary file with branch and timestamp info
TEMP_FILE=$(mktemp)
{
  echo "### Branch: \`$BRANCH\`"
  echo "### Timestamp: $TIMESTAMP"
  echo ""
  cat "$REPORT_FILE"
} > "$TEMP_FILE"

# PR number can be passed as an argument, otherwise try to find it based on the branch name
PR_NUMBER=${1:-}
if [[ -z "$PR_NUMBER" ]]; then
  PR_NUMBER=$(gh pr list --state open --json number,headRefName | jq -r \
    --arg BRANCH "$BRANCH" \
    '.[] | select(.headRefName==$BRANCH) | .number')
fi

if [[ -z "$PR_NUMBER" ]]; then
  echo "❌ No open PR found for branch $BRANCH, and no PR number passed as argument"
  exit 1
fi

echo "📤 Uploading report to PR #$PR_NUMBER ..."
gh pr comment "$PR_NUMBER" --body-file "$TEMP_FILE"
gh pr comment "$PR_NUMBER" --body-file "monitoring-report.md" || true  # ignore errors
rm "$TEMP_FILE"  # cleanup temporary file

echo "✅ Report uploaded successfully"