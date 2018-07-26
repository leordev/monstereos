/**
 * Pet-Tamagotchi-Alike Smart Contract
 *
 * The idea is to copy the original tamagotchi to the chain :)
 *
 *
 * @author Leo Ribeiro
 */
#include <eosiolib/eosio.hpp>
#include <eosiolib/asset.hpp>
#include <eosiolib/crypto.h>
#include <eosiolib/transaction.hpp>
#include <eosiolib/singleton.hpp>
#include <math.h>
#include <vector>
#include <map>
#include "lib/types.hpp"

using namespace eosio;
using namespace types;
using std::string;
using std::hash;

/* ****************************************** */
/* ------------ Contract Definition --------- */
/* ****************************************** */

class pet : public eosio::contract {
public:
    pet(account_name self)
    :eosio::contract(self),
    pettypes(_self,_self),
    elements(_self,_self),
    pets(_self,_self),
    petinbattles(_self,_self),
    pet_config(_self,_self),
    pet_config2(_self,_self)
    {}

    _tb_pet_types pettypes;
    _tb_elements  elements;
    _tb_pet pets;
    _tb_pet_in_battle petinbattles;

    // pet interactions
    void createpet    ( name owner, string pet_name );
    void updatepet    ( uuid pet_id );
    void feedpet      ( uuid pet_id );
    void bedpet       ( uuid pet_id );
    void awakepet     ( uuid pet_id );
    void destroypet   ( uuid pet_id );
    void transferpet  ( uuid pet_id, name newowner);
    
    // battle interface
    void battlecreate ( name host, battle_mode mode, checksum256 secret );
    void battlejoin   ( name host, name player, checksum256 secret );
    void battleleave  ( name host, name player );
    void battlestart  ( name host, name player, checksum256 source );
    void battleselpet ( name host, name player, uuid pet_id );
    void battleattack ( name host, name player, uuid pet_id, uuid pet_enemy_id, element_type element );
    void battlefinish ( name host, name winner );

    // admin/config interactions
    void addelemttype ( vector<uint8_t> ratios );
    void changeelemtt ( uint64_t id, vector<uint8_t> ratios );
    void addpettype   ( vector<uint8_t> elements );
    void changepettyp ( uint64_t id, vector<uint8_t> elements );
    void changecrtol  ( uint32_t new_interval );
    void changebatma  ( uint16_t new_max_arenas );
    void changebatidt ( uint32_t new_idle_tolerance );
    void changebatami ( uint8_t new_attack_min_factor );
    void changebatama ( uint8_t new_attack_max_factor );

    // token deposits
    void transfer     ( uint64_t sender, uint64_t receiver );
    void handletransf (string memo, asset quantity, account_name from);
    private:

    /* ****************************************** */
    /* ------------ Contract Config Data -------- */
    /* ****************************************** */

    // DEPRECATED OLD PETCONFIG FOR MIGRATION
    // @abi table petconfig i64
    struct st_pet_config {
        uuid     last_id = 0;
        asset    creation_fee = asset{0,S(4,EOS)};
        uint8_t  max_health = 100;
        uint32_t hunger_to_zero = 10 * HOUR;
        uint32_t min_hunger_interval = 3 * HOUR;
        uint8_t  max_hunger_points = 100;
        uint8_t  hunger_hp_modifier = 1;
        uint32_t min_awake_interval = 8 * HOUR;
        uint32_t min_sleep_period = 4 * HOUR;
        uint32_t creation_tolerance = 1 * HOUR;
        uint32_t monsters_to_activate_fee = 1000;
    };

    typedef singleton<N(petconfig), st_pet_config> pet_config_singleton;
    pet_config_singleton pet_config;

    // @abi table petconfig2 i64
    struct st_pet_config2 {
        uuid     last_id = 0;
        asset    creation_fee = asset{0,S(4,EOS)};
        uint8_t  max_health = 100;
        uint32_t hunger_to_zero = 10 * HOUR;
        uint32_t min_hunger_interval = 3 * HOUR;
        uint8_t  max_hunger_points = 100;
        uint8_t  hunger_hp_modifier = 1;
        uint32_t min_awake_interval = 8 * HOUR;
        uint32_t min_sleep_period = 4 * HOUR;
        uint32_t creation_tolerance = 1 * HOUR;
        uint32_t battle_idle_tolerance = 60;
        uint8_t  attack_min_factor = 20;
        uint8_t  attack_max_factor = 28;
        uint16_t battle_max_arenas = 10;
        uint16_t battle_busy_arenas = 0;
        uint16_t last_element_id = 0;
        uint16_t last_pet_type_id = 109;
    };

    typedef singleton<N(petconfig2), st_pet_config2> pet_config2_singleton;
    pet_config2_singleton pet_config2;

    /* ****************************************** */
    /* ------------ Private Functions ----------- */
    /* ****************************************** */

    // internal config accessers
    st_pet_config2 _get_pet_config();
    void _update_pet_config(const st_pet_config2 &pc);
    uuid _next_id();
    uint64_t _next_element_id();
    uint64_t _next_pet_type_id();

    // internal pet calcs
    void _update(st_pets &pet);
    uint32_t _calc_hunger_hp(const uint8_t &max_hunger_points,
                             const uint32_t &hunger_to_zero,
                             const uint8_t &hunger_hp_modifier,
                             const uint32_t &last_fed_at,
                             const uint32_t &current_time);
    void _transfervalue(name receiver, asset quantity, string memo);

};
