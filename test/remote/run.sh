#!/usr/bin/env bash
set -o xtrace

# removing old report
rm -f log.jtl

# starting jmeter
jmeter -n -t request.jmx -l log.jtl