#!/bin/bash
set -e

# -----------------------------
# CONFIGURATION - CHANGE THIS
# -----------------------------
REPO_URL="https://github.com/MathLearnHub/files.git"
REPO_NAME="files"
SOURCE_ONLY_DIR="/tmp/cleanrepo"
BUILD_DIR="Build"        # Relative path in your repo
RELEASE_NAME="game-build" # Name of GitHub release
# -----------------------------

echo "=== Cleaning repository for source-only push ==="

# Make temp directory
rm -rf "$SOURCE_ONLY_DIR"
mkdir -p "$SOURCE_ONLY_DIR"

# Copy everything except builds
rsync -av . "$SOURCE_ONLY_DIR" \
    --exclude='.git' \
    --exclude="$BUILD_DIR" \
    --exclude='*/Release/*'

# Go to clean repo
cd "$SOURCE_ONLY_DIR"
rm -rf .git
git init
git remote add origin "$REPO_URL"
git add .
git commit -m "Source-only repo"

echo "=== Pushing cleaned repo to GitHub ==="
git push --force --set-upstream origin main

# -----------------------------
# UPLOAD BUILD TO RELEASE
# -----------------------------
echo "=== Creating GitHub release and uploading build files ==="

# Check if release exists
if gh release view "$RELEASE_NAME" >/dev/null 2>&1; then
    echo "Release $RELEASE_NAME exists, deleting..."
    gh release delete "$RELEASE_NAME" --confirm
fi

# Create release
gh release create "$RELEASE_NAME" "$BUILD_DIR"/* \
    --title "$RELEASE_NAME" \
    --notes "Automated build upload"

# -----------------------------
# UPDATE LOADER PATHS
# -----------------------------
echo "=== Updating loader paths to CDN ==="

CDN_URL="https://github.com/MathLearnHub/files/releases/download/$RELEASE_NAME/"

# Find all loader JS files and replace build paths
find "$SOURCE_ONLY_DIR" -type f -name '*.js' | while read FILE; do
    sed -i "s|$BUILD_DIR/|$CDN_URL|g" "$FILE"
done

echo "=== Finished ==="
echo "Repo pushed, builds uploaded, loader paths updated to CDN."
