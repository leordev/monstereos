#!/bin/bash

echo 'Starting fullnode ...'

if [ "$(ls -A $DATA_DIR)" ]; then
  /opt/eosio/bin/nodeosd.sh --data-dir $DATA_DIR --hard-replay 
else
  /opt/eosio/bin/nodeosd.sh --data-dir $DATA_DIR --genesis-json genesis.json --delete-all-blocks
fi