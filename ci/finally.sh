#!/bin/bash -e
set -o nounset
set -e

. ci/set_env.sh

echo "==> Build finally block executed"
echo "==> Project: $PROJECTNAME"
echo "==> Branch: $REPLICON_GIT_BRANCH"
echo "==> Version: $VERSION"

if [ "${CODEBUILD_BUILD_SUCCEEDING:-1}" -eq 0 ]; then
    echo "==> Build FAILED"
    exit 1
else
    echo "==> Build SUCCEEDED"
fi
