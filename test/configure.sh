#!/usr/bin/env bash
set -o xtrace

source instances.sh

chmod 400 spartos-eos-key.pem

for i in ${INSTANCES}
do
    SSH_OPT='-i spartos-eos-key.pem ec2-user@'${i}'.'${REGION}' -o StrictHostKeyChecking=no -t'

    # Updating with latest packages
    ssh ${SSH_OPT} sudo yum update -y

    # Installing Java 8 - Required for JMeter
    ssh ${SSH_OPT} sudo yum install java-1.8.0-openjdk.x86_64 -y

    # Changing configuration to make java 8 the default one
    ssh ${SSH_OPT} sudo alternatives --set java /usr/lib/jvm/jre-1.8.0-openjdk.x86_64/bin/java 

    # Installing JMeter
    ssh ${SSH_OPT} sudo rm -rf /home/ec2-user/apache* /usr/local/bin/jmeter /home/ec2-user/*.sh

    ssh ${SSH_OPT} wget http://ftp.heanet.ie/mirrors/www.apache.org/dist//jmeter/binaries/apache-jmeter-4.0.tgz

    ssh ${SSH_OPT} tar -xzf apache-jmeter-4.0.tgz

    ssh ${SSH_OPT} sed \'s/-Xms1g -Xmx1g/-Xms500m -Xmx500m/g\' -i /home/ec2-user/apache-jmeter-4.0/bin/jmeter

    ssh ${SSH_OPT} sudo ln -s /home/ec2-user/apache-jmeter-4.0/bin/jmeter /usr/local/bin/jmeter

    # Moving scripts to the instance
    scp -i spartos-eos-key.pem -o StrictHostKeyChecking=no remote/schedule-to-run.sh remote/run.sh ec2-user@${i}.${REGION}:~/
done