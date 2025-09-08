#!/usr/bin/env bash
# set -euo pipefail

BASE_REPORT="loadtest-report.md"

if [[ ! -f "$BASE_REPORT" ]]; then
  echo "❌ $BASE_REPORT not found, please run load test first."
  exit 1
fi

# 获取当前分支和时间戳
BRANCH=$(git rev-parse --abbrev-ref HEAD)
# 去掉分支名里的特殊符号（比如 / 替换成 -）
SAFE_BRANCH=$(echo "$BRANCH" | tr '/:' '-')
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# 构造新的报告文件名
REPORT_FILE="loadtest-report.md"

# 在报告开头加入 branch 和时间戳
{
  echo "### Branch: \`$BRANCH\`"
  echo "### Timestamp: $TIMESTAMP"
  echo ""
  cat "$BASE_REPORT"
} > "$REPORT_FILE"

# 如果传了 PR 编号就用传的，否则自动找
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

echo "📤 Uploading $REPORT_FILE to PR #$PR_NUMBER ..."

gh pr comment "$PR_NUMBER" --body-file "$REPORT_FILE"

echo "✅ Report uploaded successfully as $REPORT_FILE"

