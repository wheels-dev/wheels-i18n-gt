#!/bin/bash
set -e

# Prepare script for Wheels I18N-GT (ForgeBox publishing)
# This script prepares the directory structure without creating ZIP files
# Usage: ./prepare-i18n-gt.sh <version> <branch> <build_number> <is_prerelease>

VERSION=$1
BRANCH=$2
BUILD_NUMBER=$3
IS_PRERELEASE=$4

echo "Preparing Wheels I18N-GT v${VERSION} for ForgeBox publishing"

# Setup directories
BUILD_DIR="build-wheels-i18n-gt"

# Cleanup and create directories
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/wheels-i18n-gt"

# Create build label file
BUILD_LABEL="wheels-i18n-gt-${VERSION}-$(date +%Y%m%d%H%M%S)"
echo "Built on $(date)" > "${BUILD_DIR}/wheels-i18n-gt/${BUILD_LABEL}"

# Copy I18N-GT files, excluding specific directories and files
echo "Copying I18N-gt files..."
rsync -av --exclude='workspace' --exclude='simpletestapp' --exclude='*.log' --exclude='.git' --exclude='.gitignore' . "${BUILD_DIR}/wheels-i18n-gt/"

# Copy template files
cp box.json "${BUILD_DIR}/wheels-i18n-gt/box.json"
cp README.md "${BUILD_DIR}/wheels-i18n-gt/README.md"

# Replace version placeholders
echo "Replacing version placeholders..."
find "${BUILD_DIR}/wheels-i18n-gt" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
    sed -i.bak "s/@build\.version@/${VERSION}/g" "$file" && rm "${file}.bak"
done

# Handle build number based on release type
if [ "${IS_PRERELEASE}" = "true" ]; then
    # PreRelease: use build number as-is
    find "${BUILD_DIR}/wheels-i18n-gt" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
        sed -i.bak "s/@build\.number@/${BUILD_NUMBER}/g" "$file" && rm "${file}.bak"
    done
elif [ "${BRANCH}" = "develop" ]; then
    # Snapshot: replace +@build.number@ with -snapshot
    find "${BUILD_DIR}/wheels-i18n-gt" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
        sed -i.bak "s/+@build\.number@/-snapshot/g" "$file" && rm "${file}.bak"
    done
else
    # Regular release: use build number as-is
    find "${BUILD_DIR}/wheels-i18n-gt" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
        sed -i.bak "s/@build\.number@/${BUILD_NUMBER}/g" "$file" && rm "${file}.bak"
    done
fi

echo "Wheels I18N-GT prepared for ForgeBox publishing!"
echo "Directory: ${BUILD_DIR}/wheels-i18n-gt/"