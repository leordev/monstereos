#include "pet.hpp"
#include "lib/utils.hpp"
#include "lib/pet.admin.cpp"
#include "lib/pet.battle.cpp"
#include "../market/lib/types.hpp"

using namespace utils;
using namespace types;

void pet::createpet(name owner,
                string pet_name) {

    require_auth(owner);

    // trim name would be nice
    // eos issue https://github.com/EOSIO/eos/issues/4184
    // boost::algorithm::trim(pet_name);

    // validates pet naming
    eosio_assert(pet_name.length() >= 1, "name must have at least 1 character");
    eosio_assert(pet_name.length() <= 20, "name cannot exceed 20 chars");
    eosio_assert(pet_name.length() > count_spaces(pet_name), "name cannot be composed of spaces only");
    // eosio_assert(!_pet_name_exists(pet_name), "duplicated pet name");

    // initialize config
    auto pc = _get_pet_config();

    // check last pet creation tolerance
    if (pc.creation_tolerance > 0) {

        auto owner_pets = pets.get_index<N(byowner)>();
        auto last_pet_itr = owner_pets.find(owner);

        uint32_t last_created_date = 0;

        for (; last_pet_itr != owner_pets.end(); last_pet_itr++) {
            auto pet = *last_pet_itr;
            if (pet.owner != owner) break;
            last_created_date = pet.created_at > last_created_date ?
                pet.created_at : last_created_date;
        }

        if (last_created_date > 0) {
            print("\nlast created pet at: ", last_created_date);
        }

        uint32_t last_creation_interval = now() - last_created_date;
        eosio_assert(last_creation_interval > pc.creation_tolerance, "You can't create another pet now");
    }

    uuid new_id = _next_id();

    // creates the pet
    pets.emplace(owner, [&](auto &r) {
        st_pets pet{};
        pet.id = new_id;
        pet.name = pet_name;
        pet.owner = owner;
        pet.created_at = now();
        pet.last_fed_at = pet.created_at;
        pet.last_play_at = pet.created_at;
        pet.last_bed_at = pet.created_at;
        pet.last_shower_at = pet.created_at;
        pet.last_awake_at = 0;

        pet.type = (hash_str(pet_name) + pet.created_at + pet.id + owner) % pc.last_pet_type_id;

        r = pet;
    });
}

void pet::updatepet(uuid pet_id) {
    require_auth(_self);
    print(pet_id, "| updating pet ");

    auto itr_pet = pets.find(pet_id);
    eosio_assert(itr_pet != pets.end(), "E404|Invalid pet");
    st_pets pet = *itr_pet;

    _update(pet);

    pets.modify(itr_pet, pet.owner, [&](auto &r) {
        r.death_at = pet.death_at;
    });
}

void pet::destroypet(uuid pet_id) {

    const auto& pet = pets.get(pet_id, "E404|Invalid pet, destroying action is unrecoverable");

    require_auth(pet.owner);

    pets.erase( pet );

}

void pet::transferpet(uuid pet_id, name newowner) {
    
    require_auth(N(monstereosmt));

    print(pet_id, "| updating pet ");
    auto itr_pet = pets.find(pet_id);
    eosio_assert(itr_pet != pets.end(), "E404|Invalid pet");
    auto pet = *itr_pet;

    pets.modify(itr_pet, 0, [&](auto &r) {
        r.owner = newowner;
    });

    print("new owner ", newowner);    
}

void pet::feedpet(uuid pet_id) {

    auto itr_pet = pets.find(pet_id);
    eosio_assert(itr_pet != pets.end(), "E404|Invalid pet");
    st_pets pet = *itr_pet;

    _update(pet);

    auto pc = _get_pet_config();

    pets.modify(itr_pet, pet.owner, [&](auto &r) {
        r.death_at = pet.death_at;

        uint32_t current_time = now();

        bool can_eat = (current_time - pet.last_fed_at) > pc.min_hunger_interval &&
            !r.is_sleeping();

        if (can_eat && r.is_alive()) {
            r.last_fed_at = now();
        } else if (r.is_sleeping()) {
            print("I111|Zzzzzzzz...");
        } else if (!can_eat) {
            print("I110|Not hungry");
        } else if(!r.is_alive()) {
            print("I199|Dead don't feed");
        }
    });
}

void pet::bedpet(uuid pet_id) {
    auto itr_pet = pets.find(pet_id);
    eosio_assert(itr_pet != pets.end(), "E404|Invalid pet");
    st_pets pet = *itr_pet;

    // only owners can make pets sleep
    require_auth(pet.owner);

    _update(pet);

    auto pc = _get_pet_config();

    pets.modify(itr_pet, pet.owner, [&](auto &r) {
        r.death_at = pet.death_at;

        uint32_t current_time = now();

        bool can_sleep = (current_time - pet.last_awake_at) > pc.min_awake_interval &&
            !r.is_sleeping();

        if (can_sleep && r.is_alive()) {
            r.last_bed_at = now();
        } else if (!can_sleep) {
            print("I201|Not now sir!");
        } else if(!r.is_alive()) {
            print("I299|Dead don't sleep");
        }
    });
}

void pet::awakepet(uuid pet_id) {
    auto itr_pet = pets.find(pet_id);
    eosio_assert(itr_pet != pets.end(), "E404|Invalid pet");
    st_pets pet = *itr_pet;

    // only owners can wake up pets
    require_auth(pet.owner);

    _update(pet);

    auto pc = _get_pet_config();

    pets.modify(itr_pet, pet.owner, [&](auto &r) {
        r.death_at = pet.death_at;

        uint32_t current_time = now();
        bool can_awake = (current_time - pet.last_bed_at) > pc.min_sleep_period &&
            r.is_sleeping();

        if (can_awake && r.is_alive()) {
            r.last_awake_at = now();
        } else if (!can_awake) {
            print("I301|Zzzzzzz");
        } else if(!r.is_alive()) {
            print("I399|Dead don't awake");
        }
    });
}

void pet::transfer(uint64_t sender, uint64_t receiver) {
    print("\n>>> sender >>>", sender, " - name: ", name{sender});
    print("\n>>> receiver >>>", receiver, " - name: ", name{receiver});

    // ??? Don't need to verify because we already did it in EOSIO_ABI_EX ???
    // eosio_assert(code == N(eosio.token), "I reject your non-eosio.token deposit");

    auto transfer_data = unpack_action_data<st_transfer>();
    if(transfer_data.from == _self || transfer_data.to != _self) {
        return;
    }

    print("\n>>> transfer data quantity >>> ", transfer_data.quantity);

    eosio_assert(transfer_data.quantity.symbol == string_to_symbol(4, "EOS"),
    "MonsterEOS only accepts EOS for deposits");
    eosio_assert(transfer_data.quantity.is_valid(), "Invalid token transfer");
    eosio_assert(transfer_data.quantity.amount > 0, "Quantity must be positive");

    _tb_accounts accounts(_self, transfer_data.from);
    asset new_balance;
    auto itr_balance = accounts.find(transfer_data.quantity.symbol.name());
    if(itr_balance != accounts.end()) {
        accounts.modify(itr_balance, transfer_data.from, [&](auto& r){
            // Assumption: total currency issued by eosio.token will not overflow asset
            r.balance += transfer_data.quantity;
            new_balance = r.balance;
        });
    } else {
        accounts.emplace(transfer_data.from, [&](auto& r){
            r.balance = transfer_data.quantity;
            new_balance = r.balance;
        });
    }

    print("\n", name{transfer_data.from}, " deposited:       ", transfer_data.quantity);
    print("\n", name{transfer_data.from}, " funds available: ", new_balance);

    _handletransf(transfer_data.memo, transfer_data.quantity, transfer_data.from);   

}

void pet::_handletransf(string memo, asset quantity, account_name from) {
    string memoprefix = "MTT";
    auto startsWithMTT = memo.rfind(memoprefix, 0);
    
    if (startsWithMTT == 0) {
        print("memo matches");
        string sofferid = memo.substr(3);
        auto offerid = stoi(sofferid);
        print("\ntransfer received for offer ", offerid);
        _tb_offers offers(N(monstereosmt), N(monstereosmt));
        auto itr_offer = offers.find(offerid);
        if (itr_offer != offers.end()) {
            auto offer = *itr_offer;
            auto itr_pet = pets.find(offer.pet_id);
            eosio_assert(itr_pet != pets.end(), "E404|Invalid pet");
            auto pet = *itr_pet;
            
            eosio_assert(offer.type != 10, "E404|Offer of type " + offer.type);
            eosio_assert(quantity.amount == offer.value.amount, "E404|amounts does not match offer's amount");
            eosio_assert(quantity.symbol == offer.value.symbol, "E404|token does not match offer's token");
            eosio_assert(pet.owner == offer.user, "E404|monster does to belong to offer's user");

            // transfer money to previous owner
            string memo = "transfer for offer " + sofferid;
            _transfervalue(pet.owner, quantity, memo);
            // change ownership
            pets.modify(itr_pet, 0, [&](auto &r) {
                r.owner = offer.new_owner;
            });

            _tb_accounts accounts(_self, from);
            asset new_balance;
            auto itr_balance = accounts.find(quantity.symbol.name());
            eosio_assert(itr_balance != accounts.end(), "E404|Invalid currency");

            accounts.modify(itr_balance, from, [&](auto& r){
                // Assumption: total currency issued by eosio.token will not overflow asset
                r.balance -= quantity;
                new_balance = r.balance;
            });
        }
    }
}

uint32_t pet::_calc_hunger_hp(const uint8_t &max_hunger_points, const uint32_t &hunger_to_zero,
    const uint8_t &hunger_hp_modifier, const uint32_t &last_fed_at, const uint32_t &current_time) {
    // how long it's hungry?
    uint32_t hungry_seconds = current_time - last_fed_at;
    uint32_t hungry_points = hungry_seconds * max_hunger_points / hunger_to_zero;

    // calculates the effective hunger on hp, if pet hunger is 0
    uint32_t effect_hp_hunger = 0;
    if (hungry_points >= max_hunger_points) {
        effect_hp_hunger = (hungry_points - max_hunger_points) / hunger_hp_modifier;
    }

    print("\npet hungry_points=", hungry_points);
    print("\npet hungry_seconds=", hungry_seconds);

    return effect_hp_hunger;
}

void pet::_update(st_pets &pet) {

    eosio_assert(pet.is_alive(), "E099|Pet is dead.");

    auto pc = _get_pet_config();

    uint32_t current_time = now();

    uint32_t effect_hp_hunger = _calc_hunger_hp(pc.max_hunger_points,
        pc.hunger_to_zero, pc.hunger_hp_modifier,
        pet.last_fed_at, current_time);

    int32_t hp = pc.max_health - effect_hp_hunger;

    print("\npet hp=", hp);
    print("\npet effect_hp_hunger=", effect_hp_hunger);

    if (hp <= 0) {
        pet.death_at = current_time;
    }
}

void pet::_transfervalue(name receiver, asset quantity, string memo) {
     action(permission_level{_self, N(active)}, N(eosio.token), N(transfer), std::make_tuple(N(monstereosio), receiver, quantity, memo)).send();
}

// we need to sacrifice abi generation for recipient listener
// keep alternating the comments between EOSIO_ABI (to generate ABI)
// and EOSIO_ABI_EX to generate the listener action
// https://eosio.stackexchange.com/q/421/54
