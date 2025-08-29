#!/usr/bin/env bash
# Quick SEMV functionality test

echo "=== SEMV Testing ==="
echo "Testing basic functionality..."

echo "1. Help command:"
bash semv.sh help 2>&1 | head -5

echo -e "\n2. Next version:"
bash semv.sh next 2>&1 | head -1

echo -e "\n3. Current tag:"
bash semv.sh tag 2>&1 | head -1

echo -e "\n4. Testing get all (with timeout):"
timeout 3 bash semv.sh get all 2>&1 | head -10

echo -e "\n5. Testing sync (with timeout):"
timeout 3 bash semv.sh sync 2>&1 | head -10

echo -e "\n6. Info command (with timeout):"
timeout 3 bash semv.sh info 2>&1 | head -15

echo -e "\n=== Test Complete ==="