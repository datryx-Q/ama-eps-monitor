# ama-eps-monitor
Bash script for monitoring Azure Monitor Agent (AMA) throughput. Parses local mdsd.qos log files to calculate Events Per Second (EPS) and megabytes (MB) processed per data stream every 15 minutes. Automatically outputs metrics to a local log file, trims old logs, and forwards structured telemetry to syslog via the logger command.

# Azure Monitor Agent (AMA) EPS Monitor

A lightweight Bash utility designed to parse the local Azure Monitor Agent Quality of Service (`mdsd.qos`) log blocks. It calculates ingestion metrics per data collection stream and forwards the telemetry to both a dedicated local log file and system logs via `syslog`.

## Features
- **Stream Analysis:** Extracts the Data Collection Endpoint (DCE) and specific stream names from raw AMA logs.
- **Performance Metrics:** Calculates Events Per Second (EPS) and throughput in Megabytes (MB) across 15-minute intervals.
- **Log Rotation Built-In:** Automatically keeps a sliding window of the last 1,000 entries in the local output log to prevent disk exhaustion.
- **Syslog Integration:** Uses `logger` to flag logs under the tag `AMA-EPS`, making it easy for external SIEM tools or log collectors to ingest.

## Prerequisites
- Linux OS with the Azure Monitor Agent installed.
- Read permissions for `/var/opt/microsoft/azuremonitoragent/log/mdsd.qos`.
- Standard core utilities installed (`awk`, `logger`, `tail`, `grep`).

## Installation & Configuration

1. **Clone the repository** to your target Linux server.
2. **Configure the output path:** Open `ama_eps_monitor.sh` and update the `OUTPUT_FILE` variable to your preferred log directory. Ensure the executing user has write permissions to this path:
```bash
OUTPUT_FILE="/var/log/ama_eps_monitor.log"
```
3. Make the script
```bash
chmod +x ama_eps_monitor.sh
```

## Automation (Cron Setup)

Because the Azure Monitor Agent writes its QoS blocks every 15 minutes, you should schedule this script to run on the same interval.

Open your system crontab:
```bash
crontab -e
```

Add the following entry to execute the script every 15 minutes:
(or use a service with timer)

```bash
*/15 * * * * /path/to/ama_eps_monitor.sh >/dev/null 2>&1
```

## Output Format Reference

The script produces structured, pipe-delimited outputs resembling the following:

```test
2026-05-23 20:45:00 UTC | my-linux-server | Microsoft-Syslog | Read:45000 | Sent:45000 | Retries:0 | SizeMB:14.20 | EPS:50.00
```
