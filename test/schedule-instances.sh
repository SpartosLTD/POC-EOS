#!/usr/bin/env bash
set -o xtrace

source instances.sh

counter=0
for i in ${INSTANCES}
do
    SSH_OPT='-i spartos-eos-key.pem ec2-user@'${i}'.'${REGION}' -oStrictHostKeyChecking=no -t'

    ssh ${SSH_OPT} ./schedule-to-run.sh ${counter}
    counter=$((counter + 1))
done