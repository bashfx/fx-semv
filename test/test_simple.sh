#!/usr/bin/env bash
# Simple semv testing

echo "=== SEMV Simple Test ==="

# Add a version comment to this file for testing  
# semv-version: 1.0.0

echo "1. Testing basic commands:"
echo "  - help:"
./semv.sh help >/dev/null 2>&1 && echo "    ✅ help works" || echo "    ❌ help failed"

echo "  - next:"
./semv.sh next >/dev/null 2>&1 && echo "    ✅ next works" || echo "    ❌ next failed"

echo "  - get bash ./test_simple.sh:"
result=$(./semv.sh get bash ./test_simple.sh 2>&1)
if [[ "$result" =~ "1.0.0" ]]; then
    echo "    ✅ get bash works: $result"
else
    echo "    ❌ get bash failed: $result"
fi

echo "  - get all:"
./semv.sh get all >/dev/null 2>&1 && echo "    ✅ get all works" || echo "    ❌ get all failed"

echo "=== End Test ==="