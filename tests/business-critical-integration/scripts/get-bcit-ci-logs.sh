#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<EOF
Usage: $(basename "$0") <test-type> [-f <output-file>] [-b <branch>] [-n <run-number>]

Get GitHub Actions CI logs for BCIT test runs.

Arguments:
  test-type     One of: in-app, inapp, deep-link, deeplink, push, embedded

Options:
  -f FILE       Save logs to FILE (default: stdout)
  -b BRANCH     Branch to check (default: current branch)
  -n NUMBER     Specific run number (default: latest)
  -h            Show this help

Examples:
  $(basename "$0") in-app
  $(basename "$0") in-app -f in-app-bcit-logs.txt
  $(basename "$0") deeplink -b master -f deeplink-logs.txt
  $(basename "$0") push -n 12345678
EOF
    exit 1
}

if [[ $# -lt 1 ]]; then
    usage
fi

TEST_TYPE="$1"
shift

OUTPUT_FILE=""
BRANCH=""
RUN_NUMBER=""

while getopts "f:b:n:h" opt; do
    case $opt in
        f) OUTPUT_FILE="$OPTARG" ;;
        b) BRANCH="$OPTARG" ;;
        n) RUN_NUMBER="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

case "$TEST_TYPE" in
    in-app|inapp)
        WORKFLOW_NAME="BCIT InApp Messaging Integration Test"
        ;;
    deep-link|deeplink)
        WORKFLOW_NAME="BCIT Deep Linking Integration Test"
        ;;
    push)
        WORKFLOW_NAME="BCIT Push Notification Integration Test"
        ;;
    embedded)
        WORKFLOW_NAME="BCIT Embedded Messages Integration Test"
        ;;
    *)
        echo "❌ Unknown test type: $TEST_TYPE"
        echo "Valid types: in-app, inapp, deep-link, deeplink, push, embedded"
        exit 1
        ;;
esac

if [[ -z "$BRANCH" ]]; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
fi

echo "🔍 Looking for '$WORKFLOW_NAME' runs on branch: $BRANCH" >&2

if [[ -n "$RUN_NUMBER" ]]; then
    RUN_ID="$RUN_NUMBER"
    echo "📋 Using specified run: $RUN_ID" >&2
else
    RUN_ID=$(gh run list \
        --workflow "$WORKFLOW_NAME" \
        --branch "$BRANCH" \
        --limit 1 \
        --json databaseId \
        --jq '.[0].databaseId' 2>/dev/null)
    
    if [[ -z "$RUN_ID" || "$RUN_ID" == "null" ]]; then
        echo "❌ No runs found for '$WORKFLOW_NAME' on branch '$BRANCH'" >&2
        echo "💡 Try specifying a different branch with -b or check workflow name" >&2
        exit 1
    fi
    echo "📋 Latest run ID: $RUN_ID" >&2
fi

RUN_INFO=$(gh run view "$RUN_ID" --json status,conclusion,createdAt,headBranch,event 2>/dev/null)
STATUS=$(echo "$RUN_INFO" | jq -r '.status')
CONCLUSION=$(echo "$RUN_INFO" | jq -r '.conclusion')
CREATED=$(echo "$RUN_INFO" | jq -r '.createdAt')
EVENT=$(echo "$RUN_INFO" | jq -r '.event')

echo "📊 Run status: $STATUS ($CONCLUSION)" >&2
echo "📅 Created: $CREATED" >&2
echo "🎯 Trigger: $EVENT" >&2
echo "" >&2

if [[ -n "$OUTPUT_FILE" ]]; then
    echo "📥 Downloading logs to: $OUTPUT_FILE" >&2
    {
        echo "=== BCIT CI Logs ==="
        echo "Workflow: $WORKFLOW_NAME"
        echo "Run ID: $RUN_ID"
        echo "Branch: $BRANCH"
        echo "Status: $STATUS ($CONCLUSION)"
        echo "Created: $CREATED"
        echo "Event: $EVENT"
        echo "===================="
        echo ""
        gh run view "$RUN_ID" --log 2>&1
    } > "$OUTPUT_FILE"
    echo "✅ Logs saved to: $OUTPUT_FILE" >&2
else
    gh run view "$RUN_ID" --log
fi
