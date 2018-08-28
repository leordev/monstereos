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

cleos set account permission monstereosio active \
'{"threshold": 1,
  "keys": [{
    "key": "'${EOS_KEY}'",
    "weight": 1
  }],
  "accounts": [{
    "permission": {"actor": "monstereosio",
                   "permission": "eosio.code"},
                   "weight": 1
  }]}' owner -p monstereosio

# some testing

echo "make offer and remove it"
cleos push action monstereosmt offerpet '[1, "friedger"]' -p leordev
cleos get table monstereosmt monstereosmt offers -l 1

cleos push action monstereosmt removeoffer '["leordev", 1]' -p leordev
cleos get table monstereosmt monstereosmt offers -l 1

sleep .5

# offer pet and claim pet
echo "make offer and claim it and reverse it"
echo "monster 1 offered by leordev claimed by friedger"
cleos get table monstereosio monstereosio pets -l 1
cleos push action monstereosmt offerpet '[1, "friedger"]' -p leordev
cleos push action monstereosmt claimpet '["leordev", 1]' -p friedger

echo "monster 1 belongs to friedger"
cleos get table monstereosio monstereosio pets -l 1

echo "monster 1 offered by friedger, claimed by leordev"
cleos push action monstereosmt offerpet '[1, "leordev"]' -p friedger
cleos push action monstereosmt claimpet '["friedger", 1]' -p leordev

echo "no offers left"
cleos get table monstereosmt monstereosmt offers -l 1
echo "monster 1 back to leordev"
cleos get table monstereosio monstereosio pets -l 1

sleep .5
cleos push action monstereosmt offerpet '[1, "friedger", 0, 10000]' -p leordev
echo "one offers for friedger"
cleos get table monstereosmt monstereosmt offers -l 1

cleos push action eosio.token transfer '["friedger", "monstereosio", "1.0000 EOS", "MTT0"]' -p friedger
echo "monster 1 to friedger"
cleos get table monstereosio monstereosio pets -l 1
echo "no offers left"
cleos get table monstereosmt monstereosmt offers -l 1

echo "and reverse"
cleos push action monstereosmt offerpet '[1, "leordev", 0, 10000]' -p friedger
cleos push action eosio.token transfer '["friedger", "monstereosio", "1.0000 EOS", "MTT1"]' -p friedger
