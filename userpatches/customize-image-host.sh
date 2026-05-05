#!/bin/bash
# Armbian host-side hook, runs before customize-image.sh enters chroot.
# Has full access to framework variables (BOARD, BRANCH, RELEASE, ...).
#
# customize-image.sh runs inside chroot and cannot read $BRANCH directly,
# so for NAPI2 we propagate it via userpatches/overlay/ which armbian
# bind-mounts as /tmp/overlay inside chroot.

if [ "${BOARD}" = "napi2" ]; then
    echo "${BRANCH}" > "${USERPATCHES_PATH}/overlay/napi-branch.txt"
fi
