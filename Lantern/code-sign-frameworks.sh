#!/bin/sh

# Source: http://stackoverflow.com/a/11284404/652615

# WARNING: You may have to run Clean in Xcode after changing CODE_SIGN_IDENTITY!

# Verify that $CODE_SIGN_IDENTITY is set
if [ -z "${CODE_SIGN_IDENTITY}" ] ; then
echo "CODE_SIGN_IDENTITY needs to be set for framework code-signing!"

if [ "${CONFIGURATION}" = "Release" ] ; then
exit 1
else
# Code-signing is optional for non-release builds.
exit 0
fi
fi

if [ -z "${CODE_SIGN_ENTITLEMENTS}" ] ; then
echo "CODE_SIGN_ENTITLEMENTS needs to be set for framework code-signing!"

if [ "${CONFIGURATION}" = "Release" ] ; then
exit 1
else
# Code-signing is optional for non-release builds.
exit 0
fi
fi

ITEMS=""

FRAMEWORK_DIR="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
if [ -d "$FRAMEWORK_DIR" ] ; then
FRAMEWORKS=$(find "${FRAMEWORK_DIR}" -depth -type d -name "*.framework" -or -name "*.dylib" -or -name "*.bundle" | sed -e "s/\(.*framework\)/\1\/Versions\/A\//")
RESULT=$?
if [[ $RESULT != 0 ]] ; then
exit 1
fi

ITEMS="${FRAMEWORKS}"
fi

LOGINITEMS_DIR="${TARGET_BUILD_DIR}/${CONTENTS_FOLDER_PATH}/Library/LoginItems/"
if [ -d "$LOGINITEMS_DIR" ] ; then
LOGINITEMS=$(find "${LOGINITEMS_DIR}" -depth -type d -name "*.app")
RESULT=$?
if [[ $RESULT != 0 ]] ; then
exit 1
fi

ITEMS="${ITEMS}"$'\n'"${LOGINITEMS}"
fi

# Prefer the expanded name, if available.
CODE_SIGN_IDENTITY_FOR_ITEMS="${EXPANDED_CODE_SIGN_IDENTITY_NAME}"
if [ "${CODE_SIGN_IDENTITY_FOR_ITEMS}" = "" ] ; then
# Fall back to old behavior.
CODE_SIGN_IDENTITY_FOR_ITEMS="${CODE_SIGN_IDENTITY}"
fi

echo "Identity:"
echo "${CODE_SIGN_IDENTITY_FOR_ITEMS}"

echo "Entitlements:"
echo "${CODE_SIGN_ENTITLEMENTS}"

echo "Found:"
echo "${ITEMS}"

# Change the Internal Field Separator (IFS) so that spaces in paths will not cause problems below.
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

# Loop through all items.
for ITEM in $ITEMS;
do
echo "Signing '${ITEM}'"
codesign --force --verbose --sign "${CODE_SIGN_IDENTITY_FOR_ITEMS}" --entitlements "${CODE_SIGN_ENTITLEMENTS}" "${ITEM}"
RESULT=$?
if [[ $RESULT != 0 ]] ; then
IFS=$SAVEIFS
exit 1
fi
done

# Restore $IFS.
IFS=$SAVEIFS