#!/bin/bash
# Usage: boot-test-simulator.sh <device-name>
#
# Starts booting the <device-name> simulator of the newest iOS runtime, the one the Makefile's
# `name=<device-name>,OS=latest` destination picks, and prints its UDID without waiting for the boot.
#
# CI boots it before building: a simulator's first boot keeps a small runner's CPUs busy for minutes,
# and a test runner launched meanwhile can hang before it connects to xcodebuild.
set -euo pipefail

name=${1:?usage: $0 <device-name>}
udid=$(xcrun simctl list devices available -j | jq -r --arg name "$name" '
    .devices
    | to_entries
    | map(select(.key | test("SimRuntime\\.iOS-")))
    | map({
        version: (.key | capture("iOS-(?<v>[0-9-]+)$").v | split("-") | map(tonumber)),
        devices: (.value | map(select(.name == $name)))
    })
    | map(select(.devices | length > 0))
    | sort_by(.version)
    | last
    | .devices[0].udid // empty')
if [[ -z $udid ]]; then
    echo "No available $name simulator" >&2
    exit 1
fi

# Booting an already booted simulator fails, which is fine here.
xcrun simctl boot "$udid" >&2 || true
echo "$udid"
