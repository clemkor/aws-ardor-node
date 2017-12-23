#!/bin/bash

set -e
set -o pipefail

# Ensure AWS_REGION environment variable is present
if [ -z "$AWS_REGION" ]; then
  echo >&2 'Error: missing AWS_REGION environment variable.'
  exit 1
fi

# Ensure AWS_S3_CONFIGURATION_OBJECT environment variable is present
if [ -z "$AWS_S3_CONFIGURATION_OBJECT" ]; then
  echo >&2 'Error: missing AWS_S3_CONFIGURATION_OBJECT environment variable.'
  exit 1
fi

# Source default env file
echo "Sourcing default Ardor configuration."
eval $(cat /opt/ardor/conf/ardor-default.env | sed 's/^/export /')

# Fetch and source overrides env file
echo "Fetching and sourcing override Ardor configuration."
eval $(aws s3 cp --sse AES256 --region ${AWS_REGION} \
    ${AWS_S3_CONFIGURATION_OBJECT} - | sed 's/^/export /')

# Fetch initial database archive if specified and not already present
if [ -n "$ARDOR_INITIAL_BLOCKCHAIN_ARCHIVE_PATH" ]; then
    if [ ! -f "/opt/ardor/nxt_db/nxt.h2.db" ]; then
        echo "Fetching initial blockchain archive from ${ARDOR_INITIAL_BLOCKCHAIN_ARCHIVE_PATH}."
        aws s3 cp --sse AES256 --region ${AWS_REGION} \
            ${ARDOR_INITIAL_BLOCKCHAIN_ARCHIVE_PATH} \
            /tmp/blockchain_archive.zip
        unzip /tmp/blockchain_archive.zip -d /opt/ardor
        rm /tmp/blockchain_archive.zip
        echo "Fetched initial blockchain archive."
    fi
fi

# Render properties template
echo "Rendering Ardor properties file."
cat /opt/ardor/conf/ardor.properties.template \
    | envsubst > /opt/ardor/conf/nxt.properties

# Move to Ardor directory
cd /opt/ardor

tree nxt_certs

# Start Ardor
echo "Starting Ardor."
./run.sh
