EOS_BUILD_PATH=$1
EOS_KEY=$2

cleos create account eosio monstereosmt ${EOS_KEY} ${EOS_KEY}
eosiocpp -o market.wast market.cpp
eosiocpp -g market.abi market.cpp
cleos set contract monstereosmt ../market

cleos set account permission monstereosmt active \
'{"threshold": 1,
  "keys": [{
    "key": "'${EOS_KEY}'",
    "weight": 1
  }],
  "accounts": [{
    "permission": {"actor": "monstereosmt",
                   "permission": "eosio.code"},
                   "weight": 1
  }]}' owner -p monstereosmt