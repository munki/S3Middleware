#!/bin/sh
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

check_exit_code() {
    if [ "$1" != "0" ]; then
        echo "$2: $1" 1>&2
        exit 1
    fi
}

TOOL="S3Middleware"
VERSION="2.0"

# find the Xcode project
THISDIR=$(dirname "$0")
PROJ="${THISDIR}/${TOOL}.xcodeproj"
if [ ! -e "${PROJ}" ] ; then
    check_exit_code 1 "${PROJ} doesn't exist"
fi

# make sure we have a build directory to use
BUILD_DIR="${THISDIR}/build"
if [ ! -d "${BUILD_DIR}" ] ; then
    mkdir "${BUILD_DIR}"
fi

# build the dylib
xcodebuild \
    -project "${PROJ}" \
    -configuration Release \
    -scheme "${TOOL}" \
    -destination "generic/platform=macOS" \
    -derivedDataPath "${BUILD_DIR}" \
    build 1>/dev/null

check_exit_code "$?" "Error building ${TOOL}.plugin"
cp "${BUILD_DIR}/Build/Products/Release/${TOOL}.plugin" "${BINARIES_DIR}/"

# build a pkg (component pkg for now)

# make the payload (package root) dir
PKG_ROOT="${THISDIR}/payload"
mkdir -p "${PKG_ROOT}/usr/local/munki/middleware"
chmod -R 755 "${PKG_ROOT}"

# copy the dylib into the payload
cp "${BUILD_DIR}/Build/Products/Release/${TOOL}.plugin" "${PKG_ROOT}/usr/local/munki/middleware/"

# build the pkg!
pkgbuild \
    --root "${PKG_ROOT}" \
    --identifier "com.googlecode.munki.${TOOL}" \
    --version "${VERSION}" \
    --ownership recommended \
    "${THISDIR}/${TOOL}-${VERSION}.pkg"

#if [ $? -eq 0 ] ; then
#    # clean up!
#    rm -r "$BUILD_DIR"
#    rm -r "$PKG_ROOT"
#fi
