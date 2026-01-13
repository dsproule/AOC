#!/bin/bash
set -o pipefail

pass=0

while IFS= read -r aoc; do
    echo "=============================="
    echo "Running make ${aoc}_sv..."
    echo "=============================="

    # Run make and capture stdout+stderr
    output=$(make "${aoc}_sv" 2>/dev/null)
    status=$?

    # Print output so you still see logs
    echo "$output"

    # Check build/run failure
    if [ $status -ne 0 ]; then
        echo "FAIL: ${aoc}_sv"
        continue
    fi

    # Check correctness marker
    if echo "$output" | grep -q "Correct:[[:space:]]*1"; then
        echo "SUCCESS: ${aoc}_sv"
        echo ""
        ((pass++))
    else
        echo "FAIL (Correct flag missing): ${aoc}_sv"
    fi
done < rtl/accelerated.txt

echo "=============================="
echo "SUMMARY"
echo "Passed: $pass"
echo "Total:  $((pass + fail))"
echo "=============================="
