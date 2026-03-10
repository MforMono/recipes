#!/usr/bin/env bash
# Generate REVIEW.md from the upgrade report directory.
# Usage: generate-report.sh <report-dir>
#
# Shows only what needs attention:
#   - clean versions: one-line summary
#   - conflict versions: rejected hunks to fix manually

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

REPORT_DIR="${1:-}"
if [[ -z "$REPORT_DIR" || ! -d "$REPORT_DIR" ]]; then
    REPORT_DIR=$(find "$PROJECT_DIR/.upgrade-report" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)
fi

if [[ -z "$REPORT_DIR" || ! -d "$REPORT_DIR" ]]; then
    echo "No changes to review — all packages are up to date."
    exit 0
fi

REVIEW_FILE="$REPORT_DIR/REVIEW.md"

{
    echo "# Upgrade Review Report"
    echo ""
    echo "Generated: $(date -Iseconds)"
    echo ""

    clean_count=0
    conflict_count=0
    conflict_packages=()

    for pkg_dir in "$REPORT_DIR"/*/*; do
        [[ -d "$pkg_dir" ]] || continue

        vendor_name="${pkg_dir#"$REPORT_DIR"/}"
        pkg_has_output=false

        for ver_dir in "$pkg_dir"/*/; do
            [[ -d "$ver_dir" ]] || continue

            ver="$(basename "$ver_dir")"
            status_file="$ver_dir/status"
            metadata_file="$ver_dir/metadata"

            [[ -f "$status_file" ]] || continue

            status=$(cat "$status_file")

            if [[ "$status" == "clean" ]]; then
                clean_count=$((clean_count + 1))
                continue
            fi

            # Conflicts — show rejected hunks
            conflict_count=$((conflict_count + 1))

            if ! $pkg_has_output; then
                echo "## $vendor_name"
                echo ""
                pkg_has_output=true
            fi

            patch_source=""
            if [[ -f "$metadata_file" ]]; then
                patch_source=$(grep '^patch_source=' "$metadata_file" | cut -d= -f2-)
            fi

            echo "### $ver — \`CONFLICTS\`"
            echo ""
            if [[ -n "$patch_source" ]]; then
                echo "Patch source: \`$patch_source\`"
                echo ""
            fi

            for rej in "$ver_dir"/*.rej "$ver_dir"/rejected.patch; do
                [[ -f "$rej" ]] || continue
                echo '```diff'
                cat "$rej"
                echo '```'
                echo ""
            done

            conflict_packages+=("$vendor_name/$ver")
        done
    done

    # Summary at the top
    echo "---"
    echo ""
    if [[ $clean_count -gt 0 ]]; then
        echo "$clean_count version(s) upgraded cleanly."
    fi
    if [[ $conflict_count -gt 0 ]]; then
        echo ""
        echo "**$conflict_count version(s) need manual fixes:**"
        for pkg in "${conflict_packages[@]}"; do
            echo "- \`$pkg\`"
        done
    fi
    echo ""
} > "$REVIEW_FILE"

# Clean up empty report
if [[ $clean_count -eq 0 && $conflict_count -eq 0 ]]; then
    rm -rf "$REPORT_DIR"
    echo "No changes to review — all packages are up to date."
    exit 0
fi

echo "Review report: $REVIEW_FILE"
cat "$REVIEW_FILE"
