#!/bin/bash

set -eo pipefail

# Source environment variables
. ci/set_env.sh

function buildCloudWatchLogs() {
    echo "==> Building cloudwatchlogs-with-dlq..."
    pushd cloudwatchlogs-with-dlq
    npm install
    npm run build

    # Rename zip file based on branch
    if [ "$REPLICON_GIT_BRANCH" = "main" ]; then
        ZIP_NAME="sumologic-aws-lambda-m-${VERSION}.zip"
    else
        ZIP_NAME="sumologic-aws-lambda-b-${REPLICON_GIT_CLEAN_BRANCH}-${VERSION}.zip"
    fi

    mv cloudwatchlogs-with-dlq.zip $ZIP_NAME
    echo "==> Renamed to $ZIP_NAME"
    ls -lh $ZIP_NAME
    popd
}

function uploadToS3() {
    echo "==> Uploading artifacts to S3..."

    if [ "$REPLICON_GIT_BRANCH" = "main" ]; then
        # Main branch - upload to release artifacts
        S3_PATH="s3://replicon-release-artifact/sumologic-aws-lambda/"
        echo "==> Uploading to release artifacts (main branch)"
    else
        # Feature branch - upload to build artifacts
        S3_PATH="s3://replicon-build-artifacts/sumologic-aws-lambda/"
        echo "==> Uploading to build artifacts (branch: $REPLICON_GIT_BRANCH)"
    fi

    pushd cloudwatchlogs-with-dlq
    for ZIP_FILE in *.zip; do
        if [ -f "$ZIP_FILE" ]; then
            echo "==> Uploading $ZIP_FILE to ${S3_PATH}"
            aws s3 cp $ZIP_FILE ${S3_PATH}${ZIP_FILE}
            echo "==> Upload completed: ${S3_PATH}${ZIP_FILE}"
        fi
    done
    popd
}

echo "==> Starting build process..."
echo "==> Project: $PROJECTNAME"
echo "==> Branch: $REPLICON_GIT_BRANCH"
echo "==> Version: $VERSION"

buildCloudWatchLogs
uploadToS3

echo "==> Build completed successfully!"
