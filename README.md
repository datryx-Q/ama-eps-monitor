# ama-eps-monitor
Bash script for monitoring Azure Monitor Agent (AMA) throughput. Parses local mdsd.qos log files to calculate Events Per Second (EPS) and megabytes (MB) processed per data stream every 15 minutes. Automatically outputs metrics to a local log file, trims old logs, and forwards structured telemetry to syslog via the logger command.
