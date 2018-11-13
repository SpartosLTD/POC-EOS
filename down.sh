#!/usr/bin/env bash
set -o errexit

# Reset the volumes
docker-compose down

# Removing old files
rm -rf eos/wallet/
rm -rf eos/logs/
rm -rf eos/nodeos*
rm -rf eos/keystore

rm -f eos/contracts/fifaworldcup/fifaworldcup.abi
rm -f eos/contracts/fifaworldcup/fifaworldcup.w*

rm -f test/remote/transaction-list/index.csv
rm -f test/remote/transaction-list/error.csv
rm -rf test/remote/transaction-list/transactions
