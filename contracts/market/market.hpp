#include <eosiolib/eosio.hpp>
#include <eosiolib/asset.hpp>
#include "lib/types.hpp"
#include "../pet/lib/types.hpp"

using namespace eosio;
using namespace types;

/* ****************************************** */
/* ------------ Contract Definition --------- */
/* ****************************************** */

class market : public eosio::contract {
public: 
    market(account_name self)
    :eosio::contract(self),
    offers(_self, _self),
    pets(N(monstereosio), N(monstereosio))
    {
    }

    _tb_offers offers;
    types::_tb_pet pets;

    void offerpet(uuid pet_id, name newowner, uint32_t until, uint64_t amount);
    void removeoffer(name owner, uuid pet_id);
    void claimpet(name oldowner, uuid pet_id);
    void bidpet(uuid pet_id, name bidder, uint32_t until, uint64_t amount);
    void removebid(name bidder, uuid pet_id);
};