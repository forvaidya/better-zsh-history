#!/bin/bash
################################################################################
# Docker E2E Test Runner
#
# Runs the zsh history hook e2e tests in an Ubuntu Docker container
# and outputs results to stdout
#
# Usage:
#   bash docker-test.sh
#
################################################################################

set -e

echo "════════════════════════════════════════════════════════════════"
echo "Zsh History Hook - Docker E2E Test"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Generate unique container name
CONTAINER="zsh-history-test-$(date +%s)"

echo "📦 Creating container: $CONTAINER"
docker run -d --name "$CONTAINER" ubuntu sleep infinity > /dev/null

echo "📚 Installing zsh..."
docker exec "$CONTAINER" bash -c "apt-get update -qq && apt-get install -y zsh >/dev/null 2>&1"

echo "📋 Copying test files..."
docker cp "$(dirname "$0")/zsh-history-hook.sh" "$CONTAINER":/
docker cp "$(dirname "$0")/e2e-test.sh" "$CONTAINER":/

echo "🔧 Installing hook..."
docker exec "$CONTAINER" zsh /zsh-history-hook.sh install >/dev/null 2>&1

echo "▶️  Running e2e test..."
echo ""
echo "────────────────────────────────────────────────────────────────"
docker exec "$CONTAINER" zsh /e2e-test.sh
echo "────────────────────────────────────────────────────────────────"
echo ""

echo "🧹 Cleaning up..."
docker rm -f "$CONTAINER" > /dev/null

echo "✅ Test completed successfully!"
echo ""
