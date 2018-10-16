#include <pet/pet.hpp>

#include "pet.admin.cpp"
#include "pet.battle.cpp"
#include "pet.market.cpp"
#include "pet.messages.cpp"

using namespace utils;
using namespace types;

void pet::createpet(name owner,
                    string pet_name) {

    require_auth(owner);

    // trim name would be nice
    // eos issue https://github.com/EOSIO/eos/issues/4184
    // boost::algorithm::trim(pet_name);

    // validates pet naming
    eosio_assert(pet_name.length() >= 1, "name must have at least 1 character!");
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
        pet.last_shower_at = pet.created_at;
        pet.last_bed_at = pet.created_at;
        pet.last_awake_at = pet.created_at + pc.creation_awake;

        // we are considering only 105 monsters, the type 105 is
        // monstereos devilish icon
        pet.type = (pet.created_at + pet.id + owner + _random(100)) 
            % (pc.last_pet_type_id - 3); 

        r = pet;
    });
}

void pet::destroypet(uuid pet_id) {

    const auto& pet = pets.get(pet_id, "E404|Invalid pet, destroying action is unrecoverable");

    require_auth(pet.owner);

    pets.erase( pet );

    // primer roller
    _random(10);
}

void pet::transferpet(uuid pet_id, name new_owner) {

    auto itr_pet = pets.find(pet_id);
    eosio_assert(itr_pet != pets.end(), "E404|Invalid pet");
    auto pet = *itr_pet;

    eosio_assert(has_auth(_self) || has_auth(pet.owner),
        "missing required authority of contract or owner");

    // require_auth(pet.owner);

    pets.modify(itr_pet, 0, [&](auto &r) {
        r.owner = new_owner;
    });

    // primer roller
    _random(10);
}

void pet::feedpet(uuid pet_id) {

    auto itr_pet = pets.find(pet_id);
    eosio_assert(itr_pet != pets.end(), "E404|Invalid pet");
    st_pets pet = *itr_pet;

    auto pc = _get_pet_config();

    eosio_assert(_is_alive(pet, pc), "dead don't eat");
    eosio_assert(!pet.is_sleeping(), "zzzzzz");

    bool can_eat = (now() - pet.last_fed_at) > pc.min_hunger_interval;
    eosio_assert(can_eat, "not hungry");

    pets.modify(itr_pet, pet.owner, [&](auto &r) {
        r.last_fed_at = now();
    });

    // primer roller
    _random(10);
}

void pet::bedpet(uuid pet_id) {
    auto itr_pet = pets.find(pet_id);
    eosio_assert(itr_pet != pets.end(), "E404|Invalid pet");
    st_pets pet = *itr_pet;

    // only owners can make pets sleep
    require_auth(pet.owner);

    auto pc = _get_pet_config();

    eosio_assert(_is_alive(pet, pc), "dead don't sleep");
    eosio_assert(!pet.is_sleeping(), "already sleeping");

    bool can_sleep = (now() - pet.last_awake_at) > pc.min_awake_interval;
    eosio_assert(can_sleep, "not now!");

    pets.modify(itr_pet, pet.owner, [&](auto &r) {
        r.last_bed_at = now();
    });

    // primer roller
    _random(10);
}

void pet::awakepet(uuid pet_id) {
    auto itr_pet = pets.find(pet_id);
    eosio_assert(itr_pet != pets.end(), "E404|Invalid pet");
    st_pets pet = *itr_pet;

    // only owners can wake up pets
    require_auth(pet.owner);

    auto pc = _get_pet_config();

    eosio_assert(_is_alive(pet, pc), "dead don't awake");
    eosio_assert(pet.is_sleeping(), "already awake");

    bool can_awake = (now() - pet.last_bed_at) > pc.min_sleep_period;
    eosio_assert(can_awake, "zzzzzz");

    pets.modify(itr_pet, pet.owner, [&](auto &r) {
        r.last_awake_at = now();
    });

    // primer roller
    _random(10);
}

void pet::signup(name user) {

    require_auth(user);
    asset new_balance = asset{0,S(4,EOS)};

    // check user is already signed up
    _tb_accounts accounts(_self, user);
    auto itr_balance = accounts.find(new_balance.symbol.name());
    eosio_assert(itr_balance == accounts.end(), "you have signed up already");

    accounts.emplace(user, [&](auto& r){
        r.balance = new_balance;
    });

    // primer roller
    _random(10);
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

    string memoprefix = "mtt";
    auto startsWithMTT = transfer_data.memo.rfind(memoprefix, 0);

    // Monster Market Transfer
    if (startsWithMTT == 0) {

        _handle_transf(transfer_data.memo, transfer_data.quantity, transfer_data.from);

    } else { // in-app transfer
        _tb_accounts accounts(_self, transfer_data.from);
        asset new_balance;
        auto itr_balance = accounts.find(transfer_data.quantity.symbol.name());
        if(itr_balance != accounts.end()) {
            accounts.modify(itr_balance, 0, [&](auto& r){
                // Assumption: total currency issued by eosio.token will not overflow asset
                r.balance += transfer_data.quantity;
                new_balance = r.balance;
            });
        }
    }

    // primer roller
    _random(10);
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

    return effect_hp_hunger;
}

bool pet::_is_alive(st_pets &pet, const st_pet_config2 &pc) {

    // auto pc = _get_pet_config();

    uint32_t current_time = now();

    uint32_t effect_hp_hunger = _calc_hunger_hp(pc.max_hunger_points,
        pc.hunger_to_zero, pc.hunger_hp_modifier,
        pet.last_fed_at, current_time);

    int32_t hp = pc.max_health - effect_hp_hunger;

    return hp > 0;
}

int pet::_random(const int num) {
  
  auto itr_seed = seed.begin();
  
  if (itr_seed == seed.end()) {
    itr_seed = seed.emplace( _self, [&]( auto& r ) { });
  }

  auto new_seed = (itr_seed->last + now()) % 65537;

  seed.modify( itr_seed, _self, [&]( auto& s ) {
    s.last = new_seed;
  });

  return new_seed % num;
}
