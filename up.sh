#!/usr/bin/env bash
set -o errexit
set -o xtrace

err_report() {
    echo "Error on line $1"
}

trap 'err_report $LINENO' ERR

function dc() {
  docker-compose up -d --build "$@"
}

export URL_KEOSD=http://172.15.0.99:8899

function keos() {
  docker exec -it spartos-eos_eos-keosd_1 cleos --wallet-url ${URL_KEOSD} "$@"
}

function nodeos() {
  docker exec -it spartos-eos_eos-main-node_1 "$@"
}

function cleos() {
  docker exec -it spartos-eos_eos-main-node_1 cleos "$@"
}

function cleosw() {
  docker exec -it spartos-eos_eos-main-node_1 cleos --wallet-url ${URL_KEOSD} "$@"
}

function eosiocpp() {
  docker exec -it spartos-eos_eos-main-node_1 eosiocpp "$@"
}

source down.sh

# Running the first main nodes
dc eos-main-node eos-keosd

# Waiting for the nodes to be up
sleep 5s

# Creating the wallet
keos wallet create --file /opt/eosio/wallet/pass.txt

# Importing the private key. TODO: Check how to generate it since for this example I am using the default.
keos wallet import --private-key 5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3

# FIXING THE OFFICIAL DOCKER IMAGE FOR THEM - this will fix it on GitHub: https://github.com/EOSIO/eos/pull/5401 - upgrade docker image when this has been merged
nodeos cp /opt/eosio/contracts/eosiolib/core_symbol.hpp /eos/contracts/eosiolib/core_symbol.hpp 

# Copy files for local development
docker cp spartos-eos_eos-main-node_1:/eos/contracts/libc++ ./eos/contracts/libc++
docker cp spartos-eos_eos-main-node_1:/eos/contracts/eosiolib ./eos/contracts/eosiolib
docker cp spartos-eos_eos-main-node_1:/eos/contracts/musl ./eos/contracts/musl
docker cp spartos-eos_eos-main-node_1:/usr/local/include/boost ./eos/contracts/boost
docker cp spartos-eos_eos-main-node_1:/eos/externals/magic_get/include/boost/pfr.hpp ./eos/contracts/boost/pfr.hpp
docker cp spartos-eos_eos-main-node_1:/eos/externals/magic_get/include/boost/pfr ./eos/contracts/boost/pfr

# Deploying the eosio.bios contract
cleosw set contract eosio /contracts/eosio.bios

#### Token Contract ####
# Creating a key pair for token contract
cleos create key --file /mnt/dev/keystore/token.keystore

# Importing token key the wallet
export TOKEN_PRI_KEY=$(grep 'Private key: ' eos/keystore/token.keystore | sed 's/Private key: //g')
cleosw wallet import --private-key ${TOKEN_PRI_KEY}

# Creating an account
export TOKEN_PUB_KEY=$(grep 'Public key: ' eos/keystore/token.keystore | sed 's/Public key: //g')
cleosw create account eosio eosio.token ${TOKEN_PUB_KEY}

# Deploying the eosio.token contract
cleosw set contract eosio.token /opt/eosio/contracts/eosio.token -p eosio.token@active

# Set the threshold of the tokens in your account and the token name
cleosw push action eosio.token create '{"issuer":"eosio.token", "maximum_supply": "1000000000.0000 SYS"}' -p eosio.token@active

# Issue eosio.token account tokens in order to transfer to other accounts
cleosw push action eosio.token issue '{"to":"eosio.token", "quantity": "100000000.0000 SYS", "memo": "issue"}' -p eosio.token@active
#### END Token Contract ####

#### Spartos Betting Contract ####
# Creating a key pair
cleos create key --file /mnt/dev/keystore/spartosbet.keystore

# Importing key
export SPBET_PRI_KEY=$(grep 'Private key: ' eos/keystore/spartosbet.keystore | sed 's/Private key: //g')
cleosw wallet import --private-key ${SPBET_PRI_KEY}

# Creating an account
export SPBET_PUB_KEY=$(grep 'Public key: ' eos/keystore/spartosbet.keystore | sed 's/Public key: //g')
cleosw create account eosio spartosbet ${SPBET_PUB_KEY}

# Compiling Spartos Betting contract
eosiocpp -g /contracts/fifaworldcup/fifaworldcup.abi /contracts/fifaworldcup/fifaworldcup.cpp
eosiocpp -o /contracts/fifaworldcup/fifaworldcup.wast /contracts/fifaworldcup/fifaworldcup.cpp

# Deploying Spartos Betting contract
cleosw set contract spartosbet /contracts/fifaworldcup -p spartosbet@active

# Activating permission of transfering tokens for spartosbet user
cleosw set account permission spartosbet active '{"threshold":1, "keys":[{"key":"'${SPBET_PUB_KEY}'", "weight":1}], "accounts": [{"permission":{"actor":"spartosbet","permission":"eosio.code"},"weight":1}]}' owner -p spartosbet@active

# Initiating contract with oracle data
sleep 2
cleosw push action spartosbet oracledata '{ "id": "1001", "description": "World Cup 2018 - France x Croacia", "name": "World Cup 2018", "startDate": "123123123", "status": "PENDING-TO-START", "homeTeam": "France", "awayTeam": "Croacia", "result": "4x2", "winning": "home" }' -p spartosbet@active

#### END Spartos Betting Contract ####

# Creating configuration for 6 more nodes and at the end starting them up one by one
### Name should be less than 13 characters and only contains the following symbol .12345abcdefghijklmnopqrstuvwxyz
for i in {a..f}
do
    # Creating a new key for the node
    cleos create key --file /mnt/dev/keystore/node_${i}.keystore

    export NODE_${i}_PUB_KEY=$(grep 'Public key: ' eos/keystore/node_${i}.keystore | sed 's/Public key: //g')
    export NODE_${i}_PRI_KEY=$(grep 'Private key: ' eos/keystore/node_${i}.keystore | sed 's/Private key: //g')

    REF_PUB_KEY=NODE_${i}_PUB_KEY
    REF_PRI_KEY=NODE_${i}_PRI_KEY

    # Importing the new private key
    cleosw wallet import --private-key ${!REF_PRI_KEY}

    # Create a new account for the new node with the public key
    cleosw create account eosio node${i} ${!REF_PUB_KEY}

    export NODE_${i}_KEY=${!REF_PUB_KEY}=KEY:${!REF_PRI_KEY}

    # Running node
    dc eos-node_${i}

    sleep 1s
done

# Create Test Accounts
for i in {a..g}
do
  ACCOUNT_NAME=sr${i}
  # Create account
  cleos create key --file /mnt/dev/keystore/${ACCOUNT_NAME}.keystore
  PRI_KEY=$(grep 'Private key: ' eos/keystore/${ACCOUNT_NAME}.keystore | sed 's/Private key: //g')
  cleosw wallet import --private-key ${PRI_KEY}
  PUB_KEY=$(grep 'Public key: ' eos/keystore/${ACCOUNT_NAME}.keystore | sed 's/Public key: //g')
  cleosw create account spartosbet ${ACCOUNT_NAME} ${PUB_KEY}

  # Set permissions to run code
  cleosw set account permission ${ACCOUNT_NAME} active '{"threshold":1, "keys":[{"key":"'${PUB_KEY}'", "weight":1}], "accounts": [{"permission":{"actor":"spartosbet","permission":"eosio.code"},"weight":1}]}' owner -p ${ACCOUNT_NAME}

  # Give initial token balance
  cleosw transfer eosio.token ${ACCOUNT_NAME} '1000.0000 SYS' # Maybe give more tokens anyway
done

# Set node_a as a producer:

# echo "NODE_a_PUB_KEY:"
# echo ${NODE_a_PUB_KEY}

# cleosw push action eosio setprods "{ \"schedule\": [{\"producer_name\": \"nodea\",\"block_signing_key\": \"${NODE_a_PUB_KEY}\"}]}" -p eosio@active

dc blocker-main-node blocker-node_a blocker-node_b blocker-node_c blocker-node_d blocker-node_e blocker-node_f

# showing docker logs
docker-compose logs -f