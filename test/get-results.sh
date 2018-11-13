#!/usr/bin/env bash
set -o xtrace

source instances.sh

rm -rf output/

mkdir -p output

for i in ${INSTANCES}
do
    scp -i spartos-eos-key.pem -o StrictHostKeyChecking=no ec2-user@${i}.${REGION}:~/log.jtl ./output/log_${i}.jtl
done