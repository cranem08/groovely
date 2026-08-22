#!/usr/bin/env bash
# new-instance.sh — create a versioned project instance from the workflow template.
#
# A "project instance" is a clone of the product-workflow template pinned to a specific
# version (git tag), used for one project (or family). The template repo itself stays a
# clean template; project work happens in the instance.
#
# Usage:
#   scripts/new-instance.sh <target-dir> [version] [repo-url]
#
#   <target-dir>  Destination for the new instance (must not already exist).
#   [version]     Workflow version/tag to pin, e.g. "1.0.0" or "v1.0.0".
#                 Default: the tag matching this template's VERSION file.
#   [repo-url]    Template repo to clone from.
#                 Default: this repo's 'origin' remote.
#
# Requires: git and network access (this is a bootstrap tool, not the offline audit tool).

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_ROOT="$(cd "$HERE/.." && pwd)"

TARGET="${1:-}"
VERSION_ARG="${2:-}"
REPO_ARG="${3:-}"

if [ -z "$TARGET" ]; then
    echo "Usage: scripts/new-instance.sh <target-dir> [version] [repo-url]" >&2
    exit 1
fi
if [ -e "$TARGET" ]; then
    echo "ERROR: target '$TARGET' already exists. Choose a new directory." >&2
    exit 1
fi

# Resolve version -> tag (accept "1.2.3" or "v1.2.3").
if [ -n "$VERSION_ARG" ]; then
    VER="$VERSION_ARG"
elif [ -f "$TEMPLATE_ROOT/VERSION" ]; then
    VER="$(tr -d '[:space:]' < "$TEMPLATE_ROOT/VERSION")"
else
    echo "ERROR: no version given and no VERSION file found at $TEMPLATE_ROOT/VERSION" >&2
    exit 1
fi
case "$VER" in
    v*) TAG="$VER" ;;
    *)  TAG="v$VER" ;;
esac

# Resolve repo URL.
if [ -n "$REPO_ARG" ]; then
    REPO="$REPO_ARG"
else
    REPO="$(git -C "$TEMPLATE_ROOT" config --get remote.origin.url 2>/dev/null || true)"
fi
if [ -z "$REPO" ]; then
    echo "ERROR: no repo URL given and no 'origin' remote on the template." >&2
    echo "Pass it explicitly: scripts/new-instance.sh <target-dir> <version> <repo-url>" >&2
    exit 1
fi

echo "Creating instance:"
echo "  template repo : $REPO"
echo "  pinned version: $TAG"
echo "  target dir    : $TARGET"
echo ""

if ! git clone --branch "$TAG" --depth 1 "$REPO" "$TARGET"; then
    echo "" >&2
    echo "ERROR: clone failed. Is the tag '$TAG' pushed to the remote?" >&2
    echo "List available versions with:  git -C \"$TEMPLATE_ROOT\" tag -l" >&2
    exit 1
fi

echo ""
echo "Instance ready at: $TARGET  (pinned to $TAG)"
echo "Next:"
echo "  cd \"$TARGET\""
echo "  # start a Cowork/Claude Code session here; the navigator will scaffold your"
echo "  # project and stamp it with workflow version $VER."
