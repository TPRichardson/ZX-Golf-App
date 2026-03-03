#!/usr/bin/env bash
# Run the test suite in 4 sequential chunks.
# Integration tests tagged 'integration' are skipped by default (see dart_test.yaml).
# To run them explicitly: flutter test -t integration
#
# Usage:
#   bash tool/run_tests.sh

set -euo pipefail
cd "$(dirname "$0")/.."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CHUNK1="test/core/scoring"
CHUNK2="test/core/sync test/core/services test/core/widgets test/core/startup_checks_test.dart"
CHUNK3="test/data"
CHUNK4="test/features test/integration"

echo -e "${YELLOW}Running 4 test chunks sequentially...${NC}"
failed=0

echo -e "\n${YELLOW}[1/4] core/scoring${NC}"
flutter test $CHUNK1 || failed=1

echo -e "\n${YELLOW}[2/4] core/sync+services+widgets${NC}"
flutter test $CHUNK2 || failed=1

echo -e "\n${YELLOW}[3/4] data${NC}"
flutter test $CHUNK3 || failed=1

echo -e "\n${YELLOW}[4/4] features+integration${NC}"
flutter test $CHUNK4 || failed=1

if [[ $failed -ne 0 ]]; then
  echo -e "\n${RED}Some chunks failed.${NC}"
  exit 1
fi
echo -e "\n${GREEN}All 4 chunks passed.${NC}"
