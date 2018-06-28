# Battle Release notes

## Migration Plan for the current pet contract on the Mainnet Live monstereosio account

1. pet.cpp: uncomment/comment abi extension function
1. eosiocpp -g pet.abi pet.cpp
1. pet.cpp: uncomment/comment abi extension function
1. eosiocpp -o pet.wast pet.cpp
1. cleos set contract monstereosio ../pet
1. ../load-elements.sh
1. ../load-pet-types.sh

Running the above steps will conclude the Migration

### Migration costs

before migration contract account stats:

```
cleos get account monstereosio
permissions:
     owner     1:    1 EOS59G44aAf1e6ayDcRnn1gw7dquUoxmiGwhUpXpnA5g9tm13cCop
        active     1:    1 EOS59G44aAf1e6ayDcRnn1gw7dquUoxmiGwhUpXpnA5g9tm13cCop
memory:
     quota:     773.1 KiB    used:     313.9 KiB

net bandwidth:
     staked:        100.0000 EOS           (total stake delegated from account to self)
     delegated:       0.0000 EOS           (total staked delegated to account from others)
     used:             14.14 KiB
     available:        19.17 MiB
     limit:            19.18 MiB

cpu bandwidth:
     staked:        100.0000 EOS           (total stake delegated from account to self)
     delegated:       0.0000 EOS           (total staked delegated to account from others)
     used:             10.09 ms
     available:        3.828 sec
     limit:            3.838 sec

EOS balances:
     liquid:        10031.0000 EOS
     staked:          200.0000 EOS
     unstaking:         0.0000 EOS
     total:         10231.0000 EOS

producers:     <not voted>
```

after deploying new battle contract:

```
cleos get account monstereosio
permissions:
     owner     1:    1 EOS59G44aAf1e6ayDcRnn1gw7dquUoxmiGwhUpXpnA5g9tm13cCop
        active     1:    1 EOS59G44aAf1e6ayDcRnn1gw7dquUoxmiGwhUpXpnA5g9tm13cCop
memory:
     quota:     773.1 KiB    used:     727.2 KiB

net bandwidth:
     staked:        100.0000 EOS           (total stake delegated from account to self)
     delegated:       0.0000 EOS           (total staked delegated to account from others)
     used:             39.83 KiB
     available:        19.14 MiB
     limit:            19.18 MiB

cpu bandwidth:
     staked:        100.0000 EOS           (total stake delegated from account to self)
     delegated:       0.0000 EOS           (total staked delegated to account from others)
     used:             14.81 ms
     available:        3.824 sec
     limit:            3.838 sec

EOS balances:
     liquid:        10031.0000 EOS
     staked:          200.0000 EOS
     unstaking:         0.0000 EOS
     total:         10231.0000 EOS

producers:     <not voted>
```

after loading the element types (took around 21 seconds in Junglenet - node eosgreen):

```
cleos get account monstereosio
permissions:
     owner     1:    1 EOS59G44aAf1e6ayDcRnn1gw7dquUoxmiGwhUpXpnA5g9tm13cCop
        active     1:    1 EOS59G44aAf1e6ayDcRnn1gw7dquUoxmiGwhUpXpnA5g9tm13cCop
memory:
     quota:     773.1 KiB    used:     728.6 KiB

net bandwidth:
     staked:        100.0000 EOS           (total stake delegated from account to self)
     delegated:       0.0000 EOS           (total staked delegated to account from others)
     used:             40.79 KiB
     available:        19.14 MiB
     limit:            19.18 MiB

cpu bandwidth:
     staked:        100.0000 EOS           (total stake delegated from account to self)
     delegated:       0.0000 EOS           (total staked delegated to account from others)
     used:                33 ms
     available:        3.805 sec
     limit:            3.838 sec

EOS balances:
     liquid:        10031.0000 EOS
     staked:          200.0000 EOS
     unstaking:         0.0000 EOS
     total:         10231.0000 EOS

producers:     <not voted>
```

after loading all 109 pet types (took around 6 minutes):

```
cleos get account monstereosio
permissions:
     owner     1:    1 EOS59G44aAf1e6ayDcRnn1gw7dquUoxmiGwhUpXpnA5g9tm13cCop
        active     1:    1 EOS59G44aAf1e6ayDcRnn1gw7dquUoxmiGwhUpXpnA5g9tm13cCop
memory:
     quota:     773.1 KiB    used:     741.9 KiB

net bandwidth:
     staked:        100.0000 EOS           (total stake delegated from account to self)
     delegated:       0.0000 EOS           (total staked delegated to account from others)
     used:             50.92 KiB
     available:        19.13 MiB
     limit:            19.18 MiB

cpu bandwidth:
     staked:        100.0000 EOS           (total stake delegated from account to self)
     delegated:       0.0000 EOS           (total staked delegated to account from others)
     used:             170.8 ms
     available:        3.668 sec
     limit:            3.838 sec

EOS balances:
     liquid:        10031.0000 EOS
     staked:          200.0000 EOS
     unstaking:         0.0000 EOS
     total:         10231.0000 EOS

producers:     <not voted>
```

# battle costs safe values

For MonsterEOS.io:
RAM: 2kb (during the battle, )
net/cpu: free

For players:
RAM: 0kb
net: 1kb (the avg is 1kb, but lets set 2kb as a safe amount)
cpu: 30ms (the avg is 14ms, but lets set 30ms as a safe amount)

## deploy basic contracts and monstereosio contract

Run the below commands from the pet folder (also you need to adjust your eos relative path)

```

# starting node, BE CAREFUL it's deleting blocks to start from a fresh environment
nodeos -e -p eosio --plugin eosio::wallet_api_plugin --plugin eosio::chain_api_plugin --plugin eosio::history_api_plugin --plugin eosio::net_api_plugin --access-control-allow-origin "*" --access-control-allow-headers "*" --access-control-allow-credentials true --contracts-console --max-transaction-time 100 -f "*" --delete-all-blocks

echo "deploy bios and token..."
cleos set contract eosio ../../../eos-mainnet/build/contracts/eosio.bios -p eosio
cleos create account eosio eosio.token EOS8Be9m6RgEXHXR4tTYZyorm1fEkMLMTubTd2PJHDeYCH2Ufg3XN EOS4ywPbXJp1V9AKQpSVKkCCDhgLSj7vvGK5pdowY5zL5s7hJdGn3
cleos set contract eosio.token ../../../eos-mainnet/build/contracts/eosio.token -p eosio.token
cleos push action eosio.token create '[ "eosio", "1000000000.0000 EOS", 0, 0, 0]' -p eosio.token
cleos push action eosio.token issue '["eosio", "100.0000 EOS", "initial issue"]' -p eosio
sleep .5

cleos create account eosio monstereosio EOS4ywPbXJp1V9AKQpSVKkCCDhgLSj7vvGK5pdowY5zL5s7hJdGn3 EOS4ywPbXJp1V9AKQpSVKkCCDhgLSj7vvGK5pdowY5zL5s7hJdGn3
cleos set contract monstereosio ../pet

```

Add elements and pet types:

```
../load-elements.sh
../load-pet-types.sh # it has some delays to avoid transaction duplication
```

Create accounts and create pets:

```
cleos create account eosio leordev EOS4ywPbXJp1V9AKQpSVKkCCDhgLSj7vvGK5pdowY5zL5s7hJdGn3 EOS4ywPbXJp1V9AKQpSVKkCCDhgLSj7vvGK5pdowY5zL5s7hJdGn3

cleos push action monstereosio createpet '[ "leordev", "Bubble" ]' -p leordev
cleos push action monstereosio createpet '[ "eosio", "Master" ]' -p eosio

cleos get table monstereosio monstereosio pets -l 5000

# id Bubble = 1, id Master = 2
```

Create, join & start start a battle:

```
echo "creating and joining in a battle"
HASH1=$(openssl rand 32 -hex)
SECR1=$(echo -n $HASH1 | xxd -r -p | sha256sum -b | awk '{print $1}')
echo "join 1 sec/hash"
echo $SECR1
echo $HASH1
cleos push action monstereosio battlecreate "[ \"leordev\", 1, \"$SECR1\" ]" -p leordev

HASH2=$(openssl rand 32 -hex)
SECR2=$(echo -n $HASH2 | xxd -r -p | sha256sum -b | awk '{print $1}')
echo "join 2 sec/hash"
echo $SECR2
echo $HASH2
cleos push action monstereosio battlejoin "[ \"leordev\", \"eosio\", \"$SECR2\" ]" -p eosio

cleos get table monstereosio monstereosio battles -l 5000

echo "starting battle"
cleos push action monstereosio battlestart "[ \"leordev\", \"leordev\", \"$HASH1\" ]" -p leordev
cleos push action monstereosio battlestart "[ \"leordev\", \"eosio\", \"$HASH2\" ]" -p eosio

cleos get table monstereosio monstereosio battles -l 5000
```

need to check the turn orders to select pets and start fight

```
echo "selecting pets"
cleos push action monstereosio battleselpet '[ "leordev", "leordev", 1 ]' -p leordev
cleos push action monstereosio battleselpet '[ "leordev", "eosio", 2 ]' -p eosio

cleos push action monstereosio battleattack '[ "leordev", "leordev", 1, 2, 0 ]' -p leordev
cleos push action monstereosio battleattack '[ "leordev", "eosio", 2, 1, 0 ]' -p eosio
```
