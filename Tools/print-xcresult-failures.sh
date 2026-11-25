#!/bin/bash
# Usage: print-xcresult-failures.sh <derived-data-dir>
#
# Prints the failures recorded in the newest test result bundle under <derived-data-dir>/Logs/Test.
# xcbeautify's GitHub renderer drops some failures, such as a test that exceeded its execution
# time allowance, so CI calls this after a failed test step to name the failing tests.
set -uo pipefail

derived_data=${1:?usage: $0 <derived-data-dir>}
# Earlier runs leave their bundles here too, so only the newest one is this run's.
bundle=$(ls -dt "$derived_data"/Logs/Test/*.xcresult 2>/dev/null | head -n 1)
if [[ -z $bundle ]]; then
    echo "No result bundle under $derived_data/Logs/Test"
    exit 0
fi

summary=$(xcrun xcresulttool get test-results summary --path "$bundle" --compact)
echo "::group::Summary of $bundle"
echo "$summary"
echo "::endgroup::"
jq -r '.testFailures[]? | "::error title=\(.targetName) \(.testIdentifierString)::\(.testIdentifierString): \(.failureText | gsub("\n"; " "))"' <<<"$summary"
