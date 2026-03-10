#!/usr/bin/env bash
# Compare local recipes against schranz-php-recipes/symfony-recipes-php upstream
# Usage: ./compare-upstream.sh [--diff] [--package vendor/package]
#
# Options:
#   --diff      Show file-level diffs for matching versions
#   --package   Compare a single package (e.g. symfony/routing)
#
# Requires: gh (GitHub CLI), jq

set -euo pipefail

UPSTREAM_REPO="schranz-php-recipes/symfony-recipes-php"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKIP_VENDORS=("mformono")

SHOW_DIFF=false
FILTER_PACKAGE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --diff) SHOW_DIFF=true; shift ;;
        --package) FILTER_PACKAGE="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

header() { echo -e "\n${BOLD}${CYAN}=== $1 ===${NC}"; }
info()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn()   { echo -e "  ${YELLOW}▶${NC} $1"; }
alert()  { echo -e "  ${RED}✗${NC} $1"; }

# Collect local recipes: vendor/package/version
declare -A LOCAL_PACKAGES # key=vendor/package, value=space-separated versions

while IFS= read -r manifest; do
    rel="${manifest#"$PROJECT_DIR"/}"
    # rel = vendor/package/version/manifest.json
    version_dir="$(dirname "$rel")"
    version="$(basename "$version_dir")"
    package="$(dirname "$version_dir")"

    # Skip filtered vendors
    vendor="$(echo "$package" | cut -d/ -f1)"
    skip=false
    for sv in "${SKIP_VENDORS[@]}"; do
        [[ "$vendor" == "$sv" ]] && skip=true
    done
    $skip && continue

    # Apply package filter
    [[ -n "$FILTER_PACKAGE" && "$package" != "$FILTER_PACKAGE" ]] && continue

    LOCAL_PACKAGES["$package"]="${LOCAL_PACKAGES[$package]:-} $version"
done < <(find "$PROJECT_DIR" -name "manifest.json" -not -path "*/.git/*" -not -path "*/.awf/*" | sort)

if [[ ${#LOCAL_PACKAGES[@]} -eq 0 ]]; then
    echo "No local recipes found."
    exit 0
fi

# Check each package against upstream
newer_versions=()
not_upstream=()
manifest_changes=()

for package in $(echo "${!LOCAL_PACKAGES[@]}" | tr ' ' '\n' | sort); do
    local_versions="${LOCAL_PACKAGES[$package]}"
    vendor="$(echo "$package" | cut -d/ -f1)"
    name="$(echo "$package" | cut -d/ -f2)"

    # Fetch upstream versions
    upstream_versions=$(gh api "repos/$UPSTREAM_REPO/contents/$vendor/$name" \
        --jq '[.[] | select(.type=="dir") | .name] | sort_by(. | split(".") | map(tonumber? // 0)) | .[]' 2>/dev/null || echo "")

    if [[ -z "$upstream_versions" ]]; then
        not_upstream+=("$package ($(echo $local_versions | xargs | tr ' ' ', '))")
        continue
    fi

    upstream_latest=$(echo "$upstream_versions" | tail -1)

    # Find local max version
    local_max=$(echo "$local_versions" | tr ' ' '\n' | grep -v '^$' | sort -V | tail -1)

    # Compare versions (simple string compare after sort -V)
    if echo -e "$local_max\n$upstream_latest" | sort -V | tail -1 | grep -qv "^${local_max}$"; then
        newer_versions+=("$package: local=$local_max, upstream=$upstream_latest")
    fi

    # For each local version that exists upstream, compare manifest.json
    for ver in $local_versions; do
        [[ -z "$ver" ]] && continue

        if echo "$upstream_versions" | grep -qx "$ver"; then
            local_manifest="$PROJECT_DIR/$package/$ver/manifest.json"
            upstream_manifest=$(gh api "repos/$UPSTREAM_REPO/contents/$vendor/$name/$ver/manifest.json" \
                --jq '.content' 2>/dev/null | base64 -d 2>/dev/null || echo "")

            if [[ -z "$upstream_manifest" ]]; then
                continue
            fi

            local_manifest_content=$(cat "$local_manifest")

            # Normalize JSON for comparison (sort keys)
            local_normalized=$(echo "$local_manifest_content" | jq -S . 2>/dev/null || echo "$local_manifest_content")
            upstream_normalized=$(echo "$upstream_manifest" | jq -S . 2>/dev/null || echo "$upstream_manifest")

            if [[ "$local_normalized" != "$upstream_normalized" ]]; then
                manifest_changes+=("$package/$ver")

                if $SHOW_DIFF; then
                    echo ""
                    warn "DIFF $package/$ver/manifest.json:"
                    /usr/bin/diff --color=auto <(echo "$local_normalized") <(echo "$upstream_normalized") || true
                fi
            fi

            # Compare all files in the version directory
            if $SHOW_DIFF; then
                upstream_files=$(gh api "repos/$UPSTREAM_REPO/contents/$vendor/$name/$ver" \
                    --jq '[.[] | select(.type=="file") | .name] | .[]' 2>/dev/null || echo "")

                for f in $upstream_files; do
                    [[ "$f" == "manifest.json" ]] && continue
                    local_file="$PROJECT_DIR/$package/$ver/$f"
                    if [[ -f "$local_file" ]]; then
                        upstream_content=$(gh api "repos/$UPSTREAM_REPO/contents/$vendor/$name/$ver/$f" \
                            --jq '.content' 2>/dev/null | base64 -d 2>/dev/null || echo "")
                        if [[ -n "$upstream_content" ]] && ! diff -q <(cat "$local_file") <(echo "$upstream_content") >/dev/null 2>&1; then
                            warn "DIFF $package/$ver/$f:"
                            /usr/bin/diff --color=auto <(cat "$local_file") <(echo "$upstream_content") || true
                        fi
                    fi
                done
            fi
        fi
    done
done

# Report
header "Newer versions available upstream"
if [[ ${#newer_versions[@]} -gt 0 ]]; then
    for item in "${newer_versions[@]}"; do
        alert "$item"
    done
else
    info "All local recipes are at the latest upstream version"
fi

header "Manifest.json differences (same version)"
if [[ ${#manifest_changes[@]} -gt 0 ]]; then
    for item in "${manifest_changes[@]}"; do
        warn "$item"
    done
    echo -e "\n  Run with ${BOLD}--diff${NC} to see detailed differences"
else
    info "All manifests match upstream"
fi

header "Packages not found upstream (local-only)"
if [[ ${#not_upstream[@]} -gt 0 ]]; then
    for item in "${not_upstream[@]}"; do
        echo -e "  - $item"
    done
else
    info "All local packages exist upstream"
fi

echo ""
