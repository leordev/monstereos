/**
 * Pet-Tamagotchi-Alike Smart Contract
 *
 * The idea is to copy the original tamagotchi to the chain :)
 *
 *
 * @author Leo Ribeiro
 */
#include <eosiolib/asset.hpp>
#include <eosiolib/eosio.hpp>
#include <eosiolib/transaction.hpp>
#include <eosiolib/singleton.hpp>
#include <math.h>
// #include <boost/algorithm/string.hpp>

using namespace eosio;

using std::string;
using std::hash;

/* ****************************************** */
/* ------------ Types Declarations ---------- */
/* ****************************************** */

typedef uint64_t uuid;

constexpr uint8_t PET_TYPES = 109;
constexpr uint32_t DAY = 86400;
constexpr uint32_t HOUR = 3600;
constexpr uint32_t MINUTE = 60;



/* ****************************************** */
/* ------------ Contract Definition --------- */
/* ****************************************** */

class pet : public eosio::contract {
public:
    pet(account_name self)
    :eosio::contract(self),
    pets(_self,_self),
    pet_config(_self,_self)
    {}



    void awakepet(uuid pet_id);
    void bedpet(uuid pet_id);
    void feedpet(uuid pet_id);
    void updatepet(uuid pet_id);
    void createpet(name owner, string pet_name);
    void destroypet(uuid pet_id);
    void transferpet(uuid pet_id, name newowner);
    void claimpet(uuid pet_id);
    void transfer(uint64_t sender, uint64_t receiver);
    void changecrtol(uint32_t new_interval);
    void changecrfee(asset new_fee);


    private:


    struct st_transfer {
        account_name from;
        account_name to;
        asset        quantity;
        string       memo;
    };



    /* ****************************************** */
    /* ------------ Contract Tables ------------- */
    /* ****************************************** */

    // @abi table pets i64
    struct st_pets {
        uuid id;
        name owner;
        name new_owner;
        string name;
        uint8_t type;
        uint32_t created_at;
        uint32_t death_at = 0;
        uint32_t last_fed_at;
        uint32_t last_bed_at;
        uint32_t last_awake_at = 0;
        uint32_t last_play_at;
        uint32_t last_shower_at;

        uint64_t primary_key() const { return id; }

        uint64_t get_pets_by_owner() const { return owner.value; }

        bool is_sleeping() const {
            return last_bed_at > last_awake_at;
        }

        bool is_alive() const {
            return death_at == 0;
        }
    };

    typedef multi_index<N(pets), st_pets,
        indexed_by<N(byowner), const_mem_fun<st_pets, uint64_t, &st_pets::get_pets_by_owner>>
    > _tb_pet;
    _tb_pet pets;

    // @abi table accounts i64
    struct st_account {
        asset    balance;
        uint64_t primary_key() const { return balance.symbol.name(); }
    };
    typedef multi_index<N(accounts), st_account> _tb_accounts;




    /* ****************************************** */
    /* ------------ Contract Config Data -------- */
    /* ****************************************** */

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

    /* ****************************************** */
    /* ------------ Private Functions ----------- */
    /* ****************************************** */

    st_pet_config _get_pet_config();

    uuid _next_id();

    uint64_t _hash_str(const string &str);

    void _update(st_pets &pet);

    uint32_t _calc_hunger_hp(const st_pet_config &pc,
                             const uint32_t &last_fed_at,
                             const uint32_t &current_time);

    bool _pet_name_exists(string pet_name);

};
