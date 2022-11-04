#!/usr/bin/env bash

# This script monitors node that running cosmos sdk (Cosmos validator node), and update status via Discord webhook
#
# Arguments
# =========
# $1 is PID we are monitoring the CPU usage. For example 'pidof gaiad'.
# $2 is Disk volume usage we are monitoring.
# $3 is Discord webhook url
#
# Usage
# =====
# I use this with crontab job (crond). This is example for cron job running every 15 minutes.
# >>> $ crontab -e
# editor|SHELL=/usr/bin/sh
#       |0,15,30,45 * * * * /path/to/monitor-cosmos.sh $(pidof gaiad) /mnt/c 'https://discord.com/api/webhooks/xxx/yyy'
#
# And to make the script executable, run
# >>> $ sudo chmod +x /path/to/monitor-cosmos.sh

# Get status from default cosmos sdk port, this url can also be public url
status=$(curl localhost:26657/status)

# If status was successfully fetch, then update info. If failed, tag @everyone.
rc=$?
if [ $rc -eq 0 ];
then
  # https://stackoverflow.com/questions/1221555/retrieve-cpu-usage-and-memory-usage-of-a-single-process-on-linux
  pcpu=$(top -b -n 2 -d 0.2 -p $1 | tail -1 | awk '{print "CPU " $9 "%\nMem " $10 "%\n" }')

  # https://askubuntu.com/questions/847752/how-to-capture-disk-usage-percentage-of-a-partition-as-an-integer
  pdsk=$(df --output=pcent $2 | tr -dc '0-9')

  # Use jq format data and display only necessary information to build json request body for Discord webhook api.
  data=$(echo $status | jq '.result.sync_info | {content: ("Node status\n'\
"$pcpu\nDisk $pdsk%\n"\
'Block time " + .latest_block_time + "\nHeight " + (.latest_block_height | tostring) + "\nCatching up " + (.catching_up | tostring))}')
else
  data='{"content": "@everyone Fetch status failed"}'
fi

# Post message to Discord channel
curl -g -X POST $3 \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
-d "$data"