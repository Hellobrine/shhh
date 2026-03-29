#!/bin/bash
# Delete log files older than 30 days
find /root/pg_data/18/docker/log -name "*.log" -type f -mtime +7 -delete
