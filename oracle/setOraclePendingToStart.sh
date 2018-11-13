#!/usr/bin/env bash
set -o xtrace

export URL_KEOSD=http://172.15.0.99:8899

docker exec -it spartos-eos_eos-main-node_1 cleos --wallet-url ${URL_KEOSD} push action spartosbet oracledata '{ "id": "1001", "description": "World Cup 2018 - France x Croacia", "name": "World Cup 2018", "startDate": "123123123", "status": "PENDING-TO-START", "homeTeam": "France", "awayTeam": "Croacia", "result": "4x2", "winning": "home" }' -p spartosbet@active