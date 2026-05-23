#!/bin/bash

# ==============================================================================
#
# DATE: DD-MMM-YYYY
# PATH: /path/to/ama-eps-metrics.sh
#
#  PURPOSE:
#   Parses the local Azure Monitor Agent (AMA) Quality of Service log file 
#   (mdsd.qos) to calculate telemetry ingestion metrics across 15-minute 
#   intervals. It extracts metrics per data collection stream, computing both 
#   Events Per Second (EPS) and throughput in Megabytes (MB).
#
# USAGE:
#   1. Set the desired path for OUTPUT_FILE below.
#   2. Make the script executable: chmod +x <script_name>.sh
#   3. Automate via cron to match AMA log rotation (every 15 minutes):
#      */15 * * * * /path/to/<script_name>.sh >/dev/null 2>&1
#
# OUTPUTS:
#   - Appends structured, pipe-delimited records to OUTPUT_FILE.
#   - Automatically trims OUTPUT_FILE to the trailing 1,000 entries.
#   - Forwards logs to syslog via the 'logger' utility under tag 'AMA-EPS'.
# ==============================================================================

QOS_FILE="/var/opt/microsoft/azuremonitoragent/log/mdsd.qos"
OUTPUT_FILE="/filepath/to/file.log"

TIME_GEN=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
HOSTNAME=$(hostname)

if [ ! -f "$QOS_FILE" ]; then
    exit 0
fi

RESULTS=$(awk -F',' -v timegen="$TIME_GEN" -v host="$HOSTNAME" '
/^#Time:/ {
    # A new 15-minute interval block has started. 
    # Delete the historical arrays so old streams do not carry over.
    delete dce_map
    delete latest_read
    delete latest_sent
    delete latest_retries
    delete latest_bytes
}
/MaRunTaskTransmitAMACoreAgent/ {
    url = $2
    
    split(url, url_parts, "//"); split(url_parts[2], dce_parts, "/"); dce = dce_parts[1]
    split(url, stream_parts, "/streams/"); 
    if (length(stream_parts) > 1) { split(stream_parts[2], s_parts, "\\?"); stream = s_parts[1] } 
    else { stream = "Unknown" }

    gsub(/\r/, "", $NF)
    retries = $5; bytes = $9; read = $10; sent = $11
    
    dce_map[stream] = dce
    latest_read[stream] = read
    latest_sent[stream] = sent
    latest_retries[stream] = retries
    latest_bytes[stream] = bytes
}
END {
    for (s in latest_sent) {
        r = latest_read[s]; sn = latest_sent[s]; ret = latest_retries[s]; b = latest_bytes[s]; d = dce_map[s]
        
        eps = (sn > 0) ? (sn / 900) : 0
        mb = (b > 0) ? (b / 1024 / 1024) : 0

        printf "%s | %s | %s | Read:%d | Sent:%d | Retries:%d | SizeMB:%.2f | EPS:%.2f\n", timegen, host, s, r, sn, ret, mb, eps
    }
}' "$QOS_FILE")

if [ ! -z "$RESULTS" ]; then
    echo "$RESULTS" >> "$OUTPUT_FILE"

    echo "$RESULTS" | while read -r line; do
        logger -t AMA-EPS "$line"
    done
fi

if [ -f "$OUTPUT_FILE" ]; then
    tail -n 1000 "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
fi
