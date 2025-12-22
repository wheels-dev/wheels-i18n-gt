#!/bin/bash
set -e

# Build script for Wheels I18N-GT
# This script creates GitHub artifacts (ZIP files) from the directory prepared by prepare-i18n-gt.sh
# Usage: ./build-i18n-gt.sh <version> <branch> <build_number> <is_prerelease>

VERSION=$1
BRANCH=$2
BUILD_NUMBER=$3
IS_PRERELEASE=$4

echo "Building Wheels I18N-GT v${VERSION} artifacts from prepared directory"

# Setup directories
BUILD_DIR="build-wheels-i18n-gt"
EXPORT_DIR="artifacts/wheels/${VERSION}"
BE_EXPORT_DIR="artifacts/wheels"

# Verify that prepare-i18n-gt.sh has been run
if [ ! -d "${BUILD_DIR}/wheels-i18n-gt" ]; then
    echo "ERROR: ${BUILD_DIR}/wheels-i18n-gt does not exist!"
    echo "Please run prepare-i18n-gt.sh first to create the build directory."
    exit 1
fi

# Create export directories
mkdir -p "${EXPORT_DIR}"
mkdir -p "${BE_EXPORT_DIR}"

# Create ZIP file
echo "Creating ZIP package from prepared directory..."
cd "${BUILD_DIR}" && zip -r "../${EXPORT_DIR}/wheels-i18n-gt-${VERSION}.zip" wheels-i18n-gt/ && cd ..

# Generate checksums
echo "Generating checksums..."
cd "${EXPORT_DIR}"
md5sum "wheels-i18n-gt-${VERSION}.zip" > "wheels-i18n-gt-${VERSION}.md5"
sha512sum "wheels-i18n-gt-${VERSION}.zip" > "wheels-i18n-gt-${VERSION}.sha512"
cd - > /dev/null

# Copy bleeding edge version
echo "Creating bleeding edge version..."
mkdir -p "${BE_EXPORT_DIR}"
cp "${EXPORT_DIR}/wheels-i18n-gt-${VERSION}.zip" "${BE_EXPORT_DIR}/wheels-i18n-gt-be.zip"

echo "Wheels I18N-GT build completed!"