#!/usr/bin/env bash
set -euo pipefail

REPORT="../loadtest-report.md"

if [[ ! -f "$REPORT" ]]; then
  echo "❌ $REPORT not found, please run load test first."
  exit 1
fi

# 解析当前分支的 PR 编号（假设你在 feature 分支）
PR_NUMBER=$(gh pr list --state open --json number,headRefName | jq -r \
  --arg BRANCH "$(git rev-parse --abbrev-ref HEAD)" \
  '.[] | select(.headRefName==$BRANCH) | .number')

if [[ -z "$PR_NUMBER" ]]; then
  echo "❌ No open PR found for branch $(git rev-parse --abbrev-ref HEAD)"
  exit 1
fi

echo "📤 Uploading $REPORT to PR #$PR_NUMBER ..."

gh pr comment "$PR_NUMBER" --body-file "$REPORT"

echo "✅ Report uploaded successfully!"