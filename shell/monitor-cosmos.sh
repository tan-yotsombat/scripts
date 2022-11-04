#!/usr/bin/env bash

# This script monitors node that running cosmos sdk status, and update status via Discord webhook
# Argument $1 should be Discord webhook url

# Get status from default cosmos sdk port, this url can also be public url
status=$(curl localhost:26657/status)

# If status was successfully fetch, then update info. If failed, tag @everyone.
rc=$?
if [ $rc -eq 0 ];
then
  data=$(echo $status | jq '.result.sync_info | {content: ("Time " + .latest_block_time + "\nHeight " + (.latest_block_height | tostring) + "\nCatching up " + (.catching_up | tostring))}')
else
  data='{"content": "@everyone Fetch status failed"}'
fi

# Post message to Discord channel
curl -g -X POST $1 \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
-d "$data"