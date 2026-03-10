#!/usr/bin/env bash
# Upgrade a local recipe by downloading missing upstream versions
# and applying local customizations via 3-way merge.
#
# Strategy:
#   1. Find the highest local version that also exists upstream (= merge base)
#   2. For each newer upstream version, 3-way merge:
#      base=upstream/old  ours=local/old  theirs=upstream/new
#   3. Stop on first conflict (user fixes, re-runs)
#
# Usage: ./upgrade-recipe.sh <vendor/package> [--dry-run] [--keep-tmp] [--report-dir <dir>] [--upstream-cache <dir>]
#
# Requires: gh (GitHub CLI), jq, git

set -euo pipefail

UPSTREAM_REPO="schranz-php-recipes/symfony-recipes-php"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

header()  { echo -e "\n${BOLD}${CYAN}── $1 ──${NC}"; }
info()    { echo -e "  ${GREEN}✓${NC} $1"; }
warn()    { echo -e "  ${YELLOW}▶${NC} $1"; }
error()   { echo -e "  ${RED}✗${NC} $1"; }
dim()     { echo -e "  ${DIM}$1${NC}"; }

# --- Args ---
PACKAGE=""
DRY_RUN=false
KEEP_TMP=false
REPORT_DIR=""
UPSTREAM_CACHE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)         DRY_RUN=true; shift ;;
        --keep-tmp)        KEEP_TMP=true; shift ;;
        --report-dir)      REPORT_DIR="$2"; shift 2 ;;
        --upstream-cache)  UPSTREAM_CACHE="$2"; shift 2 ;;
        -*)                echo "Unknown option: $1"; exit 1 ;;
        *)                 PACKAGE="$1"; shift ;;
    esac
done

if [[ -z "$PACKAGE" ]]; then
    echo "Usage: $0 <vendor/package> [--dry-run] [--keep-tmp] [--report-dir <dir>] [--upstream-cache <dir>]"
    exit 1
fi

VENDOR="${PACKAGE%%/*}"
NAME="${PACKAGE##*/}"
LOCAL_PKG_DIR="$PROJECT_DIR/$VENDOR/$NAME"

if [[ ! -d "$LOCAL_PKG_DIR" ]]; then
    error "Local recipe not found: $LOCAL_PKG_DIR"
    exit 1
fi

# --- Report helpers ---
PKG_REPORT_DIR=""
if [[ -n "$REPORT_DIR" ]]; then
    PKG_REPORT_DIR="$REPORT_DIR/$VENDOR/$NAME"
fi

# Write a report file for a version (only when there are actual changes)
# Usage: write_report <version> <status> <patch_source> <diff_content>
write_report() {
    [[ -z "$PKG_REPORT_DIR" ]] && return

    local ver="$1" status="$2" patch_source="${3:-}" diff_content="${4:-}"

    [[ -z "$diff_content" ]] && return

    local ver_dir="$PKG_REPORT_DIR/$ver"
    mkdir -p "$ver_dir"

    echo "$status" > "$ver_dir/status"

    {
        echo "package=$PACKAGE"
        echo "version=$ver"
        echo "status=$status"
        echo "patch_source=$patch_source"
        echo "date=$(date -Iseconds)"
    } > "$ver_dir/metadata"

    echo "$diff_content" > "$ver_dir/applied.diff"
}

save_patch_to_report() {
    [[ -z "$PKG_REPORT_DIR" ]] && return
    [[ -d "$PKG_REPORT_DIR" ]] || return

    local src="$1" patch_file="$2"
    [[ -s "$patch_file" ]] && cp "$patch_file" "$PKG_REPORT_DIR/customizations-from-$src.patch"
}

save_rejects_to_report() {
    [[ -z "$PKG_REPORT_DIR" ]] && return

    local ver="$1" reject_dir="$2" dest_dir="$3"
    local ver_report="$PKG_REPORT_DIR/$ver"
    [[ -d "$ver_report" ]] || return

    if compgen -G "$reject_dir/*" > /dev/null 2>&1; then
        while IFS= read -r rej; do
            cp "$rej" "$ver_report/"
        done < <(find "$reject_dir" -name "*.patch" -o -name "*.rej" 2>/dev/null)
    fi

    while IFS= read -r rej; do
        cp "$rej" "$ver_report/"
    done < <(find "$dest_dir" -name "*.rej" 2>/dev/null)
}

# --- 3-way directory merge ---
# Merge local customizations into a new upstream version using git merge-file.
# base=upstream/old  ours=local/old  theirs=upstream/new  output=destination
# Returns: 0 if clean, 1 if conflicts
merge_three_way() {
    local base="$1" ours="$2" theirs="$3" output="$4"
    local has_conflicts=0
    local empty_file
    empty_file=$(mktemp)

    # Collect unique file paths from all three trees
    local -A seen
    local all_files=()
    for dir in "$base" "$ours" "$theirs"; do
        [[ -d "$dir" ]] || continue
        while IFS= read -r f; do
            if [[ -z "${seen[$f]:-}" ]]; then
                seen[$f]=1
                all_files+=("$f")
            fi
        done < <(cd "$dir" && find . -type f ! -name '*.orig' ! -name '*.rej' | sed 's|^\./||' | sort)
    done

    mkdir -p "$output"

    for file in "${all_files[@]}"; do
        local b="$base/$file" o="$ours/$file" t="$theirs/$file"
        mkdir -p "$output/$(dirname "$file")"

        local in_base=false in_ours=false in_theirs=false
        [[ -f "$b" ]] && in_base=true
        [[ -f "$o" ]] && in_ours=true
        [[ -f "$t" ]] && in_theirs=true

        if $in_theirs && $in_base && $in_ours; then
            # Common case: file in all three → 3-way merge
            if git merge-file -p "$o" "$b" "$t" > "$output/$file" 2>/dev/null; then
                :
            else
                has_conflicts=1
                warn "Conflict in $file"
            fi
        elif $in_theirs && $in_base && ! $in_ours; then
            # We deleted it → respect local deletion
            :
        elif $in_theirs && ! $in_base && $in_ours; then
            # Added independently in both → merge with empty base
            if git merge-file -p "$o" "$empty_file" "$t" > "$output/$file" 2>/dev/null; then
                :
            else
                has_conflicts=1
                warn "Conflict in $file (added in both)"
            fi
        elif $in_theirs && ! $in_base && ! $in_ours; then
            # New upstream file → copy
            cp "$t" "$output/$file"
        elif ! $in_theirs && $in_base && $in_ours; then
            # Upstream deleted, we kept (maybe modified) → keep if modified
            if ! /usr/bin/diff -q "$b" "$o" > /dev/null 2>&1; then
                cp "$o" "$output/$file"
                warn "Kept locally-modified file deleted upstream: $file"
            fi
        elif ! $in_theirs && ! $in_base && $in_ours; then
            # Local-only file → keep
            cp "$o" "$output/$file"
        fi
    done

    rm -f "$empty_file"
    return $has_conflicts
}

# Find files with merge conflict markers
find_conflict_files() {
    local dir="$1"
    grep -rl '^<<<<<<<' "$dir" 2>/dev/null || true
}

# --- Find local versions ---
LOCAL_VERSIONS=()
for d in "$LOCAL_PKG_DIR"/*/; do
    [[ -f "$d/manifest.json" ]] && LOCAL_VERSIONS+=("$(basename "$d")")
done

if [[ ${#LOCAL_VERSIONS[@]} -eq 0 ]]; then
    error "No versions found locally for $PACKAGE"
    exit 1
fi

LOCAL_VERSIONS=($(printf '%s\n' "${LOCAL_VERSIONS[@]}" | sort -V))
LOCAL_MAX="${LOCAL_VERSIONS[-1]}"

header "Local recipe: $PACKAGE"
info "Local versions: ${LOCAL_VERSIONS[*]}"

# --- Fetch upstream versions ---
if [[ -n "$UPSTREAM_CACHE" && -d "$UPSTREAM_CACHE/$VENDOR/$NAME" ]]; then
    UPSTREAM_VERSIONS=$(find "$UPSTREAM_CACHE/$VENDOR/$NAME" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -V)
else
    UPSTREAM_RAW=$(gh api "repos/$UPSTREAM_REPO/contents/$VENDOR/$NAME" 2>/dev/null || echo "")

    if [[ -z "$UPSTREAM_RAW" ]] || echo "$UPSTREAM_RAW" | jq -e '.message' >/dev/null 2>&1; then
        info "Package $PACKAGE not found upstream — skipping"
        exit 0
    fi

    UPSTREAM_VERSIONS=$(echo "$UPSTREAM_RAW" \
        | jq -r '[.[] | select(.type=="dir") | .name] | sort_by(. | split(".") | map(tonumber? // 0)) | .[]' 2>/dev/null || echo "")
fi

if [[ -z "$UPSTREAM_VERSIONS" ]]; then
    info "No upstream versions found for $PACKAGE — skipping"
    exit 0
fi

info "Upstream versions: $(echo "$UPSTREAM_VERSIONS" | tr '\n' ' ')"

# --- Find newer versions (upstream versions strictly above LOCAL_MAX) ---
MISSING_VERSIONS=()
while IFS= read -r ver; do
    if [[ $(printf '%s\n%s' "$LOCAL_MAX" "$ver" | sort -V | tail -1) != "$LOCAL_MAX" ]]; then
        MISSING_VERSIONS+=("$ver")
    fi
done <<< "$UPSTREAM_VERSIONS"

if [[ ${#MISSING_VERSIONS[@]} -eq 0 ]]; then
    info "Already at latest upstream version ($LOCAL_MAX)"
    exit 0
fi

warn "Newer versions available: ${MISSING_VERSIONS[*]}"

# --- Find patch source: highest local version that exists upstream ---
PATCH_SOURCE=""
for lv in "${LOCAL_VERSIONS[@]}"; do
    echo "$UPSTREAM_VERSIONS" | grep -qx "$lv" && PATCH_SOURCE="$lv"
done
# LOCAL_VERSIONS is sorted, so last match = highest common version

# --- Setup temp dir ---
TMP_DIR=$(mktemp -d)
cleanup() {
    if ! $KEEP_TMP; then
        rm -rf "$TMP_DIR"
    else
        dim "Temp dir preserved: $TMP_DIR"
    fi
}
trap cleanup EXIT

# --- Download a full version directory from upstream ---
download_upstream_version() {
    local ver="$1" dest="$2"

    if [[ -n "$UPSTREAM_CACHE" && -d "$UPSTREAM_CACHE/$VENDOR/$NAME/$ver" ]]; then
        cp -r "$UPSTREAM_CACHE/$VENDOR/$NAME/$ver" "$dest"
        return
    fi

    mkdir -p "$dest"

    local files
    files=$(gh api "repos/$UPSTREAM_REPO/git/trees/main:$VENDOR/$NAME/$ver?recursive=1" \
        --jq '.tree[] | select(.type=="blob") | .path' 2>/dev/null || echo "")

    if [[ -z "$files" ]]; then
        error "Failed to fetch file tree for $PACKAGE/$ver"
        return 1
    fi

    while IFS= read -r filepath; do
        local dir
        dir=$(dirname "$filepath")
        mkdir -p "$dest/$dir"

        gh api "repos/$UPSTREAM_REPO/contents/$VENDOR/$NAME/$ver/$filepath" \
            --jq '.content' 2>/dev/null | base64 -d > "$dest/$filepath" 2>/dev/null || {
            error "Failed to download $PACKAGE/$ver/$filepath"
            return 1
        }
    done <<< "$files"
}

# --- No common version with upstream → download as-is ---
if [[ -z "$PATCH_SOURCE" ]]; then
    warn "No local version matches upstream — downloading all missing versions as-is"

    for ver in "${MISSING_VERSIONS[@]}"; do
        header "Downloading $PACKAGE/$ver"
        DEST="$LOCAL_PKG_DIR/$ver"

        if [[ -d "$DEST" ]]; then
            warn "Already exists locally, skipping: $DEST"
            continue
        fi

        if $DRY_RUN; then
            dim "[dry-run] Would download to $DEST"
            continue
        fi

        download_upstream_version "$ver" "$DEST"
        info "Downloaded $PACKAGE/$ver"
    done

    header "Done"
    exit 0
fi

# --- Check local customizations ---
header "Checking customizations from $PATCH_SOURCE"

UPSTREAM_BASE="$TMP_DIR/upstream-$PATCH_SOURCE"
download_upstream_version "$PATCH_SOURCE" "$UPSTREAM_BASE"
info "Downloaded upstream $PATCH_SOURCE"

LOCAL_BASE="$LOCAL_PKG_DIR/$PATCH_SOURCE"

customization_diff=$(/usr/bin/diff -ruN "$UPSTREAM_BASE" "$LOCAL_BASE" 2>/dev/null || true)

if [[ -z "$customization_diff" ]]; then
    info "No local customizations in $PATCH_SOURCE — identical to upstream"
    info "Copying all newer versions as-is"

    for ver in "${MISSING_VERSIONS[@]}"; do
        DEST="$LOCAL_PKG_DIR/$ver"
        [[ -d "$DEST" ]] && { warn "Already exists: $DEST"; continue; }

        if $DRY_RUN; then
            dim "[dry-run] Would copy upstream $ver as-is"
            continue
        fi

        download_upstream_version "$ver" "$DEST"
        info "Copied $PACKAGE/$ver as-is"
    done

    header "Done"
    exit 0
fi

CUSTOM_LINES=$(echo "$customization_diff" | wc -l)
info "Local customizations detected: $CUSTOM_LINES diff lines (from $PATCH_SOURCE)"

echo ""
echo -e "${DIM}--- Customization preview (first 40 lines) ---${NC}"
echo "$customization_diff" | head -40
if [[ $CUSTOM_LINES -gt 40 ]]; then
    echo -e "${DIM}... ($((CUSTOM_LINES - 40)) more lines)${NC}"
fi

# --- 3-way merge for each missing version ---
PROCESSED=()

for ver in "${MISSING_VERSIONS[@]}"; do
    header "Upgrade $PACKAGE/$ver"

    DEST="$LOCAL_PKG_DIR/$ver"

    if [[ -d "$DEST" ]]; then
        warn "Already exists locally, skipping: $DEST"
        PROCESSED+=("$ver")
        continue
    fi

    # Download upstream target version
    UPSTREAM_NEW="$TMP_DIR/upstream-$ver"
    if [[ ! -d "$UPSTREAM_NEW" ]]; then
        download_upstream_version "$ver" "$UPSTREAM_NEW"
        info "Downloaded upstream $ver"
    fi

    if $DRY_RUN; then
        dim "[dry-run] Testing 3-way merge: local/$PATCH_SOURCE + upstream/$PATCH_SOURCE → upstream/$ver"
        TEST_DIR="$TMP_DIR/test-$ver"
        if merge_three_way "$UPSTREAM_BASE" "$LOCAL_BASE" "$UPSTREAM_NEW" "$TEST_DIR"; then
            info "[dry-run] Merge applies cleanly to $ver"
        else
            conflict_files=$(find_conflict_files "$TEST_DIR")
            if [[ -n "$conflict_files" ]]; then
                error "[dry-run] Merge has conflicts on $ver:"
                echo "$conflict_files" | while read -r cf; do
                    error "  $(basename "$cf")"
                done
            else
                warn "[dry-run] Merge completed with warnings for $ver"
            fi
        fi
        rm -rf "$TEST_DIR"
        PROCESSED+=("$ver")
        continue
    fi

    # 3-way merge: base=upstream/old  ours=local/old  theirs=upstream/new
    echo ""
    if merge_three_way "$UPSTREAM_BASE" "$LOCAL_BASE" "$UPSTREAM_NEW" "$DEST"; then
        info "3-way merge clean for $ver"

        applied_diff=$(/usr/bin/diff -ruN "$UPSTREAM_NEW" "$DEST" 2>/dev/null || true)
        if [[ -n "$applied_diff" ]]; then
            echo ""
            dim "--- Changes applied to $ver (vs upstream) ---"
            echo "$applied_diff" | head -80
            echo ""
            write_report "$ver" "clean" "$PATCH_SOURCE" "$applied_diff"
        fi

        PROCESSED+=("$ver")
    else
        # Check for actual conflict markers
        conflict_files=$(find_conflict_files "$DEST")

        if [[ -n "$conflict_files" ]]; then
            error "3-way merge has conflicts on $ver"
            echo ""
            echo "$conflict_files" | while read -r cf; do
                error "Conflict: $cf"
                echo ""
                cat "$cf"
                echo ""
            done

            applied_diff=$(/usr/bin/diff -ruN "$UPSTREAM_NEW" "$DEST" 2>/dev/null || true)
            report_diff="${applied_diff:-# Merge conflicts — see conflict markers in files}"
            write_report "$ver" "conflicts" "$PATCH_SOURCE" "$report_diff"

            echo ""
            error "Fix conflicts in $PACKAGE/$ver, then re-run for remaining versions"
            exit 1
        else
            # git merge-file returned non-zero but no conflict markers → treat as success
            warn "Merge completed with warnings for $ver"

            applied_diff=$(/usr/bin/diff -ruN "$UPSTREAM_NEW" "$DEST" 2>/dev/null || true)
            if [[ -n "$applied_diff" ]]; then
                write_report "$ver" "clean" "$PATCH_SOURCE" "$applied_diff"
            fi

            PROCESSED+=("$ver")
        fi
    fi
done

# --- Summary ---
header "Summary"
echo ""
info "Merge base: $PATCH_SOURCE ($CUSTOM_LINES lines of customizations)"
echo ""

for ver in "${PROCESSED[@]}"; do
    DEST="$LOCAL_PKG_DIR/$ver"
    if $DRY_RUN; then
        dim "$PACKAGE/$ver — dry-run ok"
    elif [[ -d "$DEST" ]]; then
        info "$PACKAGE/$ver — ready"
    fi
done

if $KEEP_TMP; then
    echo ""
    dim "Temp dir: $TMP_DIR"
    dim "  upstream-*/          Downloaded upstream versions"
    dim "  upstream-*/          Upstream versions used for 3-way merge"
fi

echo ""
