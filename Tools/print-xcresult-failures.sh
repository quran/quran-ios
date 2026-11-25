#!/bin/bash
# Usage: print-xcresult-failures.sh <derived-data-dir>
#
# Prints the failures recorded in the test result bundles under <derived-data-dir>/Logs/Test.
# xcbeautify's GitHub renderer drops some failures, such as a test that exceeded its execution
# time allowance, so CI calls this after a failed test step to name the failing tests.
set -uo pipefail
shopt -s nullglob

derived_data=${1:?usage: $0 <derived-data-dir>}
bundles=("$derived_data"/Logs/Test/*.xcresult)
if ((${#bundles[@]} == 0)); then
    echo "No result bundle under $derived_data/Logs/Test"
    exit 0
fi

for bundle in "${bundles[@]}"; do
    echo "::group::Summary of $bundle"
    xcrun xcresulttool get test-results summary --path "$bundle" --compact
    echo
    echo "::endgroup::"
    xcrun xcresulttool get test-results summary --path "$bundle" --compact |
        jq -r '.testFailures[]? | "::error title=\(.targetName) \(.testIdentifierString)::\(.failureText | gsub("\n"; " "))"'
done
