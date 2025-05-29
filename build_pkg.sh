#!/bin/sh
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

check_exit_code() {
    if [ "$1" != "0" ]; then
        echo "$2: $1" 1>&2
        exit 1
    fi
}

TOOL="S3Middleware"
VERSION="2.0.0"

# find the Xcode project
THISDIR=$(dirname "$0")
PROJ="${THISDIR}/${TOOL}.xcodeproj"
if [ ! -e "${PROJ}" ] ; then
    check_exit_code 1 "${PROJ} doesn't exist"
fi

# run tests
echo "Running tests for ${TOOL}..."
xcodebuild test \
    -project "${PROJ}" \
    -configuration Debug \
    -scheme "${TOOL}" \
    -destination "platform=macOS,arch=$(arch)" \
    1>/dev/null

check_exit_code "$?" "Error running tests for ${TOOL}"

# generate a revision number for from the list of Git revisions
GITREV=$(git log -n1 --format="%H" -- "${THISDIR}")
GITREVINDEX=$(git rev-list --count "$GITREV")
VERSION="${VERSION}.${GITREVINDEX}"

# make sure we have a clean build directory to use
BUILD_DIR="${THISDIR}/build"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# build the dylib
echo "Building ${TOOL}.plugin..."
xcodebuild build \
    -project "${PROJ}" \
    -configuration Release \
    -scheme "${TOOL}" \
    -destination "generic/platform=macOS" \
    -derivedDataPath "${BUILD_DIR}" \
    1>/dev/null

check_exit_code "$?" "Error building ${TOOL}.plugin"

# build a pkg (component pkg for now)

# make the payload (package root) dir
PKG_ROOT="${THISDIR}/payload"
mkdir -p "${PKG_ROOT}/usr/local/munki/middleware"
chmod -R 755 "${PKG_ROOT}"

# copy the dylib into the payload
cp "${BUILD_DIR}/Build/Products/Release/${TOOL}.plugin" "${PKG_ROOT}/usr/local/munki/middleware/"

# build the pkg!
echo "Building pkg for ${TOOL}..."
pkgbuild \
    --root "${PKG_ROOT}" \
    --identifier "com.googlecode.munki.${TOOL}" \
    --version "${VERSION}" \
    --ownership recommended \
    "${THISDIR}/${TOOL}-${VERSION}.pkg"

check_exit_code "$?" "Error building ${TOOL} pkg"

#if [ $? -eq 0 ] ; then
#    # clean up!
#    rm -r "$BUILD_DIR"
#    rm -r "$PKG_ROOT"
#fi
