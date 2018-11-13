#!/usr/bin/env bash
set -o xtrace

# Scheduling script to run at a given time
at -f /home/ec2-user/run.sh `date -d "+2 minutes" "+%H:%M"`