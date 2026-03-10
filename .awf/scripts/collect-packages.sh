#!/usr/bin/env bash
# Collect local recipe packages and output as JSON array.
# Skips vendors listed in SKIP_VENDORS.
# Output: JSON array of package names, e.g. ["symfony/routing","symfony/framework-bundle"]
#
# Requires: jq

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKIP_VENDORS=("mformono")

declare -A SEEN

for manifest in "$PROJECT_DIR"/*/*/manifest.json "$PROJECT_DIR"/*/*/*/manifest.json; do
    [[ -f "$manifest" ]] || continue

    rel="${manifest#"$PROJECT_DIR"/}"
    version_dir="$(dirname "$rel")"
    package="$(dirname "$version_dir")"
    vendor="${package%%/*}"

    # Skip vendors
    skip=false
    for sv in "${SKIP_VENDORS[@]}"; do
        [[ "$vendor" == "$sv" ]] && skip=true
    done
    $skip && continue

    SEEN["$package"]=1
done

# Sort and output as JSON array
if [[ ${#SEEN[@]} -eq 0 ]]; then
    echo "[]"
else
    printf '%s\n' "${!SEEN[@]}" | sort | jq -R . | jq -s .
fi
