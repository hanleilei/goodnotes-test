#!/usr/bin/env bash
set -euo pipefail

# 使用绝对路径或相对于仓库根目录的路径
REPORT_FILE="${GITHUB_WORKSPACE:-.}/loadtest-report.md"

if [[ ! -f "$REPORT_FILE" ]]; then
  echo "❌ $REPORT_FILE not found, please run load test first."
  exit 1
fi

# 获取当前分支（在 GitHub Actions 中更可靠的方式）
BRANCH=${GITHUB_HEAD_REF:-$GITHUB_REF_NAME}
SAFE_BRANCH=$(echo "$BRANCH" | tr '/:' '-')
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# 生成带元数据的临时文件
TEMP_FILE=$(mktemp)
{
  echo "### Branch: \`$BRANCH\`"
  echo "### Timestamp: $TIMESTAMP"
  echo ""
  cat "$REPORT_FILE"
} > "$TEMP_FILE"

# PR 编号优先使用参数，其次自动检测
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
rm "$TEMP_FILE"  # 清理临时文件

echo "✅ Report uploaded successfully"