## What is this?
This project is responsible for running EOS nodes for the Spartos project. It is also responsible for setting up all the smart contracts and DAPPs into the nodes on the startup. 

Currently it is configured to run:

 - 7 nodeos node
 - 1 keosd node

## Prerequisites
 - Docker Engine and Docker Compose  (tested on Ubuntu and macOS, Docker 18.06.0-ce and docker-compose 1.22.0). In order to download the images required to run the project, access to internet is needed. Images could also take a considerable amount of disk space, make sure to have at least 30GB free.

## EOS Blockchain
EOSIO is software that introduces a blockchain architecture designed to enable vertical and horizontal scaling of decentralized applications. It comes with a number of programs. The primary ones that you will use, and the ones that are covered here, are:

- nodeos (node + eos = nodeos) - the core EOSIO node daemon that can be configured with plugins to run a node. Example uses are block production, dedicated API endpoints, and local development.
- cleos (cli + eos = cleos) - command line interface to interact with the blockchain and to manage wallets
- keosd (key + eos = keosd) - component that securely stores EOSIO keys in wallets. 

For more information: https://eos.io/

## Configuration
For the 7 nodeos instance and 1 keosd instance available in this project, there are 2 main files that holds all the configuration:

- `docker-compose.yml`: it has all the configuration about instances and the node initialization parameters and commands.
     
- `up.sh`: This is a script that orchestrate all the configuration that needs to be done prior running the nodes and also, as the name states, starts everything up. At this file, there is configuration for: a default wallet inside keosd node; deploying the eosio.bios smart contract; and all the initial setup of the 7 nodeos instance.

## Adding / Removing nodes
Currently the project is configured to run 7 nodeos instances and 1 keosd instance. If there is a need to add more or remove some nodes, it could be done by editing the configuration of the `docker-compose.yml` and `up.sh` files.

## Network 
Docker compose file is configured to startup all the nodes under the subnet 172.15.0.0/16. If you are running locally you may also refer to the nodes and servers using **localhost**.

## Running Locally
Run: `./up.sh` in the project folder.
Now:
 - **Keosd nodes**:
    - http://172.15.0.99:8899
    
 - **Nodeos nodes**:
    - http://172.15.0.10:8888 - Main EOS node / Block producer
    - http://172.15.0.11:8889
    - http://172.15.0.12:8890
    - http://172.15.0.13:8891
    - http://172.15.0.14:8892
    - http://172.15.0.15:8893
    - http://172.15.0.16:8894

 - **Blocker nodes**:
    - http://172.15.0.101:3001
    - http://172.15.0.102:3002
    - http://172.15.0.103:3003
    - http://172.15.0.104:3004
    - http://172.15.0.105:3005
    - http://172.15.0.106:3006
    - http://172.15.0.107:3007
    
You may test if it running by accessing: http://localhost:8888/v1/chain/get_info. Change the port value to see if the other nodes are running.

## Environment Variables
For a full list, please see the environment variables which are set in the `docker-compose.yml` files for each application.  

**Locally:** Modify the `docker-compose.yml` files `environment` section to add new variables. Check also the variables declared inside the `up.sh` file.

**Server:** Set variables based on above files.

## Clean up
In order to stop all the nodes and remove all the files created please use the `down.sh` script.

## Tests
In order to test Spartos EOS, specially about Transaction Per Second (TPS) measurements, you need to configure and run the files under the test folder. The idea of these scripts is to achieve the following statements:

- Transactions should be executed from different addresses (to avoid state caching)
- Transactions sources should be distributed in network 
- All network nodes should receive equal number of transactions (to reproduce real world scenario)

**NOTE:** The below is all referring to being inside the `test` folder.

This is not ready to go test. First you need to create the AWS instances where the test will be performed. You also need to provide a SSH PEM file to connect on those instances. Check the `instances.sh` and `spartos-eos-key.pem` files.  

After that, you may call the `configure.sh` script. It will install and configure everything that is needed for the test on the remote client instances. 

1. Run `./setup.sh` on the orchestrating node.
2. Run `./schedule-instances.sh` on the orchestrating node. This will schedule `remote/run.sh` script to run at the same time on all the client instances.
3. Once the tests have been completed, run `./get-results.sh` and the results should be copied into the `./output` folder, ready for consumption into JMeter GUI.


## Folder structure
    .
    ├── .vscode                 # VS Code config files (recommended editor)
    ├── eos                     # Folder holds all files related to EOS
    ├── oracle                  # It has all the files required to run the oracle.
    ├── test                    # It has all the files required to run the tests related to the spartos EOS.
    ├── .gitignore              # Files which should not be checked into git
    ├── docker-compose.yml      # docker-compose orchestration file
    ├── up.sh                   # Start-up script
    ├── down.sh                 # Script used to stop all nodes and removing all files created.
    └── README.md
