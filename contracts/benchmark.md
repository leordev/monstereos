## separated singleton from pet element types

the cpu reduced from 20k avg (see below) to 4k. (5x less)

## benchmark before changes - big singleton with all types and elements:

start battle and select pets:
```
executed transaction: a7212f6a189b6de0d84cb1638801498d912ba4fee46ecd601e5ad4ff8c215aab  104 bytes  4056 us
#  monstereosio <= monstereosio::battlecreate   {"host":"leordev","mode":1}
warning: transaction executed locally, but may not be confirmed by the network yet
{
  "rows": [{
      "host": "leordev",
      "mode": 1,
      "started_at": 0,
      "last_move_at": 0,
      "commits": [],
      "pets_stats": []
    }
  ],
  "more": false
}
joining battle
executed transaction: a00b020ed34e128dd093fb7c86d3a74ccdf8c2c4a27b97bd142b77c41ca55e85  144 bytes  1979 us
#  monstereosio <= monstereosio::battlejoin     {"host":"leordev","player":"leordev","secret":"d533f24d6f28ddcef3f066474f7b8355383e485681ba8e793e037...
warning: transaction executed locally, but may not be confirmed by the network yet
executed transaction: 4b39c0e857ae5fa01b2bc87679878169834921583a96321594bf2f4e6686f482  144 bytes  1979 us
#  monstereosio <= monstereosio::battlejoin     {"host":"leordev","player":"eosio","secret":"50ed53fcdaf27f88d51ea4e835b1055efe779bb87e6cfdff47d28c8...
warning: transaction executed locally, but may not be confirmed by the network yet
{
  "rows": [{
      "host": "leordev",
      "mode": 1,
      "started_at": 0,
      "last_move_at": 0,
      "commits": [{
          "player": "leordev",
          "commitment": "d533f24d6f28ddcef3f066474f7b8355383e485681ba8e793e037f5cf36e4883",
          "reveal": "0000000000000000000000000000000000000000000000000000000000000000"
        },{
          "player": "eosio",
          "commitment": "50ed53fcdaf27f88d51ea4e835b1055efe779bb87e6cfdff47d28c88ffb27129",
          "reveal": "0000000000000000000000000000000000000000000000000000000000000000"
        }
      ],
      "pets_stats": []
    }
  ],
  "more": false
}
starting battle
executed transaction: a6467cc931454d4475074404907ad5f4a9a5dab11c7d76f1c295479094bb64e6  144 bytes  2116 us
#  monstereosio <= monstereosio::battlestart    {"host":"leordev","player":"leordev","source":"28349b1d4bcdc9905e4ef9719019e55743c84efa0c5e9a0b077f0...
warning: transaction executed locally, but may not be confirmed by the network yet
executed transaction: 60cb24b1e13ce63082c391e6afcaab0efb56fe1b2120efc66e967cec669b3a5b  144 bytes  2162 us
#  monstereosio <= monstereosio::battlestart    {"host":"leordev","player":"eosio","source":"15fe76d25e124b08feb835f12e00a879bd15666a33786e64b655891...
warning: transaction executed locally, but may not be confirmed by the network yet
{
  "rows": [{
      "host": "leordev",
      "mode": 1,
      "started_at": 1529839932,
      "last_move_at": 0,
      "commits": [{
          "player": "leordev",
          "commitment": "d533f24d6f28ddcef3f066474f7b8355383e485681ba8e793e037f5cf36e4883",
          "reveal": "28349b1d4bcdc9905e4ef9719019e55743c84efa0c5e9a0b077f0b54fcd84905"
        },{
          "player": "eosio",
          "commitment": "50ed53fcdaf27f88d51ea4e835b1055efe779bb87e6cfdff47d28c88ffb27129",
          "reveal": "15fe76d25e124b08feb835f12e00a879bd15666a33786e64b655891fba7d6c12"
        }
      ],
      "pets_stats": []
    }
  ],
  "more": false
}
selecting pets
executed transaction: f5bd72b237a6300eab73ed0aefbbdbea77966639a363977ae2419f015bfda32d  120 bytes  32326 us
#  monstereosio <= monstereosio::battleselpet   {"host":"leordev","player":"leordev","pet_id":1}
warning: transaction executed locally, but may not be confirmed by the network yet
executed transaction: c17ea232273118106072eb1bc18e470856126b94873ba09f56fb4ec1dc78143f  120 bytes  25256 us
#  monstereosio <= monstereosio::battleselpet   {"host":"leordev","player":"eosio","pet_id":2}
```

attacks til death:
```
TURN 1)
executed transaction: 0862b2f8bde9037f4b707ac634f206f8eacb21113235da39fb9da2f63e53ec55  128 bytes  25293 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"leordev","pet_id":1,"pet_enemy_id":2,"element":0}

executed transaction: 1257a7587e90e693a335d40d3dd1e65cb5acd10f7bb7ee325057e7ec18297219  128 bytes  25340 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"eosio","pet_id":2,"pet_enemy_id":1,"element":0}

------------------

executed transaction: 9cee89322953dd6ab291d387c5855d9c0a45a0621a612413f8f0c5722cfed271  128 bytes  25207 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"eosio","pet_id":2,"pet_enemy_id":1,"element":0}

-----------

executed transaction: 7c938222afb3f3163ef9958c31c3da333799c880a78fb27d1fb5e71178cbc1d1  128 bytes  26061 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"leordev","pet_id":1,"pet_enemy_id":2,"element":0}
executed transaction: 9b625e4db819e92229c1ea3a9da679b514f912b17e83511212c568557ddd067d  128 bytes  24914 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"eosio","pet_id":2,"pet_enemy_id":1,"element":0}

-------------------

executed transaction: 8abfc800b93cfc12378505bf4f8f58bb2d9b88396208c727547ae9c745a8e87c  128 bytes  25304 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"leordev","pet_id":1,"pet_enemy_id":2,"element":0}

executed transaction: 736041768e5a65618344b1c1c999ebb9b828157c3cb70ef4603fd1f8dacefbd8  128 bytes  25273 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"eosio","pet_id":2,"pet_enemy_id":1,"element":0}

------------------------

executed transaction: 1771c831b7962198f2de86eda4d4793ae957d74db35d3d67061f17c722ab1d5a  128 bytes  25974 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"leordev","pet_id":1,"pet_enemy_id":2,"element":0}

executed transaction: 6b95b543d7af2edd32d6aabd4c4eb4cf3e4f82bc7e9ad369d2a1bca74e568a67  128 bytes  25863 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"eosio","pet_id":2,"pet_enemy_id":1,"element":0}

------------------------

executed transaction: eac5aa2e9bc690275aa185ce45d98e6cd03fe0a8f1d4f6ee3119485a1bad2962  128 bytes  26240 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"leordev","pet_id":1,"pet_enemy_id":2,"element":0}

executed transaction: 2a62718c24d59fe5e35fdc3f4672a926eface20148bd5f2c3983e60042943d4f  128 bytes  27030 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"eosio","pet_id":2,"pet_enemy_id":1,"element":0}

--------------------------

executed transaction: 6b7b8ab299ac3e2418e8ac368ee3fb43f88dd672929603f41f726efb5b3bf058  128 bytes  26032 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"leordev","pet_id":1,"pet_enemy_id":2,"element":0}

executed transaction: 55b964437e3b5eb0086c1870c1487228e26fc33818e5b4caec6f2da6dc4f9436  128 bytes  25805 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"eosio","pet_id":2,"pet_enemy_id":1,"element":0}

--------------------------

executed transaction: bb6eec3e5780994d897ceb5641ba7fef1dcb762669ea0b21f565926cd79ae441  128 bytes  25873 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"leordev","pet_id":1,"pet_enemy_id":2,"element":0}

executed transaction: 1b39178acf061d106e9eec8befed5ad4e115dc4443acd71532d83099041b8b48  128 bytes  25901 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"eosio","pet_id":2,"pet_enemy_id":1,"element":0}

-------------------------

executed transaction: 2857279158f0765d76518990632802b2ec6339776056f2dae4bf1979f4a498e0  128 bytes  25350 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"leordev","pet_id":1,"pet_enemy_id":2,"element":0}

executed transaction: 28f51ebcbec1259a6192e9a962ad7c4c1398a78531c2d340b3cd80cc39da7ca7  128 bytes  25785 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"eosio","pet_id":2,"pet_enemy_id":1,"element":0}

-------------------------

executed transaction: 2426b53cc6e17c395a88b88e1788c582767ee4ff5fc5d7c3b7dbb366add231a8  128 bytes  26494 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"leordev","pet_id":1,"pet_enemy_id":2,"element":0}

executed transaction: 22faf76787d65bb89e12763bcda976d6f2159264ce111d1ffe6bcd6ce8f85174  128 bytes  33004 us
#  monstereosio <= monstereosio::battleattack   {"host":"leordev","player":"eosio","pet_id":2,"pet_enemy_id":1,"element":0}

#  monstereosio <= monstereosio::battlefinish   {"host":"leordev","winner":"eosio"}
```
