#!/usr/bin/env bash
set -o xtrace

for i in {a..g}
do
  ACCOUNT_NAME=sr${i}
  export NODE_${i}_PRI_KEY=$(grep 'Private key: ' ../eos/keystore/sr${i}.keystore | sed 's/Private key: //g')
done

cd transaction-list 
npm install
chmod +x app

rm -rf transactions*

./app -n 10 -u http://127.0.0.1:8888 -o transactions0 -k ${NODE_a_PRI_KEY} -b 10 -a sra &
./app -n 10 -u http://127.0.0.1:8889 -o transactions1 -k ${NODE_b_PRI_KEY} -b 10 -a srb &
./app -n 10 -u http://127.0.0.1:8890 -o transactions2 -k ${NODE_c_PRI_KEY} -b 10 -a src &
./app -n 10 -u http://127.0.0.1:8891 -o transactions3 -k ${NODE_d_PRI_KEY} -b 10 -a srd &
./app -n 10 -u http://127.0.0.1:8892 -o transactions4 -k ${NODE_e_PRI_KEY} -b 10 -a sre &
./app -n 10 -u http://127.0.0.1:8893 -o transactions5 -k ${NODE_f_PRI_KEY} -b 10 -a srf & 
./app -n 10 -u http://127.0.0.1:8894 -o transactions6 -k ${NODE_g_PRI_KEY} -b 10 -a srg

cd ..

chmod 400 spartos-eos-key.pem

source instances.sh

EOS_INSTANCE='ec2-52-210-61-116.eu-west-1.compute.amazonaws.com'

counter=8888
for i in ${INSTANCES}
do
  SSH_OPT='-i spartos-eos-key.pem ec2-user@'${i}'.'${REGION}' -o StrictHostKeyChecking=no -t'

  ssh ${SSH_OPT} rm -rf transactions/ index.csv request.jmx
  
  scp -i spartos-eos-key.pem -o StrictHostKeyChecking=no -r transaction-list/transactions${counter}/ ec2-user@${i}.${REGION}:~/transactions/
  scp -i spartos-eos-key.pem -o StrictHostKeyChecking=no transaction-list/index.csv transaction-list/request.jmx ec2-user@${i}.${REGION}:~/

  ssh ${SSH_OPT} sed \'s/127.0.0.1/${EOS_INSTANCE}/g\' -i /home/ec2-user/request.jmx
  ssh ${SSH_OPT} sed \'s/3001/$((${counter}))/g\' -i /home/ec2-user/request.jmx

  counter=$((counter + 1))
done
